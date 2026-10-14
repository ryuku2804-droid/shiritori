using System;
using UnityEngine;

namespace NightShards.Museum
{
    // 作品ごとの「仕掛け」を動かす。ジオラマの箱に付ける。
    //   Trigger() (鑑賞モードで Space) → _Event が 0 → 1 に盛り上がり、しばらく続いてから 0 に戻る
    //   その間、毎フレーム Pulse で強さを知らせる (部屋の照明や床が連動する: RoomReactor)
    //   音は画像や音声ファイルを使わず、ここで波形を作って鳴らす
    [RequireComponent(typeof(Renderer))]
    public class DioramaWork : MonoBehaviour
    {
        [SerializeField] string work;
        [Tooltip("盛り上がるまでの秒数")] [SerializeField] float rise = 1.5f;
        [Tooltip("いちばん強い状態が続く秒数")] [SerializeField] float hold = 9f;
        [Tooltip("おさまるまでの秒数")] [SerializeField] float fall = 7f;
        [SerializeField, Range(0f, 1f)] float volume = 0.9f;

        // 仕掛けが動いている間、毎フレーム (作品, 強さ 0〜1) を知らせる
        public static event Action<DioramaWork, float> Pulse;

        public string Work => work;
        public float Value { get; private set; }

        static readonly int EventId = Shader.PropertyToID("_Event");
        static readonly int EventTimeId = Shader.PropertyToID("_EventTime");

        float started = -1000f;
        Renderer rend;
        MaterialPropertyBlock block;
        AudioSource source;

        bool spatial = true;

        // spatialSound = false にすると、音を場所に関係なく同じ大きさで鳴らす (ジオラマの世界の中では、こちら)
        public void Setup(string workName, bool spatialSound = true)
        {
            work = workName;
            spatial = spatialSound;
        }

        void Awake()
        {
            rend = GetComponent<Renderer>();
            block = new MaterialPropertyBlock();
        }

        // 仕掛けを動かす。動いている途中なら、最初からやり直す
        public void Trigger()
        {
            started = Time.time;
            PlaySound();
        }

        void Update()
        {
            float t = Time.time - started;
            float v;
            if (t < 0f || t > rise + hold + fall) v = 0f;
            else if (t < rise) v = Smooth(t / rise);
            else if (t < rise + hold) v = 1f;
            else v = 1f - Smooth((t - rise - hold) / fall);

            if (v <= 0f && Value <= 0f) return; // 止まっている間は何もしない
            Value = v;

            rend.GetPropertyBlock(block); // _Biome や _Steps を消さないように、今の値を読んでから書き足す
            block.SetFloat(EventId, v);
            block.SetFloat(EventTimeId, Mathf.Max(0f, t));
            rend.SetPropertyBlock(block);

            Pulse?.Invoke(this, v);
        }

        static float Smooth(float x)
        {
            x = Mathf.Clamp01(x);
            return x * x * (3f - 2f * x);
        }

        // ---------------------------------------------------------------- 音

        void PlaySound()
        {
            AudioClip clip = SoundFor(work);
            if (clip == null) return;
            if (source == null)
            {
                source = gameObject.AddComponent<AudioSource>();
                source.playOnAwake = false;
                source.spatialBlend = spatial ? 1f : 0f; // 作品の位置から聞こえる (世界の中では、まわり全体から)
                source.minDistance = 0.8f;
                source.maxDistance = 14f;
                source.rolloffMode = AudioRolloffMode.Linear;
            }
            source.PlayOneShot(clip, volume);
        }

        static AudioClip rumble;

        static AudioClip SoundFor(string workName)
        {
            if (workName == "Eruption")
            {
                if (rumble == null) rumble = MakeRumble(9f);
                return rumble;
            }
            return null;
        }

        // 地鳴り: 低い音だけを残した雑音 (ブラウンノイズ) に、ときどき岩が弾けるパチパチという音を混ぜる
        static AudioClip MakeRumble(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(7);
            float brown = 0f, low = 0f, crackle = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                brown = (brown + 0.02f * white) / 1.02f;  // ゆっくり揺れる低い音
                low += (brown - low) * 0.05f;            // さらに高い音を削る
                if (random.NextDouble() < 0.0006) crackle = 1f; // ときどき弾ける
                crackle *= 0.995f;
                float pop = white * crackle * 0.25f;

                float attack = Mathf.Clamp01(time / 0.6f);
                float decay = Mathf.Exp(-Mathf.Max(0f, time - 2f) * 0.45f);
                data[i] = (low * 9f + pop) * attack * decay;
            }
            // 大きすぎて音が割れないように、いちばん大きい所を 0.9 にそろえる
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.9f / peak;

            var clip = AudioClip.Create("Eruption Rumble", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }
    }
}
