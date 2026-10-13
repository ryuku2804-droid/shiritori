using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace NightShards.Museum
{
    // 画面の仕上げ (ポストプロセス)。プレイヤーに付ける。
    //   いつも: ブルーム (明るい所がにじむ)・ACES のトーンマップ (映画のような明るさの階調)・ビネット (画面の四隅を暗く)
    //   鑑賞モード: 被写界深度で作品の前後をぼかす。ミニチュア写真 (ティルトシフト) のような「小さな世界」に見える
    // 設定はすべてコードで作るので、シーンの Global Volume を編集しなくてよい (こちらのほうが優先される)
    public class MuseumPost : MonoBehaviour
    {
        public ExhibitViewer viewer;
        public Camera viewCamera;

        [Header("いつも")]
        [SerializeField] float bloomIntensity = 0.8f;
        [SerializeField] float bloomThreshold = 1f;
        [SerializeField, Range(0f, 1f)] float vignette = 0.3f;

        [Header("鑑賞モードのぼかし")]
        [Tooltip("レンズの F 値。小さいほど、ピントの前後が強くぼける")]
        [SerializeField] float aperture = 4f;
        [Tooltip("レンズの焦点距離 (mm)。大きいほど、ぼけが強い")]
        [SerializeField] float focalLength = 60f;
        [Tooltip("ピントを作品の中心から奥へずらす量 (m)。作品全体にピントを合わせるため")]
        [SerializeField] float focusOffset = 0.2f;

        Volume baseVolume, focusVolume;
        VolumeProfile baseProfile, focusProfile;
        DepthOfField dof;

        void Start()
        {
            baseProfile = ScriptableObject.CreateInstance<VolumeProfile>();
            var bloom = baseProfile.Add<Bloom>(true);
            bloom.intensity.Override(bloomIntensity);
            bloom.threshold.Override(bloomThreshold);
            bloom.scatter.Override(0.7f);
            var tone = baseProfile.Add<Tonemapping>(true);
            tone.mode.Override(TonemappingMode.ACES);
            var vig = baseProfile.Add<Vignette>(true);
            vig.intensity.Override(vignette);
            vig.smoothness.Override(0.45f);
            baseVolume = MakeVolume("Museum Post", baseProfile, 10f);

            focusProfile = ScriptableObject.CreateInstance<VolumeProfile>();
            dof = focusProfile.Add<DepthOfField>(true);
            dof.mode.Override(DepthOfFieldMode.Bokeh);
            dof.focusDistance.Override(1.6f);
            dof.aperture.Override(aperture);
            dof.focalLength.Override(focalLength);
            focusVolume = MakeVolume("Museum Focus", focusProfile, 11f);
            focusVolume.weight = 0f;
        }

        Volume MakeVolume(string name, VolumeProfile profile, float priority)
        {
            var go = new GameObject(name);
            go.transform.SetParent(transform, false);
            var v = go.AddComponent<Volume>();
            v.isGlobal = true;
            v.priority = priority;
            v.sharedProfile = profile;
            return v;
        }

        void LateUpdate()
        {
            if (focusVolume == null) return;
            float w = viewer != null ? viewer.Blend : 0f;
            focusVolume.weight = w;
            if (w > 0f && viewer.Current != null && viewCamera != null)
            {
                float d = Vector3.Distance(viewCamera.transform.position, viewer.Current.FocusPoint) + focusOffset;
                dof.focusDistance.value = d;
            }
        }

        void OnDestroy()
        {
            if (baseProfile != null) Destroy(baseProfile);
            if (focusProfile != null) Destroy(focusProfile);
        }
    }
}
