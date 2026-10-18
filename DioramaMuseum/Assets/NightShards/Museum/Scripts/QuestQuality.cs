using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace NightShards.Museum
{
    // Quest (Android) で動かすときだけの、軽い画質。パソコンやエディターの再生では何もしない。
    //   ・スポットライトなどの影を切る (影は、ライト 1 つごとに場面をもう一度描くので、いちばん重い)
    //   ・SSAO (すみの暗がり) を切る (画面全体をもう一度なぞるので重い)
    //   ・1 つの物を照らすライトの数を 4 つまでにする
    //   ・光のにじみ (ブルーム) と四隅の暗がり (ビネット) は MuseumPost が切る。明るさの階調 (トーンマップ) は残す
    //   ・画面の細かさは AutoQuality が 70% から始めて、72 fps に合わせる
    // 再生を始めると自動で動く (シーンに置く必要はない)
    public static class QuestQuality
    {
        // Quest などのスマホ系の機械で動いているか
        public static bool IsMobile => Application.isMobilePlatform;

        const int MaxLightsPerObject = 4;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Apply()
        {
            if (!IsMobile) return;

            // ライトの影を全部切る (美術館のライトは、再生を始めたときにはもうできている)
            int lights = 0;
            foreach (var l in Object.FindObjectsByType<Light>(FindObjectsInactive.Include, FindObjectsSortMode.None))
            {
                if (l.shadows == LightShadows.None) continue;
                l.shadows = LightShadows.None;
                lights++;
            }

            if (GraphicsSettings.currentRenderPipeline is UniversalRenderPipelineAsset urp)
            {
                urp.shadowDistance = 0f; // 太陽の影も描かない
                urp.maxAdditionalLightsCount = Mathf.Min(urp.maxAdditionalLightsCount, MaxLightsPerObject);
            }

            // SSAO を切る (URP の Renderer に足してある「Screen Space Ambient Occlusion」)
            int features = 0;
            foreach (var f in Resources.FindObjectsOfTypeAll<ScriptableRendererFeature>())
            {
                if (f.GetType().Name != "ScreenSpaceAmbientOcclusion" || !f.isActive) continue;
                f.SetActive(false);
                features++;
            }

            Debug.Log($"[Museum] Quest 用の軽い画質: 影を切ったライト {lights} 個、切った SSAO {features} 個");
        }
    }
}
