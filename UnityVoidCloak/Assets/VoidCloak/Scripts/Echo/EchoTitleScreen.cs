using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// The title screen: the knight stands in the dark among the shards of the great bell, and
    /// every few seconds a soft echo (now and then a golden bell) shows the ruins around him.
    /// Menu: はじめから / つづきから / おわる.
    /// Put it on any object in the title scene; <see cref="knight"/> is where the echoes start.
    /// </summary>
    [DisallowMultipleComponent]
    public class EchoTitleScreen : MonoBehaviour
    {
        [SerializeField] private Transform knight = null;
        [SerializeField, Min(0.5f)] private float pulseInterval = 3.2f;
        [SerializeField, Min(1f)] private float pulseRadius = 18f;
        [Tooltip("Every Nth echo is a golden bell.")]
        [SerializeField, Min(1)] private int bellEvery = 3;

        static GUIStyle titleStyle, subStyle;
        static int builtFor;

        string[] items;
        bool[] enabled;
        int selected;
        float startTime;
        float nextPulse;
        int pulses;
        bool chosen;

        public void Setup(Transform newKnight)
        {
            knight = newKnight;
        }

        void Start()
        {
            EchoGame.SetPaused(false);
            EchoSystem.Ensure();
            EchoAudio.Ensure();
            bool hasSave = EchoGame.HasSave;
            string continueLabel = hasSave ? "つづきから（" + EchoGame.Chapters[EchoGame.SavedChapter].title + "）" : "つづきから";
            items = new[] { "はじめから", continueLabel, "おわる" };
            enabled = new[] { true, hasSave, true };
            selected = hasSave ? 1 : 0;
            startTime = Time.time;
            nextPulse = Time.time + 1.2f;
        }

        void Update()
        {
            Vector3 origin = (knight != null ? knight.position : transform.position) + Vector3.up * 0.2f;
            if (Time.time >= nextPulse)
            {
                nextPulse = Time.time + pulseInterval;
                pulses++;
                if (pulses % bellEvery == 0)
                {
                    EchoSystem.Emit(origin + Vector3.up * 2f, pulseRadius * 1.6f, EchoSource.Bell, 1.1f);
                    EchoAudio.Play(EchoSound.ShrineBell, origin + Vector3.up * 3f, 0.35f, 0.75f);
                }
                else
                {
                    EchoSystem.Emit(origin, pulseRadius, EchoSource.Player, 0.9f);
                    EchoAudio.Play(EchoSound.Step, origin, 0.4f);
                }
            }

            if (chosen || EchoSceneFader.Busy || Time.time - startTime < 1.5f) return;
            int move = EchoMenuInput.Vertical();
            if (move != 0)
            {
                // skip the items that cannot be chosen
                for (int k = 0; k < items.Length; k++)
                {
                    selected = (selected + move + items.Length) % items.Length;
                    if (enabled[selected]) break;
                }
            }
            if (EchoMenuInput.Confirm()) Choose(selected);
        }

        void Choose(int index)
        {
            if (chosen || !enabled[index]) return;
            chosen = true;
            EchoSystem.Emit((knight != null ? knight.position : transform.position) + Vector3.up * 2f, 60f, EchoSource.Bell, 1.3f);
            EchoAudio.Play(EchoSound.ShrineBell, transform.position + Vector3.up * 3f, 0.8f);
            switch (index)
            {
                case 0: EchoGame.NewGame(); break;
                case 1: EchoGame.Continue(); break;
                default: EchoGame.Quit(); break;
            }
        }

        void OnGUI()
        {
            if (items == null) return;
            if (titleStyle == null || builtFor != Screen.height)
            {
                builtFor = Screen.height;
                titleStyle = new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter, fontSize = Mathf.Max(28, Screen.height / 9) };
                titleStyle.normal.textColor = new Color(1f, 0.86f, 0.55f);
                subStyle = new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter, fontSize = Mathf.Max(14, Screen.height / 36) };
                subStyle.normal.textColor = new Color(0.75f, 0.76f, 0.8f);
            }
            float t = Time.time - startTime;
            float a = Mathf.Clamp01((t - 0.3f) / 2f);
            float w = Screen.width, h = Screen.height;
            EchoScreenText.Label(new Rect(0f, h * 0.06f, w, h * 0.16f), "残響の騎士", titleStyle, a);
            string line = !EchoGame.FinishedAll ? "目を失った騎士は、足音で世界を見る"
                : EchoGame.LastEnding != null ? "―　終　―　" + EchoGame.LastEnding
                : "―　" + EchoGame.NextChapterName + "へ　つづく　―";
            EchoScreenText.Label(new Rect(0f, h * 0.22f, w, h * 0.06f), line, subStyle, a);

            float menuAlpha = Mathf.Clamp01((t - 1.5f) / 1f) * (chosen ? 0.4f : 1f);
            int clicked = EchoMenuDraw.Draw(items, enabled, selected, h * 0.8f, menuAlpha);
            if (clicked >= 0 && !chosen && t > 1.5f)
            {
                selected = clicked;
                Choose(clicked);
            }
        }
    }
}
