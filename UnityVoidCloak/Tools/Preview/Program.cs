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
        if (args.Length > 0 && args[0] == "town") return DumpTownPieces(args.Length > 1 ? args[1] : "town.bin");
        if (args.Length > 0 && args[0] == "armor") return DumpArmor(args.Length > 1 ? args[1] : "armor.bin");
        if (args.Length > 0 && args[0] == "stage") return DumpStage(args.Length > 1 ? args[1] : "stage.bin");
        if (args.Length > 0 && args[0] == "prologue") return DumpLayout(EchoKnight.EchoPrologueLayout.Build(), args.Length > 1 ? args[1] : "prologue");
        if (args.Length > 0 && args[0] == "title") return DumpLayout(EchoKnight.EchoTitleLayout.Build(), args.Length > 1 ? args[1] : "title");
        if (args.Length > 0 && args[0] == "chapter3") return DumpLayout(EchoKnight.EchoChapter3Layout.Build(), args.Length > 1 ? args[1] : "chapter3");
        if (args.Length > 0 && args[0] == "chapter2") return DumpLayout(EchoKnight.EchoChapter2Layout.Build(), args.Length > 1 ? args[1] : "chapter2");
        if (args.Length > 0 && args[0] == "chapter1") return DumpLayout(EchoKnight.EchoChapter1Layout.Build(), args.Length > 1 ? args[1] : "chapter1");
        if (args.Length > 0 && args[0] == "sounds") return DumpSounds(args.Length > 1 ? args[1] : "sounds");
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

    // The chapter 1 town pieces side by side along X: house, ruined house, well, stall.
    static int DumpTownPieces(string outPath)
    {
        var K = EchoKnight.EchoKitKind.House;
        var specs = new (EchoKnight.EchoKitSpec spec, float x)[]
        {
            (new EchoKnight.EchoKitSpec { kind = K, size = new UnityEngine.Vector3(11f, 9f, 8f), roofHeight = 4.5f, pointSpacing = 0.16f, seed = 1 }, -14f),
            (new EchoKnight.EchoKitSpec { kind = K, size = new UnityEngine.Vector3(10f, 8f, 8f), ruined = true, pointSpacing = 0.16f, seed = 2 }, 0f),
            (new EchoKnight.EchoKitSpec { kind = EchoKnight.EchoKitKind.Well, size = new UnityEngine.Vector3(3.2f, 1.1f, 0f), pointSpacing = 0.09f, seed = 3 }, 10f),
            (new EchoKnight.EchoKitSpec { kind = EchoKnight.EchoKitKind.Stall, size = new UnityEngine.Vector3(4f, 3.4f, 2.6f), pointSpacing = 0.1f, seed = 4 }, 17f),
        };
        int total = 0;
        using (var w = new BinaryWriter(File.Create(outPath)))
        {
            foreach (var (spec, x) in specs)
            {
                var b = new EchoKnight.EchoPointBuilder(spec.seed);
                EchoKnight.EchoKitGenerator.Build(spec, b, new System.Collections.Generic.List<UnityEngine.Bounds>());
                Write(w, b, new UnityEngine.Vector3(x, 0f, 0f), 0f, 0f);
                Console.WriteLine($"  {spec.kind}{(spec.ruined ? " (ruined)" : ""),-10} {b.Count,8}");
                total += b.Count;
            }
        }
        Console.WriteLine($"town pieces: {total}");
        return 0;
    }

    // The Hollow Armor alone at the origin (same record as DumpStage, type 1).
    static int DumpArmor(string outPath)
    {
        var b = new EchoKnight.EchoPointBuilder(11);
        EchoKnight.EchoHollowArmorBody.Build(b);
        using (var w = new BinaryWriter(File.Create(outPath))) Write(w, b, UnityEngine.Vector3.zero, 0f, 1f);
        Console.WriteLine($"Hollow Armor: {b.Count} points");
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

    // Renders every procedural sound effect to a 16-bit WAV file so it can be listened to outside Unity.
    static int DumpSounds(string dir)
    {
        Directory.CreateDirectory(dir);
        for (int s = 0; s < (int)EchoKnight.EchoSound.Count; s++)
        {
            var sound = (EchoKnight.EchoSound)s;
            float[] data = EchoKnight.EchoSoundSynth.Generate(sound, 0);
            string path = Path.Combine(dir, sound + ".wav");
            using (var w = new BinaryWriter(File.Create(path)))
            {
                int rate = EchoKnight.EchoSoundSynth.SampleRate, bytes = data.Length * 2;
                w.Write(System.Text.Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + bytes);
                w.Write(System.Text.Encoding.ASCII.GetBytes("WAVEfmt ")); w.Write(16); w.Write((short)1); w.Write((short)1);
                w.Write(rate); w.Write(rate * 2); w.Write((short)2); w.Write((short)16);
                w.Write(System.Text.Encoding.ASCII.GetBytes("data")); w.Write(bytes);
                foreach (float f in data) w.Write((short)Math.Max(-32767, Math.Min(32767, (int)(f * 32767f))));
            }
            Console.WriteLine($"  {sound,-16} {data.Length / (float)EchoKnight.EchoSoundSynth.SampleRate,5:0.00} s");
        }
        return 0;
    }

    // Dumps a whole stage layout: <prefix>.bin (points, same record as DumpStage, type 0 stone / 1 enemy / 2 gold),
    // <prefix>_boxes.txt (colliders: cx cy cz sx sy sz yaw) and <prefix>_meta.txt (spawn, goal, hints, ghosts, shrines, listeners).
    static int DumpLayout(EchoKnight.EchoStageLayout L, string prefix)
    {
        int total = 0;
        var boxes = new System.Text.StringBuilder();
        var inv = System.Globalization.CultureInfo.InvariantCulture;
        void Box(UnityEngine.Bounds b, UnityEngine.Vector3 pos, float yaw)
        {
            var q = UnityEngine.Quaternion.Euler(0f, yaw, 0f);
            var c = q * b.center + pos;
            boxes.AppendLine(string.Format(inv, "{0} {1} {2} {3} {4} {5} {6}", c.x, c.y, c.z, b.size.x, b.size.y, b.size.z, yaw));
        }
        using (var w = new BinaryWriter(File.Create(prefix + ".bin")))
        {
            foreach (var p in L.pieces)
            {
                var b = new EchoKnight.EchoPointBuilder(p.spec.seed);
                var cols = new System.Collections.Generic.List<UnityEngine.Bounds>();
                EchoKnight.EchoKitGenerator.Build(p.spec, b, cols);
                Write(w, b, p.position, p.yaw, p.gold ? 2f : 0f);
                foreach (var c in cols) Box(c, p.position, p.yaw);
                total += b.Count;
            }
            foreach (var sh in L.shrines)
            {
                var f = new EchoKnight.EchoPointBuilder(91);
                var cols = new System.Collections.Generic.List<UnityEngine.Bounds>();
                EchoKnight.EchoBellShrineShape.BuildFrame(f, cols);
                Write(w, f, sh.position, sh.yaw, 2f);
                var bell = new EchoKnight.EchoPointBuilder(92);
                EchoKnight.EchoBellShrineShape.BuildBell(bell);
                Write(w, bell, sh.position + UnityEngine.Quaternion.Euler(0f, sh.yaw, 0f) * EchoKnight.EchoBellShrineShape.BellPivot, sh.yaw, 2f);
                foreach (var c in cols) Box(c, sh.position, sh.yaw);
                total += f.Count + bell.Count;
            }
            foreach (var g in L.ghosts)
            {
                var b = new EchoKnight.EchoPointBuilder(31);
                EchoKnight.EchoGhostBody.Build(b);
                Write(w, b, g.position, g.yaw, 2f);
                total += b.Count;
            }
            foreach (var e in L.listeners)
            {
                var b = new EchoKnight.EchoPointBuilder(7);
                EchoKnight.EchoListenerBody.Build(b);
                Write(w, b, e.position, e.yaw, 1f);
                total += b.Count;
            }
            foreach (var a in L.armors)
            {
                var b = new EchoKnight.EchoPointBuilder(11);
                EchoKnight.EchoHollowArmorBody.Build(b);
                Write(w, b, a.position, a.yaw, 1f);
                total += b.Count;
            }
            foreach (var water in L.waters)
            {
                var b = new EchoKnight.EchoPointBuilder(5);
                EchoKnight.EchoKitGenerator.WaterSurface(b, water.size, 0.35f);
                Write(w, b, water.position, 0f, 0f);
                total += b.Count;
            }
            foreach (var th in L.theatres)
            {
                var scene = EchoKnight.EchoTheatreScenes.Get(th.sceneId);
                if (scene == null || th.triggerRadius <= 0f) continue;   // hidden until a boss falls
                var tq = UnityEngine.Quaternion.Euler(0f, th.yaw, 0f);
                foreach (var keys in scene.actors)
                {
                    if (keys[0].pose == EchoKnight.EchoFigurePose.None) continue;
                    var b = new EchoKnight.EchoPointBuilder(40 + (int)keys[0].pose);
                    EchoKnight.EchoFigureBody.Build(b, keys[0].pose);
                    Write(w, b, th.position + tq * keys[0].position, th.yaw + keys[0].yaw, 2f);
                    total += b.Count;
                }
            }
            if (L.hasEnding)
            {
                var b = new EchoKnight.EchoPointBuilder(77);
                EchoKnight.EchoFigureBody.Build(b, EchoKnight.EchoFigurePose.ChildKneel);
                Write(w, b, L.endingCenter + new UnityEngine.Vector3(0f, 0f, 1.5f), 180f, 2f);
                total += b.Count;
            }
            foreach (var boss in L.bosses)
            {
                var b = new EchoKnight.EchoPointBuilder(21);
                EchoKnight.EchoSilentKnightBody.Build(b);
                for (int i = 0; i < b.Count; i++) b.positions[i] = b.positions[i] * 1.12f;
                Write(w, b, boss.position, boss.yaw, 1f);
                total += b.Count;
            }
            // sound puzzles. The hollow wall and the door leaves are left out of the colliders,
            // so the walkability check sees them solved (broken / open).
            foreach (var hw in L.hollowWalls)
            {
                var b = new EchoKnight.EchoPointBuilder(hw.seed);
                var spec = new EchoKnight.EchoKitSpec { kind = EchoKnight.EchoKitKind.Wall, size = hw.size, pointSpacing = 0.15f, seed = hw.seed };
                EchoKnight.EchoKitGenerator.Build(spec, b, new System.Collections.Generic.List<UnityEngine.Bounds>());
                Write(w, b, hw.position, hw.yaw, 0f);
                total += b.Count;
            }
            foreach (var door in L.bellDoors)
            {
                var dq = UnityEngine.Quaternion.Euler(0f, door.yaw, 0f);
                for (int side = -1; side <= 1; side += 2)
                {
                    var b = new EchoKnight.EchoPointBuilder(side < 0 ? 71 : 72);
                    EchoKnight.EchoBellDoorShape.BuildLeaf(b, door.width, door.openingHeight, side, new System.Collections.Generic.List<UnityEngine.Bounds>());
                    Write(w, b, door.position + dq * new UnityEngine.Vector3(side * door.width * 0.5f, 0f, 0f), door.yaw, 0f);
                    total += b.Count;
                }
                foreach (var bp in door.bells)
                {
                    var stand = new EchoKnight.EchoPointBuilder(61);
                    var cols = new System.Collections.Generic.List<UnityEngine.Bounds>();
                    EchoKnight.EchoPuzzleBellShape.BuildStand(stand, cols);
                    Write(w, stand, bp.position, bp.yaw, 2f);
                    foreach (var c in cols) Box(c, bp.position, bp.yaw);
                    var bell = new EchoKnight.EchoPointBuilder(62);
                    EchoKnight.EchoPuzzleBellShape.BuildBell(bell);
                    Write(w, bell, bp.position + UnityEngine.Quaternion.Euler(0f, bp.yaw, 0f) * EchoKnight.EchoPuzzleBellShape.BellPivot, bp.yaw, 2f);
                    total += stand.Count + bell.Count;
                }
            }
        }
        File.WriteAllText(prefix + "_boxes.txt", boxes.ToString());
        var meta = new System.Text.StringBuilder();
        meta.AppendLine(string.Format(inv, "spawn {0} {1} {2}", L.playerSpawn.x, L.playerSpawn.y, L.playerSpawn.z));
        if (L.hasEnding)   // the walkability check treats the ending zone as the goal
            meta.AppendLine(string.Format(inv, "goal {0} {1} {2} {3} {4} {5}", L.endingCenter.x, L.endingCenter.y + 2f, L.endingCenter.z, L.endingSize.x, 4f, L.endingSize.z));
        else
            meta.AppendLine(string.Format(inv, "goal {0} {1} {2} {3} {4} {5}", L.goalCenter.x, L.goalCenter.y, L.goalCenter.z, L.goalSize.x, L.goalSize.y, L.goalSize.z));
        foreach (var h in L.hints) meta.AppendLine(string.Format(inv, "hint {0} {1} {2} {3} {4} {5}", h.center.x, h.center.y, h.center.z, h.size.x, h.size.y, h.size.z));
        foreach (var g in L.ghosts) meta.AppendLine(string.Format(inv, "ghost {0} {1} {2}", g.position.x, g.position.y, g.position.z));
        foreach (var s in L.shrines) meta.AppendLine(string.Format(inv, "shrine {0} {1} {2}", s.position.x, s.position.y, s.position.z));
        foreach (var e in L.listeners) meta.AppendLine(string.Format(inv, "listener {0} {1} {2} {3}", e.position.x, e.position.y, e.position.z, e.wanderRadius));
        foreach (var door in L.bellDoors)
            foreach (var bp in door.bells) meta.AppendLine(string.Format(inv, "bell {0} {1} {2}", bp.position.x, bp.position.y, bp.position.z));
        foreach (var boss in L.bosses) meta.AppendLine(string.Format(inv, "armor {0} {1} {2}", boss.position.x, boss.position.y, boss.position.z));
        foreach (var a in L.armors)
            foreach (var r in a.route) meta.AppendLine(string.Format(inv, "armor {0} {1} {2}", r.x, r.y, r.z));
        File.WriteAllText(prefix + "_meta.txt", meta.ToString());
        Console.WriteLine($"{L.name}: {total} points, {boxes.ToString().Split('\n').Length - 1} colliders");
        return 0;
    }
}
