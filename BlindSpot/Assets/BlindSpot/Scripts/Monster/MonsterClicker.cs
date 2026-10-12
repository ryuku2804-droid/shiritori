using UnityEngine;

namespace BlindSpot
{
    /// <summary>
    /// 怪物のクリック音 (舌打ちのような「カチカチ」)。怪物の位置をプレイヤーに知らせる。
    /// 音を出すのは怪物の都合なので、NoiseSystem には流さない (怪物自身の耳には関係ない)。
    /// </summary>
    [RequireComponent(typeof(AudioSource))]
    public class MonsterClicker : MonoBehaviour
    {
        [SerializeField] MonsterAI monster;

        [Tooltip("クリック音。空ならコードで作った仮の音を使う")]
        [SerializeField] AudioClip clickClip;

        [Tooltip("巡回中の、クリックとクリックの間隔 (秒、最小〜最大)")]
        [SerializeField] Vector2 calmInterval = new Vector2(1.5f, 3f);
        [Tooltip("調査・追跡中の間隔 (秒、最小〜最大)。短いほど興奮している感じになる")]
        [SerializeField] Vector2 alertInterval = new Vector2(0.4f, 0.8f);
        [Tooltip("1回に続けて鳴らす回数")]
        [SerializeField] int clicksPerBurst = 2;
        [SerializeField] float clickGap = 0.09f;
        [Range(0f, 1f)] [SerializeField] float volume = 0.8f;

        AudioSource source;
        float nextBurstTime;
        float nextClickTime;
        int clicksLeft;

        void Awake()
        {
            source = GetComponent<AudioSource>();
            if (monster == null) monster = GetComponent<MonsterAI>();
            if (clickClip == null) clickClip = CreateClickClip();
            ScheduleNextBurst();
        }

        void Update()
        {
            if (monster != null && monster.State == MonsterState.Caught) return;

            if (clicksLeft > 0)
            {
                if (Time.time < nextClickTime) return;
                source.pitch = Random.Range(0.95f, 1.05f);
                source.PlayOneShot(clickClip, volume);
                clicksLeft--;
                nextClickTime = Time.time + clickGap;
                return;
            }

            if (Time.time >= nextBurstTime)
            {
                clicksLeft = clicksPerBurst;
                nextClickTime = Time.time;
                ScheduleNextBurst();
            }
        }

        void ScheduleNextBurst()
        {
            bool alert = monster != null &&
                         (monster.State == MonsterState.Investigate || monster.State == MonsterState.Chase);
            Vector2 range = alert ? alertInterval : calmInterval;
            nextBurstTime = Time.time + Random.Range(range.x, range.y);
        }

        /// <summary>素材が無くても鳴らせるように、短い「カチッ」をコードで作る。</summary>
        static AudioClip CreateClickClip()
        {
            const int rate = 44100;
            int length = (int)(rate * 0.025f); // 25 ミリ秒
            var data = new float[length];
            var rng = new System.Random(7);    // 毎回同じ音になるよう、乱数の種を固定
            for (int i = 0; i < length; i++)
            {
                float t = (float)i / length;
                float envelope = Mathf.Exp(-t * 10f);                   // すぐ消える
                float noise = (float)(rng.NextDouble() * 2.0 - 1.0);    // ザッという成分
                float tone = Mathf.Sin(2f * Mathf.PI * 1800f * i / rate); // 硬いカチッという成分
                data[i] = (noise * 0.6f + tone * 0.4f) * envelope;
            }
            var clip = AudioClip.Create("MonsterClick", length, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }
    }
}
