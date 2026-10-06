using UnityEngine;

namespace VoidCloak
{
    /// <summary>
    /// WASD / arrow key walking for the Void Cloak character.
    ///
    /// - Movement is relative to the camera (W = away from the camera).
    /// - The character turns smoothly to face the direction it walks.
    /// - Hold Left Shift to run.
    /// - Works with the new Input System package and with the old Input Manager.
    /// - If a CharacterController is on the same GameObject it is used (with gravity),
    ///   otherwise the character slides on its current height (no floor needed).
    ///
    /// It also drives the cloth motion in the shader: the hem trails behind, the front of
    /// the cloak swings with each step and the body bobs slightly.
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(VoidCloakCharacter))]
    public class VoidCloakMover : MonoBehaviour
    {
        [Header("Input")]
        [Tooltip("Movement is relative to this camera. Empty = Camera.main.")]
        [SerializeField] private Transform cameraTransform = null;

        [Header("Movement (units per second, character is ~4.2 units tall)")]
        [SerializeField, Min(0f)] private float walkSpeed = 3.2f;
        [SerializeField, Min(0f)] private float runSpeed = 7f;
        [Tooltip("How fast the speed changes (units/s^2).")]
        [SerializeField, Min(0.1f)] private float acceleration = 10f;
        [Tooltip("Turning speed in degrees per second.")]
        [SerializeField, Min(1f)] private float turnSpeed = 420f;
        [SerializeField] private float gravity = -25f;

        [Header("Cloth Motion")]
        [Tooltip("How far the hem trails behind: seconds of velocity.")]
        [SerializeField, Range(0f, 0.6f)] private float trailStrength = 0.16f;
        [Tooltip("Maximum trailing distance of the hem.")]
        [SerializeField, Range(0f, 2f)] private float maxTrail = 0.6f;
        [Tooltip("How slowly the cloth follows changes of speed and direction.")]
        [SerializeField, Range(0.01f, 1f)] private float clothLagTime = 0.3f;
        [Tooltip("Distance covered by one step.")]
        [SerializeField, Min(0.1f)] private float stepLength = 1.5f;
        [Tooltip("How far each step pushes the front of the cloak.")]
        [SerializeField, Range(0f, 0.5f)] private float stepPush = 0.12f;
        [Tooltip("Vertical bob of the whole figure per step.")]
        [SerializeField, Range(0f, 0.2f)] private float bobHeight = 0.035f;

        VoidCloakCharacter character;
        CharacterController controller;

        Vector3 velocity;          // world space, horizontal
        float verticalSpeed;
        Vector3 clothVelocity;     // object space, smoothed
        Vector3 clothVelocityRef;
        float stepPhase;
        float gaitAmount;

        void Awake()
        {
            character = GetComponent<VoidCloakCharacter>();
            controller = GetComponent<CharacterController>();
        }

        void Update()
        {
            float dt = Time.deltaTime;
            if (dt <= 0f) return;

            bool run;
            Vector2 input = ReadMoveInput(out run);
            Vector3 wish = CameraRelative(input);

            // --- speed ---------------------------------------------------------------
            float targetSpeed = wish.sqrMagnitude > 0f ? (run ? runSpeed : walkSpeed) : 0f;
            Vector3 targetVelocity = wish * targetSpeed;
            velocity = Vector3.MoveTowards(velocity, targetVelocity, acceleration * dt);

            // --- turning (face the walking direction) ---------------------------------
            if (wish.sqrMagnitude > 1e-4f)
            {
                Quaternion look = Quaternion.LookRotation(wish, Vector3.up);
                transform.rotation = Quaternion.RotateTowards(transform.rotation, look, turnSpeed * dt);
            }

            // --- move -------------------------------------------------------------------
            Vector3 delta = velocity * dt;
            if (controller != null && controller.enabled)
            {
                verticalSpeed = controller.isGrounded ? -1f : verticalSpeed + gravity * dt;
                delta.y = verticalSpeed * dt;
                controller.Move(delta);
            }
            else
            {
                transform.position += delta;
            }

            UpdateClothMotion(dt);
        }

        void UpdateClothMotion(float dt)
        {
            if (character == null) return;

            // velocity in the character's own space; smoothing makes the cloth lag behind
            // when the character starts, stops or turns
            Vector3 local = transform.InverseTransformDirection(velocity);
            clothVelocity = Vector3.SmoothDamp(clothVelocity, local, ref clothVelocityRef, clothLagTime, Mathf.Infinity, dt);
            Vector3 lag = clothVelocity * trailStrength;
            if (lag.magnitude > maxTrail) lag = lag.normalized * maxTrail;

            float speed = new Vector3(velocity.x, 0f, velocity.z).magnitude;
            // half a gait cycle per step
            stepPhase += speed / stepLength * Mathf.PI * dt;
            if (stepPhase > 1000f) stepPhase -= 2f * Mathf.PI * 150f;
            float targetGait = walkSpeed > 0f ? Mathf.Clamp01(speed / walkSpeed) : 0f;
            gaitAmount = Mathf.MoveTowards(gaitAmount, targetGait, dt * 3f);

            float bob = -Mathf.Abs(Mathf.Sin(stepPhase)) * bobHeight * gaitAmount;
            character.SetMotion(lag, stepPhase, stepPush * gaitAmount, bob);
        }

        void OnDisable()
        {
            if (character != null) character.SetMotion(Vector3.zero, 0f, 0f, 0f);
        }

        Vector3 CameraRelative(Vector2 input)
        {
            if (input.sqrMagnitude < 1e-4f) return Vector3.zero;
            if (input.sqrMagnitude > 1f) input.Normalize();

            Transform cam = cameraTransform;
            if (cam == null && Camera.main != null) cam = Camera.main.transform;

            Vector3 forward = cam != null ? cam.forward : Vector3.forward;
            Vector3 right = cam != null ? cam.right : Vector3.right;
            forward.y = 0f;
            right.y = 0f;
            if (forward.sqrMagnitude < 1e-4f) forward = Vector3.Cross(right, Vector3.up);
            forward.Normalize();
            right.Normalize();
            Vector3 wish = forward * input.y + right * input.x;
            return wish.sqrMagnitude > 1f ? wish.normalized : wish;
        }

        static Vector2 ReadMoveInput(out bool run)
        {
            run = false;
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            if (kb != null)
            {
                float x = (kb.dKey.isPressed || kb.rightArrowKey.isPressed ? 1f : 0f) - (kb.aKey.isPressed || kb.leftArrowKey.isPressed ? 1f : 0f);
                float y = (kb.wKey.isPressed || kb.upArrowKey.isPressed ? 1f : 0f) - (kb.sKey.isPressed || kb.downArrowKey.isPressed ? 1f : 0f);
                run = kb.leftShiftKey.isPressed;
                return new Vector2(x, y);
            }
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            {
                float x = (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow) ? 1f : 0f) - (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow) ? 1f : 0f);
                float y = (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow) ? 1f : 0f) - (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow) ? 1f : 0f);
                run = Input.GetKey(KeyCode.LeftShift);
                return new Vector2(x, y);
            }
#else
            return Vector2.zero;
#endif
        }
    }
}
