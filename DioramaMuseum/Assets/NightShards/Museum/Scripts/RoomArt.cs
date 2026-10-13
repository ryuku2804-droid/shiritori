using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 展示室を、部屋ごとのアート (インスタレーション) にする。床・壁の質感は MuseumBuilder がテーマで選び、
    // ここではその上に置くもの (月・光の糸・溶岩の熱・火の粉・障子と夕日) を作る
    public static class RoomArt
    {
        // 部屋の寸法と向き。座標はすべて建物の親 (Museum (Generated)) から見たもの
        public struct RoomInfo
        {
            public Transform parent;
            public Vector3 center;      // 床の中心
            public Vector3 forward;     // 入口から奥へ向かう向き
            public Vector3 right;
            public float width;         // forward と直角の幅
            public float depth;         // forward の向きの奥行き
            public float height;        // 天井の高さ
            public Color accent;
            public List<Vector3> exhibits; // 台座の位置
        }

        // 作ったライト。明るさの倍率 (Brightness) を後からかけられるよう、MuseumBuilder に返す
        public static List<Light> Build(RoomTheme theme, RoomInfo room, Shader artShader)
        {
            var lights = new List<Light>();
            if (artShader == null) artShader = Shader.Find("NightShards/MuseumArt");
            if (artShader == null)
            {
                Debug.LogError("[Museum] シェーダー NightShards/MuseumArt が見つかりません。MuseumArt.shader を Assets に入れてください。");
                return lights;
            }

            var art = new GameObject("Art").transform;
            art.SetParent(room.parent, false);

            switch (theme)
            {
                case RoomTheme.Moon: Moon(room, art, artShader, lights); break;
                case RoomTheme.Fire: Fire(room, art, artShader, lights); break;
                case RoomTheme.Dusk: Dusk(room, art, artShader, lights); break;
                case RoomTheme.Sea: Sea(room, art, lights); break;
            }
            return lights;
        }

        // ---------------------------------------------------------------- 月の間

        // 奥の壁いっぱいの月、天井から下がる無数の光の糸。床の水盤には、反射プローブで月と糸が映る
        static void Moon(RoomInfo room, Transform art, Shader shader, List<Light> lights)
        {
            float size = Mathf.Min(room.width * 0.45f, room.height * 0.8f);
            Panel(art, "Moon", room.center + room.forward * (room.depth * 0.5f - 0.03f) + Vector3.up * (room.height * 0.55f),
                room.forward, new Vector2(size, size), MakeArt(shader, "Moon", 0, new Color(1.6f, 1.6f, 1.7f), additive: true));

            var threads = new GameObject("Light Threads");
            threads.transform.SetParent(art, false);
            threads.transform.localPosition = room.center;
            threads.AddComponent<MeshFilter>();
            threads.AddComponent<MeshRenderer>().sharedMaterial = MakeArt(shader, "Light Thread", 1, new Color(0.7f, 0.85f, 1.6f), additive: true);
            var avoid = new List<Vector3>();
            foreach (var e in room.exhibits) avoid.Add(e - room.center);
            Vector2 area = Mathf.Abs(room.forward.z) > 0.5f
                ? new Vector2(room.width - 1f, room.depth - 1f)
                : new Vector2(room.depth - 1f, room.width - 1f);
            threads.AddComponent<LightThreads>().Setup(area, room.height - 0.05f, avoid);

            // 月の光が水盤に映るように、部屋の反射を再生の最初に1回だけ撮る
            var probeGo = new GameObject("Reflection");
            probeGo.transform.SetParent(art, false);
            probeGo.transform.localPosition = room.center + Vector3.up * 1.2f;
            var probe = probeGo.AddComponent<ReflectionProbe>();
            probe.mode = UnityEngine.Rendering.ReflectionProbeMode.Realtime;
            probe.refreshMode = UnityEngine.Rendering.ReflectionProbeRefreshMode.OnAwake;
            probe.timeSlicingMode = UnityEngine.Rendering.ReflectionProbeTimeSlicingMode.AllFacesAtOnce;
            probe.boxProjection = true;
            probe.size = Mathf.Abs(room.forward.z) > 0.5f
                ? new Vector3(room.width, room.height, room.depth)
                : new Vector3(room.depth, room.height, room.width);
            probe.center = Vector3.up * (room.height * 0.5f - 1.2f);
            probe.resolution = 256;
        }

        // ---------------------------------------------------------------- 火の間

        // 床のひびから熱が立ちのぼり、火の粉がゆっくり舞い上がる
        static void Fire(RoomInfo room, Transform art, Shader shader, List<Light> lights)
        {
            // 床の溶岩の照り返し。床すれすれの橙の光で、壁と台座の下のほうを赤く染める
            foreach (float side in new[] { -0.3f, 0.3f })
            {
                var go = new GameObject("Lava Glow");
                go.transform.SetParent(art, false);
                go.transform.localPosition = room.center + room.right * (room.width * side) + Vector3.up * 0.25f;
                var l = go.AddComponent<Light>();
                l.type = LightType.Point;
                l.color = new Color(1f, 0.35f, 0.08f);
                l.intensity = 3f;
                l.range = 5f;
                l.shadows = LightShadows.None;
                lights.Add(l);
            }

            var embers = new GameObject("Embers");
            embers.transform.SetParent(art, false);
            embers.transform.localPosition = room.center + Vector3.up * 0.05f;
            embers.transform.localRotation = Quaternion.Euler(-90f, 0f, 0f); // パーティクルは +z へ飛ぶので、上へ向ける
            var ps = embers.AddComponent<ParticleSystem>();

            var main = ps.main;
            main.loop = true;
            main.prewarm = true;
            main.playOnAwake = true;
            main.startLifetime = new ParticleSystem.MinMaxCurve(6f, 11f);
            main.startSpeed = new ParticleSystem.MinMaxCurve(0.15f, 0.5f);
            main.startSize = new ParticleSystem.MinMaxCurve(0.025f, 0.06f);
            main.startColor = new ParticleSystem.MinMaxGradient(new Color(1f, 0.55f, 0.15f), new Color(1f, 0.25f, 0.05f));
            main.gravityModifier = -0.01f;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.maxParticles = 400;

            var emission = ps.emission;
            emission.rateOverTime = 30f;

            var shape = ps.shape;
            shape.shapeType = ParticleSystemShapeType.Box;
            bool alongZ = Mathf.Abs(room.forward.z) > 0.5f;
            float sx = alongZ ? room.width : room.depth;
            float sz = alongZ ? room.depth : room.width;
            shape.scale = new Vector3(sx - 1f, sz - 1f, 0.1f); // 回してあるので、y が奥行きになる

            var noise = ps.noise;
            noise.enabled = true;
            noise.strength = 0.25f;
            noise.frequency = 0.3f;
            noise.scrollSpeed = 0.15f;

            var fade = ps.colorOverLifetime;
            fade.enabled = true;
            var gradient = new Gradient();
            gradient.SetKeys(
                new[] { new GradientColorKey(Color.white, 0f), new GradientColorKey(new Color(1f, 0.6f, 0.4f), 1f) },
                new[] { new GradientAlphaKey(0f, 0f), new GradientAlphaKey(1f, 0.15f), new GradientAlphaKey(0.8f, 0.6f), new GradientAlphaKey(0f, 1f) });
            fade.color = new ParticleSystem.MinMaxGradient(gradient);

            var renderer = embers.GetComponent<ParticleSystemRenderer>();
            renderer.renderMode = ParticleSystemRenderMode.Billboard;
            renderer.sharedMaterial = MakeArt(shader, "Ember", 3, new Color(2.5f, 2.5f, 2.5f), additive: true);
            if (Application.isPlaying) ps.Play(); // 再生中に作ったときは、自分で動かし始める
        }

        // ---------------------------------------------------------------- 夕の間

        // 奥の壁一面の障子に夕日が透け、格子の影が床にのびる。影は再生中にゆっくり長くなったり短くなったりする
        static void Dusk(RoomInfo room, Transform art, Shader shader, List<Light> lights)
        {
            float h = Mathf.Min(3.6f, room.height - 0.6f);
            Panel(art, "Shoji", room.center + room.forward * (room.depth * 0.5f - 0.03f) + Vector3.up * (h * 0.5f + 0.05f),
                room.forward, new Vector2(room.width - 0.6f, h), MakeArt(shader, "Shoji", 2, new Color(1.6f, 1.6f, 1.6f), additive: false));

            var sunGo = new GameObject("Shoji Sun");
            sunGo.transform.SetParent(art, false);
            sunGo.transform.localPosition = room.center + room.forward * (room.depth * 0.5f - 0.4f) + Vector3.up * (h + 0.3f);
            var sun = sunGo.AddComponent<Light>();
            sun.type = LightType.Spot;
            sun.color = new Color(1f, 0.58f, 0.3f);
            sun.intensity = 40f;
            sun.range = room.depth + 6f;
            sun.spotAngle = 80f;
            sun.shadows = LightShadows.None;
            lights.Add(sun);
            var shojiSun = sunGo.AddComponent<ShojiSun>();
            shojiSun.aimFlat = -room.forward;
        }

        // ---------------------------------------------------------------- 海の間

        // 壁・天井・床に水の光が揺れる (MuseumSurface の「水の光」の質感)。ここでは青緑の光を少し足すだけ
        static void Sea(RoomInfo room, Transform art, List<Light> lights)
        {
            var go = new GameObject("Sea Sky");
            go.transform.SetParent(art, false);
            go.transform.localPosition = room.center + Vector3.up * (room.height - 0.4f);
            var l = go.AddComponent<Light>();
            l.type = LightType.Point;
            l.color = new Color(0.55f, 0.9f, 1f);
            l.intensity = 8f;
            l.range = Mathf.Max(room.width, room.depth);
            l.shadows = LightShadows.None;
            lights.Add(l);
        }

        // ---------------------------------------------------------------- 共通

        // 壁に貼る板 (Quad)。normalInto は壁に向かう向き (板の表は部屋の中を向く)
        public static GameObject Panel(Transform parent, string name, Vector3 pos, Vector3 normalInto, Vector2 size, Material mat)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Quad);
            go.name = name;
            go.transform.SetParent(parent, false);
            go.transform.localPosition = pos;
            go.transform.localRotation = Quaternion.LookRotation(normalInto);
            go.transform.localScale = new Vector3(size.x, size.y, 1f);
            go.GetComponent<Renderer>().sharedMaterial = mat;
            var col = go.GetComponent<Collider>();
            if (Application.isPlaying) Object.Destroy(col);
            else Object.DestroyImmediate(col);
            return go;
        }

        // MuseumArt のマテリアルを作る。additive = 光として足し算で重ねる / false = 不透明
        public static Material MakeArt(Shader shader, string name, int mode, Color color, bool additive)
        {
            var m = new Material(shader) { name = name };
            m.SetFloat("_Mode", mode);
            m.SetColor("_Color", color);
            m.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.One);
            m.SetFloat("_DstBlend", (float)(additive ? UnityEngine.Rendering.BlendMode.One : UnityEngine.Rendering.BlendMode.Zero));
            m.SetFloat("_ZWrite", additive ? 0f : 1f);
            m.renderQueue = additive ? 3000 : 2000;
            return m;
        }
    }
}
