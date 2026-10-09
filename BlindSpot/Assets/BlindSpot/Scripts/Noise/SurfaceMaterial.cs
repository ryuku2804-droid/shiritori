using UnityEngine;

namespace BlindSpot
{
    /// <summary>床の素材。足音の大きさが変わる。</summary>
    public enum SurfaceType
    {
        Default, // コンクリートやリノリウムなど普通の床
        Carpet,  // 静か
        Glass,   // ガラス片が散らばった床。うるさい
        Water,   // 水たまり。うるさい
        Metal,   // 金属の床・グレーチング。とてもうるさい
    }

    /// <summary>
    /// 床 (コライダーを持つオブジェクト) に付けて素材を指定する。
    /// 付いていない床は Default 扱いになる。
    /// </summary>
    public class SurfaceMaterial : MonoBehaviour
    {
        [Tooltip("この床の素材")]
        public SurfaceType type = SurfaceType.Default;

        [Tooltip("ON にすると、素材ごとの標準倍率ではなく下の値を使う")]
        public bool overrideMultiplier = false;

        [Tooltip("足音の届く距離に掛ける倍率 (overrideMultiplier が ON のときだけ使用)")]
        [Min(0f)] public float customMultiplier = 1f;

        [Tooltip("この床専用の足音 (空なら FootstepNoise 側の標準の音を使う)")]
        public AudioClip[] footstepClips;

        /// <summary>この床で実際に使う倍率。</summary>
        public float Multiplier => overrideMultiplier ? customMultiplier : GetDefaultMultiplier(type);

        /// <summary>素材ごとの標準倍率。調整したいときはここを変える。</summary>
        public static float GetDefaultMultiplier(SurfaceType type)
        {
            switch (type)
            {
                case SurfaceType.Carpet: return 0.5f;
                case SurfaceType.Glass: return 1.5f;
                case SurfaceType.Water: return 1.3f;
                case SurfaceType.Metal: return 1.8f;
                default: return 1f;
            }
        }
    }
}
