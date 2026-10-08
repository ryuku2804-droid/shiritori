using System;

namespace EchoKnight
{
    /// <summary>Every sound in the game. They are synthesised in code, no audio files needed.</summary>
    public enum EchoSound
    {
        Step,
        RunStep,
        SwordStrike,
        SwingLight,
        SwingHeavy,
        Hit,
        Parry,
        Hurt,
        Death,
        ShrineBell,
        ListenerStep,
        ListenerShriek,
        ListenerDeath,
        ListenerYelp,
        Ambience,
        ArmorStep,
        ArmorWindUp,
        ArmorHit,
        ArmorCollapse,
        PuzzleBell,
        PuzzleWrong,
        DoorOpen,
        HollowKnock,
        WallCrumble,
        StoneClack,
        Splash,
        Count,
    }

    /// <summary>
    /// Procedural sound effects (mono, float samples in [-1, 1]).
    /// Pure C# so the sounds can also be rendered to WAV outside Unity.
    /// </summary>
    public static class EchoSoundSynth
    {
        public const int SampleRate = 44100;

        /// <summary>Number of variations generated per sound (footsteps sound less mechanical).</summary>
        public static int Variants(EchoSound s)
        {
            switch (s)
            {
                case EchoSound.Step:
                case EchoSound.RunStep:
                case EchoSound.ListenerStep:
                case EchoSound.ArmorStep:
                case EchoSound.StoneClack:
                case EchoSound.Splash:
                    return 4;
                case EchoSound.Hit:
                case EchoSound.SwingLight:
                    return 3;
                default:
                    return 1;
            }
        }

        public static bool Loops(EchoSound s)
        {
            return s == EchoSound.Ambience;
        }

        public static float[] Generate(EchoSound sound, int variant)
        {
            var rng = new Random(1000 + (int)sound * 37 + variant * 7919);
            float[] data;
            switch (sound)
            {
                case EchoSound.Step: data = Footstep(rng, 0.2f, 0.7f, 1f); break;
                case EchoSound.RunStep: data = Footstep(rng, 0.26f, 1f, 1.5f); break;
                case EchoSound.SwordStrike: data = SwordStrike(rng); break;
                case EchoSound.SwingLight: data = Swing(rng, 0.3f, 700f, 2600f, 0.8f); break;
                case EchoSound.SwingHeavy: data = Swing(rng, 0.55f, 300f, 1300f, 1f); break;
                case EchoSound.Hit: data = Hit(rng); break;
                case EchoSound.Parry: data = Parry(rng); break;
                case EchoSound.Hurt: data = Hurt(rng); break;
                case EchoSound.Death: data = Death(rng); break;
                case EchoSound.ShrineBell: data = ShrineBell(rng); break;
                case EchoSound.ListenerStep: data = ListenerStep(rng); break;
                case EchoSound.ListenerShriek: data = Shriek(rng, 0.85f, 1f); break;
                case EchoSound.ListenerDeath: data = ListenerDeath(rng); break;
                case EchoSound.ListenerYelp: data = Shriek(rng, 0.35f, 1.5f); break;
                case EchoSound.Ambience: data = Ambience(rng); break;
                case EchoSound.ArmorStep: data = ArmorStep(rng); break;
                case EchoSound.ArmorWindUp: data = ArmorWindUp(rng); break;
                case EchoSound.ArmorHit: data = ArmorHit(rng); break;
                case EchoSound.ArmorCollapse: data = ArmorCollapse(rng); break;
                case EchoSound.PuzzleBell: data = PuzzleBell(rng); break;
                case EchoSound.PuzzleWrong: data = PuzzleWrong(rng); break;
                case EchoSound.DoorOpen: data = DoorOpen(rng); break;
                case EchoSound.HollowKnock: data = HollowKnock(rng); break;
                case EchoSound.WallCrumble: data = WallCrumble(rng); break;
                case EchoSound.StoneClack: data = StoneClack(rng); break;
                case EchoSound.Splash: data = Splash(rng); break;
                default: data = new float[1]; break;
            }
            Normalize(data, sound == EchoSound.Ambience ? 0.5f : 0.9f, !Loops(sound));
            return data;
        }

        // ------------------------------------------------------------------ helpers

        static float[] Buffer(float seconds)
        {
            return new float[Math.Max(1, (int)(seconds * SampleRate))];
        }

        static float Noise(Random rng)
        {
            return (float)(rng.NextDouble() * 2.0 - 1.0);
        }

        /// <summary>Coefficient for a one-pole low-pass at the given cutoff.</summary>
        static float Alpha(float cutoff)
        {
            float x = (float)Math.Exp(-2.0 * Math.PI * cutoff / SampleRate);
            return 1f - x;
        }

        static void Normalize(float[] d, float peak, bool fadeEdges)
        {
            float max = 1e-6f;
            for (int i = 0; i < d.Length; i++) max = Math.Max(max, Math.Abs(d[i]));
            float g = peak / max;
            for (int i = 0; i < d.Length; i++) d[i] *= g;
            if (!fadeEdges) return;
            // tiny fade in/out so nothing clicks
            int fade = Math.Min(64, d.Length / 4);
            for (int i = 0; i < fade; i++)
            {
                float k = (float)i / fade;
                d[i] *= k;
                d[d.Length - 1 - i] *= k;
            }
        }

        static float Sin(double phase)
        {
            return (float)Math.Sin(phase);
        }

        /// <summary>Decaying partials (bells, metal). freqs in Hz, decays in 1/s.</summary>
        static void AddPartials(float[] d, Random rng, float[] freqs, float[] amps, float[] decays, float start = 0f)
        {
            int s0 = (int)(start * SampleRate);
            for (int p = 0; p < freqs.Length; p++)
            {
                double phase = rng.NextDouble() * Math.PI * 2.0;
                double w = 2.0 * Math.PI * freqs[p] / SampleRate;
                for (int i = s0; i < d.Length; i++)
                {
                    float t = (float)(i - s0) / SampleRate;
                    d[i] += amps[p] * (float)Math.Exp(-decays[p] * t) * Sin(phase + w * (i - s0));
                }
            }
        }

        // ------------------------------------------------------------------ sounds

        /// <summary>A booted foot on stone: low thump, gritty scuff, and the cloak rustling.</summary>
        static float[] Footstep(Random rng, float length, float grit, float weight)
        {
            float[] d = Buffer(length);
            float lp = 0f, hp = 0f;
            float aLow = Alpha(700f + 300f * grit), aHigh = Alpha(2500f);
            float thumpF = 70f + (float)rng.NextDouble() * 25f;
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float n = Noise(rng);
                lp += aLow * (n - lp);
                float scuff = lp * (float)Math.Exp(-t * (28f / weight)) * grit;
                float thump = Sin(2.0 * Math.PI * thumpF * t) * (float)Math.Exp(-t * 32f) * 0.9f * weight;
                // cloth: high, soft, a little later
                hp += aHigh * (n - hp);
                float cloth = (n - hp) * 0.12f * (float)Math.Exp(-Math.Pow((t - 0.06f) / 0.05f, 2.0));
                d[i] = thump + scuff * 1.4f + cloth;
            }
            return d;
        }

        /// <summary>The sword struck on the stone floor: a sharp click and a ringing blade.</summary>
        static float[] SwordStrike(Random rng)
        {
            float[] d = Buffer(2.6f);
            for (int i = 0; i < 400; i++) d[i] += Noise(rng) * (float)Math.Exp(-i / 60.0) * 1.2f;
            AddPartials(d, rng,
                new[] { 523f, 1347f, 2213f, 3170f, 4410f },
                new[] { 0.5f, 0.45f, 0.35f, 0.22f, 0.12f },
                new[] { 2.2f, 3.0f, 4.0f, 5.5f, 8f });
            // low thud of the impact
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                d[i] += Sin(2.0 * Math.PI * 95.0 * t) * (float)Math.Exp(-t * 18f) * 0.6f;
            }
            return d;
        }

        /// <summary>Whoosh: noise through a band-pass whose centre sweeps up.</summary>
        static float[] Swing(Random rng, float length, float f0, float f1, float level)
        {
            float[] d = Buffer(length);
            float lp1 = 0f, lp2 = 0f;
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / d.Length;
                float centre = f0 + (f1 - f0) * t * t;
                float n = Noise(rng);
                lp1 += Alpha(centre * 1.6f) * (n - lp1);
                lp2 += Alpha(centre * 0.6f) * (n - lp2);
                float band = lp1 - lp2;
                float env = (float)Math.Pow(Math.Sin(Math.PI * Math.Min(1.0, t * 1.15)), 2.0);
                d[i] = band * env * level;
            }
            return d;
        }

        /// <summary>The blade biting into the Listener: thump plus a tearing crunch.</summary>
        static float[] Hit(Random rng)
        {
            float[] d = Buffer(0.32f);
            float lp = 0f;
            float a = Alpha(1600f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float n = Noise(rng);
                lp += a * (n - lp);
                float crunch = lp * (float)Math.Exp(-t * 16f) * (1f + 0.6f * Sin(2.0 * Math.PI * 37.0 * t));
                float thump = Sin(2.0 * Math.PI * (85.0 - 40.0 * t) * t) * (float)Math.Exp(-t * 20f);
                d[i] = thump + crunch * 1.5f;
            }
            return d;
        }

        /// <summary>A parry: bright clang that rings on.</summary>
        static float[] Parry(Random rng)
        {
            float[] d = Buffer(2.0f);
            for (int i = 0; i < 600; i++) d[i] += Noise(rng) * (float)Math.Exp(-i / 90.0) * 1.4f;
            AddPartials(d, rng,
                new[] { 880f, 1771f, 2637f, 3954f, 5120f, 6830f },
                new[] { 0.55f, 0.5f, 0.4f, 0.3f, 0.2f, 0.12f },
                new[] { 1.8f, 2.4f, 3.2f, 4.2f, 6f, 9f });
            return d;
        }

        static float[] Hurt(Random rng)
        {
            float[] d = Buffer(0.45f);
            float lp = 0f;
            float a = Alpha(500f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                lp += a * (Noise(rng) - lp);
                d[i] = Sin(2.0 * Math.PI * 58.0 * t) * (float)Math.Exp(-t * 9f) + lp * (float)Math.Exp(-t * 12f) * 1.8f;
            }
            return d;
        }

        /// <summary>Falling: a deep boom that rolls away.</summary>
        static float[] Death(Random rng)
        {
            float[] d = Buffer(3.0f);
            float lp = 0f;
            float a = Alpha(180f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                lp += a * (Noise(rng) - lp);
                d[i] = Sin(2.0 * Math.PI * (48.0 - 10.0 * t) * t) * (float)Math.Exp(-t * 1.6f) + lp * (float)Math.Exp(-t * 1.2f) * 3f;
            }
            return d;
        }

        /// <summary>
        /// Church bell: hum, prime, minor third (tierce), fifth, nominal and higher partials,
        /// each decaying at its own rate; close pairs beat slowly like a real bell.
        /// </summary>
        static float[] ShrineBell(Random rng)
        {
            float[] d = Buffer(6.5f);
            const float f = 330f;
            for (int i = 0; i < 500; i++) d[i] += Noise(rng) * (float)Math.Exp(-i / 70.0) * 0.6f;
            AddPartials(d, rng,
                new[] { f * 0.5f, f * 0.502f, f, f * 1.003f, f * 1.19f, f * 1.5f, f * 2f, f * 2.51f, f * 3.01f, f * 4.2f },
                new[] { 0.55f, 0.35f, 0.7f, 0.4f, 0.5f, 0.35f, 0.6f, 0.28f, 0.22f, 0.12f },
                new[] { 0.32f, 0.35f, 0.55f, 0.58f, 0.75f, 0.85f, 0.95f, 1.4f, 1.9f, 3f });
            return d;
        }

        /// <summary>A Listener dragging its feet and robe.</summary>
        static float[] ListenerStep(Random rng)
        {
            float[] d = Buffer(0.42f);
            float lp = 0f, lp2 = 0f;
            float a = Alpha(450f), a2 = Alpha(3500f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float n = Noise(rng);
                lp += a * (n - lp);
                lp2 += a2 * (n - lp2);
                float env = (float)(Math.Sin(Math.PI * Math.Min(1.0, t / 0.42)) * Math.Exp(-t * 3.0));
                float scrape = (lp2 - lp) * 0.25f * env * (1f + 0.5f * Sin(2.0 * Math.PI * 23.0 * t));
                d[i] = lp * env * 2.2f + scrape;
            }
            return d;
        }

        /// <summary>A harsh, wavering shriek: the warning before a Listener lashes out.</summary>
        static float[] Shriek(Random rng, float length, float pitch)
        {
            float[] d = Buffer(length);
            double phase = 0.0, modPhase = 0.0;
            float hp = 0f;
            float aHigh = Alpha(2800f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float u = t / length;
                float carrier = (900f + 700f * u - 300f * u * u) * pitch;
                float vibrato = 1f + 0.06f * Sin(2.0 * Math.PI * 28.0 * t);
                modPhase += 2.0 * Math.PI * carrier * 1.41 / SampleRate;
                phase += 2.0 * Math.PI * carrier * vibrato / SampleRate + 2.2 * Math.Sin(modPhase) / SampleRate * 600.0;
                float n = Noise(rng);
                hp += aHigh * (n - hp);
                float hiss = (n - hp) * 0.35f;
                float env = Math.Min(1f, t / 0.04f) * (float)Math.Pow(Math.Max(0.0, 1.0 - u), 0.6);
                d[i] = (Sin(phase) * 0.8f + Sin(phase * 2.01) * 0.3f + hiss) * env;
            }
            return d;
        }

        /// <summary>A Listener collapsing: a wail falling away into silence.</summary>
        static float[] ListenerDeath(Random rng)
        {
            float[] d = Buffer(1.8f);
            double phase = 0.0;
            float lp = 0f;
            float a = Alpha(1200f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float u = t / 1.8f;
                float f = 720f * (float)Math.Pow(0.2, u);
                phase += 2.0 * Math.PI * f * (1.0 + 0.08 * Math.Sin(2.0 * Math.PI * 9.0 * t)) / SampleRate;
                lp += a * (Noise(rng) - lp);
                float env = (float)(Math.Min(1.0, t / 0.05) * Math.Pow(1.0 - u, 1.4));
                d[i] = (Sin(phase) * 0.7f + Sin(phase * 1.5) * 0.25f + lp * 0.8f) * env;
            }
            return d;
        }

        /// <summary>An empty suit of armour taking a step: a heavy thud, a hollow boom from inside, plates clinking.</summary>
        static float[] ArmorStep(Random rng)
        {
            float[] d = Buffer(0.7f);
            float j = 0.95f + (float)rng.NextDouble() * 0.1f;
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                d[i] += Sin(2.0 * Math.PI * 62.0 * j * t) * (float)Math.Exp(-t * 26f) * 0.55f;
            }
            // the hollow shell rings low
            AddPartials(d, rng, new[] { 190f * j, 233f * j }, new[] { 0.3f, 0.18f }, new[] { 9f, 11f });
            // plates knocking together, slightly after the foot lands
            for (int k = 0; k < 3; k++)
            {
                float start = 0.02f + k * 0.045f + (float)rng.NextDouble() * 0.02f;
                int s0 = (int)(start * SampleRate);
                for (int i = 0; i < 120 && s0 + i < d.Length; i++) d[s0 + i] += Noise(rng) * (float)Math.Exp(-i / 25.0) * 0.4f;
                float f = (1400f + (float)rng.NextDouble() * 900f) * j;
                AddPartials(d, rng, new[] { f, f * 1.47f, f * 2.13f }, new[] { 0.3f, 0.2f, 0.12f }, new[] { 18f, 24f, 32f }, start);
            }
            return d;
        }

        /// <summary>The great sword being raised: metal grinding on metal, rising in pitch - the only warning.</summary>
        static float[] ArmorWindUp(Random rng)
        {
            const float length = 0.95f;
            float[] d = Buffer(length);
            float lp1 = 0f, lp2 = 0f;
            double phase = 0.0;
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float u = t / length;
                float centre = 500f + 2200f * u * u;
                float n = Noise(rng);
                lp1 += Alpha(centre * 1.4f) * (n - lp1);
                lp2 += Alpha(centre * 0.7f) * (n - lp2);
                float grind = (lp1 - lp2) * (0.6f + 0.4f * Sin(2.0 * Math.PI * 41.0 * t));
                // a squealing partial that climbs with the blade
                phase += 2.0 * Math.PI * (700.0 + 900.0 * u) / SampleRate;
                float squeal = Sin(phase) * 0.12f * u;
                float env = Math.Min(1f, t / 0.08f) * (0.4f + 0.6f * u) * Math.Min(1f, (length - t) / 0.04f);
                d[i] = (grind * 2.2f + squeal) * env;
            }
            return d;
        }

        /// <summary>The knight's blade on plate: a dull clang that rings inside the empty shell.</summary>
        static float[] ArmorHit(Random rng)
        {
            float[] d = Buffer(1.4f);
            for (int i = 0; i < 500; i++) d[i] += Noise(rng) * (float)Math.Exp(-i / 70.0) * 1.1f;
            AddPartials(d, rng,
                new[] { 212f, 640f, 1013f, 1732f, 2611f },
                new[] { 0.45f, 0.5f, 0.4f, 0.25f, 0.15f },
                new[] { 4f, 5.5f, 7f, 10f, 14f });
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                d[i] += Sin(2.0 * Math.PI * 80.0 * t) * (float)Math.Exp(-t * 22f) * 0.6f;
            }
            return d;
        }

        /// <summary>The armour falling apart: pieces clattering on the stones one after another.</summary>
        static float[] ArmorCollapse(Random rng)
        {
            float[] d = Buffer(2.6f);
            float start = 0f;
            for (int k = 0; k < 9; k++)
            {
                start += 0.06f + (float)rng.NextDouble() * 0.2f * (1f + k * 0.15f);
                if (start > 2.0f) break;
                float level = 1f - k * 0.08f;
                int s0 = (int)(start * SampleRate);
                for (int i = 0; i < 300 && s0 + i < d.Length; i++) d[s0 + i] += Noise(rng) * (float)Math.Exp(-i / 50.0) * 0.7f * level;
                float f = 380f + (float)rng.NextDouble() * 1400f;
                AddPartials(d, rng, new[] { f, f * 1.58f, f * 2.37f }, new[] { 0.3f * level, 0.2f * level, 0.12f * level }, new[] { 7f, 10f, 14f }, start);
                for (int i = s0; i < d.Length && i < s0 + SampleRate / 4; i++)
                {
                    float t = (float)(i - s0) / SampleRate;
                    d[i] += Sin(2.0 * Math.PI * 70.0 * t) * (float)Math.Exp(-t * 24f) * 0.5f * level;
                }
            }
            // the helm rolls to a stop
            AddPartials(d, rng, new[] { 410f, 655f }, new[] { 0.1f, 0.07f }, new[] { 2.5f, 3.5f }, Math.Min(2.0f, start + 0.15f));
            return d;
        }

        /// <summary>
        /// A small hand bell (base note A5). The puzzle plays it at different pitches, so the
        /// partials are kept harmonic enough that the notes are easy to tell apart.
        /// </summary>
        static float[] PuzzleBell(Random rng)
        {
            float[] d = Buffer(3.2f);
            const float f = 880f;
            for (int i = 0; i < 300; i++) d[i] += Noise(rng) * (float)Math.Exp(-i / 40.0) * 0.4f;
            AddPartials(d, rng,
                new[] { f * 0.5f, f, f * 1.002f, f * 2f, f * 2.76f, f * 4.07f },
                new[] { 0.2f, 0.8f, 0.4f, 0.35f, 0.18f, 0.08f },
                new[] { 1.2f, 1.1f, 1.15f, 2f, 3.2f, 5f });
            return d;
        }

        /// <summary>The door refusing a wrong bell: a dull iron clank and a low rattle.</summary>
        static float[] PuzzleWrong(Random rng)
        {
            float[] d = Buffer(0.9f);
            for (int i = 0; i < 700; i++) d[i] += Noise(rng) * (float)Math.Exp(-i / 120.0) * 0.8f;
            AddPartials(d, rng, new[] { 118f, 167f, 311f, 452f }, new[] { 0.6f, 0.4f, 0.25f, 0.15f }, new[] { 7f, 9f, 12f, 16f });
            // the bolt rattling in its bracket
            for (int k = 1; k < 4; k++)
            {
                int s0 = (int)((0.09f * k + (float)rng.NextDouble() * 0.02f) * SampleRate);
                for (int i = 0; i < 200 && s0 + i < d.Length; i++) d[s0 + i] += Noise(rng) * (float)Math.Exp(-i / 30.0) * 0.35f / k;
            }
            return d;
        }

        /// <summary>A heavy wooden door swinging open: creaking hinges over a low rumble.</summary>
        static float[] DoorOpen(Random rng)
        {
            const float length = 3.0f;
            float[] d = Buffer(length);
            float lp = 0f, lpR = 0f, lpSub = 0f;
            float a = Alpha(2200f), aR = Alpha(140f), aSub = Alpha(40f);
            double phase = 0.0;
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float u = t / length;
                float n = Noise(rng);
                lp += a * (n - lp);
                lpR += aR * (n - lpR);
                lpSub += aSub * (n - lpSub);
                float rumble = lpR - lpSub;   // 40-140 Hz: felt, not a sub-sonic hum
                // creak: a slowly wandering pitch, driven in stick-slip pulses
                double f = 260.0 + 90.0 * Math.Sin(t * 2.3) + 40.0 * Math.Sin(t * 7.1);
                phase += 2.0 * Math.PI * f / SampleRate;
                float pulses = 0.5f + 0.5f * Sin(2.0 * Math.PI * 23.0 * t);
                float creak = (Sin(phase) * 0.5f + Sin(phase * 2.0) * 0.3f + Sin(phase * 3.0) * 0.15f) * pulses * pulses + lp * 0.15f;
                float env = Math.Min(1f, t / 0.15f) * (float)Math.Pow(1.0 - u, 0.7);
                d[i] = creak * env * 0.6f + rumble * 6f * env;
            }
            // the leaves hitting their stops at the end
            AddPartials(d, rng, new[] { 95f, 143f }, new[] { 0.35f, 0.2f }, new[] { 10f, 13f }, length - 0.55f);
            return d;
        }

        /// <summary>A hollow wall answering a sound: a deep boom with a cavity ringing behind it.</summary>
        static float[] HollowKnock(Random rng)
        {
            float[] d = Buffer(2.0f);
            float lp = 0f;
            float a = Alpha(400f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                lp += a * (Noise(rng) - lp);
                d[i] = lp * (float)Math.Exp(-t * 30f) * 2f;
            }
            // the empty room behind the stones resonates (low, slow, a little beating)
            AddPartials(d, rng, new[] { 104f, 105.5f, 157f, 236f }, new[] { 0.7f, 0.5f, 0.35f, 0.15f }, new[] { 2.4f, 2.6f, 3.5f, 5f });
            return d;
        }

        /// <summary>A wall breaking: a crack, then stones tumbling and settling.</summary>
        static float[] WallCrumble(Random rng)
        {
            float[] d = Buffer(3.2f);
            float lp = 0f;
            float a = Alpha(900f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                lp += a * (Noise(rng) - lp);
                d[i] = Sin(2.0 * Math.PI * (60.0 - 12.0 * t) * t) * (float)Math.Exp(-t * 4f) * 0.8f + lp * (float)Math.Exp(-t * 1.3f) * 1.6f;
            }
            for (int i = 0; i < 800; i++) d[i] += Noise(rng) * (float)Math.Exp(-i / 150.0) * 1.2f;   // the crack
            float start = 0.1f;
            for (int k = 0; k < 18 && start < 2.8f; k++)
            {
                start += 0.03f + (float)rng.NextDouble() * 0.17f;
                int s0 = (int)(start * SampleRate);
                float level = 0.9f * (float)Math.Exp(-start * 0.9f);
                float f = 160f + (float)rng.NextDouble() * 500f;
                for (int i = 0; i < SampleRate / 10 && s0 + i < d.Length; i++)
                {
                    float t = (float)i / SampleRate;
                    d[s0 + i] += (Sin(2.0 * Math.PI * f * t) * 0.5f + Noise(rng) * 0.6f) * (float)Math.Exp(-t * 45f) * level;
                }
            }
            return d;
        }

        /// <summary>A thrown stone landing: a hard click, a smaller bounce, a little skitter.</summary>
        static float[] StoneClack(Random rng)
        {
            float[] d = Buffer(0.7f);
            float[] at = { 0.004f, 0.13f + (float)rng.NextDouble() * 0.05f, 0.24f + (float)rng.NextDouble() * 0.05f };   // (not at 0: the edges fade)
            float[] level = { 1f, 0.45f, 0.2f };
            for (int k = 0; k < at.Length; k++)
            {
                int s0 = (int)(at[k] * SampleRate);
                for (int i = 0; i < 260 && s0 + i < d.Length; i++) d[s0 + i] += Noise(rng) * (float)Math.Exp(-i / 35.0) * level[k];
                float f = 2300f + (float)rng.NextDouble() * 900f;
                AddPartials(d, rng, new[] { f, f * 1.37f, f * 0.61f }, new[] { 0.25f * level[k], 0.15f * level[k], 0.12f * level[k] }, new[] { 38f, 50f, 30f }, at[k]);
            }
            return d;
        }

        /// <summary>A foot in shallow water: a slap, a hiss of spray and a few bubbly drops.</summary>
        static float[] Splash(Random rng)
        {
            float[] d = Buffer(0.55f);
            float lp = 0f, lp2 = 0f;
            float a = Alpha(3200f), a2 = Alpha(600f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float n = Noise(rng);
                lp += a * (n - lp);
                lp2 += a2 * (n - lp2);
                float spray = (lp - lp2) * (float)Math.Exp(-t * 9f) * Math.Min(1f, t / 0.01f);
                float slap = lp2 * (float)Math.Exp(-t * 30f) * 2.5f;
                d[i] = spray * 1.6f + slap;
            }
            // drops: short rising chirps
            for (int k = 0; k < 4; k++)
            {
                float start = 0.05f + (float)rng.NextDouble() * 0.35f;
                float f0 = 700f + (float)rng.NextDouble() * 900f;
                int s0 = (int)(start * SampleRate);
                double phase = 0.0;
                for (int i = 0; i < SampleRate / 25 && s0 + i < d.Length; i++)
                {
                    float t = (float)i / SampleRate;
                    phase += 2.0 * Math.PI * f0 * (1.0 + t * 25.0) / SampleRate;
                    d[s0 + i] += Sin(phase) * (float)Math.Exp(-t * 90f) * 0.25f;
                }
            }
            return d;
        }

        /// <summary>Low wind in the dark (seamless loop).</summary>
        static float[] Ambience(Random rng)
        {
            const float seconds = 12f;
            float[] d = Buffer(seconds);
            float lp = 0f, lp2 = 0f;
            float a = Alpha(220f), a2 = Alpha(60f);
            for (int i = 0; i < d.Length; i++)
            {
                float t = (float)i / SampleRate;
                float n = Noise(rng);
                lp += a * (n - lp);
                lp2 += a2 * (n - lp2);
                // slow swells that repeat exactly every 12 s so the loop is seamless
                float swell = 0.55f + 0.3f * Sin(2.0 * Math.PI * t / seconds) + 0.15f * Sin(2.0 * Math.PI * 3.0 * t / seconds + 1.0);
                d[i] = (lp * 0.6f + lp2 * 2.0f) * swell;
            }
            // cross-fade the ends so the loop has no seam
            int fade = SampleRate / 2;
            for (int i = 0; i < fade; i++)
            {
                float k = (float)i / fade;
                float end = d[d.Length - fade + i];
                d[i] = d[i] * k + end * (1f - k);
            }
            Array.Resize(ref d, d.Length - fade);
            return d;
        }
    }
}
