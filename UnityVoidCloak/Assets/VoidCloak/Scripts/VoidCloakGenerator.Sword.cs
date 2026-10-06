using UnityEngine;

namespace VoidCloak
{
    /// <summary>
    /// Medieval longsword and the sleeves that hide the hands holding it.
    /// The sword is sampled into the same point cloud as the cloak, but its particles are
    /// tagged as steel / leather so the shader lights them as metal instead of cloth.
    /// </summary>
    public sealed partial class VoidCloakGenerator
    {
        // Sleeve roots sit inside the cloak, just behind the front opening, under the shoulder cape.
        static readonly Vector3 RightShoulderInside = new Vector3(0.3f, 2.85f, 0.0f);

        void GenerateSword()
        {
            SwordFrame frame;
            Vector3 tip, direction;
            switch (sword.pose)
            {
                case SwordPose.PlantedFront:
                    tip = new Vector3(0f, 0.03f, 1.12f);
                    direction = new Vector3(0f, -1f, 0.1f);
                    break;
                case SwordPose.Custom:
                    tip = sword.customTip;
                    direction = sword.customBladeDirection.sqrMagnitude > 1e-6f ? sword.customBladeDirection : Vector3.down;
                    break;
                default:
                    tip = new Vector3(0.95f, 0.03f, 1.3f);
                    direction = new Vector3(0.25f, -1f, 0.45f);
                    break;
            }
            frame = SwordFrame.FromTip(tip, direction, sword.bladeLength, Vector3.forward);

            GenerateSwordBlade(frame);
            GenerateSwordHilt(frame);
            if (sword.sleeves) GenerateSwordSleeves(frame);
        }

        // --------------------------------------------------------------------------------
        // Blade
        // --------------------------------------------------------------------------------

        void GenerateSwordBlade(SwordFrame frame)
        {
            var blade = new SwordBladeSurface(frame, sword);
            Sample(blade, density.Scaled(sword.blade), 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.SwordBlade,
                   null, 1f, 160, 32, ParticleMaterial.Steel);
            // Extra particles along both cutting edges keep the outline crisp.
            Sample(blade, density.Scaled(sword.bladeEdges), 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.SwordEdge,
                   s => s.edge * s.edge, 0.8f, 160, 64, ParticleMaterial.Steel);
        }

        // --------------------------------------------------------------------------------
        // Hilt: cross guard, leather grip, wheel pommel
        // --------------------------------------------------------------------------------

        void GenerateSwordHilt(SwordFrame frame)
        {
            float halfGuard = sword.guardWidth * 0.5f;
            const float guardRadius = 0.022f;

            // Straight cross guard whose quillons curve slightly towards the blade and flare at the ends.
            var guard = new SwordTubeSurface(
                u =>
                {
                    float s = 2f * u - 1f;
                    return frame.Point(0.04f * s * s, s * halfGuard, 0f);
                },
                (u, a) =>
                {
                    float s = Mathf.Abs(2f * u - 1f);
                    return guardRadius * (1f + 0.55f * CloakMath.Smooth(0.8f, 1f, s) + 0.6f * CloakMath.Smooth(0.18f, 0f, s));
                },
                frame.axis, frame.face, 1.25f, 0.55f);
            Sample(guard, density.Scaled(sword.guard), 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.SwordGuard,
                   null, 1f, 96, 24, ParticleMaterial.Steel);

            // Grip: slightly barrel shaped, with a spiral leather wrap.
            float gripLength = sword.gripLength;
            float rg = sword.gripRadius;
            var grip = new SwordTubeSurface(
                u => frame.Point(-0.03f - u * (gripLength - 0.03f), 0f, 0f),
                (u, a) => rg * (0.9f + 0.18f * Mathf.Sin(Mathf.PI * u))
                          + 0.004f * Mathf.Pow(Mathf.Max(0f, Mathf.Cos(CloakMath.Tau * u * 9f - a)), 3f),
                frame.edge, frame.face, 1f, 0.5f);
            Sample(grip, density.Scaled(sword.grip), 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.SwordGrip,
                   null, 1f, 64, 24, ParticleMaterial.Leather);

            var pommel = new SwordPommelSurface(frame.Point(-gripLength - sword.pommelRadius * 0.85f, 0f, 0f), frame, sword.pommelRadius);
            Sample(pommel, density.Scaled(sword.pommel), 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.SwordPommel,
                   null, 1f, 48, 24, ParticleMaterial.Steel);
        }

        // --------------------------------------------------------------------------------
        // Sleeves: the hand is inside the cuff, only the grip comes out
        // --------------------------------------------------------------------------------

        void GenerateSwordSleeves(SwordFrame frame)
        {
            float gripLength = sword.gripLength;
            switch (sword.pose)
            {
                case SwordPose.PlantedFront:
                {
                    // Both hands on the grip, forearms coming in from the sides.
                    Vector3 upperHand = frame.Point(-gripLength * 0.55f, 0f, 0f);
                    Vector3 lowerHand = frame.Point(-gripLength * 0.22f, 0f, 0f);
                    Vector3 rightCuff = upperHand + new Vector3(0.12f, 0.02f, -0.02f);
                    Vector3 leftCuff = lowerHand + new Vector3(-0.12f, -0.01f, -0.03f);
                    Vector3 rightDir = new Vector3(-0.7f, -0.05f, 0.7f).normalized;
                    Vector3 leftDir = new Vector3(0.68f, -0.1f, 0.72f).normalized;
                    Vector3 leftShoulder = new Vector3(-RightShoulderInside.x, RightShoulderInside.y, RightShoulderInside.z);
                    BuildSleeve(RightShoulderInside, new Vector3(0.5f, 2.45f, 0.25f), rightCuff - rightDir * 0.4f, rightCuff);
                    BuildSleeve(leftShoulder, new Vector3(-0.52f, 2.4f, 0.22f), leftCuff - leftDir * 0.4f, leftCuff);
                    break;
                }
                default:
                {
                    // One hand: the forearm continues along the sword, the grip leaves the cuff.
                    Vector3 cuff = frame.Point(-gripLength * 0.55f, 0f, 0f);
                    BuildSleeve(RightShoulderInside, new Vector3(0.36f, 2.45f, 0.18f), cuff - frame.axis * 0.45f, cuff);
                    break;
                }
            }
        }

        void BuildSleeve(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3)
        {
            var outerSleeve = new SleeveSurface(p0, p1, p2, p3, sword.sleeveWidth, sword.sleeveBell, rng, shape.clothThickness, false);
            Sample(outerSleeve, density.Scaled(sword.sleevePerArm), 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.Sleeve,
                   s => 1f + 0.6f * Mathf.Abs(s.major) + 1.5f * s.edge, 1f, 48, 96);

            // Dark inside of the cuff and a black disc deeper in, so the hand is never visible.
            var innerSleeve = new SleeveSurface(p0, p1, p2, p3, sword.sleeveWidth, sword.sleeveBell, rng, shape.clothThickness, true);
            int inside = density.Scaled(sword.sleeveInside);
            Sample(innerSleeve, inside * 2 / 3, 0f, 1f, 0.7f, 1f, (u, v, s) => CloakPart.SleeveVoid, null, 1f, 48, 24);
            var cap = new SleeveCapSurface(outerSleeve, 0.8f);
            Sample(cap, inside - inside * 2 / 3, 0f, 1f, 0f, 1f, (u, v, s) => CloakPart.SleeveVoid, null, 1f, 32, 8);
        }
    }
}
