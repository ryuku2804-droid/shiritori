using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// 「抜け殻の鎧」(Hollow Armor): the empty armour of a fallen bell keeper, still walking its old round.
    ///
    /// - It sends out NO echoes of its own while it walks. Only the knight's waves show it.
    ///   The creak of its metal is always audible, so the ears tell where it is.
    /// - Patrol: walks its route slowly, back and forth.
    /// - It cannot hear footsteps. It feels the knight only when he comes close (in front, or
    ///   very close behind), and feels the floor shake from running and bell strikes nearby.
    /// - Pursue: slower than a walking knight, but it does not give up quickly.
    /// - Attack: a slow, heavy two-handed blow. The only warning is the scrape of metal
    ///   as it raises the sword - no red echo. Parry (Q / LB) on the scrape's end.
    ///   The blow hits the floor hard and that DOES send out a red echo.
    /// - A shrine bell makes it stop and stand still for a while (it was once a bell keeper).
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoHollowArmorEnemy : MonoBehaviour, IEchoEnemy
    {
        enum State { Patrol, Investigate, Pursue, WindUp, Recover, Stunned, Frozen, Dead }

        [SerializeField] private Material material = null;
        [SerializeField] private Transform player = null;
        [Tooltip("Patrol points in world space. It walks them back and forth. Empty = stands guard where it is.")]
        [SerializeField] private Vector3[] route = new Vector3[0];

        [Header("Health")]
        [SerializeField, Min(0.1f)] private float maxHealth = 6f;
        [Tooltip("Seconds before a destroyed armour stands up again (0 = never).")]
        [SerializeField, Min(0f)] private float respawnTime = 0f;

        [Header("Senses")]
        [Tooltip("It feels the knight inside this distance in front of it.")]
        [SerializeField, Min(0f)] private float senseRadius = 5f;
        [Tooltip("Width of the 'front' (degrees).")]
        [SerializeField, Range(0f, 360f)] private float senseAngle = 140f;
        [Tooltip("It feels the knight this close even behind it.")]
        [SerializeField, Min(0f)] private float senseBehind = 2.5f;
        [Tooltip("Share of a wave's radius at which it feels the floor shake (running, bell strikes). Walking is too soft.")]
        [SerializeField, Range(0f, 1f)] private float vibrationSense = 0.4f;
        [Tooltip("Player waves smaller than this are too soft to feel (walking).")]
        [SerializeField, Min(0f)] private float softWaveRadius = 15f;
        [Tooltip("Seconds without feeling the knight before it walks back to its route.")]
        [SerializeField, Min(0f)] private float loseTime = 5f;
        [Tooltip("How long a shrine bell holds it still (seconds).")]
        [SerializeField, Min(0f)] private float freezeTime = 6f;

        [Header("Movement")]
        [SerializeField, Min(0f)] private float patrolSpeed = 1.1f;
        [SerializeField, Min(0f)] private float investigateSpeed = 2.2f;
        [Tooltip("Keep this below the knight's walking speed (3.2) so walking away works.")]
        [SerializeField, Min(0f)] private float pursueSpeed = 2.9f;
        [SerializeField, Min(1f)] private float turnSpeed = 120f;

        [Header("Attack")]
        [SerializeField, Min(0.1f)] private float attackRange = 3.8f;
        [Tooltip("Time from the metal scrape to the blow (seconds).")]
        [SerializeField, Min(0.05f)] private float windUpTime = 0.95f;
        [SerializeField, Min(0f)] private float recoverTime = 1.5f;
        [SerializeField, Min(0)] private int attackDamage = 2;
        [Tooltip("Echo of the sword hitting the floor.")]
        [SerializeField, Min(0f)] private float blowEchoRadius = 9f;

        Mesh mesh;
        State state = State.Patrol;
        Vector3 home;
        Vector3 target;
        int routeIndex;
        int routeDir = 1;
        float lastSenseTime = -100f;
        float waitUntil;
        float stateUntil;
        float nextStepTime;
        float health;
        Vector3 knockback;

        public bool IsAlive { get { return state != State.Dead; } }
        public Vector3 Position { get { return transform.position; } }

        /// <summary>Used by the stage builder.</summary>
        public void Setup(Material newMaterial, Transform newPlayer, Vector3[] newRoute)
        {
            material = newMaterial;
            player = newPlayer;
            route = newRoute ?? new Vector3[0];
            BuildBody();
        }

        void OnEnable()
        {
            BuildBody();
            home = transform.position;
            health = maxHealth;
            state = State.Patrol;
            routeIndex = 0;
            target = RoutePoint(0);
            EchoSystem.WaveEmitted += OnWave;
            EchoTargets.Register(this);
        }

        void OnDisable()
        {
            EchoTargets.Unregister(this);
            EchoSystem.WaveEmitted -= OnWave;
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == mesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(mesh);
            mesh = null;
        }

        void BuildBody()
        {
            var b = new EchoPointBuilder(11);
            EchoHollowArmorBody.Build(b);
            mesh = EchoMeshUtil.Build(b, mesh, "Hollow Armor");
            GetComponent<MeshFilter>().sharedMesh = mesh;
            var r = GetComponent<MeshRenderer>();
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
        }

        Vector3 RoutePoint(int i)
        {
            if (route == null || route.Length == 0) return home;
            Vector3 p = route[Mathf.Clamp(i, 0, route.Length - 1)];
            return new Vector3(p.x, transform.position.y, p.z);
        }

        // ------------------------------------------------------------------ senses

        void OnWave(EchoWave wave)
        {
            if (!Application.isPlaying || wave.source == EchoSource.Enemy || wave.source == EchoSource.Resonance) return;
            if (state == State.Dead) return;
            if (wave.source == EchoSource.Bell)
            {
                if (FlatDistance(wave.origin) > wave.radius) return;
                // the bell it once guarded: it stops and listens
                if (state != State.Frozen) EchoAudio.Play(EchoSound.ArmorStep, transform.position + Vector3.up * 2f, 0.6f, 0.7f);
                state = State.Frozen;
                stateUntil = Time.time + freezeTime;
                return;
            }
            if (state == State.Frozen || state == State.Stunned || state == State.WindUp || state == State.Recover) return;
            // walking is too soft to feel through the floor; running and strikes are not
            if (wave.source == EchoSource.Player && wave.radius < softWaveRadius) return;
            if (FlatDistance(wave.origin) > wave.radius * vibrationSense) return;

            target = new Vector3(wave.origin.x, transform.position.y, wave.origin.z);
            lastSenseTime = Time.time;
            if (state != State.Pursue) state = State.Investigate;
            waitUntil = 0f;
        }

        bool FeelsPlayer()
        {
            if (player == null) return false;
            Vector3 to = player.position - transform.position;
            to.y = 0f;
            float d = to.magnitude;
            if (d < senseBehind) return true;
            return d < senseRadius && Vector3.Angle(transform.forward, to) < senseAngle * 0.5f;
        }

        // ------------------------------------------------------------------ being hit

        public void TakeHit(float damage, Vector3 from)
        {
            if (state == State.Dead) return;
            if (state == State.Stunned) damage *= 2f;
            health -= damage;

            Vector3 away = transform.position - from;
            away.y = 0f;
            knockback = away.sqrMagnitude > 1e-4f ? away.normalized * (1f + damage * 0.5f) : Vector3.zero;   // heavy: barely moves

            // steel on steel rings out
            EchoSystem.Emit(transform.position + Vector3.up * 2.5f, 12f + damage * 4f, EchoSource.Enemy, 1.3f);
            EchoAudio.Play(EchoSound.ArmorHit, transform.position + Vector3.up * 2.5f, 0.9f, Random.Range(0.92f, 1.08f));

            if (health <= 0f)
            {
                Die();
                return;
            }
            target = new Vector3(from.x, transform.position.y, from.z);
            lastSenseTime = Time.time;
            if (state != State.Stunned && state != State.WindUp)
            {
                // it does not flinch: it simply turns towards the blow
                state = State.Pursue;
            }
        }

        public void Stun(float seconds)
        {
            if (state == State.Dead) return;
            state = State.Stunned;
            stateUntil = Time.time + seconds;
        }

        void Die()
        {
            state = State.Dead;
            EchoSystem.Emit(transform.position + Vector3.up * 1.5f, 22f, EchoSource.Enemy, 1.5f);
            EchoAudio.Play(EchoSound.ArmorCollapse, transform.position + Vector3.up * 1.5f, 1f);
            GetComponent<MeshRenderer>().enabled = false;
            stateUntil = respawnTime > 0f ? Time.time + respawnTime : float.MaxValue;
        }

        void Revive()
        {
            transform.position = home;
            health = maxHealth;
            state = State.Patrol;
            routeIndex = 0;
            target = RoutePoint(0);
            GetComponent<MeshRenderer>().enabled = true;
        }

        // ------------------------------------------------------------------ behaviour

        void Update()
        {
            if (!Application.isPlaying) return;
            float dt = Time.deltaTime;

            if (knockback.sqrMagnitude > 1e-4f)
            {
                transform.position += knockback * dt;
                knockback = Vector3.MoveTowards(knockback, Vector3.zero, 10f * dt);
            }

            switch (state)
            {
                case State.Dead:
                    if (Time.time >= stateUntil) Revive();
                    return;
                case State.Frozen:
                    if (Time.time >= stateUntil) ReturnToRoute();
                    return;
                case State.Stunned:
                case State.Recover:
                    if (Time.time >= stateUntil) state = State.Pursue;
                    return;
                case State.WindUp:
                    FaceTowards(player != null ? player.position : target, 0.35f, dt);
                    if (Time.time >= stateUntil) LandBlow();
                    return;
            }

            if (FeelsPlayer())
            {
                if (state != State.Pursue) EchoAudio.Play(EchoSound.ArmorStep, transform.position + Vector3.up * 2.5f, 0.9f, 0.8f);   // a sharp turn of the helm
                state = State.Pursue;
                lastSenseTime = Time.time;
                target = new Vector3(player.position.x, transform.position.y, player.position.z);
            }
            else if (state != State.Patrol && Time.time - lastSenseTime > loseTime)
            {
                ReturnToRoute();
            }

            if (state == State.Pursue && player != null && FlatDistance(player.position) < attackRange)
            {
                state = State.WindUp;
                stateUntil = Time.time + windUpTime;
                // the only warning: metal scraping as the great sword rises. No echo.
                EchoAudio.Play(EchoSound.ArmorWindUp, transform.position + Vector3.up * 3f, 1f);
                return;
            }

            Move(dt);
        }

        void ReturnToRoute()
        {
            state = State.Patrol;
            // continue from the nearest patrol point
            if (route != null && route.Length > 0)
            {
                float best = float.MaxValue;
                for (int i = 0; i < route.Length; i++)
                {
                    float d = FlatDistance(route[i]);
                    if (d < best) { best = d; routeIndex = i; }
                }
            }
            target = RoutePoint(routeIndex);
            waitUntil = 0f;
        }

        void Move(float dt)
        {
            float speed = state == State.Pursue ? pursueSpeed : state == State.Investigate ? investigateSpeed : patrolSpeed;
            Vector3 to = target - transform.position;
            to.y = 0f;
            float dist = to.magnitude;

            if (dist < 1.0f)
            {
                if (state == State.Patrol)
                {
                    // stand at each point for a moment, then walk on
                    if (waitUntil <= 0f) waitUntil = Time.time + Random.Range(1.5f, 3f);
                    if (Time.time > waitUntil) { NextRoutePoint(); waitUntil = 0f; }
                }
                return;
            }

            Vector3 dir = Steer(to / dist);
            Quaternion look = Quaternion.LookRotation(dir, Vector3.up);
            transform.rotation = Quaternion.RotateTowards(transform.rotation, look, turnSpeed * dt);
            // heavy: it only walks once it roughly faces the way
            float facing = Mathf.Clamp01((Vector3.Dot(transform.forward, dir) - 0.3f) / 0.7f);
            Vector3 step = transform.forward * (speed * facing * dt);
            transform.position += step;
            Footsteps(step.magnitude);
        }

        void NextRoutePoint()
        {
            if (route == null || route.Length < 2) { target = RoutePoint(0); return; }
            if (routeIndex + routeDir < 0 || routeIndex + routeDir >= route.Length) routeDir = -routeDir;
            routeIndex += routeDir;
            target = RoutePoint(routeIndex);
        }

        void LandBlow()
        {
            state = State.Recover;
            stateUntil = Time.time + recoverTime;

            // the great sword hits the floor: loud, and it shows the armour for a moment
            Vector3 impact = transform.position + transform.forward * 2.6f + Vector3.up * 0.2f;
            EchoSystem.Emit(impact, blowEchoRadius, EchoSource.Enemy, 1.2f);
            EchoAudio.Play(EchoSound.SwordStrike, impact, 0.9f, 0.7f);

            if (player == null) return;
            Vector3 to = player.position - transform.position;
            to.y = 0f;
            bool inReach = to.magnitude < attackRange + 0.8f && Vector3.Angle(transform.forward, to) < 60f;
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

        void FaceTowards(Vector3 p, float speedScale, float dt)
        {
            Vector3 to = p - transform.position;
            to.y = 0f;
            if (to.sqrMagnitude < 1e-4f) return;
            transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(to, Vector3.up), turnSpeed * speedScale * dt);
        }

        float FlatDistance(Vector3 p)
        {
            Vector3 d = p - transform.position;
            d.y = 0f;
            return d.magnitude;
        }

        /// <summary>Metal creaks with every step - heard, never seen.</summary>
        void Footsteps(float moved)
        {
            if (moved <= 0f || Time.time < nextStepTime) return;
            float interval = state == State.Pursue ? 0.55f : state == State.Investigate ? 0.7f : 0.95f;
            nextStepTime = Time.time + interval * Random.Range(0.9f, 1.1f);
            EchoAudio.Play(EchoSound.ArmorStep, transform.position + Vector3.up * 1.5f, state == State.Pursue ? 0.8f : 0.55f, Random.Range(0.94f, 1.06f));
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
            return hit.collider.GetComponentInParent<EchoPlayer>() == null;
        }
    }
}
