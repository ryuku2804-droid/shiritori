using UnityEngine;
using UnityEngine.InputSystem;

namespace BlindSpot
{
    /// <summary>
    /// 試作用の情報表示。画面左上に移動状態・床・足音の距離などを出す。
    /// F1 キーで表示を切り替える。本番では外してよい。
    /// </summary>
    public class DebugHud : MonoBehaviour
    {
        [SerializeField] PlayerController player;
        [SerializeField] FootstepNoise footsteps;
        [SerializeField] bool visible = true;

        GUIStyle style;

        void Awake()
        {
            if (player == null) player = GetComponent<PlayerController>();
            if (footsteps == null) footsteps = GetComponent<FootstepNoise>();
        }

        void Update()
        {
            var keyboard = Keyboard.current;
            if (keyboard != null && keyboard.f1Key.wasPressedThisFrame) visible = !visible;
        }

        void OnGUI()
        {
            if (!visible || player == null) return;
            if (style == null)
            {
                style = new GUIStyle(GUI.skin.label) { fontSize = 16 };
                style.normal.textColor = Color.white;
            }

            string text =
                $"状態: {player.State}\n" +
                $"速度: {player.HorizontalSpeed:F2} m/s\n" +
                (footsteps != null
                    ? $"床: {footsteps.CurrentSurface}\n最後の足音: {footsteps.LastStepRadius:F1} m\n"
                    : "") +
                (NoiseSystem.LastNoise is NoiseEvent n
                    ? $"最後の音: {n.Type} / {n.Radius:F1} m ({Time.time - n.Time:F1} 秒前)\n"
                    : "") +
                "\n[WASD] 移動  [Shift] 走る  [Ctrl / C] しゃがむ\n[Esc] カーソル解放  [F1] この表示";

            GUI.Box(new Rect(10, 10, 360, 190), GUIContent.none);
            GUI.Label(new Rect(20, 15, 350, 185), text, style);
        }
    }
}
