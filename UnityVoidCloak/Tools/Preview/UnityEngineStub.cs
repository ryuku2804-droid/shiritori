// Minimal stand-ins for the UnityEngine math types used by the generators, so the geometry code
// can be compiled and inspected outside Unity (dotnet run). NOT used inside Unity.
using System;

namespace UnityEngine
{
    [AttributeUsage(AttributeTargets.Field)] public class HeaderAttribute : Attribute { public HeaderAttribute(string h) { } }
    [AttributeUsage(AttributeTargets.Field)] public class TooltipAttribute : Attribute { public TooltipAttribute(string t) { } }
    [AttributeUsage(AttributeTargets.Field)] public class RangeAttribute : Attribute { public RangeAttribute(float a, float b) { } }
    [AttributeUsage(AttributeTargets.Field)] public class MinAttribute : Attribute { public MinAttribute(float a) { } }

    public struct Vector2
    {
        public float x, y;
        public Vector2(float x, float y) { this.x = x; this.y = y; }
        public static Vector2 zero => new Vector2(0, 0);
        public float sqrMagnitude => x * x + y * y;
        public void Normalize() { float m = (float)Math.Sqrt(sqrMagnitude); if (m > 1e-5f) { x /= m; y /= m; } }
        public static Vector2 operator *(Vector2 a, float s) => new Vector2(a.x * s, a.y * s);
    }

    public struct Vector4
    {
        public float x, y, z, w;
        public Vector4(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
        public static Vector4 zero => new Vector4(0, 0, 0, 0);
        public static implicit operator Vector4(Vector3 v) => new Vector4(v.x, v.y, v.z, 0);
    }

    public struct Color
    {
        public float r, g, b, a;
        public Color(float r, float g, float b, float a) { this.r = r; this.g = g; this.b = b; this.a = a; }
        public Color(float r, float g, float b) : this(r, g, b, 1f) { }
        public static Color white => new Color(1, 1, 1, 1);
        public static Color black => new Color(0, 0, 0, 1);
    }

    public struct Vector3
    {
        public float x, y, z;
        public Vector3(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
        public static Vector3 zero => new Vector3(0, 0, 0);
        public static Vector3 one => new Vector3(1, 1, 1);
        public static Vector3 up => new Vector3(0, 1, 0);
        public static Vector3 down => new Vector3(0, -1, 0);
        public static Vector3 forward => new Vector3(0, 0, 1);
        public static Vector3 back => new Vector3(0, 0, -1);
        public static Vector3 right => new Vector3(1, 0, 0);
        public static Vector3 left => new Vector3(-1, 0, 0);
        public float sqrMagnitude => x * x + y * y + z * z;
        public float magnitude => (float)Math.Sqrt(sqrMagnitude);
        public Vector3 normalized { get { float m = magnitude; return m > 1e-5f ? this / m : zero; } }
        public void Normalize() { this = normalized; }
        public static Vector3 operator +(Vector3 a, Vector3 b) => new Vector3(a.x + b.x, a.y + b.y, a.z + b.z);
        public static Vector3 operator -(Vector3 a, Vector3 b) => new Vector3(a.x - b.x, a.y - b.y, a.z - b.z);
        public static Vector3 operator -(Vector3 a) => new Vector3(-a.x, -a.y, -a.z);
        public static Vector3 operator *(Vector3 a, float s) => new Vector3(a.x * s, a.y * s, a.z * s);
        public static Vector3 operator *(float s, Vector3 a) => a * s;
        public static Vector3 operator /(Vector3 a, float s) => new Vector3(a.x / s, a.y / s, a.z / s);
        public static float Dot(Vector3 a, Vector3 b) => a.x * b.x + a.y * b.y + a.z * b.z;
        public static Vector3 Cross(Vector3 a, Vector3 b) => new Vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
        public static float Distance(Vector3 a, Vector3 b) => (a - b).magnitude;
        public static float Angle(Vector3 a, Vector3 b) { float d = a.magnitude * b.magnitude; return d < 1e-8f ? 0f : (float)(Math.Acos(Math.Max(-1f, Math.Min(1f, Dot(a, b) / d))) * 180.0 / Math.PI); }
        public static Vector3 Lerp(Vector3 a, Vector3 b, float t) { t = Mathf.Clamp01(t); return a + (b - a) * t; }
        public static Vector3 Scale(Vector3 a, Vector3 b) => new Vector3(a.x * b.x, a.y * b.y, a.z * b.z);
        public static Vector3 MoveTowards(Vector3 a, Vector3 b, float d) { Vector3 v = b - a; float m = v.magnitude; return m <= d || m == 0f ? b : a + v / m * d; }
        public static Vector3 SmoothDamp(Vector3 a, Vector3 b, ref Vector3 vel, float t, float max, float dt) => Lerp(a, b, dt / Math.Max(t, dt));
    }

    /// <summary>Real quaternion maths (the preview builds rotated geometry with it).</summary>
    public struct Quaternion
    {
        public float x, y, z, w;
        public Quaternion(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
        public static Quaternion identity => new Quaternion(0, 0, 0, 1);
        static Quaternion Axis(Vector3 a, float deg) { float h = deg * Mathf.PI / 360f; float s = Mathf.Sin(h); return new Quaternion(a.x * s, a.y * s, a.z * s, Mathf.Cos(h)); }
        // Unity order: Z, then X, then Y
        public static Quaternion Euler(float ex, float ey, float ez) => Axis(Vector3.up, ey) * Axis(Vector3.right, ex) * Axis(Vector3.forward, ez);
        public static Quaternion operator *(Quaternion a, Quaternion b) => new Quaternion(
            a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
            a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z);
        public static Vector3 operator *(Quaternion q, Vector3 v)
        {
            Vector3 u = new Vector3(q.x, q.y, q.z);
            Vector3 t = 2f * Vector3.Cross(u, v);
            return v + q.w * t + Vector3.Cross(u, t);
        }
        public static Quaternion LookRotation(Vector3 f, Vector3 up) => Euler(0f, Mathf.Atan2(f.x, f.z) * 180f / Mathf.PI, 0f);
        public static Quaternion RotateTowards(Quaternion a, Quaternion b, float d) => b;
        public static Quaternion FromToRotation(Vector3 a, Vector3 b)
        {
            a = a.normalized; b = b.normalized;
            float d = Vector3.Dot(a, b);
            if (d < -0.9999f) { Vector3 ax = Vector3.Cross(Vector3.right, a); if (ax.sqrMagnitude < 1e-6f) ax = Vector3.Cross(Vector3.up, a); ax = ax.normalized; return new Quaternion(ax.x, ax.y, ax.z, 0f); }
            Vector3 c = Vector3.Cross(a, b);
            var q = new Quaternion(c.x, c.y, c.z, 1f + d);
            float m = Mathf.Sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
            return new Quaternion(q.x / m, q.y / m, q.z / m, q.w / m);
        }
        public static Quaternion Slerp(Quaternion a, Quaternion b, float t)
        {
            t = Mathf.Clamp01(t);
            float dot = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
            if (dot < 0f) { b = new Quaternion(-b.x, -b.y, -b.z, -b.w); dot = -dot; }
            if (dot > 0.9995f) { var l = new Quaternion(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, a.w + (b.w - a.w) * t); float n = Mathf.Sqrt(l.x * l.x + l.y * l.y + l.z * l.z + l.w * l.w); return new Quaternion(l.x / n, l.y / n, l.z / n, l.w / n); }
            float th = (float)Math.Acos(dot), s0 = Mathf.Sin((1f - t) * th) / Mathf.Sin(th), s1 = Mathf.Sin(t * th) / Mathf.Sin(th);
            return new Quaternion(a.x * s0 + b.x * s1, a.y * s0 + b.y * s1, a.z * s0 + b.z * s1, a.w * s0 + b.w * s1);
        }
        public void ToAngleAxis(out float angle, out Vector3 axis)
        {
            float w = Mathf.Clamp(this.w, -1f, 1f);
            angle = 2f * (float)Math.Acos(w) * 180f / Mathf.PI;
            float s = Mathf.Sqrt(1f - w * w);
            axis = s < 1e-5f ? Vector3.up : new Vector3(x / s, y / s, z / s);
        }
    }

    public struct Bounds
    {
        public Vector3 center, size;
        public Bounds(Vector3 center, Vector3 size) { this.center = center; this.size = size; }
        public void Expand(float a) { size = size + Vector3.one * a; }
        public bool Contains(Vector3 p) { Vector3 h = size * 0.5f; return Math.Abs(p.x - center.x) <= h.x && Math.Abs(p.y - center.y) <= h.y && Math.Abs(p.z - center.z) <= h.z; }
    }

    public static class Mathf
    {
        public const float PI = (float)Math.PI;
        public const float Infinity = float.PositiveInfinity;
        public const float Deg2Rad = PI / 180f;
        public static float Sin(float f) => (float)Math.Sin(f);
        public static float Cos(float f) => (float)Math.Cos(f);
        public static float Atan2(float y, float x) => (float)Math.Atan2(y, x);
        public static float Sqrt(float f) => (float)Math.Sqrt(f);
        public static float Pow(float f, float p) => (float)Math.Pow(f, p);
        public static float Exp(float f) => (float)Math.Exp(f);
        public static float Abs(float f) => Math.Abs(f);
        public static float Sign(float f) => f >= 0f ? 1f : -1f;
        public static float Min(float a, float b) => Math.Min(a, b);
        public static float Max(float a, float b) => Math.Max(a, b);
        public static int Min(int a, int b) => Math.Min(a, b);
        public static int Max(int a, int b) => Math.Max(a, b);
        public static float Clamp(float v, float a, float b) => v < a ? a : (v > b ? b : v);
        public static float Clamp01(float v) => Clamp(v, 0f, 1f);
        public static float Lerp(float a, float b, float t) => a + (b - a) * Clamp01(t);
        public static float LerpAngle(float a, float b, float t) => Lerp(a, b, t);
        public static float DeltaAngle(float a, float b) { float d = (b - a) % 360f; if (d > 180f) d -= 360f; if (d < -180f) d += 360f; return d; }
        public const float Rad2Deg = 180f / PI;
        public static float MoveTowards(float a, float b, float d) => Math.Abs(b - a) <= d ? b : a + Math.Sign(b - a) * d;
        public static float Floor(float f) => (float)Math.Floor(f);
        public static int FloorToInt(float f) => (int)Math.Floor(f);
        public static int CeilToInt(float f) => (int)Math.Ceiling(f);
        public static int RoundToInt(float f) => (int)Math.Round(f);
    }
}
