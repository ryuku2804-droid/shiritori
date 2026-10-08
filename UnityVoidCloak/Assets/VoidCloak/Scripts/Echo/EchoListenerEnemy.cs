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
    /// - Attack: when the knight is in reach it draws breath, then SHRIEKS: a red ring of sound
    ///   spreads from it (<see cref="EchoShockwaves"/>). The ring kills. Parry (Q / LB) as the
    ///   front reaches the knight to throw it back (the Listener is hurt and stunned), or keep
    ///   a pillar or wall between the two.
    /// It never sees the knight - it only knows where the last sound came from. Standing
    /// still is the way to lose it. Its footsteps are heard (3D sound), but make no echo:
    /// it is only seen when the knight's own echo passes over it.
    /// The sound of a shrine bell makes it flee. When the knight falls, it goes back home.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoListenerEnemy : MonoBehaviour, IEchoEnemy
    {
        enum State { Wander, Investigate, Chase, WindUp, Recover, Stunned, Flee, Dead }

        static readonly List<EchoListenerEnemy> all = new List<EchoListenerEnemy>();

        /// <summary>Every Listener in the scene (used by the knight's attacks).</summary>
        public static IReadOnlyList<EchoListenerEnemy> All { get { return all; } }

        [SerializeField] private Material material = null;
        [SerializeField] private Transform player = null;

        [Header("Health")]
        [SerializeField, Min(0.1f)] private float maxHealth = 3f;
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

        [Header("Attack (shriek ring)")]
        [Tooltip("It shrieks when the knight is this close.")]
        [SerializeField, Min(0.1f)] private float attackRange = 7f;
        [Tooltip("Drawing breath before the shriek (seconds) - a rasping sound is the only warning.")]
        [SerializeField, Min(0.05f)] private float windUpTime = 0.7f;
        [SerializeField, Min(0f)] private float recoverTime = 1.4f;
        [Tooltip("How far the shriek ring reaches.")]
        [SerializeField, Min(1f)] private float ringRadius = 11f;
        [Tooltip("How fast the ring spreads (units per second). Slow enough to see it coming.")]
        [SerializeField, Min(1f)] private float ringSpeed = 9f;

        [Header("Footsteps")]
        [Tooltip("Seconds between footstep echoes while wandering (a little random).")]
        [SerializeField, Min(0.1f)] private float wanderEchoInterval = 3.5f;
        [Tooltip("Seconds between footstep echoes while investigating a sound.")]
        [SerializeField, Min(0.1f)] private float investigateEchoInterval = 2.2f;
        [Tooltip("Seconds between footstep echoes while chasing.")]
        [SerializeField, Min(0.1f)] private float chaseEchoInterval = 1.1f;
        [Tooltip("0 = its footsteps make no echo at all (only heard). Larger = it shows itself as it walks.")]
        [SerializeField, Min(0f)] private float footstepEchoRadius = 0f;

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
        Quaternion homeRotation;

        public bool IsAlive { get { return state != State.Dead; } }
        public Vector3 Position { get { return transform.position; } }

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
            homeRotation = transform.rotation;
            target = home;
            health = maxHealth;
            state = State.Wander;
            EchoSystem.WaveEmitted += OnWave;
            EchoGame.PlayerDied += ResetToStart;
            if (!all.Contains(this)) all.Add(this);
            EchoTargets.Register(this);
        }

        void OnDisable()
        {
            all.Remove(this);
            EchoTargets.Unregister(this);
            EchoSystem.WaveEmitted -= OnWave;
            EchoGame.PlayerDied -= ResetToStart;
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
            if (!Application.isPlaying || wave.source == EchoSource.Enemy || wave.source == EchoSource.Resonance) return;
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
            EchoSystem.Noise(transform.position, 18f);   // the other Listeners hear the fight
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

            // the knight is in reach: draw breath (a rasp - the only warning), then shriek
            if (state == State.Chase && player != null && FlatDistance(player.position) < attackRange)
            {
                state = State.WindUp;
                stateUntil = Time.time + windUpTime;
                EchoAudio.Play(EchoSound.ListenerYelp, transform.position + Vector3.up * 3f, 0.55f, 0.55f);
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

        /// <summary>The shriek: a ring of sound that kills (see EchoShockwaves).</summary>
        void LandBlow()
        {
            state = State.Recover;
            stateUntil = Time.time + recoverTime;
            Vector3 mouth = transform.position + Vector3.up * 3f;
            EchoShockwaves.Fire(new Vector3(mouth.x, transform.position.y + 0.3f, mouth.z), this, ringRadius, ringSpeed);
            EchoAudio.Play(EchoSound.ListenerShriek, mouth, 1f);
        }

        /// <summary>The knight fell: back home, whole again, unaware.</summary>
        void ResetToStart()
        {
            transform.SetPositionAndRotation(home, homeRotation);
            health = maxHealth;
            state = State.Wander;
            knockback = Vector3.zero;
            lastHeardTime = -100f;
            waitUntil = 0f;
            target = home;
            GetComponent<MeshRenderer>().enabled = true;
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
            if (footstepEchoRadius <= 0f || Time.time < nextStepEchoTime) return;
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
