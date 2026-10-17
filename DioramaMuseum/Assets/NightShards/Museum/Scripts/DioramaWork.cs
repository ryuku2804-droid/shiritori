using System;
using UnityEngine;

namespace NightShards.Museum
{
    // 作品ごとの「仕掛け」を動かす。ジオラマの箱に付ける。
    //   Trigger() (鑑賞モードで Space、世界の中でクリック) → _Event が 0 → 1 に盛り上がり、しばらく続いてから 0 に戻る
    //   演出の最中にもう一度 Trigger() しても、最初からやり直さない (終わってから次を受け付ける)
    //   その間、毎フレーム Pulse で強さを知らせる (部屋の照明や床が連動する: RoomReactor)
    //   音は画像や音声ファイルを使わず、ここで波形を作って鳴らす
    [RequireComponent(typeof(Renderer))]
    public class DioramaWork : MonoBehaviour
    {
        [SerializeField] string work;
        [Tooltip("盛り上がるまでの秒数")] [SerializeField] float rise = 1.5f;
        [Tooltip("いちばん強い状態が続く秒数")] [SerializeField] float hold = 9f;
        [Tooltip("おさまるまでの秒数")] [SerializeField] float fall = 7f;
        [SerializeField, Range(0f, 1f)] float volume = 0.9f;

        // 仕掛けが動いている間、毎フレーム (作品, 強さ 0〜1) を知らせる
        public static event Action<DioramaWork, float> Pulse;

        public string Work => work;

        // 仕掛けが動いている間、部屋の照明をこの色に寄せる (a が寄せる強さ。0 なら照明の色はそのまま)
        public Color Tint => TintFor(work);

        static Color TintFor(string workName)
        {
            switch (workName)
            {
                case "BlueFire": return new Color(0.3f, 0.55f, 1f, 0.85f); // 青い炎
                case "Glacier": return new Color(0.75f, 0.88f, 1f, 0.4f);   // 月の光の青白さ
                case "Aurora": return new Color(0.3f, 1f, 0.55f, 0.75f);    // オーロラの緑
                case "Atoll": return new Color(0.45f, 0.95f, 1f, 0.45f);    // 浅瀬のターコイズ
                case "DeepSea": return new Color(0.2f, 0.5f, 1f, 0.8f);     // 生物発光の青
                case "Terraces": return new Color(0.35f, 0.4f, 0.8f, 0.5f);  // 夜の青
                case "Torii": return new Color(1f, 0.55f, 0.25f, 0.55f);     // 夕日の金色
                case "Paris": return new Color(1f, 0.8f, 0.45f, 0.5f);       // エッフェル塔の金色
                case "Pisa": return new Color(1f, 0.9f, 0.7f, 0.35f);        // 午後の光
                case "Pyramids": return new Color(1f, 0.55f, 0.28f, 0.6f);   // 砂嵐と夕日の橙
                case "DeadSea": return new Color(0.6f, 0.95f, 0.95f, 0.4f);  // 浅瀬の青緑
                case "Uyuni": return new Color(0.35f, 0.4f, 0.85f, 0.6f);     // 夕焼けから星空の青
                case "MachuPicchu": return new Color(1f, 0.82f, 0.55f, 0.45f); // 朝日の金色
                default: return Color.clear;
            }
        }
        public float Value { get; private set; }

        // 演出の最中か (盛り上がり〜おさまるまで)
        public bool IsPlaying => Time.time - started < rise + hold + fall;

        static readonly int EventId = Shader.PropertyToID("_Event");
        static readonly int EventTimeId = Shader.PropertyToID("_EventTime");

        float started = -1000f;
        Renderer rend;
        MaterialPropertyBlock block;
        AudioSource source;

        bool spatial = true;

        // spatialSound = false にすると、音を場所に関係なく同じ大きさで鳴らす (ジオラマの世界の中では、こちら)
        public void Setup(string workName, bool spatialSound = true)
        {
            work = workName;
            spatial = spatialSound;
        }

        void Awake()
        {
            rend = GetComponent<Renderer>();
            block = new MaterialPropertyBlock();
        }

        static readonly int HeightTexId = Shader.PropertyToID("_HeightTex");
        static readonly int HeightTexOnId = Shader.PropertyToID("_HeightTexOn");
        static readonly int SeedId = Shader.PropertyToID("_Seed");

        // 再生が始まったら、地形の高さの表を作ってシェーダーに渡す (シェーダーが速くなる)
        void Start()
        {
            rend.GetPropertyBlock(block);
            Texture2D height = DioramaTerrain.BakeHeight(work, block.GetFloat(SeedId));
            if (height == null) return;
            block.SetTexture(HeightTexId, height);
            block.SetFloat(HeightTexOnId, 1f);
            rend.SetPropertyBlock(block);
        }

        // 仕掛けを動かす。演出の最中なら何もしない
        public void Trigger()
        {
            if (IsPlaying) return;
            started = Time.time;
            PlaySound();
        }

        void Update()
        {
            float t = Time.time - started;
            float v;
            if (t < 0f || t > rise + hold + fall) v = 0f;
            else if (t < rise) v = Smooth(t / rise);
            else if (t < rise + hold) v = 1f;
            else v = 1f - Smooth((t - rise - hold) / fall);

            if (v <= 0f && Value <= 0f) return; // 止まっている間は何もしない
            Value = v;

            rend.GetPropertyBlock(block); // _Biome や _Steps を消さないように、今の値を読んでから書き足す
            block.SetFloat(EventId, v);
            block.SetFloat(EventTimeId, Mathf.Max(0f, t));
            rend.SetPropertyBlock(block);

            Pulse?.Invoke(this, v);
        }

        static float Smooth(float x)
        {
            x = Mathf.Clamp01(x);
            return x * x * (3f - 2f * x);
        }

        // ---------------------------------------------------------------- 音

        void PlaySound()
        {
            AudioClip clip = SoundFor(work);
            if (clip == null) return;
            if (source == null)
            {
                source = gameObject.AddComponent<AudioSource>();
                source.playOnAwake = false;
                source.spatialBlend = spatial ? 1f : 0f; // 作品の位置から聞こえる (世界の中では、まわり全体から)
                source.minDistance = 0.8f;
                source.maxDistance = 14f;
                source.rolloffMode = AudioRolloffMode.Linear;
            }
            source.PlayOneShot(clip, volume);
        }

        static AudioClip rumble, roar, calving, shimmer, tide, glow, evening, shrine, sparkle, bells, sandstorm, saltGrow, starNight, quena;

        static AudioClip SoundFor(string workName)
        {
            switch (workName)
            {
                case "Eruption":
                    if (rumble == null) rumble = MakeRumble(9f);
                    return rumble;
                case "BlueFire":
                    if (roar == null) roar = MakeRoar(10f);
                    return roar;
                case "Glacier":
                    if (calving == null) calving = MakeCalving(9f);
                    return calving;
                case "Aurora":
                    if (shimmer == null) shimmer = MakeShimmer(12f);
                    return shimmer;
                case "Atoll":
                    if (tide == null) tide = MakeTide(12f);
                    return tide;
                case "DeepSea":
                    if (glow == null) glow = MakeDeepGlow(12f);
                    return glow;
                case "Terraces":
                    if (evening == null) evening = MakeEvening(14f);
                    return evening;
                case "Torii":
                    if (shrine == null) shrine = MakeShrineBell(10f);
                    return shrine;
                case "Paris":
                    if (sparkle == null) sparkle = MakeSparkle(10f);
                    return sparkle;
                case "Pisa":
                    if (bells == null) bells = MakeChurchBells(12f);
                    return bells;
                case "Pyramids":
                    if (sandstorm == null) sandstorm = MakeSandstorm(14f);
                    return sandstorm;
                case "DeadSea":
                    if (saltGrow == null) saltGrow = MakeSaltGrow(12f);
                    return saltGrow;
                case "Uyuni":
                    if (starNight == null) starNight = MakeStarNight(14f);
                    return starNight;
                case "MachuPicchu":
                    if (quena == null) quena = MakeQuena(16f);
                    return quena;
                default:
                    return null;
            }
        }

        // 氷河が崩れる音: 「ピシッ」と氷が割れ、ゴゴゴと崩れ、3 秒後に「ザブン」と湖に落ちる
        static AudioClip MakeCalving(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(5);
            float low = 0f, mid = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                low += (white - low) * 0.03f;
                mid += (white - mid) * 0.25f;
                float crack = white * Mathf.Exp(-time * 30f) * 1.5f + Mathf.Sin(time * 2f * Mathf.PI * 55f) * Mathf.Exp(-time * 6f);   // ピシッ
                float rumbleEnv = Mathf.Clamp01((time - 1.4f) / 0.3f) * Mathf.Exp(-Mathf.Max(0f, time - 1.7f) * 1.2f);               // ゴゴゴ
                float splashEnv = time > 3f ? Mathf.Exp(-(time - 3f) * 1.6f) : 0f;                                                    // ザブン
                data[i] = crack + low * 6f * rumbleEnv + (mid * 1.5f + low * 3f) * splashEnv;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.85f / peak;
            var clip = AudioClip.Create("Glacier Calving", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // オーロラの音: 風のようなやわらかいざわめきに、遠くで鳴る鈴のような和音が、ゆっくりふくらんで消える
        static AudioClip MakeShimmer(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(3);
            float air = 0f;
            float[] tones = { 392f, 493.9f, 587.3f, 784f }; // ソ・シ・レ・ソ
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                air += (white - air) * 0.08f;
                float swell = Mathf.Sin(Mathf.Clamp01(time / seconds) * Mathf.PI); // ゆっくりふくらんで、消える
                float pad = 0f;
                for (int k = 0; k < tones.Length; k++)
                {
                    float vib = 1f + 0.003f * Mathf.Sin(time * (0.7f + k * 0.3f)); // 少しゆらぐ
                    pad += Mathf.Sin(2f * Mathf.PI * tones[k] * vib * time) * (0.5f + 0.5f * Mathf.Sin(time * (0.4f + k * 0.17f) + k));
                }
                data[i] = (air * 0.8f * (0.6f + 0.4f * Mathf.Sin(time * 0.9f)) + pad * 0.12f) * swell;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.7f / peak;
            var clip = AudioClip.Create("Aurora Shimmer", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // 潮が引く音: 寄せては返す波の音が、ゆっくり遠ざかっていく
        static AudioClip MakeTide(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(9);
            float wash = 0f, low = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                wash += (white - wash) * 0.15f;  // ザーッという波の音
                low += (white - low) * 0.02f;
                float wave = Mathf.Pow(0.5f + 0.5f * Mathf.Sin(time * 2f * Mathf.PI / 3.2f - 1.5f), 3f); // 3.2 秒ごとに寄せて返す
                float away = Mathf.Lerp(1f, 0.35f, time / seconds);                                      // だんだん遠ざかる
                float fade = Mathf.Clamp01(time / 0.5f) * Mathf.Clamp01((seconds - time) / 1.5f);
                data[i] = (wash * 0.8f + low * 2f) * (0.25f + wave) * away * fade;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.7f / peak;
            var clip = AudioClip.Create("Atoll Tide", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // 深海の光の音: 低く深いうなりの上に、きらきらと光る粒のような高い音が、次々に鳴っては消える
        static AudioClip MakeDeepGlow(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(13);
            float[] notes = { 523.3f, 659.3f, 784f, 987.8f, 1174.7f, 1318.5f }; // 高いきらきらの音
            float noteStart = -10f, noteFreq = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float swell = Mathf.Sin(Mathf.Clamp01(time / seconds) * Mathf.PI);
                float hum = Mathf.Sin(2f * Mathf.PI * 55f * time) * 0.5f + Mathf.Sin(2f * Mathf.PI * 82.4f * time) * 0.3f;
                if (time - noteStart > 0.18f && random.NextDouble() < 0.0006)
                {
                    noteStart = time;
                    noteFreq = notes[random.Next(notes.Length)];
                }
                float bell = Mathf.Sin(2f * Mathf.PI * noteFreq * (time - noteStart)) * Mathf.Exp(-(time - noteStart) * 4f);
                data[i] = (hum * 0.35f + bell * 0.5f) * swell;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.7f / peak;
            var clip = AudioClip.Create("Deep Sea Glow", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // 里の夜の音: 遠くのお寺の鐘がゴーンと鳴り、だんだんカエルとコオロギの声がにぎやかになる
        static AudioClip MakeEvening(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(21);
            float frogStart = -10f, frogPitch = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                // 鐘: 低い音と、少しずれた倍音が、長く尾を引く
                float bell = (Mathf.Sin(2f * Mathf.PI * 110f * time) + 0.5f * Mathf.Sin(2f * Mathf.PI * 221.5f * time) + 0.25f * Mathf.Sin(2f * Mathf.PI * 331f * time))
                           * Mathf.Exp(-time * 0.35f) * Mathf.Clamp01(time / 0.02f);
                // カエル: ケロケロと短く鳴く。時間がたつほど、よく鳴く
                float night = Mathf.Clamp01((time - 2f) / 5f);
                if (time - frogStart > 0.25f && random.NextDouble() < 0.0004 * night)
                {
                    frogStart = time;
                    frogPitch = 300f + (float)random.NextDouble() * 200f;
                }
                float ft = time - frogStart;
                float frog = ft < 0.18f ? Mathf.Sin(2f * Mathf.PI * frogPitch * ft) * Mathf.Sin(ft * Mathf.PI / 0.18f) * (0.5f + 0.5f * Mathf.Sign(Mathf.Sin(ft * 2f * Mathf.PI * 25f))) : 0f;
                // コオロギ: 高い音が、リリリと小刻みに
                float cricket = Mathf.Sin(2f * Mathf.PI * 4200f * time) * Mathf.Max(0f, Mathf.Sin(time * 2f * Mathf.PI * 30f)) * Mathf.Max(0f, Mathf.Sin(time * 2f * Mathf.PI * 0.7f)) * night;
                float fade = Mathf.Clamp01((seconds - time) / 2f);
                data[i] = (bell * 0.5f + frog * 0.3f + cricket * 0.08f) * fade;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.7f / peak;
            var clip = AudioClip.Create("Terraces Evening", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // 神社の音: 杉の森を渡る風の音の中で、鈴がシャンシャンと鳴る
        static AudioClip MakeShrineBell(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(17);
            float wind = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                wind += (white - wind) * 0.04f;
                float gust = 0.5f + 0.5f * Mathf.Sin(time * 0.8f) * Mathf.Sin(time * 0.33f + 1f);
                // 鈴: 0.5 秒ごとに 4 回、高い金属の音
                float bells = 0f;
                for (int k = 0; k < 4; k++)
                {
                    float bt = time - 0.4f - k * 0.5f;
                    if (bt > 0f)
                        bells += (Mathf.Sin(2f * Mathf.PI * 2350f * bt) + 0.6f * Mathf.Sin(2f * Mathf.PI * 3720f * bt)) * Mathf.Exp(-bt * 5f) * (0.75f + 0.25f * Mathf.Sin(k * 2.1f));
                }
                float fade = Mathf.Clamp01(time / 1f) * Mathf.Clamp01((seconds - time) / 2f);
                data[i] = (wind * 3f * gust + bells * 0.25f) * fade;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.7f / peak;
            var clip = AudioClip.Create("Shrine Bell", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // パリの夜: 遠くの街のざわめきの上で、塔のきらめきに合わせて、小さな鈴のような音がきらきら鳴る
        static AudioClip MakeSparkle(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(31);
            float city = 0f;
            float noteStart = -10f, noteFreq = 0f;
            float[] notes = { 1568f, 1760f, 2093f, 2349f, 2637f, 3136f };
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                city += (white - city) * 0.02f;
                if (time - noteStart > 0.06f && random.NextDouble() < 0.003)
                {
                    noteStart = time;
                    noteFreq = notes[random.Next(notes.Length)];
                }
                float twinkle = Mathf.Sin(2f * Mathf.PI * noteFreq * (time - noteStart)) * Mathf.Exp(-(time - noteStart) * 18f);
                float fade = Mathf.Clamp01(time / 0.5f) * Mathf.Clamp01((seconds - time) / 2f);
                data[i] = (city * 2f + twinkle * 0.25f) * fade;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.6f / peak;
            var clip = AudioClip.Create("Paris Sparkle", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // 砂嵐: 遠くから風がうなりを上げて近づき、ザーッと砂が吹きつけ、8 秒ほどで遠ざかる
        static AudioClip MakeSandstorm(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(53);
            float low = 0f, mid = 0f, gust = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                low += (white - low) * 0.02f;                    // うなり (低い風の音)
                mid += (white - mid) * 0.3f;                     // ザーッという砂の音
                gust += ((float)random.NextDouble() - gust) * 0.0002f; // 風の強弱
                float storm = Mathf.Clamp01(time / 2.5f) * (1f - Mathf.Clamp01((time - 7f) / 4f));
                float howl = Mathf.Sin(2f * Mathf.PI * (180f + 60f * Mathf.Sin(time * 0.7f)) * time) * 0.05f;
                data[i] = (low * 5f + mid * 0.6f * (0.6f + gust) + howl) * storm;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.6f / peak;
            var clip = AudioClip.Create("Giza Sandstorm", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // 塩の結晶が育つ音: 静かな水のちゃぷちゃぷに、結晶ができるたび、ガラスのような小さな音がチリン、パキッと重なる
        static AudioClip MakeSaltGrow(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(61);
            float water = 0f;
            float noteStart = -10f, noteFreq = 0f;
            float[] notes = { 2093f, 2637f, 3136f, 3520f, 4186f };
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                water += (white - water) * 0.05f;
                float lap = 0.5f + 0.5f * Mathf.Sin(time * 2.1f) * Mathf.Sin(time * 0.7f + 1f);
                if (time - noteStart > 0.12f && random.NextDouble() < 0.0012 * Mathf.Clamp01(time / 3f))
                {
                    noteStart = time;
                    noteFreq = notes[random.Next(notes.Length)];
                }
                float dt = time - noteStart;
                float ping = Mathf.Sin(2f * Mathf.PI * noteFreq * dt) * Mathf.Exp(-dt * 9f) + (dt < 0.004f ? white * 0.6f : 0f);
                float fade = Mathf.Clamp01(time / 0.5f) * Mathf.Clamp01((seconds - time) / 2.5f);
                data[i] = (water * 1.2f * lap + ping * 0.3f) * fade;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.55f / peak;
            var clip = AudioClip.Create("Dead Sea Salt", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // 天空の鏡の夜: 高原の静かな風に、星がまたたくような、やわらかい鈴の和音が重なっていく
        static AudioClip MakeStarNight(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(71);
            float wind = 0f;
            float[] chord = { 523.25f, 659.25f, 783.99f, 987.77f, 1174.66f, 1567.98f };
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                wind += (white - wind) * 0.01f;
                float bells = 0f;
                for (int k = 0; k < chord.Length; k++)
                {
                    float start = 2.5f + k * 1.1f;
                    float dt = time - start;
                    if (dt > 0f) bells += Mathf.Sin(2f * Mathf.PI * chord[k] * dt) * Mathf.Exp(-dt * 0.6f) * 0.25f;
                }
                float fade = Mathf.Clamp01(time / 1f) * Mathf.Clamp01((seconds - time) / 3f);
                data[i] = (wind * 2.5f + bells) * fade;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.5f / peak;
            var clip = AudioClip.Create("Uyuni Night", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // アンデスの笛 (ケーナ): 雲が流れる風の音に、息のまじった素朴な旋律が流れる
        static AudioClip MakeQuena(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(83);
            float wind = 0f, breath = 0f, phase = 0f;
            // 5 音音階 (ラ・ド・レ・ミ・ソ) の、ゆったりした旋律。(音の高さ, 長さ)
            float[] notes = { 440f, 523.25f, 587.33f, 659.25f, 587.33f, 523.25f, 440f, 392f, 440f, 523.25f, 659.25f, 783.99f, 659.25f, 587.33f, 440f };
            float[] lens = { 0.6f, 0.6f, 1.2f, 0.6f, 0.6f, 0.6f, 1.8f, 0.6f, 0.6f, 0.6f, 1.2f, 0.6f, 0.6f, 0.6f, 2.4f };
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                wind += (white - wind) * 0.015f;
                breath += (white - breath) * 0.4f;
                // 今の音を探す (1 秒たってから吹きはじめる)
                float tt = time - 1f, acc = 0f, freq = 0f, start = 0f, len = 1f;
                for (int k = 0; k < notes.Length; k++)
                {
                    if (tt >= acc && tt < acc + lens[k]) { freq = notes[k]; start = acc; len = lens[k]; break; }
                    acc += lens[k];
                }
                float tone = 0f;
                if (freq > 0f)
                {
                    float dt = tt - start;
                    float env = Mathf.Clamp01(dt / 0.06f) * Mathf.Clamp01((len - dt) / 0.12f);
                    float vib = 1f + 0.006f * Mathf.Sin(2f * Mathf.PI * 5.5f * dt) * Mathf.Clamp01(dt / 0.3f);
                    phase += 2f * Mathf.PI * freq * vib / rate;
                    tone = (Mathf.Sin(phase) + 0.25f * Mathf.Sin(phase * 2f) + 0.1f * Mathf.Sin(phase * 3f) + breath * 0.15f) * env;
                }
                float fade = Mathf.Clamp01(time / 1f) * Mathf.Clamp01((seconds - time) / 2f);
                data[i] = (wind * 3f + tone * 0.35f) * fade;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.55f / peak;
            var clip = AudioClip.Create("Machu Picchu Quena", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // ピサの鐘: 大きさのちがう 3 つの鐘が、交互にゴーン・カーンと鳴り響き、鳩の羽音がばさばさと重なる
        static AudioClip MakeChurchBells(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(41);
            float[] bellFreq = { 196f, 247f, 294f };
            float flutter = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float sum = 0f;
                for (int k = 0; k < 9; k++)
                {
                    float strike = 0.2f + k * 1.1f;
                    float bt = time - strike;
                    if (bt < 0f) continue;
                    float f = bellFreq[k % 3];
                    // 鐘の音: 基音と、少しずれた倍音 (2.4 倍・3 倍) が、長く尾を引く
                    sum += (Mathf.Sin(2f * Mathf.PI * f * bt) + 0.6f * Mathf.Sin(2f * Mathf.PI * f * 2.4f * bt) + 0.3f * Mathf.Sin(2f * Mathf.PI * f * 3f * bt)) * Mathf.Exp(-bt * 0.8f);
                }
                float white = (float)random.NextDouble() * 2f - 1f;
                flutter += (white - flutter) * 0.3f;
                float wings = flutter * Mathf.Max(0f, Mathf.Sin(time * 2f * Mathf.PI * 9f)) * Mathf.Exp(-Mathf.Max(0f, time - 0.8f) * 1.5f) * Mathf.Clamp01((time - 0.4f) * 3f);
                float fade = Mathf.Clamp01((seconds - time) / 2f);
                data[i] = (sum * 0.3f + wings * 0.5f) * fade;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.75f / peak;
            var clip = AudioClip.Create("Pisa Bells", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // ガスが燃える音: 「ボッ」と火がつく音のあと、ゴーッと吹き出す炎の音が続き、ゆっくり小さくなる
        static AudioClip MakeRoar(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(11);
            float hiss = 0f, body = 0f, low = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                hiss += (white - hiss) * 0.35f;  // シャーという、ガスが吹き出す音
                body += (white - body) * 0.06f;  // ゴーッという、炎の胴の音
                low += (body - low) * 0.02f;     // 低いうなり
                float gust = 0.75f + 0.25f * Mathf.Sin(time * 2.1f) * Mathf.Sin(time * 0.7f + 1f); // 風にあおられて強弱がつく
                float ignite = Mathf.Exp(-time * 6f) * 2.5f;                                     // 火がつく瞬間の「ボッ」
                float attack = Mathf.Clamp01(time / 0.08f);
                float decay = Mathf.Exp(-Mathf.Max(0f, time - 3f) * 0.35f);
                data[i] = (hiss * 0.25f + body * 1.2f + low * 4f) * (gust + ignite) * attack * decay;
            }
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.85f / peak;

            var clip = AudioClip.Create("Blue Fire Roar", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        // 地鳴り: 低い音だけを残した雑音 (ブラウンノイズ) に、ときどき岩が弾けるパチパチという音を混ぜる
        static AudioClip MakeRumble(float seconds)
        {
            const int rate = 22050;
            int n = Mathf.RoundToInt(seconds * rate);
            var data = new float[n];
            var random = new System.Random(7);
            float brown = 0f, low = 0f, crackle = 0f;
            for (int i = 0; i < n; i++)
            {
                float time = (float)i / rate;
                float white = (float)random.NextDouble() * 2f - 1f;
                brown = (brown + 0.02f * white) / 1.02f;  // ゆっくり揺れる低い音
                low += (brown - low) * 0.05f;            // さらに高い音を削る
                if (random.NextDouble() < 0.0006) crackle = 1f; // ときどき弾ける
                crackle *= 0.995f;
                float pop = white * crackle * 0.25f;

                float attack = Mathf.Clamp01(time / 0.6f);
                float decay = Mathf.Exp(-Mathf.Max(0f, time - 2f) * 0.45f);
                data[i] = (low * 9f + pop) * attack * decay;
            }
            // 大きすぎて音が割れないように、いちばん大きい所を 0.9 にそろえる
            float peak = 0.0001f;
            foreach (float s in data) peak = Mathf.Max(peak, Mathf.Abs(s));
            for (int i = 0; i < n; i++) data[i] *= 0.9f / peak;

            var clip = AudioClip.Create("Eruption Rumble", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }
    }
}
