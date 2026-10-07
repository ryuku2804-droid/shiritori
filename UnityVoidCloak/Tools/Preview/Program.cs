// Offline preview: generates the particle cloud and dumps it as raw float32 records
// (pos3, normal3, tangent4, color4, uv0 2, uv1 2, uv2 2 = 20 floats) for render_preview.py.
// usage: dotnet run -- out.bin [stage 1-10] [seed] [pose 0-2|-1 = no sword]
using System;
using System.IO;
using VoidCloak;

static class Program
{
    static int Main(string[] args)
    {
        if (args.Length > 0 && args[0] == "stage") return DumpStage(args.Length > 1 ? args[1] : "stage.bin");
        string outPath = args.Length > 0 ? args[0] : "cloak.bin";
        int stage = args.Length > 1 ? int.Parse(args[1]) : (int)BuildStage.Complete;
        int seed = args.Length > 2 ? int.Parse(args[2]) : 1337;

        var buffer = new ParticleBuffer();
        int pose = args.Length > 3 ? int.Parse(args[3]) : 0;
        var sword = new VoidCloakSword { enabled = pose >= 0, pose = (SwordPose)System.Math.Max(0, pose) };
        var gen = new VoidCloakGenerator(new VoidCloakShape(), new VoidCloakDensity(), sword, (BuildStage)stage, seed, buffer);
        var sw = System.Diagnostics.Stopwatch.StartNew();
        gen.Generate();
        Console.WriteLine($"particles: {buffer.Count}  ({sw.ElapsedMilliseconds} ms)");
        for (int i = 0; i < (int)CloakPart.Count; i++)
            if (buffer.partCounts[i] > 0) Console.WriteLine($"  {(CloakPart)i,-22} {buffer.partCounts[i]}");

        using (var w = new BinaryWriter(File.Create(outPath)))
        {
            for (int i = 0; i < buffer.Count; i++)
            {
                var p = buffer.positions[i]; var n = buffer.normals[i]; var t = buffer.tangents[i];
                var c = buffer.colors[i]; var a = buffer.uv0[i]; var b = buffer.uv1[i]; var m = buffer.uv2[i];
                foreach (var f in new[] { p.x, p.y, p.z, n.x, n.y, n.z, t.x, t.y, t.z, t.w, c.r, c.g, c.b, c.a, a.x, a.y, b.x, b.y, m.x, m.y }) w.Write(f);
            }
        }
        return 0;
    }

    // Echo Knight prototype stage: every kit piece + the Listener, in world space.
    // Record: pos3, normal3, brightness, random, cavity, type (0 stone, 1 enemy) = 10 floats
    static int DumpStage(string outPath)
    {
        var sw = System.Diagnostics.Stopwatch.StartNew();
        int total = 0;
        using (var w = new BinaryWriter(File.Create(outPath)))
        {
            foreach (var placement in EchoKnight.EchoPrototypeLayout.Pieces())
            {
                var b = new EchoKnight.EchoPointBuilder(placement.spec.seed);
                EchoKnight.EchoKitGenerator.Build(placement.spec, b, new System.Collections.Generic.List<UnityEngine.Bounds>());
                Write(w, b, placement.position, placement.yaw, 0f);
                Console.WriteLine($"  {placement.name,-14} {b.Count,8}");
                total += b.Count;
            }
            foreach (var shrine in EchoKnight.EchoPrototypeLayout.Shrines())
            {
                var frame = new EchoKnight.EchoPointBuilder(91);
                EchoKnight.EchoBellShrineShape.BuildFrame(frame, new System.Collections.Generic.List<UnityEngine.Bounds>());
                Write(w, frame, shrine.position, shrine.yaw, 2f);
                var bell = new EchoKnight.EchoPointBuilder(92);
                EchoKnight.EchoBellShrineShape.BuildBell(bell);
                var q = UnityEngine.Quaternion.Euler(0f, shrine.yaw, 0f);
                Write(w, bell, shrine.position + q * EchoKnight.EchoBellShrineShape.BellPivot, shrine.yaw, 2f);
                Console.WriteLine($"  {shrine.name,-24} {frame.Count + bell.Count,8}");
                total += frame.Count + bell.Count;
            }
            var enemy = new EchoKnight.EchoPointBuilder(7);
            EchoKnight.EchoListenerBody.Build(enemy);
            Write(w, enemy, EchoKnight.EchoPrototypeLayout.ListenerSpawn, 180f, 1f);
            Console.WriteLine($"  {"Listener",-14} {enemy.Count,8}");
            total += enemy.Count;
        }
        Console.WriteLine($"stage points: {total} ({sw.ElapsedMilliseconds} ms)");
        return 0;
    }

    static void Write(BinaryWriter w, EchoKnight.EchoPointBuilder b, UnityEngine.Vector3 pos, float yaw, float type)
    {
        var q = UnityEngine.Quaternion.Euler(0f, yaw, 0f);
        for (int i = 0; i < b.Count; i++)
        {
            var p = q * b.positions[i] + pos; var n = q * b.normals[i]; var c = b.colors[i];
            foreach (var f in new[] { p.x, p.y, p.z, n.x, n.y, n.z, c.r, c.g, c.b, type }) w.Write(f);
        }
    }
}
