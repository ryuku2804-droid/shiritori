using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// One medieval building piece made of points (wall, arch, pillar, tower, stairs ...).
    /// Change the values in the Inspector and the piece rebuilds itself, including its
    /// box colliders (on a child called "_Colliders").
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoKitPiece : MonoBehaviour
    {
        [SerializeField] private EchoKitSpec spec = new EchoKitSpec();
        [Tooltip("Material using the EchoKnight/WorldPoint shader.")]
        [SerializeField] private Material material = null;
        [SerializeField] private bool generateColliders = true;

        [Header("Info (read only)")]
        [SerializeField] private int pointCount;

        Mesh mesh;
        bool dirty = true;

        public EchoKitSpec Spec { get { return spec; } }

        /// <summary>Used by the stage builder.</summary>
        public void Configure(EchoKitSpec newSpec, Material newMaterial)
        {
            spec = newSpec;
            material = newMaterial;
            Rebuild();
        }

        void OnEnable()
        {
            dirty = true;
            Rebuild();
        }

        void OnValidate()
        {
            dirty = true;
        }

        void Update()
        {
            if (dirty) Rebuild();
        }

        void OnDisable()
        {
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == mesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(mesh);
            mesh = null;
        }

        [ContextMenu("Rebuild")]
        public void Rebuild()
        {
            dirty = false;
            var builder = new EchoPointBuilder(spec.seed);
            var boxes = new List<Bounds>();
            EchoKitGenerator.Build(spec, builder, boxes);
            mesh = EchoMeshUtil.Build(builder, mesh, "EchoKit " + spec.kind);
            pointCount = builder.Count;

            GetComponent<MeshFilter>().sharedMesh = mesh;
            var r = GetComponent<MeshRenderer>();
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;

            if (generateColliders) EchoMeshUtil.SyncBoxColliders(transform, boxes);
        }
    }
}
