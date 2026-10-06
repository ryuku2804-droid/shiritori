using UnityEngine;

namespace VoidCloak
{
    /// <summary>
    /// Simple third-person camera for the Void Cloak character. Put it on the Main Camera.
    ///
    /// - Follows the target's position smoothly. The camera never turns on its own:
    ///   movement is camera-relative, so turning the camera after the character would change
    ///   what A / D / S mean every frame and make the character run in circles.
    /// - Hold the right mouse button and drag to orbit; mouse wheel to zoom.
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

        float yaw;
        Vector3 focus;
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
            transform.position = focus - rotation * Vector3.forward * distance;
            transform.rotation = rotation;
        }

        static Vector2 ReadOrbitInput(out bool orbiting)
        {
            orbiting = false;
#if ENABLE_INPUT_SYSTEM
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
