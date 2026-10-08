using UnityEngine;
using UnityEngine.Rendering;
using VoidCloak;

namespace EchoKnight
{
    /// <summary>
    /// The end of the story, at the heart of the Silence. Rine's voice waits here as a small
    /// golden figure. When the knight comes close, she speaks, then he chooses:
    ///
    ///   1 鐘を鋳直す            - 「暁の鐘」     light returns; next year another child's voice is given
    ///   2 しじまとともに眠る    - 「静寂の兄妹」 no bell, no light; brother and sister sleep in the dark
    ///   3 最後の響きを鐘に渡す  - 「残響の騎士」 (true ending) only with all three memory fragments
    ///
    /// After the ending the game returns to the title, which names the ending.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public class EchoEnding : MonoBehaviour
    {
        enum Phase { Waiting, Speaking, Choosing, Ending }

        struct Beat { public float time; public string speaker; public string line; public float seconds; }

        [SerializeField] private Material material = null;
        [SerializeField] private Vector3 zoneSize = new Vector3(12f, 6f, 10f);
        [Tooltip("Where Rine's figure kneels (local).")]
        [SerializeField] private Vector3 rineOffset = new Vector3(0f, 0f, 1.5f);

        static readonly Beat[] Intro =
        {
            new Beat { time = 0.8f, speaker = "リーネ", line = "……兄さん。やっと、来てくれた。", seconds = 3.5f },
            new Beat { time = 4.8f, speaker = "リーネ", line = "わたしの声は、しじまの心臓になったの。……兄さんが鐘を砕いた、あの夜に。", seconds = 5.5f },
            new Beat { time = 10.8f, speaker = "リーネ", line = "鐘を鋳直せば、光は戻る。……でも、また誰かの声が捧げられる。", seconds = 5.5f },
            new Beat { time = 16.8f, speaker = "リーネ", line = "兄さん。……選んで。", seconds = 3f },
        };
        const float ChoiceAt = 19.5f;

        static readonly Beat[] EndingDawn =
        {
            new Beat { time = 0.5f, line = "鐘守りの騎士は、砕けた暁鐘を鋳直した。", seconds = 4f },
            new Beat { time = 5f, line = "鐘は鳴り、しじまは退き、王国に光が戻った。", seconds = 4.5f },
            new Beat { time = 10f, speaker = "リーネ", line = "……", seconds = 3f },
            new Beat { time = 13.5f, line = "次の年。また、ひとりの子どもの声が、鐘に捧げられた。", seconds = 5f },
        };

        static readonly Beat[] EndingSilence =
        {
            new Beat { time = 0.5f, line = "騎士は剣を置き、鐘を鳴らさなかった。", seconds = 4f },
            new Beat { time = 5f, speaker = "リーネ", line = "……いいの？　ずっと、暗いままだよ。", seconds = 4f },
            new Beat { time = 9.5f, speaker = "アルドレン", line = "お前の声が聞こえるなら、それでいい。", seconds = 4f },
            new Beat { time = 14f, line = "光は戻らない。残響たちは、ひとり、またひとりと消えていった。", seconds = 4.5f },
            new Beat { time = 19f, line = "兄妹は、音のない闇の中で、寄り添って眠った。", seconds = 4.5f },
        };

        static readonly Beat[] EndingTrue =
        {
            new Beat { time = 0.5f, line = "騎士の体には、あの夜の暁鐘の、最後の響きが残っていた。", seconds = 4.5f },
            new Beat { time = 5.5f, speaker = "アルドレン", line = "……これを、鐘に返す。代わりに、もう誰の声も食べるな。", seconds = 4.5f },
            new Beat { time = 10.5f, line = "騎士の体が、ひとつずつ、光の粒になってほどけていく。", seconds = 4f },
            new Beat { time = 15f, speaker = "リーネ", line = "……兄さん？　兄さん……！", seconds = 3.5f },
            new Beat { time = 19f, line = "鐘は、誰の声も食べずに鳴った。リーネの声は、もう誰にも奪われない。", seconds = 5f },
            new Beat { time = 24.5f, speaker = "リーネ", line = "……聞こえる？　兄さん。……わたしの、声。", seconds = 5f },
        };

        Phase phase = Phase.Waiting;
        float phaseStart;
        int nextBeat;
        Beat[] beats;
        float beatsEnd;
        string endingName;
        int endingKind;
        bool knightGone;
        bool bellRung;
        float nextPulse;
        int selected;
        string[] items;
        bool[] enabled;
        Mesh rineMesh;
        Transform rine;

        void OnEnable()
        {
            BuildRine();
        }

        void OnDisable()
        {
            if (rine != null)
            {
                var f = rine.GetComponent<MeshFilter>();
                if (f != null && f.sharedMesh == rineMesh) f.sharedMesh = null;
            }
            EchoMeshUtil.DestroySafe(rineMesh);
            rineMesh = null;
        }

        public void Setup(Material newMaterial, Vector3 newZoneSize)
        {
            material = newMaterial;
            zoneSize = newZoneSize;
            BuildRine();
        }

        void BuildRine()
        {
            rine = transform.Find("_Rine");
            if (rine == null)
            {
                var go = new GameObject("_Rine");
                rine = go.transform;
                rine.SetParent(transform, false);
                go.AddComponent<MeshFilter>();
                go.AddComponent<MeshRenderer>();
            }
            rine.localPosition = rineOffset;
            rine.localRotation = Quaternion.Euler(0f, 180f, 0f);
            var b = new EchoPointBuilder(77);
            EchoFigureBody.Build(b, EchoFigurePose.ChildKneel);
            rineMesh = EchoMeshUtil.Build(b, rineMesh, "Rine");
            rine.GetComponent<MeshFilter>().sharedMesh = rineMesh;
            var r = rine.GetComponent<MeshRenderer>();
            if (material != null) r.sharedMaterial = material;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
        }

        void Update()
        {
            if (!Application.isPlaying) return;
            EchoPlayer player = EchoPlayer.Current;
            Vector3 centre = transform.position + Vector3.up * 2f;

            if (phase == Phase.Waiting)
            {
                // a soft golden heartbeat, so she can be found in the dark
                if (Time.time >= nextPulse)
                {
                    nextPulse = Time.time + 2.4f;
                    EchoSystem.Emit(centre, 7f, EchoSource.Resonance, 0.8f);
                    EchoAudio.Play(EchoSound.ShrineBell, centre, 0.15f, 1.6f);
                }
                if (player != null && new Bounds(transform.position + Vector3.up * zoneSize.y * 0.5f, zoneSize).Contains(player.transform.position + Vector3.up))
                    Begin(player);
                return;
            }

            float t = Time.time - phaseStart;
            if (Time.time >= nextPulse && !(phase == Phase.Ending && endingKind == 1))
            {
                nextPulse = Time.time + 1.1f;
                EchoSystem.Emit(centre, 10f, EchoSource.Resonance, 0.9f);
            }
            while (beats != null && nextBeat < beats.Length && t >= beats[nextBeat].time)
            {
                Beat b = beats[nextBeat++];
                EchoGame.Say(b.speaker, b.line, b.seconds);
            }

            if (phase == Phase.Speaking)
            {
                if (t >= ChoiceAt) OpenChoice();
            }
            else if (phase == Phase.Choosing)
            {
                int move = EchoMenuInput.Vertical();
                if (move != 0)
                {
                    for (int k = 0; k < items.Length; k++)
                    {
                        selected = (selected + move + items.Length) % items.Length;
                        if (enabled[selected]) break;
                    }
                }
                if (EchoMenuInput.Confirm()) Choose(selected);
            }
            else if (phase == Phase.Ending)
            {
                if (endingKind == 2 && !knightGone && t >= 10.5f && player != null)
                {
                    // the true ending: the knight comes undone into light
                    knightGone = true;
                    var r = player.GetComponent<MeshRenderer>();
                    if (r != null) r.enabled = false;
                    EchoSystem.Emit(player.transform.position + Vector3.up * 2f, 40f, EchoSource.Resonance, 1.5f);
                    EchoAudio.Play(EchoSound.ShrineBell, player.transform.position + Vector3.up * 2f, 0.7f, 1.3f);
                }
                if (endingKind == 2 && !bellRung && t >= 19f)
                {
                    // the bell rings without eating anyone's voice
                    bellRung = true;
                    EchoAudio.Play(EchoSound.ShrineBell, centre + Vector3.up * 4f, 1f, 0.5f);
                    EchoSystem.Emit(centre, 80f, EchoSource.Bell, 1.4f);
                }
                if (t >= beatsEnd + 6f) EchoGame.FinishGame(endingName);
            }
        }

        void Begin(EchoPlayer player)
        {
            phase = Phase.Speaking;
            phaseStart = Time.time;
            beats = Intro;
            nextBeat = 0;
            EchoGame.InCutscene = true;
            var mover = player.GetComponent<VoidCloakMover>();
            if (mover != null) { mover.SpeedMultiplier = 0f; mover.AllowTurning = false; }
        }

        void OpenChoice()
        {
            phase = Phase.Choosing;
            bool all = EchoGame.MemoryCount >= EchoGame.MemoryTotal;
            items = new[]
            {
                "鐘を鋳直す（光を取り戻す）",
                "しじまとともに眠る",
                all ? "最後の響きを、鐘に渡す" : "？？？（記憶のかけら　" + EchoGame.MemoryCount + " / " + EchoGame.MemoryTotal + "）",
            };
            enabled = new[] { true, true, all };
            selected = all ? 2 : 0;
        }

        void Choose(int index)
        {
            if (!enabled[index]) return;
            endingKind = index;
            phase = Phase.Ending;
            phaseStart = Time.time;
            nextBeat = 0;
            switch (index)
            {
                case 0: beats = EndingDawn; endingName = "暁の鐘"; break;
                case 1: beats = EndingSilence; endingName = "静寂の兄妹"; break;
                default: beats = EndingTrue; endingName = "残響の騎士"; break;
            }
            Beat last = beats[beats.Length - 1];
            beatsEnd = last.time + last.seconds;
            Vector3 centre = transform.position + Vector3.up * 3f;
            if (index == 0)
            {
                EchoAudio.Play(EchoSound.ShrineBell, centre, 1f, 0.5f, 0.3f);
                EchoSystem.Emit(centre, 80f, EchoSource.Bell, 1.4f);
            }
        }

        void OnGUI()
        {
            if (!Application.isPlaying) return;
            if (phase == Phase.Choosing)
            {
                int clicked = EchoMenuDraw.Draw(items, enabled, selected, Screen.height * 0.82f, 1f);
                if (clicked >= 0) { selected = clicked; Choose(clicked); }
            }
            else if (phase == Phase.Ending)
            {
                float t = Time.time - phaseStart;
                // the world fades out under the last lines; then the ending's name
                float dark = Mathf.Clamp01((t - (beatsEnd - 6f)) / 5f);
                if (dark > 0f)
                {
                    Color old = GUI.color;
                    GUI.color = new Color(0f, 0f, 0f, dark * 0.85f);
                    GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), Texture2D.whiteTexture);
                    GUI.color = old;
                }
                float title = Mathf.Clamp01((t - beatsEnd) / 1.5f);
                if (title > 0f) EchoScreenText.DrawTitle("終", endingName, title);
            }
        }

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(1f, 0.85f, 0.5f, 0.7f);
            Gizmos.DrawWireCube(transform.position + Vector3.up * zoneSize.y * 0.5f, zoneSize);
        }
    }
}
