using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// The Silent Knight: the plate armour of a bell keeper with a long torn cloak and a crest on
    /// the helm. Local space, feet at y = 0, facing +Z.
    /// </summary>
    public static class EchoSilentKnightBody
    {
        public static void Build(EchoPointBuilder b)
        {
            EchoHollowArmorBody.Build(b);
            b.spacing = 0.075f;
            // torn cloak hanging from the shoulders down the back
            const float top = 3.25f;
            int rows = Mathf.CeilToInt(top / b.spacing);
            for (int j = 0; j < rows; j++)
            {
                float y = top - (j + b.Rand()) / rows * top;
                float t = 1f - y / top;                                   // 0 at the shoulders, 1 at the floor
                float radius = Mathf.Lerp(0.6f, 1.15f, t);
                int around = Mathf.CeilToInt(Mathf.PI * radius * 1.1f / b.spacing);
                for (int i = 0; i < around; i++)
                {
                    float a = Mathf.Lerp(0.55f, 2.6f, (i + b.Rand()) / around) + Mathf.PI * 0.5f;   // the back half
                    float rag = 0.25f + 0.2f * Mathf.Sin(a * 7f) + 0.1f * Mathf.Sin(a * 17f + 1f);
                    if (y < rag) continue;                                 // ragged hem
                    if (Mathf.Sin(a * 5f + y * 3f) * Mathf.Sin(y * 7f) > 0.88f) continue;   // holes
                    float fold = 0.06f * Mathf.Sin(a * 9f) * t;
                    Vector3 radial = new Vector3(Mathf.Cos(a), 0f, Mathf.Sin(a));
                    Vector3 p = new Vector3(0f, y, -0.15f) + radial * (radius + fold);
                    b.Add(p, radial, b.Range(0.6f, 0.85f), 0.8f);
                }
            }
            // a crest along the helm, front to back
            Vector3 c = new Vector3(0.04f, 4.18f, 0.02f);
            b.Tube(c + new Vector3(0f, 0f, 0.3f), c + new Vector3(0f, 0.25f, 0.15f), c + new Vector3(0f, 0.3f, -0.2f), c + new Vector3(0f, 0.05f, -0.55f),
                   t => 0.07f * (1f - 0.5f * t), 1.15f);
        }
    }

    /// <summary>Poses of the figures in an echo theatre.</summary>
    public enum EchoFigurePose
    {
        None,
        KnightSwordDown,
        KnightSwordRaised,
        KnightSwordSwung,
        Kneel,
        Robed,
        RobedArmsUp,
        Child,
        ChildKneel,
        GreatBell,
    }

    /// <summary>
    /// Figures for the echo theatres (残響劇): a cloaked knight with a sword in three poses,
    /// robed townsfolk, a child, a kneeling figure and the great bell as it hung before it broke.
    /// Local space, feet at y = 0, facing +Z, people about 4 units tall.
    /// </summary>
    public static class EchoFigureBody
    {
        public static void Build(EchoPointBuilder b, EchoFigurePose pose)
        {
            b.spacing = 0.075f;
            int start = b.Count;
            switch (pose)
            {
                case EchoFigurePose.KnightSwordDown:
                case EchoFigurePose.KnightSwordRaised:
                case EchoFigurePose.KnightSwordSwung:
                    Knight(b, pose);
                    break;
                case EchoFigurePose.Kneel:
                    EchoGhostBody.Build(b);
                    break;
                case EchoFigurePose.Robed:
                case EchoFigurePose.RobedArmsUp:
                    Robed(b, pose == EchoFigurePose.RobedArmsUp);
                    break;
                case EchoFigurePose.Child:
                    Robed(b, false);
                    Scale(b, start, 0.6f);
                    break;
                case EchoFigurePose.ChildKneel:
                    EchoGhostBody.Build(b);
                    Scale(b, start, 0.62f);
                    break;
                case EchoFigurePose.GreatBell:
                    GreatBell(b);
                    break;
            }
        }

        static void Scale(EchoPointBuilder b, int start, float s)
        {
            for (int i = start; i < b.Count; i++) b.positions[i] = b.positions[i] * s;
        }

        static void Knight(EchoPointBuilder b, EchoFigurePose pose)
        {
            // legs, body under a cloak, hooded head
            for (int side = -1; side <= 1; side += 2)
                b.Tube(new Vector3(side * 0.22f, 0.05f, 0.05f), new Vector3(side * 0.23f, 0.7f, 0.02f), new Vector3(side * 0.24f, 1.3f, 0f), new Vector3(side * 0.24f, 1.9f, 0f),
                       t => Mathf.Lerp(0.14f, 0.19f, t), 0.75f);
            b.Tube(new Vector3(0f, 1.75f, 0f), new Vector3(0f, 2.3f, 0.02f), new Vector3(0f, 2.8f, 0.02f), new Vector3(0f, 3.25f, 0f),
                   t => Mathf.Lerp(0.42f, 0.36f, t), 0.85f);
            b.Tube(new Vector3(0f, 3.2f, -0.1f), new Vector3(0f, 2.2f, -0.25f), new Vector3(0f, 1.0f, -0.35f), new Vector3(0f, 0.15f, -0.4f),
                   t => Mathf.Lerp(0.5f, 0.85f, t), 0.7f, 7, 0.05f);
            b.Ellipsoid(new Vector3(0f, 3.62f, 0.02f), new Vector3(0.3f, 0.36f, 0.33f), Quaternion.identity, 0.9f);

            Vector3 hands, tip;
            switch (pose)
            {
                case EchoFigurePose.KnightSwordRaised:
                    hands = new Vector3(0.1f, 4.5f, 0.15f);
                    tip = new Vector3(0.1f, 6.1f, -0.7f);
                    break;
                case EchoFigurePose.KnightSwordSwung:
                    hands = new Vector3(0.1f, 2.1f, 1.15f);
                    tip = new Vector3(0.15f, 0.5f, 2.7f);
                    break;
                default:
                    hands = new Vector3(0.55f, 1.95f, 0.35f);
                    tip = new Vector3(0.75f, 0.25f, 1.0f);
                    break;
            }
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 shoulder = new Vector3(side * 0.45f, 3.1f, 0f);
                Vector3 hand = pose == EchoFigurePose.KnightSwordDown && side < 0 ? new Vector3(-0.5f, 1.9f, 0.1f) : hands + new Vector3(side * 0.08f, 0f, 0f);
                b.Tube(shoulder, Vector3.Lerp(shoulder, hand, 0.33f) + new Vector3(side * 0.15f, -0.1f, 0f), Vector3.Lerp(shoulder, hand, 0.66f) + new Vector3(side * 0.1f, 0f, 0f), hand,
                       t => Mathf.Lerp(0.13f, 0.1f, t), 0.8f);
            }
            Vector3 blade = (tip - hands).normalized;
            float length = Vector3.Distance(hands, tip);
            b.Ellipsoid(hands + blade * (length * 0.55f), new Vector3(0.08f, length * 0.45f, 0.02f), Quaternion.FromToRotation(Vector3.up, blade), 1.2f);
            Vector3 across = Vector3.Cross(blade, Vector3.forward).sqrMagnitude > 0.01f ? Vector3.Cross(blade, Vector3.forward).normalized : Vector3.right;
            Vector3 guard = hands + blade * 0.12f;
            b.Tube(guard - across * 0.3f, guard - across * 0.1f, guard + across * 0.1f, guard + across * 0.3f, t => 0.035f, 1.1f);
        }

        static void Robed(EchoPointBuilder b, bool armsUp)
        {
            b.Tube(new Vector3(0f, 0.02f, 0f), new Vector3(0f, 1.2f, 0f), new Vector3(0f, 2.4f, 0.02f), new Vector3(0f, 3.25f, 0.05f),
                   t => Mathf.Lerp(0.85f, 0.38f, Mathf.Pow(t, 0.8f)), 0.8f, 8, 0.06f);
            b.Ellipsoid(new Vector3(0f, 3.55f, 0.1f), new Vector3(0.3f, 0.34f, 0.33f), Quaternion.Euler(10f, 0f, 0f), 0.9f);
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 shoulder = new Vector3(side * 0.42f, 3.05f, 0.05f);
                Vector3 hand = armsUp ? new Vector3(side * 0.55f, 4.3f, 0.6f) : new Vector3(side * 0.55f, 1.75f, 0.25f);
                b.Tube(shoulder, Vector3.Lerp(shoulder, hand, 0.33f) + new Vector3(side * 0.12f, 0f, 0f), Vector3.Lerp(shoulder, hand, 0.66f) + new Vector3(side * 0.1f, 0f, 0f), hand,
                       t => Mathf.Lerp(0.16f, 0.1f, t), 0.75f);
            }
        }

        /// <summary>The great bell 〈暁鐘〉 hanging whole, as it was before it broke: lip at y = 4.5.</summary>
        static void GreatBell(EchoPointBuilder b)
        {
            b.spacing = 0.11f;
            b.Tube(new Vector3(0f, 8.6f, 0f), new Vector3(0f, 7.4f, 0f), new Vector3(0f, 5.8f, 0f), new Vector3(0f, 4.5f, 0f),
                   t => 1.5f + 1.5f * t * t, 1.05f);
            b.Ellipsoid(new Vector3(0f, 8.6f, 0f), new Vector3(1.55f, 0.6f, 1.55f), Quaternion.identity, 1f);
            b.Disc(new Vector3(0f, 4.5f, 0f), 2.6f, 3.05f, Vector3.down, 1.1f);
            // a band cast round the waist
            b.Tube(new Vector3(0f, 6.32f, 0f), new Vector3(0f, 6.27f, 0f), new Vector3(0f, 6.18f, 0f), new Vector3(0f, 6.12f, 0f), t => 2.09f, 1.25f);
            // the beam it hangs from
            b.Tube(new Vector3(-4.5f, 9.4f, 0f), new Vector3(-1.5f, 9.45f, 0f), new Vector3(1.5f, 9.45f, 0f), new Vector3(4.5f, 9.4f, 0f), t => 0.25f, 0.7f);
        }
    }
}
