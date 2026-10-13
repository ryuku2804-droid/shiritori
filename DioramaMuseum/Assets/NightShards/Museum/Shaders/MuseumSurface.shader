// 美術館の床・壁・天井・台座の質感。テクスチャ画像は使わず、ワールド座標からノイズで模様を作る。
// _Kind で種類を切り替える: 0 打ち放しコンクリート / 1 木の床 / 2 石 (研ぎ出し) / 3 漆喰
// サーフェスシェーダーなので、スポットライトや影は Unity の標準ライティング (Standard) がそのまま効く
Shader "NightShards/MuseumSurface"
{
    Properties
    {
        [Enum(Concrete,0,Wood,1,Stone,2,Plaster,3)] _Kind ("Kind", Float) = 0
        _ColorA ("Color A", Color) = (0.46, 0.45, 0.43, 1)
        _ColorB ("Color B", Color) = (0.34, 0.33, 0.32, 1)
        _Smoothness ("Smoothness", Range(0, 1)) = 0.2
        _Scale ("Pattern Scale", Float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.5

        float _Kind;
        fixed4 _ColorA;
        fixed4 _ColorB;
        half _Smoothness;
        float _Scale;

        struct Input
        {
            float3 worldPos;
            float3 worldNormal;
        };

        // ---------------------------------------------------------------- ノイズ

        float Hash21(float2 p)
        {
            p = frac(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return frac(p.x * p.y);
        }

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

        // 線 (継ぎ目・目地) の太さ w を、画面上で1ピクセルより細くならないようにぼかす。遠くでちらつかない。
        // px は1ピクセルが何 m にあたるか。微分 (fwidth) は分岐の中で使えないので、surf の最初で計算して渡す
        float LineMask(float dist, float w, float px)
        {
            float aa = max(px, 1e-4);
            return 1.0 - smoothstep(w - aa, w + aa, dist);
        }

        // ---------------------------------------------------------------- 種類ごとの模様

        // 打ち放しコンクリート: 1800×900 の型枠の継ぎ目と、600×450 間隔のセパ穴 (型枠を留めた丸い穴)
        void Concrete(float2 uv, float px, out float3 albedo, out float gloss, out float occ)
        {
            float cloud = Fbm(uv * 0.55);
            float grain = ValueNoise(uv * 38.0) - 0.5;
            float streak = Fbm(float2(uv.x * 2.5, uv.y * 0.25)); // 縦に流れる雨じみのようなむら
            albedo = lerp(_ColorB.rgb, _ColorA.rgb, saturate(cloud * 1.2 - 0.1));
            albedo *= 1.0 + grain * 0.08;
            albedo *= lerp(0.92, 1.04, streak);
            gloss = _Smoothness * (0.8 + 0.4 * cloud);
            occ = 1.0;

            float2 panel = float2(1.8, 0.9);
            float2 g = frac(uv / panel) * panel;
            float seamDist = min(min(g.x, panel.x - g.x), min(g.y, panel.y - g.y));
            float seam = LineMask(seamDist, 0.004, px);

            float2 pitch = float2(0.6, 0.45);
            float2 q = uv - float2(0.3, 0.225);
            q -= pitch * round(q / pitch);
            float r = length(q);
            float hole = LineMask(r, 0.014, px);
            float ring = LineMask(abs(r - 0.022), 0.004, px) * (1.0 - hole);

            albedo *= 1.0 - seam * 0.35;
            albedo *= 1.0 - hole * 0.55;
            albedo *= 1.0 + ring * 0.08;
            occ = 1.0 - hole * 0.6 - seam * 0.3;
            gloss *= 1.0 - hole;
        }

        // 木の床: 幅19cm・長さ1.8mの板を、列ごとにずらして張る。木目は板の長さ方向に伸ばしたノイズ
        void Wood(float2 uv, float px, out float3 albedo, out float gloss, out float occ)
        {
            float w = 0.19;
            float len = 1.8;
            float row = floor(uv.y / w);
            float along = uv.x + Hash21(float2(row, 7.0)) * 3.0;
            float plank = floor(along / len);
            float h = Hash21(float2(row, plank));

            float grain = Fbm(float2(along * 0.7, uv.y * 26.0 + h * 10.0));
            float rings = sin((uv.y * 70.0 + grain * 9.0 + h * 6.0)) * 0.5 + 0.5;
            float tone = saturate(grain * 0.8 + rings * 0.25);
            albedo = lerp(_ColorB.rgb, _ColorA.rgb, tone) * (0.82 + 0.32 * h);

            float dy = frac(uv.y / w) * w;
            float dx = frac(along / len) * len;
            float gapDist = min(min(dy, w - dy), min(dx, len - dx));
            float gap = LineMask(gapDist, 0.0015, px);
            albedo *= 1.0 - gap * 0.6;
            gloss = _Smoothness * (0.75 + 0.35 * grain) * (1.0 - gap);
            occ = 1.0 - gap * 0.5;
        }

        // 石の研ぎ出し: 雲のようなむらに細かい粒を散らし、1.2m 角の目地を入れる。よく磨いてあるので光を映す
        void Stone(float2 uv, float px, out float3 albedo, out float gloss, out float occ)
        {
            float cloud = Fbm(uv * 0.8);
            float chip = step(0.86, ValueNoise(uv * 85.0));
            float chip2 = step(0.9, ValueNoise(uv * 140.0 + 31.0));
            albedo = lerp(_ColorA.rgb, _ColorB.rgb, cloud);
            albedo += chip * 0.06 + chip2 * 0.04;

            float tile = 1.2;
            float2 g = frac(uv / tile) * tile;
            float jointDist = min(min(g.x, tile - g.x), min(g.y, tile - g.y));
            float joint = LineMask(jointDist, 0.0015, px);
            albedo *= 1.0 - joint * 0.5;
            gloss = _Smoothness * (0.9 + 0.1 * cloud) * (1.0 - joint * 0.6);
            occ = 1.0 - joint * 0.4;
        }

        // 漆喰: ごく弱いむらだけ。台座や仮の箱に使う
        void Plaster(float2 uv, float px, out float3 albedo, out float gloss, out float occ)
        {
            float cloud = Fbm(uv * 2.0);
            float grain = ValueNoise(uv * 60.0) - 0.5;
            albedo = lerp(_ColorA.rgb, _ColorB.rgb, cloud) * (1.0 + grain * 0.04);
            gloss = _Smoothness * (0.85 + 0.3 * cloud);
            occ = 1.0;
        }

        // ---------------------------------------------------------------- 本体

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            // 面の向きでいちばん近い平面に投影する (床と天井は xz、壁は xy か zy)
            float3 n = abs(normalize(IN.worldNormal));
            bool horizontal = n.y > max(n.x, n.z);
            float2 uv = horizontal ? IN.worldPos.xz : (n.x > n.z ? IN.worldPos.zy : IN.worldPos.xy);
            uv /= max(_Scale, 1e-3);
            float px = length(fwidth(uv)) * 0.7;

            float3 albedo;
            float gloss;
            float occ;
            if (_Kind < 0.5)      Concrete(uv, px, albedo, gloss, occ);
            else if (_Kind < 1.5) Wood(uv, px, albedo, gloss, occ);
            else if (_Kind < 2.5) Stone(uv, px, albedo, gloss, occ);
            else                  Plaster(uv, px, albedo, gloss, occ);

            o.Albedo = albedo;
            o.Metallic = 0;
            o.Smoothness = saturate(gloss);
            o.Occlusion = saturate(occ);
        }
        ENDCG
    }

    FallBack "Diffuse"
}
