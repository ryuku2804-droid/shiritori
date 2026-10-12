using System;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.SceneManagement;

namespace BlindSpot
{
    /// <summary>怪物の状態。</summary>
    public enum MonsterState
    {
        Patrol,      // 巡回ポイントを順に回る
        Investigate, // 音がした場所へ調べに行き、着いたら見回す
        Chase,       // 大きな音・近くの音を追いかける
        Caught,      // プレイヤーを捕まえた
    }

    /// <summary>
    /// 目が見えない (という設定の) 怪物の AI。音だけを頼りに動く。
    /// 巡回 → 調査 (音の場所へ) → 追跡 (大きな音・至近距離) → 捕獲。
    /// 見失うと、最後に音がした場所を調べに行く。
    /// </summary>
    [RequireComponent(typeof(NavMeshAgent))]
    public class MonsterAI : MonoBehaviour
    {
        [Header("巡回")]
        [SerializeField] Transform[] patrolPoints;
        [SerializeField] float patrolSpeed = 1.5f;
        [Tooltip("巡回ポイントに着いてから次へ向かうまでの秒数")]
        [SerializeField] float patrolWait = 2f;

        [Header("聴覚")]
        [Tooltip("1 で音の届く距離どおり。大きいほど耳がいい")]
        [SerializeField] float hearingMultiplier = 1f;
        [Tooltip("届く距離がこれ以上の大きな音を聞いたら、すぐ追跡する (走りの足音は 12m)")]
        [SerializeField] float loudNoiseRadius = 10f;
        [Tooltip("この距離より近くで音がしたら、すぐ追跡する")]
        [SerializeField] float closeNoiseDistance = 3f;

        [Header("調査")]
        [SerializeField] float investigateSpeed = 2.5f;
        [Tooltip("音の場所に着いてから見回す秒数")]
        [SerializeField] float lookAroundTime = 4f;

        [Header("追跡")]
        [SerializeField] float chaseSpeed = 4f;
        [Tooltip("この秒数、新しい音が聞こえなければ追跡をやめ、最後の音の場所を調べる")]
        [SerializeField] float loseInterestTime = 4f;

        [Header("捕獲")]
        [SerializeField] float catchDistance = 1.1f;
        [Tooltip("隠れているプレイヤーでも、この秒数以内にすぐそばで音を聞いていれば見つけて捕まえる")]
        [SerializeField] float foundHiddenTime = 1f;
        [Tooltip("捕まえてからシーンを読み込み直すまでの秒数")]
        [SerializeField] float restartDelay = 2.5f;

        /// <summary>現在の状態。</summary>
        public MonsterState State { get; private set; } = MonsterState.Patrol;

        /// <summary>状態が変わるたびに呼ばれる (クリック音や UI が使う)。</summary>
        public event Action<MonsterState> OnStateChanged;

        /// <summary>最後に聞いた音の位置。</summary>
        public Vector3 LastNoisePosition { get; private set; }

        NavMeshAgent agent;
        PlayerController player;
        int patrolIndex;
        float timer;         // 待ち時間・見回し時間・捕獲後の時間に使う
        float lastHeardTime;
        bool lastNoiseFromPlayer; // 最後に聞いた音が、プレイヤー自身の出した音か

        void Awake()
        {
            agent = GetComponent<NavMeshAgent>();
        }

        void OnEnable()
        {
            NoiseSystem.OnNoise += HandleNoise;
        }

        void OnDisable()
        {
            NoiseSystem.OnNoise -= HandleNoise;
        }

        void Start()
        {
            player = FindFirstObjectByType<PlayerController>();

            // NavMesh は RuntimeNavMesh の Awake で作られる。Start の時点ならもうあるので、ここで有効にする
            agent.enabled = true;
            if (!agent.isOnNavMesh)
            {
                Debug.LogWarning("[BlindSpot] 怪物が NavMesh の上にいません。シーンに RuntimeNavMesh があるか確認してください。");
                enabled = false;
                return;
            }
            EnterPatrol();
        }

        void Update()
        {
            switch (State)
            {
                case MonsterState.Patrol: UpdatePatrol(); break;
                case MonsterState.Investigate: UpdateInvestigate(); break;
                case MonsterState.Chase: UpdateChase(); break;
                case MonsterState.Caught: UpdateCaught(); break;
            }

            if (State != MonsterState.Caught && player != null &&
                FlatDistance(player.transform.position) <= catchDistance && CanCatchPlayer())
            {
                Catch();
            }
        }

        // ---------------- 音を聞く ----------------

        void HandleNoise(NoiseEvent e)
        {
            if (State == MonsterState.Caught || e.Source == gameObject) return;
            if (!e.IsAudibleAt(transform.position, hearingMultiplier)) return;

            LastNoisePosition = e.Position;
            lastHeardTime = Time.time;
            lastNoiseFromPlayer = player != null && e.Source == player.gameObject;

            bool loud = e.Radius >= loudNoiseRadius;
            bool close = FlatDistance(e.Position) <= closeNoiseDistance;
            if (loud || close || State == MonsterState.Chase) EnterChase();
            else EnterInvestigate(e.Position);
        }

        // ---------------- 状態ごとの処理 ----------------

        void EnterPatrol()
        {
            SetState(MonsterState.Patrol);
            agent.speed = patrolSpeed;
            timer = 0f;
            if (patrolPoints != null && patrolPoints.Length > 0) agent.SetDestination(patrolPoints[patrolIndex].position);
        }

        void UpdatePatrol()
        {
            if (patrolPoints == null || patrolPoints.Length == 0 || !Arrived()) return;

            timer += Time.deltaTime;
            if (timer < patrolWait) return;
            timer = 0f;
            patrolIndex = (patrolIndex + 1) % patrolPoints.Length; // 最後まで行ったら最初に戻る
            agent.SetDestination(patrolPoints[patrolIndex].position);
        }

        void EnterInvestigate(Vector3 position)
        {
            SetState(MonsterState.Investigate);
            agent.speed = investigateSpeed;
            timer = 0f;
            agent.SetDestination(position);
        }

        void UpdateInvestigate()
        {
            if (!Arrived()) return;

            // 着いたらその場で見回す (首を振るかわりに体ごと回る)
            transform.Rotate(0f, 90f * Time.deltaTime, 0f);
            timer += Time.deltaTime;
            if (timer >= lookAroundTime) EnterPatrol();
        }

        void EnterChase()
        {
            SetState(MonsterState.Chase);
            agent.speed = chaseSpeed;
        }

        void UpdateChase()
        {
            // 追いかける先は、プレイヤーではなく「最後に音がした場所」
            // (すぐそばにいても、息を止めて静かにしていれば見失う)
            agent.SetDestination(LastNoisePosition);

            if (Time.time - lastHeardTime > loseInterestTime) EnterInvestigate(LastNoisePosition);
        }

        /// <summary>
        /// 捕まえられるか。隠れていなければ捕まえられる。
        /// 隠れていても、追跡中にすぐそばでプレイヤーの音 (呼吸など) を聞いた直後なら見つかる。
        /// </summary>
        bool CanCatchPlayer()
        {
            if (!player.IsHidden) return true;
            return State == MonsterState.Chase && lastNoiseFromPlayer && Time.time - lastHeardTime <= foundHiddenTime;
        }

        void Catch()
        {
            SetState(MonsterState.Caught);
            agent.isStopped = true;
            timer = 0f;
            player.InputEnabled = false;
            Vector3 look = player.transform.position;
            look.y = transform.position.y;
            transform.LookAt(look);
            Debug.Log("[BlindSpot] 捕まった");
        }

        void UpdateCaught()
        {
            // 本番の演出とセーブはステップ7で作る。今はシーンを読み込み直すだけ
            timer += Time.deltaTime;
            if (timer < restartDelay) return;
            int index = SceneManager.GetActiveScene().buildIndex;
            if (index >= 0) SceneManager.LoadScene(index);
            else Debug.LogWarning("[BlindSpot] シーンがビルド設定に無いため、読み込み直せません。");
            enabled = false;
        }

        // ---------------- 補助 ----------------

        void SetState(MonsterState next)
        {
            if (State == next) return;
            State = next;
            OnStateChanged?.Invoke(next);
        }

        /// <summary>目的地に着いたか。</summary>
        bool Arrived()
        {
            return !agent.pathPending && agent.remainingDistance <= agent.stoppingDistance + 0.1f;
        }

        /// <summary>高さを無視した距離。</summary>
        float FlatDistance(Vector3 target)
        {
            Vector3 d = target - transform.position;
            d.y = 0f;
            return d.magnitude;
        }

        void OnDrawGizmosSelected()
        {
            if (patrolPoints != null)
            {
                Gizmos.color = Color.yellow;
                for (int i = 0; i < patrolPoints.Length; i++)
                {
                    if (patrolPoints[i] == null) continue;
                    Gizmos.DrawWireSphere(patrolPoints[i].position, 0.3f);
                    Transform next = patrolPoints[(i + 1) % patrolPoints.Length];
                    if (next != null) Gizmos.DrawLine(patrolPoints[i].position, next.position);
                }
            }
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(LastNoisePosition, 0.4f);
            Gizmos.DrawWireSphere(transform.position, catchDistance);
        }
    }
}
