using System;
using UnityEngine;

namespace NightShards.Museum
{
    // ジオラマの地形の高さを、C# でも計算できるようにしたもの。ジオラマの世界に入って歩くときの地面になる。
    // シェーダーの Height() と同じ式・同じノイズを、そのまま書き写している。
    // ※ シェーダーの Height() を変えたら、ここも同じに直す (ずれると、見た目の地面と歩く地面が合わなくなる)
    //
    // 座標はジオラマの箱の中 (-0.5〜0.5)。高さも同じ単位
    public static class DioramaTerrain
    {
        public struct Info
        {
            public Func<Vector2, float> height;  // xz → 地面の高さ
            public float water;                  // 水面の高さ
            public Vector2 center;               // 島の中心 (ここを向いて立つ)
        }

        // 中に入れる作品なら true。work は作品専用シェーダーの名前 (例: Eruption)、seed は作品名から決めた数
        public static bool TryGet(string work, float seed, out Info info)
        {
            switch (work)
            {
                case "Eruption":
                    info = new Info
                    {
                        height = xz => EruptionHeight(xz, seed),
                        water = -0.22f,
                        center = new Vector2(0.02f, -0.03f),
                    };
                    return true;
                default:
                    info = default;
                    return false;
            }
        }

        // ---------------------------------------------------------------- 大噴火 (DioramaEruption.shader の Height と同じ)

        static float EruptionHeight(Vector2 xz, float seed)
        {
            var crater = new Vector2(0.02f, -0.03f);
            Vector2 c = xz - crater;
            float r = c.magnitude;
            float th = Mathf.Atan2(c.y, c.x);
            float h = -0.40f + 0.58f * Mathf.Exp(-Mathf.Pow(r / 0.25f, 1.7f));
            float gully = 1f - Mathf.Abs(Mathf.Sin(th * 9f + Fbm3(new Vector2(r * 9f + seed, th * 2f + seed)) * 3f));
            h += 0.022f * gully * gully * SmoothStep(0.03f, 0.12f, r) * Mathf.Exp(-r * 2.5f);
            h -= 0.075f * Mathf.Exp(-Mathf.Pow(r / 0.045f, 2f));
            h += 0.012f * Mathf.Exp(-Mathf.Pow((r - 0.055f) / 0.015f, 2f));
            h += 0.012f * Fbm3(new Vector2(xz.x * 14f + seed, xz.y * 14f + seed)) - 0.006f;
            float rid = 1f - Mathf.Abs(ValueNoise(new Vector2(xz.x * 38f + seed * 1.7f, xz.y * 38f + seed * 1.7f)) * 2f - 1f);
            float rid2 = 1f - Mathf.Abs(ValueNoise(new Vector2(xz.x * 81f + seed * 2.3f + 7f, xz.y * 81f + seed * 2.3f + 7f)) * 2f - 1f);
            h += (0.006f * rid * rid + 0.0025f * rid2 * rid2) * SmoothStep(-0.25f, -0.15f, h);
            return h;
        }

        // ---------------------------------------------------------------- シェーダーと同じノイズ

        static float Frac(float x) => x - Mathf.Floor(x);

        // HLSL の smoothstep と同じ (edge0 > edge1 のときも同じ式で動く)
        static float SmoothStep(float edge0, float edge1, float x)
        {
            float t = Mathf.Clamp01((x - edge0) / (edge1 - edge0));
            return t * t * (3f - 2f * t);
        }

        static float Hash21(float x, float y)
        {
            float px = Frac(x * 123.34f);
            float py = Frac(y * 456.21f);
            float d = px * (px + 45.32f) + py * (py + 45.32f);
            px += d;
            py += d;
            return Frac(px * py);
        }

        static float ValueNoise(Vector2 p)
        {
            float ix = Mathf.Floor(p.x), iy = Mathf.Floor(p.y);
            float fx = p.x - ix, fy = p.y - iy;
            float ux = fx * fx * (3f - 2f * fx), uy = fy * fy * (3f - 2f * fy);
            float a = Hash21(ix, iy), b = Hash21(ix + 1f, iy);
            float c = Hash21(ix, iy + 1f), d = Hash21(ix + 1f, iy + 1f);
            return Mathf.Lerp(Mathf.Lerp(a, b, ux), Mathf.Lerp(c, d, ux), uy);
        }

        static float Fbm3(Vector2 p)
        {
            return 0.5f * ValueNoise(p)
                 + 0.25f * ValueNoise(new Vector2(p.x * 2.03f + 17.1f, p.y * 2.03f + 17.1f))
                 + 0.125f * ValueNoise(new Vector2(p.x * 4.1f + 31.7f, p.y * 4.1f + 31.7f));
        }
    }
}
