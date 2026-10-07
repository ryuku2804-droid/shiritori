using System.Collections.Generic;
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
    /// - Attack: when it is close it shrieks (a red echo - the warning), then lashes out.
    ///   Parry (Q / LB) right before the blow to stun it.
    /// It never sees the knight - it only knows where the last sound came from. Standing
    /// still is the way to lose it. Its own footsteps send out small red echoes.
    /// The sound of a shrine bell makes it flee.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoListenerEnemy : MonoBehaviour
    {
        enum State { Wander, Investigate, Chase, WindUp, Recover, Stunned, Flee, Dead }

        static readonly List<EchoListenerEnemy> all = new List<EchoListenerEnemy>();

        /// <summary>Every Listener in the scene (used by the knight's attacks).</summary>
        public static IReadOnlyList<EchoListenerEnemy> All { get { return all; } }

        [SerializeField] private Material material = null;
        [SerializeField] private Transform player = null;

        [Header("Health")]
        [SerializeField, Min(0.1f)] private float maxHealth = 4f;
        [Tooltip("Seconds before a defeated Listener rises again (0 = never).")]
        [SerializeField, Min(0f)] private float respawnTime = 0f;

        [Header("Hearing")]
        [Tooltip("1 = hears a sound as far as its wave reaches. Lower = harder of hearing.")]
        [SerializeField, Range(0f, 2f)] private float hearing = 0.8f;
        [Tooltip("Sounds closer than this make it chase instead of just investigate.")]
        [SerializeField, Min(0f)] private float chaseDistance = 16f;
        [Tooltip("Seconds without new sounds before it gives up and wanders again.")]
        [SerializeField, Min(0f)] private float giveUpTime = 4f;
        [Tooltip("How long it runs from the sound of a shrine bell (seconds).")]
        [SerializeField, Min(0f)] private float fleeTime = 5f;

        [Header("Movement")]
        [SerializeField, Min(0f)] private float wanderRadius = 9f;
        [SerializeField, Min(0f)] private float wanderSpeed = 1.4f;
        [SerializeField, Min(0f)] private float investigateSpeed = 2.8f;
        [SerializeField, Min(0f)] private float chaseSpeed = 5.2f;
        [SerializeField, Min(1f)] private float turnSpeed = 220f;

        [Header("Attack")]
        [SerializeField, Min(0.1f)] private float attackRange = 3.6f;
        [Tooltip("Warning time between the shriek and the blow (seconds).")]
        [SerializeField, Min(0.05f)] private float windUpTime = 0.75f;
        [SerializeField, Min(0f)] private float recoverTime = 0.9f;
        [SerializeField, Min(0)] private int attackDamage = 1;

        [Header("Footsteps")]
        [Tooltip("Seconds between footstep echoes while wandering (a little random).")]
        [SerializeField, Min(0.1f)] private float wanderEchoInterval = 3.5f;
        [Tooltip("Seconds between footstep echoes while investigating a sound.")]
        [SerializeField, Min(0.1f)] private float investigateEchoInterval = 2.2f;
        [Tooltip("Seconds between footstep echoes while chasing.")]
        [SerializeField, Min(0.1f)] private float chaseEchoInterval = 1.1f;
        [SerializeField, Min(0f)] private float footstepEchoRadius = 7f;

        Mesh mesh;
        State state = State.Wander;
        Vector3 home;
        Vector3 target;
        float lastHeardTime = -100f;
        float waitUntil;
        float nextStepEchoTime;
        float nextStepSoundTime;
        float health;
        float stateUntil;
        Vector3 knockback;

        public bool IsAlive { get { return state != State.Dead; } }

        /// <summary>Used by the stage builder.</summary>
        public void Setup(Material newMaterial, Transform newPlayer)
        {
            material = newMaterial;
            player = newPlayer;
            BuildBody();
        }

        /// <summary>Used by the stage builder.</summary>
        public void Setup(Material newMaterial, Transform newPlayer, float newWanderRadius)
        {
            wanderRadius = newWanderRadius;
            Setup(newMaterial, newPlayer);
        }

        void OnEnable()
        {
            BuildBody();
            home = transform.position;
            target = home;
            health = maxHealth;
            state = State.Wander;
            EchoSystem.WaveEmitted += OnWave;
            if (!all.Contains(this)) all.Add(this);
        }

        void OnDisable()
        {
            all.Remove(this);
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

        // ------------------------------------------------------------------ hearing

        void OnWave(EchoWave wave)
        {
            if (!Application.isPlaying || wave.source == EchoSource.Enemy) return;
            if (wave.source == EchoSource.Bell)
            {
                HearBell(wave);
                return;
            }
            if (state == State.Flee) return;
            if (state == State.Dead || state == State.Stunned || state == State.WindUp || state == State.Recover) return;
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

        /// <summary>A shrine bell: it cannot stand the sound and runs away from it.</summary>
        void HearBell(EchoWave wave)
        {
            if (state == State.Dead) return;
            Vector3 away = transform.position - wave.origin;
            away.y = 0f;
            if (away.magnitude > wave.radius) return;
            if (away.sqrMagnitude < 1e-4f) away = -transform.forward;
            target = transform.position + away.normalized * 14f;
            if (state != State.Flee) EchoAudio.Play(EchoSound.ListenerYelp, transform.position + Vector3.up * 3f, 0.8f, 1f, Random.Range(0.2f, 0.5f));
            state = State.Flee;
            stateUntil = Time.time + fleeTime;
            waitUntil = 0f;
        }

        // ------------------------------------------------------------------ being hit

        /// <summary>Damage from the knight's sword.</summary>
        public void TakeHit(float damage, Vector3 from)
        {
            if (state == State.Dead) return;
            if (state == State.Stunned) damage *= 2f;   // punish a parried enemy
            health -= damage;

            Vector3 away = transform.position - from;
            away.y = 0f;
            knockback = away.sqrMagnitude > 1e-4f ? away.normalized * (2.5f + damage) : Vector3.zero;

            // the hit itself is loud: the knight sees what it struck
            EchoSystem.Emit(transform.position + Vector3.up * 1.5f, 10f + damage * 4f, EchoSource.Enemy, 1.3f);
            EchoAudio.Play(EchoSound.Hit, transform.position + Vector3.up * 1.8f, 0.9f);

            if (health <= 0f)
            {
                Die();
                return;
            }
            // it now knows exactly where the knight is
            target = new Vector3(from.x, transform.position.y, from.z);
            lastHeardTime = Time.time;
            if (state != State.Stunned)
            {
                state = State.Recover;
                stateUntil = Time.time + 0.35f;   // short flinch
            }
        }

        /// <summary>Called when the knight parries this Listener's blow.</summary>
        public void Stun(float seconds)
        {
            if (state == State.Dead) return;
            state = State.Stunned;
            stateUntil = Time.time + seconds;
        }

        void Die()
        {
            state = State.Dead;
            EchoSystem.Emit(transform.position + Vector3.up * 1.5f, 24f, EchoSource.Enemy, 1.5f);
            EchoAudio.Play(EchoSound.ListenerDeath, transform.position + Vector3.up * 3f, 1f, 1f, 0.15f);
            GetComponent<MeshRenderer>().enabled = false;
            stateUntil = respawnTime > 0f ? Time.time + respawnTime : float.MaxValue;
        }

        // ------------------------------------------------------------------ behaviour

        void Update()
        {
            if (!Application.isPlaying) return;
            float dt = Time.deltaTime;

            // knockback slides it back a little after a hit
            if (knockback.sqrMagnitude > 1e-4f)
            {
                transform.position += knockback * dt;
                knockback = Vector3.MoveTowards(knockback, Vector3.zero, 12f * dt);
            }

            switch (state)
            {
                case State.Dead:
                    if (Time.time >= stateUntil) Revive();
                    return;
                case State.Stunned:
                case State.Recover:
                    if (Time.time >= stateUntil) state = State.Chase;
                    return;
                case State.WindUp:
                    FacePlayer(dt);
                    if (Time.time >= stateUntil) LandBlow();
                    return;
                case State.Flee:
                    if (Time.time >= stateUntil)
                    {
                        state = State.Wander;
                        PickWanderTarget();
                    }
                    else Move(dt);
                    return;
            }

            if (state != State.Wander && Time.time - lastHeardTime > giveUpTime)
            {
                state = State.Wander;
                PickWanderTarget();
            }

            // close enough to the knight: shriek, then strike
            if (state == State.Chase && player != null && FlatDistance(player.position) < attackRange)
            {
                state = State.WindUp;
                stateUntil = Time.time + windUpTime;
                EchoSystem.Emit(transform.position + Vector3.up * 3f, 14f, EchoSource.Enemy, 1.2f);
                EchoAudio.Play(EchoSound.ListenerShriek, transform.position + Vector3.up * 3f, 1f);
                return;
            }

            Move(dt);
        }

        void Move(float dt)
        {
            float speed = state == State.Chase || state == State.Flee ? chaseSpeed : state == State.Investigate ? investigateSpeed : wanderSpeed;
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
                return;
            }

            Vector3 dir = Steer(to / dist);
            Quaternion look = Quaternion.LookRotation(dir, Vector3.up);
            transform.rotation = Quaternion.RotateTowards(transform.rotation, look, turnSpeed * dt);
            Vector3 step = transform.forward * (speed * dt);
            transform.position += step;
            Footsteps(step.magnitude);
        }

        void LandBlow()
        {
            state = State.Recover;
            stateUntil = Time.time + recoverTime;
            if (player == null) return;

            Vector3 to = player.position - transform.position;
            to.y = 0f;
            bool inReach = to.magnitude < attackRange + 0.8f && Vector3.Angle(transform.forward, to) < 70f;
            if (!inReach) return;

            var combat = player.GetComponent<EchoCombat>();
            if (combat != null)
            {
                combat.ReceiveBlow(attackDamage, this);
            }
            else
            {
                var echoPlayer = player.GetComponent<EchoPlayer>();
                if (echoPlayer != null) echoPlayer.Respawn();
            }
        }

        void FacePlayer(float dt)
        {
            if (player == null) return;
            Vector3 to = player.position - transform.position;
            to.y = 0f;
            if (to.sqrMagnitude < 1e-4f) return;
            transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(to, Vector3.up), turnSpeed * 0.5f * dt);
        }

        void Revive()
        {
            transform.position = home;
            health = maxHealth;
            state = State.Wander;
            GetComponent<MeshRenderer>().enabled = true;
            PickWanderTarget();
        }

        float FlatDistance(Vector3 p)
        {
            Vector3 d = p - transform.position;
            d.y = 0f;
            return d.magnitude;
        }

        void Footsteps(float moved)
        {
            if (moved <= 0f) return;
            // the shuffling is always audible (3D sound tells where it is)...
            if (Time.time >= nextStepSoundTime)
            {
                float soundInterval = state == State.Chase ? 0.38f : state == State.Investigate ? 0.65f : 0.9f;
                nextStepSoundTime = Time.time + soundInterval * Random.Range(0.85f, 1.15f);
                EchoAudio.Play(EchoSound.ListenerStep, transform.position + Vector3.up * 0.3f, state == State.Chase ? 0.85f : 0.55f);
            }
            // ...but it only shows up as an echo now and then
            if (Time.time < nextStepEchoTime) return;
            float interval = state == State.Chase ? chaseEchoInterval : state == State.Investigate ? investigateEchoInterval : wanderEchoInterval;
            nextStepEchoTime = Time.time + interval * Random.Range(0.8f, 1.25f);   // uneven, so it is not a steady beat
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
            // anything solid except the knight blocks the way
            return hit.collider.GetComponentInParent<EchoPlayer>() == null;
        }
    }
}
