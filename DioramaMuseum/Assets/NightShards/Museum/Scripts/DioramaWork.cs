using System;
using UnityEngine;

namespace NightShards.Museum
{
    // 作品ごとの「仕掛け」を動かす。ジオラマの箱に付ける。
    //   Trigger() (鑑賞モードで Space、世界の中でクリック) → _Event が 0 → 1 に盛り上がり、しばらく続いてから 0 に戻る
    //   演出の最中にもう一度 Trigger() しても、最初からやり直さない (終わってから次を受け付ける)
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

        // 仕掛けが動いている間、部屋の照明をこの色に寄せる (a が寄せる強さ。0 なら照明の色はそのまま)
        public Color Tint => TintFor(work);

        static Color TintFor(string workName)
        {
            switch (workName)
            {
                case "BlueFire": return new Color(0.3f, 0.55f, 1f, 0.85f); // 青い炎
                case "Glacier": return new Color(0.75f, 0.88f, 1f, 0.4f);   // 月の光の青白さ
                case "Aurora": return new Color(0.3f, 1f, 0.55f, 0.75f);    // オーロラの緑
                default: return Color.clear;
            }
        }
        public float Value { get; private set; }

        // 演出の最中か (盛り上がり〜おさまるまで)
        public bool IsPlaying => Time.time - started < rise + hold + fall;

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

        static readonly int HeightTexId = Shader.PropertyToID("_HeightTex");
        static readonly int HeightTexOnId = Shader.PropertyToID("_HeightTexOn");
        static readonly int SeedId = Shader.PropertyToID("_Seed");

        // 再生が始まったら、地形の高さの表を作ってシェーダーに渡す (シェーダーが速くなる)
        void Start()
        {
            rend.GetPropertyBlock(block);
            Texture2D height = DioramaTerrain.BakeHeight(work, block.GetFloat(SeedId));
            if (height == null) return;
            block.SetTexture(HeightTexId, height);
            block.SetFloat(HeightTexOnId, 1f);
            rend.SetPropertyBlock(block);
        }

        // 仕掛けを動かす。演出の最中なら何もしない
        public void Trigger()
        {
            if (IsPlaying) return;
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

        static AudioClip rumble, roar, calving, shimmer;

        static AudioClip SoundFor(string workName)
        {
            switch (workName)
            {
                case "Eruption":
                    if (rumble == null) rumble = MakeRumble(9f);
                    return rumble;
                case "BlueFire":
                    if (roar == null) roar = MakeRoar(10f);
                    return roar;
                case "Glacier":
                    if (calving == null) calving = MakeCalving(9f);
                    return calving;
                case "Aurora":
                    if (shimmer == null) shimmer = MakeShimmer(12f);
                    return shimmer;
                default:
                    return null;
            }
        }

        // 氷河が崩れる音: 「ピシッ」と氷が割れ、ゴゴゴと崩れ、3 秒後に「ザブン」と湖に落ちる
        static AudioClip MakeCalving(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(5);
            float low = 0f, mid = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                low += (white - low) * 0.03f;
                mid += (white - mid) * 0.25f;
                float crack = white * Mathf.Exp(-time * 30f) * 1.5f + Mathf.Sin(time * 2f * Mathf.PI * 55f) * Mathf.Exp(-time * 6f);   // ピシッ
                float rumbleEnv = Mathf.Clamp01((time - 1.4f) / 0.3f) * Mathf.Exp(-Mathf.Max(0f, time - 1.7f) * 1.2f);               // ゴゴゴ
                float splashEnv = time > 3f ? Mathf.Exp(-(time - 3f) * 1.6f) : 0f;                                                    // ザブン
                data[i] = crack + low * 6f * rumbleEnv + (mid * 1.5f + low * 3f) * splashEnv;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.85f / peak;
            var clip = AudioClip.Create("Glacier Calving", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // オーロラの音: 風のようなやわらかいざわめきに、遠くで鳴る鈴のような和音が、ゆっくりふくらんで消える
        static AudioClip MakeShimmer(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(3);
            float air = 0f;
            float[] tones = { 392f, 493.9f, 587.3f, 784f }; // ソ・シ・レ・ソ
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                air += (white - air) * 0.08f;
                float swell = Mathf.Sin(Mathf.Clamp01(time / seconds) * Mathf.PI); // ゆっくりふくらんで、消える
                float pad = 0f;
                for (int k = 0; k < tones.Length; k++)
                {
                    float vib = 1f + 0.003f * Mathf.Sin(time * (0.7f + k * 0.3f)); // 少しゆらぐ
                    pad += Mathf.Sin(2f * Mathf.PI * tones[k] * vib * time) * (0.5f + 0.5f * Mathf.Sin(time * (0.4f + k * 0.17f) + k));
                }
                data[i] = (air * 0.8f * (0.6f + 0.4f * Mathf.Sin(time * 0.9f)) + pad * 0.12f) * swell;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.7f / peak;
            var clip = AudioClip.Create("Aurora Shimmer", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // ガスが燃える音: 「ボッ」と火がつく音のあと、ゴーッと吹き出す炎の音が続き、ゆっくり小さくなる
        static AudioClip MakeRoar(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(11);
            float hiss = 0f, body = 0f, low = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                hiss += (white - hiss) * 0.35f;  // シャーという、ガスが吹き出す音
                body += (white - body) * 0.06f;  // ゴーッという、炎の胴の音
                low += (body - low) * 0.02f;     // 低いうなり
                float gust = 0.75f + 0.25f * Mathf.Sin(time * 2.1f) * Mathf.Sin(time * 0.7f + 1f); // 風にあおられて強弱がつく
                float ignite = Mathf.Exp(-time * 6f) * 2.5f;                                     // 火がつく瞬間の「ボッ」
                float attack = Mathf.Clamp01(time / 0.08f);
                float decay = Mathf.Exp(-Mathf.Max(0f, time - 3f) * 0.35f);
                data[i] = (hiss * 0.25f + body * 1.2f + low * 4f) * (gust + ignite) * attack * decay;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.85f / peak;

            var clip = AudioClip.Create("Blue Fire Roar", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
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
