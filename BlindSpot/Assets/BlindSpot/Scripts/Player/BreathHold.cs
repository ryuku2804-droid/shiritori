using UnityEngine;
using UnityEngine.InputSystem;

namespace BlindSpot
{
    /// <summary>
    /// 呼吸と息止め。Player に付ける。
    /// 普段は小さな呼吸音が出ていて、怪物がすぐそばにいると聞こえてしまう。
    /// Space を長押しすると息を止められるが、ゲージが尽きると咳き込んで大きな音が出る。
    /// ゲージの減る速さは心拍 (怪物との距離) に連動する。
    /// </summary>
    [RequireComponent(typeof(PlayerController))]
    public class BreathHold : MonoBehaviour
    {
        [Header("息止め")]
        [Tooltip("落ち着いているときに、息を止めていられる秒数")]
        [SerializeField] float maxHoldSeconds = 8f;
        [Tooltip("怪物がすぐそばにいるとき、ゲージが何倍の速さで減るか")]
        [SerializeField] float panicDrainMultiplier = 3f;
        [Tooltip("息をしている間、1秒に回復するゲージの量 (満タンが 1)")]
        [SerializeField] float recoverPerSecond = 0.2f;
        [Tooltip("咳き込んだときの音の届く距離 (m)")]
        [SerializeField] float coughRadius = 12f;
        [Tooltip("咳き込んでから、また息を止められるようになるまでの秒数")]
        [SerializeField] float coughRecoverSeconds = 3f;

        [Header("呼吸の音")]
        [Tooltip("落ち着いているときの呼吸音の届く距離 (m)")]
        [SerializeField] float calmBreathRadius = 1f;
        [Tooltip("怪物がすぐそばにいるときの呼吸音の届く距離 (m)。緊張すると息が荒くなる")]
        [SerializeField] float panicBreathRadius = 2.2f;
        [Tooltip("呼吸音を出す間隔 (秒)")]
        [SerializeField] float breathInterval = 0.8f;

        [Header("心拍")]
        [Tooltip("怪物がこれより遠ければ、落ち着いている")]
        [SerializeField] float calmDistance = 15f;
        [Tooltip("怪物がこれより近ければ、一番緊張している")]
        [SerializeField] float panicDistance = 3f;
        [SerializeField] float calmHeartRate = 60f;
        [SerializeField] float panicHeartRate = 140f;

        /// <summary>息止めゲージ (0〜1)。</summary>
        public float Gauge { get; private set; } = 1f;

        /// <summary>今、息を止めているか。</summary>
        public bool IsHolding { get; private set; }

        /// <summary>咳き込んだ直後で、息を止められない間は true。</summary>
        public bool IsCoughing => Time.time < coughUntil;

        /// <summary>緊張の度合い (0: 落ち着いている 〜 1: 怪物がすぐそば)。</summary>
        public float Panic { get; private set; }

        /// <summary>心拍数 (1分あたり)。</summary>
        public float HeartRate => Mathf.Lerp(calmHeartRate, panicHeartRate, Panic);

        PlayerController player;
        MonsterAI[] monsters;
        InputAction holdAction;
        float nextBreathTime;
        float coughUntil;

        void Awake()
        {
            player = GetComponent<PlayerController>();
            holdAction = new InputAction("HoldBreath", InputActionType.Button, "<Keyboard>/space");
            holdAction.AddBinding("<Gamepad>/leftShoulder");
        }

        void OnEnable() { holdAction.Enable(); }
        void OnDisable() { holdAction.Disable(); }
        void OnDestroy() { holdAction.Dispose(); }

        void Start()
        {
            monsters = FindObjectsByType<MonsterAI>(FindObjectsSortMode.None);
        }

        void Update()
        {
            Panic = ComputePanic();

            IsHolding = player.InputEnabled && holdAction.IsPressed() && !IsCoughing && Gauge > 0f;

            if (IsHolding)
            {
                // 緊張しているほど、ゲージが速く減る
                Gauge -= Time.deltaTime / maxHoldSeconds * Mathf.Lerp(1f, panicDrainMultiplier, Panic);
                if (Gauge <= 0f)
                {
                    Gauge = 0f;
                    Cough();
                }
                return;
            }

            Gauge = Mathf.Min(1f, Gauge + recoverPerSecond * Time.deltaTime);

            if (Time.time >= nextBreathTime)
            {
                nextBreathTime = Time.time + breathInterval;
                float radius = Mathf.Lerp(calmBreathRadius, panicBreathRadius, Panic);
                // 音の出どころは足元ではなく口元 (高さ 1.5m)
                NoiseSystem.Emit(transform.position + Vector3.up * 1.5f, radius, NoiseType.Breath, gameObject);
            }
        }

        void Cough()
        {
            IsHolding = false;
            coughUntil = Time.time + coughRecoverSeconds;
            NoiseSystem.Emit(transform.position + Vector3.up * 1.5f, coughRadius, NoiseType.Cough, gameObject);
        }

        /// <summary>一番近い怪物との距離から、緊張の度合い (0〜1) を求める。</summary>
        float ComputePanic()
        {
            float nearest = float.MaxValue;
            foreach (MonsterAI monster in monsters)
            {
                if (monster == null || !monster.isActiveAndEnabled) continue;
                nearest = Mathf.Min(nearest, Vector3.Distance(monster.transform.position, transform.position));
            }
            // calmDistance で 0、panicDistance で 1 になる (その間はなめらかに変わる)
            return Mathf.InverseLerp(calmDistance, panicDistance, nearest);
        }
    }
}
