using UnityEngine;
using UnityEngine.Rendering;

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

        static void Label(Rect r, string text, GUIStyle style, float alpha)
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
        public static void Draw(string speaker, string line, string instruction, float alpha)
        {
            Ensure();
            float w = Screen.width * 0.8f, x = Screen.width * 0.1f, h = Screen.height;
            Label(new Rect(x, h * 0.60f, w, h * 0.05f), speaker, speakerStyle, alpha);
            Label(new Rect(x, h * 0.645f, w, h * 0.07f), line, lineStyle, alpha);
            Label(new Rect(x, h * 0.72f, w, h * 0.07f), instruction, instructionStyle, alpha);
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

    /// <summary>
    /// Shows a line of story and / or an instruction while the knight is inside this box.
    /// </summary>
    [DisallowMultipleComponent]
    public class EchoHintZone : MonoBehaviour
    {
        [SerializeField] private Vector3 size = new Vector3(8f, 6f, 8f);
        [SerializeField] private string speaker = "";
        [SerializeField, TextArea(1, 3)] private string line = "";
        [SerializeField, TextArea(1, 3)] private string instruction = "";

        float alpha;

        public void Setup(Vector3 zoneSize, string zoneSpeaker, string zoneLine, string zoneInstruction)
        {
            size = zoneSize;
            speaker = zoneSpeaker ?? "";
            line = zoneLine ?? "";
            instruction = zoneInstruction ?? "";
        }

        void Update()
        {
            EchoPlayer player = EchoPlayer.Current;
            bool inside = player != null && new Bounds(transform.position, size).Contains(player.transform.position + Vector3.up);
            alpha = Mathf.MoveTowards(alpha, inside ? 1f : 0f, Time.deltaTime * 2f);
        }

        void OnGUI()
        {
            if (alpha > 0.01f) EchoScreenText.Draw(speaker, line, instruction, alpha);
        }

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(0.4f, 0.8f, 1f, 0.6f);
            Gizmos.DrawWireCube(transform.position, size);
        }
    }

    /// <summary>
    /// A memory echo (残響): someone's last moment, frozen as a kneeling gold figure.
    /// Like everything else it is only visible in an echo; when the knight comes close it
    /// chimes softly (a small gold wave) and its last words appear.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoMemoryGhost : MonoBehaviour
    {
        [SerializeField] private Material material = null;
        [SerializeField] private string speaker = "残響";
        [SerializeField, TextArea(1, 3)] private string line = "";
        [SerializeField, Min(1f)] private float hearDistance = 6f;

        Mesh mesh;
        float alpha;
        bool wasNear;
        float nextChime;

        public void Setup(Material newMaterial, string ghostSpeaker, string ghostLine)
        {
            material = newMaterial;
            speaker = ghostSpeaker;
            line = ghostLine;
            Build();
        }

        void OnEnable()
        {
            Build();
        }

        void OnDisable()
        {
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == mesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(mesh);
            mesh = null;
        }

        void Build()
        {
            var b = new EchoPointBuilder(31);
            EchoGhostBody.Build(b);
            mesh = EchoMeshUtil.Build(b, mesh, "Memory Echo");
            GetComponent<MeshFilter>().sharedMesh = mesh;
            var r = GetComponent<MeshRenderer>();
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
        }

        void Update()
        {
            if (!Application.isPlaying) return;
            EchoPlayer player = EchoPlayer.Current;
            bool near = false;
            if (player != null)
            {
                Vector3 d = player.transform.position - transform.position;
                d.y = 0f;
                near = d.magnitude < hearDistance;
            }
            if (near && !wasNear && Time.time >= nextChime)
            {
                // a soft chime so the figure shows itself
                Vector3 p = transform.position + Vector3.up * 2f;
                EchoSystem.Emit(p, 9f, EchoSource.Bell, 0.9f);
                EchoAudio.Play(EchoSound.ShrineBell, p, 0.25f, 2f);
                nextChime = Time.time + 6f;
            }
            wasNear = near;
            alpha = Mathf.MoveTowards(alpha, near ? 1f : 0f, Time.deltaTime * 1.5f);
        }

        void OnGUI()
        {
            if (Application.isPlaying && alpha > 0.01f) EchoScreenText.Draw(speaker, line, null, alpha);
        }
    }

    /// <summary>The end of a stage: reaching it rings out a great golden echo and shows the chapter title.</summary>
    [DisallowMultipleComponent]
    public class EchoStageGoal : MonoBehaviour
    {
        [SerializeField] private Vector3 size = new Vector3(6f, 5f, 4f);
        [SerializeField] private string title = "";
        [SerializeField] private string subtitle = "";
        [SerializeField, Min(1f)] private float showSeconds = 10f;

        float reachedTime = -1f;

        public bool Reached { get { return reachedTime >= 0f; } }

        public void Setup(Vector3 zoneSize, string goalTitle, string goalSubtitle)
        {
            size = zoneSize;
            title = goalTitle;
            subtitle = goalSubtitle;
        }

        void Update()
        {
            if (Reached) return;
            EchoPlayer player = EchoPlayer.Current;
            if (player == null) return;
            if (!new Bounds(transform.position, size).Contains(player.transform.position + Vector3.up)) return;

            reachedTime = Time.time;
            EchoSystem.Emit(transform.position, 90f, EchoSource.Bell, 1.3f);
            EchoAudio.Play(EchoSound.ShrineBell, transform.position + Vector3.up * 3f, 1f, 0.8f);
        }

        void OnGUI()
        {
            if (!Reached) return;
            float t = Time.time - reachedTime;
            float alpha = Mathf.Clamp01(t / 1.5f) * Mathf.Clamp01((showSeconds - t) / 2f);
            if (alpha > 0.01f) EchoScreenText.DrawTitle(title, subtitle, alpha);
        }

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(1f, 0.8f, 0.3f, 0.7f);
            Gizmos.DrawWireCube(transform.position, size);
        }
    }
}
