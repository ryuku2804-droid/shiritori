using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

namespace NightShards.Museum
{
    // VR (Quest 2 など) のコントローラーの入力。MuseumInput がここを見て、キーボードやマウスと同じ意味に読みかえる。
    //   左スティック  歩く (押しこむと走る)       右スティック  左右に倒すと 30 度ずつ向きを変える
    //   トリガー      クリックと同じ (作品の中に入る・中で仕掛け)
    //   A ボタン      近くの作品の仕掛けを動かす    B ボタン      作品の中から美術館に戻る (E と同じ)
    // VR の機器がつながっていないときは、何もしない (Active が false)
    public static class VRInput
    {
        public static bool Active => XRSettings.isDeviceActive;

        public static Vector2 Move { get { Refresh(); return move; } }
        public static bool RunHeld { get { Refresh(); return runHeld; } }
        public static bool TriggerPressed { get { Refresh(); return Edge(1); } }
        public static bool TriggerReleased { get { Refresh(); return (prev & 1) != 0 && (now & 1) == 0; } }
        public static bool TriggerHeld { get { Refresh(); return (now & 1) != 0; } }
        public static bool APressed { get { Refresh(); return Edge(2); } }
        public static bool BPressed { get { Refresh(); return Edge(4); } }
        // 右スティックを左右に倒した瞬間: -1 / +1。それ以外は 0
        public static int SnapTurn { get { Refresh(); return snap; } }

        static int frame = -1;
        static int now, prev;
        static Vector2 move;
        static bool runHeld;
        static int snap;
        static bool turnArmed = true;
        static readonly List<InputDevice> found = new List<InputDevice>();

        static bool Edge(int bit) => (now & bit) != 0 && (prev & bit) == 0;

        // 1 フレームに 1 回だけ、コントローラーの状態を読む
        static void Refresh()
        {
            if (frame == Time.frameCount) return;
            frame = Time.frameCount;
            prev = now;
            now = 0;
            move = Vector2.zero;
            runHeld = false;
            snap = 0;
            if (!Active) return;

            InputDevice left = Device(InputDeviceCharacteristics.Left | InputDeviceCharacteristics.Controller);
            InputDevice right = Device(InputDeviceCharacteristics.Right | InputDeviceCharacteristics.Controller);

            if (left.isValid)
            {
                left.TryGetFeatureValue(CommonUsages.primary2DAxis, out move);
                if (move.magnitude < 0.15f) move = Vector2.zero; // スティックの遊び
                left.TryGetFeatureValue(CommonUsages.primary2DAxisClick, out runHeld);
            }
            if (right.isValid)
            {
                if (right.TryGetFeatureValue(CommonUsages.triggerButton, out bool trig) && trig) now |= 1;
                if (right.TryGetFeatureValue(CommonUsages.primaryButton, out bool a) && a) now |= 2;
                if (right.TryGetFeatureValue(CommonUsages.secondaryButton, out bool b) && b) now |= 4;
                right.TryGetFeatureValue(CommonUsages.primary2DAxis, out Vector2 stick);
                // 一度倒したら、真ん中にもどすまで次の向き変えはしない
                if (turnArmed && Mathf.Abs(stick.x) > 0.7f) { snap = stick.x > 0f ? 1 : -1; turnArmed = false; }
                else if (Mathf.Abs(stick.x) < 0.3f) turnArmed = true;
            }
            // 左手のトリガーでも、クリックできるようにする
            if (left.isValid && left.TryGetFeatureValue(CommonUsages.triggerButton, out bool ltrig) && ltrig) now |= 1;
        }

        static InputDevice Device(InputDeviceCharacteristics c)
        {
            InputDevices.GetDevicesWithCharacteristics(c, found);
            return found.Count > 0 ? found[0] : default;
        }
    }

    // VR の頭の動きを、カメラに写す。再生を始めると自動で動く (VR の機器がつながっているときだけ働く)。
    //   ・頭の位置と向きを、目の高さの位置 (cameraPivot) からの動きとして、カメラに入れる
    //   ・はじめに、いまの頭の位置を真ん中にする (立っていても座っていても、目の高さは美術館の目の高さ)
    //   ・A ボタンで、いちばん近い作品の仕掛けを動かす
    //   ・Quest の画面のまわりを少し粗く描いて (フォービエイテッド)、軽くする
    [DefaultExecutionOrder(1000)] // 鑑賞のカメラの動きなど、ほかのスクリプトのあとに上書きする
    public class VRRig : MonoBehaviour
    {
        static readonly List<XRInputSubsystem> inputs = new List<XRInputSubsystem>();
        static readonly List<XRDisplaySubsystem> displays = new List<XRDisplaySubsystem>();

        Transform cam;
        Vector3 center;
        bool centered;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Create()
        {
            if (FindFirstObjectByType<VRRig>() != null) return;
            var go = new GameObject("VR Rig");
            DontDestroyOnLoad(go);
            go.AddComponent<VRRig>();
        }

        void OnEnable() { Application.onBeforeRender += ApplyHead; }
        void OnDisable() { Application.onBeforeRender -= ApplyHead; }

        void Start()
        {
            if (!VRInput.Active) return;
            AutoQuality.TargetFps = 72f; // Quest 2 の画面は 1 秒に 72 回
            // 床からの高さではなく「はじめの頭の位置」を真ん中にする
            SubsystemManager.GetSubsystems(inputs);
            foreach (var s in inputs) s.TrySetTrackingOriginMode(TrackingOriginModeFlags.Device);
            // フォービエイテッド: 視野のまわりを粗く描く (Quest で大きく軽くなる)
            SubsystemManager.GetSubsystems(displays);
            foreach (var d in displays) d.foveatedRenderingLevel = 1f;
        }

        void LateUpdate()
        {
            if (!VRInput.Active) return;
            if (VRInput.APressed) TriggerNearest();
            ApplyHead();
        }

        void ApplyHead()
        {
            if (!VRInput.Active) return;
            if (cam == null)
            {
                var fp = FindFirstObjectByType<FirstPersonController>();
                if (fp == null || fp.cameraPivot == null || fp.cameraPivot.childCount == 0) return;
                cam = fp.cameraPivot.GetChild(0);
            }
            InputDevice head = InputDevices.GetDeviceAtXRNode(XRNode.CenterEye);
            if (!head.isValid) head = InputDevices.GetDeviceAtXRNode(XRNode.Head);
            if (!head.isValid) return;
            if (!head.TryGetFeatureValue(CommonUsages.centerEyePosition, out Vector3 pos))
                head.TryGetFeatureValue(CommonUsages.devicePosition, out pos);
            if (!head.TryGetFeatureValue(CommonUsages.centerEyeRotation, out Quaternion rot))
                head.TryGetFeatureValue(CommonUsages.deviceRotation, out rot);
            if (!centered) { center = pos; centered = true; }
            cam.localPosition = pos - center;
            cam.localRotation = rot;
        }

        // いちばん近く (3 m 以内) の作品の仕掛けを動かす
        static void TriggerNearest()
        {
            Camera c = Camera.main;
            if (c == null) return;
            ExhibitStand best = null;
            float bestDist = 3f;
            foreach (var stand in ExhibitStand.All)
            {
                if (stand == null || stand.Work == null || stand.Diorama == null || !stand.Diorama.enabled) continue;
                float d = Vector3.Distance(c.transform.position, stand.Diorama.transform.position);
                if (d < bestDist) { bestDist = d; best = stand; }
            }
            if (best != null) best.Work.Trigger();
        }
    }
}
