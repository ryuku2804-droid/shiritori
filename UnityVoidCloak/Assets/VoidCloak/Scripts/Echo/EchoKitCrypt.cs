using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>Crypt pieces for chapter 2: gravestones, stone coffins and low ceilings.</summary>
    public static partial class EchoKitGenerator
    {
        static void Gravestone(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float w = s.size.x, h = s.size.y, t = s.size.z;
            float r = w * 0.5f, spring = h - r;
            // a little lean, as old stones have
            Quaternion lean = Quaternion.Euler(b.Range(-6f, 6f), 0f, b.Range(-5f, 5f));
            int start = b.Count;
            System.Func<float, float, bool> outside = (a, y) =>
            {
                if (y <= spring) return false;
                float dx = a - r, dy = y - spring;
                return dx * dx + dy * dy > r * r;
            };
            // a cross cut into the front (no points there: it reads as a dark groove)
            System.Func<float, float, bool> cross = (a, y) =>
                (Mathf.Abs(a - r) < 0.06f && y > h * 0.45f && y < h * 0.85f) || (Mathf.Abs(y - h * 0.72f) < 0.06f && Mathf.Abs(a - r) < w * 0.22f);
            b.Rect(new Vector3(-r, 0f, t * 0.5f), Vector3.right, Vector3.up, w, h, Vector3.forward, 0.8f, 0.9f, (a, y) => outside(a, y) || cross(a, y));
            b.Rect(new Vector3(r, 0f, -t * 0.5f), Vector3.left, Vector3.up, w, h, Vector3.back, 0.7f, 0.9f, outside);
            b.Rect(new Vector3(-r, 0f, -t * 0.5f), Vector3.forward, Vector3.up, t, spring, Vector3.left, 0.6f);
            b.Rect(new Vector3(r, 0f, t * 0.5f), Vector3.back, Vector3.up, t, spring, Vector3.right, 0.6f);
            // the rounded top
            int n = Mathf.CeilToInt(Mathf.PI * r / b.spacing);
            int nt = Mathf.Max(1, Mathf.CeilToInt(t / b.spacing));
            for (int i = 0; i < n; i++)
            {
                for (int j = 0; j < nt; j++)
                {
                    float ang = (i + b.Rand()) / n * Mathf.PI;
                    Vector3 dir = new Vector3(Mathf.Cos(ang), Mathf.Sin(ang), 0f);
                    b.Add(new Vector3(0f, spring, -t * 0.5f + (j + b.Rand()) / nt * t) + dir * r, dir, 0.75f);
                }
            }
            for (int i = start; i < b.Count; i++) { b.positions[i] = lean * b.positions[i]; b.normals[i] = lean * b.normals[i]; }
            // the base it stands in
            b.MasonryBox(new Vector3(0f, 0.12f, 0f), new Vector3(w + 0.3f, 0.24f, t + 0.4f), 0.24f, true, false, 0.6f);
            colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, 0f), new Vector3(w, h, t + 0.3f)));
        }

        static void Coffin(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float w = s.size.x, h = s.size.y, L = s.size.z;
            // the stone box
            b.MasonryBox(new Vector3(0f, h * 0.4f, 0f), new Vector3(w, h * 0.8f, L), h * 0.4f, false, false, 0.75f);
            // the lid: slightly larger, with a ridge along the middle, pushed a little aside
            float lidShift = b.Range(-0.12f, 0.12f), lidTurn = b.Range(-4f, 4f);
            Quaternion q = Quaternion.Euler(0f, lidTurn, 0f);
            int start = b.Count;
            float lw = w + 0.12f, ll = L + 0.12f, lt = h * 0.2f;
            int nu = Mathf.CeilToInt(lw / b.spacing), nv = Mathf.CeilToInt(ll / b.spacing);
            for (int j = 0; j < nv; j++)
            {
                for (int i = 0; i < nu; i++)
                {
                    float x = ((i + b.Rand()) / nu - 0.5f) * lw;
                    float z = ((j + b.Rand()) / nv - 0.5f) * ll;
                    float ridge = 0.08f * (1f - Mathf.Abs(x) / (lw * 0.5f));
                    b.Add(new Vector3(x, h * 0.8f + lt + ridge, z), new Vector3(-Mathf.Sign(x) * 0.25f, 1f, 0f), 0.85f, 0.9f);
                }
            }
            b.Rect(new Vector3(-lw * 0.5f, h * 0.8f, ll * 0.5f), Vector3.right, Vector3.up, lw, lt, Vector3.forward, 0.7f);
            b.Rect(new Vector3(lw * 0.5f, h * 0.8f, -ll * 0.5f), Vector3.left, Vector3.up, lw, lt, Vector3.back, 0.7f);
            b.Rect(new Vector3(lw * 0.5f, h * 0.8f, ll * 0.5f), Vector3.back, Vector3.up, ll, lt, Vector3.right, 0.7f);
            b.Rect(new Vector3(-lw * 0.5f, h * 0.8f, -ll * 0.5f), Vector3.forward, Vector3.up, ll, lt, Vector3.left, 0.7f);
            for (int i = start; i < b.Count; i++)
            {
                b.positions[i] = q * b.positions[i] + new Vector3(lidShift, 0f, 0f);
                b.normals[i] = q * b.normals[i];
            }
            colliders.Add(new Bounds(new Vector3(0f, h * 0.5f, 0f), new Vector3(w, h, L)));
        }

        static void Ceiling(EchoKitSpec s, EchoPointBuilder b, List<Bounds> colliders)
        {
            float w = s.size.x, d = s.size.z;
            // big slabs seen from below
            b.Masonry(new Vector3(-w * 0.5f, 0f, d * 0.5f), Vector3.right, Vector3.back, Vector3.down, w, d, 1.4f, 1.6f, 3.2f, null, 0.08f, 0.04f, 0.7f);
            // ribs across the room every few metres
            for (float z = -d * 0.5f + 3f; z < d * 0.5f - 1f; z += 6f)
            {
                b.Tube(new Vector3(-w * 0.5f, -0.25f, z), new Vector3(-w / 6f, -0.3f, z), new Vector3(w / 6f, -0.3f, z), new Vector3(w * 0.5f, -0.25f, z),
                       x => 0.28f, 0.85f);
            }
            colliders.Add(new Bounds(new Vector3(0f, 0.5f, 0f), new Vector3(w, 1f, d)));
        }

        /// <summary>A sparse, slightly rippled surface (the echo glints on it), plus a rim where it meets the stone.</summary>
        public static void WaterSurface(EchoPointBuilder b, Vector2 size, float depth)
        {
            float sp = 0.16f;
            int nu = Mathf.CeilToInt(size.x / sp), nv = Mathf.CeilToInt(size.y / sp);
            for (int j = 0; j < nv; j++)
            {
                for (int i = 0; i < nu; i++)
                {
                    float x = ((i + b.Rand()) / nu - 0.5f) * size.x;
                    float z = ((j + b.Rand()) / nv - 0.5f) * size.y;
                    float ripple = Mathf.Sin(x * 1.7f + z * 0.6f) * 0.5f + Mathf.Sin(z * 2.3f - x * 0.9f) * 0.5f;
                    Vector3 n = new Vector3(Mathf.Cos(x * 1.7f) * 0.25f, 1f, Mathf.Cos(z * 2.3f) * 0.25f);
                    b.Add(new Vector3(x, depth + ripple * 0.025f, z), n, 0.35f + 0.25f * Mathf.Abs(ripple), 0.8f);
                }
            }
        }
    }
}
