using System;
using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// Collects the points of one world object (building piece, enemy body).
    ///
    /// Vertex layout read by EchoWorldPoint.shader:
    ///   position, normal
    ///   color : r = brightness of the stone / plank, g = random, b = cavity (1 open .. 0 deep joint)
    ///   uv0   : x = point size multiplier
    /// </summary>
    public sealed class EchoPointBuilder
    {
        public readonly List<Vector3> positions = new List<Vector3>();
        public readonly List<Vector3> normals = new List<Vector3>();
        public readonly List<Color> colors = new List<Color>();
        public readonly List<Vector2> uv0 = new List<Vector2>();

        readonly System.Random rng;

        /// <summary>Distance between neighbouring points.</summary>
        public float spacing = 0.12f;

        public EchoPointBuilder(int seed)
        {
            rng = new System.Random(seed);
        }

        public int Count { get { return positions.Count; } }

        public float Rand()
        {
            return (float)rng.NextDouble();
        }

        public float Range(float a, float b)
        {
            return a + (b - a) * Rand();
        }

        public void Add(Vector3 p, Vector3 n, float brightness, float cavity = 1f, float size = 1f)
        {
            positions.Add(p);
            normals.Add(n.sqrMagnitude > 1e-8f ? n.normalized : Vector3.up);
            colors.Add(new Color(brightness, Rand(), Mathf.Clamp01(cavity), 0f));
            uv0.Add(new Vector2(size, 0f));
        }

        // ------------------------------------------------------------------------------
        // Plain surfaces
        // ------------------------------------------------------------------------------

        /// <summary>Jittered grid of points on a rectangle origin + u*a + v*b (a in [0,w], b in [0,h]).</summary>
        public void Rect(Vector3 origin, Vector3 u, Vector3 v, float w, float h, Vector3 normal, float brightness,
                         float cavity = 1f, Func<float, float, bool> skip = null, float pointSpacing = 0f)
        {
            float sp = pointSpacing > 0f ? pointSpacing : spacing;
            int nu = Mathf.Max(1, Mathf.CeilToInt(w / sp));
            int nv = Mathf.Max(1, Mathf.CeilToInt(h / sp));
            for (int j = 0; j < nv; j++)
            {
                for (int i = 0; i < nu; i++)
                {
                    float a = (i + Rand()) / nu * w;
                    float b = (j + Rand()) / nv * h;
                    if (skip != null && skip(a, b)) continue;
                    Add(origin + u * a + v * b, normal, brightness * Range(0.9f, 1.1f), cavity);
                }
            }
        }

        // ------------------------------------------------------------------------------
        // Masonry: stone courses with recessed joints and slightly domed stones
        // ------------------------------------------------------------------------------

        /// <summary>
        /// Stone face in running bond. Points are placed only on the stones, so the mortar
        /// joints stay dark lines. Each stone is slightly domed and its edges are bevelled
        /// (normals tilt), so the wave light picks out every block.
        /// </summary>
        /// <param name="hole">Optional (a, b) -> true to leave a hole (doors, arches, windows).</param>
        public void Masonry(Vector3 origin, Vector3 u, Vector3 v, Vector3 normal, float w, float h,
                            float stoneHeight, float stoneMin, float stoneMax, Func<float, float, bool> hole = null,
                            float joint = 0.07f, float bulge = 0.05f, float brightness = 1f)
        {
            int rows = Mathf.Max(1, Mathf.RoundToInt(h / stoneHeight));
            float sh = h / rows;
            for (int r = 0; r < rows; r++)
            {
                float y0 = r * sh;
                float x = -Range(0f, stoneMax);
                while (x < w)
                {
                    float sw = Range(stoneMin, stoneMax);
                    float x0 = Mathf.Max(x, 0f), x1 = Mathf.Min(x + sw, w);
                    if (x1 - x0 > joint * 2f)
                        Stone(origin, u, v, normal, x0, x1, y0, y0 + sh, hole, joint, bulge, brightness);
                    x += sw;
                }
            }
        }

        void Stone(Vector3 origin, Vector3 u, Vector3 v, Vector3 normal, float x0, float x1, float y0, float y1,
                   Func<float, float, bool> hole, float joint, float bulge, float brightness)
        {
            float j = joint * 0.5f;
            float sx0 = x0 + j, sx1 = x1 - j, sy0 = y0 + j, sy1 = y1 - j;
            if (sx1 <= sx0 || sy1 <= sy0) return;
            float stoneBright = brightness * Range(0.68f, 1.05f);
            float dome = bulge * Range(0.4f, 1.2f);
            int nu = Mathf.Max(1, Mathf.CeilToInt((sx1 - sx0) / spacing));
            int nv = Mathf.Max(1, Mathf.CeilToInt((sy1 - sy0) / spacing));
            for (int jj = 0; jj < nv; jj++)
            {
                for (int ii = 0; ii < nu; ii++)
                {
                    float a = sx0 + (ii + Rand()) / nu * (sx1 - sx0);
                    float b = sy0 + (jj + Rand()) / nv * (sy1 - sy0);
                    if (hole != null && hole(a, b)) continue;
                    float ea = (a - sx0) / (sx1 - sx0) * 2f - 1f;
                    float eb = (b - sy0) / (sy1 - sy0) * 2f - 1f;
                    float ea4 = ea * ea * ea * ea, eb4 = eb * eb * eb * eb;
                    float shape = (1f - ea4) * (1f - eb4);
                    Vector3 p = origin + u * a + v * b + normal * (dome * shape);
                    Vector3 n = normal + (u * (ea4 * ea) + v * (eb4 * eb)) * 0.9f;
                    Add(p, n, stoneBright, 0.6f + 0.4f * shape);
                }
            }
        }

        /// <summary>Box made of masonry on its four sides and a row of capping stones on top.</summary>
        public void MasonryBox(Vector3 center, Vector3 size, float stoneHeight, bool top = true, bool bottom = false,
                               float brightness = 1f)
        {
            float hx = size.x * 0.5f, hz = size.z * 0.5f;
            Vector3 b0 = center - new Vector3(0f, size.y * 0.5f, 0f);
            float sMin = stoneHeight * 1.2f, sMax = stoneHeight * 2.6f;
            Masonry(b0 + new Vector3(-hx, 0f, hz), Vector3.right, Vector3.up, Vector3.forward, size.x, size.y, stoneHeight, sMin, sMax, null, 0.07f, 0.05f, brightness);
            Masonry(b0 + new Vector3(hx, 0f, -hz), Vector3.left, Vector3.up, Vector3.back, size.x, size.y, stoneHeight, sMin, sMax, null, 0.07f, 0.05f, brightness);
            Masonry(b0 + new Vector3(hx, 0f, hz), Vector3.back, Vector3.up, Vector3.right, size.z, size.y, stoneHeight, sMin, sMax, null, 0.07f, 0.05f, brightness);
            Masonry(b0 + new Vector3(-hx, 0f, -hz), Vector3.forward, Vector3.up, Vector3.left, size.z, size.y, stoneHeight, sMin, sMax, null, 0.07f, 0.05f, brightness);
            if (top)
                Masonry(b0 + new Vector3(-hx, size.y, -hz), Vector3.right, Vector3.forward, Vector3.up, size.x, size.z,
                        Mathf.Min(size.z, stoneHeight * 2f), sMin, sMax, null, 0.06f, 0.03f, brightness);
            if (bottom)
                Rect(b0 + new Vector3(-hx, 0f, -hz), Vector3.right, Vector3.forward, size.x, size.z, Vector3.down, brightness * 0.6f);
        }

        // ------------------------------------------------------------------------------
        // Round masonry (pillars, towers)
        // ------------------------------------------------------------------------------

        /// <summary>
        /// Cylinder of stones. <paramref name="hole"/> works in unrolled coordinates
        /// (a = arc length from the +Z direction going towards +X, b = height).
        /// </summary>
        public void MasonryCylinder(Vector3 baseCenter, float radius, float height, float stoneHeight, float stoneMin,
                                    float stoneMax, Func<float, float, bool> hole = null, float brightness = 1f, float bulge = 0.05f)
        {
            float circumference = 2f * Mathf.PI * radius;
            int rows = Mathf.Max(1, Mathf.RoundToInt(height / stoneHeight));
            float sh = height / rows;
            const float joint = 0.07f;
            for (int r = 0; r < rows; r++)
            {
                float y0 = r * sh;
                float x = Range(0f, stoneMax);
                float start = x;
                while (x < start + circumference - 0.05f)
                {
                    float sw = Mathf.Min(Range(stoneMin, stoneMax), start + circumference - x);
                    float sx0 = x + joint * 0.5f, sx1 = x + sw - joint * 0.5f;
                    float sy0 = y0 + joint * 0.5f, sy1 = y0 + sh - joint * 0.5f;
                    float bright = brightness * Range(0.68f, 1.05f);
                    float dome = bulge * Range(0.4f, 1.2f);
                    int nu = Mathf.Max(1, Mathf.CeilToInt((sx1 - sx0) / spacing));
                    int nv = Mathf.Max(1, Mathf.CeilToInt((sy1 - sy0) / spacing));
                    for (int jj = 0; jj < nv; jj++)
                    {
                        for (int ii = 0; ii < nu; ii++)
                        {
                            float a = sx0 + (ii + Rand()) / nu * (sx1 - sx0);
                            float b = sy0 + (jj + Rand()) / nv * (sy1 - sy0);
                            float aw = a % circumference;
                            if (hole != null && hole(aw, b)) continue;
                            float ea = (a - sx0) / (sx1 - sx0) * 2f - 1f;
                            float eb = (b - sy0) / (sy1 - sy0) * 2f - 1f;
                            float ea4 = ea * ea * ea * ea, eb4 = eb * eb * eb * eb;
                            float shape = (1f - ea4) * (1f - eb4);
                            float ang = aw / radius;
                            Vector3 radial = new Vector3(Mathf.Sin(ang), 0f, Mathf.Cos(ang));
                            Vector3 tangent = new Vector3(Mathf.Cos(ang), 0f, -Mathf.Sin(ang));
                            Vector3 p = baseCenter + radial * (radius + dome * shape) + Vector3.up * b;
                            Vector3 n = radial + (tangent * (ea4 * ea) + Vector3.up * (eb4 * eb)) * 0.9f;
                            Add(p, n, bright, 0.6f + 0.4f * shape);
                        }
                    }
                    x += sw;
                }
            }
        }

        /// <summary>Flat disc / ring (tops of pillars, tower floors).</summary>
        public void Disc(Vector3 center, float innerRadius, float outerRadius, Vector3 normal, float brightness)
        {
            float area = Mathf.PI * (outerRadius * outerRadius - innerRadius * innerRadius);
            int count = Mathf.Max(8, Mathf.RoundToInt(area / (spacing * spacing)));
            Vector3 t1 = Mathf.Abs(normal.y) > 0.9f ? Vector3.right : Vector3.up;
            Vector3 a = Vector3.Cross(normal, t1).normalized;
            Vector3 b = Vector3.Cross(normal, a);
            for (int i = 0; i < count; i++)
            {
                // stratified in radius^2 so the density is even
                float t = (i + Rand()) / count;
                float r = Mathf.Sqrt(Mathf.Lerp(innerRadius * innerRadius, outerRadius * outerRadius, t));
                float ang = Rand() * 2f * Mathf.PI;
                Add(center + (a * Mathf.Cos(ang) + b * Mathf.Sin(ang)) * r, normal, brightness * Range(0.85f, 1.1f));
            }
        }

        /// <summary>Conical roof with overlapping shingle rows (each row's lower edge sticks out).</summary>
        public void ShingleCone(Vector3 baseCenter, float radius, float height, float brightness)
        {
            float slant = Mathf.Sqrt(radius * radius + height * height);
            const float rowLength = 0.55f;
            int rows = Mathf.Max(1, Mathf.RoundToInt(slant / rowLength));
            for (int r = 0; r < rows; r++)
            {
                float s0 = (float)r / rows, s1 = (float)(r + 1) / rows; // 0 = eaves, 1 = apex
                float rowR = radius * (1f - s0);
                float circumference = 2f * Mathf.PI * Mathf.Max(rowR, 0.05f);
                int nAround = Mathf.Max(6, Mathf.CeilToInt(circumference / spacing));
                int nAlong = Mathf.Max(1, Mathf.CeilToInt(rowLength / spacing));
                float tabWidth = 0.45f;
                float stagger = (r % 2) * 0.5f;
                for (int j = 0; j < nAlong; j++)
                {
                    for (int i = 0; i < nAround; i++)
                    {
                        float t = (j + Rand()) / nAlong;              // 0 = lower edge of this row
                        float s = Mathf.Lerp(s0, s1, t);
                        float ang = (i + Rand()) / nAround * 2f * Mathf.PI;
                        float arc = ang * Mathf.Max(rowR, 0.05f) / tabWidth + stagger;
                        float inTab = arc - Mathf.Floor(arc);
                        if (inTab > 0.93f && t < 0.6f) continue;      // gap between shingle tabs
                        float lift = 0.07f * (1f - t);                // lower edge stands out
                        float rr = radius * (1f - s);
                        Vector3 radial = new Vector3(Mathf.Sin(ang), 0f, Mathf.Cos(ang));
                        Vector3 n = (radial * height / slant + Vector3.up * radius / slant).normalized;
                        Vector3 p = baseCenter + radial * rr + Vector3.up * (height * s) + n * lift;
                        Add(p, n, brightness * Range(0.75f, 1.0f) * (0.75f + 0.25f * t), 0.55f + 0.45f * t);
                    }
                }
            }
        }

        // ------------------------------------------------------------------------------
        // Organic shapes (enemies)
        // ------------------------------------------------------------------------------

        public void Ellipsoid(Vector3 center, Vector3 radii, Quaternion rotation, float brightness, float size = 1f)
        {
            float area = 4f * Mathf.PI * Mathf.Pow((radii.x * radii.y + radii.y * radii.z + radii.x * radii.z) / 3f, 1f);
            int count = Mathf.Max(16, Mathf.RoundToInt(area / (spacing * spacing)));
            for (int i = 0; i < count; i++)
            {
                // even points on the unit sphere, then scaled
                float zc = 1f - 2f * (i + Rand()) / count;
                float rr = Mathf.Sqrt(Mathf.Max(0f, 1f - zc * zc));
                float ang = Rand() * 2f * Mathf.PI;
                Vector3 d = new Vector3(rr * Mathf.Cos(ang), zc, rr * Mathf.Sin(ang));
                Vector3 p = Vector3.Scale(d, radii);
                Vector3 n = new Vector3(d.x / radii.x, d.y / radii.y, d.z / radii.z);
                Add(center + rotation * p, rotation * n, brightness * Range(0.85f, 1.1f), 1f, size);
            }
        }

        /// <summary>Tube along a cubic Bezier with a radius profile and optional vertical folds.</summary>
        public void Tube(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, Func<float, float> radius, float brightness,
                         int folds = 0, float foldDepth = 0f, float size = 1f)
        {
            const int samples = 64;
            float length = 0f;
            Vector3 prev = Bezier(p0, p1, p2, p3, 0f);
            for (int i = 1; i <= samples; i++)
            {
                Vector3 c = Bezier(p0, p1, p2, p3, (float)i / samples);
                length += Vector3.Distance(prev, c);
                prev = c;
            }
            float avgR = (radius(0f) + radius(0.5f) + radius(1f)) / 3f;
            int nAlong = Mathf.Max(2, Mathf.CeilToInt(length / spacing));
            int nAround = Mathf.Max(6, Mathf.CeilToInt(2f * Mathf.PI * avgR / spacing));
            for (int j = 0; j < nAlong; j++)
            {
                for (int i = 0; i < nAround; i++)
                {
                    float t = (j + Rand()) / nAlong;
                    float ang = (i + Rand()) / nAround * 2f * Mathf.PI;
                    Vector3 c = Bezier(p0, p1, p2, p3, t);
                    Vector3 tg = BezierTangent(p0, p1, p2, p3, t);
                    Vector3 reference = Mathf.Abs(tg.y) > 0.95f ? Vector3.forward : Vector3.up;
                    Vector3 n1 = Vector3.Cross(tg, reference).normalized;
                    Vector3 n2 = Vector3.Cross(n1, tg).normalized;
                    Vector3 radial = n1 * Mathf.Cos(ang) + n2 * Mathf.Sin(ang);
                    float fold = folds > 0 ? foldDepth * Mathf.Cos(ang * folds + t * 2f) * t : 0f;
                    float r = radius(t) + fold;
                    Add(c + radial * r, radial, brightness * Range(0.8f, 1.05f), 0.75f + 0.25f * Mathf.Cos(ang * folds), size);
                }
            }
        }

        public static Vector3 Bezier(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, float t)
        {
            float a = 1f - t;
            return p0 * (a * a * a) + p1 * (3f * a * a * t) + p2 * (3f * a * t * t) + p3 * (t * t * t);
        }

        public static Vector3 BezierTangent(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, float t)
        {
            float a = 1f - t;
            Vector3 d = (p1 - p0) * (3f * a * a) + (p2 - p1) * (6f * a * t) + (p3 - p2) * (3f * t * t);
            return d.sqrMagnitude > 1e-10f ? d.normalized : Vector3.up;
        }
    }
}
