using System;
using UnityEngine;

namespace BlindSpot
{
    /// <summary>音の種類。怪物の反応を変えたいときの判定に使う。</summary>
    public enum NoiseType
    {
        Footstep,   // 足音
        Throw,      // 投擲物の着地音
        GlassBreak, // ガラスが割れる音
        Cough,      // 息止め限界の咳き込み
        Device,     // 番号錠の押下音・ブザーなど
        Other,
    }

    /// <summary>1回分の音の情報。</summary>
    public readonly struct NoiseEvent
    {
        public readonly Vector3 Position;   // 音が鳴った位置
        public readonly float Radius;       // 音が届く距離 (m)
        public readonly NoiseType Type;
        public readonly GameObject Source;  // 音を出したもの (不明なら null)
        public readonly float Time;         // 発生時刻 (Time.time)

        public NoiseEvent(Vector3 position, float radius, NoiseType type, GameObject source, float time)
        {
            Position = position;
            Radius = radius;
            Type = type;
            Source = source;
            Time = time;
        }

        /// <summary>listener の位置でこの音が聞こえるか。hearingMultiplier で聴力の強さを調整できる。</summary>
        public bool IsAudibleAt(Vector3 listener, float hearingMultiplier = 1f)
        {
            float r = Radius * hearingMultiplier;
            return (listener - Position).sqrMagnitude <= r * r;
        }
    }

    /// <summary>
    /// ゲーム内の「音」を一か所に集めて配る静的クラス。
    /// 音を出す側は Emit を呼ぶだけ、聞く側 (怪物など) は OnNoise を購読するだけでよい。
    /// </summary>
    public static class NoiseSystem
    {
        /// <summary>音が発生するたびに呼ばれる。</summary>
        public static event Action<NoiseEvent> OnNoise;

        /// <summary>最後に発生した音 (まだ無ければ null)。</summary>
        public static NoiseEvent? LastNoise { get; private set; }

        /// <summary>プレイ中、シーンビューに音の範囲を円で描くか。</summary>
        public static bool ShowDebugCircles = true;

        /// <summary>デバッグ円を表示しておく秒数。</summary>
        public static float DebugCircleDuration = 1f;

        /// <summary>音を発生させる。</summary>
        /// <param name="position">音が鳴った位置</param>
        /// <param name="radius">音が届く距離 (m)。0 以下なら何もしない</param>
        /// <param name="type">音の種類</param>
        /// <param name="source">音を出したオブジェクト (省略可)</param>
        public static void Emit(Vector3 position, float radius, NoiseType type, GameObject source = null)
        {
            if (radius <= 0f) return;

            var e = new NoiseEvent(position, radius, type, source, UnityEngine.Time.time);
            LastNoise = e;
            OnNoise?.Invoke(e);

#if UNITY_EDITOR || DEVELOPMENT_BUILD
            if (ShowDebugCircles) DrawCircle(position, radius, ColorOf(type), DebugCircleDuration);
#endif
        }

        // 「ドメインリロードなしでプレイ開始」設定でも、前回のプレイの購読が残らないようにする
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        static void ResetStatics()
        {
            OnNoise = null;
            LastNoise = null;
        }

        static Color ColorOf(NoiseType type)
        {
            switch (type)
            {
                case NoiseType.Footstep: return new Color(0.3f, 0.9f, 1f);
                case NoiseType.Throw: return Color.yellow;
                case NoiseType.GlassBreak: return new Color(1f, 0.5f, 0f);
                case NoiseType.Cough: return Color.red;
                case NoiseType.Device: return Color.magenta;
                default: return Color.white;
            }
        }

        /// <summary>水平な円を Debug.DrawLine で描く (シーンビューに表示される)。</summary>
        static void DrawCircle(Vector3 center, float radius, Color color, float duration)
        {
            const int segments = 48;
            Vector3 prev = center + new Vector3(radius, 0f, 0f);
            for (int i = 1; i <= segments; i++)
            {
                float a = i * Mathf.PI * 2f / segments;
                Vector3 next = center + new Vector3(Mathf.Cos(a) * radius, 0f, Mathf.Sin(a) * radius);
                Debug.DrawLine(prev, next, color, duration);
                prev = next;
            }
            // 中心の目印
            Debug.DrawLine(center, center + Vector3.up * 0.5f, color, duration);
        }
    }
}
