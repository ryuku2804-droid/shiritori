// Offline preview: generates the particle cloud and dumps it as raw float32 records
// (pos3, normal3, tangent4, color4, uv0 2, uv1 2 = 18 floats) for render_preview.py.
using System;
using System.IO;
using VoidCloak;

static class Program
{
    static int Main(string[] args)
    {
        string outPath = args.Length > 0 ? args[0] : "cloak.bin";
        int stage = args.Length > 1 ? int.Parse(args[1]) : (int)BuildStage.Complete;
        int seed = args.Length > 2 ? int.Parse(args[2]) : 1337;

        var buffer = new ParticleBuffer();
        var gen = new VoidCloakGenerator(new VoidCloakShape(), new VoidCloakDensity(), (BuildStage)stage, seed, buffer);
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
                var c = buffer.colors[i]; var a = buffer.uv0[i]; var b = buffer.uv1[i];
                foreach (var f in new[] { p.x, p.y, p.z, n.x, n.y, n.z, t.x, t.y, t.z, t.w, c.r, c.g, c.b, c.a, a.x, a.y, b.x, b.y }) w.Write(f);
            }
        }
        return 0;
    }
}
