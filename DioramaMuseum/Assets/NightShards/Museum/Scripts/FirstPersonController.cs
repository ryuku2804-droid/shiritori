using UnityEngine;

namespace NightShards.Museum
{
    // 一人称の歩き。CharacterController を使うので、壁や台座はすり抜けない。
    // 入力は MuseumInput からだけ受け取る
    [RequireComponent(typeof(CharacterController))]
    public class FirstPersonController : MonoBehaviour
    {
        [Header("移動")]
        [SerializeField] float walkSpeed = 2.2f;
        [SerializeField] float runSpeed = 4.4f;
        [Tooltip("速度が目標に追いつく速さ。大きいほどきびきび動く")]
        [SerializeField] float acceleration = 10f;
        [SerializeField] float jumpHeight = 0.9f;
        [SerializeField] float gravity = -18f;

        [Header("視点")]
        [SerializeField] float lookSensitivity = 2f;
        [SerializeField] float pitchLimit = 85f;

        [Tooltip("上下に首を振るための子オブジェクト (カメラの親)")]
        public Transform cameraPivot;

        // false にすると歩きと視点を止める (鑑賞モードやメニューの間)
        public bool InputEnabled { get; set; } = true;

        // カーソルの固定をこのスクリプトが受け持つか (段階4で鑑賞モードに切り替えるときに false にする)
        public bool ManageCursor { get; set; } = true;

        public bool IsRunning { get; private set; }

        CharacterController controller;
        Vector3 planarVelocity;
        float verticalVelocity;
        float yaw;
        float pitch;

        void Awake()
        {
            controller = GetComponent<CharacterController>();
            yaw = transform.eulerAngles.y;
        }

        void OnEnable()
        {
            if (ManageCursor) SetCursorLocked(true);
        }

        void Update()
        {
            UpdateCursor();

            bool canLook = InputEnabled && Cursor.lockState == CursorLockMode.Locked;
            if (canLook) Look(MuseumInput.Look);

            Vector2 move = InputEnabled ? MuseumInput.Move : Vector2.zero;
            IsRunning = InputEnabled && MuseumInput.Run && move.y > 0.1f;
            float speed = IsRunning ? runSpeed : walkSpeed;
            Vector3 target = (transform.right * move.x + transform.forward * move.y) * speed;

            // 指数で近づけると、フレームレートが変わっても同じ感触になる
            float k = 1f - Mathf.Exp(-acceleration * Time.deltaTime);
            planarVelocity = Vector3.Lerp(planarVelocity, target, k);

            if (controller.isGrounded)
            {
                if (verticalVelocity < 0f) verticalVelocity = -2f; // 地面に押し付けて、段差や坂で浮かないようにする
                if (InputEnabled && MuseumInput.JumpPressed)
                    verticalVelocity = Mathf.Sqrt(2f * jumpHeight * -gravity);
            }
            verticalVelocity += gravity * Time.deltaTime;

            CollisionFlags flags = controller.Move((planarVelocity + Vector3.up * verticalVelocity) * Time.deltaTime);
            if ((flags & CollisionFlags.Above) != 0 && verticalVelocity > 0f) verticalVelocity = 0f; // 天井に頭をぶつけたら落ちる
        }

        void Look(Vector2 delta)
        {
            yaw += delta.x * lookSensitivity;
            pitch = Mathf.Clamp(pitch - delta.y * lookSensitivity, -pitchLimit, pitchLimit);
            transform.rotation = Quaternion.Euler(0f, yaw, 0f);
            if (cameraPivot != null) cameraPivot.localRotation = Quaternion.Euler(pitch, 0f, 0f);
        }

        // Esc でカーソルを解放、画面クリックでまた固定する
        void UpdateCursor()
        {
            if (!ManageCursor) return;
            if (Cursor.lockState == CursorLockMode.Locked && MuseumInput.BackPressed) SetCursorLocked(false);
            else if (Cursor.lockState != CursorLockMode.Locked && MuseumInput.ClickPressed) SetCursorLocked(true);
        }

        public static void SetCursorLocked(bool locked)
        {
            Cursor.lockState = locked ? CursorLockMode.Locked : CursorLockMode.None;
            Cursor.visible = !locked;
        }

        // 別の場所へ一瞬で移す (CharacterController が有効なままだと位置が戻されるので、いったん切る)
        public void Teleport(Vector3 position, float newYaw)
        {
            controller.enabled = false;
            transform.position = position;
            yaw = newYaw;
            transform.rotation = Quaternion.Euler(0f, yaw, 0f);
            planarVelocity = Vector3.zero;
            verticalVelocity = 0f;
            controller.enabled = true;
        }
    }
}
