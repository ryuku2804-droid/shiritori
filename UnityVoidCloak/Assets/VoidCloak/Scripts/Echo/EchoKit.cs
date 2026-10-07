using System;
using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>Medieval building pieces that can be placed in a stage.</summary>
    public enum EchoKitKind
    {
        /// <summary>Flagstone floor. size.x / size.z = extent.</summary>
        Floor,
        /// <summary>Masonry wall. size = width, height, thickness.</summary>
        Wall,
        /// <summary>Masonry wall with an arched gateway in the middle.</summary>
        ArchWall,
        /// <summary>Round pillar with base and capital. size.x = diameter, size.y = height.</summary>
        Pillar,
        /// <summary>Round tower with a door and a shingled cone roof. size.x = diameter, size.y = wall height.</summary>
        Tower,
        /// <summary>Stone stairs rising along +Z. size = width, total height, depth.</summary>
        Stairs,
        /// <summary>Raised masonry block with a flagstone top. size = width, height, depth.</summary>
        Platform,
        /// <summary>Wooden crate. size = box size.</summary>
        Crate,
        /// <summary>Wooden barrel. size.x = diameter, size.y = height.</summary>
        Barrel,
        /// <summary>Pile of fallen masonry blocks. size = footprint x, max height, footprint z.</summary>
        Rubble,
        /// <summary>A shard of the great bell lying on the floor. size.x = bell diameter, size.y = bell height.</summary>
        BellFragment,
        /// <summary>Town house with windows, a door on the front (+Z) and a gable roof. size = width, wall height, depth.
        /// ruined = no roof, broken walls, and you can walk in through the doorway.</summary>
        House,
        /// <summary>Round stone well with a little roof. size.x = diameter, size.y = height of the stone ring.</summary>
        Well,
        /// <summary>Abandoned market stall: counter at the front (+Z), posts and a torn awning. size = width, height, depth.</summary>
        Stall,
    }

    /// <summary>Everything needed to build one piece. Lengths in world units (the knight is ~4.2 tall).</summary>
    [Serializable]
    public class EchoKitSpec
    {
        public EchoKitKind kind = EchoKitKind.Wall;
        public Vector3 size = new Vector3(10f, 7f, 1.4f);
        [Tooltip("Height of one stone course.")]
        [Range(0.2f, 2f)] public float stoneHeight = 0.6f;
        [Tooltip("Distance between points. Smaller = denser and heavier.")]
        [Range(0.05f, 0.5f)] public float pointSpacing = 0.13f;
        public int seed = 1;

        [Header("Wall")]
        [Tooltip("Crenellations along the top of a wall.")]
        public bool battlements;
        [Tooltip("Only the front face (+Z) is built. Use for outer walls (and row houses) nobody sees from behind.")]
        public bool frontOnly;

        [Header("Arch / Door")]
        public float openingWidth = 5f;
        public float openingHeight = 7f;

        [Header("Stairs")]
        [Range(1, 40)] public int steps = 6;

        [Header("Tower")]
        public float roofHeight = 7f;
        public bool door = true;
        [Tooltip("Broken tower: jagged top, no roof, hollow inside (you can walk in).")]
        public bool ruined;

        public EchoKitSpec Clone()
        {
            return (EchoKitSpec)MemberwiseClone();
        }
    }

    /// <summary>
    /// Builds the points and the collision boxes of a kit piece (local space, piece origin at
    /// the bottom centre). Pure C# so it also runs in the offline preview.
    /// </summary>
    public static partial class EchoKitGenerator
    {
        public static void Build(EchoKitSpec spec, EchoPointBuilder b, List<Bounds> colliders)
        {
            b.spacing = spec.pointSpacing;
            switch (spec.kind)
            {
                case EchoKitKind.Floor: Floor(spec, b, colliders); break;
                case EchoKitKind.Wall: Wall(spec, b, colliders, false); break;
                case EchoKitKind.ArchWall: Wall(spec, b, colliders, true); break;
                case EchoKitKind.Pillar: Pillar(spec, b, colliders); break;
                case EchoKitKind.Tower: Tower(spec, b, colliders); break;
                case EchoKitKind.Stairs: Stairs(spec, b, colliders); break;
                case EchoKitKind.Platform: Platform(spec, b, colliders); break;
                case EchoKitKind.Crate: Crate(spec, b, colliders); break;
                case EchoKitKind.Barrel: Barrel(spec, b, colliders); break;
                case EchoKitKind.Rubble: Rubble(spec, b, colliders); break;
                case EchoKitKind.BellFragment: BellFragment(spec, b, colliders); break;
                case EchoKitKind.House: House(spec, b, colliders); break;
                case EchoKitKind.Well: Well(spec, b, colliders); break;
                case EchoKitKind.Stall: Stall(spec, b, colliders); break;
            }
        }

        // ---------------------------------------------------------------- floor

        static void Floor(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            Flagstones(b, -s.size.x * 0.5f, s.size.x * 0.5f, -s.size.z * 0.5f, s.size.z * 0.5f, 0f, 0.62f);
            colliders.Add(new Bounds(new Vector3(0f, -0.5f, 0f), new Vector3(s.size.x, 1f, s.size.z)));
        }

        /// <summary>Irregular rows of flagstones; each slab sits a little higher or lower.</summary>
        public static void Flagstones(EchoPointBuilder b, float x0, float x1, float z0, float z1, float y, float brightness)
        {
            float z = z0;
            while (z < z1 - 0.05f)
            {
                float rowDepth = Mathf.Min(b.Range(1.1f, 1.9f), z1 - z);
                float x = x0 - b.Range(0f, 1.5f);
                while (x < x1 - 0.05f)
                {
                    float w = b.Range(1.0f, 2.4f);
                    float sx0 = Mathf.Max(x, x0), sx1 = Mathf.Min(x + w, x1);
                    if (sx1 - sx0 > 0.15f)
                    {
                        float lift = b.Range(-0.03f, 0.04f);
                        float tiltX = b.Range(-0.03f, 0.03f), tiltZ = b.Range(-0.03f, 0.03f);
                        float bright = brightness * b.Range(0.7f, 1.1f);
                        float jx0 = sx0 + 0.05f, jx1 = sx1 - 0.05f, jz0 = z + 0.05f, jz1 = z + rowDepth - 0.05f;
                        int nu = Mathf.Max(1, Mathf.CeilToInt((jx1 - jx0) / b.spacing));
                        int nv = Mathf.Max(1, Mathf.CeilToInt((jz1 - jz0) / b.spacing));
                        Vector3 n = new Vector3(-tiltX, 1f, -tiltZ);
                        float cx = (jx0 + jx1) * 0.5f, cz = (jz0 + jz1) * 0.5f;
                        for (int j = 0; j < nv; j++)
                        {
                            for (int i = 0; i < nu; i++)
                            {
                                float px = jx0 + (i + b.Rand()) / nu * (jx1 - jx0);
                                float pz = jz0 + (j + b.Rand()) / nv * (jz1 - jz0);
                                float py = y + lift + tiltX * (px - cx) + tiltZ * (pz - cz);
                                float ex = Mathf.Abs((px - cx) / ((jx1 - jx0) * 0.5f));
                                float ez = Mathf.Abs((pz - cz) / ((jz1 - jz0) * 0.5f));
                                float edge = Mathf.Max(ex, ez);
                                b.Add(new Vector3(px, py, pz), n, bright * b.Range(0.9f, 1.1f), 1f - 0.4f * edge * edge * edge * edge);
                            }
                        }
                    }
                    x += w;
                }
                z += rowDepth;
            }
        }

        // ---------------------------------------------------------------- walls

        static void Wall(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders, bool arch)
        {
            float w = s.size.x, h = s.size.y, t = s.size.z;
            float sh = s.stoneHeight, sMin = sh * 1.3f, sMax = sh * 2.8f;
            float ow = Mathf.Min(s.openingWidth, w - 1f);
            float R = ow * 0.5f;
            float spring = Mathf.Max(0.5f, Mathf.Min(s.openingHeight, h - 1f) - R);   // where the arch curve starts
            const float voussoirDepth = 0.75f;

            // hole in face coordinates (a from the left end, b up)
            Func<float, float, bool> openingWithRing = null;
            if (arch)
            {
                float half = w * 0.5f;
                openingWithRing = (a, bb) => InArch(a - half, bb, R, spring, voussoirDepth);
            }

            // front (+Z) and back (-Z) faces
            b.Masonry(new Vector3(-w * 0.5f, 0f, t * 0.5f), Vector3.right, Vector3.up, Vector3.forward, w, h, sh, sMin, sMax, openingWithRing);
            if (!s.frontOnly)
            {
                Func<float, float, bool> backHole = openingWithRing == null ? null : (a, bb) => openingWithRing(w - a, bb);
                b.Masonry(new Vector3(w * 0.5f, 0f, -t * 0.5f), Vector3.left, Vector3.up, Vector3.back, w, h, sh, sMin, sMax, backHole);
                // ends and coping
                b.Masonry(new Vector3(-w * 0.5f, 0f, -t * 0.5f), Vector3.forward, Vector3.up, Vector3.left, t, h, sh, sMin, sMax);
                b.Masonry(new Vector3(w * 0.5f, 0f, t * 0.5f), Vector3.back, Vector3.up, Vector3.right, t, h, sh, sMin, sMax);
            }
            b.Masonry(new Vector3(-w * 0.5f, h, -t * 0.5f), Vector3.right, Vector3.forward, Vector3.up, w, t, t, sMin, sMax, null, 0.06f, 0.03f);

            if (arch)
            {
                const float cx = 0f; // the arch is centred on the piece
                Voussoirs(b, new Vector3(cx, spring, t * 0.5f), Vector3.right, Vector3.forward, R, voussoirDepth);
                if (!s.frontOnly) Voussoirs(b, new Vector3(cx, spring, -t * 0.5f), Vector3.left, Vector3.back, R, voussoirDepth);
                // jambs (inner side faces of the opening) and the curved soffit
                b.Masonry(new Vector3(cx - R, 0f, t * 0.5f), Vector3.back, Vector3.up, Vector3.right, t, spring, sh, sMin, sMax);
                b.Masonry(new Vector3(cx + R, 0f, -t * 0.5f), Vector3.forward, Vector3.up, Vector3.left, t, spring, sh, sMin, sMax);
                Soffit(b, new Vector3(cx, spring, 0f), R, t);

                // collision: two sides and the lintel above the arch
                float sideW = (w - ow) * 0.5f;
                colliders.Add(new Bounds(new Vector3(-w * 0.5f + sideW * 0.5f, h * 0.5f, 0f), new Vector3(sideW, h, t)));
                colliders.Add(new Bounds(new Vector3(w * 0.5f - sideW * 0.5f, h * 0.5f, 0f), new Vector3(sideW, h, t)));
                float lintelBottom = spring + R * 0.7f;
                colliders.Add(new Bounds(new Vector3(0f, (lintelBottom + h) * 0.5f, 0f), new Vector3(ow, h - lintelBottom, t)));
            }
            else
            {
                colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, 0f), new Vector3(w, h, t)));
            }

            if (s.battlements) Battlements(b, w, h, t, sh);
        }

        static bool InArch(float x, float y, float R, float spring, float ring)
        {
            if (y < 0f) return false;
            if (y <= spring) return Mathf.Abs(x) < R;
            float d = Mathf.Sqrt(x * x + (y - spring) * (y - spring));
            return d < R + ring;
        }

        /// <summary>Wedge-shaped stones around the arch, with a slightly larger keystone.</summary>
        static void Voussoirs(EchoPointBuilder b, Vector3 center, Vector3 right, Vector3 normal, float R, float depth)
        {
            const int stones = 13;
            for (int k = 0; k < stones; k++)
            {
                float a0 = Mathf.PI * k / stones, a1 = Mathf.PI * (k + 1) / stones;
                bool key = k == stones / 2;
                float r0 = R + 0.04f, r1 = R + depth + (key ? 0.25f : 0f) - 0.04f;
                float gap = 0.035f / R;
                float bright = b.Range(0.75f, 1.05f);
                int nr = Mathf.Max(1, Mathf.CeilToInt((r1 - r0) / b.spacing));
                int na = Mathf.Max(1, Mathf.CeilToInt((a1 - a0) * R / b.spacing));
                for (int j = 0; j < nr; j++)
                {
                    for (int i = 0; i < na; i++)
                    {
                        float ang = Mathf.Lerp(a0 + gap, a1 - gap, (i + b.Rand()) / na);
                        float r = Mathf.Lerp(r0, r1, (j + b.Rand()) / nr);
                        float er = ((r - r0) / (r1 - r0)) * 2f - 1f;
                        float ea = ((ang - a0) / (a1 - a0)) * 2f - 1f;
                        float shape = (1f - er * er * er * er) * (1f - ea * ea * ea * ea);
                        // angle 0 = right side, PI = left side
                        Vector3 dir = right * Mathf.Cos(ang) + Vector3.up * Mathf.Sin(ang);
                        b.Add(center + dir * r + normal * (0.06f * shape), normal + dir * (er * er * er * 0.6f), bright, 0.6f + 0.4f * shape);
                    }
                }
            }
        }

        /// <summary>Underside of the arch (half cylinder through the wall).</summary>
        static void Soffit(EchoPointBuilder b, Vector3 center, float R, float thickness)
        {
            int na = Mathf.Max(4, Mathf.CeilToInt(Mathf.PI * R / b.spacing));
            int nz = Mathf.Max(1, Mathf.CeilToInt(thickness / b.spacing));
            for (int j = 0; j < nz; j++)
            {
                for (int i = 0; i < na; i++)
                {
                    float ang = (i + b.Rand()) / na * Mathf.PI;
                    float z = -thickness * 0.5f + (j + b.Rand()) / nz * thickness;
                    Vector3 dir = new Vector3(Mathf.Cos(ang), Mathf.Sin(ang), 0f);
                    int stone = Mathf.FloorToInt(ang / Mathf.PI * 13f);
                    float inStone = ang / Mathf.PI * 13f - stone;
                    if (inStone < 0.04f || inStone > 0.96f) continue;
                    b.Add(center + dir * R + Vector3.forward * z, -dir, 0.75f, 0.85f);
                }
            }
        }

        static void Battlements(EchoPointBuilder b, float w, float h, float t, float sh)
        {
            const float merlon = 1.3f, gap = 0.9f, mh = 1.2f;
            float x = -w * 0.5f + 0.2f;
            while (x + merlon <= w * 0.5f)
            {
                b.MasonryBox(new Vector3(x + merlon * 0.5f, h + mh * 0.5f, 0f), new Vector3(merlon, mh, t * 0.9f), sh, true, false, 0.95f);
                x += merlon + gap;
            }
        }

        // ---------------------------------------------------------------- round pieces

        static void Pillar(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float r = s.size.x * 0.5f, h = s.size.y;
            float baseH = Mathf.Min(0.6f, h * 0.1f), capH = Mathf.Min(0.6f, h * 0.1f);
            // square plinth, round shaft made of drums, square capital
            b.MasonryBox(new Vector3(0f, baseH * 0.5f, 0f), new Vector3(r * 2.7f, baseH, r * 2.7f), baseH, true);
            float circumference = 2f * Mathf.PI * r;
            b.MasonryCylinder(new Vector3(0f, baseH, 0f), r, h - baseH - capH, Mathf.Max(0.6f, s.stoneHeight * 1.4f),
                              circumference * 0.98f, circumference * 1.0f, null, 1f, 0.03f);
            b.MasonryBox(new Vector3(0f, h - capH * 0.5f, 0f), new Vector3(r * 2.8f, capH, r * 2.8f), capH, true);
            colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, 0f), new Vector3(r * 2.2f, h, r * 2.2f)));
        }

        static void Tower(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float r = s.size.x * 0.5f, h = s.size.y;
            float doorW = Mathf.Min(2.6f, r), doorH = Mathf.Min(4.4f, h * 0.45f);
            float circumference = 2f * Mathf.PI * r;
            Func<float, float, bool> holes = (a, y) =>
            {
                // door facing +Z (a = 0 is the +Z direction), arrow slits around the upper part
                float da = Mathf.Min(a, circumference - a);
                if (s.door && da < doorW * 0.5f)
                {
                    float top = doorH - doorW * 0.5f;
                    if (y < top) return true;
                    float dy = y - top;
                    if (da * da + dy * dy < doorW * doorW * 0.25f) return true;
                }
                for (int k = 0; k < 4; k++)
                {
                    float slitA = circumference * (0.125f + 0.25f * k);
                    if (Mathf.Abs(a - slitA) < 0.18f && y > h * 0.6f && y < h * 0.6f + 1.6f) return true;
                }
                return false;
            };
            if (s.ruined)
            {
                RuinedTower(s, b, colliders, r, h, doorW, holes);
                return;
            }
            b.MasonryCylinder(Vector3.zero, r, h, s.stoneHeight, s.stoneHeight * 1.4f, s.stoneHeight * 2.8f, holes);
            // projecting ring under the roof and the roof itself
            b.MasonryCylinder(new Vector3(0f, h, 0f), r + 0.35f, 0.6f, 0.6f, 1.2f, 2.2f, null, 0.9f);
            b.Disc(new Vector3(0f, h, 0f), r, r + 0.35f, Vector3.down, 0.5f);
            b.ShingleCone(new Vector3(0f, h + 0.6f, 0f), r + 0.9f, s.roofHeight, 0.8f);
            if (s.door)
            {
                // dark interior just behind the doorway
                b.Disc(new Vector3(0f, 0.02f, 0f), 0f, r - 0.1f, Vector3.up, 0.25f);
            }
            colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, 0f), new Vector3(r * 1.8f, h, r * 1.8f)));
        }

        /// <summary>
        /// Broken tower you can stand inside: the wall top is jagged, there is no roof, the inner
        /// face of the wall is built too, and the collision is a ring of boxes with a gap at the door.
        /// </summary>
        static void RuinedTower(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders, float r, float h, float doorW,
                                Func<float, float, bool> holes)
        {
            float circumference = 2f * Mathf.PI * r;
            const float thickness = 1.2f;
            int seed = s.seed;
            Func<float, float> broken = a =>
            {
                // jagged top: big collapses plus small teeth
                float u = a / circumference * 2f * Mathf.PI;
                float big = 0.5f + 0.3f * Mathf.Sin(u * 1.0f + seed) + 0.2f * Mathf.Sin(u * 2.7f + seed * 0.37f);
                float teeth = 0.08f * Mathf.Sin(u * 23f + seed) + 0.05f * Mathf.Sin(u * 41f);
                return h * Mathf.Clamp(0.35f + 0.6f * big + teeth, 0.25f, 1f);
            };
            Func<float, float, bool> wallHoles = (a, y) => y > broken(a) || holes(a, y);
            b.MasonryCylinder(Vector3.zero, r, h, s.stoneHeight, s.stoneHeight * 1.4f, s.stoneHeight * 2.8f, wallHoles);
            // inner face (normals pointing inwards)
            int before = b.Count;
            b.MasonryCylinder(Vector3.zero, r - thickness, h, s.stoneHeight, s.stoneHeight * 1.4f, s.stoneHeight * 2.8f,
                              (a, y) => wallHoles(a * r / (r - thickness), y), 0.75f);
            for (int i = before; i < b.Count; i++)
            {
                Vector3 n = b.normals[i];
                b.normals[i] = new Vector3(-n.x, n.y, -n.z);
            }
            // broken wall top: rough stones along the break
            int nTop = Mathf.CeilToInt(circumference / b.spacing);
            for (int i = 0; i < nTop * 3; i++)
            {
                float a = b.Rand() * circumference;
                if (holes(a, 0.5f)) continue;
                float ang = a / r;
                float rr = Mathf.Lerp(r - thickness, r, b.Rand());
                Vector3 radial = new Vector3(Mathf.Sin(ang), 0f, Mathf.Cos(ang));
                b.Add(radial * rr + Vector3.up * (broken(a) + b.Range(-0.1f, 0.15f)), Vector3.up + radial * b.Range(-0.4f, 0.4f), b.Range(0.6f, 1f));
            }
            // fallen stones scattered on the inside
            for (int k = 0; k < 9; k++)
            {
                float ang = b.Rand() * 2f * Mathf.PI;
                if (Mathf.Abs(Mathf.DeltaAngle(ang * Mathf.Rad2Deg, 0f)) < 35f) continue;   // keep the doorway clear
                float rr = b.Range(r * 0.45f, r - thickness - 0.6f);
                Vector3 p = new Vector3(Mathf.Sin(ang) * rr, 0f, Mathf.Cos(ang) * rr);
                float sz = b.Range(0.5f, 1.1f);
                b.MasonryBox(p + Vector3.up * (sz * 0.35f), new Vector3(sz * 1.4f, sz * 0.7f, sz), sz * 0.7f, true, false, 0.75f);
            }

            // collision: a ring of boxes, leaving the doorway open
            const int segments = 24;
            for (int k = 0; k < segments; k++)
            {
                float a0 = circumference * k / segments, a1 = circumference * (k + 1) / segments;
                float mid = (a0 + a1) * 0.5f;
                float da = Mathf.Min(mid, circumference - mid);
                if (s.door && da < doorW * 0.5f + 0.3f) continue;
                float ang = mid / r;
                float rc = r - thickness * 0.5f;
                var c = new Vector3(Mathf.Sin(ang) * rc, h * 0.5f, Mathf.Cos(ang) * rc);
                float len = (a1 - a0) * 1.08f;
                // boxes are axis aligned, so use a square that covers the segment
                float side = Mathf.Max(len, thickness) * 0.75f;
                colliders.Add(new Bounds(c, new Vector3(side, h, side)));
            }
        }

        // ---------------------------------------------------------------- stairs / platform

        static void Stairs(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float w = s.size.x, H = s.size.y, D = s.size.z;
            int n = Mathf.Max(1, s.steps);
            float rise = H / n, run = D / n;
            for (int i = 0; i < n; i++)
            {
                float z0 = -D * 0.5f + i * run, y1 = (i + 1) * rise;
                // tread made of two or three slabs, riser as one course of stones
                float x = -w * 0.5f;
                while (x < w * 0.5f - 0.05f)
                {
                    float sw = Mathf.Min(b.Range(1.2f, 2.2f), w * 0.5f - x);
                    float bright = b.Range(0.65f, 0.95f);
                    b.Rect(new Vector3(x + 0.04f, y1, z0 + 0.04f), Vector3.right, Vector3.forward, sw - 0.08f, run - 0.08f + (i == n - 1 ? 0f : 0.0f), Vector3.up, bright);
                    x += sw;
                }
                b.Masonry(new Vector3(-w * 0.5f, i * rise, z0), Vector3.right, Vector3.up, Vector3.back, w, rise, rise, 1.0f, 2.2f);
                // side walls of this step column
                b.Rect(new Vector3(-w * 0.5f, 0f, z0), Vector3.forward, Vector3.up, run, y1, Vector3.left, 0.6f);
                b.Rect(new Vector3(w * 0.5f, 0f, z0), Vector3.forward, Vector3.up, run, y1, Vector3.right, 0.6f);
                colliders.Add(new Bounds(new Vector3(0f, y1 * 0.5f, z0 + run * 0.5f), new Vector3(w, y1, run)));
            }
        }

        static void Platform(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            b.MasonryBox(new Vector3(0f, s.size.y * 0.5f, 0f), s.size, s.stoneHeight, false);
            Flagstones(b, -s.size.x * 0.5f, s.size.x * 0.5f, -s.size.z * 0.5f, s.size.z * 0.5f, s.size.y, 0.7f);
            colliders.Add(new Bounds(new Vector3(0f, s.size.y * 0.5f, 0f), s.size));
        }

        // ---------------------------------------------------------------- props

        static void Crate(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            Vector3 size = s.size;
            float hx = size.x * 0.5f, hy = size.y, hz = size.z * 0.5f;
            const float plank = 0.32f, groove = 0.035f;
            Func<float, float, bool> grooves = (a, y) => (y % plank) < groove;
            float bright = 0.55f;
            // four sides with horizontal planks, frame boards stand out a little
            PlankFace(b, new Vector3(-hx, 0f, hz), Vector3.right, Vector3.up, Vector3.forward, size.x, hy, grooves, bright);
            PlankFace(b, new Vector3(hx, 0f, -hz), Vector3.left, Vector3.up, Vector3.back, size.x, hy, grooves, bright);
            PlankFace(b, new Vector3(hx, 0f, hz), Vector3.back, Vector3.up, Vector3.right, size.z, hy, grooves, bright);
            PlankFace(b, new Vector3(-hx, 0f, -hz), Vector3.forward, Vector3.up, Vector3.left, size.z, hy, grooves, bright);
            PlankFace(b, new Vector3(-hx, hy, -hz), Vector3.right, Vector3.forward, Vector3.up, size.x, size.z, (a, y) => (a % plank) < groove, bright);
            colliders.Add(new Bounds(new Vector3(0f, hy * 0.5f, 0f), size));
        }

        static void PlankFace(EchoPointBuilder b, Vector3 origin, Vector3 u, Vector3 v, Vector3 n, float w, float h,
                              Func<float, float, bool> grooves, float bright)
        {
            const float frame = 0.16f;
            int nu = Mathf.Max(1, Mathf.CeilToInt(w / b.spacing));
            int nv = Mathf.Max(1, Mathf.CeilToInt(h / b.spacing));
            for (int j = 0; j < nv; j++)
            {
                for (int i = 0; i < nu; i++)
                {
                    float a = (i + b.Rand()) / nu * w, y = (j + b.Rand()) / nv * h;
                    bool onFrame = a < frame || a > w - frame || y < frame || y > h - frame;
                    if (!onFrame && grooves(a, y)) continue;
                    float lift = onFrame ? 0.04f : 0f;
                    b.Add(origin + u * a + v * y + n * lift, n, bright * (onFrame ? 1.1f : 0.9f) * b.Range(0.85f, 1.1f), onFrame ? 1f : 0.85f);
                }
            }
        }

        static void Barrel(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float r = s.size.x * 0.5f, h = s.size.y;
            const float staveWidth = 0.28f;
            int nAround = Mathf.Max(8, Mathf.CeilToInt(2f * Mathf.PI * r * 1.12f / b.spacing));
            int nUp = Mathf.Max(2, Mathf.CeilToInt(h / b.spacing));
            for (int j = 0; j < nUp; j++)
            {
                for (int i = 0; i < nAround; i++)
                {
                    float t = (j + b.Rand()) / nUp;
                    float ang = (i + b.Rand()) / nAround * 2f * Mathf.PI;
                    float bulge = 1f + 0.13f * Mathf.Sin(Mathf.PI * t);
                    float arc = ang * r / staveWidth;
                    if (arc - Mathf.Floor(arc) < 0.06f) continue;                 // gap between staves
                    bool hoop = Mathf.Abs(t - 0.15f) < 0.045f || Mathf.Abs(t - 0.85f) < 0.045f;
                    Vector3 radial = new Vector3(Mathf.Sin(ang), 0f, Mathf.Cos(ang));
                    float slope = 0.13f * Mathf.PI * Mathf.Cos(Mathf.PI * t) * r / h;
                    Vector3 n = (radial - Vector3.up * slope).normalized;
                    float rr = r * bulge + (hoop ? 0.04f : 0f);
                    b.Add(radial * rr + Vector3.up * (t * h), n, (hoop ? 0.35f : 0.55f) * b.Range(0.85f, 1.1f), hoop ? 1f : 0.9f);
                }
            }
            b.Disc(new Vector3(0f, h, 0f), 0f, r * 0.95f, Vector3.up, 0.5f);
            colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, 0f), new Vector3(r * 2.2f, h, r * 2.2f)));
        }

        static void Rubble(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            // stacked broken blocks, bigger at the bottom
            float hx = s.size.x * 0.5f, hz = s.size.z * 0.5f;
            int blocks = Mathf.Max(3, Mathf.RoundToInt(s.size.x * s.size.z * 0.9f));
            for (int k = 0; k < blocks; k++)
            {
                float layer = b.Rand();
                float sz = Mathf.Lerp(1.2f, 0.45f, layer) * b.Range(0.7f, 1.2f);
                float shrink = 1f - layer * 0.7f;
                Vector3 p = new Vector3(b.Range(-hx, hx) * shrink, layer * s.size.y * 0.75f, b.Range(-hz, hz) * shrink);
                b.MasonryBox(p + Vector3.up * (sz * 0.3f), new Vector3(sz * b.Range(0.9f, 1.6f), sz * 0.6f, sz), sz * 0.6f, true, false, b.Range(0.6f, 0.9f));
            }
            colliders.Add(new Bounds(new Vector3(0f, s.size.y * 0.35f, 0f), new Vector3(s.size.x * 0.85f, s.size.y * 0.7f, s.size.z * 0.85f)));
        }

        /// <summary>A curved shard of a huge bronze bell, lying on its side with a jagged edge.</summary>
        static void BellFragment(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float R = s.size.x * 0.5f, H = s.size.y;
            const float arc = 1.7f;                 // radians of the bell's circumference
            int rows = Mathf.CeilToInt(H / b.spacing);
            for (int j = 0; j < rows; j++)
            {
                float t = (j + b.Rand()) / rows;
                float r = R * (0.45f + 0.55f * Mathf.Pow(t, 1.6f)) + R * 0.08f * Mathf.Clamp01((t - 0.85f) / 0.15f);
                int around = Mathf.Max(4, Mathf.CeilToInt(arc * r / b.spacing));
                for (int i = 0; i < around; i++)
                {
                    float u = (i + b.Rand()) / around;
                    // jagged broken edges along the sides and the top
                    float edge = 0.08f * Mathf.Sin(t * 37f + s.seed) + 0.06f * Mathf.Sin(t * 71f);
                    if (u < 0.05f + edge || u > 0.95f - edge * 0.7f) continue;
                    if (t < 0.12f + 0.1f * Mathf.Sin(u * 19f + s.seed)) continue;
                    // the shard rests on the floor like a cradle: its outer (convex) side down,
                    // the bell's axis along local X, the inside of the bell facing up
                    float delta = (u - 0.5f) * arc;
                    Vector3 radial = new Vector3(0f, -Mathf.Cos(delta), Mathf.Sin(delta));
                    Vector3 p = new Vector3((t - 0.5f) * H, r + 0.12f, 0f) + radial * r;
                    float lip = t > 0.88f ? 1.15f : 1f;
                    b.Add(p, -radial, 0.95f * lip);                              // inside, facing up
                    b.Add(p + radial * 0.12f, radial, 0.55f * lip, 0.7f);         // outside, facing the floor
                }
            }
            colliders.Add(new Bounds(new Vector3(0f, R * 0.3f, 0f), new Vector3(H, R * 0.6f, R * 1.4f)));
        }
    }
}
