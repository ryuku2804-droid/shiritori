using UnityEngine;

namespace EchoKnight
{
    /// <summary>Shared look for the few lines of text the game shows (there is no other HUD).</summary>
    public static class EchoScreenText
    {
        static GUIStyle speakerStyle, lineStyle, instructionStyle, titleStyle, subtitleStyle;
        static int builtForHeight;

        static void Ensure()
        {
            if (speakerStyle != null && builtForHeight == Screen.height) return;
            builtForHeight = Screen.height;
            int u = Mathf.Max(12, Screen.height / 45);
            speakerStyle = Make(Mathf.RoundToInt(u * 0.85f), new Color(1f, 0.8f, 0.45f), FontStyle.Normal);
            lineStyle = Make(Mathf.RoundToInt(u * 1.15f), new Color(0.93f, 0.93f, 0.97f), FontStyle.Normal);
            instructionStyle = Make(Mathf.RoundToInt(u * 0.9f), new Color(0.65f, 0.67f, 0.72f), FontStyle.Normal);
            titleStyle = Make(Mathf.RoundToInt(u * 2.0f), new Color(1f, 0.86f, 0.55f), FontStyle.Normal);
            subtitleStyle = Make(Mathf.RoundToInt(u * 1.05f), new Color(0.85f, 0.85f, 0.9f), FontStyle.Normal);
        }

        static GUIStyle Make(int size, Color color, FontStyle font)
        {
            var s = new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter, fontSize = size, fontStyle = font, wordWrap = true };
            s.normal.textColor = color;
            return s;
        }

        /// <summary>Text with a soft drop shadow, so it stays readable when an echo lights up the stones behind it.</summary>
        public static void Label(Rect r, string text, GUIStyle style, float alpha)
        {
            if (string.IsNullOrEmpty(text)) return;
            Color old = GUI.color;
            GUI.color = new Color(0f, 0f, 0f, alpha * 0.8f);
            GUI.Label(new Rect(r.x + 2f, r.y + 2f, r.width, r.height), text, style);   // shadow
            GUI.color = new Color(1f, 1f, 1f, alpha);
            GUI.Label(r, text, style);
            GUI.color = old;
        }

        /// <summary>Story line and / or instruction in the lower part of the screen.</summary>
        // Several things may speak at once (a hint, a memory echo, Rine). Each block of text drawn in
        // the same GUI pass goes above the previous one instead of on top of it; the same text twice
        // is drawn once.
        static int passFrame = -1;
        static EventType passEvent;
        static float nextBottom, nextPromptTop;
        static readonly System.Collections.Generic.List<string> drawnThisPass = new System.Collections.Generic.List<string>();

        static void BeginPass()
        {
            EventType e = Event.current != null ? Event.current.type : EventType.Repaint;
            if (passFrame == Time.frameCount && passEvent == e) return;
            passFrame = Time.frameCount;
            passEvent = e;
            nextBottom = Screen.height * 0.79f;
            nextPromptTop = Screen.height * 0.82f;
            drawnThisPass.Clear();
        }

        /// <summary>Story line and / or instruction in the lower part of the screen (stacked upwards if several).</summary>
        public static void Draw(string speaker, string line, string instruction, float alpha)
        {
            Ensure();
            BeginPass();
            string key = speaker + "\n" + line + "\n" + instruction;
            if (drawnThisPass.Contains(key)) return;
            drawnThisPass.Add(key);

            float w = Screen.width * 0.8f, x = Screen.width * 0.1f, h = Screen.height;
            float hs = string.IsNullOrEmpty(speaker) ? 0f : h * 0.045f;
            float hl = string.IsNullOrEmpty(line) ? 0f : h * 0.07f;
            float hi = string.IsNullOrEmpty(instruction) ? 0f : h * 0.07f;
            float total = hs + hl + hi;
            if (total <= 0f) return;
            float y = nextBottom - total;
            Label(new Rect(x, y, w, hs), speaker, speakerStyle, alpha);
            Label(new Rect(x, y + hs, w, hl), line, lineStyle, alpha);
            Label(new Rect(x, y + hs + hl, w, hi), instruction, instructionStyle, alpha);
            nextBottom = y - h * 0.02f;
        }

        /// <summary>A short "press F" style prompt near the bottom (below hints, so both can show at once).</summary>
        public static void DrawPrompt(string text, float alpha)
        {
            Ensure();
            BeginPass();
            if (string.IsNullOrEmpty(text) || drawnThisPass.Contains(text)) return;
            drawnThisPass.Add(text);
            float w = Screen.width * 0.8f, x = Screen.width * 0.1f, h = Screen.height;
            Label(new Rect(x, nextPromptTop, w, h * 0.05f), text, speakerStyle, alpha);
            nextPromptTop += h * 0.05f;   // several prompts stack downwards
        }

        /// <summary>Big centred title (end of a chapter).</summary>
        public static void DrawTitle(string title, string subtitle, float alpha)
        {
            Ensure();
            float w = Screen.width * 0.9f, x = Screen.width * 0.05f, h = Screen.height;
            Label(new Rect(x, h * 0.38f, w, h * 0.1f), title, titleStyle, alpha);
            Label(new Rect(x, h * 0.49f, w, h * 0.07f), subtitle, subtitleStyle, alpha);
        }
    }
}
