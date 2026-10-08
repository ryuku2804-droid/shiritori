using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>One pose of one figure at one moment (position and yaw local to the theatre).</summary>
    public struct EchoTheatreKey
    {
        public float time;
        public Vector3 position;
        public float yaw;
        public EchoFigurePose pose;

        public EchoTheatreKey(float time, float x, float z, float yaw, EchoFigurePose pose)
        {
            this.time = time;
            position = new Vector3(x, 0f, z);
            this.yaw = yaw;
            this.pose = pose;
        }
    }

    public struct EchoTheatreLine
    {
        public float time;
        public string speaker;
        public string text;
        public float seconds;
    }

    /// <summary>A bright moment in the scene (a blow, the bell breaking): a big golden echo and a sound.</summary>
    public struct EchoTheatreFlash
    {
        public float time;
        public float radius;
        public EchoSound sound;
        public float pitch;
    }

    public class EchoTheatreScene
    {
        public float duration;
        public readonly List<EchoTheatreKey[]> actors = new List<EchoTheatreKey[]>();
        public readonly List<EchoTheatreLine> lines = new List<EchoTheatreLine>();
        public readonly List<EchoTheatreFlash> flashes = new List<EchoTheatreFlash>();

        public void Line(float time, string speaker, string text, float seconds)
        {
            lines.Add(new EchoTheatreLine { time = time, speaker = speaker, text = text, seconds = seconds });
        }

        public void Flash(float time, float radius, EchoSound sound, float pitch)
        {
            flashes.Add(new EchoTheatreFlash { time = time, radius = radius, sound = sound, pitch = pitch });
        }
    }

    /// <summary>
    /// The echo theatres (残響劇): moments of the past that replay as golden figures when a loud
    /// echo reaches the place they happened.
    /// </summary>
    public static class EchoTheatreScenes
    {
        public const string HallRitual = "hall_ritual";
        public const string MarketNight = "market_night";
        public const string GarethMemory = "gareth_memory";

        public static EchoTheatreScene Get(string id)
        {
            switch (id)
            {
                case HallRitual: return Ritual();
                case MarketNight: return Market();
                case GarethMemory: return Gareth();
                default: return null;
            }
        }

        const EchoFigurePose KDown = EchoFigurePose.KnightSwordDown, KUp = EchoFigurePose.KnightSwordRaised, KSwing = EchoFigurePose.KnightSwordSwung;
        const EchoFigurePose Robed = EchoFigurePose.Robed, ArmsUp = EchoFigurePose.RobedArmsUp, Child = EchoFigurePose.Child, ChildKneel = EchoFigurePose.ChildKneel;

        static EchoTheatreKey K(float t, float x, float z, float yaw, EchoFigurePose pose) { return new EchoTheatreKey(t, x, z, yaw, pose); }

        /// <summary>
        /// Prologue, great hall: the night of the offering. A priest, two bell keepers, a kneeling
        /// child - and a knight who walks in, raises his sword, strikes the floor and leaves
        /// towards the belfry. Who he is, is not said.
        /// </summary>
        static EchoTheatreScene Ritual()
        {
            var s = new EchoTheatreScene { duration = 14f };
            s.actors.Add(new[] { K(0f, 0f, 9f, 180f, Robed), K(7.4f, 0f, 9f, 180f, ArmsUp), K(10f, 0f, 9f, 180f, Robed) });            // priest
            s.actors.Add(new[] { K(0f, 0f, 5.5f, 0f, ChildKneel), K(8.5f, 0f, 5.5f, 180f, Child) });                                  // the child (Rine)
            s.actors.Add(new[] { K(0f, -4.5f, 4f, 30f, Robed), K(4.2f, -4.5f, 4f, 150f, ArmsUp), K(7f, -4.5f, 4f, 150f, Robed) });     // bell keepers
            s.actors.Add(new[] { K(0f, 4.5f, 4f, -30f, Robed), K(4.2f, 4.5f, 4f, -150f, ArmsUp), K(7f, 4.5f, 4f, -150f, Robed) });
            s.actors.Add(new[]                                                                                                          // the knight
            {
                K(0f, 0f, -14f, 0f, KDown), K(4f, 0f, -1f, 0f, KDown), K(5f, 0f, 2.6f, 0f, KUp), K(7.3f, 0f, 2.6f, 0f, KUp),
                K(7.5f, 0f, 2.6f, 0f, KSwing), K(8.6f, 0f, 2.6f, 180f, KDown), K(13f, 0f, -14f, 180f, KDown),
            });
            s.Line(0.6f, "司祭の残響", "「暁鐘よ。今年、捧げる声は ― リーネ」", 3.5f);
            s.Line(4.3f, "鐘守りの残響", "「止まれ！　儀式の最中だぞ！」", 2.8f);
            s.Line(7.6f, "司祭の残響", "「やめろ……！　鐘を、どうするつもりだ……！」", 3f);
            s.Line(10.8f, "幼いリーネの残響", "「……行かないで」", 3f);
            s.Flash(7.5f, 22f, EchoSound.SwordStrike, 0.8f);
            return s;
        }

        /// <summary>
        /// Chapter 1, market well: the night the bell stopped. People run; a child stays by the well;
        /// her mother comes back for her and leads her west - to the hollow wall.
        /// </summary>
        static EchoTheatreScene Market()
        {
            var s = new EchoTheatreScene { duration = 13f };
            s.actors.Add(new[] { K(0f, -3f, -3f, 225f, ArmsUp), K(5f, -12f, -15f, 225f, ArmsUp) });
            s.actors.Add(new[] { K(0f, 3f, 2f, 45f, ArmsUp), K(5f, 13f, 14f, 45f, ArmsUp) });
            s.actors.Add(new[] { K(0f, 2.5f, -4f, 0f, ChildKneel), K(8f, 2.5f, -4f, 0f, Child), K(12.5f, -22f, -5.5f, -90f, Child) });
            s.actors.Add(new[]
            {
                K(0f, -14f, 10f, 135f, Robed), K(4f, 2.5f, -2.3f, 180f, Robed), K(5.5f, 2.5f, -2.3f, 180f, ArmsUp), K(8f, 2.5f, -2.3f, 250f, Robed),
                K(12.5f, -22f, -4.3f, -90f, Robed),
            });
            s.Line(0.5f, "町人の残響", "「鐘が……止まった！　しじまが来るぞ！」", 3f);
            s.Line(4.4f, "鐘守りの母の残響", "「リーネ！　ここにいたのね！」", 3f);
            s.Line(8.4f, "鐘守りの母の残響", "「隠れましょう。……兄さんが、きっと来てくれる」", 4f);
            s.Flash(0.1f, 30f, EchoSound.ShrineBell, 0.5f);
            return s;
        }

        /// <summary>
        /// Chapter 1, under the cathedral (after the Silent Knight falls): Gareth tries to stop
        /// Aldren. Aldren cuts him down and goes on to the belfry. Now it is said.
        /// </summary>
        static EchoTheatreScene Gareth()
        {
            var s = new EchoTheatreScene { duration = 15f };
            s.actors.Add(new[] { K(0f, 0f, -6f, 0f, KDown), K(7.2f, 0f, -6f, 0f, EchoFigurePose.Kneel) });                              // Gareth
            s.actors.Add(new[]                                                                                                         // Aldren
            {
                K(0f, 0f, 6f, 180f, KDown), K(5f, 0f, 6f, 180f, KUp), K(6.8f, 0f, -3.4f, 180f, KUp), K(7f, 0f, -3.4f, 180f, KSwing),
                K(9f, 0f, -3.4f, 180f, KDown), K(13.5f, 0f, -16f, 180f, KDown),
            });
            s.Line(0.5f, "ガレスの残響", "「アルドレン、やめろ！　鐘を砕けば、しじまが溢れる！」", 4f);
            s.Line(4.8f, "アルドレンの残響", "「……リーネの声は、渡さない」", 3f);
            s.Line(9.2f, "ガレスの残響", "「……行け。……お前はきっと、後悔する」", 3.8f);
            s.Line(13.6f, "リーネ", "「……兄さん。いまのは……兄さん、なの……？」", 5f);
            s.Flash(7f, 14f, EchoSound.Parry, 0.6f);
            return s;
        }
    }
}
