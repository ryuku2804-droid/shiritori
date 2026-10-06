using UnityEngine;

namespace VoidCloak
{
    /// <summary>
    /// Simple third-person camera for the Void Cloak character. Put it on the Main Camera.
    ///
    /// - Follows the target's position smoothly. The camera never turns on its own:
    ///   movement is camera-relative, so turning the camera after the character would change
    ///   what A / D / S mean every frame and make the character run in circles.
    /// - Hold the right mouse button and drag to orbit (gamepad: right stick); mouse wheel to zoom.
    /// - Works with the new Input System package and with the old Input Manager.
    /// </summary>
    [DisallowMultipleComponent]
    public class VoidCloakFollowCamera : MonoBehaviour
    {
        [Tooltip("The GameObject with VoidCloakCharacter / VoidCloakMover.")]
        [SerializeField] private Transform target = null;
        [Tooltip("Height of the point the camera looks at (the character is ~4.2 units tall).")]
        [SerializeField] private float lookHeight = 2.4f;
        [SerializeField, Min(1f)] private float distance = 11f;
        [SerializeField] private Vector2 distanceLimits = new Vector2(4f, 25f);
        [Tooltip("Up / down angle of the camera in degrees.")]
        [SerializeField, Range(-20f, 80f)] private float pitch = 12f;
        [SerializeField] private Vector2 pitchLimits = new Vector2(-10f, 70f);
        [Tooltip("Start behind the character (true) or in front of it, looking at the hood (false).")]
        [SerializeField] private bool startBehind = true;
        [SerializeField, Range(0.01f, 1f)] private float followSmoothing = 0.12f;
        [SerializeField, Range(0.01f, 2f)] private float orbitSensitivity = 0.2f;
        [SerializeField, Range(0.1f, 5f)] private float zoomSensitivity = 1f;
        [Tooltip("Move the camera closer when a wall is between it and the character.")]
        [SerializeField] private bool avoidWalls = true;
        [SerializeField, Range(0.05f, 2f)] private float wallPadding = 0.4f;

        float yaw;
        Vector3 focus;

        /// <summary>The character the camera follows.</summary>
        public Transform Target
        {
            get { return target; }
            set { target = value; initialized = false; }
        }
        Vector3 focusVelocity;
        bool initialized;

        void LateUpdate()
        {
            if (target == null) return;
            float dt = Time.deltaTime;

            if (!initialized)
            {
                yaw = target.eulerAngles.y + (startBehind ? 0f : 180f);
                focus = target.position + Vector3.up * lookHeight;
                initialized = true;
            }

            bool orbiting;
            Vector2 look = ReadOrbitInput(out orbiting);
            float scroll = ReadScroll();

            if (orbiting)
            {
                yaw += look.x * orbitSensitivity;
                pitch = Mathf.Clamp(pitch - look.y * orbitSensitivity, pitchLimits.x, pitchLimits.y);
            }

            distance = Mathf.Clamp(distance - scroll * zoomSensitivity, distanceLimits.x, distanceLimits.y);

            Vector3 wantedFocus = target.position + Vector3.up * lookHeight;
            focus = Vector3.SmoothDamp(focus, wantedFocus, ref focusVelocity, followSmoothing, Mathf.Infinity, dt);

            Quaternion rotation = Quaternion.Euler(pitch, yaw, 0f);
            Vector3 back = -(rotation * Vector3.forward);
            transform.position = focus + back * VisibleDistance(back);
            transform.rotation = rotation;
        }

        /// <summary>Camera distance, shortened if a wall (not the character itself) is in the way.</summary>
        float VisibleDistance(Vector3 back)
        {
            if (!avoidWalls) return distance;
            RaycastHit hit;
            if (Physics.SphereCast(focus, wallPadding, back, out hit, distance, ~0, QueryTriggerInteraction.Ignore))
            {
                if (hit.transform != target && !hit.transform.IsChildOf(target))
                    return Mathf.Max(1f, hit.distance - wallPadding * 0.5f);
            }
            return distance;
        }

        static Vector2 ReadOrbitInput(out bool orbiting)
        {
            orbiting = false;
#if ENABLE_INPUT_SYSTEM
            // gamepad right stick orbits continuously
            var pad = UnityEngine.InputSystem.Gamepad.current;
            if (pad != null)
            {
                Vector2 stick = pad.rightStick.ReadValue();
                if (stick.sqrMagnitude > 0.04f)
                {
                    orbiting = true;
                    return stick * (600f * Time.deltaTime);
                }
            }
            var mouse = UnityEngine.InputSystem.Mouse.current;
            if (mouse != null)
            {
                orbiting = mouse.rightButton.isPressed;
                return orbiting ? mouse.delta.ReadValue() : Vector2.zero;
            }
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            orbiting = Input.GetMouseButton(1);
            return orbiting ? new Vector2(Input.GetAxis("Mouse X"), Input.GetAxis("Mouse Y")) * 10f : Vector2.zero;
#else
            return Vector2.zero;
#endif
        }

        static float ReadScroll()
        {
#if ENABLE_INPUT_SYSTEM
            var mouse = UnityEngine.InputSystem.Mouse.current;
            if (mouse != null) return mouse.scroll.ReadValue().y / 120f;
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            return Input.mouseScrollDelta.y;
#else
            return 0f;
#endif
        }
    }
}
