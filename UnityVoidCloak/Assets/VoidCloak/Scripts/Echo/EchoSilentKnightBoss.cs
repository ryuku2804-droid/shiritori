using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// 「沈黙の騎士」(the Silent Knight): a bell keeper swallowed by the Silence, guarding the end
    /// of a chapter. Like everything else it is only seen in an echo.
    ///
    /// - Sword slam (far): the sword is raised with a long metal scrape, then slammed down:
    ///   a big red ring. Parry it back as the front arrives and the knight is stunned -
    ///   or hide behind a pillar.
    /// - Lunge (near): two quick thrusts. The scrape of the blade is the only warning. Parry stuns it.
    /// - Veil of silence (when hurt): for a few seconds the knight's footsteps make no echo at all.
    ///   It hunts in the dark. Stones and the bell strike still sound.
    /// - It blocks every blow from the front. It can only be hurt while stunned, or from behind.
    ///   A blocked blow rings out, and it answers with a thrust at once.
    /// When the knight falls, time goes back to the last save: it waits at its place again (or stays fallen).
    /// When it falls, the sealed door opens and its memory (an echo theatre) plays.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoSilentKnightBoss : MonoBehaviour, IEchoEnemy, IEchoSaveable
    {
        enum State { Dormant, Stalk, SlamWindUp, LungeWindUp, Lunge, Recover, Stunned, Veil, Dead }

        [SerializeField] private Material material = null;
        [SerializeField] private Transform player = null;
        [Tooltip("Opened when it falls.")]
        [SerializeField] private EchoBellDoor sealedDoor = null;
        [Tooltip("Played when it falls (its memory).")]
        [SerializeField] private EchoMemoryTheatre memory = null;
        [SerializeField] private string bossName = "沈黙の騎士　ガレス";
        [Tooltip("What Rine says when it wakes.")]
        [SerializeField, TextArea(1, 3)] private string awakenLine = "……この気配。ガレス……？　兄さんの、仲間だった人。";

        [Header("Health")]
        [Tooltip("Light attack 1, heavy 2.5, a reflected ring 2. x1.5 while stunned.")]
        [SerializeField, Min(1f)] private float maxHealth = 9f;
        [Tooltip("Blows from more than this angle off its front land (from behind).")]
        [SerializeField, Range(90f, 180f)] private float behindAngle = 115f;

        [Header("Movement")]
        [SerializeField, Min(1f)] private float awakenDistance = 13f;
        [SerializeField, Min(0f)] private float walkSpeed = 2.4f;
        [SerializeField, Min(1f)] private float turnSpeed = 160f;

        [Header("Sword slam (ring)")]
        [SerializeField, Min(0f)] private float slamMinDistance = 6.5f;
        [SerializeField, Min(0.1f)] private float slamWindUp = 1.0f;
        [SerializeField, Min(1f)] private float ringRadius = 22f;
        [SerializeField, Min(1f)] private float ringSpeed = 11f;

        [Header("Lunge")]
        [SerializeField, Min(0f)] private float lungeRange = 5f;
        [SerializeField, Min(0.1f)] private float lungeWindUp = 0.55f;
        [SerializeField, Min(0f)] private float lungeDistance = 3.2f;
        [SerializeField, Min(1)] private int lungesPerCombo = 2;

        [Header("Veil of silence")]
        [SerializeField, Min(0f)] private float veilSeconds = 6f;
        [SerializeField, Min(0f)] private float veilCooldown = 20f;

        [Header("After a move")]
        [SerializeField, Min(0f)] private float recoverTime = 1.1f;

        Mesh mesh;
        State state = State.Dormant;
        Vector3 home;
        Quaternion homeRotation;
        float health;
        float stateUntil;
        float nextDecision;
        float nextVeil;
        float nextStep;
        int lungesLeft;
        bool veilAnnounced;

        public bool IsAlive { get { return state != State.Dead; } }
        public Vector3 Position { get { return transform.position; } }

        /// <summary>Who this Silent Knight is (name on screen, Rine's line when it wakes, health).</summary>
        public void SetIdentity(string newName, string newAwakenLine, float newMaxHealth)
        {
            if (!string.IsNullOrEmpty(newName)) bossName = newName;
            if (!string.IsNullOrEmpty(newAwakenLine)) awakenLine = newAwakenLine;
            if (newMaxHealth > 0f) { maxHealth = newMaxHealth; health = newMaxHealth; }
        }

        public void Setup(Material newMaterial, Transform newPlayer, EchoBellDoor door, EchoMemoryTheatre theatre)
        {
            material = newMaterial;
            player = newPlayer;
            sealedDoor = door;
            memory = theatre;
            BuildBody();
        }

        void OnEnable()
        {
            BuildBody();
            home = transform.position;
            homeRotation = transform.rotation;
            health = maxHealth;
            state = State.Dormant;
            EchoTargets.Register(this);
            EchoSnapshot.Register(this);
        }

        void OnDisable()
        {
            EchoTargets.Unregister(this);
            EchoSnapshot.Unregister(this);
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == mesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(mesh);
            mesh = null;
        }

        void BuildBody()
        {
            var b = new EchoPointBuilder(21);
            EchoSilentKnightBody.Build(b);
            mesh = EchoMeshUtil.Build(b, mesh, "Silent Knight");
            GetComponent<MeshFilter>().sharedMesh = mesh;
            var r = GetComponent<MeshRenderer>();
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
        }

        // ------------------------------------------------------------------ being hit

        public void TakeHit(float damage, Vector3 from)
        {
            if (state == State.Dead || state == State.Dormant) return;
            Vector3 to = from - transform.position;
            to.y = 0f;
            bool behind = to.sqrMagnitude > 1e-4f && Vector3.Angle(transform.forward, to) > behindAngle;
            bool open = state == State.Stunned || state == State.Recover;

            if (!open && !behind)
            {
                // blocked: steel on steel, and it answers at once
                Vector3 clash = transform.position + transform.forward * 1.2f + Vector3.up * 2.5f;
                EchoAudio.Play(EchoSound.Parry, clash, 0.9f, 0.7f);
                EchoSystem.Emit(clash, 9f, EchoSource.Enemy, 1.2f);
                EchoSystem.Noise(clash, 20f);
                BeginLunge(0.4f, 1);
                return;
            }

            if (state == State.Stunned) damage *= 1.5f;
            health -= damage;
            EchoSystem.Emit(transform.position + Vector3.up * 2.5f, 12f + damage * 4f, EchoSource.Enemy, 1.3f);
            EchoAudio.Play(EchoSound.ArmorHit, transform.position + Vector3.up * 2.5f, 1f, 0.85f);
            if (health <= 0f) Die();
        }

        public void Stun(float seconds)
        {
            if (state == State.Dead || state == State.Dormant) return;
            state = State.Stunned;
            stateUntil = Time.time + seconds;
            EchoAudio.Play(EchoSound.ArmorStep, transform.position + Vector3.up * 2f, 1f, 0.6f);   // it staggers
        }

        void Die()
        {
            state = State.Dead;
            EchoGame.SilencedUntil = 0f;
            GetComponent<MeshRenderer>().enabled = false;
            EchoSystem.Emit(transform.position + Vector3.up * 2f, 45f, EchoSource.Resonance, 1.4f);
            EchoAudio.Play(EchoSound.ArmorCollapse, transform.position + Vector3.up * 1.5f, 1f, 0.8f);
            if (sealedDoor != null) sealedDoor.ForceOpen();
            if (memory != null) memory.Play();
            else EchoGame.Say("リーネ", "……眠って。もう、鐘を守らなくていいの。", 5f);
        }

        public string SaveKey { get { return gameObject.name; } }

        public string Capture()
        {
            return state == State.Dead ? "d" : "a";
        }

        /// <summary>A fight is never saved half-way: it either fell before the save, or waits whole at its place.</summary>
        public void Restore(string saved)
        {
            if (saved == "d")
            {
                state = State.Dead;
                GetComponent<MeshRenderer>().enabled = false;
                return;
            }
            transform.SetPositionAndRotation(home, homeRotation);
            health = maxHealth;
            state = State.Dormant;
            nextVeil = 0f;
            GetComponent<MeshRenderer>().enabled = true;
        }

        // ------------------------------------------------------------------ behaviour

        void Update()
        {
            if (!Application.isPlaying || player == null) return;
            float dt = Time.deltaTime;
            float dist = FlatDistance(player.position);

            switch (state)
            {
                case State.Dead:
                    return;
                case State.Dormant:
                    if (dist < awakenDistance) Awaken();
                    return;
                case State.Stunned:
                case State.Recover:
                    if (Time.time >= stateUntil) { state = State.Stalk; nextDecision = Time.time + Random.Range(0.3f, 0.8f); }
                    return;
                case State.SlamWindUp:
                    Face(player.position, 0.6f, dt);
                    if (Time.time >= stateUntil) Slam();
                    return;
                case State.LungeWindUp:
                    Face(player.position, 1.2f, dt);
                    if (Time.time >= stateUntil) { state = State.Lunge; stateUntil = Time.time + 0.22f; }
                    return;
                case State.Lunge:
                    if (!Blocked(transform.forward, 1.6f)) transform.position += transform.forward * (lungeDistance / 0.22f * dt);
                    if (Time.time >= stateUntil) LungeHit();
                    return;
                case State.Veil:
                    if (Time.time >= stateUntil) { state = State.Stalk; nextDecision = Time.time + 0.2f; }
                    return;
            }

            // Stalk: walk towards the knight (it hears him... unless the veil hides his steps)
            if (dist > 3.2f)
            {
                Vector3 to = player.position - transform.position;
                to.y = 0f;
                Vector3 dir = Steer(to.normalized);
                transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(dir, Vector3.up), turnSpeed * dt);
                transform.position += transform.forward * (walkSpeed * dt);
                Footsteps();
            }
            else
            {
                Face(player.position, 1f, dt);
            }

            if (Time.time < nextDecision) return;
            nextDecision = Time.time + Random.Range(0.9f, 1.6f);
            if (Time.time >= nextVeil && health <= maxHealth * 0.7f && !EchoGame.Silenced)
            {
                BeginVeil();
            }
            else if (dist > slamMinDistance && !EchoGame.Silenced)
            {
                state = State.SlamWindUp;
                stateUntil = Time.time + slamWindUp;
                EchoAudio.Play(EchoSound.ArmorWindUp, transform.position + Vector3.up * 3f, 1f, 0.75f);
            }
            else if (dist < lungeRange)
            {
                BeginLunge(lungeWindUp, lungesPerCombo);
            }
        }

        void Awaken()
        {
            state = State.Stalk;
            nextDecision = Time.time + 2f;
            nextVeil = Time.time + 8f;
            EchoSystem.Emit(transform.position + Vector3.up * 2f, 30f, EchoSource.Enemy, 1.4f);
            EchoAudio.Play(EchoSound.ArmorWindUp, transform.position + Vector3.up * 3f, 1f, 0.55f);
            EchoGame.Say("リーネ", awakenLine, 4.5f);
        }

        void Slam()
        {
            state = State.Recover;
            stateUntil = Time.time + recoverTime;
            Vector3 impact = transform.position + transform.forward * 2.4f;
            EchoShockwaves.Fire(new Vector3(impact.x, transform.position.y + 0.3f, impact.z), this, ringRadius, ringSpeed);
            EchoAudio.Play(EchoSound.SwordStrike, impact, 1f, 0.6f);
        }

        void BeginLunge(float windUp, int count)
        {
            if (state == State.Dead) return;
            lungesLeft = count;
            state = State.LungeWindUp;
            stateUntil = Time.time + windUp;
            EchoAudio.Play(EchoSound.ArmorWindUp, transform.position + Vector3.up * 2.5f, 0.7f, 1.4f);
        }

        void LungeHit()
        {
            Vector3 tip = transform.position + transform.forward * 2.6f + Vector3.up * 2f;
            EchoSystem.Emit(tip, 6f, EchoSource.Enemy, 1.1f);   // the thrust is heard, and shows it for a moment
            EchoAudio.Play(EchoSound.SwingHeavy, tip, 0.8f, 1.3f);

            Vector3 to = player.position - transform.position;
            to.y = 0f;
            bool inReach = to.magnitude < 3.4f && Vector3.Angle(transform.forward, to) < 55f;
            if (inReach)
            {
                var combat = player.GetComponent<EchoCombat>();
                if (combat != null && combat.ReceiveBlow(1, this)) return;   // parried: Stun() already took over
            }
            lungesLeft--;
            if (lungesLeft > 0)
            {
                state = State.LungeWindUp;
                stateUntil = Time.time + 0.35f;
                EchoAudio.Play(EchoSound.ArmorWindUp, transform.position + Vector3.up * 2.5f, 0.6f, 1.6f);
            }
            else
            {
                state = State.Recover;
                stateUntil = Time.time + recoverTime;
            }
        }

        void BeginVeil()
        {
            state = State.Veil;
            stateUntil = Time.time + 1.2f;
            nextVeil = Time.time + veilCooldown;
            EchoGame.SilencedUntil = Time.time + veilSeconds;
            // a deep thud, then nothing: the Silence spreads
            EchoAudio.Play(EchoSound.Death, transform.position + Vector3.up * 2f, 0.8f, 0.6f);
            if (!veilAnnounced)
            {
                veilAnnounced = true;
                EchoGame.Say("リーネ", "……音が、消えた……！　兄さん、石を……！", 4f);
            }
        }

        void Footsteps()
        {
            if (EchoGame.Silenced || Time.time < nextStep) return;   // under the veil it makes no sound either
            nextStep = Time.time + 0.75f;
            if (EchoWaterZone.IsInWater(transform.position))
            {
                EchoAudio.Play(EchoSound.Splash, transform.position, 0.8f, 0.7f);
                EchoSystem.Emit(transform.position + Vector3.up * 0.3f, 7f, EchoSource.Enemy, 1f);   // wading shows it
            }
            EchoAudio.Play(EchoSound.ArmorStep, transform.position + Vector3.up * 1f, 0.75f, 0.8f);
        }

        void Face(Vector3 p, float speedScale, float dt)
        {
            Vector3 to = p - transform.position;
            to.y = 0f;
            if (to.sqrMagnitude < 1e-4f) return;
            transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(to, Vector3.up), turnSpeed * speedScale * dt);
        }

        /// <summary>Walks round pillars instead of through them.</summary>
        Vector3 Steer(Vector3 desired)
        {
            float[] angles = { 0f, 35f, -35f, 70f, -70f, 110f, -110f };
            foreach (float a in angles)
            {
                Vector3 dir = Quaternion.Euler(0f, a, 0f) * desired;
                if (!Blocked(dir, 2.4f)) return dir;
            }
            return desired;
        }

        bool Blocked(Vector3 dir, float distance)
        {
            RaycastHit hit;
            Vector3 origin = transform.position + Vector3.up * 1.5f;
            if (!Physics.SphereCast(origin, 0.9f, dir, out hit, distance, ~0, QueryTriggerInteraction.Ignore)) return false;
            return hit.collider.GetComponentInParent<EchoPlayer>() == null;
        }

        float FlatDistance(Vector3 p)
        {
            Vector3 d = p - transform.position;
            d.y = 0f;
            return d.magnitude;
        }

        void OnGUI()
        {
            if (!Application.isPlaying || state == State.Dormant || state == State.Dead) return;
            EchoScreenText.DrawPrompt(bossName, 0.55f);
        }
    }
}
