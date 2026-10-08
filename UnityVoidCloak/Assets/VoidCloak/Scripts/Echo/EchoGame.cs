using System;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// The game as a whole: the list of chapters, moving between scenes, the save data and the
    /// pause flag. The save is tiny (which chapter, which bell shrine) and lives in PlayerPrefs.
    /// </summary>
    public static class EchoGame
    {
        public struct Chapter
        {
            public string scene;
            public string title;
            public Chapter(string scene, string title) { this.scene = scene; this.title = title; }
        }

        /// <summary>Scene names must match the scenes made by Tools > Echo Knight > Build Game.</summary>
        public const string TitleScene = "EchoTitle";

        public static readonly Chapter[] Chapters =
        {
            new Chapter("EchoPrologue", "序章　崩れた鐘楼"),
            new Chapter("EchoChapter1", "第一章　灰の城下町"),
            new Chapter("EchoChapter2", "第二章　沈んだ修道院"),
        };

        const string KeyHasSave = "EchoKnight.HasSave";
        const string KeyChapter = "EchoKnight.Chapter";
        const string KeyShrine = "EchoKnight.Shrine";

        static string pendingShrine;

        /// <summary>True while the pause menu is open: gameplay input is ignored.</summary>
        public static bool Paused { get; private set; }

        static readonly string[] Numerals = { "零", "一", "二", "三", "四", "五", "六", "七", "八", "九" };

        /// <summary>"第三章" etc.: the chapter after the last one that exists (for "to be continued").</summary>
        public static string NextChapterName
        {
            get { int n = Chapters.Length; return "第" + (n < Numerals.Length ? Numerals[n] : n.ToString()) + "章"; }
        }

        /// <summary>Set when the last chapter has just been finished (the title screen says "to be continued").</summary>
        public static bool FinishedAll { get; set; }

        // ------------------------------------------------------------------ during play

        /// <summary>The knight fell. Enemies go back to where they started; attack rings vanish.</summary>
        public static event Action PlayerDied;

        public static void NotifyPlayerDied()
        {
            EchoShockwaves.Clear();
            SilencedUntil = 0f;
            if (PlayerDied != null) PlayerDied();
            Say("リーネ", DeathLines[UnityEngine.Random.Range(0, DeathLines.Length)], 3.5f);
        }

        static readonly string[] DeathLines =
        {
            "……兄さん。立って。",
            "まだ、終わってない。……聞こえる？",
            "……もう一度。今度は、よく聞いて。",
            "音は、嘘をつかない。……兄さん、もう一度。",
        };

        /// <summary>While Time.time is below this, the knight's footsteps make no echo (the Silent Knight's veil).</summary>
        public static float SilencedUntil { get; set; }
        public static bool Silenced { get { return Time.time < SilencedUntil; } }

        /// <summary>A line of dialogue at the bottom of the screen (Rine mostly). Drawn by the stage.</summary>
        public static void Say(string speaker, string line, float seconds)
        {
            sayingSpeaker = speaker;
            sayingLine = line;
            sayingUntil = Time.time + seconds;
            sayingFrom = Time.time;
        }

        static string sayingSpeaker, sayingLine;
        static float sayingUntil = -1f, sayingFrom;

        /// <summary>Current line and its fade (0 when nothing is said).</summary>
        public static float Saying(out string speaker, out string line)
        {
            speaker = sayingSpeaker;
            line = sayingLine;
            if (sayingFrom > Time.time + 1f) sayingUntil = -1f;   // left over from an earlier play session
            float a = Mathf.Clamp01((Time.time - sayingFrom) / 0.4f) * Mathf.Clamp01((sayingUntil - Time.time) / 0.8f);
            return line == null ? 0f : a;
        }

        // ------------------------------------------------------------------ save data

        public static bool HasSave { get { return PlayerPrefs.GetInt(KeyHasSave, 0) == 1; } }
        public static int SavedChapter { get { return Mathf.Clamp(PlayerPrefs.GetInt(KeyChapter, 0), 0, Chapters.Length - 1); } }

        /// <summary>The knight has arrived at the start of a chapter.</summary>
        public static void SaveChapterStart(int chapter)
        {
            if (chapter < 0 || chapter >= Chapters.Length) return;
            PlayerPrefs.SetInt(KeyHasSave, 1);
            PlayerPrefs.SetInt(KeyChapter, chapter);
            PlayerPrefs.SetString(KeyShrine, "");
            PlayerPrefs.Save();
        }

        /// <summary>A bell shrine was rung (saved by its GameObject name).</summary>
        public static void SaveShrine(string shrineName)
        {
            EchoStageInfo stage = EchoStageInfo.Current;
            if (stage == null || stage.ChapterIndex < 0) return;   // a test scene: nothing to save
            PlayerPrefs.SetInt(KeyHasSave, 1);
            PlayerPrefs.SetInt(KeyChapter, stage.ChapterIndex);
            PlayerPrefs.SetString(KeyShrine, shrineName ?? "");
            PlayerPrefs.Save();
        }

        /// <summary>Called by the stage when it starts: the shrine to resume at, if the player chose "continue".</summary>
        public static bool TakePendingShrine(out string shrineName)
        {
            shrineName = pendingShrine;
            pendingShrine = null;
            return !string.IsNullOrEmpty(shrineName);
        }

        // ------------------------------------------------------------------ moving between scenes

        public static void NewGame()
        {
            pendingShrine = null;
            FinishedAll = false;
            SaveChapterStart(0);
            EchoSceneFader.FadeTo(Chapters[0].scene);
        }

        public static void Continue()
        {
            if (!HasSave) { NewGame(); return; }
            FinishedAll = false;
            pendingShrine = PlayerPrefs.GetString(KeyShrine, "");
            EchoSceneFader.FadeTo(Chapters[SavedChapter].scene);
        }

        /// <summary>The goal of a chapter was reached: on to the next one, or back to the title after the last.</summary>
        public static void CompleteChapter(int chapter)
        {
            pendingShrine = null;
            int next = chapter + 1;
            if (chapter >= 0 && next < Chapters.Length)
            {
                SaveChapterStart(next);
                EchoSceneFader.FadeTo(Chapters[next].scene);
            }
            else
            {
                FinishedAll = chapter >= 0;
                EchoSceneFader.FadeTo(TitleScene);
            }
        }

        public static void BackToTitle()
        {
            pendingShrine = null;
            EchoSceneFader.FadeTo(TitleScene);
        }

        public static void Quit()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }

        public static void SetPaused(bool paused)
        {
            Paused = paused;
            Time.timeScale = paused ? 0f : 1f;
            AudioListener.pause = paused;
        }
    }

    /// <summary>Menu input for keyboard, mouse and gamepad (both input systems).</summary>
    public static class EchoMenuInput
    {
        static float nextRepeat;

        /// <summary>-1 = up, +1 = down, 0 = nothing. Holding repeats a little.</summary>
        public static int Vertical()
        {
            int dir = 0;
            bool held = false;
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            if (kb != null)
            {
                if (kb.upArrowKey.wasPressedThisFrame || kb.wKey.wasPressedThisFrame) dir = -1;
                if (kb.downArrowKey.wasPressedThisFrame || kb.sKey.wasPressedThisFrame) dir = 1;
            }
            var pad = UnityEngine.InputSystem.Gamepad.current;
            if (pad != null && dir == 0)
            {
                if (pad.dpad.up.wasPressedThisFrame) dir = -1;
                if (pad.dpad.down.wasPressedThisFrame) dir = 1;
                float y = pad.leftStick.ReadValue().y;
                if (Mathf.Abs(y) > 0.6f)
                {
                    held = true;
                    if (Time.unscaledTime >= nextRepeat) { dir = y > 0f ? -1 : 1; nextRepeat = Time.unscaledTime + 0.3f; }
                }
            }
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            if (dir == 0)
            {
                if (Input.GetKeyDown(KeyCode.UpArrow) || Input.GetKeyDown(KeyCode.W)) dir = -1;
                if (Input.GetKeyDown(KeyCode.DownArrow) || Input.GetKeyDown(KeyCode.S)) dir = 1;
            }
#endif
            if (!held && dir == 0) nextRepeat = 0f;
            return dir;
        }

        public static bool Confirm()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            if (kb != null && (kb.enterKey.wasPressedThisFrame || kb.numpadEnterKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame)) return true;
            var pad = UnityEngine.InputSystem.Gamepad.current;
            if (pad != null && pad.buttonSouth.wasPressedThisFrame) return true;
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            if (Input.GetKeyDown(KeyCode.Return) || Input.GetKeyDown(KeyCode.KeypadEnter) || Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.JoystickButton0)) return true;
#endif
            return false;
        }

        /// <summary>Esc or the gamepad Start button.</summary>
        public static bool PauseToggle()
        {
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            if (kb != null && kb.escapeKey.wasPressedThisFrame) return true;
            var pad = UnityEngine.InputSystem.Gamepad.current;
            if (pad != null && pad.startButton.wasPressedThisFrame) return true;
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            if (Input.GetKeyDown(KeyCode.Escape) || Input.GetKeyDown(KeyCode.JoystickButton7)) return true;
#endif
            return false;
        }
    }

    /// <summary>Draws a vertical text menu (OnGUI). Returns the index of an item clicked with the mouse, or -1.</summary>
    public static class EchoMenuDraw
    {
        static GUIStyle style;
        static int builtFor;

        public static int Draw(string[] items, bool[] enabled, int selected, float centreY, float alpha)
        {
            int u = Mathf.Max(14, Screen.height / 30);
            if (style == null || builtFor != Screen.height)
            {
                builtFor = Screen.height;
                style = new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter, fontSize = u };
            }
            float lineH = u * 2f, w = Screen.width * 0.5f, x = Screen.width * 0.25f;
            float top = centreY - lineH * items.Length * 0.5f;
            int clicked = -1;
            for (int i = 0; i < items.Length; i++)
            {
                bool on = enabled == null || enabled[i];
                var r = new Rect(x, top + i * lineH, w, lineH);
                string text = i == selected ? "―　" + items[i] + "　―" : items[i];
                Color c = !on ? new Color(0.35f, 0.35f, 0.38f) : i == selected ? new Color(1f, 0.86f, 0.55f) : new Color(0.75f, 0.76f, 0.8f);
                style.normal.textColor = c;
                EchoScreenText.Label(r, text, style, alpha);
                Event e = Event.current;
                if (on && e != null && e.type == EventType.MouseDown && e.button == 0 && r.Contains(e.mousePosition))
                {
                    clicked = i;
                    e.Use();
                }
            }
            return clicked;
        }
    }
}
