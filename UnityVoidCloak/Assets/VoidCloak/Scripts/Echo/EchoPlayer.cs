using UnityEngine;
using VoidCloak;

namespace EchoKnight
{
    /// <summary>
    /// The blind knight's senses: every footstep sends out an echo (small when walking,
    /// bigger when running) and Space / gamepad Y strikes the ground with the sword for a
    /// large echo that every enemy nearby will hear.
    /// Put it on the same GameObject as VoidCloakCharacter and VoidCloakMover.
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(VoidCloakMover))]
    public class EchoPlayer : MonoBehaviour
    {
        [Header("Footsteps")]
        [SerializeField, Min(0f)] private float walkEchoRadius = 18f;
        [SerializeField, Min(0f)] private float runEchoRadius = 32f;
        [SerializeField, Range(0f, 2f)] private float walkEchoStrength = 0.75f;
        [SerializeField, Range(0f, 2f)] private float runEchoStrength = 1f;
        [Tooltip("Minimum seconds between footstep echoes while walking. Higher = darker, harder.")]
        [SerializeField, Min(0f)] private float walkEchoInterval = 1.8f;
        [Tooltip("Minimum seconds between footstep echoes while running.")]
        [SerializeField, Min(0f)] private float runEchoInterval = 0.9f;

        [Header("Bell Strike (Space / gamepad Y)")]
        [SerializeField, Min(0f)] private float strikeEchoRadius = 70f;
        [SerializeField, Range(0f, 3f)] private float strikeStrength = 1.05f;
        [Tooltip("Seconds before the strike can be used again.")]
        [SerializeField, Min(0f)] private float strikeCooldown = 4f;

        VoidCloakMover mover;
        CharacterController controller;
        Vector3 spawnPosition;
        Quaternion spawnRotation;
        float strikeReadyTime;
        float lastStepEchoTime = -100f;

        /// <summary>0 = strike ready, 1 = just used.</summary>
        public float StrikeCooldown01
        {
            get { return strikeCooldown > 0f ? Mathf.Clamp01((strikeReadyTime - Time.time) / strikeCooldown) : 0f; }
        }

        /// <summary>The knight in the scene (used by shrines).</summary>
        public static EchoPlayer Current { get; private set; }

        /// <summary>Where the knight comes back after falling (set by bell shrines).</summary>
        public void SetCheckpoint(Vector3 position, Quaternion rotation)
        {
            spawnPosition = position + Vector3.up * 0.05f;
            spawnRotation = rotation;
        }

        void Awake()
        {
            Current = this;
            mover = GetComponent<VoidCloakMover>();
            controller = GetComponent<CharacterController>();
            spawnPosition = transform.position;
            spawnRotation = transform.rotation;
            EchoSystem.Ensure();
        }

        void OnEnable()
        {
            Current = this;
            if (mover == null) mover = GetComponent<VoidCloakMover>();
            mover.Stepped += OnStep;
        }

        void OnDisable()
        {
            if (Current == this) Current = null;
            if (mover != null) mover.Stepped -= OnStep;
        }

        void Start()
        {
            // one echo on arrival so the player sees where they are
            EchoSystem.Emit(Feet(), walkEchoRadius, EchoSource.Player, walkEchoStrength);
        }

        void OnStep(float speed)
        {
            bool running = speed > mover.WalkSpeed * 1.15f;
            // not every footstep is heard: only one echo per interval
            if (Time.time - lastStepEchoTime < (running ? runEchoInterval : walkEchoInterval)) return;
            lastStepEchoTime = Time.time;
            EchoSystem.Emit(Feet(), running ? runEchoRadius : walkEchoRadius, EchoSource.Player,
                            running ? runEchoStrength : walkEchoStrength);
        }

        void Update()
        {
            if (StrikePressed() && Time.time >= strikeReadyTime)
            {
                strikeReadyTime = Time.time + strikeCooldown;
                EchoSystem.Emit(Feet(), strikeEchoRadius, EchoSource.Strike, strikeStrength);
            }
        }

        /// <summary>Back to the start (called when an enemy catches the knight).</summary>
        public void Respawn()
        {
            bool hadController = controller != null && controller.enabled;
            if (hadController) controller.enabled = false;
            transform.SetPositionAndRotation(spawnPosition, spawnRotation);
            if (hadController) controller.enabled = true;
            EchoSystem.Emit(Feet(), runEchoRadius, EchoSource.Player, 1f);
        }

        Vector3 Feet()
        {
            return transform.position + Vector3.up * 0.2f;
        }

        static bool StrikePressed()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            if (kb != null && kb.spaceKey.wasPressedThisFrame) return true;
            var pad = UnityEngine.InputSystem.Gamepad.current;
            if (pad != null && pad.buttonNorth.wasPressedThisFrame) return true;
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            if (Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.JoystickButton3)) return true;
#endif
            return false;
        }
    }
}
