using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// Sound puzzle: a sealed double door that "sings" a melody when the knight comes near.
    /// Each note is played by one of the puzzle bells, from where that bell stands, so the
    /// knight hears which direction each note comes from. Ring the bells in the same order
    /// and the door swings open. A wrong bell makes the door clank and the order starts over.
    ///
    /// Place it in an arched opening: origin at the bottom centre of the opening. The knight
    /// comes from the -Z side of the transform; the leaves swing open towards +Z.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public class EchoBellDoor : MonoBehaviour
    {
        [SerializeField] private Material material = null;
        [Tooltip("Width of the opening (the two leaves share it).")]
        [SerializeField, Min(1f)] private float width = 5f;
        [Tooltip("Height of the opening at its top (the arch is a half circle).")]
        [SerializeField, Min(1f)] private float openingHeight = 6.5f;

        [Header("Puzzle")]
        [SerializeField] private EchoPuzzleBell[] bells = new EchoPuzzleBell[0];
        [Tooltip("The melody: indexes into Bells, in order.")]
        [SerializeField] private int[] sequence = new int[0];
        [Tooltip("The melody plays when the knight comes this close (in front of the door).")]
        [SerializeField, Min(1f)] private float listenDistance = 7f;
        [SerializeField, Min(0.2f)] private float noteInterval = 0.9f;
        [Tooltip("Seconds before the melody can play again.")]
        [SerializeField, Min(0f)] private float replayCooldown = 6f;

        [Header("Opening")]
        [SerializeField, Range(0f, 170f)] private float openAngle = 100f;
        [SerializeField, Min(0.1f)] private float openTime = 2.6f;
        [SerializeField, Min(0f)] private float openEchoRadius = 30f;

        readonly Mesh[] meshes = new Mesh[2];
        readonly Transform[] leaves = new Transform[2];
        int progress;
        bool solved;
        float openStart = -100f;
        float melodyStart = -100f;
        int melodyNext = -1;
        float lastMelodyEnd = -100f;
        bool wasNear;
        float messageUntil;

        public bool Solved { get { return solved; } }

        public void Setup(Material newMaterial, float newWidth, float newOpeningHeight, EchoPuzzleBell[] newBells, int[] newSequence)
        {
            material = newMaterial;
            width = newWidth;
            openingHeight = newOpeningHeight;
            bells = newBells;
            sequence = newSequence;
            Build();
            Subscribe(true);
        }

        void OnEnable()
        {
            Build();
            Subscribe(true);
        }

        void OnDisable()
        {
            Subscribe(false);
            for (int i = 0; i < 2; i++)
            {
                if (leaves[i] != null)
                {
                    var f = leaves[i].GetComponent<MeshFilter>();
                    if (f != null && f.sharedMesh == meshes[i]) f.sharedMesh = null;
                }
                EchoMeshUtil.DestroySafe(meshes[i]);
                meshes[i] = null;
            }
        }

        void Subscribe(bool on)
        {
            if (bells == null) return;
            foreach (EchoPuzzleBell bell in bells)
            {
                if (bell == null) continue;
                bell.Rung -= OnBellRung;   // never twice
                if (on) bell.Rung += OnBellRung;
            }
        }

        void Build()
        {
            for (int i = 0; i < 2; i++)
            {
                int side = i == 0 ? -1 : 1;
                string name = i == 0 ? "_LeafLeft" : "_LeafRight";
                Transform leaf = transform.Find(name);
                if (leaf == null)
                {
                    var go = new GameObject(name);
                    leaf = go.transform;
                    leaf.SetParent(transform, false);
                    go.AddComponent<MeshFilter>();
                    go.AddComponent<MeshRenderer>();
                }
                leaf.localPosition = new Vector3(side * width * 0.5f, 0f, 0f);   // the hinge
                leaves[i] = leaf;

                var b = new EchoPointBuilder(71 + i);
                var boxes = new List<Bounds>();
                EchoBellDoorShape.BuildLeaf(b, width, openingHeight, side, boxes);
                meshes[i] = EchoMeshUtil.Build(b, meshes[i], "Bell Door Leaf");
                leaf.GetComponent<MeshFilter>().sharedMesh = meshes[i];
                var r = leaf.GetComponent<MeshRenderer>();
                if (material != null) r.sharedMaterial = material;
                r.shadowCastingMode = ShadowCastingMode.Off;
                r.receiveShadows = false;
                EchoMeshUtil.SyncBoxColliders(leaf, boxes);
            }
            ApplyLeafRotation();
        }

        void ApplyLeafRotation()
        {
            float k = solved ? Smooth(Mathf.Clamp01((Time.time - openStart) / openTime)) : 0f;
            for (int i = 0; i < 2; i++)
            {
                if (leaves[i] == null) continue;
                // both leaves swing towards +Z, away from the knight
                float sign = i == 0 ? -1f : 1f;
                leaves[i].localRotation = Quaternion.Euler(0f, sign * openAngle * k, 0f);
            }
        }

        static float Smooth(float x)
        {
            return x * x * (3f - 2f * x);
        }

        Vector3 Center { get { return transform.position + Vector3.up * (openingHeight * 0.5f); } }

        void Update()
        {
            if (!Application.isPlaying) return;
            ApplyLeafRotation();
            if (solved) return;

            // the knight comes close (on the near side): the door sings its melody
            EchoPlayer player = EchoPlayer.Current;
            bool near = false;
            if (player != null)
            {
                Vector3 local = transform.InverseTransformPoint(player.transform.position);
                near = local.z < 0f && new Vector2(local.x, local.z).magnitude < listenDistance;
            }
            if (near && !wasNear && melodyNext < 0 && Time.time - lastMelodyEnd >= replayCooldown) StartMelody(0.3f);
            wasNear = near;

            // play the next note when it is due
            if (melodyNext >= 0 && Time.time >= melodyStart + melodyNext * noteInterval)
            {
                int index = sequence[melodyNext];
                if (index >= 0 && index < bells.Length && bells[index] != null) bells[index].Ring(false);
                melodyNext++;
                if (melodyNext >= sequence.Length)
                {
                    melodyNext = -1;
                    lastMelodyEnd = Time.time;
                }
            }
        }

        void StartMelody(float delay)
        {
            if (sequence == null || sequence.Length == 0) return;
            progress = 0;   // listening again starts the answer over
            melodyStart = Time.time + delay;
            melodyNext = 0;
        }

        void OnBellRung(EchoPuzzleBell bell)
        {
            if (solved || sequence == null || sequence.Length == 0) return;
            if (melodyNext >= 0) return;   // the door is still singing

            int expected = sequence[progress];
            if (expected >= 0 && expected < bells.Length && bells[expected] == bell)
            {
                progress++;
                if (progress >= sequence.Length) Open();
                return;
            }

            // wrong bell: the door refuses, and the answer starts over (this bell may be a new start)
            EchoAudio.Play(EchoSound.PuzzleWrong, Center, 0.9f, 1f, 0.35f);
            int first = sequence[0];
            progress = first >= 0 && first < bells.Length && bells[first] == bell ? 1 : 0;
        }

        /// <summary>Opens without the puzzle (a door sealed until a boss falls).</summary>
        public void ForceOpen()
        {
            if (!solved) Open();
        }

        void Open()
        {
            solved = true;
            openStart = Time.time + 0.6f;   // a beat of silence after the last note
            messageUntil = Time.time + 4f;
            EchoSystem.Emit(Center, openEchoRadius, EchoSource.Resonance, 1.2f);
            EchoAudio.Play(EchoSound.DoorOpen, Center, 1f, 1f, 0.6f);
        }

        void OnGUI()
        {
            if (!Application.isPlaying || Time.time >= messageUntil) return;
            float a = Mathf.Clamp01((messageUntil - Time.time) / 0.8f);
            EchoScreenText.Draw("リーネ", "……開いた。兄さん、先へ。", null, a);
        }

        void OnDrawGizmos()
        {
            if (bells == null) return;
            Gizmos.color = new Color(1f, 0.8f, 0.4f, 0.6f);
            foreach (EchoPuzzleBell bell in bells)
            {
                if (bell != null) Gizmos.DrawLine(Center, bell.transform.position + Vector3.up * 2f);
            }
        }
    }
}
