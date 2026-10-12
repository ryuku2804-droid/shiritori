using UnityEngine;
using UnityEngine.InputSystem;

namespace BlindSpot
{
    /// <summary>
    /// 試作用の画面表示。
    /// 左上: 移動状態・床・足音・怪物の状態など (F1 で表示を切り替え)。
    /// 中央: 照準と、調べられるものの説明。下: 息止めゲージと持ち物。
    /// 1章からは UI Toolkit で作り直す。
    /// </summary>
    public class DebugHud : MonoBehaviour
    {
        [SerializeField] PlayerController player;
        [SerializeField] FootstepNoise footsteps;
        [SerializeField] PlayerInteractor interactor;
        [SerializeField] PlayerThrower thrower;
        [SerializeField] BreathHold breath;
        [SerializeField] MonsterAI monster;
        [SerializeField] bool visible = true;

        GUIStyle style;
        GUIStyle centerStyle;

        void Awake()
        {
            if (player == null) player = GetComponent<PlayerController>();
            if (footsteps == null) footsteps = GetComponent<FootstepNoise>();
            if (interactor == null) interactor = GetComponent<PlayerInteractor>();
            if (thrower == null) thrower = GetComponent<PlayerThrower>();
            if (breath == null) breath = GetComponent<BreathHold>();
        }

        void Start()
        {
            if (monster == null) monster = FindFirstObjectByType<MonsterAI>();
        }

        void Update()
        {
            var keyboard = Keyboard.current;
            if (keyboard != null && keyboard.f1Key.wasPressedThisFrame) visible = !visible;
        }

        void OnGUI()
        {
            if (player == null) return;
            if (style == null)
            {
                style = new GUIStyle(GUI.skin.label) { fontSize = 16 };
                style.normal.textColor = Color.white;
                centerStyle = new GUIStyle(style) { alignment = TextAnchor.MiddleCenter };
            }

            if (visible) DrawDebugText();
            DrawCrosshairAndPrompt();
            DrawBreathGauge();
            DrawInventory();
        }

        void DrawDebugText()
        {
            string text =
                $"状態: {player.State}{(player.IsHidden ? "  (隠れている)" : "")}\n" +
                $"速度: {player.HorizontalSpeed:F2} m/s\n" +
                (footsteps != null
                    ? $"床: {footsteps.CurrentSurface}\n最後の足音: {footsteps.LastStepRadius:F1} m\n"
                    : "") +
                (monster != null
                    ? $"怪物: {monster.State} ({Vector3.Distance(monster.transform.position, player.transform.position):F1} m)\n"
                    : "") +
                (breath != null ? $"心拍: {breath.HeartRate:F0}\n" : "") +
                (NoiseSystem.LastNoise is NoiseEvent n
                    ? $"最後の音: {n.Type} / {n.Radius:F1} m ({Time.time - n.Time:F1} 秒前)\n"
                    : "") +
                "\n[WASD] 移動  [Shift] 走る  [Ctrl / C] しゃがむ\n" +
                "[E] 調べる・隠れる・拾う  [Space 長押し] 息を止める\n" +
                "[左クリック] 投げる  [Q / ホイール] 投げる物を切り替え\n" +
                "[Esc] カーソル解放  [F1] この表示";

            GUI.Box(new Rect(10, 10, 440, 300), GUIContent.none);
            GUI.Label(new Rect(20, 15, 430, 290), text, style);
        }

        void DrawCrosshairAndPrompt()
        {
            float cx = Screen.width / 2f;
            float cy = Screen.height / 2f;
            GUI.DrawTexture(new Rect(cx - 2f, cy - 2f, 4f, 4f), Texture2D.whiteTexture); // 画面中央の小さな点

            if (interactor != null && interactor.CurrentPrompt != null)
            {
                GUI.Label(new Rect(cx - 200f, cy + 20f, 400f, 30f), "[E] " + interactor.CurrentPrompt, centerStyle);
            }
        }

        void DrawBreathGauge()
        {
            if (breath == null) return;
            const float width = 240f;
            const float height = 10f;
            var back = new Rect((Screen.width - width) / 2f, Screen.height - 50f, width, height);

            Color old = GUI.color;
            GUI.color = new Color(0f, 0f, 0f, 0.6f);
            GUI.DrawTexture(back, Texture2D.whiteTexture); // ゲージの背景
            // 咳き込んだ直後は赤、息を止めている間は水色、普段は白
            GUI.color = breath.IsCoughing ? new Color(1f, 0.3f, 0.3f) : breath.IsHolding ? new Color(0.5f, 0.9f, 1f) : Color.white;
            GUI.DrawTexture(new Rect(back.x, back.y, width * breath.Gauge, height), Texture2D.whiteTexture);
            GUI.color = old;

            string label = breath.IsCoughing ? "咳き込んだ!" : breath.IsHolding ? "息を止めている" : "息";
            GUI.Label(new Rect(back.x, back.y - 26f, width, 24f), label, centerStyle);
        }

        void DrawInventory()
        {
            if (thrower == null) return;
            string text = "";
            for (int i = 0; i < ThrowableDefs.TypeCount; i++)
            {
                var type = (ThrowableType)i;
                string mark = type == thrower.Selected && thrower.CountOf(type) > 0 ? "▶" : " ";
                text += $"{mark}{ThrowableDefs.DisplayName(type)} × {thrower.CountOf(type)}\n";
            }
            text += $"合計 {thrower.Total} / {ThrowableDefs.MaxCarry}";
            GUI.Label(new Rect(Screen.width - 170f, Screen.height - 120f, 160f, 110f), text, style);
        }
    }
}
