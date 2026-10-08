using UnityEngine;
using UnityEngine.SceneManagement;

namespace EchoKnight
{
    /// <summary>
    /// Fades the screen to black, loads a scene, and fades back in. Lives across the scene change
    /// (DontDestroyOnLoad) and removes itself afterwards. Works while the game is paused.
    /// </summary>
    public class EchoSceneFader : MonoBehaviour
    {
        const float FadeOut = 1.2f, FadeIn = 1.0f;

        static EchoSceneFader active;
        static Texture2D black;

        string sceneName;
        float start;
        bool loaded;
        string error;

        public static bool Busy { get { return active != null; } }

        public static void FadeTo(string scene)
        {
            if (active != null) return;   // already on the way somewhere
            var go = new GameObject("EchoSceneFader");
            DontDestroyOnLoad(go);
            active = go.AddComponent<EchoSceneFader>();
            active.sceneName = scene;
            active.start = Time.unscaledTime;
            if (!Application.CanStreamedLevelBeLoaded(scene))
                active.error = "シーン「" + scene + "」が見つかりません。\nメニューの Tools > Echo Knight > Build Game を実行してから、EchoTitle シーンで Play してください。";
        }

        void Update()
        {
            float t = Time.unscaledTime - start;
            if (error != null)
            {
                if (t > 6f) Finish();
                return;
            }
            if (!loaded && t >= FadeOut)
            {
                loaded = true;
                EchoGame.SetPaused(false);
                SceneManager.LoadScene(sceneName);
                start = Time.unscaledTime;
            }
            else if (loaded && t >= FadeIn)
            {
                Finish();
            }
        }

        void Finish()
        {
            if (active == this) active = null;
            Destroy(gameObject);
        }

        void OnDestroy()
        {
            if (active == this) active = null;
        }

        void OnGUI()
        {
            GUI.depth = -1000;   // on top of everything
            float t = Time.unscaledTime - start;
            if (error != null)
            {
                EchoScreenText.Draw(null, error, null, Mathf.Clamp01(t * 2f) * Mathf.Clamp01((6f - t) * 2f));
                return;
            }
            float a = loaded ? 1f - Mathf.Clamp01(t / FadeIn) : Mathf.Clamp01(t / FadeOut);
            if (black == null)
            {
                black = new Texture2D(1, 1) { hideFlags = HideFlags.DontSave };
                black.SetPixel(0, 0, Color.black);
                black.Apply();
            }
            Color old = GUI.color;
            GUI.color = new Color(1f, 1f, 1f, a);
            GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), black);
            GUI.color = old;
        }
    }
}
