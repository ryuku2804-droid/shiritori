using UnityEngine;
using UnityEngine.InputSystem;

namespace BlindSpot
{
    /// <summary>プレイヤーの移動状態。足音の大きさを決める。</summary>
    public enum MoveState
    {
        Idle,   // 立ち止まっている
        Crouch, // しゃがみ (止まっていても移動中でもこれ)
        Walk,   // 歩き
        Run,    // 走り (前進中のみ)
    }

    /// <summary>
    /// CharacterController を使った一人称操作。
    /// 入力は新しい Input System をコード内で定義しているので、.inputactions ファイルは不要。
    /// オブジェクトの原点 (pivot) は足元にある前提。
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public class PlayerController : MonoBehaviour
    {
        [Header("参照")]
        [Tooltip("カメラの親。上下の視点回転としゃがみの高さ変更に使う")]
        [SerializeField] Transform cameraRoot;

        [Header("移動速度 (m/秒)")]
        [SerializeField] float crouchSpeed = 1.2f;
        [SerializeField] float walkSpeed = 2.5f;
        [SerializeField] float runSpeed = 5f;
        [Tooltip("速度の変わりやすさ。大きいほどキビキビ動く")]
        [SerializeField] float acceleration = 15f;

        [Header("視点")]
        [Tooltip("マウス感度 (1ピクセルあたりの回転角度)")]
        [SerializeField] float mouseSensitivity = 0.1f;
        [Tooltip("ゲームパッド右スティックの回転速度 (度/秒)")]
        [SerializeField] float gamepadLookSpeed = 150f;
        [SerializeField] float maxPitch = 85f;

        [Header("しゃがみ")]
        [Tooltip("ON: 押すたびに切り替え / OFF: 押している間だけしゃがむ")]
        [SerializeField] bool crouchToggle = false;
        [SerializeField] float standHeight = 1.8f;
        [SerializeField] float crouchHeight = 1.0f;
        [SerializeField] float standEyeHeight = 1.65f;
        [SerializeField] float crouchEyeHeight = 0.85f;
        [SerializeField] float crouchTransitionSpeed = 6f;
        [Tooltip("立ち上がれるか (頭上に何も無いか) の判定に使うレイヤー。Player レイヤーは外すこと")]
        [SerializeField] LayerMask obstacleMask = ~0;

        [Header("重力")]
        [SerializeField] float gravity = -20f;

        /// <summary>現在の移動状態。</summary>
        public MoveState State { get; private set; } = MoveState.Idle;

        /// <summary>false にすると移動・視点の入力を受け付けない (隠れる演出や死亡アニメ中など)。</summary>
        public bool InputEnabled { get; set; } = true;

        public bool IsCrouching { get; private set; }
        public bool IsGrounded => controller.isGrounded;
        public Transform CameraRoot => cameraRoot;

        /// <summary>現在の水平方向の速度 (m/秒)。</summary>
        public float HorizontalSpeed => new Vector3(controller.velocity.x, 0f, controller.velocity.z).magnitude;

        CharacterController controller;
        Vector3 horizontalVelocity;
        float verticalVelocity;
        float pitch;
        float currentHeight;
        bool crouchToggled;

        InputAction moveAction, mouseLookAction, padLookAction, runAction, crouchAction;

        void Awake()
        {
            controller = GetComponent<CharacterController>();
            currentHeight = standHeight;
            ApplyHeight(currentHeight);
            CreateInputActions();
        }

        void CreateInputActions()
        {
            moveAction = new InputAction("Move", InputActionType.Value);
            moveAction.AddCompositeBinding("2DVector")
                .With("Up", "<Keyboard>/w")
                .With("Down", "<Keyboard>/s")
                .With("Left", "<Keyboard>/a")
                .With("Right", "<Keyboard>/d");
            moveAction.AddBinding("<Gamepad>/leftStick");

            mouseLookAction = new InputAction("MouseLook", InputActionType.PassThrough, "<Mouse>/delta");
            padLookAction = new InputAction("PadLook", InputActionType.Value, "<Gamepad>/rightStick");

            runAction = new InputAction("Run", InputActionType.Button, "<Keyboard>/leftShift");
            runAction.AddBinding("<Gamepad>/leftStickPress");

            crouchAction = new InputAction("Crouch", InputActionType.Button, "<Keyboard>/leftCtrl");
            crouchAction.AddBinding("<Keyboard>/c");
            crouchAction.AddBinding("<Gamepad>/buttonEast");
        }

        void OnEnable()
        {
            moveAction.Enable();
            mouseLookAction.Enable();
            padLookAction.Enable();
            runAction.Enable();
            crouchAction.Enable();
        }

        void OnDisable()
        {
            moveAction.Disable();
            mouseLookAction.Disable();
            padLookAction.Disable();
            runAction.Disable();
            crouchAction.Disable();
        }

        void OnDestroy()
        {
            moveAction.Dispose();
            mouseLookAction.Dispose();
            padLookAction.Dispose();
            runAction.Dispose();
            crouchAction.Dispose();
        }

        void Start()
        {
            LockCursor(true);
        }

        void Update()
        {
            UpdateCursorLock();

            bool canInput = InputEnabled;
            Vector2 moveInput = canInput ? Vector2.ClampMagnitude(moveAction.ReadValue<Vector2>(), 1f) : Vector2.zero;

            if (canInput && Cursor.lockState == CursorLockMode.Locked) UpdateLook();
            UpdateCrouch(canInput);

            // 走りは「前進入力あり・しゃがんでいない」ときだけ
            bool running = canInput && runAction.IsPressed() && moveInput.y > 0.1f && !IsCrouching;

            float speed = IsCrouching ? crouchSpeed : running ? runSpeed : walkSpeed;
            Vector3 wish = transform.right * moveInput.x + transform.forward * moveInput.y;
            Vector3 targetVelocity = wish * speed; // スティックを少し倒しただけならゆっくり歩く
            horizontalVelocity = Vector3.MoveTowards(horizontalVelocity, targetVelocity, acceleration * Time.deltaTime);

            if (controller.isGrounded && verticalVelocity < 0f) verticalVelocity = -2f; // 接地を保つ
            verticalVelocity += gravity * Time.deltaTime;

            controller.Move((horizontalVelocity + Vector3.up * verticalVelocity) * Time.deltaTime);

            // 状態の決定
            bool moving = HorizontalSpeed > 0.1f;
            if (IsCrouching) State = MoveState.Crouch;
            else if (!moving) State = MoveState.Idle;
            else if (running) State = MoveState.Run;
            else State = MoveState.Walk;
        }

        void UpdateLook()
        {
            Vector2 mouse = mouseLookAction.ReadValue<Vector2>() * mouseSensitivity;
            Vector2 pad = padLookAction.ReadValue<Vector2>() * gamepadLookSpeed * Time.deltaTime;
            Vector2 look = mouse + pad;

            transform.Rotate(0f, look.x, 0f);
            pitch = Mathf.Clamp(pitch - look.y, -maxPitch, maxPitch);
            if (cameraRoot != null) cameraRoot.localRotation = Quaternion.Euler(pitch, 0f, 0f);
        }

        void UpdateCrouch(bool canInput)
        {
            if (canInput && crouchToggle && crouchAction.WasPressedThisFrame()) crouchToggled = !crouchToggled;
            bool wantCrouch = canInput && (crouchToggle ? crouchToggled : crouchAction.IsPressed());
            // 入力を止めている間はしゃがみ状態を維持する
            if (!canInput) wantCrouch = IsCrouching;

            if (wantCrouch) IsCrouching = true;
            else if (IsCrouching && CanStand()) IsCrouching = false; // 頭上がふさがっていたら立てない

            float targetHeight = IsCrouching ? crouchHeight : standHeight;
            currentHeight = Mathf.MoveTowards(currentHeight, targetHeight,
                crouchTransitionSpeed * (standHeight - crouchHeight) * Time.deltaTime);
            ApplyHeight(currentHeight);
        }

        void ApplyHeight(float height)
        {
            controller.height = height;
            controller.center = new Vector3(0f, height * 0.5f, 0f);

            if (cameraRoot != null)
            {
                // 身長の変化に合わせて目線の高さも補間する
                float t = Mathf.InverseLerp(crouchHeight, standHeight, height);
                Vector3 p = cameraRoot.localPosition;
                p.y = Mathf.Lerp(crouchEyeHeight, standEyeHeight, t);
                cameraRoot.localPosition = p;
            }
        }

        /// <summary>立ち上がるだけの空間が頭上にあるか。</summary>
        bool CanStand()
        {
            float r = controller.radius * 0.9f;
            Vector3 bottom = transform.position + Vector3.up * (r + 0.05f);
            Vector3 top = transform.position + Vector3.up * (standHeight - r);
            return !Physics.CheckCapsule(bottom, top, r, obstacleMask, QueryTriggerInteraction.Ignore);
        }

        void UpdateCursorLock()
        {
            var keyboard = Keyboard.current;
            var mouse = Mouse.current;
            if (keyboard != null && keyboard.escapeKey.wasPressedThisFrame) LockCursor(false);
            else if (mouse != null && mouse.leftButton.wasPressedThisFrame && Cursor.lockState != CursorLockMode.Locked) LockCursor(true);
        }

        static void LockCursor(bool locked)
        {
            Cursor.lockState = locked ? CursorLockMode.Locked : CursorLockMode.None;
            Cursor.visible = !locked;
        }
    }
}
