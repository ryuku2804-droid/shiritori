using System;
using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>Town pieces for chapter 1: houses, a well and market stalls.</summary>
    public static partial class EchoKitGenerator
    {
        /// <summary>A hole in a wall face, in face coordinates (a along the face, y up).</summary>
        struct Opening
        {
            public float a0, a1, y0, y1;
            public bool roundTop;

            public bool Contains(float a, float y)
            {
                if (a < a0 || a > a1 || y < y0) return false;
                if (!roundTop) return y < y1;
                float r = (a1 - a0) * 0.5f, spring = y1 - r;
                if (y < spring) return true;
                float dx = a - (a0 + a1) * 0.5f, dy = y - spring;
                return dx * dx + dy * dy < r * r;
            }
        }

        static bool InAny(List<Opening> list, float a, float y)
        {
            for (int i = 0; i < list.Count; i++) if (list[i].Contains(a, y)) return true;
            return false;
        }

        // ---------------------------------------------------------------- house

        const float HouseDoorWidth = 2.6f, HouseDoorHeight = 4.8f;

        /// <summary>Windows along one face: an upper row, and (on the front of wide houses) a ground row beside the door.</summary>
        static List<Opening> HouseOpenings(float faceWidth, float h, bool front, bool door)
        {
            var list = new List<Opening>();
            float centre = faceWidth * 0.5f;
            if (front && door)
                list.Add(new Opening { a0 = centre - HouseDoorWidth * 0.5f, a1 = centre + HouseDoorWidth * 0.5f, y0 = 0f, y1 = HouseDoorHeight, roundTop = true });

            int count = Mathf.Max(1, Mathf.FloorToInt(faceWidth / 3.4f));
            float upper0 = Mathf.Max(HouseDoorHeight + 1.2f, h * 0.58f);
            for (int i = 0; i < count; i++)
            {
                float c = faceWidth * (i + 0.5f) / count;
                if (upper0 + 1.9f < h - 0.5f)
                    list.Add(new Opening { a0 = c - 0.6f, a1 = c + 0.6f, y0 = upper0, y1 = upper0 + 1.9f, roundTop = false });
                bool besideDoor = Mathf.Abs(c - centre) > HouseDoorWidth * 0.5f + 1.2f;
                if (front && faceWidth > 8f && besideDoor)
                    list.Add(new Opening { a0 = c - 0.55f, a1 = c + 0.55f, y0 = 1.7f, y1 = 3.4f, roundTop = false });
            }
            return list;
        }

        /// <summary>
        /// Builds one masonry face with its openings: dark recesses behind the windows, a stone
        /// sill under each, and (for a closed house) a plank door in the doorway.
        /// origin = bottom-left corner seen from outside, u = along the face, n = outwards.
        /// </summary>
        static void HouseFace(EchoPointBuilder b, Vector3 origin, Vector3 u, Vector3 n, float w, float h, float sh,
                              List<Opening> openings, Func<float, float, bool> extraHole, bool closedDoor)
        {
            Func<float, float, bool> hole = (a, y) => InAny(openings, a, y) || (extraHole != null && extraHole(a, y));
            b.Masonry(origin, u, Vector3.up, n, w, h, sh, sh * 1.3f, sh * 2.8f, hole);
            foreach (Opening o in openings)
            {
                bool isDoor = o.roundTop;
                if (isDoor && !closedDoor) continue;
                // the recess: a dark back face a little inside the wall
                float depth = isDoor ? 0.3f : 0.45f;
                Vector3 back = origin + u * o.a0 + Vector3.up * o.y0 - n * depth;
                float ow = o.a1 - o.a0, oh = o.y1 - o.y0;
                if (isDoor)
                {
                    // vertical planks with dark grooves, an iron ring
                    b.Rect(back, u, Vector3.up, ow, oh, n, 0.32f, 0.8f,
                           (a, y) => !o.Contains(o.a0 + a, o.y0 + y) || ((a / 0.38f) % 1f) < 0.1f);
                    float jamb = oh - ow * 0.5f;
                    b.Rect(origin + u * o.a0, -n, Vector3.up, depth, jamb, u, 0.55f);
                    b.Rect(origin + u * o.a1, -n, Vector3.up, depth, jamb, -u, 0.55f);
                    b.Ellipsoid(back + u * (ow * 0.75f) + Vector3.up * 2.2f + n * 0.05f, new Vector3(0.08f, 0.08f, 0.08f), Quaternion.identity, 1.1f);
                }
                else
                {
                    b.Rect(back, u, Vector3.up, ow, oh, n, 0.12f, 0.5f);
                    // jambs (the sides of the window opening) so the hole reads as deep
                    b.Rect(origin + u * o.a0 + Vector3.up * o.y0, -n, Vector3.up, depth, oh, u, 0.45f);
                    b.Rect(origin + u * o.a1 + Vector3.up * o.y0, -n, Vector3.up, depth, oh, -u, 0.45f);
                    // sill
                    Vector3 sill = origin + u * ((o.a0 + o.a1) * 0.5f) + Vector3.up * (o.y0 - 0.12f) + n * 0.1f;
                    b.Rect(sill - u * (ow * 0.5f + 0.15f) - n * 0.25f, u, n, ow + 0.3f, 0.45f, Vector3.up, 0.9f);
                }
            }
        }

        static void House(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float w = s.size.x, h = s.size.y, d = s.size.z, sh = s.stoneHeight;
            if (s.ruined)
            {
                RuinedHouse(s, b, colliders);
                return;
            }
            float rh = s.roofHeight;
            Func<float, float, bool> gable = (a, y) => y > h && (y - h) > rh * (1f - Mathf.Abs(a - d * 0.5f) / (d * 0.5f));

            HouseFace(b, new Vector3(-w * 0.5f, 0f, d * 0.5f), Vector3.right, Vector3.forward, w, h, sh, HouseOpenings(w, h, true, s.door), null, true);
            if (!s.frontOnly)   // row houses: nobody ever sees the back
                HouseFace(b, new Vector3(w * 0.5f, 0f, -d * 0.5f), Vector3.left, Vector3.back, w, h, sh, HouseOpenings(w, h, false, false), null, true);
            // side walls rise into the gable triangles
            HouseFace(b, new Vector3(w * 0.5f, 0f, d * 0.5f), Vector3.back, Vector3.right, d, h + rh, sh, HouseOpenings(d, h, false, false), gable, true);
            HouseFace(b, new Vector3(-w * 0.5f, 0f, -d * 0.5f), Vector3.forward, Vector3.left, d, h + rh, sh, HouseOpenings(d, h, false, false), gable, true);

            // a projecting band of stones between the floors
            float band = Mathf.Max(h * 0.5f, HouseDoorHeight + 0.5f);
            if (band < h - 0.6f)
                b.MasonryBox(new Vector3(0f, band, 0f), new Vector3(w + 0.3f, 0.3f, d + 0.3f), 0.3f, false, false, 0.85f);

            GableRoof(b, w, d, h, rh, 0.75f, s.frontOnly);
            // chimney through the back slope
            float cx = (b.Rand() < 0.5f ? -1f : 1f) * w * 0.25f;
            float roofAtChimney = h + rh * (1f - 0.3f / 0.5f);
            b.MasonryBox(new Vector3(cx, roofAtChimney + 0.6f, -d * 0.15f), new Vector3(1.0f, 2.4f, 1.0f), 0.4f, true, false, 0.8f);

            colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, 0f), new Vector3(w, h, d)));
        }

        /// <summary>Two shingled slopes, ridge along X, eaves overhanging the walls.</summary>
        static void GableRoof(EchoPointBuilder b, float w, float d, float baseY, float rh, float brightness, bool frontSlopeOnly = false)
        {
            const float over = 0.6f, rowLength = 0.5f, tab = 0.5f;
            float W = w + over * 2f, halfD = d * 0.5f;
            float slope = rh / halfD;
            float eaveZ = halfD + over, eaveY = baseY - over * slope;
            for (int side = frontSlopeOnly ? 1 : -1; side <= 1; side += 2)
            {
                Vector3 eave = new Vector3(-W * 0.5f, eaveY, side * eaveZ);
                Vector3 ridge = new Vector3(-W * 0.5f, baseY + rh, 0f);
                Vector3 t = ridge - eave;
                float L = t.magnitude;
                t /= L;
                Vector3 n = side > 0 ? Vector3.Cross(Vector3.right, t) : Vector3.Cross(t, Vector3.right);
                int rows = Mathf.Max(1, Mathf.RoundToInt(L / rowLength));
                int nAround = Mathf.Max(2, Mathf.CeilToInt(W / b.spacing));
                int nAlong = Mathf.Max(1, Mathf.CeilToInt(rowLength / b.spacing));
                for (int r = 0; r < rows; r++)
                {
                    float stagger = (r % 2) * 0.5f;
                    for (int j = 0; j < nAlong; j++)
                    {
                        for (int i = 0; i < nAround; i++)
                        {
                            float tt = (j + b.Rand()) / nAlong;                 // 0 = lower edge of the row
                            float along = (r + tt) / rows * L;
                            float x = (i + b.Rand()) / nAround * W;
                            float inTab = (x / tab + stagger) % 1f;
                            if (inTab > 0.92f && tt < 0.6f) continue;           // gap between shingles
                            Vector3 p = eave + Vector3.right * x + t * along + n * (0.07f * (1f - tt));
                            b.Add(p, n, brightness * b.Range(0.75f, 1f) * (0.75f + 0.25f * tt), 0.55f + 0.45f * tt);
                        }
                    }
                }
                // underside of the eaves, so the overhang reads from below
                b.Rect(eave, Vector3.right, t, W, over / Mathf.Sqrt(Mathf.Max(0.05f, 1f - t.y * t.y)), -n, 0.35f);
            }
            // ridge beam
            b.Tube(new Vector3(-W * 0.5f, baseY + rh + 0.05f, 0f), new Vector3(-W / 6f, baseY + rh + 0.05f, 0f),
                   new Vector3(W / 6f, baseY + rh + 0.05f, 0f), new Vector3(W * 0.5f, baseY + rh + 0.05f, 0f), x => 0.12f, 0.8f);
        }

        /// <summary>
        /// Burnt-out house: no roof, jagged wall tops, inner faces, a floor, rubble and a fallen
        /// beam inside. The doorway is open, so it can be used to hide in.
        /// </summary>
        static void RuinedHouse(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float w = s.size.x, h = s.size.y, d = s.size.z, sh = s.stoneHeight;
            const float t = 0.8f;
            int seed = s.seed;
            Func<float, float, float> broken = (a, face) =>
            {
                float u = a * 0.45f + face * 3.1f + seed;
                float big = 0.5f + 0.3f * Mathf.Sin(u) + 0.2f * Mathf.Sin(u * 2.3f + 1.7f);
                float teeth = 0.06f * Mathf.Sin(u * 11f) + 0.04f * Mathf.Sin(u * 23f);
                return h * Mathf.Clamp(0.4f + 0.6f * big + teeth, 0.3f, 1f);
            };

            // outer and inner faces of the four walls: (origin, u, n, width, face id)
            var faces = new[]
            {
                (new Vector3(-w * 0.5f, 0f, d * 0.5f), Vector3.right, Vector3.forward, w, 0),
                (new Vector3(w * 0.5f, 0f, -d * 0.5f), Vector3.left, Vector3.back, w, 1),
                (new Vector3(w * 0.5f, 0f, d * 0.5f), Vector3.back, Vector3.right, d, 2),
                (new Vector3(-w * 0.5f, 0f, -d * 0.5f), Vector3.forward, Vector3.left, d, 3),
            };
            foreach (var f in faces)
            {
                Vector3 origin = f.Item1, u = f.Item2, n = f.Item3;
                float fw = f.Item4;
                int id = f.Item5;
                List<Opening> openings = HouseOpenings(fw, h, id == 0, id == 0 && s.door);
                Func<float, float, bool> top = (a, y) => y > broken(a, id);
                HouseFace(b, origin, u, n, fw, h, sh, openings, top, false);
                // inner face, inset by the wall thickness (the openings line up)
                Vector3 inner = origin - n * t + u * t;
                float iw = fw - 2f * t;
                Func<float, float, bool> innerHole = (a, y) => InAny(openings, a + t, y) || y > broken(a + t, id);
                b.Masonry(inner, u, Vector3.up, -n, iw, h, sh, sh * 1.3f, sh * 2.8f, innerHole, 0.07f, 0.05f, 0.7f);
                // rough stones along the broken top
                int nTop = Mathf.CeilToInt(fw / b.spacing) * 2;
                for (int i = 0; i < nTop; i++)
                {
                    float a = b.Rand() * fw;
                    if (InAny(openings, a, broken(a, id) - 0.2f)) continue;
                    b.Add(origin + u * a - n * (b.Rand() * t) + Vector3.up * (broken(a, id) + b.Range(-0.1f, 0.12f)),
                          Vector3.up + n * b.Range(-0.4f, 0.4f), b.Range(0.6f, 0.95f));
                }
                // door jambs through the wall thickness
                foreach (Opening o in openings)
                {
                    if (!o.roundTop) continue;
                    b.Rect(origin + u * o.a0, -n, Vector3.up, t, o.y1 - (o.a1 - o.a0) * 0.5f, u, 0.6f);
                    b.Rect(origin + u * o.a1, -n, Vector3.up, t, o.y1 - (o.a1 - o.a0) * 0.5f, -u, 0.6f);
                }
            }

            // floor, ash and rubble, and a roof beam that fell in
            Flagstones(b, -w * 0.5f + t, w * 0.5f - t, -d * 0.5f + t, d * 0.5f - t, 0f, 0.5f);
            for (int k = 0; k < 6; k++)
            {
                float px = b.Range(-w * 0.5f + t + 0.8f, w * 0.5f - t - 0.8f);
                float pz = b.Range(-d * 0.5f + t + 0.8f, -0.5f);   // keep the area behind the door clear
                float sz = b.Range(0.4f, 0.9f);
                b.MasonryBox(new Vector3(px, sz * 0.3f, pz), new Vector3(sz * 1.4f, sz * 0.6f, sz), sz * 0.6f, true, false, 0.7f);
            }
            Vector3 beamA = new Vector3(-w * 0.5f + t + 0.3f, h * 0.45f, -d * 0.5f + t + 0.4f);
            Vector3 beamB = new Vector3(w * 0.25f, 0.2f, -d * 0.5f + t + 1.2f);
            b.Tube(beamA, Vector3.Lerp(beamA, beamB, 0.33f), Vector3.Lerp(beamA, beamB, 0.66f), beamB, x => 0.2f, 0.45f);

            // collision: four walls with a gap at the door, and the floor
            float sideW = (w - HouseDoorWidth) * 0.5f;
            if (s.door)
            {
                colliders.Add(new Bounds(new Vector3(-w * 0.5f + sideW * 0.5f, h * 0.5f, d * 0.5f - t * 0.5f), new Vector3(sideW, h, t)));
                colliders.Add(new Bounds(new Vector3(w * 0.5f - sideW * 0.5f, h * 0.5f, d * 0.5f - t * 0.5f), new Vector3(sideW, h, t)));
                colliders.Add(new Bounds(new Vector3(0f, (HouseDoorHeight + h) * 0.5f, d * 0.5f - t * 0.5f), new Vector3(HouseDoorWidth, h - HouseDoorHeight, t)));
            }
            else
            {
                colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, d * 0.5f - t * 0.5f), new Vector3(w, h, t)));
            }
            colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, -d * 0.5f + t * 0.5f), new Vector3(w, h, t)));
            colliders.Add(new Bounds(new Vector3(w * 0.5f - t * 0.5f, h * 0.5f, 0f), new Vector3(t, h, d)));
            colliders.Add(new Bounds(new Vector3(-w * 0.5f + t * 0.5f, h * 0.5f, 0f), new Vector3(t, h, d)));
            colliders.Add(new Bounds(new Vector3(0f, -0.5f, 0f), new Vector3(w, 1f, d)));
        }

        // ---------------------------------------------------------------- well

        static void Well(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float r = s.size.x * 0.5f, h = s.size.y;
            const float t = 0.4f;
            b.MasonryCylinder(Vector3.zero, r, h, 0.35f, 0.6f, 1.1f);
            int before = b.Count;
            b.MasonryCylinder(Vector3.zero, r - t, h, 0.35f, 0.5f, 0.9f, null, 0.6f);
            for (int i = before; i < b.Count; i++)
            {
                Vector3 nn = b.normals[i];
                b.normals[i] = new Vector3(-nn.x, nn.y, -nn.z);
            }
            b.Disc(new Vector3(0f, h, 0f), r - t, r + 0.05f, Vector3.up, 0.9f);
            b.Disc(new Vector3(0f, h - 0.9f, 0f), 0f, r - t, Vector3.up, 0.08f);   // black water far below

            // two posts, a beam with a winch, a little roof, rope and bucket
            float postX = r - 0.2f, top = h + 2.6f;
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 foot = new Vector3(side * postX, h, 0f);
                b.Tube(foot, foot + Vector3.up * 0.9f, foot + Vector3.up * 1.8f, foot + Vector3.up * 2.75f, x => 0.12f, 0.6f);
            }
            b.Tube(new Vector3(-postX - 0.2f, top, 0f), new Vector3(-0.3f, top, 0f), new Vector3(0.3f, top, 0f), new Vector3(postX + 0.2f, top, 0f), x => 0.14f, 0.65f);
            GableRoof(b, 2f * postX, 1.6f, top + 0.25f, 0.8f, 0.7f);
            b.Tube(new Vector3(0.1f, top - 0.1f, 0f), new Vector3(0.1f, top - 0.6f, 0f), new Vector3(0.1f, h + 0.9f, 0f), new Vector3(0.1f, h + 0.55f, 0f), x => 0.025f, 0.8f);
            b.Tube(new Vector3(0.1f, h + 0.1f, 0f), new Vector3(0.1f, h + 0.2f, 0f), new Vector3(0.1f, h + 0.4f, 0f), new Vector3(0.1f, h + 0.55f, 0f), x => 0.24f + 0.04f * x, 0.55f);

            colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, 0f), new Vector3(2f * r, h, 2f * r)));
            for (int side = -1; side <= 1; side += 2)
                colliders.Add(new Bounds(new Vector3(side * postX, h + 1.4f, 0f), new Vector3(0.3f, 2.8f, 0.3f)));
        }

        // ---------------------------------------------------------------- market stall

        static void Stall(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float w = s.size.x, h = s.size.y, d = s.size.z;
            const float counterH = 1.3f, counterD = 0.9f;
            float cz = d * 0.5f - counterD * 0.5f;

            // the counter: a plank box
            const float plank = 0.3f, groove = 0.03f;
            Func<float, float, bool> grooves = (a, y) => (y % plank) < groove;
            float hx = w * 0.5f, hz = counterD * 0.5f;
            Vector3 c0 = new Vector3(0f, 0f, cz);
            PlankFace(b, c0 + new Vector3(-hx, 0f, hz), Vector3.right, Vector3.up, Vector3.forward, w, counterH, grooves, 0.5f);
            PlankFace(b, c0 + new Vector3(hx, 0f, -hz), Vector3.left, Vector3.up, Vector3.back, w, counterH, grooves, 0.45f);
            PlankFace(b, c0 + new Vector3(hx, 0f, hz), Vector3.back, Vector3.up, Vector3.right, counterD, counterH, grooves, 0.5f);
            PlankFace(b, c0 + new Vector3(-hx, 0f, -hz), Vector3.forward, Vector3.up, Vector3.left, counterD, counterH, grooves, 0.5f);
            PlankFace(b, c0 + new Vector3(-hx, counterH, -hz), Vector3.right, Vector3.forward, Vector3.up, w, counterD, (a, y) => (a % plank) < groove, 0.55f);

            // posts: taller at the back so the awning slopes down to the front
            float front = h - 0.4f, back = h + 0.4f;
            for (int sx = -1; sx <= 1; sx += 2)
            {
                for (int sz = -1; sz <= 1; sz += 2)
                {
                    float top = sz > 0 ? front : back;
                    Vector3 foot = new Vector3(sx * (hx - 0.1f), 0f, sz * (d * 0.5f - 0.1f));
                    b.Tube(foot, foot + Vector3.up * top * 0.33f, foot + Vector3.up * top * 0.66f, foot + Vector3.up * top, x => 0.08f, 0.55f);
                    colliders.Add(new Bounds(foot + Vector3.up * (top * 0.5f), new Vector3(0.25f, top, 0.25f)));
                }
            }

            // torn cloth awning, sagging between the posts, ragged at the front
            float aw = w + 0.4f, ad = d + 0.8f;
            int nu = Mathf.CeilToInt(aw / b.spacing), nv = Mathf.CeilToInt(ad / b.spacing);
            int tearSeed = s.seed;
            for (int j = 0; j < nv; j++)
            {
                for (int i = 0; i < nu; i++)
                {
                    float u = (i + b.Rand()) / nu, v = (j + b.Rand()) / nv;   // v = 0 back, 1 front
                    float x = (u - 0.5f) * aw;
                    float ragged = 0.92f - 0.12f * Mathf.Abs(Mathf.Sin(x * 3.1f + tearSeed)) - 0.06f * Mathf.Sin(x * 7.3f);
                    if (v > ragged) continue;
                    // a few holes burnt through
                    float hole = Mathf.Sin(x * 1.7f + tearSeed) * Mathf.Sin(v * 9f + tearSeed * 0.3f);
                    if (hole > 0.82f) continue;
                    float z = (v - 0.5f) * ad;
                    float y = Mathf.Lerp(back, front, v) + 0.05f - 0.25f * Mathf.Sin(Mathf.PI * u) * Mathf.Sin(Mathf.PI * Mathf.Clamp01(v * 1.1f));
                    float wave = 0.04f * Mathf.Sin(x * 5f + v * 3f);
                    b.Add(new Vector3(x, y + wave, z), new Vector3(0f, 1f, 0.8f / Mathf.Max(0.5f, ad) * 1.2f), b.Range(0.45f, 0.6f), 0.85f);
                }
            }

            // a few jars and a sack left on the counter
            int jars = Mathf.Max(2, Mathf.RoundToInt(w / 1.2f));
            for (int k = 0; k < jars; k++)
            {
                float x = b.Range(-hx + 0.4f, hx - 0.4f);
                float rr = b.Range(0.16f, 0.26f);
                b.Ellipsoid(new Vector3(x, counterH + rr * 1.2f, cz + b.Range(-0.2f, 0.2f)), new Vector3(rr, rr * 1.3f, rr), Quaternion.identity, 0.7f);
            }
            b.Ellipsoid(new Vector3(hx - 0.6f, 0.45f, cz - counterD - 0.3f), new Vector3(0.45f, 0.45f, 0.4f), Quaternion.Euler(0f, 0f, 15f), 0.5f);

            colliders.Add(new Bounds(new Vector3(0f, counterH * 0.5f, cz), new Vector3(w, counterH, counterD)));
        }
    }
}
