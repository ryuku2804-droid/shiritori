using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// Shallow water over the floor. Every step in it splashes:
    ///   - the knight's footsteps make an echo on every step (no waiting) and a little bigger,
    ///     so he sees more - but everything hears him;
    ///   - an enemy wading through it shows itself with small red echoes.
    /// The surface is drawn as points like everything else (seen only in an echo).
    /// Origin at the floor, in the middle of the pool; Size = width (X) and length (Z).
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoWaterZone : MonoBehaviour
    {
        static readonly List<EchoWaterZone> all = new List<EchoWaterZone>();

        [SerializeField] private Material material = null;
        [SerializeField] private Vector2 size = new Vector2(10f, 10f);
        [SerializeField, Min(0.05f)] private float depth = 0.35f;
        [SerializeField] private int seed = 1;

        Mesh mesh;

        public void Setup(Material newMaterial, Vector2 newSize, int newSeed)
        {
            material = newMaterial;
            size = newSize;
            seed = newSeed;
            Build();
        }

        void OnEnable()
        {
            Build();
            if (!all.Contains(this)) all.Add(this);
        }

        void OnDisable()
        {
            all.Remove(this);
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == mesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(mesh);
            mesh = null;
        }

        void Build()
        {
            var b = new EchoPointBuilder(seed);
            EchoKitGenerator.WaterSurface(b, size, depth);
            mesh = EchoMeshUtil.Build(b, mesh, "Water");
            GetComponent<MeshFilter>().sharedMesh = mesh;
            var r = GetComponent<MeshRenderer>();
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
        }

        public bool Contains(Vector3 p)
        {
            Vector3 local = transform.InverseTransformPoint(p);
            return Mathf.Abs(local.x) <= size.x * 0.5f && Mathf.Abs(local.z) <= size.y * 0.5f && local.y > -1f && local.y < 2f;
        }

        /// <summary>Is this point standing in any water?</summary>
        public static bool IsInWater(Vector3 p)
        {
            for (int i = 0; i < all.Count; i++)
                if (all[i] != null && all[i].Contains(p)) return true;
            return false;
        }

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(0.4f, 0.7f, 1f, 0.6f);
            Gizmos.DrawWireCube(transform.position + Vector3.up * depth, new Vector3(size.x, 0.05f, size.y));
        }
    }
}
