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
    /// Health is shown without a HUD: the screen edges darken as the knight gets hurt and flash
    /// red on every hit.
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(VoidCloakCharacter), typeof(VoidCloakMover), typeof(EchoPlayer))]
    public class EchoCombat : MonoBehaviour
    {
        enum Action { None, Light, Heavy, Parry }

        [Header("Health")]
        [SerializeField, Min(1)] private int maxHealth = 5;
        [Tooltip("Seconds of invulnerability after being hit.")]
        [SerializeField, Min(0f)] private float hurtInvulnerability = 0.8f;

        [Header("Light Attack (left mouse / X)")]
        [SerializeField, Min(0f)] private float lightDamage = 1f;
        [SerializeField, Min(0f)] private float lightRange = 4.8f;
        [SerializeField, Range(10f, 360f)] private float lightArc = 120f;
        [SerializeField, Min(0f)] private float lightEchoRadius = 13f;

        [Header("Heavy Attack (E / RB)")]
        [SerializeField, Min(0f)] private float heavyDamage = 2.5f;
        [SerializeField, Min(0f)] private float heavyRange = 5.6f;
        [SerializeField, Range(10f, 360f)] private float heavyArc = 70f;
        [SerializeField, Min(0f)] private float heavyEchoRadius = 30f;

        [Header("Parry (Q / LB)")]
        [Tooltip("How long after pressing parry an enemy blow is deflected (seconds).")]
        [SerializeField, Min(0f)] private float parryWindow = 0.3f;
        [SerializeField, Min(0f)] private float parryEchoRadius = 28f;
        [SerializeField, Min(0f)] private float enemyStunTime = 1.8f;

        [Header("Feel")]
        [Tooltip("Movement speed while attacking (1 = full speed).")]
        [SerializeField, Range(0f, 1f)] private float attackMoveSpeed = 0.25f;

        // timing of each action: wind-up, active (hits land in the middle), recovery
        static readonly float[] LightTiming = { 0.12f, 0.12f, 0.26f };
        static readonly float[] HeavyTiming = { 0.42f, 0.14f, 0.5f };
        static readonly float[] ParryTiming = { 0.06f, 0.3f, 0.22f };

        VoidCloakCharacter character;
        VoidCloakMover mover;
        EchoPlayer echoPlayer;

        Action action = Action.None;
        Action queued = Action.None;
        float actionTime;
        bool hitDone;
        float parryPressedTime = -100f;

        int health;
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
            ReadInput();
            UpdateAction(Time.deltaTime);
            hurtFlash = Mathf.MoveTowards(hurtFlash, 0f, Time.deltaTime * 2.5f);
        }

        // ------------------------------------------------------------------ input

        void ReadInput()
        {
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

            foreach (EchoListenerEnemy enemy in EchoListenerEnemy.All)
            {
                if (enemy == null || !enemy.IsAlive) continue;
                Vector3 to = enemy.transform.position - transform.position;
                to.y = 0f;
                if (to.magnitude > range) continue;
                if (Vector3.Angle(transform.forward, to) > arc * 0.5f) continue;
                enemy.TakeHit(damage, transform.position);
            }
        }

        // ------------------------------------------------------------------ defence

        /// <summary>
        /// Called by an enemy when its blow lands. Returns true when the blow was parried.
        /// </summary>
        public bool ReceiveBlow(int damage, EchoListenerEnemy attacker)
        {
            if (Time.time - parryPressedTime <= parryWindow)
            {
                // a parry rings like a bell
                EchoSystem.Emit(transform.position + transform.forward * 1.5f + Vector3.up * 2f, parryEchoRadius, EchoSource.Strike, 1.2f);
                if (attacker != null) attacker.Stun(enemyStunTime);
                return true;
            }
            if (Time.time < invulnerableUntil) return false;

            health -= damage;
            invulnerableUntil = Time.time + hurtInvulnerability;
            hurtFlash = 1f;
            if (health <= 0) Die();
            return false;
        }

        void Die()
        {
            health = maxHealth;
            action = Action.None;
            queued = Action.None;
            mover.SpeedMultiplier = 1f;
            mover.AllowTurning = true;
            character.SetSwing(Vector3.zero, Vector3.up, 0f);
            echoPlayer.Respawn();
        }

        // ------------------------------------------------------------------ health on screen

        void OnGUI()
        {
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
