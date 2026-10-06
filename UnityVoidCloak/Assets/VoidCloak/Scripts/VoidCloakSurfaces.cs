using System;
using UnityEngine;

namespace VoidCloak
{
    /// <summary>Result of evaluating a cloth surface at (u, v).</summary>
    public struct SurfaceSample
    {
        public Vector3 position;
        /// <summary>Major fold ridge value, -1 (valley) .. +1 (crest).</summary>
        public float major;
        /// <summary>Secondary fold ridge value, -1 .. +1.</summary>
        public float secondary;
        /// <summary>0..1, how close to a free cloth edge (hem, front edge).</summary>
        public float edge;
        /// <summary>Baked cavity / occlusion, 1 = open, 0 = fully occluded.</summary>
        public float ao;
        /// <summary>How much the wind moves this point (0 = pinned).</summary>
        public float wind;
        /// <summary>0..1, how strongly the shader should turn this into the black void.</summary>
        public float voidAmount;
        /// <summary>Per surface particle size multiplier.</summary>
        public float sizeScale;
        /// <summary>When true <see cref="normal"/> is used instead of the numeric normal.</summary>
        public bool hasNormal;
        public Vector3 normal;
        /// <summary>Optional 0..1 extra density weight (used for ground wrinkle crests).</summary>
        public float wrinkle;

        public void Reset()
        {
            position = Vector3.zero;
            major = 0f;
            secondary = 0f;
            edge = 0f;
            ao = 1f;
            wind = 0f;
            voidAmount = 0f;
            sizeScale = 1f;
            hasNormal = false;
            normal = Vector3.up;
            wrinkle = 0f;
        }
    }

    /// <summary>
    /// A mathematically defined cloth sheet P(u, v). Particles are sampled on it by
    /// <see cref="VoidCloakGenerator"/>; the surface itself never uses randomness.
    /// </summary>
    public abstract class ClothSurface
    {
        /// <summary>Total thickness of the particle layers around the surface.</summary>
        public float thickness = 0.02f;
        /// <summary>Flip cross(dP/du, dP/dv) so that the normal points away from the body.</summary>
        public bool flipNormal;
        /// <summary>Flow (tangent) direction = flowSign * dP/dv (or dP/du if flowAlongU).</summary>
        public float flowSign = 1f;
        public bool flowAlongU;
        /// <summary>Flip the final normal (e.g. the inside wall of a sleeve).</summary>
        public bool invertNormal;

        public abstract void Evaluate(float u, float v, ref SurfaceSample s);

        /// <summary>Holes in the sheet (e.g. the face opening). Called with the evaluated sample.</summary>
        public virtual bool Contains(float u, float v, ref SurfaceSample s)
        {
            return true;
        }

        /// <summary>
        /// Closed solids return a point inside the solid near (u, v); the sampler then turns the
        /// normal so it points away from it, whatever the parameter orientation is.
        /// </summary>
        public virtual bool TryGetInteriorPoint(float u, float v, out Vector3 point)
        {
            point = Vector3.zero;
            return false;
        }
    }

    /// <summary>How the shader lights a particle.</summary>
    public enum ParticleMaterial
    {
        Cloth = 0,
        Steel = 1,
        Leather = 2,
    }

    // ------------------------------------------------------------------------------------
    // HOOD
    // ------------------------------------------------------------------------------------

    /// <summary>
    /// The hood is a cloth shell built from stacked horizontal ellipses.
    /// The horizontal size follows a soft mountain profile so the crown is a rounded peak,
    /// not a sphere. The face opening is a hole in the shell (no face, no plate).
    ///
    /// u: angle around the head (0 = front, 0.25 = +X / right side)
    /// v: 0 at the lower hem of the hood, 1 at the crown tip.
    /// </summary>
    public sealed class HoodShellSurface : ClothSurface
    {
        public readonly float baseY;
        public readonly float hoodH;
        public readonly float halfW;
        public readonly float halfD;
        public readonly float centerZ;
        public readonly float frontReach = 1.1f; // front edge reaches forward over the face
        readonly float crownSoftness;
        readonly float foldDepth;
        readonly FoldField folds;
        public readonly HoodOpening opening;

        public HoodShellSurface(VoidCloakShape shape, float baseY, float centerZ, CloakRandom rng)
        {
            this.baseY = baseY;
            hoodH = shape.hoodHeight;
            halfW = shape.hoodWidth * 0.5f;
            halfD = shape.hoodDepth * 0.5f;
            this.centerZ = centerZ;
            crownSoftness = shape.crownSoftness;
            foldDepth = shape.hoodFoldDepth;
            folds = new FoldField(11, true, 0.8f, 0.02f, 0f, 0.4f, rng);
            opening = new HoodOpening(shape, baseY);
            thickness = shape.clothThickness * 1.2f;
            flipNormal = false;
            flowSign = -1f;
        }

        /// <summary>Horizontal size factor of the shell at height fraction q.</summary>
        public float Shape(float q)
        {
            const float qMax = 0.38f;
            if (q <= qMax) return CloakMath.Lerp(0.93f, 1f, CloakMath.Smooth(0f, qMax, q));
            float Q = Mathf.Clamp01((q - qMax) / (1f - qMax));
            // 1/crownSoftness < 1 gives a soft point instead of a dome
            return Mathf.Pow(Mathf.Max(0f, 1f - Mathf.Pow(Q, 2.2f)), 1f / crownSoftness);
        }

        public float CenterZ(float q)
        {
            float Q = Mathf.Clamp01((q - 0.38f) / 0.62f);
            return centerZ - 0.08f * Q * Q;
        }

        public float FrontFactor(float cosT)
        {
            return cosT > 0f ? CloakMath.Lerp(1f, frontReach, cosT) : 1f;
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            float theta = CloakMath.Tau * u;
            float q = Mathf.Clamp01(v);
            float sinT = Mathf.Sin(theta), cosT = Mathf.Cos(theta);

            float k = Shape(q);
            float hw = halfW * k;
            float hd = halfD * k * FrontFactor(cosT);

            // Soft folds that start below the crown and flow down the sides / back.
            float backMask = CloakMath.Smooth(0.5f, -0.1f, cosT);
            float ridge;
            float f = folds.Evaluate(u, 1f - q, out ridge);
            float env = CloakMath.Smooth(0f, 0.55f, 1f - q) * backMask;
            float circumference = CloakMath.Tau * 0.5f * (hw + hd);
            float disp = f * circumference * foldDepth * env;

            float y = baseY + q * hoodH;
            // The back hem of the hood hangs a little lower over the shoulder cape.
            float low = 1f - q;
            y -= 0.12f * CloakMath.Smooth(0.2f, -1f, cosT) * low * low * low;

            s.position = new Vector3((hw + disp) * sinT, y, CenterZ(q) + (hd + disp) * cosT);
            s.major = ridge * env;
            s.ao = 1f - 0.3f * Mathf.Max(0f, -ridge) * env;
            s.wind = 0.02f * low;
        }

        public override bool Contains(float u, float v, ref SurfaceSample s)
        {
            Vector3 p = s.position;
            if (p.z < CenterZ(v) + 0.02f) return true; // back half is always closed
            return !opening.Inside(p.x, p.y, 0.012f);
        }

        /// <summary>Front surface z of the (fold free) shell at a given x, y.</summary>
        public float FrontZ(float x, float y, out Vector3 normal)
        {
            float q = Mathf.Clamp01((y - baseY) / hoodH);
            float k = Shape(q);
            float hw = Mathf.Max(1e-3f, halfW * k);
            float sinT = Mathf.Clamp(x / hw, -0.999f, 0.999f);
            float cosT = Mathf.Sqrt(1f - sinT * sinT);
            float hd = halfD * k * FrontFactor(cosT);
            float z = CenterZ(q) + hd * cosT;
            normal = new Vector3(sinT / hw, 0f, cosT / Mathf.Max(1e-3f, hd)).normalized;
            return z;
        }
    }

    /// <summary>
    /// Face opening outline in front view:
    ///        ______
    ///      /        \
    ///     |          |
    ///      \        /
    ///       \__  __/
    ///          \/
    /// Rounded top, near vertical sides, slightly pointed bottom.
    /// </summary>
    public sealed class HoodOpening
    {
        public readonly float top;
        public readonly float bottom;
        public readonly float halfWidth;
        readonly float yArc;
        readonly float yPoint;

        public HoodOpening(VoidCloakShape shape, float hoodBaseY)
        {
            top = hoodBaseY + shape.hoodHeight * shape.openingTop;
            bottom = hoodBaseY + shape.hoodHeight * shape.openingBottom;
            halfWidth = shape.openingWidth * 0.5f;
            float h = top - bottom;
            yArc = top - Mathf.Min(halfWidth * 1.0f, h * 0.4f);
            yPoint = bottom + Mathf.Min(halfWidth * 1.2f, h * 0.4f);
        }

        public float Center { get { return 0.5f * (top + bottom); } }

        /// <summary>Half width of the opening at height y (0 outside the vertical range).</summary>
        public float HalfWidthAt(float y)
        {
            if (y <= bottom || y >= top) return 0f;
            if (y < yPoint)
            {
                float t = (y - bottom) / (yPoint - bottom);
                return halfWidth * Mathf.Pow(t, 0.7f);
            }
            if (y > yArc)
            {
                float t = (y - yArc) / (top - yArc);
                return halfWidth * Mathf.Sqrt(Mathf.Max(0f, 1f - t * t));
            }
            // sides lean in very slightly towards the chin
            float s = (y - yPoint) / (yArc - yPoint);
            return halfWidth * CloakMath.Lerp(0.94f, 1f, s);
        }

        public bool Inside(float x, float y, float margin)
        {
            if (y <= bottom - margin || y >= top + margin) return false;
            float hw = HalfWidthAt(Mathf.Clamp(y, bottom + 1e-4f, top - 1e-4f));
            return Mathf.Abs(x) < hw + margin;
        }
    }

    /// <summary>
    /// The rolled front edge of the hood that frames the opening.
    /// u: position along the closed outline, v: angle around the rolled hem.
    /// </summary>
    public sealed class HoodRimSurface : ClothSurface
    {
        const int Resolution = 400;
        readonly Vector3[] points = new Vector3[Resolution + 1];
        readonly Vector3[] outward = new Vector3[Resolution + 1];
        readonly float[] arc = new float[Resolution + 1];
        readonly float rollOut;
        readonly float rollIn;
        readonly HoodShellSurface hood;

        public HoodRimSurface(HoodShellSurface hood, float rimThickness)
        {
            this.hood = hood;
            rollOut = rimThickness * 0.55f;
            rollIn = rimThickness;
            thickness = rimThickness * 0.25f;
            flowAlongU = true;

            HoodOpening o = hood.opening;
            int half = Resolution / 2;
            for (int i = 0; i <= Resolution; i++)
            {
                // right side bottom -> top, then left side top -> bottom; cosine spacing
                bool right = i <= half;
                float k = right ? (float)i / half : (float)(Resolution - i) / half;
                float y = CloakMath.Lerp(o.bottom, o.top, 0.5f - 0.5f * Mathf.Cos(Mathf.PI * k));
                float x = o.HalfWidthAt(Mathf.Clamp(y, o.bottom + 1e-4f, o.top - 1e-4f)) * (right ? 1f : -1f);
                Vector3 n;
                float z = hood.FrontZ(x, y, out n);
                points[i] = new Vector3(x, y, z);
                outward[i] = n;
            }
            arc[0] = 0f;
            for (int i = 1; i <= Resolution; i++) arc[i] = arc[i - 1] + Vector3.Distance(points[i], points[i - 1]);
        }

        void Locate(float u, out Vector3 p, out Vector3 tangent, out Vector3 n)
        {
            float target = (u - Mathf.Floor(u)) * arc[Resolution];
            int i = 1;
            while (i < Resolution && arc[i] < target) i++;
            float seg = Mathf.Max(1e-6f, arc[i] - arc[i - 1]);
            float t = Mathf.Clamp01((target - arc[i - 1]) / seg);
            p = Vector3.Lerp(points[i - 1], points[i], t);
            tangent = (points[i] - points[i - 1]).normalized;
            n = Vector3.Lerp(outward[i - 1], outward[i], t).normalized;
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            Vector3 p, tangent, n;
            Locate(u, out p, out tangent, out n);

            // n: away from the head; inward: into the opening, perpendicular to the outline
            n = (n - Vector3.Dot(n, tangent) * tangent).normalized;
            Vector3 toCenter = new Vector3(0f, hood.opening.Center, p.z) - p;
            Vector3 inward = toCenter - Vector3.Dot(toCenter, tangent) * tangent - Vector3.Dot(toCenter, n) * n;
            inward = inward.sqrMagnitude > 1e-8f ? inward.normalized : Vector3.Cross(tangent, n);

            float a = CloakMath.Tau * v;
            float ca = Mathf.Cos(a), sa = Mathf.Sin(a);
            // rolled hem: centre sits slightly outside the shell and leans forward
            Vector3 center = p + n * (rollOut * 0.8f) + Vector3.forward * (rollOut * 0.6f);
            Vector3 dir = n * ca + inward * sa;
            s.position = center + n * (ca * rollOut) + inward * (sa * rollIn);
            s.hasNormal = true;
            s.normal = dir.normalized;

            // the inside of the roll that faces into the hood falls into the void
            float facingIn = Mathf.Clamp01(-ca * 0.8f + sa * 0.6f);
            s.voidAmount = 0.55f * facingIn;
            s.ao = 1f - 0.5f * facingIn;
            s.edge = 1f;
            s.sizeScale = 0.85f;
            s.wind = 0.01f;
        }
    }

    /// <summary>
    /// The black void inside the hood: a concave cup behind the opening.
    /// Rendered almost black by the shader so the opening reads as empty depth.
    /// </summary>
    public sealed class HoodVoidSurface : ClothSurface
    {
        readonly Vector3 center;
        readonly Vector3 radii;

        public HoodVoidSurface(HoodShellSurface hood)
        {
            HoodOpening o = hood.opening;
            float midY = o.Center;
            float q = (midY - hood.baseY) / hood.hoodH;
            center = new Vector3(0f, midY - 0.02f, hood.CenterZ(q) + hood.halfD * 0.25f);
            radii = new Vector3(o.halfWidth * 1.15f, (o.top - o.bottom) * 0.55f, hood.halfD * 0.7f);
            thickness = 0.04f;
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            float phi = (u - 0.5f) * Mathf.PI * 0.95f;
            float beta = (v - 0.5f) * Mathf.PI * 0.95f;
            Vector3 dir = new Vector3(Mathf.Sin(phi) * Mathf.Cos(beta), Mathf.Sin(beta), -Mathf.Cos(phi) * Mathf.Cos(beta));
            s.position = center + Vector3.Scale(dir, radii);
            s.hasNormal = true;
            s.normal = -dir; // faces the opening (concave cup)
            s.voidAmount = 1f;
            s.ao = 0f;
            s.sizeScale = 1.6f;
            s.wind = 0f;
        }
    }

    // ------------------------------------------------------------------------------------
    // SHOULDERS
    // ------------------------------------------------------------------------------------

    /// <summary>
    /// Shoulder cape: starts under the hood hem and spreads sideways before the cloak falls.
    ///          HOOD
    ///      ______|______
    ///    /               \
    /// u: angle around the body, v: 0 at the neck, 1 at the cape edge.
    /// </summary>
    public sealed class ShoulderCapeSurface : ClothSurface
    {
        public readonly float neckY;
        public readonly float neckRx = 0.25f;
        public readonly float neckRz = 0.27f;
        public readonly float edgeRx;
        public readonly float edgeRz;
        public readonly float drop;
        public readonly float centerZ;
        readonly float foldDepth;
        readonly FoldField folds;

        public ShoulderCapeSurface(VoidCloakShape shape, float neckY, float centerZ, CloakRandom rng)
        {
            this.neckY = neckY;
            this.centerZ = centerZ;
            edgeRx = shape.shoulderWidth;
            edgeRz = 0.42f * shape.cloakDepth;
            drop = shape.shoulderDrop;
            foldDepth = shape.shoulderFoldDepth;
            folds = new FoldField(18, true, 0.7f, 0.015f, 0f, 0.35f, rng);
            thickness = shape.shoulderThickness;
            flipNormal = true;
        }

        public float Drop(float v)
        {
            // flat over the top of the shoulder, then rolling down at the edge
            return drop * (0.18f * v + 0.82f * Mathf.Pow(v, 2.2f));
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            float theta = CloakMath.Tau * u;
            float sinT = Mathf.Sin(theta), cosT = Mathf.Cos(theta);
            float rx = CloakMath.Lerp(neckRx, edgeRx, v);
            float rz = CloakMath.Lerp(neckRz, edgeRz, v);

            float y = neckY - Drop(v);
            y -= 0.07f * v * CloakMath.Smooth(0.5f, 1f, cosT);   // soft V at the front
            y -= 0.05f * v * CloakMath.Smooth(0f, -1f, cosT);    // a little longer at the back

            float ridge;
            float f = folds.Evaluate(u, v, out ridge);
            float env = CloakMath.Smooth(0.25f, 1f, v);
            float disp = f * CloakMath.Tau * 0.5f * (rx + rz) * foldDepth * env;

            Vector3 nh = new Vector3(sinT / rx, 0f, cosT / rz).normalized;
            Vector3 dispDir = (nh * 0.75f + Vector3.up * 0.35f).normalized;

            s.position = new Vector3(rx * sinT, y, centerZ + rz * cosT) + dispDir * disp;
            s.major = ridge * env;
            s.ao = (1f - 0.35f * Mathf.Max(0f, -ridge) * env) * CloakMath.Lerp(0.75f, 1f, CloakMath.Smooth(0f, 0.3f, v));
            s.edge = CloakMath.Smooth(0.9f, 1f, v);
            s.wind = 0.08f * v;
        }
    }

    // ------------------------------------------------------------------------------------
    // DRAPE (outer cloak, front panels, inner front layer)
    // ------------------------------------------------------------------------------------

    /// <summary>
    /// A cloth sheet that hangs from the shoulders, flares out, bends at the floor and lies
    /// on the ground. One continuous surface so the vertical folds flow into the diagonal
    /// lower drape and then into radial ground folds:
    ///
    ///     |          vertical part   (fold displacement along the horizontal normal)
    ///     |
    ///      \         lower drape     (normal rotates from horizontal to up)
    ///       \____    ground cloth    (folds lie flat, transverse wrinkles)
    ///
    /// u maps to an angle range around the body, v runs from the top edge to the hem.
    /// Panels that do not reach the floor use a cut hem instead (hemY(u)).
    /// </summary>
    public sealed class DrapeSurface : ClothSurface
    {
        // --- configuration ----------------------------------------------------------
        public float thetaStartTop, thetaStartBottom, thetaEndTop, thetaEndBottom;
        public float yTop;
        public float yBend;
        public float groundY = 0.012f;
        public float radiusOffset;
        public float widthTop = 1f, widthBottom = 1f, depthScale = 1f;
        public float frontDepthFactor = 0.82f;
        public float majorDepth, secondaryDepth;
        public float edgeRoll;
        public float baseAo = 1f;
        public float noiseAmount;
        public int noiseSeed;

        // ground
        public bool groundMode = true;
        public float groundSpread, groundTrain, wrinkleHeight, bundleStrength;
        public float[] bundleAngles, bundleWidths, bundleAmps;

        // cut hem (panels)
        public Func<float, float> hemY;

        public FoldField major;
        public FoldField secondary;

        public readonly Profile1D widthProfile;
        public readonly Profile1D depthProfile;

        // --- v layout ---------------------------------------------------------------
        public const float VerticalEnd = 0.74f;
        public const float BendEnd = 0.84f;

        public DrapeSurface(Profile1D widthProfile, Profile1D depthProfile)
        {
            this.widthProfile = widthProfile;
            this.depthProfile = depthProfile;
            flipNormal = true;
        }

        public float VerticalFraction { get { return groundMode ? VerticalEnd : 1f; } }

        public float ThetaAt(float u, float t)
        {
            float a = CloakMath.Lerp(thetaStartTop, thetaStartBottom, t);
            float b = CloakMath.Lerp(thetaEndTop, thetaEndBottom, t);
            return CloakMath.Lerp(a, b, u);
        }

        void Ring(float y, float t, float theta, out Vector3 p, out Vector3 nh, out float a, out float b)
        {
            float sinT = Mathf.Sin(theta), cosT = Mathf.Cos(theta);
            a = widthProfile.Evaluate(y) * CloakMath.Lerp(widthTop, widthBottom, t) + radiusOffset;
            b = depthProfile.Evaluate(y) * depthScale + radiusOffset;
            float bz = cosT > 0f ? b * frontDepthFactor : b;
            float zc = -0.04f - 0.07f * t;
            p = new Vector3(a * sinT, y, zc + bz * cosT);
            nh = new Vector3(sinT / a, 0f, cosT / bz).normalized;
        }

        float GroundLength(float theta)
        {
            float back = 0.5f - 0.5f * Mathf.Cos(theta); // 0 front, 1 back
            float len = groundSpread * (0.4f + 0.6f * back) + groundTrain * CloakMath.Smooth(0.5f, 1f, back);
            float bundles = 0f;
            if (bundleAngles != null)
            {
                for (int i = 0; i < bundleAngles.Length; i++)
                {
                    float d = CloakMath.WrapAngle(theta - bundleAngles[i]) / bundleWidths[i];
                    bundles += bundleAmps[i] * CloakMath.Gauss(d);
                }
            }
            return len * (1f + bundleStrength * bundles);
        }

        float BundleHeight(float theta)
        {
            if (bundleAngles == null) return 0f;
            float h = 0f;
            for (int i = 0; i < bundleAngles.Length; i++)
            {
                float d = CloakMath.WrapAngle(theta - bundleAngles[i]) / bundleWidths[i];
                h += bundleAmps[i] * CloakMath.Gauss(d * 1.3f);
            }
            return h * bundleStrength;
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            float vf = VerticalFraction;
            float tv = Mathf.Clamp01(v / vf);              // progress along the vertical part
            float theta = ThetaAt(u, tv);

            // ---- base sheet --------------------------------------------------------
            Vector3 p, nh, normal;
            float a, b;
            float bendW = 0f;       // 0 vertical .. 1 lying on the ground
            float g = 0f;           // progress across the ground part
            float radiusForArc;

            if (!groundMode || v <= vf)
            {
                float yEnd = groundMode ? yBend : hemY(u);
                float y = CloakMath.Lerp(yTop, yEnd, tv);
                Ring(y, tv, theta, out p, out nh, out a, out b);
                normal = nh;
                radiusForArc = 0.5f * (a + b);
            }
            else
            {
                Vector3 pb;
                Ring(yBend, 1f, theta, out pb, out nh, out a, out b);
                float rb = yBend - groundY;
                if (v <= BendEnd)
                {
                    float phi = (v - vf) / (BendEnd - vf) * Mathf.PI * 0.5f;
                    p = pb + nh * (rb * (1f - Mathf.Cos(phi))) - Vector3.up * (rb * Mathf.Sin(phi));
                    normal = nh * Mathf.Cos(phi) + Vector3.up * Mathf.Sin(phi);
                    bendW = phi / (Mathf.PI * 0.5f);
                    radiusForArc = 0.5f * (a + b) + rb * (1f - Mathf.Cos(phi));
                }
                else
                {
                    g = (v - BendEnd) / (1f - BendEnd);
                    float len = GroundLength(theta);
                    p = pb + nh * (rb + g * len);
                    p.y = groundY;
                    normal = Vector3.up;
                    bendW = 1f;
                    radiusForArc = 0.5f * (a + b) + rb + g * len;
                }
            }

            // ---- folds ---------------------------------------------------------------
            float arcPerU = Mathf.Abs(ThetaAt(1f, tv) - ThetaAt(0f, tv)) * radiusForArc;
            float ridgeM = 0f, ridgeS = 0f;
            float dispM = 0f, dispS = 0f, maxM = 0f;
            float env = CloakMath.Smooth(0f, 0.1f, v) * (0.3f + 0.7f * CloakMath.Smooth(0f, 0.8f, v));

            if (major != null && majorDepth > 0f)
            {
                float fm = major.Evaluate(u, v, out ridgeM);
                dispM = fm * arcPerU * majorDepth * env;
                maxM = arcPerU * majorDepth * env / major.Count;
            }
            if (secondary != null && secondaryDepth > 0f)
            {
                float fs = secondary.Evaluate(u, v, out ridgeS);
                // secondary folds live mostly between the major crests
                float between = 0.45f + 0.55f * (1f - Mathf.Max(0f, ridgeM));
                float env2 = CloakMath.Smooth(0.06f, 0.35f, v) * between;
                dispS = fs * arcPerU * secondaryDepth * env2;
                ridgeS *= env2;
            }

            float dVertical = dispM + dispS;
            // on the floor the folds can only rise up from the ground
            float dGround = Mathf.Max(0f, 0.45f * maxM + 0.65f * dVertical);
            float d = CloakMath.Lerp(dVertical, dGround, bendW * bendW);

            // front edge of the outer cloak turns slightly outward (lapel-like edge)
            float edgeU = Mathf.Min(u, 1f - u);
            float frontEdge = edgeRoll > 0f ? CloakMath.Smooth(0.03f, 0f, edgeU) : 0f;
            d += edgeRoll * frontEdge;

            p += normal * d;

            // ---- ground wrinkles and bundles ------------------------------------------
            float wr = 0f;
            if (groundMode && bendW > 0f)
            {
                float k = 7f + 3f * Mathf.Sin(theta * 3.1f + 0.7f);
                float phase = g * k + theta * 2.3f + 0.6f * Mathf.Sin(theta * 5.3f + g * 4f);
                float w = 0.5f + 0.5f * Mathf.Sin(CloakMath.Tau * phase);
                wr = Mathf.Pow(w, 1.6f) * CloakMath.Smooth(0f, 0.15f, g) * (1f - 0.55f * g) * bendW;
                float bundle = BundleHeight(theta) * (1f - 0.6f * g) * bendW;
                p.y += wrinkleHeight * wr + 0.05f * bundle * Mathf.Sqrt(Mathf.Max(0f, 1f - g));
                s.wrinkle = wr;
            }

            // ---- micro noise (step 9, very small) --------------------------------------
            if (noiseAmount > 0f)
            {
                p += normal * (noiseAmount * CloakMath.Noise3(p * 9f, noiseSeed));
            }

            // ---- attributes -----------------------------------------------------------
            s.position = p;
            s.major = ridgeM;
            s.secondary = ridgeS;
            float hemEdge = groundMode ? CloakMath.Smooth(0.96f, 1f, v) : CloakMath.Smooth(0.95f, 1f, v);
            s.edge = Mathf.Max(hemEdge, frontEdge);

            float ao = baseAo;
            ao *= 1f - 0.5f * Mathf.Max(0f, -ridgeM);
            ao *= 1f - 0.25f * Mathf.Max(0f, -ridgeS);
            ao *= CloakMath.Lerp(0.5f, 1f, CloakMath.Smooth(0f, 0.09f, v));                // under the shoulder cape
            if (groundMode && bendW > 0f) ao *= CloakMath.Lerp(0.7f, 1f, CloakMath.Smooth(0f, 0.45f, g)) * (1f - 0.25f * (1f - wr) * bendW);
            s.ao = ao;

            float vertWind = Mathf.Pow(tv, 1.3f);
            s.wind = groundMode && v > vf ? CloakMath.Lerp(1f, 0.12f, g) * CloakMath.Lerp(1f, 0.6f, bendW) : vertWind;
        }

        /// <summary>Which half of the body a u coordinate belongs to (+X = right).</summary>
        public bool IsRight(float u, float v)
        {
            float theta = ThetaAt(u, Mathf.Clamp01(v / VerticalFraction));
            return Mathf.Sin(theta) >= 0f;
        }

        public float ThetaFor(float u, float v)
        {
            return ThetaAt(u, Mathf.Clamp01(v / VerticalFraction));
        }
    }
}
