using UnityEngine;
using UnityEngine.Rendering;

namespace VoidCloak
{
    /// <summary>
    /// Hooded black cloak character made of particles.
    ///
    /// C#  : builds the cloth shape (hood, void, shoulders, cloak, folds, front panels,
    ///       lower drape, ground cloth) as points with per-particle attributes.
    /// HLSL: VoidCloakPointShader draws every point as a small satin cloth particle.
    ///
    /// Attach to an empty GameObject, assign the shader (or a material made from it),
    /// and press Play or just look at the Scene view (runs in edit mode as well).
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class VoidCloakCharacter : MonoBehaviour
    {
        [Header("Rendering")]
        [Tooltip("VoidCloak/ClothPoint shader. Used when no material template is set.")]
        [SerializeField] private Shader characterShader = null;
        [Tooltip("Optional material using the VoidCloak/ClothPoint shader. A runtime copy is used.")]
        [SerializeField] private Material materialTemplate = null;

        [Header("Build")]
        [Tooltip("Build the character step by step (hand-off document section 40).")]
        [SerializeField] private BuildStage buildStage = BuildStage.Complete;
        [SerializeField] private int seed = 1337;
        [Tooltip("Regenerate automatically when a shape / density value changes.")]
        [SerializeField] private bool autoRegenerate = true;

        [SerializeField] private VoidCloakShape shape = new VoidCloakShape();
        [SerializeField] private VoidCloakDensity density = new VoidCloakDensity();
        [Tooltip("Medieval longsword held by hands hidden in the sleeves.")]
        [SerializeField] private VoidCloakSword sword = new VoidCloakSword();

        [Header("Particles")]
        [Tooltip("World size of one particle (radius of its quad).")]
        [SerializeField, Min(0.0001f)] private float pointSize = 0.016f;
        [Tooltip("Small random size variation per particle.")]
        [SerializeField, Range(0f, 1f)] private float pointVariation = 0.2f;
        [Tooltip("Stretch of each particle along the cloth flow (fold direction).")]
        [SerializeField, Range(0f, 3f)] private float flowStretch = 0.8f;

        [Header("Wind")]
        [SerializeField, Range(0f, 0.5f)] private float windStrength = 0.04f;
        [SerializeField, Range(0f, 10f)] private float windSpeed = 1.2f;
        [SerializeField, Range(0f, 6f)] private float windFrequency = 1.3f;
        [SerializeField] private Vector3 windDirection = new Vector3(1f, 0f, 0.35f);
        [SerializeField, Range(0f, 1f)] private float windFlutter = 0.25f;

        [Header("Cloth Look")]
        [SerializeField] private Color baseColor = new Color(0.022f, 0.022f, 0.026f, 1f);
        [SerializeField] private Color sheenColor = new Color(0.62f, 0.64f, 0.68f, 1f);
        [SerializeField] private Color ambientColor = new Color(0.35f, 0.35f, 0.38f, 1f);
        [Tooltip("Direction the fake light comes FROM (world space).")]
        [SerializeField] private Vector3 fakeLightDirection = new Vector3(-0.45f, 0.75f, 0.6f);
        [SerializeField] private Color fakeLightColor = Color.white;
        [Tooltip("0 = fake light only, 1 = URP main light.")]
        [SerializeField, Range(0f, 1f)] private float mainLightInfluence = 0f;
        [SerializeField, Range(0f, 4f)] private float diffuseStrength = 1.5f;
        [SerializeField, Range(0f, 2f)] private float specularStrength = 0.42f;
        [SerializeField, Range(0.05f, 1.5f)] private float roughnessAlongFolds = 0.55f;
        [SerializeField, Range(0.02f, 1f)] private float roughnessAcrossFolds = 0.16f;
        [SerializeField, Range(0f, 3f)] private float ridgeHighlight = 0.9f;
        [SerializeField, Range(0f, 1f)] private float valleyDarkening = 0.35f;
        [SerializeField, Range(0f, 2f)] private float rimStrength = 0.25f;
        [SerializeField] private Color voidColor = new Color(0.004f, 0.004f, 0.005f, 1f);
        [SerializeField, Range(0f, 1f)] private float insideBrightness = 0.12f;
        [Tooltip("Color every particle group differently to check the structure.")]
        [SerializeField] private bool debugPartColors = false;

        [Header("Sword Look")]
        [SerializeField] private Color steelColor = new Color(0.42f, 0.43f, 0.45f, 1f);
        [Tooltip("Reflected environment below / above the horizon (fake, no reflection probe needed).")]
        [SerializeField] private Color steelEnvironmentLow = new Color(0.03f, 0.03f, 0.035f, 1f);
        [SerializeField] private Color steelEnvironmentHigh = new Color(0.58f, 0.6f, 0.64f, 1f);
        [SerializeField, Range(0f, 2f)] private float steelReflection = 0.55f;
        [SerializeField, Range(0f, 4f)] private float steelSpecular = 1.6f;
        [SerializeField, Range(4f, 512f)] private float steelGloss = 90f;
        [SerializeField] private Color gripColor = new Color(0.07f, 0.045f, 0.03f, 1f);

        [Header("Info (read only)")]
        [SerializeField, TextArea(3, 30)] private string generationReport;

        Mesh mesh;
        Material runtimeMaterial;
        Object runtimeMaterialSource;   // the Material template or Shader the runtime material was made from
        bool dirty = true;
        readonly ParticleBuffer buffer = new ParticleBuffer();

        // Walking state, written by VoidCloakMover (object space, already smoothed).
        Vector3 motionLag;
        Vector4 gait;   // x = step phase (radians), y = step push, z = body bob, w = billow (running)
        Vector4 floorMotion = new Vector4(0.85f, 0.3f, 0f, 0f);   // x = floor cloth follow, y = floor cloth lift
        Vector4 swingPivot;      // xyz = pivot of the sword arm (object space)
        Vector4 swingAxisAngle;  // xyz = rotation axis (object space), w = angle in radians

        static readonly int PointSizeId = Shader.PropertyToID("_PointSize");
        static readonly int PointVariationId = Shader.PropertyToID("_PointVariation");
        static readonly int FlowStretchId = Shader.PropertyToID("_FlowStretch");
        static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        static readonly int SheenColorId = Shader.PropertyToID("_SheenColor");
        static readonly int AmbientColorId = Shader.PropertyToID("_AmbientColor");
        static readonly int LightDirectionId = Shader.PropertyToID("_LightDirection");
        static readonly int LightColorId = Shader.PropertyToID("_LightColor");
        static readonly int MainLightInfluenceId = Shader.PropertyToID("_MainLightInfluence");
        static readonly int DiffuseStrengthId = Shader.PropertyToID("_DiffuseStrength");
        static readonly int SpecularStrengthId = Shader.PropertyToID("_SpecularStrength");
        static readonly int AnisoAlongId = Shader.PropertyToID("_AnisoAlong");
        static readonly int AnisoAcrossId = Shader.PropertyToID("_AnisoAcross");
        static readonly int RidgeHighlightId = Shader.PropertyToID("_RidgeHighlight");
        static readonly int ValleyDarkeningId = Shader.PropertyToID("_ValleyDarkening");
        static readonly int RimStrengthId = Shader.PropertyToID("_RimStrength");
        static readonly int VoidColorId = Shader.PropertyToID("_VoidColor");
        static readonly int BackfaceDarknessId = Shader.PropertyToID("_BackfaceDarkness");
        static readonly int WindStrengthId = Shader.PropertyToID("_WindStrength");
        static readonly int WindSpeedId = Shader.PropertyToID("_WindSpeed");
        static readonly int WindFrequencyId = Shader.PropertyToID("_WindFrequency");
        static readonly int WindDirectionId = Shader.PropertyToID("_WindDirection");
        static readonly int WindFlutterId = Shader.PropertyToID("_WindFlutter");
        static readonly int DebugPartsId = Shader.PropertyToID("_DebugParts");
        static readonly int SteelColorId = Shader.PropertyToID("_SteelColor");
        static readonly int SteelEnvLowId = Shader.PropertyToID("_SteelEnvLow");
        static readonly int SteelEnvHighId = Shader.PropertyToID("_SteelEnvHigh");
        static readonly int SteelReflectionId = Shader.PropertyToID("_SteelReflection");
        static readonly int SteelSpecularId = Shader.PropertyToID("_SteelSpecular");
        static readonly int SteelGlossId = Shader.PropertyToID("_SteelGloss");
        static readonly int GripColorId = Shader.PropertyToID("_GripColor");
        static readonly int MotionLagId = Shader.PropertyToID("_MotionLag");
        static readonly int GaitId = Shader.PropertyToID("_Gait");
        static readonly int FloorMotionId = Shader.PropertyToID("_FloorMotion");
        static readonly int SwingPivotId = Shader.PropertyToID("_SwingPivot");
        static readonly int SwingAxisAngleId = Shader.PropertyToID("_SwingAxisAngle");

        public int ParticleCount { get { return buffer.Count; } }

        /// <summary>Total height of the character in world units (before transform scale).</summary>
        public float Height { get { return shape.height; } }

        /// <summary>
        /// Called by <see cref="VoidCloakMover"/> every frame. The shader uses it to let the lower
        /// cloak trail behind, sway with each step and bob slightly. Rigid parts (hood, shoulders,
        /// sword) are not affected because their wind weight is ~0.
        /// </summary>
        /// <param name="lagObjectSpace">How far the hem trails, in object space (points opposite to the motion).</param>
        /// <param name="stepPhase">Gait phase in radians (one full cycle = two steps).</param>
        /// <param name="stepPush">How far each step pushes the front of the cloak forward.</param>
        /// <param name="bob">Vertical body offset.</param>
        /// <param name="billow">0 = calm, 1 = full billowing (waves running down the cloak while running).</param>
        /// <param name="floorFollow">0..1, how much the cloth lying on the floor is dragged along.</param>
        /// <param name="floorLift">How high the floor cloth lifts while running.</param>
        /// <summary>Shoulder of the sword arm in object space (the swing pivot).</summary>
        public Vector3 SwordShoulder
        {
            get { return VoidCloakGenerator.RightShoulderInside * (shape.height / VoidCloakGenerator.ReferenceHeight); }
        }

        /// <summary>Direction from the shoulder to the sword tip in the resting pose (object space).</summary>
        public Vector3 SwordRestDirection
        {
            get
            {
                Vector3 tip, dir;
                VoidCloakGenerator.SwordRestPose(sword, out tip, out dir);
                Vector3 d = tip - VoidCloakGenerator.RightShoulderInside;
                return d.sqrMagnitude > 1e-6f ? d.normalized : Vector3.down;
            }
        }

        /// <summary>
        /// Rotates the sword and the sword sleeve around <paramref name="pivotObjectSpace"/>
        /// (used by EchoCombat for attacks and parries). Angle 0 = resting pose.
        /// </summary>
        public void SetSwing(Vector3 pivotObjectSpace, Vector3 axisObjectSpace, float angleRadians)
        {
            Vector3 axis = axisObjectSpace.sqrMagnitude > 1e-8f ? axisObjectSpace.normalized : Vector3.up;
            swingPivot = new Vector4(pivotObjectSpace.x, pivotObjectSpace.y, pivotObjectSpace.z, 0f);
            swingAxisAngle = new Vector4(axis.x, axis.y, axis.z, angleRadians);
        }

        public void SetMotion(Vector3 lagObjectSpace, float stepPhase, float stepPush, float bob, float billow = 0f,
                              float floorFollow = 0.85f, float floorLift = 0.3f)
        {
            motionLag = lagObjectSpace;
            gait = new Vector4(stepPhase, stepPush, bob, billow);
            floorMotion = new Vector4(floorFollow, floorLift, 0f, 0f);
        }

        void OnEnable()
        {
            dirty = true;
            Regenerate();
        }

        void OnValidate()
        {
            // Mesh work is not allowed inside OnValidate; defer to Update.
            if (autoRegenerate) dirty = true;
        }

        void Update()
        {
            if (dirty) Regenerate();
            ApplyMaterial();
        }

        void OnDisable()
        {
            var filter = GetComponent<MeshFilter>();
            if (filter != null && filter.sharedMesh == mesh) filter.sharedMesh = null;
            DestroySafe(mesh);
            DestroySafe(runtimeMaterial);
            mesh = null;
            runtimeMaterial = null;
            runtimeMaterialSource = null;
        }

        static void DestroySafe(Object o)
        {
            if (o == null) return;
            if (Application.isPlaying) Destroy(o);
            else DestroyImmediate(o);
        }

        [ContextMenu("Regenerate")]
        public void Regenerate()
        {
            dirty = false;

            var generator = new VoidCloakGenerator(shape, density, sword, buildStage, seed, buffer);
            generator.Generate();
            BuildMesh();
            ApplyMaterial();
            BuildReport();
        }

        void BuildMesh()
        {
            if (mesh == null)
            {
                mesh = new Mesh { name = "VoidCloakParticles", hideFlags = HideFlags.DontSave };
                mesh.indexFormat = IndexFormat.UInt32;
                mesh.MarkDynamic();
            }
            mesh.Clear();
            mesh.SetVertices(buffer.positions);
            mesh.SetNormals(buffer.normals);
            mesh.SetTangents(buffer.tangents);
            mesh.SetColors(buffer.colors);
            mesh.SetUVs(0, buffer.uv0);
            mesh.SetUVs(1, buffer.uv1);
            mesh.SetUVs(2, buffer.uv2);

            var indices = new int[buffer.Count];
            for (int i = 0; i < indices.Length; i++) indices[i] = i;
            mesh.SetIndices(indices, MeshTopology.Points, 0, false);

            mesh.RecalculateBounds();
            Bounds b = mesh.bounds;
            b.Expand(windStrength * 4f + pointSize * 8f + 1.5f); // room for wind and walking motion
            mesh.bounds = b;

            GetComponent<MeshFilter>().sharedMesh = mesh;
        }

        void EnsureMaterial()
        {
            Object source = materialTemplate != null ? (Object)materialTemplate : characterShader;
            if (runtimeMaterial != null && runtimeMaterialSource == source && source != null) return;

            DestroySafe(runtimeMaterial);
            runtimeMaterial = null;
            runtimeMaterialSource = source;

            if (materialTemplate != null)
            {
                runtimeMaterial = new Material(materialTemplate);
            }
            else if (characterShader != null)
            {
                runtimeMaterial = new Material(characterShader);
            }
            else
            {
                // Last resort only - assign the shader in the Inspector so it is included in builds.
                Shader fallback = Shader.Find("VoidCloak/ClothPoint");
                if (fallback == null)
                {
                    Debug.LogWarning("[VoidCloak] Assign the VoidCloak/ClothPoint shader to 'Character Shader'.", this);
                    return;
                }
                runtimeMaterial = new Material(fallback);
            }
            runtimeMaterial.name = "VoidCloak (Runtime)";
            runtimeMaterial.hideFlags = HideFlags.DontSave;

            var renderer = GetComponent<MeshRenderer>();
            renderer.sharedMaterial = runtimeMaterial;
            renderer.shadowCastingMode = ShadowCastingMode.Off;
            renderer.receiveShadows = false;
        }

        void ApplyMaterial()
        {
            EnsureMaterial();
            if (runtimeMaterial == null) return;

            var renderer = GetComponent<MeshRenderer>();
            if (renderer.sharedMaterial != runtimeMaterial) renderer.sharedMaterial = runtimeMaterial;

            float scale = shape.height / VoidCloakGenerator.ReferenceHeight;
            Material m = runtimeMaterial;
            m.SetFloat(PointSizeId, pointSize);
            m.SetFloat(PointVariationId, pointVariation);
            m.SetFloat(FlowStretchId, flowStretch);
            m.SetColor(BaseColorId, baseColor);
            m.SetColor(SheenColorId, sheenColor);
            m.SetColor(AmbientColorId, ambientColor);
            m.SetVector(LightDirectionId, fakeLightDirection.normalized);
            m.SetColor(LightColorId, fakeLightColor);
            m.SetFloat(MainLightInfluenceId, mainLightInfluence);
            m.SetFloat(DiffuseStrengthId, diffuseStrength);
            m.SetFloat(SpecularStrengthId, specularStrength);
            m.SetFloat(AnisoAlongId, roughnessAlongFolds);
            m.SetFloat(AnisoAcrossId, roughnessAcrossFolds);
            m.SetFloat(RidgeHighlightId, ridgeHighlight);
            m.SetFloat(ValleyDarkeningId, valleyDarkening);
            m.SetFloat(RimStrengthId, rimStrength);
            m.SetColor(VoidColorId, voidColor);
            m.SetFloat(BackfaceDarknessId, insideBrightness);
            m.SetFloat(WindStrengthId, windStrength * scale);
            m.SetFloat(WindSpeedId, windSpeed);
            m.SetFloat(WindFrequencyId, windFrequency / Mathf.Max(0.01f, scale));
            m.SetVector(WindDirectionId, windDirection);
            m.SetFloat(WindFlutterId, windFlutter);
            m.SetFloat(DebugPartsId, debugPartColors ? 1f : 0f);
            m.SetColor(SteelColorId, steelColor);
            m.SetColor(SteelEnvLowId, steelEnvironmentLow);
            m.SetColor(SteelEnvHighId, steelEnvironmentHigh);
            m.SetFloat(SteelReflectionId, steelReflection);
            m.SetFloat(SteelSpecularId, steelSpecular);
            m.SetFloat(SteelGlossId, steelGloss);
            m.SetColor(GripColorId, gripColor);
            m.SetVector(MotionLagId, motionLag);
            m.SetVector(GaitId, gait);
            m.SetVector(FloorMotionId, floorMotion);
            m.SetVector(SwingPivotId, swingPivot);
            m.SetVector(SwingAxisAngleId, swingAxisAngle);
        }

        void BuildReport()
        {
            var sb = new System.Text.StringBuilder();
            sb.AppendLine("Stage: " + buildStage + "   Particles: " + buffer.Count);
            for (int i = 0; i < (int)CloakPart.Count; i++)
            {
                if (buffer.partCounts[i] > 0) sb.AppendLine(((CloakPart)i) + ": " + buffer.partCounts[i]);
            }
            generationReport = sb.ToString();
        }
    }
}
