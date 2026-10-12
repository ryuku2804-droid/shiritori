using UnityEngine;

namespace BlindSpot
{
    /// <summary>投げられる物の種類。</summary>
    public enum ThrowableType
    {
        Stone,  // 石・コンクリ片: 普通の音
        Bottle, // ガラス瓶: 割れて大きな音
        Can,    // 空き缶: 転がって音が続く
    }

    /// <summary>
    /// 投擲物の種類ごとの性質。試作なのでコードに直接書いている
    /// (1章からは ScriptableObject に移して、Inspector で調整できるようにする)。
    /// </summary>
    public static class ThrowableDefs
    {
        /// <summary>合計で持てる数。</summary>
        public const int MaxCarry = 5;

        /// <summary>種類の数 (配列の大きさに使う)。</summary>
        public const int TypeCount = 3;

        public static string DisplayName(ThrowableType type)
        {
            switch (type)
            {
                case ThrowableType.Stone: return "石";
                case ThrowableType.Bottle: return "瓶";
                default: return "缶";
            }
        }

        /// <summary>ぶつかったときの音の届く距離 (m)。</summary>
        public static float NoiseRadius(ThrowableType type)
        {
            switch (type)
            {
                case ThrowableType.Stone: return 8f;   // 怪物は「調べに来る」
                case ThrowableType.Bottle: return 14f; // 大きな音なので「追いかけて来る」
                default: return 6f;                    // 缶は弱いが、転がる間ずっと鳴る
            }
        }

        public static NoiseType NoiseKind(ThrowableType type)
        {
            return type == ThrowableType.Bottle ? NoiseType.GlassBreak : NoiseType.Throw;
        }

        /// <summary>一度ぶつかったら割れて消えるか。</summary>
        public static bool Breaks(ThrowableType type) => type == ThrowableType.Bottle;

        /// <summary>転がっている間、音が続くか。</summary>
        public static bool Rattles(ThrowableType type) => type == ThrowableType.Can;

        /// <summary>見た目と当たり判定を持った物を作る (落ちている物・投げた物の両方で使う)。</summary>
        public static GameObject CreateObject(ThrowableType type, Material material)
        {
            GameObject go;
            switch (type)
            {
                case ThrowableType.Stone:
                    go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                    go.transform.localScale = new Vector3(0.14f, 0.12f, 0.14f);
                    break;
                case ThrowableType.Bottle:
                    go = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                    go.transform.localScale = new Vector3(0.08f, 0.13f, 0.08f);
                    break;
                default:
                    go = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                    go.transform.localScale = new Vector3(0.07f, 0.06f, 0.07f);
                    break;
            }
            go.name = type.ToString();
            if (material != null) go.GetComponent<MeshRenderer>().sharedMaterial = material;
            return go;
        }

        /// <summary>床に置いたとき、中心が床から何 m 上に来るか。</summary>
        public static float HalfHeight(ThrowableType type)
        {
            // 球は直径 1、カプセルと円柱は高さ 2 が元の大きさ
            return type == ThrowableType.Stone ? 0.5f * 0.12f : type == ThrowableType.Bottle ? 0.13f : 0.06f;
        }
    }
}
