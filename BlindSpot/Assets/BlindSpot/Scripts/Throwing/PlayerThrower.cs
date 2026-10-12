using UnityEngine;
using UnityEngine.InputSystem;

namespace BlindSpot
{
    /// <summary>
    /// 拾った投擲物を持ち、左クリックで投げる。Q かマウスホイールで種類を切り替える。Player に付ける。
    /// </summary>
    [RequireComponent(typeof(PlayerController))]
    public class PlayerThrower : MonoBehaviour
    {
        [Tooltip("前へ投げる速さ (m/秒)")]
        [SerializeField] float throwSpeed = 11f;
        [Tooltip("上向きに足す速さ (m/秒)。少し山なりに飛ぶ")]
        [SerializeField] float upwardSpeed = 2f;
        [Tooltip("目の前の何 m の位置から投げ始めるか")]
        [SerializeField] float spawnDistance = 0.45f;

        /// <summary>今選んでいる種類。</summary>
        public ThrowableType Selected { get; private set; }

        /// <summary>持っている合計の数。</summary>
        public int Total
        {
            get
            {
                int sum = 0;
                foreach (int c in counts) sum += c;
                return sum;
            }
        }

        public bool CanAdd => Total < ThrowableDefs.MaxCarry;

        public int CountOf(ThrowableType type) => counts[(int)type];

        readonly int[] counts = new int[ThrowableDefs.TypeCount];
        readonly Material[] materials = new Material[ThrowableDefs.TypeCount];

        PlayerController player;
        CharacterController body;
        InputAction throwAction, nextAction, scrollAction;

        void Awake()
        {
            player = GetComponent<PlayerController>();
            body = GetComponent<CharacterController>();

            throwAction = new InputAction("Throw", InputActionType.Button, "<Mouse>/leftButton");
            throwAction.AddBinding("<Gamepad>/rightTrigger");
            nextAction = new InputAction("NextItem", InputActionType.Button, "<Keyboard>/q");
            nextAction.AddBinding("<Gamepad>/dpad/right");
            scrollAction = new InputAction("ScrollItem", InputActionType.PassThrough, "<Mouse>/scroll/y");
        }

        void OnEnable()
        {
            throwAction.Enable();
            nextAction.Enable();
            scrollAction.Enable();
        }

        void OnDisable()
        {
            throwAction.Disable();
            nextAction.Disable();
            scrollAction.Disable();
        }

        void OnDestroy()
        {
            throwAction.Dispose();
            nextAction.Dispose();
            scrollAction.Dispose();
        }

        /// <summary>拾った物を足す。持ちきれなければ false。</summary>
        public bool Add(ThrowableType type, Material material)
        {
            if (!CanAdd) return false;
            counts[(int)type]++;
            if (material != null) materials[(int)type] = material;
            if (CountOf(Selected) == 0) Selected = type; // 何も持っていなかったら、拾った物を選ぶ
            return true;
        }

        void Update()
        {
            // 捕まった後やロッカーの中では投げられない
            if (!player.InputEnabled || !player.MovementEnabled) return;

            float scroll = scrollAction.ReadValue<float>();
            if (nextAction.WasPressedThisFrame() || scroll > 0.1f) SelectNext(1);
            else if (scroll < -0.1f) SelectNext(-1);

            // カーソルが外れているときの左クリックは「カーソルを戻す」操作なので、投げない
            if (throwAction.WasPressedThisFrame() && Cursor.lockState == CursorLockMode.Locked) Throw();
        }

        /// <summary>持っている種類の中で、次 (dir = 1) か前 (dir = -1) の種類を選ぶ。</summary>
        void SelectNext(int dir)
        {
            for (int i = 1; i <= ThrowableDefs.TypeCount; i++)
            {
                int index = ((int)Selected + dir * i + ThrowableDefs.TypeCount) % ThrowableDefs.TypeCount;
                if (counts[index] > 0)
                {
                    Selected = (ThrowableType)index;
                    return;
                }
            }
        }

        void Throw()
        {
            if (CountOf(Selected) == 0) SelectNext(1);
            if (CountOf(Selected) == 0) return; // 何も持っていない

            ThrowableType type = Selected;
            counts[(int)type]--;

            Transform eye = player.CameraRoot;
            GameObject go = ThrowableDefs.CreateObject(type, materials[(int)type]);
            go.transform.position = eye.position + eye.forward * spawnDistance;

            var rb = go.AddComponent<Rigidbody>();
            rb.mass = 0.3f;
            rb.interpolation = RigidbodyInterpolation.Interpolate;              // 動きをなめらかに見せる
            rb.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic; // 速くても壁をすり抜けない
            rb.linearVelocity = eye.forward * throwSpeed + Vector3.up * upwardSpeed;
            rb.angularVelocity = Random.insideUnitSphere * 10f;                  // 回転しながら飛ぶ

            Physics.IgnoreCollision(go.GetComponent<Collider>(), body); // 投げた瞬間に自分の体に当たらないように
            go.AddComponent<ThrownObject>().Setup(type);

            if (CountOf(type) == 0) SelectNext(1);
        }
    }
}
