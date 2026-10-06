using System;
using UnityEngine;

namespace VoidCloak
{
    /// <summary>
    /// Particle group identifiers. The id is written into the vertex color (r channel)
    /// so the shader can treat groups differently (void darkening, debug colors).
    /// </summary>
    public enum CloakPart
    {
        HoodCrown = 0,
        HoodLeftShell = 1,
        HoodRightShell = 2,
        HoodOpeningRim = 3,
        HoodInnerVoid = 4,

        LeftShoulder = 5,
        RightShoulder = 6,

        OuterLeftSurface = 7,
        OuterRightSurface = 8,
        OuterLeftMajorFolds = 9,
        OuterRightMajorFolds = 10,
        SecondaryFolds = 11,

        CenterLeft = 12,
        CenterRight = 13,
        FrontFold = 14,

        LowerLeftTransition = 15,
        LowerRightTransition = 16,

        GroundLeftOuter = 17,
        GroundLeftMiddle = 18,
        GroundLeftInner = 19,
        GroundRightOuter = 20,
        GroundRightMiddle = 21,
        GroundRightInner = 22,
        GroundWrinkles = 23,

        HemEdge = 24,

        SwordBlade = 25,
        SwordEdge = 26,
        SwordGuard = 27,
        SwordGrip = 28,
        SwordPommel = 29,
        Sleeve = 30,
        SleeveVoid = 31,

        Count = 32,
    }

    /// <summary>
    /// Production steps from the hand-off document (section 40).
    /// Every step includes all previous steps, so the shape can be checked stage by stage.
    /// Steps 10 (gloss) and 11 (wind) live in the shader and are always active.
    /// </summary>
    public enum BuildStage
    {
        Step01_HoodAndVoid = 1,
        Step02_Shoulders = 2,
        Step03_OuterSilhouette = 3,
        Step04_MajorFolds = 4,
        Step05_FrontCloak = 5,
        Step06_LowerDrape = 6,
        Step07_GroundCloth = 7,
        Step08_SecondaryFolds = 8,
        Step09_MicroNoise = 9,
        Complete = 10,
    }

    /// <summary>
    /// Shape parameters. All lengths are authored for a 4.2 unit tall character and the
    /// final point cloud is uniformly scaled to <see cref="height"/>.
    /// </summary>
    [Serializable]
    public class VoidCloakShape
    {
        [Header("Overall")]
        [Tooltip("Total height (feet at Y=0, hood tip at Y=height).")]
        [Min(0.1f)] public float height = 4.2f;

        [Header("Hood")]
        [Tooltip("Full width of the hood shell.")]
        [Range(0.3f, 1.2f)] public float hoodWidth = 0.66f;
        [Tooltip("Vertical size of the hood from its lower hem to the crown tip.")]
        [Range(0.5f, 1.4f)] public float hoodHeight = 0.94f;
        [Tooltip("Front-back depth of the hood shell.")]
        [Range(0.4f, 1.2f)] public float hoodDepth = 0.76f;
        [Tooltip("Full width of the face opening.")]
        [Range(0.15f, 0.6f)] public float openingWidth = 0.37f;
        [Tooltip("Top of the face opening as a fraction of the hood height.")]
        [Range(0.5f, 0.95f)] public float openingTop = 0.8f;
        [Tooltip("Bottom tip of the face opening as a fraction of the hood height.")]
        [Range(0.0f, 0.4f)] public float openingBottom = 0.12f;
        [Tooltip("How pointed the crown is (1 = cone, 2 = dome).")]
        [Range(1.0f, 2.0f)] public float crownSoftness = 1.3f;
        [Range(0f, 0.4f)] public float hoodFoldDepth = 0.14f;

        [Header("Shoulders")]
        [Tooltip("Half width of the shoulder cape edge.")]
        [Range(0.3f, 1.0f)] public float shoulderWidth = 0.58f;
        [Tooltip("How far the shoulder cape drops from the neck to its edge.")]
        [Range(0.1f, 0.8f)] public float shoulderDrop = 0.48f;
        [Range(0f, 0.4f)] public float shoulderFoldDepth = 0.06f;

        [Header("Outer Cloak")]
        [Tooltip("Width multiplier for the upper cloak.")]
        [Range(0.5f, 1.6f)] public float cloakWidth = 1.0f;
        [Tooltip("Width multiplier for the lower cloak / hem.")]
        [Range(0.5f, 1.8f)] public float hemWidth = 1.0f;
        [Tooltip("Front-back depth multiplier.")]
        [Range(0.5f, 1.6f)] public float cloakDepth = 1.0f;
        [Tooltip("Height where the cloth starts bending onto the ground.")]
        [Range(0.1f, 1.0f)] public float hemBendHeight = 0.4f;
        [Tooltip("Half angle (radians) of the front opening at the top / at the hem.")]
        public Vector2 frontGap = new Vector2(0.38f, 0.6f);

        [Header("Folds")]
        [Tooltip("Number of major folds around the outer cloak (25-35 in the reference).")]
        [Range(8, 60)] public int foldCount = 30;
        [Tooltip("Fold depth relative to the local fold spacing.")]
        [Range(0f, 0.6f)] public float foldAmplitude = 0.3f;
        [Tooltip("Irregularity of the fold spacing (0 = equal spacing).")]
        [Range(0f, 1f)] public float foldIrregularity = 0.75f;
        [Tooltip("How much folds drift sideways toward the hem.")]
        [Range(0f, 0.1f)] public float foldDrift = 0.025f;
        [Range(0, 120)] public int secondaryFoldCount = 64;
        [Range(0f, 0.4f)] public float secondaryAmplitude = 0.16f;
        [Range(0f, 0.03f)] public float microNoise = 0.006f;

        [Header("Front Cloak")]
        [Range(1, 10)] public int frontPanelFolds = 5;
        [Range(0f, 0.6f)] public float frontPanelFoldDepth = 0.28f;
        [Tooltip("How far the centre panels stand in front of the outer cloak.")]
        [Range(0f, 0.2f)] public float frontPanelOffset = 0.07f;

        [Header("Ground Cloth")]
        [Tooltip("How far the cloth spreads on the ground at the sides.")]
        [Range(0f, 1.5f)] public float groundSpread = 0.55f;
        [Tooltip("Extra train length at the back.")]
        [Range(0f, 1.5f)] public float groundTrain = 0.22f;
        [Tooltip("Height of the transverse wrinkles on the ground cloth.")]
        [Range(0f, 0.1f)] public float groundWrinkleHeight = 0.03f;
        [Tooltip("Strength of the Outer/Middle/Inner cloth bundles on the ground.")]
        [Range(0f, 1f)] public float groundBundleStrength = 0.45f;

        [Header("Particle Thickness")]
        [Range(0f, 0.1f)] public float clothThickness = 0.016f;
        [Range(0f, 0.15f)] public float shoulderThickness = 0.045f;
    }

    /// <summary>
    /// Particle budget per group (section 27 of the hand-off document).
    /// </summary>
    [Serializable]
    public class VoidCloakDensity
    {
        [Tooltip("Global multiplier applied to every count.")]
        [Range(0.05f, 4f)] public float multiplier = 1f;

        [Header("Hood")]
        public int hoodCrown = 3000;
        public int hoodShells = 9000;
        public int hoodRim = 4000;
        public int hoodInnerVoid = 3000;

        [Header("Shoulders")]
        public int shoulders = 6000;

        [Header("Outer Cloak")]
        public int outerSurface = 25000;
        public int majorFolds = 15000;
        public int secondaryFolds = 10000;
        public int frontEdges = 1500;

        [Header("Front Cloak")]
        public int centerPanels = 6000;
        public int frontFold = 7000;

        [Header("Lower / Ground")]
        public int lowerDrape = 10000;
        public int groundCloth = 12000;
        public int groundWrinkles = 2000;
        public int hemEdge = 3000;

        public int Scaled(int count)
        {
            return Mathf.Max(0, Mathf.RoundToInt(count * multiplier));
        }
    }
}
