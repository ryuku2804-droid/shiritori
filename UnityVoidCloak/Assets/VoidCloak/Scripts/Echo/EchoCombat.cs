using UnityEngine;
using VoidCloak;

namespace EchoKnight
{
    /// <summary>
    /// The knight's sword fighting.
    ///
    ///   Light attack : left mouse / gamepad X   - quick horizontal slash
    ///   Heavy attack : E / gamepad RB           - slow overhead blow, hits harder, very loud
    ///   Parry        : Q / gamepad LB           - raise the sword just before an enemy strikes
    ///
    /// Every swing makes a sound (an echo), so fighting also shows - and is heard by - everything
    /// around. A successful parry rings like a bell: a big echo, and the enemy is stunned and takes
    /// double damage for a moment.
    ///
    /// Attack rings (<see cref="EchoShockwaves"/>): parry just as the red ring's front reaches the
    /// knight and it is thrown back at its owner (damage + stun). Pillars and walls between the
    /// knight and the ring's origin block it.
    ///
    /// One blow is death (Max Health 1): the screen goes dark, the knight wakes at the last shrine
    /// and every enemy is back where it started.
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(VoidCloakCharacter), typeof(VoidCloakMover), typeof(EchoPlayer))]
    public class EchoCombat : MonoBehaviour
    {
        enum Action { None, Light, Heavy, Parry }

        [Header("Health")]
        [Tooltip("1 = any blow is death.")]
        [SerializeField, Min(1)] private int maxHealth = 1;
        [Tooltip("Seconds of invulnerability after being hit.")]
        [SerializeField, Min(0f)] private float hurtInvulnerability = 0.8f;

        [Header("Light Attack (left mouse / X)")]
        [SerializeField, Min(0f)] private float lightDamage = 1f;
        [SerializeField, Min(0f)] private float lightRange = 4.8f;
        [SerializeField, Range(10f, 360f)] private float lightArc = 120f;
        [SerializeField, Min(0f)] private float lightEchoRadius = 9f;

        [Header("Heavy Attack (E / RB)")]
        [SerializeField, Min(0f)] private float heavyDamage = 2.5f;
        [SerializeField, Min(0f)] private float heavyRange = 5.6f;
        [SerializeField, Range(10f, 360f)] private float heavyArc = 70f;
        [SerializeField, Min(0f)] private float heavyEchoRadius = 22f;

        [Header("Parry (Q / LB)")]
        [Tooltip("How long after pressing parry an enemy blow is deflected (seconds).")]
        [SerializeField, Min(0f)] private float parryWindow = 0.5f;
        [SerializeField, Min(0f)] private float parryEchoRadius = 28f;
        [SerializeField, Min(0f)] private float enemyStunTime = 1.8f;

        [Header("Attack Rings")]
        [Tooltip("How early before a ring's front arrives the parry may be pressed (seconds).")]
        [SerializeField, Min(0f)] private float ringParryEarly = 0.5f;
        [Tooltip("How late after the front arrived the parry still counts (seconds).")]
        [SerializeField, Min(0f)] private float ringParryLate = 0.12f;
        [SerializeField, Min(0f)] private float reflectDamage = 2f;
        [SerializeField, Min(0f)] private float reflectStun = 2.2f;

        [Header("Death")]
        [SerializeField, Min(0.2f)] private float deathSeconds = 1.8f;

        [Header("Feel")]
        [Tooltip("Movement speed while attacking (1 = full speed).")]
        [SerializeField, Range(0f, 1f)] private float attackMoveSpeed = 0.25f;

        // timing of each action: wind-up, active (hits land in the middle), recovery
        static readonly float[] LightTiming = { 0.12f, 0.12f, 0.26f };
        static readonly float[] HeavyTiming = { 0.42f, 0.14f, 0.5f };
        static readonly float[] ParryTiming = { 0.06f, 0.5f, 0.22f };   // the guard is held as long as the parry counts

        VoidCloakCharacter character;
        VoidCloakMover mover;
        EchoPlayer echoPlayer;

        Action action = Action.None;
        Action queued = Action.None;
        float actionTime;
        bool hitDone;
        float parryPressedTime = -100f;

        struct Reflection { public IEchoEnemy owner; public float hitTime; public Vector3 from; }
        readonly System.Collections.Generic.List<Reflection> reflections = new System.Collections.Generic.List<Reflection>();

        int health;
        bool dying;
        float deathTime;
        float invulnerableUntil;
        float hurtFlash;
        Texture2D vignette;

        public int Health { get { return health; } }
        public int MaxHealth { get { return maxHealth; } }

        void Awake()
        {
            character = GetComponent<VoidCloakCharacter>();
            mover = GetComponent<VoidCloakMover>();
            echoPlayer = GetComponent<EchoPlayer>();
            health = maxHealth;
        }

        void OnDisable()
        {
            if (character != null) character.SetSwing(Vector3.zero, Vector3.up, 0f);
            if (mover != null) { mover.SpeedMultiplier = 1f; mover.AllowTurning = true; }
        }

        void OnDestroy()
        {
            if (vignette != null) Destroy(vignette);
        }

        void Update()
        {
            if (dying)
            {
                if (Time.time - deathTime >= deathSeconds) WakeUp();
                return;
            }
            ReadInput();
            UpdateAction(Time.deltaTime);
            ResolveRings();
            UpdateReflections();
            hurtFlash = Mathf.MoveTowards(hurtFlash, 0f, Time.deltaTime * 2.5f);
        }

        // ------------------------------------------------------------------ input

        void ReadInput()
        {
            if (EchoGame.InputBlocked) return;
            Action pressed = Action.None;
#if ENABLE_INPUT_SYSTEM
            var mouse = UnityEngine.InputSystem.Mouse.current;
            var kb = UnityEngine.InputSystem.Keyboard.current;
            var pad = UnityEngine.InputSystem.Gamepad.current;
            if ((mouse != null && mouse.leftButton.wasPressedThisFrame) || (pad != null && pad.buttonWest.wasPressedThisFrame)) pressed = Action.Light;
            if ((kb != null && kb.eKey.wasPressedThisFrame) || (pad != null && pad.rightShoulder.wasPressedThisFrame)) pressed = Action.Heavy;
            if ((kb != null && kb.qKey.wasPressedThisFrame) || (pad != null && pad.leftShoulder.wasPressedThisFrame)) pressed = Action.Parry;
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            if (pressed == Action.None)
            {
                if (Input.GetMouseButtonDown(0) || Input.GetKeyDown(KeyCode.JoystickButton2)) pressed = Action.Light;
                if (Input.GetKeyDown(KeyCode.E) || Input.GetKeyDown(KeyCode.JoystickButton5)) pressed = Action.Heavy;
                if (Input.GetKeyDown(KeyCode.Q) || Input.GetKeyDown(KeyCode.JoystickButton4)) pressed = Action.Parry;
            }
#endif
            if (pressed == Action.None) return;

            if (action == Action.None) Begin(pressed);
            else queued = pressed;   // remembered and started as soon as the current move ends
        }

        void Begin(Action a)
        {
            action = a;
            actionTime = 0f;
            hitDone = false;
            queued = Action.None;
            if (a == Action.Parry) parryPressedTime = Time.time;
            Vector3 blade = transform.position + transform.forward * 1.5f + Vector3.up * 2.5f;
            if (a == Action.Light) EchoAudio.Play(EchoSound.SwingLight, blade, 0.7f, 1f, LightTiming[0] * 0.6f);
            else if (a == Action.Heavy) EchoAudio.Play(EchoSound.SwingHeavy, blade, 0.9f, 1f, HeavyTiming[0] * 0.75f);
            else EchoAudio.Play(EchoSound.SwingLight, blade, 0.35f, 1.3f);
            mover.SpeedMultiplier = a == Action.Parry ? 0.5f : attackMoveSpeed;
            mover.AllowTurning = false;
        }

        // ------------------------------------------------------------------ attacks

        void UpdateAction(float dt)
        {
            if (action == Action.None)
            {
                character.SetSwing(Vector3.zero, Vector3.up, 0f);
                return;
            }

            actionTime += dt;
            float[] timing = action == Action.Light ? LightTiming : action == Action.Heavy ? HeavyTiming : ParryTiming;
            float windUp = timing[0], active = timing[1], recover = timing[2];

            if (!hitDone && actionTime >= windUp + active * 0.5f && action != Action.Parry)
            {
                hitDone = true;
                Strike(action == Action.Heavy);
            }

            ApplySwingPose(timing);

            if (actionTime >= windUp + active + recover)
            {
                action = Action.None;
                mover.SpeedMultiplier = 1f;
                mover.AllowTurning = true;
                character.SetSwing(Vector3.zero, Vector3.up, 0f);
                if (queued != Action.None) Begin(queued);
            }
        }

        /// <summary>
        /// Moves the sword: wind up -> swing through -> back to rest.
        /// Each move is described by where the blade points (object space, the knight faces +Z);
        /// the rotations between those directions keep the blade in front of the body.
        /// </summary>
        void ApplySwingPose(float[] timing)
        {
            float windUp = timing[0], active = timing[1], recover = timing[2];
            float t = actionTime;

            Vector3 back, through;
            switch (action)
            {
                case Action.Light:   // diagonal slash from high right to low left
                    back = new Vector3(0.85f, 0.35f, 0.35f);
                    through = new Vector3(-0.8f, -0.3f, 0.55f);
                    break;
                case Action.Heavy:   // raised overhead, then brought down in front
                    back = new Vector3(0.1f, 1f, -0.15f);
                    through = new Vector3(0.1f, -0.5f, 0.85f);
                    break;
                default:             // parry: blade held across the body
                    back = new Vector3(-0.2f, 0.4f, 0.9f);
                    through = new Vector3(-0.55f, 0.35f, 0.75f);
                    break;
            }

            Vector3 rest = character.SwordRestDirection;
            Quaternion qBack = Quaternion.FromToRotation(rest, back.normalized);
            Quaternion qThrough = Quaternion.FromToRotation(rest, through.normalized);

            Quaternion q;
            if (t < windUp) q = Quaternion.Slerp(Quaternion.identity, qBack, Ease(t / windUp));
            else if (t < windUp + active) q = Quaternion.Slerp(qBack, qThrough, Ease((t - windUp) / active));
            else q = Quaternion.Slerp(qThrough, Quaternion.identity, Ease((t - windUp - active) / recover));

            float angleDeg;
            Vector3 axis;
            q.ToAngleAxis(out angleDeg, out axis);
            if (float.IsNaN(axis.x) || float.IsInfinity(axis.x)) { axis = Vector3.up; angleDeg = 0f; }
            character.SetSwing(character.SwordShoulder, axis, angleDeg * Mathf.Deg2Rad);
        }

        static float Ease(float x)
        {
            x = Mathf.Clamp01(x);
            return x * x * (3f - 2f * x);
        }

        void Strike(bool heavy)
        {
            float range = heavy ? heavyRange : lightRange;
            float arc = heavy ? heavyArc : lightArc;
            float damage = heavy ? heavyDamage : lightDamage;

            // the swing itself is a sound
            Vector3 swordPoint = transform.position + transform.forward * 2f + Vector3.up * 0.3f;
            EchoSystem.Emit(swordPoint, heavy ? heavyEchoRadius : lightEchoRadius, heavy ? EchoSource.Strike : EchoSource.Player, heavy ? 1.1f : 0.8f);
            if (heavy) EchoAudio.Play(EchoSound.SwordStrike, swordPoint, 0.7f, 0.85f);   // the blade hits the stones

            for (int i = EchoTargets.All.Count - 1; i >= 0; i--)
            {
                IEchoHittable target = EchoTargets.All[i];
                if (target == null || !target.IsAlive) continue;
                Vector3 to = target.Position - transform.position;
                to.y = 0f;
                if (to.magnitude > range) continue;
                if (Vector3.Angle(transform.forward, to) > arc * 0.5f) continue;
                target.TakeHit(damage, transform.position);
            }
        }

        // ------------------------------------------------------------------ defence

        /// <summary>
        /// Called by an enemy when its blow lands. Returns true when the blow was parried.
        /// </summary>
        public bool ReceiveBlow(int damage, IEchoEnemy attacker)
        {
            if (Time.time - parryPressedTime <= parryWindow)
            {
                // a parry rings like a bell
                EchoSystem.Emit(transform.position + transform.forward * 1.5f + Vector3.up * 2f, parryEchoRadius, EchoSource.Strike, 1.2f);
                EchoAudio.Play(EchoSound.Parry, transform.position + transform.forward * 1.5f + Vector3.up * 2f, 1f);
                if (attacker != null) attacker.Stun(enemyStunTime);
                return true;
            }
            if (Time.time < invulnerableUntil || dying) return false;

            health -= damage;
            EchoAudio.Play(EchoSound.Hurt, transform.position + Vector3.up * 2f, 0.9f);
            invulnerableUntil = Time.time + hurtInvulnerability;
            hurtFlash = 1f;
            if (health <= 0) Die();
            return false;
        }

        /// <summary>Full health again (bell shrines).</summary>
        public void RestoreHealth()
        {
            health = maxHealth;
        }

        public bool IsDying { get { return dying; } }

        void Die()
        {
            if (dying) return;
            dying = true;
            deathTime = Time.time;
            EchoAudio.Play(EchoSound.Death, transform.position + Vector3.up * 1.5f, 1f);
            action = Action.None;
            queued = Action.None;
            reflections.Clear();
            mover.SpeedMultiplier = 0f;
            mover.AllowTurning = false;
            character.SetSwing(Vector3.zero, Vector3.up, 0f);
        }

        /// <summary>After the dark: back at the last shrine, enemies reset.</summary>
        void WakeUp()
        {
            dying = false;
            health = maxHealth;
            invulnerableUntil = Time.time + 1f;
            mover.SpeedMultiplier = 1f;
            mover.AllowTurning = true;
            EchoGame.NotifyPlayerDied();
            echoPlayer.Respawn();
        }

        // ------------------------------------------------------------------ attack rings

        void ResolveRings()
        {
            Vector3 me = transform.position;
            foreach (EchoShockwave ring in EchoShockwaves.Active)
            {
                if (ring.resolved) continue;
                if (!ring.Reaches(me))
                {
                    if (Time.time > ring.startTime + ring.radius / ring.speed) ring.resolved = true;
                    continue;
                }
                float arrival = ring.ArrivalTime(me);
                if (Time.time < arrival + ringParryLate) continue;
                ring.resolved = true;

                if (parryPressedTime >= arrival - ringParryEarly && parryPressedTime <= arrival + ringParryLate)
                {
                    Reflect(ring);
                }
                else if (!Shielded(ring.origin) && Time.time >= invulnerableUntil)
                {
                    hurtFlash = 1f;
                    EchoAudio.Play(EchoSound.Hurt, me + Vector3.up * 2f, 0.9f);
                    health -= 1;
                    if (health <= 0) Die();
                    return;
                }
            }
        }

        /// <summary>Is something solid between the ring's origin and the knight?</summary>
        bool Shielded(Vector3 origin)
        {
            Vector3 from = new Vector3(origin.x, transform.position.y + 1.6f, origin.z);
            Vector3 to = transform.position + Vector3.up * 1.6f;
            RaycastHit hit;
            if (!Physics.Linecast(from, to, out hit, ~0, QueryTriggerInteraction.Ignore)) return false;
            return hit.collider.GetComponentInParent<EchoPlayer>() == null;
        }

        /// <summary>The ring is thrown back: a golden ring runs back to its owner and hits it.</summary>
        void Reflect(EchoShockwave ring)
        {
            Vector3 chest = transform.position + Vector3.up * 2f;
            EchoAudio.Play(EchoSound.Parry, chest, 1f);
            if (ring.owner == null || !ring.owner.IsAlive) return;
            Vector3 d = ring.owner.Position - transform.position;
            d.y = 0f;
            float speed = ring.speed * 1.8f;
            EchoSystem.Emit(chest, d.magnitude + 2f, EchoSource.Resonance, 1.4f, speed);
            reflections.Add(new Reflection { owner = ring.owner, hitTime = Time.time + d.magnitude / speed, from = transform.position });
        }

        void UpdateReflections()
        {
            for (int i = reflections.Count - 1; i >= 0; i--)
            {
                Reflection r = reflections[i];
                if (Time.time < r.hitTime) continue;
                reflections.RemoveAt(i);
                if (r.owner == null || !r.owner.IsAlive) continue;
                // stun first: a reflected ring always lands (a Silent Knight would otherwise block it
                // when it arrives after the knight's recovery), and it gets the stunned bonus
                r.owner.Stun(reflectStun);
                r.owner.TakeHit(reflectDamage, r.from);
            }
        }

        // ------------------------------------------------------------------ health on screen

        void OnGUI()
        {
            if (dying)
            {
                if (vignette == null) vignette = MakeVignette();
                float k = Mathf.Clamp01((Time.time - deathTime) / (deathSeconds * 0.6f));
                Color keep = GUI.color;
                GUI.color = new Color(0.25f, 0f, 0f, 0.6f + 0.4f * k);
                GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), vignette);
                GUI.color = new Color(0f, 0f, 0f, k * 0.92f);
                GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), Texture2D.whiteTexture);
                GUI.color = keep;
                return;
            }
            float hurt = 1f - (float)health / Mathf.Max(1, maxHealth);
            float darkness = hurt * 0.9f;
            if (darkness <= 0.001f && hurtFlash <= 0.001f) return;
            if (vignette == null) vignette = MakeVignette();
            var full = new Rect(0f, 0f, Screen.width, Screen.height);
            Color old = GUI.color;
            if (darkness > 0.001f)
            {
                GUI.color = new Color(0f, 0f, 0f, darkness);
                GUI.DrawTexture(full, vignette);
            }
            if (hurtFlash > 0.001f)
            {
                GUI.color = new Color(0.8f, 0.05f, 0.03f, hurtFlash * 0.6f);
                GUI.DrawTexture(full, vignette);
            }
            GUI.color = old;
        }

        static Texture2D MakeVignette()
        {
            const int size = 128;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Clamp, hideFlags = HideFlags.DontSave };
            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float dx = (x + 0.5f) / size * 2f - 1f, dy = (y + 0.5f) / size * 2f - 1f;
                    float d = Mathf.Sqrt(dx * dx + dy * dy) / 1.414f;
                    float a = Mathf.Clamp01((d - 0.35f) / 0.65f);
                    tex.SetPixel(x, y, new Color(1f, 1f, 1f, a * a));
                }
            }
            tex.Apply();
            return tex;
        }
    }
}
