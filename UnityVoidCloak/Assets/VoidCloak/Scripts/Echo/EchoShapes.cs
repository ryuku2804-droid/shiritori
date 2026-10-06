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

    /// <summary>One piece in the prototype stage.</summary>
    public struct EchoPiecePlacement
    {
        public string name;
        public Vector3 position;
        public float yaw;
        public EchoKitSpec spec;
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
