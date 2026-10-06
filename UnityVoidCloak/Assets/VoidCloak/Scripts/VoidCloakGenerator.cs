using System;
using System.Collections.Generic;
using UnityEngine;

namespace VoidCloak
{
    /// <summary>
    /// Plain particle arrays, ready to be copied into a Mesh with MeshTopology.Points.
    ///
    /// Vertex layout (read by VoidCloakPointShader):
    ///   position  : particle position (object space)
    ///   normal    : cloth normal (away from the body on the outside of the cloth)
    ///   tangent   : xyz = cloth flow direction (along the folds), w = layer (-1 back .. +1 front)
    ///   color     : r = part id / 32, g = major ridge (0 valley .. 1 crest), b = void amount, a = random
    ///   uv0       : x = size multiplier, y = wind weight
    ///   uv1       : x = secondary ridge (0..1), y = baked occlusion (0..1)
    /// </summary>
    public sealed class ParticleBuffer
    {
        public readonly List<Vector3> positions = new List<Vector3>();
        public readonly List<Vector3> normals = new List<Vector3>();
        public readonly List<Vector4> tangents = new List<Vector4>();
        public readonly List<Color> colors = new List<Color>();
        public readonly List<Vector2> uv0 = new List<Vector2>();
        public readonly List<Vector2> uv1 = new List<Vector2>();
        public readonly int[] partCounts = new int[(int)CloakPart.Count];

        public int Count { get { return positions.Count; } }

        public void Clear()
        {
            positions.Clear();
            normals.Clear();
            tangents.Clear();
            colors.Clear();
            uv0.Clear();
            uv1.Clear();
            Array.Clear(partCounts, 0, partCounts.Length);
        }

        public void Add(CloakPart part, Vector3 p, Vector3 n, Vector3 flow, float layer, float ridge, float voidAmount,
                        float rnd, float size, float wind, float secondary, float ao)
        {
            positions.Add(p);
            normals.Add(n);
            tangents.Add(new Vector4(flow.x, flow.y, flow.z, layer));
            colors.Add(new Color(((int)part + 0.5f) / 32f, ridge * 0.5f + 0.5f, voidAmount, rnd));
            uv0.Add(new Vector2(size, wind));
            uv1.Add(new Vector2(secondary * 0.5f + 0.5f, ao));
            partCounts[(int)part]++;
        }

        public void Scale(float s)
        {
            for (int i = 0; i < positions.Count; i++) positions[i] = positions[i] * s;
        }
    }

    /// <summary>
    /// Builds the hooded black cloak as a point cloud.
    ///
    /// Order of construction (never random scattering):
    ///   silhouette -> 3D cross sections -> cloth sheet -> major folds -> secondary folds
    ///   -> edges -> micro noise -> particle sampling on the sheet.
    ///
    /// Coordinate system: feet at Y = 0, character faces +Z, +X is the character's right.
    /// Everything is authored for a 4.2 unit tall figure and scaled to shape.height at the end.
    /// </summary>
    public sealed class VoidCloakGenerator
    {
        public const float ReferenceHeight = 4.2f;

        readonly VoidCloakShape shape;
        readonly VoidCloakDensity density;
        readonly BuildStage stage;
        readonly int seed;
        readonly ParticleBuffer buffer;
        CloakRandom rng;

        // Shared geometry
        HoodShellSurface hood;
        ShoulderCapeSurface cape;
        DrapeSurface outer;
        Profile1D widthProfile;
        Profile1D depthProfile;

        const float HoodBaseY = 3.27f;
        const float BodyCenterZ = -0.03f;

        public VoidCloakGenerator(VoidCloakShape shape, VoidCloakDensity density, BuildStage stage, int seed, ParticleBuffer buffer)
        {
            this.shape = shape;
            this.density = density;
            this.stage = stage;
            this.seed = seed;
            this.buffer = buffer;
        }

        bool AtLeast(BuildStage s)
        {
            return (int)stage >= (int)s;
        }

        public void Generate()
        {
            buffer.Clear();
            rng = new CloakRandom(seed);
            BuildProfiles();

            GenerateHood();
            if (AtLeast(BuildStage.Step02_Shoulders)) GenerateShoulders();
            if (AtLeast(BuildStage.Step03_OuterSilhouette)) GenerateOuterCloak();
            if (AtLeast(BuildStage.Step05_FrontCloak)) GenerateFrontCloak();
            if (AtLeast(BuildStage.Step06_LowerDrape)) GenerateLowerDrape();
            if (AtLeast(BuildStage.Step07_GroundCloth)) GenerateGroundCloth();

            buffer.Scale(shape.height / ReferenceHeight);
        }

        // ================================================================================
        // Silhouette profiles
        // ================================================================================

        void BuildProfiles()
        {
            // Half width (X) and half depth (Z) of the cloak as a function of height.
            // Narrow at the shoulders, widening through chest / waist / knees to the hem.
            float[] ys = { 3.15f, 2.9f, 2.4f, 1.8f, 1.2f, 0.6f, 0.3f };
            float[] ws = { 0.44f, 0.55f, 0.70f, 0.88f, 1.07f, 1.25f, 1.32f };
            float[] ds = { 0.30f, 0.35f, 0.44f, 0.55f, 0.68f, 0.82f, 0.88f };
            for (int i = 0; i < ws.Length; i++) ds[i] *= shape.cloakDepth;
            widthProfile = new Profile1D(Reverse(ys), Reverse(ws));
            depthProfile = new Profile1D(Reverse(ys), Reverse(ds));
        }

        static float[] Reverse(float[] a)
        {
            float[] r = new float[a.Length];
            for (int i = 0; i < a.Length; i++) r[i] = a[a.Length - 1 - i];
            return r;
        }

        // ================================================================================
        // STEP 1 : HOOD
        // ================================================================================

        void GenerateHood()
        {
            hood = new HoodShellSurface(shape, HoodBaseY, BodyCenterZ, rng);
            GenerateHoodCrown();
            GenerateHoodShells();
            GenerateHoodOpening();
            GenerateHoodInnerVoid();
        }

        const float CrownStart = 0.7f;

        void GenerateHoodCrown()
        {
            Sample(hood, density.Scaled(density.hoodCrown), 0f, 1f, CrownStart, 1f,
                   (u, v, s) => CloakPart.HoodCrown, null, 1f, 96, 32);
        }

        void GenerateHoodShells()
        {
            // u in (0, 0.5) is the +X (right) side, (0.5, 1) the left side.
            int half = density.Scaled(density.hoodShells) / 2;
            Sample(hood, half, 0f, 0.5f, 0f, CrownStart, (u, v, s) => CloakPart.HoodRightShell, null, 1f, 64, 64);
            Sample(hood, half, 0.5f, 1f, 0f, CrownStart, (u, v, s) => CloakPart.HoodLeftShell, null, 1f, 64, 64);
        }

        void GenerateHoodOpening()
        {
            var rim = new HoodRimSurface(hood, 0.045f);
            Sample(rim, density.Scaled(density.hoodRim), 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.HoodOpeningRim, null, 1f, 256, 16);
        }

        void GenerateHoodInnerVoid()
        {
            var cup = new HoodVoidSurface(hood);
            Sample(cup, density.Scaled(density.hoodInnerVoid), 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.HoodInnerVoid, null, 1f, 32, 32);
        }

        // ================================================================================
        // STEP 2 : SHOULDERS
        // ================================================================================

        void GenerateShoulders()
        {
            cape = new ShoulderCapeSurface(shape, HoodBaseY + 0.05f, BodyCenterZ, rng);
            int count = density.Scaled(density.shoulders);
            // denser towards the edge, where the cape defines the silhouette
            Func<SurfaceSample, float> w = s => 1f + 1.5f * s.edge;
            Sample(cape, count / 2, 0f, 0.5f, 0f, 1f, (u, v, s) => CloakPart.RightShoulder, w, 1f, 64, 40);
            Sample(cape, count - count / 2, 0.5f, 1f, 0f, 1f, (u, v, s) => CloakPart.LeftShoulder, w, 1f, 64, 40);
        }

        // ================================================================================
        // STEP 3/4/8 : OUTER CLOAK + MAJOR / SECONDARY FOLDS
        // ================================================================================

        DrapeSurface CreateOuterDrape()
        {
            var d = new DrapeSurface(widthProfile, depthProfile);
            d.thetaStartTop = shape.frontGap.x;
            d.thetaStartBottom = shape.frontGap.y;
            d.thetaEndTop = CloakMath.Tau - shape.frontGap.x;
            d.thetaEndBottom = CloakMath.Tau - shape.frontGap.y;
            d.yTop = 3.06f;
            d.yBend = shape.hemBendHeight;
            d.widthTop = shape.cloakWidth;
            d.widthBottom = shape.hemWidth;
            d.thickness = shape.clothThickness;
            d.edgeRoll = 0.02f;

            bool folds = AtLeast(BuildStage.Step04_MajorFolds);
            d.majorDepth = folds ? shape.foldAmplitude : 0f;

            // Major folds: separate fold sets per side so the left and right are not mirrored.
            // Systematic drift pushes front folds towards the sides (they flow outward going down).
            d.major = new FoldField(shape.foldCount, false, shape.foldIrregularity, shape.foldDrift, shape.foldDrift * 1.6f,
                                    0.3f, rng, u => 0.012f * Mathf.Sin(4f * Mathf.PI * u));

            bool secondary = AtLeast(BuildStage.Step08_SecondaryFolds) && shape.secondaryFoldCount > 0;
            d.secondaryDepth = secondary ? shape.secondaryAmplitude : 0f;
            d.secondary = new FoldField(Mathf.Max(2, shape.secondaryFoldCount), false, 0.9f, shape.foldDrift * 0.6f,
                                        shape.foldDrift, 0.5f, rng);

            d.noiseAmount = AtLeast(BuildStage.Step09_MicroNoise) ? shape.microNoise : 0f;
            d.noiseSeed = seed + 17;

            d.groundSpread = shape.groundSpread;
            d.groundTrain = shape.groundTrain;
            d.wrinkleHeight = shape.groundWrinkleHeight;
            d.bundleStrength = shape.groundBundleStrength;

            // Ground cloth bundles: Inner / Middle / Outer on each side, deliberately uneven.
            float[] baseAngles = { 0.85f, 1.5f, 2.3f };
            float[] baseWidths = { 0.28f, 0.34f, 0.45f };
            float[] baseAmps = { 0.9f, 0.6f, 0.75f };
            d.bundleAngles = new float[6];
            d.bundleWidths = new float[6];
            d.bundleAmps = new float[6];
            for (int i = 0; i < 3; i++)
            {
                d.bundleAngles[i] = baseAngles[i] + rng.Range(-0.12f, 0.12f);
                d.bundleWidths[i] = baseWidths[i] * rng.Range(0.85f, 1.2f);
                d.bundleAmps[i] = baseAmps[i] * rng.Range(0.8f, 1.2f);
                d.bundleAngles[i + 3] = CloakMath.Tau - (baseAngles[i] + rng.Range(-0.12f, 0.12f));
                d.bundleWidths[i + 3] = baseWidths[i] * rng.Range(0.85f, 1.2f);
                d.bundleAmps[i + 3] = baseAmps[i] * rng.Range(0.8f, 1.2f);
            }
            return d;
        }

        void GenerateOuterCloak()
        {
            outer = CreateOuterDrape();
            float vEnd = DrapeSurface.VerticalEnd;

            // Base sheet (left / right surfaces)
            Sample(outer, density.Scaled(density.outerSurface), 0f, 1f, 0f, vEnd,
                   (u, v, s) => outer.IsRight(u, v) ? CloakPart.OuterRightSurface : CloakPart.OuterLeftSurface,
                   s => 1f + 0.5f * Mathf.Abs(s.major), 1f, 160, 96);

            if (AtLeast(BuildStage.Step04_MajorFolds)) GenerateMajorFolds();
            if (AtLeast(BuildStage.Step08_SecondaryFolds)) GenerateSecondaryFolds();

            // Thin front edges of the outer cloak (silhouette of the opening)
            int edges = density.Scaled(density.frontEdges);
            Sample(outer, edges / 2, 0f, 0.012f, 0f, vEnd, (u, v, s) => CloakPart.HemEdge, null, 0.8f, 4, 128);
            Sample(outer, edges - edges / 2, 0.988f, 1f, 0f, vEnd, (u, v, s) => CloakPart.HemEdge, null, 0.8f, 4, 128);
        }

        float LowerLimit()
        {
            if (AtLeast(BuildStage.Step07_GroundCloth)) return 1f;
            if (AtLeast(BuildStage.Step06_LowerDrape)) return DrapeSurface.BendEnd;
            return DrapeSurface.VerticalEnd;
        }

        void GenerateMajorFolds()
        {
            // Extra particles concentrated along fold crests and valley bottoms,
            // so the ridges read as cloth mass and not as noise.
            float vEnd = Mathf.Min(LowerLimit(), DrapeSurface.BendEnd);
            Sample(outer, density.Scaled(density.majorFolds), 0f, 1f, 0.02f, vEnd,
                   (u, v, s) => outer.IsRight(u, v) ? CloakPart.OuterRightMajorFolds : CloakPart.OuterLeftMajorFolds,
                   s => Mathf.Pow(Mathf.Abs(s.major), 4f), 1f, 320, 96);
        }

        void GenerateSecondaryFolds()
        {
            float vEnd = Mathf.Min(LowerLimit(), DrapeSurface.BendEnd);
            Sample(outer, density.Scaled(density.secondaryFolds), 0f, 1f, 0.06f, vEnd,
                   (u, v, s) => CloakPart.SecondaryFolds,
                   s => Mathf.Pow(Mathf.Abs(s.secondary), 3f), 0.9f, 480, 96);
        }

        // ================================================================================
        // STEP 5 : FRONT CLOAK (centre panels + inner front layer)
        // ================================================================================

        void GenerateFrontCloak()
        {
            int panels = density.Scaled(density.centerPanels);

            // Inner front layer that is visible between and below the panels.
            var inner = new DrapeSurface(widthProfile, depthProfile);
            inner.thetaStartTop = -0.62f;
            inner.thetaStartBottom = -0.75f;
            inner.thetaEndTop = 0.62f;
            inner.thetaEndBottom = 0.75f;
            inner.yTop = 2.8f;
            inner.yBend = shape.hemBendHeight * 0.85f;
            inner.radiusOffset = -0.035f;
            inner.widthTop = shape.cloakWidth;
            inner.widthBottom = shape.hemWidth;
            inner.thickness = shape.clothThickness;
            inner.majorDepth = AtLeast(BuildStage.Step04_MajorFolds) ? shape.foldAmplitude * 0.8f : 0f;
            inner.major = new FoldField(9, false, 0.8f, 0.02f, 0.03f, 0.3f, rng);
            inner.baseAo = 0.6f;
            inner.groundSpread = shape.groundSpread * 0.35f;
            inner.groundTrain = 0f;
            inner.wrinkleHeight = shape.groundWrinkleHeight * 0.7f;
            inner.noiseAmount = AtLeast(BuildStage.Step09_MicroNoise) ? shape.microNoise : 0f;
            inner.noiseSeed = seed + 31;
            Sample(inner, density.Scaled(density.frontFold), 0f, 1f, 0f, LowerLimit(),
                   (u, v, s) => CloakPart.FrontFold, s => 1f + 0.5f * Mathf.Abs(s.major), 1f, 64, 96);

            // Centre panels: two long overlapping cloths in front of the outer cloak.
            // Their lower hems are slanted and different from each other.
            DrapeSurface right = CreatePanel(-0.07f, 0.4f, shape.frontPanelOffset + 0.012f,
                                             u => 0.26f + 0.42f * Mathf.Pow(1f - u, 1.2f) + 0.05f * Mathf.Sin(u * 9f));
            DrapeSurface left = CreatePanel(-0.4f, 0.07f, shape.frontPanelOffset,
                                            u => 0.2f + 0.5f * Mathf.Pow(u, 1.1f) + 0.04f * Mathf.Sin(u * 7f + 1f));

            Func<SurfaceSample, float> w = s => 1f + 0.6f * Mathf.Abs(s.major) + 1.2f * s.edge;
            Sample(right, panels / 2, 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.CenterRight, w, 1f, 48, 128);
            Sample(left, panels - panels / 2, 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.CenterLeft, w, 1f, 48, 128);
        }

        DrapeSurface CreatePanel(float thetaA, float thetaB, float offset, Func<float, float> hem)
        {
            var p = new DrapeSurface(widthProfile, depthProfile);
            p.groundMode = false;
            p.hemY = hem;
            p.thetaStartTop = thetaA * 0.85f;
            p.thetaEndTop = thetaB * 0.85f;
            p.thetaStartBottom = thetaA;
            p.thetaEndBottom = thetaB;
            p.yTop = 3.0f;
            p.radiusOffset = offset;
            p.widthTop = shape.cloakWidth;
            p.widthBottom = shape.hemWidth;
            p.thickness = shape.clothThickness;
            p.majorDepth = AtLeast(BuildStage.Step04_MajorFolds) ? shape.frontPanelFoldDepth : 0f;
            p.major = new FoldField(shape.frontPanelFolds, false, 0.6f, 0.03f, 0.02f, 0.2f, rng);
            p.secondaryDepth = AtLeast(BuildStage.Step08_SecondaryFolds) ? shape.secondaryAmplitude * 0.8f : 0f;
            p.secondary = new FoldField(shape.frontPanelFolds * 2 + 1, false, 0.9f, 0.02f, 0.02f, 0.5f, rng);
            p.noiseAmount = AtLeast(BuildStage.Step09_MicroNoise) ? shape.microNoise : 0f;
            p.noiseSeed = seed + 47;
            return p;
        }

        // ================================================================================
        // STEP 6 : LOWER DRAPE (vertical -> diagonal -> ground flow)
        // ================================================================================

        void GenerateLowerDrape()
        {
            if (outer == null) return;
            Sample(outer, density.Scaled(density.lowerDrape), 0f, 1f, DrapeSurface.VerticalEnd, DrapeSurface.BendEnd,
                   (u, v, s) => outer.IsRight(u, v) ? CloakPart.LowerRightTransition : CloakPart.LowerLeftTransition,
                   s => 1f + 0.8f * Mathf.Abs(s.major), 1f, 320, 24);
        }

        // ================================================================================
        // STEP 7 : GROUND CLOTH (+ ground wrinkles, hem edge)
        // ================================================================================

        CloakPart GroundPart(float u, float v)
        {
            float theta = outer.ThetaFor(u, v);
            bool right = Mathf.Sin(theta) >= 0f;
            float fromFront = Mathf.Abs(CloakMath.WrapAngle(theta));
            if (fromFront < 1.15f) return right ? CloakPart.GroundRightInner : CloakPart.GroundLeftInner;
            if (fromFront < 1.95f) return right ? CloakPart.GroundRightMiddle : CloakPart.GroundLeftMiddle;
            return right ? CloakPart.GroundRightOuter : CloakPart.GroundLeftOuter;
        }

        void GenerateGroundCloth()
        {
            if (outer == null) return;
            Sample(outer, density.Scaled(density.groundCloth), 0f, 1f, DrapeSurface.BendEnd, 1f,
                   (u, v, s) => GroundPart(u, v), s => 1f + 0.5f * s.wrinkle, 1f, 320, 32);
            GenerateGroundWrinkles();

            // Hem edge: thin, slightly denser rim that defines the outline on the floor.
            Sample(outer, density.Scaled(density.hemEdge), 0f, 1f, 0.985f, 1f,
                   (u, v, s) => CloakPart.HemEdge, null, 0.75f, 512, 2);
        }

        void GenerateGroundWrinkles()
        {
            Sample(outer, density.Scaled(density.groundWrinkles), 0f, 1f, DrapeSurface.BendEnd, 1f,
                   (u, v, s) => CloakPart.GroundWrinkles, s => Mathf.Pow(s.wrinkle, 3f), 0.9f, 320, 48);
        }

        // ================================================================================
        // Surface sampling
        // ================================================================================

        static readonly float[] LayerWeights = { 0.38f, 0.30f, 0.20f, 0.12f }; // Front, Front-Middle, Back-Middle, Back

        /// <summary>
        /// Distribute <paramref name="count"/> particles over a parametric cloth sheet,
        /// proportional to true surface area times an optional density weight.
        /// Uses a stratified walk through the area CDF so coverage is even (no clumps / holes),
        /// then offsets each particle into one of four thin layers along the normal.
        /// </summary>
        void Sample(ClothSurface surf, int count, float u0, float u1, float v0, float v1,
                    Func<float, float, SurfaceSample, CloakPart> classify,
                    Func<SurfaceSample, float> weight, float sizeScale, int gridU, int gridV)
        {
            if (count <= 0 || u1 <= u0 || v1 <= v0) return;

            var s = new SurfaceSample();
            int cu = gridU, cv = gridV;
            var corners = new Vector3[(cu + 1) * (cv + 1)];
            for (int j = 0; j <= cv; j++)
            {
                for (int i = 0; i <= cu; i++)
                {
                    s.Reset();
                    surf.Evaluate(CloakMath.Lerp(u0, u1, (float)i / cu), CloakMath.Lerp(v0, v1, (float)j / cv), ref s);
                    corners[j * (cu + 1) + i] = s.position;
                }
            }

            var cdf = new float[cu * cv];
            float total = 0f;
            for (int j = 0; j < cv; j++)
            {
                for (int i = 0; i < cu; i++)
                {
                    Vector3 p00 = corners[j * (cu + 1) + i];
                    Vector3 p10 = corners[j * (cu + 1) + i + 1];
                    Vector3 p01 = corners[(j + 1) * (cu + 1) + i];
                    Vector3 p11 = corners[(j + 1) * (cu + 1) + i + 1];
                    float area = 0.5f * (Vector3.Cross(p10 - p00, p01 - p00).magnitude + Vector3.Cross(p10 - p11, p01 - p11).magnitude);

                    float w = 1f;
                    float uc = CloakMath.Lerp(u0, u1, (i + 0.5f) / cu);
                    float vc = CloakMath.Lerp(v0, v1, (j + 0.5f) / cv);
                    s.Reset();
                    surf.Evaluate(uc, vc, ref s);
                    if (weight != null) w = Mathf.Max(0f, weight(s));
                    total += area * w;
                    cdf[j * cu + i] = total;
                }
            }
            if (total <= 0f) return;

            float du = (u1 - u0) / cu, dv = (v1 - v0) / cv;
            float eps = 1e-3f;
            var sx = new SurfaceSample();
            var sy = new SurfaceSample();

            for (int k = 0; k < count; k++)
            {
                float x = (k + rng.Value) / count * total;
                int lo = 0, hi = cdf.Length - 1;
                while (lo < hi)
                {
                    int mid = (lo + hi) >> 1;
                    if (cdf[mid] < x) lo = mid + 1; else hi = mid;
                }
                int ci = lo % cu, cj = lo / cu;
                float u = u0 + (ci + rng.Value) * du;
                float v = v0 + (cj + rng.Value) * dv;

                s.Reset();
                surf.Evaluate(u, v, ref s);
                if (!surf.Contains(u, v, ref s)) continue;

                // Tangent frame by finite differences on the final (folded) surface,
                // so fold crests get correct normals for the highlights.
                float ue = u + eps <= u1 + 1e-6f ? eps : -eps;
                float ve = v + eps <= v1 + 1e-6f ? eps : -eps;
                sx.Reset();
                surf.Evaluate(u + ue, v, ref sx);
                sy.Reset();
                surf.Evaluate(u, v + ve, ref sy);
                Vector3 pu = (sx.position - s.position) / ue;
                Vector3 pv = (sy.position - s.position) / ve;

                Vector3 n;
                if (s.hasNormal)
                {
                    n = s.normal;
                }
                else
                {
                    n = Vector3.Cross(pu, pv);
                    if (surf.flipNormal) n = -n;
                    if (n.sqrMagnitude < 1e-12f) n = Vector3.up;
                }
                n.Normalize();

                Vector3 flow = (surf.flowAlongU ? pu : pv) * surf.flowSign;
                flow -= Vector3.Dot(flow, n) * n;
                if (flow.sqrMagnitude < 1e-12f) flow = Vector3.down;
                flow.Normalize();

                // Thin multi-layer thickness: Front / Front-Middle / Back-Middle / Back.
                float r = rng.Value;
                int layer = 0;
                float acc = LayerWeights[0];
                while (layer < 3 && r > acc) { layer++; acc += LayerWeights[layer]; }
                float layerPos = 0.5f - (layer + rng.Value) / 4f; // +0.5 front .. -0.5 back
                Vector3 p = s.position + n * (layerPos * surf.thickness);

                CloakPart part = classify(u, v, s);
                buffer.Add(part, p, n, flow, layerPos * 2f, s.major, s.voidAmount, rng.Value,
                           s.sizeScale * sizeScale * (1f - 0.15f * s.edge), s.wind, s.secondary,
                           Mathf.Clamp01(s.ao * (layer >= 3 ? 0.92f : 1f)));
            }
        }
    }
}
