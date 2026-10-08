using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// An echo theatre (残響劇): a moment of the past, kept in the stones. When a loud echo
    /// (a bell strike or a heavy blow) reaches it, golden figures replay what happened here,
    /// lit by soft pulses of gold, and their words appear. Afterwards it can be played again.
    /// The figures stand still at the start of the scene until then (an echo may show them) -
    /// except in a theatre started only from code (Trigger Radius 0), which stays hidden until it plays.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public class EchoMemoryTheatre : MonoBehaviour
    {
        [SerializeField] private Material material = null;
        [Tooltip("See EchoTheatreScenes (hall_ritual, market_night, gareth_memory).")]
        [SerializeField] private string sceneId = EchoTheatreScenes.HallRitual;
        [Tooltip("A bell strike inside this distance starts it. 0 = only started from code (a boss).")]
        [SerializeField, Min(0f)] private float triggerRadius = 14f;
        [SerializeField, Min(0.2f)] private float pulseInterval = 0.8f;
        [SerializeField, Min(1f)] private float pulseRadius = 10f;

        static readonly Dictionary<EchoFigurePose, Mesh> poseMeshes = new Dictionary<EchoFigurePose, Mesh>();

        EchoTheatreScene scene;
        readonly List<MeshFilter> actors = new List<MeshFilter>();
        bool playing;
        float startTime;
        float nextPulse;
        int nextLine;
        int nextFlash;

        public bool Playing { get { return playing; } }

        public void Setup(Material newMaterial, string newSceneId, float newTriggerRadius)
        {
            material = newMaterial;
            sceneId = newSceneId;
            triggerRadius = newTriggerRadius;
            Build();
        }

        void OnEnable()
        {
            Build();
            EchoSystem.WaveEmitted += OnWave;
        }

        void OnDisable()
        {
            EchoSystem.WaveEmitted -= OnWave;
        }

        void Build()
        {
            scene = EchoTheatreScenes.Get(sceneId);
            actors.Clear();
            if (scene == null) return;
            for (int i = 0; i < scene.actors.Count; i++)
            {
                string actorName = "_Figure " + (i + 1);
                Transform t = transform.Find(actorName);
                if (t == null)
                {
                    var go = new GameObject(actorName);
                    t = go.transform;
                    t.SetParent(transform, false);
                    go.AddComponent<MeshFilter>();
                    go.AddComponent<MeshRenderer>();
                }
                var r = t.GetComponent<MeshRenderer>();
                if (material != null) r.sharedMaterial = material;
                r.shadowCastingMode = ShadowCastingMode.Off;
                r.receiveShadows = false;
                actors.Add(t.GetComponent<MeshFilter>());
            }
            Pose(0f);
        }

        static Mesh MeshFor(EchoFigurePose pose)
        {
            Mesh m;
            if (poseMeshes.TryGetValue(pose, out m) && m != null) return m;
            var b = new EchoPointBuilder(40 + (int)pose);
            EchoFigureBody.Build(b, pose);
            m = EchoMeshUtil.Build(b, null, "Echo Figure " + pose);
            poseMeshes[pose] = m;
            return m;
        }

        /// <summary>Puts every figure where it was at time t.</summary>
        void Pose(float t)
        {
            if (scene == null) return;
            for (int i = 0; i < actors.Count && i < scene.actors.Count; i++)
            {
                EchoTheatreKey[] keys = scene.actors[i];
                int k = 0;
                while (k + 1 < keys.Length && keys[k + 1].time <= t) k++;
                EchoTheatreKey a = keys[k];
                EchoTheatreKey b = k + 1 < keys.Length ? keys[k + 1] : a;
                float u = b.time > a.time ? Mathf.Clamp01((t - a.time) / (b.time - a.time)) : 0f;
                Transform tr = actors[i].transform;
                tr.localPosition = Vector3.Lerp(a.position, b.position, u);
                tr.localRotation = Quaternion.Euler(0f, Mathf.LerpAngle(a.yaw, b.yaw, u), 0f);
                // a theatre only a boss can start stays hidden until then (it would give the story away)
                bool visible = a.pose != EchoFigurePose.None && (playing || triggerRadius > 0f || !Application.isPlaying);
                if (visible) actors[i].sharedMesh = MeshFor(a.pose);
                actors[i].GetComponent<MeshRenderer>().enabled = visible;
            }
        }

        void OnWave(EchoWave wave)
        {
            if (!Application.isPlaying || playing || triggerRadius <= 0f) return;
            if (wave.source != EchoSource.Strike || wave.strength <= 0f) return;   // the bell strike or a heavy blow (not a silent noise)
            if (Vector3.Distance(wave.origin, transform.position) > triggerRadius) return;
            Play();
        }

        /// <summary>Start the scene from the beginning.</summary>
        public void Play()
        {
            if (scene == null) return;
            playing = true;
            startTime = Time.time + 0.6f;   // let the strike's own echo pass first
            nextPulse = startTime;
            nextLine = 0;
            nextFlash = 0;
        }

        void Update()
        {
            if (!Application.isPlaying || !playing || scene == null) return;
            float t = Time.time - startTime;
            if (t < 0f) return;
            Pose(t);

            Vector3 centre = transform.position + Vector3.up * 2f;
            if (Time.time >= nextPulse)
            {
                nextPulse = Time.time + pulseInterval;
                EchoSystem.Emit(centre, pulseRadius, EchoSource.Resonance, 0.85f);
            }
            while (nextFlash < scene.flashes.Count && t >= scene.flashes[nextFlash].time)
            {
                EchoTheatreFlash f = scene.flashes[nextFlash++];
                EchoSystem.Emit(centre, f.radius, EchoSource.Resonance, 1.3f);
                EchoAudio.Play(f.sound, centre, 0.8f, f.pitch);
            }
            while (nextLine < scene.lines.Count && t >= scene.lines[nextLine].time)
            {
                EchoTheatreLine l = scene.lines[nextLine++];
                EchoGame.Say(l.speaker, l.text, l.seconds);
            }
            if (t >= scene.duration)
            {
                playing = false;
                Pose(0f);
            }
        }

        void Start()
        {
            if (Application.isPlaying) Pose(0f);   // hide a code-only theatre once the game runs
        }

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(1f, 0.85f, 0.4f, 0.5f);
            Gizmos.DrawWireCube(transform.position + Vector3.up * 2f, new Vector3(triggerRadius * 2f, 4f, triggerRadius * 2f));
        }
    }
}
