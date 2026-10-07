using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>Who made a sound.</summary>
    public enum EchoSource
    {
        /// <summary>The knight's footsteps.</summary>
        Player = 0,
        /// <summary>An enemy's own noise (tints what it reveals red).</summary>
        Enemy = 1,
        /// <summary>The knight striking the ground with the sword (big wave).</summary>
        Strike = 2,
        /// <summary>A shrine bell (tints what it reveals gold; Listeners flee from it).</summary>
        Bell = 3,
    }

    public struct EchoWave
    {
        public Vector3 origin;
        public float startTime;
        public float radius;
        public float speed;
        public float strength;
        public EchoSource source;
    }

    /// <summary>
    /// Keeps track of every sound wave in the stage and hands them to the world shader as
    /// global arrays. Anything drawn with EchoKnight/WorldPoint is invisible until a wave
    /// passes over it, flashes on the wavefront and fades out again about 1.5 s later.
    ///
    /// Enemies subscribe to <see cref="WaveEmitted"/> to hear sounds.
    /// </summary>
    [ExecuteAlways]
    [DefaultExecutionOrder(-100)]
    [DisallowMultipleComponent]
    public class EchoSystem : MonoBehaviour
    {
        public const int MaxWaves = 24;

        [Header("Waves")]
        [Tooltip("How fast a wave travels (units per second).")]
        [SerializeField, Min(1f)] private float waveSpeed = 26f;
        [Tooltip("Thickness of the bright wavefront.")]
        [SerializeField, Range(0.2f, 6f)] private float frontWidth = 1.4f;
        [Tooltip("How long things stay visible after the wavefront passed (seconds).")]
        [SerializeField, Range(0.1f, 6f)] private float holdTime = 1.5f;

        [Header("Editing")]
        [Tooltip("Show the stage dimly in the editor so it can be built and arranged.")]
        [SerializeField] private bool showStageInEditMode = true;
        [SerializeField, Range(0f, 1f)] private float editModeBrightness = 0.55f;
        [Tooltip("Debug: show the whole stage while playing.")]
        [SerializeField] private bool revealAllInPlayMode = false;

        /// <summary>Raised for every new wave (enemies listen to this).</summary>
        public static event Action<EchoWave> WaveEmitted;

        static EchoSystem instance;
        readonly List<EchoWave> waves = new List<EchoWave>();
        readonly Vector4[] waveData = new Vector4[MaxWaves];
        readonly Vector4[] waveParams = new Vector4[MaxWaves];

        static readonly int WavesId = Shader.PropertyToID("_EchoWaves");
        static readonly int WaveParamsId = Shader.PropertyToID("_EchoWaveParams");
        static readonly int WaveCountId = Shader.PropertyToID("_EchoWaveCount");
        static readonly int TimeId = Shader.PropertyToID("_EchoTime");
        static readonly int FrontId = Shader.PropertyToID("_EchoBand");
        static readonly int HoldId = Shader.PropertyToID("_EchoHold");
        static readonly int RevealAllId = Shader.PropertyToID("_EchoRevealAll");

        public float WaveSpeed { get { return waveSpeed; } }

        /// <summary>The system in the scene; created on demand while playing.</summary>
        public static EchoSystem Ensure()
        {
            if (instance == null && Application.isPlaying)
            {
                var go = new GameObject("EchoSystem");
                instance = go.AddComponent<EchoSystem>();
            }
            return instance;
        }

        /// <summary>Send out a sound wave.</summary>
        /// <param name="radius">How far it travels (and how far enemies can hear it).</param>
        /// <param name="strength">Brightness of what it reveals (1 = normal).</param>
        public static void Emit(Vector3 origin, float radius, EchoSource source, float strength = 1f)
        {
            EchoSystem s = Ensure();
            if (s == null) return;
            var wave = new EchoWave
            {
                origin = origin,
                startTime = Time.time,
                radius = radius,
                speed = s.waveSpeed,
                strength = strength,
                source = source,
            };
            s.Add(wave);
            if (WaveEmitted != null) WaveEmitted(wave);
        }

        void Add(EchoWave wave)
        {
            if (waves.Count >= MaxWaves) waves.RemoveAt(0);
            waves.Add(wave);
        }

        void OnEnable()
        {
            if (instance == null) instance = this;
            Push();
        }

        void OnDisable()
        {
            if (instance == this) instance = null;
            waves.Clear();
            Push();
        }

        void Update()
        {
            float now = Time.time;
            for (int i = waves.Count - 1; i >= 0; i--)
            {
                EchoWave w = waves[i];
                if (now - w.startTime > w.radius / w.speed + holdTime + 0.2f) waves.RemoveAt(i);
            }
            Push();
        }

        void Push()
        {
            int n = Mathf.Min(waves.Count, MaxWaves);
            for (int i = 0; i < MaxWaves; i++)
            {
                if (i < n)
                {
                    EchoWave w = waves[i];
                    waveData[i] = new Vector4(w.origin.x, w.origin.y, w.origin.z, w.startTime);
                    waveParams[i] = new Vector4(w.radius, w.speed, (float)w.source, w.strength);
                }
                else
                {
                    waveData[i] = Vector4.zero;
                    waveParams[i] = new Vector4(0.001f, 1f, 0f, 0f);
                }
            }
            Shader.SetGlobalVectorArray(WavesId, waveData);
            Shader.SetGlobalVectorArray(WaveParamsId, waveParams);
            Shader.SetGlobalFloat(WaveCountId, n);
            Shader.SetGlobalFloat(TimeId, Time.time);
            Shader.SetGlobalFloat(FrontId, frontWidth);
            Shader.SetGlobalFloat(HoldId, holdTime);
            float revealAll = Application.isPlaying
                ? (revealAllInPlayMode ? 1f : 0f)
                : (showStageInEditMode ? editModeBrightness : 0f);
            Shader.SetGlobalFloat(RevealAllId, revealAll);
        }
    }

    /// <summary>Turns an <see cref="EchoPointBuilder"/> into a point mesh.</summary>
    public static class EchoMeshUtil
    {
        public static Mesh Build(EchoPointBuilder b, Mesh mesh, string name)
        {
            if (mesh == null)
            {
                mesh = new Mesh { name = name, hideFlags = HideFlags.DontSave };
                mesh.indexFormat = IndexFormat.UInt32;
            }
            mesh.Clear();
            mesh.SetVertices(b.positions);
            mesh.SetNormals(b.normals);
            mesh.SetColors(b.colors);
            mesh.SetUVs(0, b.uv0);
            var indices = new int[b.Count];
            for (int i = 0; i < indices.Length; i++) indices[i] = i;
            mesh.SetIndices(indices, MeshTopology.Points, 0, false);
            mesh.RecalculateBounds();
            Bounds bounds = mesh.bounds;
            bounds.Expand(1f);
            mesh.bounds = bounds;
            return mesh;
        }

        /// <summary>
        /// Keeps box colliders on a child called "_Colliders" in sync with <paramref name="boxes"/>
        /// (local space). Only touches them when something actually changed.
        /// </summary>
        public static void SyncBoxColliders(Transform owner, List<Bounds> boxes)
        {
            Transform holder = owner.Find("_Colliders");
            if (holder == null)
            {
                var go = new GameObject("_Colliders");
                holder = go.transform;
                holder.SetParent(owner, false);
            }

            BoxCollider[] existing = holder.GetComponents<BoxCollider>();
            bool same = existing.Length == boxes.Count;
            for (int i = 0; same && i < boxes.Count; i++)
            {
                same = (existing[i].center - boxes[i].center).sqrMagnitude < 1e-6f && (existing[i].size - boxes[i].size).sqrMagnitude < 1e-6f;
            }
            if (same) return;

            foreach (BoxCollider c in existing) DestroySafe(c);
            foreach (Bounds box in boxes)
            {
                BoxCollider c = holder.gameObject.AddComponent<BoxCollider>();
                c.center = box.center;
                c.size = box.size;
            }
        }

        public static void DestroySafe(UnityEngine.Object o)
        {
            if (o == null) return;
            if (Application.isPlaying) UnityEngine.Object.Destroy(o);
            else UnityEngine.Object.DestroyImmediate(o);
        }
    }
}
