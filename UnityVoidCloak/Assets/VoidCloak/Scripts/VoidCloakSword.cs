using System;
using UnityEngine;

namespace VoidCloak
{
    /// <summary>How the character holds the sword. Hands always stay hidden inside cloth sleeves.</summary>
    public enum SwordPose
    {
        /// <summary>Right hand, sword lowered beside the body, point resting on the ground in front.</summary>
        LoweredRight = 0,
        /// <summary>Sword planted point-down in front of the body, both hands on the grip.</summary>
        PlantedFront = 1,
        /// <summary>Use the custom tip position / blade direction below (right hand).</summary>
        Custom = 2,
    }

    /// <summary>Medieval longsword settings. Lengths are for the 4.2 unit reference figure.</summary>
    [Serializable]
    public class VoidCloakSword
    {
        public bool enabled = true;
        public SwordPose pose = SwordPose.LoweredRight;

        [Header("Blade")]
        [Range(0.8f, 3f)] public float bladeLength = 1.95f;
        [Tooltip("Full width of the blade at the guard.")]
        [Range(0.04f, 0.3f)] public float bladeWidth = 0.12f;
        [Tooltip("Full thickness of the blade at the guard.")]
        [Range(0.005f, 0.08f)] public float bladeThickness = 0.024f;
        [Tooltip("Length of the central groove as a fraction of the blade.")]
        [Range(0f, 0.9f)] public float fullerLength = 0.62f;

        [Header("Hilt")]
        [Range(0.2f, 1.2f)] public float guardWidth = 0.52f;
        [Range(0.2f, 0.9f)] public float gripLength = 0.5f;
        [Range(0.02f, 0.08f)] public float gripRadius = 0.034f;
        [Range(0.03f, 0.15f)] public float pommelRadius = 0.072f;

        [Header("Sleeves (hide the hands)")]
        public bool sleeves = true;
        [Range(0.08f, 0.35f)] public float sleeveWidth = 0.17f;
        [Range(0f, 0.3f)] public float sleeveBell = 0.08f;

        [Header("Custom Pose (object space, reference scale)")]
        public Vector3 customTip = new Vector3(0.95f, 0.03f, 1.3f);
        public Vector3 customBladeDirection = new Vector3(0.25f, -1f, 0.45f);

        [Header("Particles")]
        public int blade = 7000;
        public int bladeEdges = 2500;
        public int guard = 1800;
        public int grip = 1500;
        public int pommel = 1200;
        public int sleevePerArm = 5000;
        public int sleeveInside = 1200;
    }

    /// <summary>
    /// Local frame of the sword: origin at the centre of the cross guard,
    /// axis = towards the tip, edge = across the blade width, face = blade flat normal.
    /// </summary>
    public struct SwordFrame
    {
        public Vector3 origin;
        public Vector3 axis;
        public Vector3 edge;
        public Vector3 face;

        public Vector3 Point(float a, float e, float f)
        {
            return origin + axis * a + edge * e + face * f;
        }

        public static SwordFrame FromTip(Vector3 tip, Vector3 direction, float bladeLength, Vector3 faceHint)
        {
            var fr = new SwordFrame();
            fr.axis = direction.normalized;
            fr.origin = tip - fr.axis * bladeLength;
            Vector3 f = faceHint - fr.axis * Vector3.Dot(faceHint, fr.axis);
            if (f.sqrMagnitude < 1e-6f) f = Vector3.Cross(fr.axis, Vector3.right);
            fr.face = f.normalized;
            fr.edge = Vector3.Cross(fr.face, fr.axis).normalized;
            return fr;
        }
    }

    static class SwordMath
    {
        /// <summary>sign(x) * |x|^p (superquadric helper)</summary>
        public static float SPow(float x, float p)
        {
            return Mathf.Sign(x) * Mathf.Pow(Mathf.Abs(x), p);
        }
    }

    /// <summary>
    /// Blade: diamond / lenticular cross section with distal taper, a central fuller (groove)
    /// in the upper part and a pointed tip.
    /// u: guard (0) -> tip (1), v: around the cross section.
    /// </summary>
    public sealed class SwordBladeSurface : ClothSurface
    {
        readonly SwordFrame frame;
        readonly float length, halfWidth, halfThickness, fullerLength;

        public SwordBladeSurface(SwordFrame frame, VoidCloakSword s)
        {
            this.frame = frame;
            length = s.bladeLength;
            halfWidth = s.bladeWidth * 0.5f;
            halfThickness = s.bladeThickness * 0.5f;
            fullerLength = s.fullerLength;
            thickness = 0f;
            flowAlongU = true;
        }

        public float WidthAt(float u)
        {
            const float tip = 0.13f;
            float w = halfWidth * (1f - 0.35f * u);
            if (u > 1f - tip) w *= Mathf.Pow(Mathf.Max(0f, (1f - u) / tip), 0.8f);
            return w;
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            float w = WidthAt(u);
            float t = halfThickness * (1f - 0.55f * u) * Mathf.Min(1f, w / Mathf.Max(1e-4f, halfWidth * 0.4f) + 0.25f);
            float phi = CloakMath.Tau * v;
            float c = Mathf.Cos(phi), sn = Mathf.Sin(phi);

            float x = w * c;
            float z = t * Mathf.Pow(1f - Mathf.Abs(c), 0.8f);
            // fuller: shallow groove along the middle of each flat
            if (fullerLength > 0f)
            {
                float mask = CloakMath.Smooth(0.02f, 0.06f, u) * CloakMath.Smooth(fullerLength, fullerLength - 0.08f, u);
                z -= t * 0.45f * mask * CloakMath.Gauss(c / 0.22f);
            }
            z = Mathf.Max(z, t * 0.1f * (1f - Mathf.Abs(c)));
            if (sn < 0f) z = -z;

            s.position = frame.Point(u * length, x, z);
            float edge = Mathf.Pow(Mathf.Abs(c), 10f);
            s.major = edge;        // the shader brightens the bevelled edges
            s.edge = edge;
            s.ao = 1f;
            s.wind = 0f;
            s.sizeScale = 0.55f;
        }

        public override bool TryGetInteriorPoint(float u, float v, out Vector3 point)
        {
            point = frame.Point(u * length, 0f, 0f);
            return true;
        }
    }

    /// <summary>
    /// Generic tube around a centre line (cross guard, grip). u: along the line, v: around.
    /// </summary>
    public sealed class SwordTubeSurface : ClothSurface
    {
        readonly Func<float, Vector3> center;
        readonly Func<float, float, float> radius;   // (u, angle) -> radius
        readonly Vector3 sideA;
        readonly Vector3 sideB;
        readonly float stretchB;
        readonly float sizeScale;

        public SwordTubeSurface(Func<float, Vector3> center, Func<float, float, float> radius, Vector3 sideA, Vector3 sideB,
                                float stretchB, float sizeScale)
        {
            this.center = center;
            this.radius = radius;
            this.sideA = sideA;
            this.sideB = sideB;
            this.stretchB = stretchB;
            this.sizeScale = sizeScale;
            thickness = 0f;
            flowAlongU = true;
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            float a = CloakMath.Tau * v;
            float r = radius(u, a);
            // close the ends of the tube with a rounded cap
            float end = Mathf.Min(u, 1f - u);
            if (end < 0.03f) r *= Mathf.Sqrt(Mathf.Max(0f, 1f - Mathf.Pow((0.03f - end) / 0.03f, 2f)));
            s.position = center(u) + sideA * (Mathf.Cos(a) * r) + sideB * (Mathf.Sin(a) * r * stretchB);
            s.major = 0f;
            s.ao = 1f;
            s.wind = 0f;
            s.sizeScale = sizeScale;
        }

        public override bool TryGetInteriorPoint(float u, float v, out Vector3 point)
        {
            point = center(u);
            return true;
        }
    }

    /// <summary>Wheel pommel: a flattened superquadric disc with a raised centre boss.</summary>
    public sealed class SwordPommelSurface : ClothSurface
    {
        readonly Vector3 center;
        readonly SwordFrame frame;
        readonly float r, halfT;

        public SwordPommelSurface(Vector3 center, SwordFrame frame, float radius)
        {
            this.center = center;
            this.frame = frame;
            r = radius;
            halfT = radius * 0.42f;
            thickness = 0f;
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            float theta = CloakMath.Tau * u;
            float phi = (v - 0.5f) * Mathf.PI;
            float radial = r * SwordMath.SPow(Mathf.Cos(phi), 0.45f);
            float f = halfT * SwordMath.SPow(Mathf.Sin(phi), 0.45f);
            f += Mathf.Sign(f) * halfT * 0.35f * CloakMath.Gauss(radial / (r * 0.42f)); // centre boss
            Vector3 dir = frame.axis * Mathf.Cos(theta) + frame.edge * Mathf.Sin(theta);
            s.position = center + dir * radial + frame.face * f;
            s.major = CloakMath.Smooth(0.75f, 0.98f, radial / r) * 0.6f; // rim catches light
            s.ao = 1f;
            s.wind = 0f;
            s.sizeScale = 0.55f;
        }

        public override bool TryGetInteriorPoint(float u, float v, out Vector3 point)
        {
            point = center;
            return true;
        }
    }

    /// <summary>
    /// A loose cloth sleeve along a cubic Bezier from inside the cloak to the hand.
    /// It flares into a bell at the cuff and its lower side droops with gravity, so the hand
    /// is never visible - only the grip leaves the sleeve.
    /// u: around the arm, v: shoulder (0) -> cuff (1).
    /// </summary>
    public sealed class SleeveSurface : ClothSurface
    {
        readonly Vector3 p0, p1, p2, p3;
        readonly float rStart, rEnd, bell;
        readonly FoldField folds;
        readonly float foldDepth;
        readonly bool inner;

        public SleeveSurface(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, float width, float bell, CloakRandom rng,
                             float clothThickness, bool inner)
        {
            this.p0 = p0; this.p1 = p1; this.p2 = p2; this.p3 = p3;
            rStart = width * 0.85f;
            rEnd = width * 0.8f;
            this.bell = bell;
            folds = new FoldField(9, true, 0.8f, 0.03f, 0.02f, 0.3f, rng);
            foldDepth = 0.16f;
            this.inner = inner;
            thickness = clothThickness;
            invertNormal = inner;
        }

        Vector3 Curve(float t)
        {
            float a = 1f - t;
            return p0 * (a * a * a) + p1 * (3f * a * a * t) + p2 * (3f * a * t * t) + p3 * (t * t * t);
        }

        Vector3 Tangent(float t)
        {
            float a = 1f - t;
            Vector3 d = (p1 - p0) * (3f * a * a) + (p2 - p1) * (6f * a * t) + (p3 - p2) * (3f * t * t);
            return d.sqrMagnitude > 1e-10f ? d.normalized : Vector3.down;
        }

        void Frame(float t, out Vector3 c, out Vector3 n1, out Vector3 n2)
        {
            c = Curve(t);
            Vector3 tg = Tangent(t);
            Vector3 reference = Mathf.Abs(tg.y) > 0.95f ? Vector3.forward : Vector3.up;
            n1 = Vector3.Cross(tg, reference).normalized;
            n2 = Vector3.Cross(n1, tg).normalized;
        }

        public float RadiusAt(float v)
        {
            return CloakMath.Lerp(rStart, rEnd, v) + bell * CloakMath.Smooth(0.6f, 1f, v);
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            Vector3 c, n1, n2;
            Frame(v, out c, out n1, out n2);
            float a = CloakMath.Tau * u;
            Vector3 radial = n1 * Mathf.Cos(a) + n2 * Mathf.Sin(a);

            float r = RadiusAt(v);
            // the underside of a loose sleeve hangs lower than the top
            float down = Mathf.Max(0f, -radial.y);
            r *= 1f + 0.45f * down * CloakMath.Smooth(0.35f, 1f, v);

            float ridge;
            float f = folds.Evaluate(u, v, out ridge);
            float env = CloakMath.Smooth(0.05f, 0.5f, v);
            float disp = f * CloakMath.Tau * r * foldDepth * env;
            // soft compression rings where the elbow bends
            disp += 0.01f * Mathf.Cos(v * 26f + u * 3f) * CloakMath.Smooth(0.2f, 0.45f, v) * CloakMath.Smooth(0.75f, 0.55f, v);

            float rr = inner ? (r + disp) * 0.9f : r + disp;
            Vector3 p = c + radial * rr + Vector3.down * (0.06f * down * CloakMath.Smooth(0.5f, 1f, v));

            s.position = p;
            s.major = inner ? 0f : ridge * env;
            s.edge = CloakMath.Smooth(0.95f, 1f, v);
            s.ao = inner ? 0.4f : (1f - 0.4f * Mathf.Max(0f, -ridge) * env) * CloakMath.Lerp(0.6f, 1f, CloakMath.Smooth(0f, 0.3f, v));
            // the deeper inside the sleeve, the darker (the hand is never visible)
            s.voidAmount = inner ? CloakMath.Lerp(0.55f, 1f, CloakMath.Smooth(0.98f, 0.8f, v)) : 0f;
            s.wind = 0.12f * v * (1f - 0.6f * CloakMath.Smooth(0.85f, 1f, v));
        }

        public override bool TryGetInteriorPoint(float u, float v, out Vector3 point)
        {
            point = Curve(v);
            return true;
        }

        /// <summary>Point and axis of the sleeve at v (used for the dark cap inside the cuff).</summary>
        public void Section(float v, out Vector3 c, out Vector3 n1, out Vector3 n2, out float r)
        {
            Frame(v, out c, out n1, out n2);
            r = RadiusAt(v);
        }
    }

    /// <summary>Dark disc across the inside of a sleeve, so nothing shows through the cuff.</summary>
    public sealed class SleeveCapSurface : ClothSurface
    {
        readonly Vector3 c, n1, n2, normal;
        readonly float r;

        public SleeveCapSurface(SleeveSurface sleeve, float v)
        {
            float rr;
            Vector3 a, b;
            sleeve.Section(v, out c, out a, out b, out rr);
            n1 = a;
            n2 = b;
            r = rr * 0.95f;
            normal = Vector3.Cross(n1, n2).normalized;
            thickness = 0.01f;
        }

        public override void Evaluate(float u, float v, ref SurfaceSample s)
        {
            float a = CloakMath.Tau * u;
            Vector3 radial = n1 * Mathf.Cos(a) + n2 * Mathf.Sin(a);
            float down = Mathf.Max(0f, -radial.y);
            s.position = c + radial * (r * v * (1f + 0.4f * down));
            s.hasNormal = true;
            s.normal = normal;
            s.voidAmount = 1f;
            s.ao = 0f;
            s.sizeScale = 1.4f;
            s.wind = 0f;
        }
    }
}
