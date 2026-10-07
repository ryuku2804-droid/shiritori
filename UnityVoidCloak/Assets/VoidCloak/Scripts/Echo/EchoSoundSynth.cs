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
