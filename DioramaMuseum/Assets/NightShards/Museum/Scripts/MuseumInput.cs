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
        enum K { W, A, S, D, Up, Down, Left, Right, LeftShift, RightShift, Space, E, Escape, H }

        // WASD / 矢印キー。x: 左右、y: 前後 (-1〜1)
        public static Vector2 Move
        {
            get
            {
                float x = (Held(K.D) || Held(K.Right) ? 1f : 0f) - (Held(K.A) || Held(K.Left) ? 1f : 0f);
                float y = (Held(K.W) || Held(K.Up) ? 1f : 0f) - (Held(K.S) || Held(K.Down) ? 1f : 0f);
                return Vector2.ClampMagnitude(new Vector2(x, y), 1f);
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

        public static bool Run => Held(K.LeftShift) || Held(K.RightShift);
        public static bool JumpPressed => Pressed(K.Space);
        public static bool InteractPressed => Pressed(K.E);
        public static bool BackPressed => Pressed(K.Escape);
        public static bool HelpPressed => Pressed(K.H);

        // 左クリック (押した瞬間 / 押している間)
        public static bool ClickPressed
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return m != null && m.leftButton.wasPressedThisFrame;
#else
                return Input.GetMouseButtonDown(0);
#endif
            }
        }

        public static bool ClickHeld
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                var m = Mouse.current;
                return m != null && m.leftButton.isPressed;
#else
                return Input.GetMouseButton(0);
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
                default: return KeyCode.H;
            }
        }
#endif
    }
}
