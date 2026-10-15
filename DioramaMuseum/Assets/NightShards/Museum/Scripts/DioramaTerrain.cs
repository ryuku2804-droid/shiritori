using System;
using System.Collections.Generic;
using System.Threading.Tasks;
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
            public bool hasSpawn;                // true なら、立つ場所を spawn に決めてある
            public Vector2 spawn;                // 立つ場所 (xz)
            public Func<Vector2, float> bakeHeight; // シェーダーの高さの表に焼く式 (null なら height と同じ)
            public Func<Vector2, bool> icy;         // そこが氷の上か (つるつる滑る)。null なら氷はない
            public Func<List<Prop>> props;          // ぶつかる物 (柱・木・建物) の一覧。null ならなし
        }

        // ぶつかる物 1 つ分。ジオラマの箱の座標 (-0.5〜0.5) で表す
        public struct Prop
        {
            public bool box;       // true なら箱、false なら縦のカプセル (柱・木の幹)
            public Vector3 bottom; // カプセルの下の端 / 箱の中心
            public float height;   // カプセルの高さ
            public float radius;   // カプセルの半径
            public Vector3 size;   // 箱の大きさ
            public float yaw;      // 箱の向き (ラジアン。シェーダーと同じ向きの決め方)

            public static Prop Capsule(Vector3 bottom, float height, float radius) =>
                new Prop { bottom = bottom, height = height, radius = radius };

            public static Prop Box(Vector3 center, Vector3 size, float yaw) =>
                new Prop { box = true, bottom = center, size = size, yaw = yaw };
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
                case "BlueFire":
                    // 手前 (+z) の焼け野原の端に立ち、奥へ広がる焦土を見渡す
                    info = new Info
                    {
                        height = xz => BlueFireHeight(xz, seed),
                        water = -1f, // 水はない
                        center = Vector2.zero,
                        hasSpawn = true,
                        spawn = new Vector2(0f, 0.36f),
                    };
                    return true;
                case "Glacier":
                    // 手前の湖の岸に立ち、奥の氷河と雪の峰と月を見上げる。シェーダーの表には岩の山だけを焼く (氷河は式で描く)
                    info = new Info
                    {
                        height = xz => GlacierHeight(xz, seed),
                        bakeHeight = xz => GlacierRock(xz, seed),
                        icy = xz => xz.y < TerminusZ(xz.x, seed) && GlacierTop(xz, seed) > GlacierRock(xz, seed) + 0.002f, // 氷河の上
                        water = -0.2f,
                        center = new Vector2(0f, -0.2f),
                        hasSpawn = true,
                        spawn = new Vector2(0f, 0.38f),
                    };
                    return true;
                case "Aurora":
                    // 手前の岸に立ち、凍った湖とオーロラを見る。凍った湖の上も歩ける (氷の面 -0.2 の上に立つ)
                    info = new Info
                    {
                        height = xz => AuroraHeight(xz, seed),
                        icy = xz => AuroraHeight(xz, seed) < -0.2f, // 凍った湖の上
                        water = -0.196f,
                        center = new Vector2(0f, -0.1f),
                        hasSpawn = true,
                        spawn = new Vector2(0f, 0.36f),
                    };
                    return true;
                case "Atoll":
                    // 小島のひとつに立ち、礁湖を見わたす。島の縁から外へ出ると、空へ落ちる (落ちたら小島に戻る)
                    info = new Info
                    {
                        height = xz => AtollWalk(xz, seed),
                        bakeHeight = xz => AtollSeabed(xz, seed),
                        water = -10f, // 水面は AtollWalk の中で扱う
                        center = Vector2.zero,
                        hasSpawn = true,
                        spawn = new Vector2(Mathf.Cos(0.3f), Mathf.Sin(0.3f)) * AtollRing(0.3f, seed),
                    };
                    return true;
                case "DeepSea":
                    // 珊瑚の棚の上 (水の中) に立ち、崖の先の深い海のほうを向く。崖から出ると、深い底へ落ちる
                    info = new Info
                    {
                        height = xz => DeepSeaHeight(xz, seed),
                        bakeHeight = xz => ShelfTop(xz, seed),
                        water = -10f,
                        center = new Vector2(0.4f, 0f),
                        hasSpawn = true,
                        spawn = new Vector2(-0.3f, 0f),
                    };
                    return true;
                case "Terraces":
                    // 手前の里に立ち、奥へ重なる棚田を見上げる
                    info = new Info
                    {
                        height = xz => TerracesHeight(xz, seed),
                        water = -10f,
                        center = new Vector2(-0.05f, -0.2f),
                        hasSpawn = true,
                        spawn = new Vector2(0.22f, 0.36f),
                        props = () => TerracesProps(seed),
                    };
                    return true;
                case "Torii":
                    // 参道の入口に立ち、鳥居のトンネルの奥 (参道の進む向き) を向く
                    info = new Info
                    {
                        height = xz => ToriiHeight(xz, seed),
                        water = -10f,
                        center = new Vector2(-0.1f, ToriiR0),
                        hasSpawn = true,
                        spawn = new Vector2(-0.012f, ToriiR0), // 入口の少し先 (参道の上)
                        props = () => ToriiProps(seed),
                    };
                    return true;
                default:
                    info = default;
                    return false;
            }
        }

        // ---------------------------------------------------------------- 高さの表 (シェーダーを速くする)

        public const int BakeSize = 512;   // 表の細かさ (1 辺のます目の数)
        const float BakeInner = 0.47f;     // 表がおおう範囲 (シェーダーの INNER と同じ)

        static readonly Dictionary<string, Texture2D> baked = new Dictionary<string, Texture2D>();

        // 地形の高さを、512×512 の表 (1 チャンネルの浮動小数の画像) に 1 回だけ計算して保存する。
        // シェーダーは線を進めるたびにこの表を読むだけになるので、ノイズを毎回計算するよりずっと速い。
        // 同じ作品・同じ形 (seed) なら、2 回目からは保存したものを返す。中に入れない作品なら null
        public static Texture2D BakeHeight(string work, float seed)
        {
            string key = work + "/" + seed.ToString("R");
            if (baked.TryGetValue(key, out var cached) && cached != null) return cached;
            if (!TryGet(work, seed, out var info)) return null;
            Func<Vector2, float> bake = info.bakeHeight ?? info.height;

            int n = BakeSize;
            var data = new float[n * n];
            // 行ごとに、CPU のいくつものコアで同時に計算する
            Parallel.For(0, n, j =>
            {
                float z = -BakeInner + (j + 0.5f) / n * 2f * BakeInner;
                for (int i = 0; i < n; i++)
                {
                    float x = -BakeInner + (i + 0.5f) / n * 2f * BakeInner;
                    data[j * n + i] = bake(new Vector2(x, z));
                }
            });

            var tex = new Texture2D(n, n, TextureFormat.RFloat, false, true)
            {
                name = "Baked Height " + work,
                wrapMode = TextureWrapMode.Clamp,
                filterMode = FilterMode.Bilinear,
            };
            tex.SetPixelData(data, 0);
            tex.Apply(false, true); // CPU 側の写しは捨てて、メモリを節約する
            baked[key] = tex;
            return tex;
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

        // ---------------------------------------------------------------- 青い火の焦土 (DioramaBlueFire.shader の Height と同じ)
        // 枯れ木には当たり判定を付けない (歩いて通り抜けられる)

        static float BlueFireHeight(Vector2 xz, float seed)
        {
            float h = -0.2f + 0.05f * Fbm3(new Vector2(xz.x * 3f + seed, xz.y * 3f + seed)) - 0.025f;
            float ax = (xz.x + 0.22f) / 0.15f, az = (xz.y + 0.22f) / 0.15f;
            float bx = (xz.x - 0.25f) / 0.12f, bz = (xz.y + 0.05f) / 0.12f;
            h += 0.08f * Mathf.Exp(-(ax * ax + az * az)) + 0.05f * Mathf.Exp(-(bx * bx + bz * bz));
            float river = (xz.x - 0.1f - 0.08f * Mathf.Sin(xz.y * 6f + seed)) / 0.03f;
            h -= 0.025f * Mathf.Exp(-river * river);
            h += 0.01f * Fbm3(new Vector2(xz.x * 14f + seed, xz.y * 14f + seed)) - 0.005f;
            float rid = 1f - Mathf.Abs(ValueNoise(new Vector2(xz.x * 38f + seed * 1.7f, xz.y * 38f + seed * 1.7f)) * 2f - 1f);
            float rid2 = 1f - Mathf.Abs(ValueNoise(new Vector2(xz.x * 81f + seed * 2.3f + 7f, xz.y * 81f + seed * 2.3f + 7f)) * 2f - 1f);
            h += 0.004f * rid * rid + 0.002f * rid2 * rid2;
            return h;
        }

        // ---------------------------------------------------------------- 月下の氷河 (DioramaGlacier.shader と同じ)

        static float ValleyX(float z, float seed) => 0.05f * Mathf.Sin(z * 5f + seed);

        static float GlacierFloor(float z)
        {
            return Mathf.Lerp(-0.26f, 0.02f, SmoothStep(0f, -0.45f, z)) + 0.11f * SmoothStep(0.24f, 0.44f, z);
        }

        static float Ridged(Vector2 p)
        {
            float s = 0f, a = 0.5f, w = 1f;
            for (int i = 0; i < 4; i++)
            {
                float n = 1f - Mathf.Abs(ValueNoise(p) * 2f - 1f);
                n = n * n * w;
                w = Mathf.Clamp01(n * 1.5f);
                s += n * a;
                p = new Vector2(p.x * 2.07f + 13.1f, p.y * 2.07f + 13.1f);
                a *= 0.5f;
            }
            return s;
        }

        static float GlacierRock(Vector2 xz, float seed)
        {
            float side = Mathf.Abs(xz.x - ValleyX(xz.y, seed));
            float back = SmoothStep(-0.12f, -0.44f, xz.y);
            float m = 0.3f * Mathf.Max(SmoothStep(0.1f, 0.42f, side), back);
            float h = GlacierFloor(xz.y) + m * (0.15f + 0.85f * Ridged(new Vector2(xz.x * 4f + seed, xz.y * 4f + seed)));
            h += 0.008f * Fbm3(new Vector2(xz.x * 20f + seed, xz.y * 20f + seed)) - 0.004f;
            return h;
        }

        static float TerminusZ(float x, float seed)
        {
            float dx = (x - ValleyX(-0.02f, seed)) / 0.2f;
            return -0.04f + 0.05f * Mathf.Clamp01(1f - dx * dx);
        }

        static float GlacierTop(Vector2 xz, float seed)
        {
            float dx = (xz.x - ValleyX(xz.y, seed)) / 0.2f;
            float prof = Mathf.Clamp01(1f - dx * dx * dx * dx);
            float cv = Mathf.Sin((xz.y + 0.05f * dx * dx) * 140f + ValueNoise(new Vector2(xz.x * 30f + seed, xz.y * 30f + seed)) * 3f);
            return GlacierFloor(xz.y) + 0.13f * prof - 0.005f * SmoothStep(0.7f, 1f, cv) * prof;
        }

        // 歩く地面: 岩の山と、氷河の表面の高いほう (氷河は、湖に面した崖より奥だけ)
        static float GlacierHeight(Vector2 xz, float seed)
        {
            float h = GlacierRock(xz, seed);
            if (xz.y < TerminusZ(xz.x, seed)) h = Mathf.Max(h, GlacierTop(xz, seed));
            return h;
        }

        // ---------------------------------------------------------------- オーロラの夜 (DioramaAurora.shader の LandHeight と同じ)
        // 針葉樹には当たり判定を付けない (歩いて通り抜けられる)

        static float AuroraHeight(Vector2 xz, float seed)
        {
            float qx = xz.x, qz = (xz.y + 0.03f) * 1.35f;
            float r = Mathf.Sqrt(qx * qx + qz * qz);
            float h = -0.24f + 0.1f * SmoothStep(0.18f, 0.32f, r);
            float back = SmoothStep(-0.15f, -0.44f, xz.y);
            h += 0.22f * back * (0.3f + 0.7f * Fbm3(new Vector2(xz.x * 3f + seed, xz.y * 3f + seed)));
            h += 0.03f * Fbm3(new Vector2(xz.x * 6f + seed * 1.3f, xz.y * 6f + seed * 1.3f)) * SmoothStep(0.25f, 0.35f, r);
            h += 0.006f * Fbm3(new Vector2(xz.x * 20f + seed, xz.y * 20f + seed)) - 0.003f;
            return h;
        }

        // ---------------------------------------------------------------- 環礁 (DioramaAtoll.shader と同じ)

        const float AtollSea = 0.05f;
        static readonly float[] MotuA = { 0.3f, 1.55f, 2.7f, 3.95f, 5.15f };
        static readonly float[] FallA = { 0.95f, 2.2f, 3.35f, 4.6f };

        static float AtollDisk(float th, float seed) => 0.35f + 0.02f * Mathf.Sin(th * 3f + seed) + 0.012f * Mathf.Sin(th * 7f + seed * 2.1f);
        static float AtollRing(float th, float seed) => 0.21f + 0.015f * Mathf.Sin(th * 3f + seed * 1.7f);

        static float SpillDip(float th)
        {
            float s = 0f;
            foreach (float a in FallA)
            {
                float d = AngDist(th, a) / 0.1f;
                s = Mathf.Max(s, Mathf.Exp(-d * d));
            }
            return s;
        }

        static float AngDist(float a, float b) => Mathf.Abs(Mathf.Atan2(Mathf.Sin(a - b), Mathf.Cos(a - b)));

        static float AtollSeabed(Vector2 xz, float seed)
        {
            float r = xz.magnitude;
            float th = Mathf.Atan2(xz.y, xz.x);
            float R = AtollDisk(th, seed);
            float ring = AtollRing(th, seed);
            float outer = Mathf.Lerp(AtollSea - 0.055f, AtollSea - 0.02f, SmoothStep(R - 0.02f, ring + 0.05f, r));
            float lagoon = AtollSea - 0.022f + 0.006f * Fbm3(new Vector2(xz.x * 12f + seed, xz.y * 12f + seed));
            float h = Mathf.Lerp(lagoon, outer, SmoothStep(ring - 0.01f, ring + 0.01f, r));
            float rd = (r - ring) / 0.022f;
            h = Mathf.Max(h, AtollSea - 0.006f + 0.004f * ValueNoise(new Vector2(xz.x * 60f + seed, xz.y * 60f + seed)) - 0.03f * (1f - Mathf.Exp(-rd * rd)));
            for (int k = 0; k < MotuA.Length; k++)
            {
                float a = MotuA[k];
                Vector2 c = new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * AtollRing(a, seed);
                Vector2 d = (xz - c) / (0.038f + 0.006f * (1f + Mathf.Sin(k * 2.3f + seed)));
                h = Mathf.Max(h, AtollSea - 0.012f + (0.035f + 0.006f * ValueNoise(new Vector2(xz.x * 40f, xz.y * 40f))) * Mathf.Exp(-Vector2.Dot(d, d)));
            }
            float lip = (r - (R - 0.008f)) / 0.007f;
            h = Mathf.Max(h, AtollSea + 0.002f - 0.009f * SpillDip(th) - 0.06f * (1f - Mathf.Exp(-lip * lip)));
            return h;
        }

        // 歩く地面: 島の上は、海の底と水面の高いほう (浅瀬を歩く)。島の外は、はるか下 (落ちる)
        static float AtollWalk(Vector2 xz, float seed)
        {
            float th = Mathf.Atan2(xz.y, xz.x);
            if (xz.magnitude > AtollDisk(th, seed) - 0.006f) return -10f;
            return Mathf.Max(AtollSeabed(xz, seed), AtollSea - 0.004f);
        }

        // ---------------------------------------------------------------- 海の断面 (DioramaDeepSea.shader と同じ)

        static float ShelfTop(Vector2 xz, float seed)
        {
            float h = 0.15f + 0.02f * Fbm3(new Vector2(xz.x * 5f + seed, xz.y * 5f + seed));
            float c1 = 1f - Mathf.Abs(ValueNoise(new Vector2(xz.x * 22f + seed, xz.y * 22f + seed)) * 2f - 1f);
            float c2 = 1f - Mathf.Abs(ValueNoise(new Vector2(xz.x * 50f + seed * 1.3f, xz.y * 50f + seed * 1.3f)) * 2f - 1f);
            float coral = c1 * c1 * 0.8f + c2 * c2 * 0.4f;
            h += 0.03f * coral * SmoothStep(0.35f, 0.6f, ValueNoise(new Vector2(xz.x * 7f + seed * 2f, xz.y * 7f + seed * 2f)));
            return h;
        }

        static float CliffX(float y, float z, float seed)
        {
            return 0.03f + 0.04f * Mathf.Sin(z * 4f + seed) + 0.016f * (ValueNoise(new Vector2(z * 5f + seed, y * 3f + seed)) - 0.5f)
                 + 0.004f * Mathf.Sin(y * 55f + Mathf.Sin(z * 3f) * 2f);
        }

        static float AbyssFloor(Vector2 xz, float seed)
        {
            return -0.38f + 0.03f * Fbm3(new Vector2(xz.x * 4f + seed, xz.y * 4f + seed));
        }

        // 歩く地面: 崖より手前は珊瑚の棚、先は深い底 (崖の面の高さによるでこぼこは、棚の高さで代表させる)
        static float DeepSeaHeight(Vector2 xz, float seed)
        {
            return xz.x < CliffX(0.15f, xz.y, seed) ? ShelfTop(xz, seed) : AbyssFloor(xz, seed);
        }

        // ---------------------------------------------------------------- 黄昏の棚田 (DioramaTerraces.shader と同じ)

        const float TerraceStep = 0.022f;

        static float TerraceSlope(Vector2 xz, float seed)
        {
            float back = SmoothStep(0.42f, -0.45f, xz.y);
            return -0.24f + 0.34f * back + 0.05f * Mathf.Sin(xz.x * 4f + seed) * back
                 + 0.04f * (Fbm3(new Vector2(xz.x * 3f + seed, xz.y * 3f + seed)) - 0.45f);
        }

        static float TerracesHeight(Vector2 xz, float seed)
        {
            float S = TerraceSlope(xz, seed);
            float u = S / TerraceStep;
            float k = Mathf.Floor(u);
            float f = u - k;
            float terr = (k + SmoothStep(0.75f, 1f, f)) * TerraceStep;
            float bund = (f - 0.7f) / 0.035f;
            terr += 0.004f * Mathf.Exp(-bund * bund);
            float mask = SmoothStep(-0.21f, -0.18f, S) * SmoothStep(0.08f, 0.04f, S);
            float h = Mathf.Lerp(S, terr, mask);
            h += 0.003f * Fbm3(new Vector2(xz.x * 30f + seed, xz.y * 30f + seed)) * (1f - mask * 0.8f);
            return h;
        }

        // ---------------------------------------------------------------- 千本鳥居の山 (DioramaTorii.shader と同じ)

        const float ToriiR0 = 0.37f, ToriiR1 = 0.045f, ToriiTurns = 2.25f, ToriiTh0 = 1.5707963f;

        static float MountainBase(float r) => -0.26f + 0.5f * Mathf.Pow(Mathf.Clamp01(1f - r / 0.48f), 1.6f);

        static Vector2 ToriiPathCoord(Vector2 xz)
        {
            float total = ToriiTurns * 2f * Mathf.PI;
            float r = xz.magnitude;
            float th = Mathf.Atan2(xz.y, xz.x);
            float sr = (ToriiR0 - r) / (ToriiR0 - ToriiR1);
            float m = Mathf.Round((sr * total - (th - ToriiTh0)) / (2f * Mathf.PI));
            float sRaw = (th - ToriiTh0 + 2f * Mathf.PI * m) / total;
            float s = Mathf.Clamp01(sRaw);
            float across = r - Mathf.Lerp(ToriiR0, ToriiR1, s);
            if (sRaw < -0.002f || sRaw > 1.002f) across = 1f;
            return new Vector2(s, across);
        }

        static float ToriiPathY(float s) => MountainBase(Mathf.Lerp(ToriiR0, ToriiR1, s));

        static float ToriiHeight(Vector2 xz, float seed)
        {
            float r = xz.magnitude;
            float th = Mathf.Atan2(xz.y, xz.x);
            float h = MountainBase(r) + 0.035f * (Fbm3(new Vector2(xz.x * 5f + seed, xz.y * 5f + seed)) - 0.45f);
            h += 0.008f * Mathf.Sin(th * 9f + Fbm3(new Vector2(xz.x * 7f, xz.y * 7f)) * 4f) * SmoothStep(0.05f, 0.2f, r);
            Vector2 pc = ToriiPathCoord(xz);
            float onPath = SmoothStep(0.016f, 0.009f, Mathf.Abs(pc.y));
            h = Mathf.Lerp(h, ToriiPathY(pc.x) - 0.001f, onPath);
            h = Mathf.Lerp(h, ToriiPathY(1f) + 0.002f, SmoothStep(0.05f, 0.035f, r));
            return h;
        }

        // ---------------------------------------------------------------- ぶつかる物 (シェーダーと同じ置き方)

        static float Hash21(Vector2 p) => Hash21(p.x, p.y);
        static Vector2 Hash22b(Vector2 p) => new Vector2(Hash21(p), Hash21(p + new Vector2(17.3f, 17.3f)));

        // シェーダーの Cedars と同じ置き方で、杉の幹のカプセルを並べる
        static void AddCedars(List<Prop> list, float cellSize, float skip, float seed, Func<Vector2, bool> allowed, Func<Vector2, float> ground, float minH, float rangeH)
        {
            const float inner = 0.47f;
            int c0 = Mathf.FloorToInt(-inner / cellSize), c1 = Mathf.FloorToInt(inner / cellSize);
            for (int cz = c0; cz <= c1; cz++)
            {
                for (int cx = c0; cx <= c1; cx++)
                {
                    var cell = new Vector2(cx, cz);
                    var id = cell + new Vector2(seed * 0.37f, seed * 0.37f);
                    if (Hash21(id) > skip) continue;
                    Vector2 jitter = Hash22b(id + new Vector2(1.3f, 1.3f)) - new Vector2(0.5f, 0.5f);
                    Vector2 b = (cell + new Vector2(0.5f, 0.5f)) * cellSize + jitter * cellSize * 0.5f;
                    if (Mathf.Abs(b.x) > inner - 0.02f || Mathf.Abs(b.y) > inner - 0.02f) continue;
                    if (!allowed(b)) continue;
                    float height = minH + rangeH * Hash21(id + new Vector2(3.3f, 3.3f));
                    list.Add(Prop.Capsule(new Vector3(b.x, ground(b) - 0.003f, b.y), height * 0.6f, 0.003f));
                }
            }
        }

        static List<Prop> TerracesProps(float seed)
        {
            var list = new List<Prop>();
            // 家 (シェーダーの HOUSE と同じ場所と向き)
            Vector3[] houses = { new Vector3(0.17f, 0.3f, 0.3f), new Vector3(0.31f, 0.23f, -0.4f), new Vector3(0.08f, 0.39f, 0.1f), new Vector3(0.33f, 0.38f, 1.2f) };
            foreach (var h in houses)
            {
                float y = TerracesHeight(new Vector2(h.x, h.y), seed) - 0.002f;
                list.Add(Prop.Box(new Vector3(h.x, y + 0.014f, h.y), new Vector3(0.034f, 0.028f, 0.024f), h.z));
            }
            AddCedars(list, 0.045f, 0.7f, seed, b => TerraceSlope(b, seed) >= 0.06f, b => TerracesHeight(b, seed), 0.05f, 0.03f);
            return list;
        }

        static List<Prop> ToriiProps(float seed)
        {
            var list = new List<Prop>();
            float total = ToriiTurns * 2f * Mathf.PI;
            const float sp = 0.0055f;
            float arcMax = total * (ToriiR0 - 0.5f * (ToriiR0 - ToriiR1));
            for (int i = 0; i * sp <= arcMax; i++)
            {
                // 入口からの長さ i * sp の所の s (道の長さの式を、s について解く)
                float A = i * sp;
                float disc = ToriiR0 * ToriiR0 - 2f * (ToriiR0 - ToriiR1) * A / total;
                if (disc < 0f) break;
                float s = (ToriiR0 - Mathf.Sqrt(disc)) / (ToriiR0 - ToriiR1);
                if (s < 0.012f || s > 0.93f) continue;
                float r = Mathf.Lerp(ToriiR0, ToriiR1, s);
                float th = ToriiTh0 + s * total;
                var dir = new Vector2(Mathf.Cos(th), Mathf.Sin(th));
                float y = ToriiPathY(s);
                for (int side = -1; side <= 1; side += 2)
                {
                    Vector2 c = dir * (r + side * 0.0062f);
                    list.Add(Prop.Capsule(new Vector3(c.x, y, c.y), 0.0172f, 0.0008f)); // 鳥居の柱
                }
                if (i % 12 == 0)
                {
                    Vector2 c = dir * (r + 0.0128f);
                    list.Add(Prop.Capsule(new Vector3(c.x, y, c.y), 0.0097f, 0.0022f));  // 石灯籠
                }
            }
            AddCedars(list, 0.04f, 0.65f, seed, b => Mathf.Abs(ToriiPathCoord(b).y) >= 0.026f && b.magnitude >= 0.06f, b => ToriiHeight(b, seed), 0.05f, 0.035f);
            // 山頂の社
            list.Add(Prop.Box(new Vector3(0f, ToriiPathY(1f) + 0.002f + 0.012f, 0f), new Vector3(0.026f, 0.024f, 0.02f), 0f));
            return list;
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
