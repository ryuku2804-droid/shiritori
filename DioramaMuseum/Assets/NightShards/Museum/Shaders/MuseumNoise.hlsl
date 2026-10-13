// 美術館のシェーダーで共有するノイズ関数。MuseumSurface.shader と MuseumArt.shader が #include する
#ifndef NIGHTSHARDS_MUSEUM_NOISE_INCLUDED
#define NIGHTSHARDS_MUSEUM_NOISE_INCLUDED

// 0〜1 の疑似乱数
float Hash21(float2 p)
{
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

float2 Hash22(float2 p)
{
    float3 q = frac(p.xyx * float3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return frac((q.xx + q.yz) * q.zy);
}

// なめらかな値ノイズ (0〜1)
float ValueNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = Hash21(i);
    float b = Hash21(i + float2(1, 0));
    float c = Hash21(i + float2(0, 1));
    float d = Hash21(i + float2(1, 1));
    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

// 細かさの違うノイズを5枚重ねたもの (0〜1 くらい)
float Fbm(float2 p)
{
    float v = 0.0;
    float amp = 0.5;
    for (int k = 0; k < 5; k++)
    {
        v += amp * ValueNoise(p);
        p = p * 2.03 + 17.1;
        amp *= 0.5;
    }
    return v;
}

// ボロノイ (ひび割れ模様)。x: いちばん近い点までの距離 / y: 境目までの近さ (0 で境目) / z: 区画ごとの乱数
float3 Voronoi(float2 x)
{
    float2 n = floor(x);
    float2 f = frac(x);
    float f1 = 8.0;
    float f2 = 8.0;
    float id = 0.0;
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            float2 g = float2(i, j);
            float2 r = g + Hash22(n + g) - f;
            float d = dot(r, r);
            if (d < f1)
            {
                f2 = f1;
                f1 = d;
                id = Hash21(n + g);
            }
            else if (d < f2)
            {
                f2 = d;
            }
        }
    }
    f1 = sqrt(f1);
    f2 = sqrt(f2);
    return float3(f1, f2 - f1, id);
}

// 水の底に揺れる光の網目 (コースティクス)。1 単位ごとにくり返す。0〜1 くらい
float Caustics(float2 uv, float time)
{
    const float TAU = 6.28318530718;
    float2 p = frac(uv) * TAU - 250.0;
    float2 i = p;
    float c = 1.0;
    const float inten = 0.005;
    for (int n = 0; n < 4; n++)
    {
        float t = time * (1.0 - (3.5 / float(n + 1)));
        i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(float2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }
    c /= 4.0;
    c = 1.17 - pow(abs(c), 1.4);
    return pow(abs(c), 8.0);
}

// 線 (継ぎ目・目地) の太さ w を、画面上で1ピクセルより細くならないようにぼかす。遠くでちらつかない。
// px は1ピクセルが何単位にあたるか。微分 (fwidth) は分岐の中で使えないので、呼ぶ側の最初で計算して渡す
float LineMask(float dist, float w, float px)
{
    float aa = max(px, 1e-4);
    return 1.0 - smoothstep(w - aa, w + aa, dist);
}

#endif
