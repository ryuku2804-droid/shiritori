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
    }

    public struct Bounds
    {
        public Vector3 center, size;
        public Bounds(Vector3 center, Vector3 size) { this.center = center; this.size = size; }
        public void Expand(float a) { size = size + Vector3.one * a; }
    }

    public static class Mathf
    {
        public const float PI = (float)Math.PI;
        public const float Infinity = float.PositiveInfinity;
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
        public static float MoveTowards(float a, float b, float d) => Math.Abs(b - a) <= d ? b : a + Math.Sign(b - a) * d;
        public static float Floor(float f) => (float)Math.Floor(f);
        public static int FloorToInt(float f) => (int)Math.Floor(f);
        public static int CeilToInt(float f) => (int)Math.Ceiling(f);
        public static int RoundToInt(float f) => (int)Math.Round(f);
    }
}
