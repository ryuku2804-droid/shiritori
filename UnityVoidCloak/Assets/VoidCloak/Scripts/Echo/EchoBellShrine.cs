using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace EchoKnight
{
    /// <summary>
    /// Bell shrine - the save point.
    ///
    /// Stand next to it and press F (gamepad A) to ring the bell:
    ///   - a big golden echo spreads out,
    ///   - the knight's health is restored,
    ///   - the knight will come back here after falling,
    ///   - Listeners caught by the sound flee (the bell's sound is what held the Silence back).
    ///
    /// The shrine is drawn in gold (use the EchoGold material) and, like everything else,
    /// is only visible when an echo passes over it.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class EchoBellShrine : MonoBehaviour
    {
        [Tooltip("Material using EchoKnight/WorldPoint, gold (EchoGold).")]
        [SerializeField] private Material material = null;
        [SerializeField, Min(0.5f)] private float interactDistance = 4.5f;
        [SerializeField, Min(0f)] private float ringEchoRadius = 45f;
        [SerializeField, Range(0f, 3f)] private float ringEchoStrength = 1.2f;
        [Tooltip("Seconds before the bell can be rung again.")]
        [SerializeField, Min(0f)] private float ringCooldown = 2f;
        [Tooltip("How far the knight respawns in front of the shrine.")]
        [SerializeField, Min(0f)] private float respawnOffset = 3f;

        Mesh frameMesh;
        Mesh bellMesh;
        Transform bell;
        float ringTime = -100f;
        float messageUntil;
        bool activated;

        /// <summary>The shrine the knight will return to (null until one is rung).</summary>
        public static EchoBellShrine ActiveShrine { get; private set; }

        public void Setup(Material newMaterial)
        {
            material = newMaterial;
            Build();
        }

        void OnEnable()
        {
            Build();
        }

        void OnDisable()
        {
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == frameMesh) filter.sharedMesh = null;
            EchoMeshUtil.DestroySafe(frameMesh);
            EchoMeshUtil.DestroySafe(bellMesh);
            frameMesh = null;
            bellMesh = null;
            if (ActiveShrine == this) ActiveShrine = null;
        }

        void Build()
        {
            var b = new EchoPointBuilder(91);
            var boxes = new List<Bounds>();
            EchoBellShrineShape.BuildFrame(b, boxes);
            frameMesh = EchoMeshUtil.Build(b, frameMesh, "Bell Shrine");
            GetComponent<MeshFilter>().sharedMesh = frameMesh;
            ApplyMaterial(GetComponent<MeshRenderer>());
            EchoMeshUtil.SyncBoxColliders(transform, boxes);

            // the bell is a child so it can swing
            bell = transform.Find("_Bell");
            if (bell == null)
            {
                var go = new GameObject("_Bell");
                bell = go.transform;
                bell.SetParent(transform, false);
                go.AddComponent<MeshFilter>();
                go.AddComponent<MeshRenderer>();
            }
            bell.localPosition = EchoBellShrineShape.BellPivot;
            var bb = new EchoPointBuilder(92);
            EchoBellShrineShape.BuildBell(bb);
            bellMesh = EchoMeshUtil.Build(bb, bellMesh, "Shrine Bell");
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

        void Update()
        {
            if (!Application.isPlaying) return;

            // the bell keeps swinging for a while after being rung
            float t = Time.time - ringTime;
            float swing = t < 4f ? 28f * Mathf.Exp(-t * 1.1f) * Mathf.Sin(t * 5.5f) : 0f;
            if (bell != null) bell.localRotation = Quaternion.Euler(swing, 0f, 0f);

            if (PlayerInReach() && InteractPressed() && t >= ringCooldown) Ring();
        }

        bool PlayerInReach()
        {
            EchoPlayer player = EchoPlayer.Current;
            if (player == null) return false;
            Vector3 d = player.transform.position - transform.position;
            d.y = 0f;
            return d.magnitude <= interactDistance;
        }

        void Ring()
        {
            ringTime = Time.time;
            messageUntil = Time.time + 2.5f;
            activated = true;
            ActiveShrine = this;
            EchoSystem.Emit(transform.TransformPoint(EchoBellShrineShape.BellPivot), ringEchoRadius, EchoSource.Bell, ringEchoStrength);
            EchoAudio.Play(EchoSound.ShrineBell, transform.TransformPoint(EchoBellShrineShape.BellPivot), 1f);

            EchoGame.SaveShrine(gameObject.name);
            SetCheckpointHere(false);
        }

        /// <summary>"Continue" from the title screen: the knight wakes up in front of this shrine.</summary>
        public void ResumeHere()
        {
            activated = true;
            ActiveShrine = this;
            SetCheckpointHere(true);
        }

        void SetCheckpointHere(bool moveThere)
        {
            EchoPlayer player = EchoPlayer.Current;
            if (player == null) return;
            Vector3 spot = transform.position + transform.forward * respawnOffset;
            Quaternion facing = Quaternion.LookRotation(-transform.forward, Vector3.up);
            player.SetCheckpoint(spot, facing);
            var combat = player.GetComponent<EchoCombat>();
            if (combat != null) combat.RestoreHealth();
            if (moveThere) player.Respawn();
        }

        /// <summary>F key or gamepad A this frame (also used by the puzzle bells).</summary>
        internal static bool InteractPressed()
        {
            if (EchoGame.Paused) return false;
#if ENABLE_INPUT_SYSTEM
            var kb = UnityEngine.InputSystem.Keyboard.current;
            if (kb != null && kb.fKey.wasPressedThisFrame) return true;
            var pad = UnityEngine.InputSystem.Gamepad.current;
            if (pad != null && pad.buttonSouth.wasPressedThisFrame) return true;
#endif
#if ENABLE_LEGACY_INPUT_MANAGER
            if (Input.GetKeyDown(KeyCode.F) || Input.GetKeyDown(KeyCode.JoystickButton0)) return true;
#endif
            return false;
        }

        // a short hint only while standing at the shrine (the game has no other HUD)
        void OnGUI()
        {
            if (!Application.isPlaying) return;
            string text = null;
            if (Time.time < messageUntil) text = "鐘が鳴った ― 倒れてもここから再び歩き出せる";
            else if (PlayerInReach()) text = activated ? "F（ゲームパッドA）：もう一度鐘を鳴らす" : "F（ゲームパッドA）：鐘を鳴らす";
            if (text == null) return;

            var style = new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter, fontSize = Mathf.Max(14, Screen.height / 40) };
            style.normal.textColor = new Color(1f, 0.85f, 0.5f, 0.9f);
            GUI.Label(new Rect(0f, Screen.height * 0.82f, Screen.width, Screen.height * 0.08f), text, style);
        }
    }
}
