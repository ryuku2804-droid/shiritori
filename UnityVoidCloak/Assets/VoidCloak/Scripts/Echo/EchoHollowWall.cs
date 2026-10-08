using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// Sound puzzle: a stretch of wall that looks like every other wall, but has an empty
    /// room behind it. When a loud wave (a bell strike or a heavy swing) reaches it, it
    /// answers with a deep hollow boom and glows gold for a moment. Footsteps are too soft.
    /// A heavy attack (E / RB) breaks it open; a light attack only knocks on it.
    /// Breaking it is loud - enemies hear it.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoHollowWall : MonoBehaviour, IEchoHittable
    {
        [SerializeField] private Material material = null;
        [Tooltip("Width, height and thickness of the wall (same as a Wall kit piece).")]
        [SerializeField] private Vector3 size = new Vector3(5f, 4.5f, 1.4f);
        [SerializeField] private int seed = 1;

        [Header("Puzzle")]
        [Tooltip("Sword damage that breaks it (light attack 1, heavy attack 2.5).")]
        [SerializeField, Min(0f)] private float breakDamage = 2f;
        [Tooltip("Size of the gold glow when it answers a sound.")]
        [SerializeField, Min(0f)] private float resonanceRadius = 5f;
        [SerializeField, Min(0f)] private float breakEchoRadius = 18f;

        Mesh wallMesh, rubbleMesh;
        Transform rubble;
        bool broken;
        float resonateAt = -1f;
        float lastResonance = -100f;

        public bool IsAlive { get { return !broken; } }
        public Vector3 Position { get { return transform.position; } }

        public void Setup(Material newMaterial, Vector3 newSize, int newSeed)
        {
            material = newMaterial;
            size = newSize;
            seed = newSeed;
            Build();
        }

        void OnEnable()
        {
            broken = false;
            Build();
            EchoSystem.WaveEmitted += OnWave;
            EchoTargets.Register(this);
        }

        void OnDisable()
        {
            EchoTargets.Unregister(this);
            EchoSystem.WaveEmitted -= OnWave;
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == wallMesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(wallMesh);
            EchoMeshUtil.DestroySafe(rubbleMesh);
            wallMesh = null;
            rubbleMesh = null;
        }

        void Build()
        {
            var spec = new EchoKitSpec { kind = EchoKitKind.Wall, size = size, pointSpacing = 0.15f, seed = seed };
            var b = new EchoPointBuilder(seed);
            var boxes = new List<Bounds>();
            EchoKitGenerator.Build(spec, b, boxes);
            wallMesh = EchoMeshUtil.Build(b, wallMesh, "Hollow Wall");
            GetComponent<MeshFilter>().sharedMesh = wallMesh;
            ApplyMaterial(GetComponent<MeshRenderer>());
            EchoMeshUtil.SyncBoxColliders(transform, boxes);

            // the rubble it leaves behind (hidden until it breaks, no colliders: it is walked over)
            rubble = transform.Find("_Rubble");
            if (rubble == null)
            {
                var go = new GameObject("_Rubble");
                rubble = go.transform;
                rubble.SetParent(transform, false);
                go.AddComponent<MeshFilter>();
                go.AddComponent<MeshRenderer>();
            }
            var rb = new EchoPointBuilder(seed + 1);
            var rubbleSpec = new EchoKitSpec { kind = EchoKitKind.Rubble, size = new Vector3(size.x * 0.9f, 0.5f, size.z + 1.6f), pointSpacing = 0.11f, seed = seed + 1 };
            EchoKitGenerator.Build(rubbleSpec, rb, new List<Bounds>());
            rubbleMesh = EchoMeshUtil.Build(rb, rubbleMesh, "Hollow Wall Rubble");
            rubble.GetComponent<MeshFilter>().sharedMesh = rubbleMesh;
            ApplyMaterial(rubble.GetComponent<MeshRenderer>());
            ShowBroken(broken);
        }

        void ApplyMaterial(MeshRenderer r)
        {
            if (r == null) return;
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
        }

        void ShowBroken(bool isBroken)
        {
            GetComponent<MeshRenderer>().enabled = !isBroken;
            Transform colliders = transform.Find("_Colliders");
            if (colliders != null) colliders.gameObject.SetActive(!isBroken);
            if (rubble != null) rubble.gameObject.SetActive(isBroken);
        }

        Vector3 Center { get { return transform.position + Vector3.up * (size.y * 0.5f); } }

        // ------------------------------------------------------------------ answering sounds

        void OnWave(EchoWave wave)
        {
            if (!Application.isPlaying || broken) return;
            // only loud sounds make the hollow ring; its own answer must not start it again
            if (wave.source != EchoSource.Strike && wave.source != EchoSource.Bell) return;
            if (wave.strength <= 0f) return;   // a silent noise (a fight somewhere) is not a wave
            float distance = Vector3.Distance(wave.origin, Center);
            if (distance > wave.radius) return;
            // it answers when the wavefront actually arrives
            float at = Time.time + distance / Mathf.Max(1f, wave.speed);
            if (resonateAt < 0f || at < resonateAt) resonateAt = at;
        }

        void Update()
        {
            if (!Application.isPlaying || broken) return;
            if (resonateAt >= 0f && Time.time >= resonateAt)
            {
                resonateAt = -1f;
                Resonate(1f);
            }
        }

        void Resonate(float loudness)
        {
            if (Time.time - lastResonance < 0.5f) return;
            lastResonance = Time.time;
            EchoSystem.Emit(Center, resonanceRadius, EchoSource.Resonance, 1.1f);
            EchoAudio.Play(EchoSound.HollowKnock, Center, loudness);
        }

        // ------------------------------------------------------------------ being hit

        public void TakeHit(float damage, Vector3 from)
        {
            if (broken) return;
            if (damage < breakDamage)
            {
                Resonate(0.7f);   // a light blow only knocks on it
                return;
            }
            broken = true;
            ShowBroken(true);
            EchoSystem.Emit(Center, breakEchoRadius, EchoSource.Strike, 1.2f);
            EchoAudio.Play(EchoSound.WallCrumble, Center, 1f);
        }
    }
}
