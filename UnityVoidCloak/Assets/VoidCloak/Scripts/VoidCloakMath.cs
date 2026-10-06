using System;
using UnityEngine;

namespace VoidCloak
{
    /// <summary>Small math helpers shared by the cloth surfaces.</summary>
    public static class CloakMath
    {
        public const float Tau = 6.28318530718f;

        /// <summary>Hermite smoothstep from edge a to edge b (works with a &gt; b as well).</summary>
        public static float Smooth(float a, float b, float x)
        {
            float t = Mathf.Clamp01((x - a) / (b - a));
            return t * t * (3f - 2f * t);
        }

        public static float Lerp(float a, float b, float t)
        {
            return a + (b - a) * t;
        }

        public static float Gauss(float x)
        {
            return Mathf.Exp(-x * x);
        }

        /// <summary>Wrap an angle difference into [-PI, PI].</summary>
        public static float WrapAngle(float a)
        {
            a = (a + Mathf.PI) % Tau;
            if (a < 0f) a += Tau;
            return a - Mathf.PI;
        }

        static float Hash(int x, int y, int z, int seed)
        {
            unchecked
            {
                uint h = (uint)(x * 374761393 + y * 668265263 + z * 1274126177 + seed * 144665 + 1013904223);
                h = (h ^ (h >> 13)) * 1274126177u;
                h ^= h >> 16;
                return (h & 0xFFFFFF) / 16777216f * 2f - 1f;
            }
        }

        /// <summary>Smooth 3D value noise in [-1, 1]. Only used for the final micro detail.</summary>
        public static float Noise3(Vector3 p, int seed)
        {
            int ix = Mathf.FloorToInt(p.x), iy = Mathf.FloorToInt(p.y), iz = Mathf.FloorToInt(p.z);
            float fx = p.x - ix, fy = p.y - iy, fz = p.z - iz;
            fx = fx * fx * (3f - 2f * fx);
            fy = fy * fy * (3f - 2f * fy);
            fz = fz * fz * (3f - 2f * fz);

            float x00 = Lerp(Hash(ix, iy, iz, seed), Hash(ix + 1, iy, iz, seed), fx);
            float x10 = Lerp(Hash(ix, iy + 1, iz, seed), Hash(ix + 1, iy + 1, iz, seed), fx);
            float x01 = Lerp(Hash(ix, iy, iz + 1, seed), Hash(ix + 1, iy, iz + 1, seed), fx);
            float x11 = Lerp(Hash(ix, iy + 1, iz + 1, seed), Hash(ix + 1, iy + 1, iz + 1, seed), fx);
            return Lerp(Lerp(x00, x10, fy), Lerp(x01, x11, fy), fz);
        }
    }

    /// <summary>
    /// Deterministic xorshift RNG. Used to pick fold parameters and to jitter samples
    /// inside a surface cell - never to invent positions on its own.
    /// </summary>
    public sealed class CloakRandom
    {
        uint state;

        public CloakRandom(int seed)
        {
            unchecked
            {
                state = (uint)seed * 2654435761u ^ 0x9E3779B9u;
                if (state == 0) state = 1;
            }
            NextUInt();
            NextUInt();
        }

        public uint NextUInt()
        {
            state ^= state << 13;
            state ^= state >> 17;
            state ^= state << 5;
            return state;
        }

        public float Value
        {
            get { return (NextUInt() & 0xFFFFFF) / 16777216f; }
        }

        public float Range(float a, float b)
        {
            return a + (b - a) * Value;
        }

        public float Signed()
        {
            return Value * 2f - 1f;
        }
    }

    /// <summary>
    /// Smooth 1D profile through control points (Catmull-Rom between knots).
    /// Used for the cloak width / depth as a function of height.
    /// </summary>
    public sealed class Profile1D
    {
        readonly float[] xs;
        readonly float[] ys;

        public Profile1D(float[] xs, float[] ys)
        {
            if (xs.Length != ys.Length || xs.Length < 2) throw new ArgumentException("profile needs >= 2 matching knots");
            this.xs = xs;
            this.ys = ys;
        }

        public float Evaluate(float x)
        {
            int n = xs.Length;
            if (x <= xs[0]) return ys[0] + Slope(0) * (x - xs[0]);
            if (x >= xs[n - 1]) return ys[n - 1] + Slope(n - 1) * (x - xs[n - 1]);

            int i = 0;
            while (i < n - 2 && x > xs[i + 1]) i++;

            float h = xs[i + 1] - xs[i];
            float t = (x - xs[i]) / h;
            float m0 = Slope(i) * h;
            float m1 = Slope(i + 1) * h;
            float t2 = t * t, t3 = t2 * t;
            return (2f * t3 - 3f * t2 + 1f) * ys[i] + (t3 - 2f * t2 + t) * m0
                 + (-2f * t3 + 3f * t2) * ys[i + 1] + (t3 - t2) * m1;
        }

        float Slope(int i)
        {
            int n = xs.Length;
            if (i == 0) return (ys[1] - ys[0]) / (xs[1] - xs[0]);
            if (i == n - 1) return (ys[n - 1] - ys[n - 2]) / (xs[n - 1] - xs[n - 2]);
            return (ys[i + 1] - ys[i - 1]) / (xs[i + 1] - xs[i - 1]);
        }
    }

    /// <summary>
    /// A family of cloth folds across a surface parameter u in [0,1], varying along t in [0,1]
    /// (t = 0 where the cloth hangs from, t = 1 at the hem).
    ///
    /// Each fold is a crest line u = c_i(t). Between two crests the cloth forms a valley,
    /// so the profile is a real ridge / valley cross section:
    ///
    ///        crest            crest
    ///        /    \          /
    ///   ____/      \___/\___/
    ///                valley
    ///
    /// Crest spacing, amplitude, valley position (skew), start height and sideways drift
    /// are chosen per fold, so the folds are irregular, not mirrored and not straight.
    /// </summary>
    public sealed class FoldField
    {
        readonly int n;
        readonly bool wrap;
        readonly float[] c0;
        readonly float[] drift;
        readonly float[] diag;
        readonly float[] amp;
        readonly float[] start;
        readonly float[] skew;
        readonly float[] width;
        readonly float[] ct;
        readonly float maxAmp;

        public int Count { get { return n; } }

        /// <param name="count">Number of crests.</param>
        /// <param name="wrap">True for closed loops (hood, shoulder cape).</param>
        /// <param name="irregularity">0 = equal spacing, 1 = strongly uneven widths.</param>
        /// <param name="driftAmount">Random sideways drift of each crest at t = 1 (u units).</param>
        /// <param name="diagonalAmount">Extra drift in the lower part (vertical -> diagonal flow).</param>
        /// <param name="lateStartChance">Probability that a fold only starts lower down.</param>
        /// <param name="driftBias">Optional systematic drift (u at t=1) as a function of crest position.</param>
        public FoldField(int count, bool wrap, float irregularity, float driftAmount, float diagonalAmount,
                         float lateStartChance, CloakRandom rng, Func<float, float> driftBias = null)
        {
            n = Mathf.Max(2, count);
            this.wrap = wrap;
            c0 = new float[n];
            drift = new float[n];
            diag = new float[n];
            amp = new float[n];
            start = new float[n];
            skew = new float[n];
            width = new float[n];
            ct = new float[n + 2];

            // Uneven widths: | || | ||||| | || ||| | ||
            float total = 0f;
            float[] gaps = new float[n];
            for (int i = 0; i < n; i++)
            {
                float g = 1f + irregularity * rng.Range(-0.6f, 0.75f);
                if (rng.Value < 0.15f * irregularity) g *= 0.55f; // occasional tight pair
                gaps[i] = Mathf.Max(0.2f, g);
                total += gaps[i];
            }

            float acc = rng.Range(0.1f, 0.9f) * gaps[0];
            for (int i = 0; i < n; i++)
            {
                c0[i] = acc / total;
                acc += gaps[(i + 1) % n];
            }
            if (!wrap)
            {
                // keep the first / last crests away from the panel borders
                float lo = c0[0], hi = c0[n - 1];
                float pad = 0.5f / n;
                for (int i = 0; i < n; i++) c0[i] = pad + (c0[i] - lo) / Mathf.Max(1e-4f, hi - lo) * (1f - 2f * pad);
            }

            maxAmp = 0f;
            for (int i = 0; i < n; i++)
            {
                float a = rng.Range(0.55f, 1.0f);
                if (rng.Value < 0.2f) a *= 1.3f; // a few dominant folds
                amp[i] = a;
                maxAmp = Mathf.Max(maxAmp, a);

                start[i] = rng.Value < lateStartChance ? rng.Range(0.12f, 0.5f) : rng.Range(0f, 0.06f);
                drift[i] = rng.Signed() * driftAmount;
                if (driftBias != null) drift[i] += driftBias(c0[i]);
                diag[i] = rng.Signed() * diagonalAmount;
                skew[i] = rng.Range(0.36f, 0.64f);
            }

            for (int i = 0; i < n; i++)
            {
                float prev = wrap ? c0[(i - 1 + n) % n] - (i == 0 ? 1f : 0f) : (i > 0 ? c0[i - 1] : c0[i] - (c0[1] - c0[0]));
                float next = wrap ? c0[(i + 1) % n] + (i == n - 1 ? 1f : 0f) : (i < n - 1 ? c0[i + 1] : c0[i] + (c0[i] - c0[i - 1]));
                width[i] = 0.5f * (next - prev);
            }
        }

        float CrestAt(int i, float t)
        {
            return c0[i] + drift[i] * t * t + diag[i] * CloakMath.Smooth(0.6f, 1f, t);
        }

        float Envelope(int i, float t)
        {
            return CloakMath.Smooth(start[i], start[i] + 0.2f, t);
        }

        /// <summary>
        /// Evaluate the fold profile.
        /// Returns a signed displacement in "u units" (already scaled by the local fold width),
        /// so callers multiply by the arc length of the u range and a depth ratio.
        /// </summary>
        /// <param name="ridge">Signed ridge value in [-1, 1]: +1 on a crest, -1 in a valley bottom.</param>
        public float Evaluate(float u, float t, out float ridge)
        {
            for (int i = 0; i < n; i++) ct[i] = CrestAt(i, t);
            float minGap = 0.15f / n;
            for (int i = 1; i < n; i++) if (ct[i] < ct[i - 1] + minGap) ct[i] = ct[i - 1] + minGap;

            int a, b;
            float ca, cb;
            if (wrap)
            {
                float uu = u - Mathf.Floor(u);
                // shift crests into [ct0, ct0+1)
                if (uu < ct[0]) uu += 1f;
                a = n - 1;
                for (int i = 0; i < n - 1; i++)
                {
                    if (uu >= ct[i] && uu < ct[i + 1]) { a = i; break; }
                }
                b = (a + 1) % n;
                ca = ct[a];
                cb = b == 0 ? ct[0] + 1f : ct[b];
                u = uu;
            }
            else
            {
                if (u < ct[0])
                {
                    a = 0; b = 0;
                    ca = ct[0] - (ct[1] - ct[0]);
                    cb = ct[0];
                }
                else if (u >= ct[n - 1])
                {
                    a = n - 1; b = n - 1;
                    ca = ct[n - 1];
                    cb = ct[n - 1] + (ct[n - 1] - ct[n - 2]);
                }
                else
                {
                    a = 0;
                    while (a < n - 2 && u >= ct[a + 1]) a++;
                    b = a + 1;
                    ca = ct[a];
                    cb = ct[b];
                }
            }

            float frac = Mathf.Clamp01((u - ca) / Mathf.Max(1e-5f, cb - ca));
            float s = skew[a];
            float x = frac < s ? 0.5f * frac / s : 0.5f + 0.5f * (frac - s) / (1f - s);
            float p = Mathf.Cos(CloakMath.Tau * x);

            float wa = amp[a] * Envelope(a, t) * width[a];
            float wb = amp[b] * Envelope(b, t) * width[b];
            float sm = frac * frac * (3f - 2f * frac);
            float aLocal = CloakMath.Lerp(wa, wb, sm);

            float ea = amp[a] * Envelope(a, t);
            float eb = amp[b] * Envelope(b, t);
            ridge = p * CloakMath.Lerp(ea, eb, sm) / maxAmp;
            return p * aLocal;
        }
    }
}
