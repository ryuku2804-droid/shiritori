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

            if (generateColliders) SyncColliders(boxes);
        }

        /// <summary>Creates / updates box colliders only when they actually changed.</summary>
        void SyncColliders(List<Bounds> boxes)
        {
            Transform holder = transform.Find("_Colliders");
            if (holder == null)
            {
                var go = new GameObject("_Colliders");
                holder = go.transform;
                holder.SetParent(transform, false);
            }

            BoxCollider[] existing = holder.GetComponents<BoxCollider>();
            bool same = existing.Length == boxes.Count;
            for (int i = 0; same && i < boxes.Count; i++)
            {
                same = (existing[i].center - boxes[i].center).sqrMagnitude < 1e-6f && (existing[i].size - boxes[i].size).sqrMagnitude < 1e-6f;
            }
            if (same) return;

            foreach (BoxCollider c in existing) EchoMeshUtil.DestroySafe(c);
            foreach (Bounds box in boxes)
            {
                BoxCollider c = holder.gameObject.AddComponent<BoxCollider>();
                c.center = box.center;
                c.size = box.size;
            }
        }
    }
}
