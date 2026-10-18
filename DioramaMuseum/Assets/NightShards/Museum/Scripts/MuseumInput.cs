using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.Controls;
#endif

namespace NightShards.Museum
{
    // 入力をまとめて受け持つ。ほかのスクリプトは「移動」「視点」「鑑賞」のような意味で入力を受け取り、
    // キーやデバイスのことは知らない。VR を足すときは、ここに VR コントローラーの入力を足すだけで済む。
    //
    // Player Settings > Active Input Handling が
    //   Input System Package (New) / Both  → 新しい Input System を使う
    //   Input Manager (Old)                → 旧 Input Manager を使う
    public static class MuseumInput
    {
        enum K { W, A, S, D, Up, Down, Left, Right, LeftShift, RightShift, Space, E, Escape, H, F1, F2, F3, F4, F5 }

        // WASD / 矢印キー。x: 左右、y: 前後 (-1〜1)
        public static Vector2 Move
        {
            get
            {
                float x = (Held(K.D) || Held(K.Right) ? 1f : 0f) - (Held(K.A) || Held(K.Left) ? 1f : 0f);
                float y = (Held(K.W) || Held(K.Up) ? 1f : 0f) - (Held(K.S) || Held(K.Down) ? 1f : 0f);
                Vector2 v = new Vector2(x, y) + VRInput.Move; // VR の左スティック
                return Vector2.ClampMagnitude(v, 1f);
            }
        }

        // マウスの動き。旧 Input Manager の "Mouse X" と同じ大きさにそろえる (1ピクセル = 0.1)
        public static Vector2 Look
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return m == null ? Vector2.zero : m.delta.ReadValue() * 0.1f;
#else
                return new Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y"));
#endif
            }
        }

        // ホイール。1目盛りでおよそ ±1
        public static float Zoom
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                if (m == null) return 0f;
                float v = m.scroll.ReadValue().y;
                return Mathf.Abs(v) > 10f ? v / 120f : v; // 環境によって 120 単位で来るのでそろえる
#else
                return Input.mouseScrollDelta.y;
#endif
            }
        }

        public static bool Run => Held(K.LeftShift) || Held(K.RightShift) || VRInput.RunHeld;
        public static bool JumpPressed => Pressed(K.Space); // VR ではジャンプしない (A ボタンは仕掛け: VRRig)
        public static bool InteractPressed => Pressed(K.E) || VRInput.BPressed;
        public static bool BackPressed => Pressed(K.Escape);
        public static bool HelpPressed => Pressed(K.H);

        // F1〜F5 (重さを調べる切り替え用)。n は 1〜5
        public static bool FunctionKeyPressed(int n)
        {
            switch (n)
            {
                case 1: return Pressed(K.F1);
                case 2: return Pressed(K.F2);
                case 3: return Pressed(K.F3);
                case 4: return Pressed(K.F4);
                case 5: return Pressed(K.F5);
                default: return false;
            }
        }

        // 左クリック (押した瞬間 / 押している間)
        public static bool ClickPressed
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return (m != null && m.leftButton.wasPressedThisFrame) || VRInput.TriggerPressed;
#else
                return Input.GetMouseButtonDown(0) || VRInput.TriggerPressed;
#endif
            }
        }

        // 左ボタンを離した瞬間
        public static bool ClickReleased
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return (m != null && m.leftButton.wasReleasedThisFrame) || VRInput.TriggerReleased;
#else
                return Input.GetMouseButtonUp(0) || VRInput.TriggerReleased;
#endif
            }
        }

        public static bool ClickHeld
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return (m != null && m.leftButton.isPressed) || VRInput.TriggerHeld;
#else
                return Input.GetMouseButton(0) || VRInput.TriggerHeld;
#endif
            }
        }

        static bool Held(K k)
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            return kb != null && Key(kb, k).isPressed;
#else
            return Input.GetKey(Code(k));
#endif
        }

        static bool Pressed(K k)
        {
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            return kb != null && Key(kb, k).wasPressedThisFrame;
#else
            return Input.GetKeyDown(Code(k));
#endif
        }

#if ENABLE_INPUT_SYSTEM
        static KeyControl Key(Keyboard kb, K k)
        {
            switch (k)
            {
                case K.W: return kb.wKey;
                case K.A: return kb.aKey;
                case K.S: return kb.sKey;
                case K.D: return kb.dKey;
                case K.Up: return kb.upArrowKey;
                case K.Down: return kb.downArrowKey;
                case K.Left: return kb.leftArrowKey;
                case K.Right: return kb.rightArrowKey;
                case K.LeftShift: return kb.leftShiftKey;
                case K.RightShift: return kb.rightShiftKey;
                case K.Space: return kb.spaceKey;
                case K.E: return kb.eKey;
                case K.Escape: return kb.escapeKey;
                case K.F1: return kb.f1Key;
                case K.F2: return kb.f2Key;
                case K.F3: return kb.f3Key;
                case K.F4: return kb.f4Key;
                case K.F5: return kb.f5Key;
                default: return kb.hKey;
            }
        }
#else
        static KeyCode Code(K k)
        {
            switch (k)
            {
                case K.W: return KeyCode.W;
                case K.A: return KeyCode.A;
                case K.S: return KeyCode.S;
                case K.D: return KeyCode.D;
                case K.Up: return KeyCode.UpArrow;
                case K.Down: return KeyCode.DownArrow;
                case K.Left: return KeyCode.LeftArrow;
                case K.Right: return KeyCode.RightArrow;
                case K.LeftShift: return KeyCode.LeftShift;
                case K.RightShift: return KeyCode.RightShift;
                case K.Space: return KeyCode.Space;
                case K.E: return KeyCode.E;
                case K.Escape: return KeyCode.Escape;
                case K.F1: return KeyCode.F1;
                case K.F2: return KeyCode.F2;
                case K.F3: return KeyCode.F3;
                case K.F4: return KeyCode.F4;
                case K.F5: return KeyCode.F5;
                default: return KeyCode.H;
            }
        }
#endif
    }
}
