using UnityEngine;

namespace NightShards.Museum
{
    // 鑑賞モード。プレイヤーに付ける。
    //   歩いているとき: 近くて視線の先にある作品を探し、「E で鑑賞」を出す
    //   E を押すと: カメラがなめらかに作品の前へ移り、ドラッグで 360° 回せる・ホイールで寄れる
    //   もう一度 E か Esc: カメラが目の位置へなめらかに戻り、歩きに戻る
    public class ExhibitViewer : MonoBehaviour
    {
        [Header("作品を見つける")]
        [Tooltip("この距離 (m) より近い作品だけを対象にする")]
        [SerializeField] float reach = 3f;
        [Tooltip("視線と作品の方向のずれの許容。1 に近いほど、まっすぐ見ていないと反応しない")]
        [SerializeField, Range(0f, 1f)] float lookCone = 0.8f;

        [Header("鑑賞モード")]
        [Tooltip("カメラの切り替えにかける秒数")]
        [SerializeField] float blendTime = 0.8f;
        [Tooltip("ドラッグの回りやすさ")]
        [SerializeField] float dragSensitivity = 3f;
        [Tooltip("キーボード (A/D・W/S) で回すときの速さ (度/秒)")]
        [SerializeField] float keyTurnSpeed = 90f;
        [Tooltip("見上げ・見下ろしの角度の範囲 (度)")]
        [SerializeField] Vector2 pitchRange = new Vector2(-5f, 75f);
        [Tooltip("作品からの距離の範囲 (m)")]
        [SerializeField] Vector2 distanceRange = new Vector2(0.6f, 3f);
        [Tooltip("回転とズームの追いつく速さ。大きいほどきびきび動く")]
        [SerializeField] float smoothing = 10f;

        public Transform cameraTransform;
        public FirstPersonController body;

        public ExhibitStand Current { get; private set; }
        public bool IsViewing => mode != Mode.Walking;
        // 0 = 目の位置、1 = 鑑賞の位置 (画面の仕上げのぼかしに使う)
        public float Blend => blend * blend * (3f - 2f * blend);

        enum Mode { Walking, Viewing, Leaving }
        Mode mode = Mode.Walking;

        float blend;                    // 0 = 目の位置、1 = 鑑賞の位置
        float yaw, pitch, distance;     // いまの値
        float yawGoal, pitchGoal, distanceGoal;

        void Update()
        {
            if (cameraTransform == null || body == null) return;

            switch (mode)
            {
                case Mode.Walking:
                    var near = FindNearest();
                    SetPrompt(near != null ? $"E で鑑賞　{near.Title}" : "");
                    if (near != null && MuseumInput.InteractPressed) Enter(near);
                    break;

                case Mode.Viewing:
                    if (MuseumInput.InteractPressed || MuseumInput.BackPressed) Leave();
                    else
                    {
                        // Space: 作品の仕掛けを動かす
                        if (MuseumInput.JumpPressed && Current.Work != null) Current.Work.Trigger();
                        ReadOrbitInput();
                    }
                    break;
            }

            UpdateCamera();
        }

        // ---------------------------------------------------------------- 作品を探す

        ExhibitStand FindNearest()
        {
            ExhibitStand best = null;
            float bestScore = float.NegativeInfinity;
            Vector3 eye = cameraTransform.position;
            Vector3 forward = cameraTransform.forward;
            foreach (var stand in ExhibitStand.All)
            {
                if (stand == null) continue;
                Vector3 to = stand.FocusPoint - eye;
                float dist = to.magnitude;
                if (dist > reach || dist < 0.01f) continue;
                float dot = Vector3.Dot(forward, to / dist);
                if (dot < lookCone) continue;
                float score = dot - dist * 0.1f; // まっすぐ見ていて、近いものほど優先
                if (score > bestScore)
                {
                    bestScore = score;
                    best = stand;
                }
            }
            return best;
        }

        // ---------------------------------------------------------------- 切り替え

        void Enter(ExhibitStand stand)
        {
            Current = stand;
            mode = Mode.Viewing;

            // 今いる側から見始める。高さの角度も今の目線から決める
            Vector3 from = cameraTransform.position - stand.FocusPoint;
            yaw = yawGoal = Mathf.Atan2(from.x, from.z) * Mathf.Rad2Deg + 180f;
            float flat = new Vector2(from.x, from.z).magnitude;
            pitch = pitchGoal = Mathf.Clamp(Mathf.Atan2(from.y, flat) * Mathf.Rad2Deg + 10f, pitchRange.x, pitchRange.y);
            distance = distanceGoal = Mathf.Clamp(stand.ViewDistance, distanceRange.x, distanceRange.y);

            body.InputEnabled = false;
            body.ManageCursor = false;
            FirstPersonController.SetCursorLocked(false); // ドラッグするのでカーソルを出す
            SetPrompt("");
            string trick = stand.Work != null ? "　　Space  仕掛け" : "";
            SetHint($"{stand.Title}　　ドラッグ  回す　　ホイール  寄る・離れる{trick}　　E / Esc  戻る");
            if (MuseumHUD.Instance != null) MuseumHUD.Instance.ShowCrosshair = false;
        }

        void Leave()
        {
            mode = Mode.Leaving;
            SetHint("");
        }

        void FinishLeaving()
        {
            mode = Mode.Walking;
            Current = null;
            cameraTransform.localPosition = Vector3.zero;
            cameraTransform.localRotation = Quaternion.identity;
            body.InputEnabled = true;
            body.ManageCursor = true;
            FirstPersonController.SetCursorLocked(true);
            if (MuseumHUD.Instance != null) MuseumHUD.Instance.ShowCrosshair = true;
        }

        // ---------------------------------------------------------------- 回す・寄る

        void ReadOrbitInput()
        {
            if (MuseumInput.ClickHeld)
            {
                Vector2 d = MuseumInput.Look * dragSensitivity;
                yawGoal += d.x;
                pitchGoal -= d.y;
            }
            // キーボードでも回せるようにする (A/D で左右、W/S で上下)
            Vector2 k = MuseumInput.Move;
            yawGoal -= k.x * keyTurnSpeed * Time.deltaTime;
            pitchGoal += k.y * keyTurnSpeed * 0.5f * Time.deltaTime;
            pitchGoal = Mathf.Clamp(pitchGoal, pitchRange.x, pitchRange.y);

            float zoom = MuseumInput.Zoom;
            if (Mathf.Abs(zoom) > 0.001f)
                distanceGoal = Mathf.Clamp(distanceGoal * (1f - zoom * 0.12f), distanceRange.x, distanceRange.y);
        }

        void UpdateCamera()
        {
            if (mode == Mode.Walking) return;

            // 回転とズームは目標になめらかに追いつかせる
            float k = 1f - Mathf.Exp(-smoothing * Time.deltaTime);
            yaw = Mathf.Lerp(yaw, yawGoal, k);
            pitch = Mathf.Lerp(pitch, pitchGoal, k);
            distance = Mathf.Lerp(distance, distanceGoal, k);

            float step = Time.deltaTime / Mathf.Max(0.01f, blendTime);
            blend = mode == Mode.Viewing ? Mathf.Min(1f, blend + step) : Mathf.Max(0f, blend - step);
            float t = blend * blend * (3f - 2f * blend); // ゆっくり動き出して、ゆっくり止まる

            // 鑑賞の位置: 作品の中心から、yaw・pitch の向きに distance だけ離れた所から中心を見る
            Vector3 center = Current.FocusPoint;
            Quaternion orbit = Quaternion.Euler(pitch, yaw, 0f);
            Vector3 orbitPos = center + orbit * new Vector3(0f, 0f, -distance);
            // 仕掛けが動いている間は、地響きのようにカメラを小さく揺らす
            if (Current.Work != null && Current.Work.Value > 0f)
            {
                float s = Time.time * 23f;
                var shake = new Vector3(Mathf.PerlinNoise(s, 0.1f) - 0.5f, Mathf.PerlinNoise(0.3f, s) - 0.5f, Mathf.PerlinNoise(s, 0.7f) - 0.5f);
                orbitPos += shake * (0.012f * Current.Work.Value * distance);
            }
            Quaternion orbitRot = Quaternion.LookRotation(center - orbitPos);

            // 目の位置 (カメラの親) と鑑賞の位置のあいだを t で混ぜる
            Transform eye = cameraTransform.parent;
            cameraTransform.position = Vector3.Lerp(eye.position, orbitPos, t);
            cameraTransform.rotation = Quaternion.Slerp(eye.rotation, orbitRot, t);

            if (mode == Mode.Leaving && blend <= 0f) FinishLeaving();
        }

        static void SetPrompt(string text)
        {
            if (MuseumHUD.Instance != null) MuseumHUD.Instance.Prompt = text;
        }

        static void SetHint(string text)
        {
            if (MuseumHUD.Instance != null) MuseumHUD.Instance.Hint = text;
        }
    }
}
