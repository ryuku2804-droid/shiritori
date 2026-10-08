using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// 第三章「鐘のない塔」(Chapter 3: The Tower Without a Bell) - the last chapter.
    /// The castle's bell tower, climbed floor by floor up stone stairs, to the heart of the Silence.
    ///
    ///   A The foot of the tower (y 0)  - bell shards, a shrine, a Listener
    ///   B First gallery (y 3)          - a Hollow Armor walks round four pillars, a Listener in a corner
    ///   C The bell floor (y 6)         - shallow water down the middle; two Listeners; the last singing
    ///                                    door with FIVE bells
    ///   D The broken floor (y 9)       - Aldren's own echo: the knight he was on that night (the last Silent Knight)
    ///   E The heart (y 12)             - Rine's voice. The ending is chosen here.
    /// The path runs north (+Z) from z = 0 to z = 158, rising 3 at every stair.
    /// </summary>
    public static class EchoChapter3Layout
    {
        public static EchoStageLayout Build()
        {
            var L = new EchoStageLayout { name = "Chapter 3 - The Tower Without a Bell", playerSpawn = new Vector3(0f, 0.05f, 3f), playerYaw = 0f };

            // ---------------- A the foot of the tower (x -10 .. 10, z 0 .. 24, y 0)
            L.Floor("Floor A", new Vector3(0f, 0f, 12f), 20.4f, 24.4f, 3001);
            L.Wall("A South", new Vector3(0f, 0f, -0.6f), 0f, 22.4f, 12f, 3002, 1.2f);
            L.Wall("A West", new Vector3(-10.6f, 0f, 12f), 90f, 25.2f, 12f, 3003, 1.2f);
            L.Wall("A East", new Vector3(10.6f, 0f, 12f), 90f, 25.2f, 12f, 3004, 1.2f);
            L.Wall("A North West", new Vector3(-6.8f, 0f, 24.6f), 0f, 7.6f, 12f, 3005, 1.2f);
            L.Wall("A North East", new Vector3(6.8f, 0f, 24.6f), 0f, 7.6f, 12f, 3006, 1.2f);
            L.Pillar("A Pillar 1", new Vector3(-6f, 0f, 9f), 1.6f, 9f, 3007);
            L.Pillar("A Pillar 2", new Vector3(6f, 0f, 15f), 1.6f, 9f, 3008);
            L.Piece("Bell Shard A1", new Vector3(-4.5f, 0f, 17f), 50f, new EchoKitSpec { kind = EchoKitKind.BellFragment, size = new Vector3(5f, 3.5f, 0f), pointSpacing = 0.09f, seed = 3009 }, true);
            L.Piece("Bell Shard A2", new Vector3(5f, 0f, 5f), -30f, new EchoKitSpec { kind = EchoKitKind.BellFragment, size = new Vector3(4f, 2.8f, 0f), pointSpacing = 0.09f, seed = 3010 }, true);
            L.Piece("Rubble A", new Vector3(7.5f, 0f, 21f), 10f, new EchoKitSpec { kind = EchoKitKind.Rubble, size = new Vector3(2.6f, 1.4f, 2.2f), pointSpacing = 0.11f, seed = 3011 });
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Tower Foot)", position = new Vector3(-8.2f, 0f, 4f), yaw = 90f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(4f, 0f, 19f), yaw = 180f, wanderRadius = 3.5f });
            L.Hint("Hint Tower", new Vector3(0f, 3f, 5f), new Vector3(20f, 6f, 8f), "リーネ", "……兄さん。この塔の上で、わたしは待ってる。", null);

            // ---------------- stairs to y 3
            Stairs(L, "Stairs 1", 0f, 24.2f, 3020);

            // ---------------- B first gallery (x -9 .. 9, z 32 .. 56, y 3)
            L.Floor("Floor B", new Vector3(0f, 3f, 44.1f), 18.4f, 24.2f, 3100);
            L.Wall("B West", new Vector3(-9.6f, 3f, 44f), 90f, 24.4f, 9f, 3101, 1.2f);
            L.Wall("B East", new Vector3(9.6f, 3f, 44f), 90f, 24.4f, 9f, 3102, 1.2f);
            L.Wall("B South West", new Vector3(-6.3f, 3f, 32f), 0f, 6.6f, 9f, 3103, 1.2f);
            L.Wall("B South East", new Vector3(6.3f, 3f, 32f), 0f, 6.6f, 9f, 3104, 1.2f);
            L.Wall("B North West", new Vector3(-6.3f, 3f, 56.6f), 0f, 6.6f, 9f, 3105, 1.2f);
            L.Wall("B North East", new Vector3(6.3f, 3f, 56.6f), 0f, 6.6f, 9f, 3106, 1.2f);
            for (int i = 0; i < 4; i++)
                L.Pillar("B Pillar " + (i + 1), new Vector3(i % 2 == 0 ? -4f : 4f, 3f, i < 2 ? 39f : 49f), 1.4f, 8f, 3110 + i);
            L.armors.Add(new EchoArmorPlacement
            {
                position = new Vector3(-6.5f, 3f, 36f), yaw = 90f,
                route = new[] { new Vector3(-6.5f, 3f, 36f), new Vector3(6.5f, 3f, 36f), new Vector3(6.5f, 3f, 52f), new Vector3(-6.5f, 3f, 52f) },
            });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(-6.5f, 3f, 53.5f), yaw = 90f, wanderRadius = 1.5f });

            // ---------------- stairs to y 6
            Stairs(L, "Stairs 2", 3f, 56.2f, 3120);

            // ---------------- C the bell floor (x -12 .. 12, z 64 .. 97, y 6): the last singing door
            L.Floor("Floor C", new Vector3(0f, 6f, 80.6f), 24.4f, 33.2f, 3200);
            L.Wall("C West", new Vector3(-12.6f, 6f, 80.5f), 90f, 33.4f, 9f, 3201, 1.2f);
            L.Wall("C East", new Vector3(12.6f, 6f, 80.5f), 90f, 33.4f, 9f, 3202, 1.2f);
            L.Wall("C South West", new Vector3(-7.8f, 6f, 64f), 0f, 9.6f, 9f, 3203, 1.2f);
            L.Wall("C South East", new Vector3(7.8f, 6f, 64f), 0f, 9.6f, 9f, 3204, 1.2f);
            L.Arch("C North", new Vector3(0f, 6f, 96.6f), 0f, 26.4f, 9f, 5f, 6.5f, 3205);
            L.waters.Add(new EchoWaterPlacement { name = "Bell Floor Water", position = new Vector3(0f, 6f, 80f), size = new Vector2(6f, 24f) });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(-5.5f, 6f, 76f), yaw = 90f, wanderRadius = 3f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(5.5f, 6f, 86f), yaw = -90f, wanderRadius = 3f });
            L.bellDoors.Add(new EchoBellDoorPlacement
            {
                name = "Bell Door (Tower)", position = new Vector3(0f, 6f, 96.6f), yaw = 0f, width = 5f, openingHeight = 6.5f,
                bells = new[]
                {
                    new EchoPuzzleBellPlacement { position = new Vector3(-10.6f, 6f, 70f), yaw = 90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(10.6f, 6f, 72f), yaw = -90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(-10.6f, 6f, 80f), yaw = 90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(10.6f, 6f, 84f), yaw = -90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(-10.6f, 6f, 90f), yaw = 90f },
                },
                sequence = new[] { 3, 1, 4, 0, 2 },
            });
            L.Hint("Hint Bell Floor", new Vector3(0f, 9f, 66.5f), new Vector3(24f, 6f, 4f), "リーネ", "……鐘が、五つ。……これが、最後の扉。", null);

            // ---------------- stairs to y 9
            Stairs(L, "Stairs 3", 6f, 97f, 3220);

            // ---------------- D the broken floor (x -13 .. 13, z 105 .. 134, y 9): Aldren's echo
            L.Floor("Floor D", new Vector3(0f, 9f, 119.7f), 26.4f, 29.4f, 3300);
            L.Wall("D West", new Vector3(-13.6f, 9f, 119.7f), 90f, 29.6f, 10f, 3301, 1.2f);
            L.Wall("D East", new Vector3(13.6f, 9f, 119.7f), 90f, 29.6f, 10f, 3302, 1.2f);
            L.Wall("D South West", new Vector3(-8.3f, 9f, 105f), 0f, 10.6f, 10f, 3303, 1.2f);
            L.Wall("D South East", new Vector3(8.3f, 9f, 105f), 0f, 10.6f, 10f, 3304, 1.2f);
            L.Arch("D North", new Vector3(0f, 9f, 133.6f), 0f, 28.4f, 10f, 5f, 6.5f, 3305);
            for (int i = 0; i < 4; i++)
                L.Pillar("D Pillar " + (i + 1), new Vector3(i % 2 == 0 ? -6f : 6f, 9f, i < 2 ? 112f : 126f), 1.8f, 9f, 3310 + i);
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Broken Floor)", position = new Vector3(-11f, 9f, 108f), yaw = 90f });
            L.bellDoors.Add(new EchoBellDoorPlacement
            {
                name = "Sealed Door (Broken Floor)", position = new Vector3(0f, 9f, 133.6f), yaw = 0f, width = 5f, openingHeight = 6.5f,
                bells = new EchoPuzzleBellPlacement[0], sequence = new int[0],
            });
            L.theatres.Add(new EchoTheatrePlacement { name = "Echo Theatre (The Last Night)", position = new Vector3(0f, 9f, 120f), yaw = 0f,
                sceneId = EchoTheatreScenes.LastNight, triggerRadius = 0f });
            L.bosses.Add(new EchoBossPlacement
            {
                name = "Silent Knight Aldren", position = new Vector3(0f, 9f, 124f), yaw = 180f,
                sealedDoorName = "Sealed Door (Broken Floor)", theatreName = "Echo Theatre (The Last Night)",
                bossName = "沈黙の騎士　アルドレンの残響",
                awakenLine = "……あれは、兄さん……？　あの夜の、兄さんの残響……！", maxHealth = 12f,
            });

            // ---------------- stairs to y 12
            Stairs(L, "Stairs 4", 9f, 134.4f, 3320);

            // ---------------- E the heart (x -8 .. 8, z 142 .. 158, y 12)
            L.Floor("Floor E", new Vector3(0f, 12f, 150.1f), 16.4f, 16.2f, 3400);
            L.Wall("E West", new Vector3(-8.6f, 12f, 150f), 90f, 16.4f, 10f, 3401, 1.2f);
            L.Wall("E East", new Vector3(8.6f, 12f, 150f), 90f, 16.4f, 10f, 3402, 1.2f);
            L.Wall("E South West", new Vector3(-5.8f, 12f, 142f), 0f, 5.6f, 10f, 3403, 1.2f);
            L.Wall("E South East", new Vector3(5.8f, 12f, 142f), 0f, 5.6f, 10f, 3404, 1.2f);
            L.Wall("E North", new Vector3(0f, 12f, 158.6f), 0f, 18.4f, 10f, 3405, 1.2f);
            L.Piece("Heart Shard 1", new Vector3(-5f, 12f, 155f), 30f, new EchoKitSpec { kind = EchoKitKind.BellFragment, size = new Vector3(4f, 2.8f, 0f), pointSpacing = 0.09f, seed = 3406 }, true);
            L.Piece("Heart Shard 2", new Vector3(5.2f, 12f, 154f), -40f, new EchoKitSpec { kind = EchoKitKind.BellFragment, size = new Vector3(3.6f, 2.4f, 0f), pointSpacing = 0.09f, seed = 3407 }, true);
            L.hasEnding = true;
            L.endingCenter = new Vector3(0f, 12f, 151.5f);
            L.endingSize = new Vector3(12f, 6f, 10f);
            return L;
        }

        /// <summary>A stair flight 6 wide and 8 long rising 3 towards +Z, with walls on both sides.</summary>
        static void Stairs(EchoStageLayout L, string stairsName, float baseY, float startZ, int seed)
        {
            L.Piece(stairsName, new Vector3(0f, baseY, startZ + 4f), 0f, new EchoKitSpec { kind = EchoKitKind.Stairs, size = new Vector3(6f, 3f, 8f), steps = 10, pointSpacing = 0.11f, seed = seed });
            L.Wall(stairsName + " West", new Vector3(-3.6f, baseY, startZ + 4f), 90f, 9.2f, 9f, seed + 1, 1.2f);
            L.Wall(stairsName + " East", new Vector3(3.6f, baseY, startZ + 4f), 90f, 9.2f, 9f, seed + 2, 1.2f);
        }
    }
}
