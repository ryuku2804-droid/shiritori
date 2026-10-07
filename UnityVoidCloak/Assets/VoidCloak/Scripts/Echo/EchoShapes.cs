using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// "Listener" body: a blind, hunched monk in a ragged robe with two huge ears.
    /// Local space, feet at y = 0, facing +Z, about 3.9 units tall (a little shorter than the knight).
    /// </summary>
    public static class EchoListenerBody
    {
        public static void Build(EchoPointBuilder b)
        {
            b.spacing = 0.075f;

            // robe: a tube bent forward from the hem to the hunched shoulders, with vertical folds
            b.Tube(new Vector3(0f, 0f, -0.15f), new Vector3(0f, 1.5f, -0.05f), new Vector3(0f, 2.6f, 0.45f), new Vector3(0f, 3.05f, 0.95f),
                   t => Mathf.Lerp(1.0f, 0.48f, Mathf.Pow(t, 0.8f)), 0.85f, 9, 0.08f);
            // ragged hem: a few longer strips hanging lower
            for (int k = 0; k < 7; k++)
            {
                float ang = k / 7f * Mathf.PI * 2f + b.Range(-0.2f, 0.2f);
                Vector3 dir = new Vector3(Mathf.Sin(ang), 0f, Mathf.Cos(ang));
                Vector3 top = dir * 0.95f + new Vector3(0f, 0.5f, -0.15f);
                b.Tube(top, top + dir * 0.05f + Vector3.down * 0.2f, top + dir * 0.12f + Vector3.down * 0.4f, top + dir * 0.18f + Vector3.down * 0.5f,
                       t => 0.09f * (1f - 0.6f * t), 0.7f);
            }

            // head bowed forward inside a small cowl
            Quaternion bow = Quaternion.Euler(25f, 0f, 0f);
            Vector3 head = new Vector3(0f, 3.2f, 1.3f);
            b.Ellipsoid(head, new Vector3(0.42f, 0.48f, 0.52f), bow, 0.9f);

            // the ears: two big thin fans pointing sideways and back
            for (int side = -1; side <= 1; side += 2)
            {
                Quaternion ear = Quaternion.Euler(-10f, side * 25f, side * -28f);
                Vector3 earCenter = head + new Vector3(side * 0.75f, 0.3f, -0.15f);
                b.Ellipsoid(earCenter, new Vector3(0.07f, 0.95f, 0.6f), ear, 1.05f);
                // cartilage ridge along the ear
                b.Tube(earCenter + ear * new Vector3(0.05f, -0.7f, 0.1f), earCenter + ear * new Vector3(0.07f, -0.1f, 0.35f),
                       earCenter + ear * new Vector3(0.07f, 0.5f, 0.25f), earCenter + ear * new Vector3(0.05f, 0.85f, -0.1f),
                       t => 0.05f, 1.1f);
            }

            // long thin arms hanging in front, claw-like hands
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 shoulder = new Vector3(side * 0.45f, 2.8f, 0.85f);
                Vector3 hand = new Vector3(side * 0.38f, 1.35f, 1.55f);
                b.Tube(shoulder, shoulder + new Vector3(side * 0.15f, -0.5f, 0.25f), hand + new Vector3(side * 0.1f, 0.4f, -0.05f), hand,
                       t => Mathf.Lerp(0.14f, 0.07f, t), 0.75f);
                for (int f = 0; f < 3; f++)
                {
                    Vector3 dir = new Vector3(side * (f - 1) * 0.12f, -0.5f, 0.15f);
                    b.Tube(hand, hand + dir * 0.3f, hand + dir * 0.6f, hand + dir * 0.85f + Vector3.forward * 0.08f, t => 0.035f * (1f - 0.7f * t), 0.95f);
                }
            }
        }
    }

    /// <summary>
    /// 「抜け殻の鎧」body: a tall suit of plate armour with nothing inside. The gorget is an
    /// open ring (you can see it is empty), the great helm sits a little crooked, and both
    /// gauntlets hold a great sword point-down in front. Local space, feet at y = 0, facing +Z,
    /// about 4.4 units tall (taller than the knight).
    /// </summary>
    public static class EchoHollowArmorBody
    {
        public static void Build(EchoPointBuilder b)
        {
            b.spacing = 0.075f;

            for (int side = -1; side <= 1; side += 2)
            {
                float x = side * 0.36f;
                // sabaton
                b.Ellipsoid(new Vector3(x, 0.13f, 0.12f), new Vector3(0.2f, 0.13f, 0.4f), Quaternion.identity, 0.9f);
                // greave up to the knee, cuisse up to the hip
                b.Tube(new Vector3(x, 0.22f, 0f), new Vector3(x, 0.6f, 0.02f), new Vector3(x, 1.0f, 0.06f), new Vector3(x, 1.3f, 0.08f),
                       t => Mathf.Lerp(0.17f, 0.2f, t), 0.85f);
                b.Ellipsoid(new Vector3(x, 1.35f, 0.17f), new Vector3(0.19f, 0.17f, 0.16f), Quaternion.identity, 1.05f);   // knee cop
                b.Tube(new Vector3(x, 1.4f, 0.06f), new Vector3(x * 0.95f, 1.7f, 0.04f), new Vector3(x * 0.9f, 1.95f, 0.02f), new Vector3(x * 0.85f, 2.15f, 0f),
                       t => Mathf.Lerp(0.2f, 0.25f, t), 0.85f);
            }

            // faulds and tassets: a stepped skirt of plates
            b.Tube(new Vector3(0f, 1.7f, 0.02f), new Vector3(0f, 1.9f, 0.02f), new Vector3(0f, 2.1f, 0.02f), new Vector3(0f, 2.35f, 0.02f),
                   t => Mathf.Lerp(0.66f, 0.52f, t), 0.9f, 10, 0.04f);
            // breastplate with a centre ridge, backplate
            b.Ellipsoid(new Vector3(0f, 2.85f, 0.04f), new Vector3(0.62f, 0.6f, 0.42f), Quaternion.identity, 0.95f);
            b.Tube(new Vector3(0f, 2.4f, 0.42f), new Vector3(0f, 2.7f, 0.47f), new Vector3(0f, 3.0f, 0.46f), new Vector3(0f, 3.3f, 0.36f),
                   t => 0.03f, 1.15f);
            // gorget: an open ring. Nothing inside.
            b.Disc(new Vector3(0f, 3.45f, 0f), 0.2f, 0.36f, Vector3.up, 1f);
            b.Tube(new Vector3(0f, 3.3f, 0f), new Vector3(0f, 3.35f, 0f), new Vector3(0f, 3.4f, 0f), new Vector3(0f, 3.45f, 0f),
                   t => 0.36f, 0.9f);

            // great helm, sitting a little crooked above the empty collar
            Quaternion tilt = Quaternion.Euler(8f, 0f, -9f);
            Vector3 helm = new Vector3(0.04f, 3.62f, 0.02f);
            b.Tube(helm, helm + tilt * new Vector3(0f, 0.15f, 0f), helm + tilt * new Vector3(0f, 0.32f, 0f), helm + tilt * new Vector3(0f, 0.48f, 0f),
                   t => 0.3f, 0.9f);
            b.Ellipsoid(helm + tilt * new Vector3(0f, 0.5f, 0f), new Vector3(0.3f, 0.2f, 0.3f), tilt, 0.95f);
            // the eye slit: a dark band, brighter rims above and below
            for (int k = -1; k <= 1; k += 2)
            {
                Vector3 c = helm + tilt * new Vector3(0f, 0.3f + k * 0.045f, 0f);
                b.Tube(c + tilt * new Vector3(-0.22f, 0f, 0.22f), c + tilt * new Vector3(-0.08f, 0f, 0.31f), c + tilt * new Vector3(0.08f, 0f, 0.31f), c + tilt * new Vector3(0.22f, 0f, 0.22f),
                       t => 0.018f, 1.25f);
            }

            for (int side = -1; side <= 1; side += 2)
            {
                // pauldron: layered plates over the shoulder
                Quaternion p = Quaternion.Euler(0f, 0f, side * -22f);
                b.Ellipsoid(new Vector3(side * 0.8f, 3.25f, 0f), new Vector3(0.36f, 0.24f, 0.4f), p, 1f);
                b.Ellipsoid(new Vector3(side * 0.9f, 3.05f, 0f), new Vector3(0.3f, 0.18f, 0.34f), p, 0.9f);
            }

            // great sword held point-down in front, both hands on the grip
            Vector3 hilt = new Vector3(0.12f, 2.2f, 0.85f);
            Vector3 point = new Vector3(0.3f, 0.04f, 1.55f);
            Vector3 blade = (point - hilt).normalized;
            Vector3 guard = hilt + blade * 0.15f;
            Quaternion along = Quaternion.FromToRotation(Vector3.up, blade);
            float bladeLength = Vector3.Distance(guard, point);
            b.Ellipsoid(guard + blade * (bladeLength * 0.5f), new Vector3(0.1f, bladeLength * 0.5f, 0.022f), along, 1.2f);
            Vector3 across = Vector3.Cross(blade, Vector3.forward).normalized;
            b.Tube(guard - across * 0.42f, guard - across * 0.15f, guard + across * 0.15f, guard + across * 0.42f, t => 0.045f, 1.1f);
            b.Ellipsoid(hilt - blade * 0.42f, new Vector3(0.07f, 0.07f, 0.07f), Quaternion.identity, 1.1f);   // pommel

            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 shoulder = new Vector3(side * 0.78f, 3.0f, 0f);
                Vector3 elbow = new Vector3(side * 0.82f, 2.3f, 0.3f);
                Vector3 hand = hilt - blade * (side < 0 ? 0.08f : 0.28f) + new Vector3(side * 0.1f, 0f, 0f);
                b.Tube(shoulder, shoulder + new Vector3(0f, -0.25f, 0.05f), elbow + new Vector3(0f, 0.2f, -0.05f), elbow, t => Mathf.Lerp(0.17f, 0.15f, t), 0.85f);
                b.Ellipsoid(elbow, new Vector3(0.16f, 0.16f, 0.16f), Quaternion.identity, 1.05f);   // couter
                b.Tube(elbow, elbow + (hand - elbow) * 0.33f, elbow + (hand - elbow) * 0.66f, hand, t => Mathf.Lerp(0.15f, 0.13f, t), 0.85f);
                b.Ellipsoid(hand, new Vector3(0.14f, 0.12f, 0.15f), Quaternion.identity, 0.95f);    // gauntlet
            }
        }
    }

    /// <summary>
    /// Bell shrine (save point):a stone plinth, two wooden posts, a beam with a small roof,
    /// and a bell hanging from the beam. The bell is a separate mesh so it can swing.
    /// Local space, origin at the bottom centre, open towards +Z.
    /// </summary>
    public static class EchoBellShrineShape
    {
        /// <summary>Where the bell hangs from (local).</summary>
        public static readonly Vector3 BellPivot = new Vector3(0f, 3.6f, 0f);

        public static void BuildFrame(EchoPointBuilder b, List<Bounds> colliders)
        {
            b.spacing = 0.07f;
            b.MasonryBox(new Vector3(0f, 0.2f, 0f), new Vector3(2.6f, 0.4f, 2.0f), 0.4f, true, false, 0.8f);
            for (int side = -1; side <= 1; side += 2)
            {
                Box(b, new Vector3(side * 1.0f, 2.1f, 0f), new Vector3(0.28f, 3.4f, 0.28f), 0.7f);
                colliders.Add(new Bounds(new Vector3(side * 1.0f, 2.1f, 0f), new Vector3(0.3f, 3.4f, 0.3f)));
            }
            Box(b, new Vector3(0f, 3.75f, 0f), new Vector3(2.7f, 0.3f, 0.36f), 0.75f);
            // small pitched roof over the beam
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 eave = new Vector3(-1.5f, 3.95f, side * 0.9f);
                Vector3 up = new Vector3(0f, 0.55f, -side * 0.9f);
                float len = up.magnitude;
                Vector3 normal = new Vector3(0f, 0.9f, side * 0.55f).normalized;
                b.Rect(eave, Vector3.right, up / len, 3.0f, len, normal, 0.6f, 1f, (a, v) => (v % 0.28f) < 0.03f);
            }
            colliders.Add(new Bounds(new Vector3(0f, 0.2f, 0f), new Vector3(2.6f, 0.4f, 2.0f)));
        }

        /// <summary>The bell, hanging down from its pivot (local origin = pivot).</summary>
        public static void BuildBell(EchoPointBuilder b)
        {
            b.spacing = 0.045f;
            const float top = -0.15f, height = 1.0f;
            int rows = Mathf.CeilToInt(height / b.spacing);
            for (int j = 0; j < rows; j++)
            {
                float t = (j + b.Rand()) / rows;                       // 0 = shoulder, 1 = lip
                float r = 0.18f + 0.32f * Mathf.Pow(t, 1.8f) + 0.06f * Mathf.Clamp01((t - 0.85f) / 0.15f);
                float y = top - t * height;
                int around = Mathf.Max(8, Mathf.CeilToInt(2f * Mathf.PI * r / b.spacing));
                float slope = 0.32f * 1.8f * Mathf.Pow(Mathf.Max(t, 1e-3f), 0.8f) / height;
                bool lipBand = t > 0.86f && t < 0.93f;
                for (int i = 0; i < around; i++)
                {
                    float ang = (i + b.Rand()) / around * 2f * Mathf.PI;
                    Vector3 radial = new Vector3(Mathf.Sin(ang), 0f, Mathf.Cos(ang));
                    Vector3 n = (radial + Vector3.up * slope).normalized;
                    b.Add(radial * r + Vector3.up * y, n, lipBand ? 1.15f : 0.95f);
                    if (t > 0.55f) b.Add(radial * (r - 0.05f) + Vector3.up * y, -n, 0.35f, 0.6f);   // dark inside
                }
            }
            b.Ellipsoid(new Vector3(0f, -0.1f, 0f), new Vector3(0.15f, 0.1f, 0.15f), Quaternion.identity, 0.9f);   // crown
            b.Tube(new Vector3(0f, -0.2f, 0f), new Vector3(0f, -0.45f, 0f), new Vector3(0f, -0.75f, 0f), new Vector3(0f, -0.98f, 0f), t => 0.025f, 0.7f);
            b.Ellipsoid(new Vector3(0f, -1.05f, 0f), new Vector3(0.11f, 0.13f, 0.11f), Quaternion.identity, 0.8f);  // clapper
        }

        static void Box(EchoPointBuilder b, Vector3 center, Vector3 size, float bright)
        {
            Vector3 h = size * 0.5f, o = center - h;
            b.Rect(o + new Vector3(0f, 0f, size.z), Vector3.right, Vector3.up, size.x, size.y, Vector3.forward, bright);
            b.Rect(o, Vector3.right, Vector3.up, size.x, size.y, Vector3.back, bright);
            b.Rect(o, Vector3.forward, Vector3.up, size.z, size.y, Vector3.left, bright);
            b.Rect(o + new Vector3(size.x, 0f, 0f), Vector3.forward, Vector3.up, size.z, size.y, Vector3.right, bright);
            b.Rect(o + new Vector3(0f, size.y, 0f), Vector3.right, Vector3.forward, size.x, size.z, Vector3.up, bright);
            b.Rect(o, Vector3.right, Vector3.forward, size.x, size.z, Vector3.down, bright * 0.6f);
        }
    }

    /// <summary>A bell shrine in the prototype stage.</summary>
    public struct EchoShrinePlacement
    {
        public string name;
        public Vector3 position;
        public float yaw;
    }

    /// <summary>One piece in the prototype stage.</summary>
    public struct EchoPiecePlacement
    {
        public string name;
        public Vector3 position;
        public float yaw;
        public EchoKitSpec spec;
        /// <summary>Draw with the gold material (story objects such as the great bell).</summary>
        public bool gold;
    }

    /// <summary>
    /// The prototype stage: a walled courtyard, an arched gate, a colonnade, a round tower,
    /// a raised platform with stairs and some props. The knight starts in the south and
    /// a Listener wanders in the courtyard behind the gate.
    /// </summary>
    public static class EchoPrototypeLayout
    {
        public static readonly Vector3 PlayerSpawn = new Vector3(0f, 0.05f, -18f);
        public static readonly Vector3 ListenerSpawn = new Vector3(4f, 0f, 10f);
        public const float HalfSize = 30f;

        public static List<EchoPiecePlacement> Pieces()
        {
            var list = new List<EchoPiecePlacement>();
            float s = HalfSize;

            Add(list, "Floor", Vector3.zero, 0f, new EchoKitSpec { kind = EchoKitKind.Floor, size = new Vector3(2f * s, 0f, 2f * s), pointSpacing = 0.2f, seed = 1 });

            // outer walls, only the inner face is built
            EchoKitSpec outer = new EchoKitSpec { kind = EchoKitKind.Wall, size = new Vector3(2f * s, 8f, 1.6f), battlements = true, frontOnly = true, pointSpacing = 0.15f };
            Add(list, "Wall North", new Vector3(0f, 0f, s), 180f, With(outer, 11));
            Add(list, "Wall South", new Vector3(0f, 0f, -s), 0f, With(outer, 12));
            Add(list, "Wall East", new Vector3(s, 0f, 0f), -90f, With(outer, 13));
            Add(list, "Wall West", new Vector3(-s, 0f, 0f), 90f, With(outer, 14));

            // inner wall with an arched gate between the entrance yard and the courtyard
            Add(list, "Gate Wall", new Vector3(0f, 0f, -10f), 0f, new EchoKitSpec
            {
                kind = EchoKitKind.ArchWall, size = new Vector3(40f, 9f, 1.8f), openingWidth = 5f, openingHeight = 7f,
                battlements = true, pointSpacing = 0.14f, seed = 21,
            });

            // colonnade on the west side of the courtyard
            for (int i = 0; i < 4; i++)
            {
                Add(list, "Pillar W" + i, new Vector3(-11f, 0f, -3f + i * 7f), 0f, new EchoKitSpec { kind = EchoKitKind.Pillar, size = new Vector3(1.5f, 7.5f, 0f), seed = 30 + i, pointSpacing = 0.11f });
                Add(list, "Pillar E" + i, new Vector3(-5f, 0f, -3f + i * 7f), 0f, new EchoKitSpec { kind = EchoKitKind.Pillar, size = new Vector3(1.5f, 7.5f, 0f), seed = 40 + i, pointSpacing = 0.11f });
            }

            // round tower in the north-east corner, door facing the courtyard
            Add(list, "Tower", new Vector3(17f, 0f, 15f), 225f, new EchoKitSpec { kind = EchoKitKind.Tower, size = new Vector3(8f, 14f, 0f), roofHeight = 7f, seed = 50, pointSpacing = 0.13f });

            // raised platform with stairs in the north-west
            Add(list, "Platform", new Vector3(-20f, 0f, 21f), 0f, new EchoKitSpec { kind = EchoKitKind.Platform, size = new Vector3(12f, 2.4f, 10f), seed = 60, pointSpacing = 0.13f });
            Add(list, "Stairs", new Vector3(-20f, 0f, 14f), 0f, new EchoKitSpec { kind = EchoKitKind.Stairs, size = new Vector3(5f, 2.4f, 4f), steps = 6, seed = 61, pointSpacing = 0.11f });

            // props in the entrance yard
            Add(list, "Crate 1", new Vector3(9f, 0f, -21f), 12f, new EchoKitSpec { kind = EchoKitKind.Crate, size = new Vector3(1.6f, 1.6f, 1.6f), seed = 70, pointSpacing = 0.09f });
            Add(list, "Crate 2", new Vector3(10.9f, 0f, -20.2f), -8f, new EchoKitSpec { kind = EchoKitKind.Crate, size = new Vector3(1.4f, 1.4f, 1.4f), seed = 71, pointSpacing = 0.09f });
            Add(list, "Barrel 1", new Vector3(-8f, 0f, -23f), 0f, new EchoKitSpec { kind = EchoKitKind.Barrel, size = new Vector3(1.3f, 1.8f, 0f), seed = 72, pointSpacing = 0.08f });
            Add(list, "Barrel 2", new Vector3(-6.6f, 0f, -22.2f), 40f, new EchoKitSpec { kind = EchoKitKind.Barrel, size = new Vector3(1.3f, 1.8f, 0f), seed = 73, pointSpacing = 0.08f });
            Add(list, "Barrel 3", new Vector3(-7.5f, 0f, -21.0f), 80f, new EchoKitSpec { kind = EchoKitKind.Barrel, size = new Vector3(1.2f, 1.6f, 0f), seed = 74, pointSpacing = 0.08f });

            // a short broken wall in the courtyard to hide behind
            Add(list, "Low Wall", new Vector3(6f, 0f, 2f), 20f, new EchoKitSpec { kind = EchoKitKind.Wall, size = new Vector3(7f, 2.6f, 1.0f), seed = 80, pointSpacing = 0.12f });
            return list;
        }

        /// <summary>Bell shrines (save points): one near the start, one on top of the platform.</summary>
        public static List<EchoShrinePlacement> Shrines()
        {
            return new List<EchoShrinePlacement>
            {
                new EchoShrinePlacement { name = "Bell Shrine (Start)", position = new Vector3(-5f, 0f, -15f), yaw = 35f },
                new EchoShrinePlacement { name = "Bell Shrine (Platform)", position = new Vector3(-20f, 2.4f, 23.5f), yaw = 180f },
            };
        }

        static EchoKitSpec With(EchoKitSpec spec, int seed)
        {
            EchoKitSpec c = spec.Clone();
            c.seed = seed;
            return c;
        }

        static void Add(List<EchoPiecePlacement> list, string name, Vector3 position, float yaw, EchoKitSpec spec)
        {
            list.Add(new EchoPiecePlacement { name = name, position = position, yaw = yaw, spec = spec });
        }
    }
}
