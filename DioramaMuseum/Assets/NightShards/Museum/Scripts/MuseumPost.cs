using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace NightShards.Museum
{
    // 画面の仕上げ (ポストプロセス)。プレイヤーに付ける。
    //   ブルーム (明るい所がにじむ)・ACES のトーンマップ (映画のような明るさの階調)・ビネット (画面の四隅を暗く)
    //   ※ 鑑賞モードのぼかし (被写界深度) は、ジオラマまでぼやけてしまうのでやめた
    // 設定はすべてコードで作るので、シーンの Global Volume を編集しなくてよい (こちらのほうが優先される)
    public class MuseumPost : MonoBehaviour
    {
        public ExhibitViewer viewer;
        public Camera viewCamera;

        [Header("いつも")]
        [SerializeField] float bloomIntensity = 0.8f;
        [SerializeField] float bloomThreshold = 1f;
        [SerializeField, Range(0f, 1f)] float vignette = 0.3f;

        Volume baseVolume;
        VolumeProfile baseProfile;

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

        void OnDestroy()
        {
            if (baseProfile != null) Destroy(baseProfile);
        }
    }
}
