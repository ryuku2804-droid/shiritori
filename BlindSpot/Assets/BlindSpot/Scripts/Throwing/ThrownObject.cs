using UnityEngine;

namespace BlindSpot
{
    /// <summary>
    /// 投げた物。何かにぶつかると音を出す。止まったら、また拾える物に戻る。
    /// </summary>
    [RequireComponent(typeof(Rigidbody))]
    public class ThrownObject : MonoBehaviour
    {
        [SerializeField] ThrowableType type;
        [Tooltip("この速さ以上でぶつかったときだけ音を出す (m/秒)")]
        [SerializeField] float minImpactSpeed = 1.5f;
        [Tooltip("缶がぶつかる音を出す最短の間隔 (秒)")]
        [SerializeField] float rattleInterval = 0.25f;
        [Tooltip("缶が転がっている間の音の届く距離 (m)")]
        [SerializeField] float rollingNoiseRadius = 2.5f;
        [Tooltip("止まってから、拾える物に戻るまでの秒数")]
        [SerializeField] float restTimeToPickup = 1f;

        Rigidbody body;
        bool landed;
        float lastNoiseTime = -10f;
        float restTimer;

        public void Setup(ThrowableType newType)
        {
            type = newType;
        }

        void Awake()
        {
            body = GetComponent<Rigidbody>();
        }

        void OnCollisionEnter(Collision collision)
        {
            float speed = collision.relativeVelocity.magnitude;
            if (speed < minImpactSpeed) return;

            if (ThrowableDefs.Rattles(type))
            {
                // 缶: ぶつかるたびに鳴る。強くぶつかるほど大きい
                if (Time.time - lastNoiseTime < rattleInterval) return;
                float radius = ThrowableDefs.NoiseRadius(type) * Mathf.Clamp01(speed / 8f);
                Emit(Mathf.Max(radius, rollingNoiseRadius));
            }
            else if (!landed)
            {
                // 石と瓶: 最初にぶつかったときだけ鳴る
                Emit(ThrowableDefs.NoiseRadius(type));
                if (ThrowableDefs.Breaks(type))
                {
                    Destroy(gameObject); // 瓶は割れて無くなる
                    return;
                }
            }
            landed = true;
        }

        void OnCollisionStay(Collision collision)
        {
            // 缶が床を転がっている間も、少しずつ音が続く
            if (!ThrowableDefs.Rattles(type)) return;
            if (body.linearVelocity.magnitude < 0.6f) return;
            if (Time.time - lastNoiseTime < 0.5f) return;
            Emit(rollingNoiseRadius);
        }

        void Update()
        {
            if (!landed) return;

            bool still = body.linearVelocity.sqrMagnitude < 0.01f && body.angularVelocity.sqrMagnitude < 0.05f;
            restTimer = still ? restTimer + Time.deltaTime : 0f;
            if (restTimer >= restTimeToPickup) BecomePickup();
        }

        void Emit(float radius)
        {
            lastNoiseTime = Time.time;
            NoiseSystem.Emit(transform.position, radius, ThrowableDefs.NoiseKind(type), gameObject);
        }

        /// <summary>止まったら、また拾える物にする。</summary>
        void BecomePickup()
        {
            gameObject.AddComponent<ItemPickup>().Setup(type);
            body.isKinematic = true; // もう転がらない
            Destroy(this);           // このスクリプトだけ外す
        }
    }
}
