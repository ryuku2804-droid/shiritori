using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 重さを調べる道具。再生中に F キーで、重そうなものを1つずつ止めて、FPS の変わり方を見る。
    //   F1  左上の表示を出す・消す (はじめは消えている)
    //   F2  ジオラマを描く・描かない
    //   F3  スポットライトの影を付ける・付けない
    //   F4  画面の細かさを、自動 → 100% → 75% → 50% と切りかえる (URP の Render Scale。自動は AutoQuality が FPS に合わせる)
    //   F5  部屋のアート (火の粉・光の糸・月・障子・光のスリット) を出す・消す
    // 止めて大きく FPS が上がったものが、重さの原因
    public class PerfDebug : MonoBehaviour
    {
        [SerializeField] bool showOnStart = false; // 左上の表示は、はじめは出さない (F1 で出せる)

        bool visible;
        float smoothedDt = 1f / 60f;
        bool dioramasOff, shadowsOff, artOff;
        int scaleIndex;
        static readonly float[] Scales = { -1f, 1f, 0.75f, 0.5f }; // -1 は自動

        readonly List<Light> shadowLights = new List<Light>();
        readonly List<GameObject> hiddenArt = new List<GameObject>();
        GUIStyle style;

        void Start()
        {
            visible = showOnStart;
        }

        void Update()
        {
            // 1フレームの時間を、なめらかにならして表示する (数字が暴れないように)
            smoothedDt = Mathf.Lerp(smoothedDt, Time.unscaledDeltaTime, 0.05f);

            if (MuseumInput.FunctionKeyPressed(1)) visible = !visible;
            if (MuseumInput.FunctionKeyPressed(2)) ToggleDioramas();
            if (MuseumInput.FunctionKeyPressed(3)) ToggleShadows();
            if (MuseumInput.FunctionKeyPressed(4)) CycleRenderScale();
            if (MuseumInput.FunctionKeyPressed(5)) ToggleArt();
        }

        void ToggleDioramas()
        {
            dioramasOff = !dioramasOff;
            DioramaLOD.HideAll = dioramasOff;
        }

        void ToggleShadows()
        {
            shadowsOff = !shadowsOff;
            if (shadowsOff)
            {
                shadowLights.Clear();
                foreach (var l in FindObjectsByType<Light>(FindObjectsSortMode.None))
                {
                    if (l.shadows == LightShadows.None) continue;
                    shadowLights.Add(l);
                    l.shadows = LightShadows.None;
                }
            }
            else
            {
                foreach (var l in shadowLights) if (l != null) l.shadows = LightShadows.Soft;
                shadowLights.Clear();
            }
        }

        // 画面の細かさを切りかえる。元にもどすのは AutoQuality が受け持つ
        void CycleRenderScale()
        {
            scaleIndex = (scaleIndex + 1) % Scales.Length;
            if (Scales[scaleIndex] < 0f) AutoQuality.Enabled = true;
            else AutoQuality.SetManual(Scales[scaleIndex]);
        }

        // 部屋のアート (各部屋の Art と、ホールの光のスリット) を消す。ライトは残す
        void ToggleArt()
        {
            artOff = !artOff;
            if (artOff)
            {
                hiddenArt.Clear();
                foreach (var t in FindObjectsByType<Transform>(FindObjectsSortMode.None))
                {
                    if (t.name == "Ceiling Slit")
                    {
                        Hide(t.gameObject);
                    }
                    else if (t.name == "Art")
                    {
                        foreach (Transform child in t)
                            if (child.GetComponent<Light>() == null) Hide(child.gameObject);
                    }
                }
            }
            else
            {
                foreach (var go in hiddenArt) if (go != null) go.SetActive(true);
                hiddenArt.Clear();
            }
        }

        void Hide(GameObject go)
        {
            if (!go.activeSelf) return;
            go.SetActive(false);
            hiddenArt.Add(go);
        }

        void OnDisable()
        {
            DioramaLOD.HideAll = false;
        }

        void OnGUI()
        {
            if (!visible) return;
            if (style == null)
            {
                style = new GUIStyle(GUI.skin.label) { fontSize = Mathf.RoundToInt(16f * Screen.height / 1080f) };
                style.normal.textColor = new Color(1f, 0.96f, 0.88f);
            }

            float fps = 1f / Mathf.Max(smoothedDt, 1e-4f);
            string text =
                $"{fps:0} fps   {smoothedDt * 1000f:0.0} ms   画面 {Screen.width}×{Screen.height}\n" +
                $"F2 ジオラマ  {(dioramasOff ? "オフ" : "オン")}\n" +
                $"F3 スポットライトの影  {(shadowsOff ? "オフ" : "オン")}\n" +
                $"F4 細かさ  {(AutoQuality.Enabled ? "自動 " : "")}{AutoQuality.CurrentScale * 100f:0}%\n" +
                $"F5 部屋のアート  {(artOff ? "オフ" : "オン")}\n" +
                "F1 この表示を消す";

            float s = Screen.height / 1080f;
            var r = new Rect(16f * s, 16f * s, 420f * s, 150f * s);
            var prev = GUI.color;
            GUI.color = new Color(0f, 0f, 0f, 0.55f);
            GUI.DrawTexture(new Rect(r.x - 8f * s, r.y - 6f * s, r.width, r.height), Texture2D.whiteTexture);
            GUI.color = prev;
            GUI.Label(r, text, style);
        }
    }
}
