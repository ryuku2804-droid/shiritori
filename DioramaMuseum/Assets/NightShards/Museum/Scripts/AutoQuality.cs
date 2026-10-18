using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace NightShards.Museum
{
    // 画面の細かさ (URP の Render Scale) を、FPS に合わせて自動で上げ下げする。
    //   ・FPS が目標より低いと、少しずつ粗く描く。余裕があれば、少しずつ細かくもどす
    //   ・粗く描いた画面は、FSR (AMD の拡大のしかた) で、ふちがくっきりするように引きのばす
    //   ・MSAA (ふちのギザギザ取り) は、ジオラマには効かず重いだけなので切る
    // 再生を始めると自動で動く (シーンに置く必要はない)。再生をやめると、URP の設定を元にもどす。
    // VR では、目標の FPS を VR の速さ (72) にして使う
    public class AutoQuality : MonoBehaviour
    {
        // false にすると自動調整を止める (PerfDebug の F4 で、手で決めるとき)
        public static bool Enabled = true;
        // 目標の FPS
        public static float TargetFps = 50f;
        // いまの細かさ (0.4〜1)
        public static float CurrentScale { get; private set; } = 1f;

        const float MinScale = 0.4f, MaxScale = 1f, Step = 0.05f, Interval = 0.5f;

        UniversalRenderPipelineAsset urp;
        float originalScale = -1f;
        UpscalingFilterSelection originalFilter;
        int originalMsaa;
        bool originalHdr;
        float timer, frameSum;
        int frames;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Create()
        {
            Enabled = true; // 前の再生で F4 を使っていても、自動からはじめる
            if (FindFirstObjectByType<AutoQuality>() != null) return;
            var go = new GameObject("Auto Quality");
            DontDestroyOnLoad(go);
            go.AddComponent<AutoQuality>();
        }

        void OnEnable()
        {
            urp = GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset;
            if (urp == null) return;
            originalScale = urp.renderScale;
            originalFilter = urp.upscalingFilter;
            originalMsaa = urp.msaaSampleCount;
            originalHdr = urp.supportsHDR;
            // 美術館の明るさは HDR (1 より明るい色) と、ACES の色の整え (トーンマッピング) を前提にしている。
            // HDR が切れた設定 (Android に切りかえたときの Mobile の画質など) だと、画面がまっ白にとんでしまうので、ここで入れる
            if (!urp.supportsHDR)
            {
                urp.supportsHDR = true;
                Debug.LogWarning($"[Museum] いまの画質 ({QualitySettings.names[QualitySettings.GetQualityLevel()]}) の URP の設定「{urp.name}」は HDR が切れていたので、再生中だけ入れました。" +
                                 "Project Settings > Quality で、このプラットフォームの画質を PC の画質 (HDR が入っているもの) にしてください。", urp);
            }
            urp.upscalingFilter = UpscalingFilterSelection.FSR;
            urp.msaaSampleCount = 1;
            CurrentScale = Mathf.Clamp(0.75f, MinScale, MaxScale); // まずは 75% から始めて、FPS を見ながら合わせる
            urp.renderScale = CurrentScale;
        }

        void Update()
        {
            if (urp == null || !Enabled) return;
            frameSum += Time.unscaledDeltaTime;
            frames++;
            timer += Time.unscaledDeltaTime;
            if (timer < Interval) return;

            float fps = frames / Mathf.Max(frameSum, 1e-4f);
            timer = 0f; frameSum = 0f; frames = 0;
            // 目標より 1 割遅ければ粗く、2 割以上速ければ細かく (行ったり来たりしないよう、間をあける)
            if (fps < TargetFps * 0.9f) CurrentScale = Mathf.Max(MinScale, CurrentScale - Step);
            else if (fps > TargetFps * 1.2f) CurrentScale = Mathf.Min(MaxScale, CurrentScale + Step);
            if (!Mathf.Approximately(urp.renderScale, CurrentScale)) urp.renderScale = CurrentScale;
        }

        // 手で細かさを決める (PerfDebug の F4 から)
        public static void SetManual(float scale)
        {
            Enabled = false;
            CurrentScale = scale;
            if (GraphicsSettings.currentRenderPipeline is UniversalRenderPipelineAsset asset) asset.renderScale = scale;
        }

        // URP の設定はファイルそのものなので、再生をやめたら元にもどす
        void OnDisable()
        {
            if (urp == null || originalScale < 0f) return;
            urp.renderScale = originalScale;
            urp.upscalingFilter = originalFilter;
            urp.msaaSampleCount = originalMsaa;
            urp.supportsHDR = originalHdr;
        }
    }
}
