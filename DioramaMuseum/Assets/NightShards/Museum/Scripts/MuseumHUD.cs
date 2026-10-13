using UnityEngine;

namespace NightShards.Museum
{
    // 画面の表示 (照準の点、操作説明、「E で鑑賞」などの案内)。
    // 外部の UI パッケージに頼らないよう、IMGUI (OnGUI) で描く。VR では画面に貼る UI が使えないので、段階7で空間に置く表示に替える
    public class MuseumHUD : MonoBehaviour
    {
        public static MuseumHUD Instance { get; private set; }

        [SerializeField] string title = "ジオラマ美術館";
        [SerializeField] float introDuration = 6f;
        [SerializeField] float introFade = 1.5f;

        // 画面中央の下に出す案内。空なら出さない
        public string Prompt { get; set; } = "";

        // 画面の下に出す操作の案内 (鑑賞モードの操作など)。空なら出さない
        public string Hint { get; set; } = "";

        // false にすると照準の点を隠す (鑑賞モードの間など)
        public bool ShowCrosshair { get; set; } = true;

        static readonly string[] HelpLines =
        {
            "WASD  歩く　　マウス  見回す",
            "Shift  走る　　Space  ジャンプ",
            "作品に近づいて  E  鑑賞する",
            "Esc  カーソルを外す　　クリック  戻る",
            "H  この説明をもう一度",
        };

        float introStart;
        GUIStyle titleStyle, bodyStyle, promptStyle;
        int styledForHeight;

        void Awake()
        {
            Instance = this;
            introStart = Time.time;
        }

        void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        void Update()
        {
            if (MuseumInput.HelpPressed) introStart = Time.time;
        }

        void OnGUI()
        {
            float scale = Screen.height / 1080f;
            if (titleStyle == null || styledForHeight != Screen.height) BuildStyles(scale);

            if (ShowCrosshair) DrawCrosshair(scale);

            if (!string.IsNullOrEmpty(Prompt))
            {
                var r = new Rect(0f, Screen.height * 0.5f + 40f * scale, Screen.width, 40f * scale);
                Shadowed(r, Prompt, promptStyle, 1f);
            }

            if (!string.IsNullOrEmpty(Hint))
            {
                var r = new Rect(0f, Screen.height - 70f * scale, Screen.width, 40f * scale);
                Fill(new Rect(0f, r.y - 6f * scale, Screen.width, r.height + 12f * scale), new Color(0f, 0f, 0f, 0.35f));
                Shadowed(r, Hint, bodyStyle, 1f);
            }

            float alpha = IntroAlpha();
            if (alpha > 0f) DrawIntro(scale, alpha);
        }

        // 表示してから introDuration 秒たったら、introFade 秒かけて消える
        float IntroAlpha()
        {
            float t = Time.time - introStart;
            if (t < introDuration) return Mathf.Clamp01(t / 0.6f);
            return 1f - Mathf.Clamp01((t - introDuration) / introFade);
        }

        void DrawCrosshair(float scale)
        {
            float outer = Mathf.Max(4f, 6f * scale);
            float inner = Mathf.Max(2f, 3f * scale);
            Vector2 c = new Vector2(Screen.width * 0.5f, Screen.height * 0.5f);
            Fill(new Rect(c.x - outer * 0.5f, c.y - outer * 0.5f, outer, outer), new Color(0f, 0f, 0f, 0.35f));
            Fill(new Rect(c.x - inner * 0.5f, c.y - inner * 0.5f, inner, inner), new Color(1f, 1f, 1f, 0.8f));
        }

        void DrawIntro(float scale, float alpha)
        {
            float w = 620f * scale;
            float lineH = 34f * scale;
            float h = 90f * scale + lineH * HelpLines.Length;
            var box = new Rect((Screen.width - w) * 0.5f, Screen.height * 0.68f, w, h);

            Fill(box, new Color(0.02f, 0.02f, 0.03f, 0.55f * alpha));
            Fill(new Rect(box.x, box.y, box.width, Mathf.Max(1f, 2f * scale)), new Color(1f, 1f, 1f, 0.25f * alpha));

            Shadowed(new Rect(box.x, box.y + 18f * scale, box.width, 44f * scale), title, titleStyle, alpha);
            for (int i = 0; i < HelpLines.Length; i++)
            {
                var r = new Rect(box.x, box.y + 70f * scale + lineH * i, box.width, lineH);
                Shadowed(r, HelpLines[i], bodyStyle, alpha);
            }
        }

        void BuildStyles(float scale)
        {
            styledForHeight = Screen.height;
            titleStyle = new GUIStyle(GUI.skin.label)
            {
                alignment = TextAnchor.MiddleCenter,
                fontSize = Mathf.RoundToInt(30f * scale),
                fontStyle = FontStyle.Bold,
            };
            bodyStyle = new GUIStyle(GUI.skin.label)
            {
                alignment = TextAnchor.MiddleCenter,
                fontSize = Mathf.RoundToInt(20f * scale),
            };
            promptStyle = new GUIStyle(bodyStyle) { fontSize = Mathf.RoundToInt(22f * scale) };
        }

        // 文字の後ろに薄い影を付けて、明るい背景でも読めるようにする
        static void Shadowed(Rect r, string text, GUIStyle style, float alpha)
        {
            var prev = GUI.color;
            GUI.color = new Color(0f, 0f, 0f, 0.6f * alpha);
            GUI.Label(new Rect(r.x + 1f, r.y + 2f, r.width, r.height), text, style);
            GUI.color = new Color(1f, 0.97f, 0.92f, alpha);
            GUI.Label(r, text, style);
            GUI.color = prev;
        }

        static void Fill(Rect r, Color color)
        {
            var prev = GUI.color;
            GUI.color = color;
            GUI.DrawTexture(r, Texture2D.whiteTexture);
            GUI.color = prev;
        }
    }
}
