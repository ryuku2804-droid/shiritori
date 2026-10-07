using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// A small bell on a stand, part of a sound puzzle (see <see cref="EchoBellDoor"/>).
    /// Ring it by striking it with the sword or by pressing F (gamepad A) next to it.
    /// Every bell has its own note. Ringing it is loud: Listeners hear it like a bell strike.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoPuzzleBell : MonoBehaviour, IEchoHittable
    {
        /// <summary>Pitch of each note relative to the bell sound (a minor pentatonic scale).</summary>
        static readonly float[] NotePitch = { 1f, 1.189f, 1.335f, 1.498f, 1.782f, 2f };

        [SerializeField] private Material material = null;
        [Tooltip("Which note this bell plays (0 = lowest).")]
        [SerializeField, Range(0, 5)] private int note = 0;
        [SerializeField, Min(0.5f)] private float interactDistance = 2.8f;
        [Tooltip("Echo when the knight rings it (enemies hear it).")]
        [SerializeField, Min(0f)] private float ringEchoRadius = 12f;
        [Tooltip("Small gold glow when the door plays the melody (enemies do not hear it).")]
        [SerializeField, Min(0f)] private float chimeEchoRadius = 2.5f;

        /// <summary>Raised when the knight rings this bell.</summary>
        public event Action<EchoPuzzleBell> Rung;

        Mesh standMesh, bellMesh;
        Transform bell;
        float ringTime = -100f;
        float swingSign = 1f;

        public bool IsAlive { get { return true; } }
        public Vector3 Position { get { return transform.position; } }
        public int Note { get { return note; } }

        public void Setup(Material newMaterial, int newNote)
        {
            material = newMaterial;
            note = newNote;
            Build();
        }

        void OnEnable()
        {
            Build();
            EchoTargets.Register(this);
        }

        void OnDisable()
        {
            EchoTargets.Unregister(this);
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == standMesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(standMesh);
            EchoMeshUtil.DestroySafe(bellMesh);
            standMesh = null;
            bellMesh = null;
        }

        void Build()
        {
            var b = new EchoPointBuilder(61);
            var boxes = new List<Bounds>();
            EchoPuzzleBellShape.BuildStand(b, boxes);
            standMesh = EchoMeshUtil.Build(b, standMesh, "Puzzle Bell Stand");
            GetComponent<MeshFilter>().sharedMesh = standMesh;
            ApplyMaterial(GetComponent<MeshRenderer>());
            EchoMeshUtil.SyncBoxColliders(transform, boxes);

            bell = transform.Find("_Bell");
            if (bell == null)
            {
                var go = new GameObject("_Bell");
                bell = go.transform;
                bell.SetParent(transform, false);
                go.AddComponent<MeshFilter>();
                go.AddComponent<MeshRenderer>();
            }
            bell.localPosition = EchoPuzzleBellShape.BellPivot;
            var bb = new EchoPointBuilder(62);
            EchoPuzzleBellShape.BuildBell(bb);
            bellMesh = EchoMeshUtil.Build(bb, bellMesh, "Puzzle Bell");
            bell.GetComponent<MeshFilter>().sharedMesh = bellMesh;
            ApplyMaterial(bell.GetComponent<MeshRenderer>());
        }

        void ApplyMaterial(MeshRenderer r)
        {
            if (r == null) return;
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
        }

        Vector3 BellPoint { get { return transform.TransformPoint(EchoPuzzleBellShape.BellPivot + Vector3.down * 0.35f); } }

        void Update()
        {
            if (!Application.isPlaying) return;
            float t = Time.time - ringTime;
            float swing = t < 3f ? 30f * swingSign * Mathf.Exp(-t * 1.6f) * Mathf.Sin(t * 9f) : 0f;
            if (bell != null) bell.localRotation = Quaternion.Euler(swing, 0f, 0f);

            if (PlayerInReach() && EchoBellShrine.InteractPressed()) Ring(true);
        }

        bool PlayerInReach()
        {
            EchoPlayer player = EchoPlayer.Current;
            if (player == null) return false;
            Vector3 d = player.transform.position - transform.position;
            d.y = 0f;
            return d.magnitude <= interactDistance;
        }

        /// <summary>Struck by the sword: it rings (the blade does not hurt it).</summary>
        public void TakeHit(float damage, Vector3 from)
        {
            swingSign = Vector3.Dot(transform.forward, transform.position - from) >= 0f ? 1f : -1f;
            Ring(true);
        }

        /// <summary>
        /// Rings the bell. byKnight = true: loud, enemies hear it, and the puzzle counts it.
        /// false: the door is playing the melody - a soft gold glow only.
        /// </summary>
        public void Ring(bool byKnight)
        {
            if (byKnight && Time.time - ringTime < 0.35f) return;   // one swing, one ring
            ringTime = Time.time;
            float pitch = NotePitch[Mathf.Clamp(note, 0, NotePitch.Length - 1)];
            EchoAudio.Play(EchoSound.PuzzleBell, BellPoint, byKnight ? 0.9f : 0.75f, pitch);
            if (byKnight)
            {
                EchoSystem.Emit(BellPoint, ringEchoRadius, EchoSource.Strike, 0.9f);
                if (Rung != null) Rung(this);
            }
            else if (chimeEchoRadius > 0f)
            {
                EchoSystem.Emit(BellPoint, chimeEchoRadius, EchoSource.Resonance, 0.9f);
            }
        }

        void OnGUI()
        {
            if (!Application.isPlaying || !PlayerInReach()) return;
            EchoScreenText.DrawPrompt("F（ゲームパッドA）または剣で打つ：鐘を鳴らす", 0.9f);
        }
    }
}
