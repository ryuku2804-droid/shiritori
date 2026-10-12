using UnityEngine;
using UnityEngine.InputSystem;

namespace BlindSpot
{
    /// <summary>
    /// 視線の先にある「調べられるもの」を探し、E キーで使う。Player に付ける。
    /// </summary>
    [RequireComponent(typeof(PlayerController))]
    public class PlayerInteractor : MonoBehaviour
    {
        [Tooltip("調べられる距離 (m)")]
        [SerializeField] float reach = 2f;
        [Tooltip("視線の太さ (m)。小さな物でも狙いやすいよう、線ではなく細い球を飛ばす")]
        [SerializeField] float aimRadius = 0.12f;
        [Tooltip("調べる対象のレイヤー。Player は外すこと")]
        [SerializeField] LayerMask mask = ~0;

        public PlayerController Player { get; private set; }
        public PlayerThrower Thrower { get; private set; }

        /// <summary>今入っているロッカー (入っていなければ null)。</summary>
        public HidingSpot ActiveHidingSpot { get; set; }

        /// <summary>今画面に出す説明 (無ければ null)。</summary>
        public string CurrentPrompt { get; private set; }

        InputAction interactAction;
        IInteractable target;

        void Awake()
        {
            Player = GetComponent<PlayerController>();
            Thrower = GetComponent<PlayerThrower>();
            interactAction = new InputAction("Interact", InputActionType.Button, "<Keyboard>/e");
            interactAction.AddBinding("<Gamepad>/buttonWest");
        }

        void OnEnable() { interactAction.Enable(); }
        void OnDisable() { interactAction.Disable(); }
        void OnDestroy() { interactAction.Dispose(); }

        void Update()
        {
            if (!Player.InputEnabled)
            {
                CurrentPrompt = null;
                return;
            }

            // ロッカーの中にいるときは、何を見ていても「出る」が対象
            target = ActiveHidingSpot != null ? ActiveHidingSpot : FindTarget();
            CurrentPrompt = target != null ? target.GetPrompt(this) : null;

            if (CurrentPrompt != null && interactAction.WasPressedThisFrame()) target.Interact(this);
        }

        IInteractable FindTarget()
        {
            Transform eye = Player.CameraRoot;
            if (Physics.SphereCast(eye.position, aimRadius, eye.forward, out RaycastHit hit, reach, mask,
                    QueryTriggerInteraction.Ignore))
            {
                return hit.collider.GetComponentInParent<IInteractable>();
            }
            return null;
        }
    }
}
