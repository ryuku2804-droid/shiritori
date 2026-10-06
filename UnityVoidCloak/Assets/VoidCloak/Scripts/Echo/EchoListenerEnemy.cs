using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// "Listener": a blind monk that hunts by sound only.
    ///
    /// - Wander: shuffles around its home.
    /// - Investigate: walks to where it heard a sound.
    /// - Chase: a loud or close sound makes it rush there.
    /// It never sees the knight - it only knows where the last sound came from. Standing
    /// still is the way to lose it. Its own footsteps send out small red echoes.
    /// When it reaches the knight, the knight is sent back to the start (combat comes later).
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoListenerEnemy : MonoBehaviour
    {
        enum State { Wander, Investigate, Chase }

        [SerializeField] private Material material = null;
        [SerializeField] private Transform player = null;

        [Header("Hearing")]
        [Tooltip("1 = hears a sound as far as its wave reaches. Lower = harder of hearing.")]
        [SerializeField, Range(0f, 2f)] private float hearing = 0.8f;
        [Tooltip("Sounds closer than this make it chase instead of just investigate.")]
        [SerializeField, Min(0f)] private float chaseDistance = 16f;
        [Tooltip("Seconds without new sounds before it gives up and wanders again.")]
        [SerializeField, Min(0f)] private float giveUpTime = 4f;

        [Header("Movement")]
        [SerializeField, Min(0f)] private float wanderRadius = 9f;
        [SerializeField, Min(0f)] private float wanderSpeed = 1.4f;
        [SerializeField, Min(0f)] private float investigateSpeed = 2.8f;
        [SerializeField, Min(0f)] private float chaseSpeed = 5.2f;
        [SerializeField, Min(1f)] private float turnSpeed = 220f;
        [SerializeField, Min(0.1f)] private float catchDistance = 2.6f;

        [Header("Footsteps")]
        [SerializeField, Min(0.1f)] private float stepLength = 1.3f;
        [SerializeField, Min(0f)] private float footstepEchoRadius = 7f;

        Mesh mesh;
        State state = State.Wander;
        Vector3 home;
        Vector3 target;
        float lastHeardTime = -100f;
        float waitUntil;
        float stepDistance;

        /// <summary>Used by the stage builder.</summary>
        public void Setup(Material newMaterial, Transform newPlayer)
        {
            material = newMaterial;
            player = newPlayer;
            BuildBody();
        }

        void OnEnable()
        {
            BuildBody();
            home = transform.position;
            target = home;
            EchoSystem.WaveEmitted += OnWave;
        }

        void OnDisable()
        {
            EchoSystem.WaveEmitted -= OnWave;
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == mesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(mesh);
            mesh = null;
        }

        void BuildBody()
        {
            var b = new EchoPointBuilder(7);
            EchoListenerBody.Build(b);
            mesh = EchoMeshUtil.Build(b, mesh, "Listener");
            GetComponent<MeshFilter>().sharedMesh = mesh;
            var r = GetComponent<MeshRenderer>();
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
        }

        void OnWave(EchoWave wave)
        {
            if (!Application.isPlaying || wave.source == EchoSource.Enemy) return;
            Vector3 d = wave.origin - transform.position;
            d.y = 0f;
            float distance = d.magnitude;
            if (distance > wave.radius * hearing) return;

            target = new Vector3(wave.origin.x, transform.position.y, wave.origin.z);
            lastHeardTime = Time.time;
            bool loud = wave.source == EchoSource.Strike || distance < chaseDistance;
            state = loud ? State.Chase : (state == State.Chase ? State.Chase : State.Investigate);
            waitUntil = 0f;
        }

        void Update()
        {
            if (!Application.isPlaying) return;
            float dt = Time.deltaTime;

            if (state != State.Wander && Time.time - lastHeardTime > giveUpTime)
            {
                state = State.Wander;
                PickWanderTarget();
            }

            float speed = state == State.Chase ? chaseSpeed : state == State.Investigate ? investigateSpeed : wanderSpeed;
            Vector3 to = target - transform.position;
            to.y = 0f;
            float dist = to.magnitude;

            if (dist < 1.2f)
            {
                // arrived: listen for a while, then pick a new spot when wandering
                if (state == State.Wander)
                {
                    if (waitUntil <= 0f) waitUntil = Time.time + Random.Range(1f, 3f);
                    if (Time.time > waitUntil) { PickWanderTarget(); waitUntil = 0f; }
                }
            }
            else
            {
                Vector3 dir = Steer(to / dist);
                Quaternion look = Quaternion.LookRotation(dir, Vector3.up);
                transform.rotation = Quaternion.RotateTowards(transform.rotation, look, turnSpeed * dt);
                Vector3 step = transform.forward * (speed * dt);
                transform.position += step;
                Footsteps(step.magnitude);
            }

            if (player != null)
            {
                Vector3 toPlayer = player.position - transform.position;
                toPlayer.y = 0f;
                if (toPlayer.magnitude < catchDistance) Caught();
            }
        }

        void Caught()
        {
            var echoPlayer = player.GetComponent<EchoPlayer>();
            if (echoPlayer != null) echoPlayer.Respawn();
            EchoSystem.Emit(transform.position + Vector3.up * 0.2f, 20f, EchoSource.Enemy, 1.2f);
            transform.position = home;
            state = State.Wander;
            PickWanderTarget();
        }

        void Footsteps(float moved)
        {
            stepDistance += moved;
            if (stepDistance < stepLength) return;
            stepDistance = 0f;
            float loudness = state == State.Chase ? 1.5f : 1f;
            EchoSystem.Emit(transform.position + Vector3.up * 0.2f, footstepEchoRadius * loudness, EchoSource.Enemy, 0.9f);
        }

        void PickWanderTarget()
        {
            Vector2 r = Random.insideUnitCircle * wanderRadius;
            target = home + new Vector3(r.x, 0f, r.y);
        }

        /// <summary>Simple obstacle avoidance against the building colliders.</summary>
        Vector3 Steer(Vector3 desired)
        {
            float[] angles = { 0f, 35f, -35f, 70f, -70f, 110f, -110f, 160f };
            foreach (float a in angles)
            {
                Vector3 dir = Quaternion.Euler(0f, a, 0f) * desired;
                if (!Blocked(dir)) return dir;
            }
            return desired;
        }

        bool Blocked(Vector3 dir)
        {
            RaycastHit hit;
            Vector3 origin = transform.position + Vector3.up * 1.5f;
            if (!Physics.SphereCast(origin, 0.8f, dir, out hit, 2.2f, ~0, QueryTriggerInteraction.Ignore)) return false;
            return hit.collider.GetComponentInParent<EchoKitPiece>() != null;
        }
    }
}
