using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// R (gamepad B): throw a stone the way the camera looks. Where it lands it clacks and
    /// sends out an echo: the knight sees that place for a moment - and every Listener nearby
    /// turns to the sound. Use it to look ahead, or to pull enemies away from the path.
    /// Put it on the knight (next to EchoPlayer).
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(EchoPlayer))]
    public class EchoStoneThrow : MonoBehaviour
    {
        [SerializeField, Min(1f)] private float maxDistance = 16f;
        [Tooltip("Size of the echo where the stone lands (Listeners hear it inside this; armour only very close).")]
        [SerializeField, Min(0f)] private float echoRadius = 15f;
        [SerializeField, Range(0f, 2f)] private float echoStrength = 0.95f;
        [SerializeField, Min(0f)] private float cooldown = 2f;

        struct Flight { public Vector3 land; public float at; }

        readonly List<Flight> flights = new List<Flight>();
        float readyTime;
        EchoCombat combat;

        void Awake()
        {
            combat = GetComponent<EchoCombat>();
        }

        void Update()
        {
            for (int i = flights.Count - 1; i >= 0; i--)
            {
                if (Time.time < flights[i].at) continue;
                Land(flights[i].land);
                flights.RemoveAt(i);
            }
            if (EchoGame.Paused || (combat != null && combat.IsDying)) return;
            if (Time.time >= readyTime && ThrowPressed()) Throw();
        }

        void Throw()
        {
            readyTime = Time.time + cooldown;
            Vector3 dir = transform.forward;
            Camera cam = Camera.main;
            if (cam != null)
            {
                Vector3 f = cam.transform.forward;
                f.y = 0f;
                if (f.sqrMagnitude > 1e-4f) dir = f.normalized;
            }
            Vector3 origin = transform.position + Vector3.up * 2.2f;
            float distance = maxDistance;
            RaycastHit hit;
            if (Physics.Raycast(origin, dir, out hit, maxDistance, ~0, QueryTriggerInteraction.Ignore))
                distance = Mathf.Max(0.6f, hit.distance - 0.4f);   // it hits a wall and drops
            Vector3 land = origin + dir * distance;
            if (Physics.Raycast(land, Vector3.down, out hit, 30f, ~0, QueryTriggerInteraction.Ignore)) land = hit.point;
            else land.y = transform.position.y;

            flights.Add(new Flight { land = land, at = Time.time + 0.3f + distance / 22f });
            EchoAudio.Play(EchoSound.SwingLight, origin, 0.25f, 1.7f);
        }

        void Land(Vector3 p)
        {
            EchoSystem.Emit(p + Vector3.up * 0.2f, echoRadius, EchoSource.Player, echoStrength);
            EchoAudio.Play(EchoSound.StoneClack, p + Vector3.up * 0.2f, 1f, Random.Range(0.9f, 1.15f));
        }

        static bool ThrowPressed()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            if (kb != null && kb.rKey.wasPressedThisFrame) return true;
            var pad = UnityEngine.InputSystem.Gamepad.current;
            if (pad != null && pad.buttonEast.wasPressedThisFrame) return true;
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            if (Input.GetKeyDown(KeyCode.R) || Input.GetKeyDown(KeyCode.JoystickButton1)) return true;
#endif
            return false;
        }
    }
}
