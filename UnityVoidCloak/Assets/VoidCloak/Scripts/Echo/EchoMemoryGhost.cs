using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
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
        [Tooltip("1-3: hearing this echo gives that memory fragment (all three open the true ending). 0 = none.")]
        [SerializeField, Range(0, 3)] private int memoryId = 0;

        Mesh mesh;
        float alpha;
        bool wasNear;
        float nextChime;

        public void SetMemory(int id)
        {
            memoryId = id;
        }

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
            if (near && memoryId > 0) EchoGame.CollectMemory(memoryId);
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
}
