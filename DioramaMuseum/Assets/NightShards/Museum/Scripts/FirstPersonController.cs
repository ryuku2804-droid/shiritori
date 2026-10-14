using UnityEngine;

namespace NightShards.Museum
{
    // 一人称の歩き。CharacterController を使うので、壁や台座はすり抜けない。
    // 入力は MuseumInput からだけ受け取る。
    //   一歩ごとの歩き: 足で地面をけるたびに少し速くなり、足を運ぶ間は少し遅くなる。視点も一歩ごとに上下し、左右に揺れる
    //   氷の上: 足元のすべりやすさ (SurfaceGrip) が小さいと、なかなか止まれず、曲がりにくく、つるつる滑る
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

        [Header("一歩ごとの歩き")]
        [Tooltip("一歩の長さ (m)。歩くとき")] [SerializeField] float walkStride = 0.75f;
        [Tooltip("一歩の長さ (m)。走るとき")] [SerializeField] float runStride = 1.1f;
        [Tooltip("一歩の中で、速さがどれだけ増えたり減ったりするか (0 で等速)")]
        [SerializeField, Range(0f, 0.6f)] float stepSurge = 0.3f;
        [Tooltip("視点の上下の揺れ (m)")] [SerializeField] float bobHeight = 0.035f;
        [Tooltip("視点の左右の揺れ (m)")] [SerializeField] float bobSway = 0.02f;
        [Tooltip("視点の左右の傾き (度)")] [SerializeField] float bobRoll = 0.6f;
        [Tooltip("走るとき、揺れを何倍にするか")] [SerializeField] float runBobScale = 1.6f;

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

        // 足元のすべりにくさ (0〜1) を返す関数。1 がふつうの地面、0 に近いほど氷のようにつるつる。
        // ジオラマの世界に入ったとき DioramaWorld が設定する。null ならいつも 1
        public System.Func<Vector3, float> SurfaceGrip;

        CharacterController controller;
        Vector3 planarVelocity;
        float verticalVelocity;
        float yaw;
        float pitch;
        float stepPhase;       // 歩きの進み具合 (π で一歩)
        float stepBlend;       // 歩いている度合い (0 止まっている 〜 1 歩いている)。揺れの強さに使う
        float roll;
        Vector3 pivotBase;
        bool pivotReady;

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
            float grip = SurfaceGrip != null && controller.isGrounded ? Mathf.Clamp01(SurfaceGrip(transform.position)) : 1f;

            // 一歩ごとの速さの波: 地面をけった直後に速く、足を運ぶ間は遅い (平均すると、もとの速さ)。
            // 氷の上では足が地面をうまくけれないので、波は小さい
            float surge = 1f + stepSurge * grip * (Mathf.Abs(Mathf.Sin(stepPhase)) - 0.637f);
            Vector3 target = (transform.right * move.x + transform.forward * move.y) * speed * surge;

            // 指数で近づけると、フレームレートが変わっても同じ感触になる。
            // すべりやすいほど近づき方がゆっくりになる = 止まれない・曲がれない・つるつる滑る
            float k = 1f - Mathf.Exp(-acceleration * Mathf.Lerp(0.04f, 1f, grip) * Time.deltaTime);
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

            UpdateSteps(move, grip);
        }

        // 一歩ごとの視点の揺れ。歩きの進み具合を、実際に進んだ速さと一歩の長さから進める
        void UpdateSteps(Vector2 move, float grip)
        {
            if (cameraPivot == null) return;
            if (!pivotReady)
            {
                pivotBase = cameraPivot.localPosition;
                pivotReady = true;
            }

            float moving = controller.isGrounded && move.sqrMagnitude > 0.01f ? 1f : 0f;
            stepBlend = Mathf.MoveTowards(stepBlend, moving, Time.deltaTime * 4f);
            float stride = IsRunning ? runStride : walkStride;
            float flat = new Vector2(planarVelocity.x, planarVelocity.z).magnitude;
            // 氷の上で滑っているだけのときは、足はあまり動かない
            stepPhase += flat / stride * Mathf.PI * Time.deltaTime * moving * Mathf.Lerp(0.4f, 1f, grip);
            if (stepBlend <= 0f) stepPhase = 0f; // 止まったら、次は一歩目から

            float scale = stepBlend * (IsRunning ? runBobScale : 1f);
            float up = (Mathf.Abs(Mathf.Sin(stepPhase)) - 0.5f) * bobHeight * scale; // 一歩ごとに上下 (足をついた瞬間がいちばん低い)
            float side = Mathf.Sin(stepPhase) * bobSway * scale;                    // 右足・左足で左右に揺れる
            cameraPivot.localPosition = pivotBase + new Vector3(side, up, 0f);
            roll = -Mathf.Sin(stepPhase) * bobRoll * scale;
            cameraPivot.localRotation = Quaternion.Euler(pitch, 0f, roll);
        }

        void Look(Vector2 delta)
        {
            yaw += delta.x * lookSensitivity;
            pitch = Mathf.Clamp(pitch - delta.y * lookSensitivity, -pitchLimit, pitchLimit);
            transform.rotation = Quaternion.Euler(0f, yaw, 0f);
            if (cameraPivot != null) cameraPivot.localRotation = Quaternion.Euler(pitch, 0f, roll);
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
            stepPhase = 0f;
            controller.enabled = true;
        }
    }
}
