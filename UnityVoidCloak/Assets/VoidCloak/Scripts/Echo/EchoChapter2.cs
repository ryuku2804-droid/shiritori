using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// 第二章「沈んだ修道院」(Chapter 2: The Sunken Abbey), under the cathedral.
    ///
    ///   A Crypt stair       - a low corridor between gravestones
    ///   B Burial vault      - coffins and columns under a low ceiling; two Listeners; a shrine
    ///   C Flooded cloister  - shallow water fills the middle: every step there splashes and echoes.
    ///                         Two Listeners wade in it, a Hollow Armor walks the east walk, a Listener
    ///                         waits on the west walk. Which way?
    ///   D The nest          - the chapter house: four Listeners among coffins. An echo theatre: the chosen
    ///                         children. A hollow wall in the west wall hides a little room.
    ///   E Passage           - a shrine
    ///   F The sunken altar  - the Silent Knight Orvan, water down both sides, four pillars
    ///   G Behind the sealed door - the end of the chapter
    /// The path runs north (+Z) from z = 0 to z = 196.
    /// </summary>
    public static class EchoChapter2Layout
    {
        public static EchoStageLayout Build()
        {
            var L = new EchoStageLayout { name = "Chapter 2 - The Sunken Abbey", playerSpawn = new Vector3(0f, 0.05f, 3f), playerYaw = 0f };

            // ---------------- A crypt stair (x -3.5 .. 3.5, z 0 .. 20, ceiling 6)
            L.Floor("Floor A", new Vector3(0f, 0f, 10f), 7.4f, 21f, 2001);
            L.Wall("A South", new Vector3(0f, 0f, -0.6f), 0f, 9.4f, 6f, 2002, 1.2f);
            L.Wall("A West", new Vector3(-4.1f, 0f, 10f), 90f, 21.2f, 6f, 2003, 1.2f);
            L.Wall("A East", new Vector3(4.1f, 0f, 10f), 90f, 21.2f, 6f, 2004, 1.2f);
            Ceiling(L, "Ceiling A", new Vector3(0f, 6f, 10f), 7.4f, 21f, 2005);
            for (int i = 0; i < 3; i++)
            {
                float z = 6f + i * 5f;
                L.Piece("Grave A W" + i, new Vector3(-2.9f, 0f, z), 90f, Grave(2010 + i));
                L.Piece("Grave A E" + i, new Vector3(2.9f, 0f, z + 2f), -90f, Grave(2020 + i));
            }
            L.Hint("Hint Crypt", new Vector3(0f, 3f, 6f), new Vector3(7f, 6f, 10f), "リーネ", "……地下。息が、白い。", null);

            // ---------------- B burial vault (x -12 .. 12, z 20 .. 60, ceiling 7)
            L.Floor("Floor B", new Vector3(0f, 0f, 40f), 25.2f, 41f, 2100);
            L.Wall("B South West", new Vector3(-8.35f, 0f, 20f), 0f, 8.5f, 7f, 2101, 1.2f);
            L.Wall("B South East", new Vector3(8.35f, 0f, 20f), 0f, 8.5f, 7f, 2102, 1.2f);
            L.Wall("B South Lintel", new Vector3(0f, 6f, 20f), 0f, 7f, 1f, 2103, 1.2f);
            L.Wall("B West", new Vector3(-12.6f, 0f, 40f), 90f, 41.2f, 7f, 2104, 1.2f);
            L.Wall("B East", new Vector3(12.6f, 0f, 40f), 90f, 41.2f, 7f, 2105, 1.2f);
            Ceiling(L, "Ceiling B", new Vector3(0f, 7f, 40f), 25.2f, 41f, 2106);
            for (int i = 0; i < 4; i++)
            {
                L.Pillar("Vault Column W" + i, new Vector3(-5f, 0f, 28f + i * 8f), 1.4f, 7f, 2110 + i);
                L.Pillar("Vault Column E" + i, new Vector3(5f, 0f, 28f + i * 8f), 1.4f, 7f, 2120 + i);
            }
            for (int i = 0; i < 5; i++)
            {
                L.Piece("Coffin B W" + i, new Vector3(-9.5f, 0f, 30f + i * 6f), 0f, Coffin(2130 + i));
                L.Piece("Coffin B E" + i, new Vector3(9.5f, 0f, 30f + i * 6f), 0f, Coffin(2140 + i));
            }
            L.Piece("Grave B1", new Vector3(-1.6f, 0f, 40f), 0f, Grave(2150));
            L.Piece("Grave B2", new Vector3(1.4f, 0f, 41f), 10f, Grave(2151));
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Vault)", position = new Vector3(-10f, 0f, 23f), yaw = 90f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(-2f, 0f, 34f), yaw = 180f, wanderRadius = 4f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(2f, 0f, 50f), yaw = 180f, wanderRadius = 4f });

            // ---------------- C flooded cloister (x -16 .. 16, z 60 .. 104, open above)
            L.Arch("Arch B-C", new Vector3(0f, 0f, 60f), 0f, 33.2f, 9f, 5f, 6f, 2200);
            L.Floor("Floor C", new Vector3(0f, 0f, 82f), 33.2f, 45f, 2201);
            L.Wall("C West", new Vector3(-16.6f, 0f, 82f), 90f, 45.2f, 9f, 2202, 1.2f);
            L.Wall("C East", new Vector3(16.6f, 0f, 82f), 90f, 45.2f, 9f, 2203, 1.2f);
            L.waters.Add(new EchoWaterPlacement { name = "Cloister Water", position = new Vector3(0f, 0f, 82f), size = new Vector2(20f, 32f) });
            for (int i = 0; i < 5; i++)
            {
                L.Pillar("Cloister Arcade W" + i, new Vector3(-10.6f, 0f, 66f + i * 8f), 1.2f, 6f, 2210 + i);
                L.Pillar("Cloister Arcade E" + i, new Vector3(10.6f, 0f, 66f + i * 8f), 1.2f, 6f, 2220 + i);
            }
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(-4f, 0f, 76f), yaw = 180f, wanderRadius = 4f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(4f, 0f, 92f), yaw = 180f, wanderRadius = 4f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(-13.2f, 0f, 82f), yaw = 90f, wanderRadius = 3f });
            L.armors.Add(new EchoArmorPlacement
            {
                position = new Vector3(13.2f, 0f, 63f), yaw = 0f,
                route = new[] { new Vector3(13.2f, 0f, 63f), new Vector3(13.2f, 0f, 101f) },
            });
            L.Hint("Hint Water", new Vector3(0f, 3f, 62.5f), new Vector3(32f, 6f, 4f), "リーネ", "……水の音。踏めば、すべてに聞こえる。",
                   "浅い水の中では、一歩ごとに大きな波が出る（よく見えるが、聞かれる）。水を歩く敵も、しぶきで見える");

            // ---------------- D the nest (x -14 .. 14, z 104 .. 140, ceiling 7)
            L.Arch("Arch C-D", new Vector3(0f, 0f, 104f), 0f, 33.2f, 9f, 5f, 6f, 2300);
            L.Floor("Floor D", new Vector3(0f, 0f, 122f), 29.6f, 37f, 2301);
            L.Wall("D West South", new Vector3(-14.6f, 0f, 108.75f), 90f, 9.5f, 7f, 2302, 1.2f);
            L.Wall("D West North", new Vector3(-14.6f, 0f, 129.25f), 90f, 21.5f, 7f, 2303, 1.2f);
            L.Wall("D West Lintel", new Vector3(-14.6f, 5f, 116f), 90f, 5f, 2f, 2304, 1.2f);
            L.hollowWalls.Add(new EchoHollowWallPlacement { name = "Hollow Wall (Nest)", position = new Vector3(-14.6f, 0f, 116f), yaw = 90f, size = new Vector3(5f, 5f, 1.2f), seed = 2305 });
            L.Wall("D East", new Vector3(14.6f, 0f, 122f), 90f, 37.2f, 7f, 2306, 1.2f);
            Ceiling(L, "Ceiling D", new Vector3(0f, 7f, 122f), 29.6f, 37f, 2307);
            for (int i = 0; i < 4; i++)
            {
                float z = i < 2 ? 112f + i * 6f : 126f + (i - 2) * 6f;
                L.Piece("Coffin D W" + i, new Vector3(-4f, 0f, z), 0f, Coffin(2310 + i));
                L.Piece("Coffin D E" + i, new Vector3(4f, 0f, z), 0f, Coffin(2320 + i));
            }
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(-8f, 0f, 110f), yaw = 90f, wanderRadius = 2f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(8f, 0f, 112f), yaw = -90f, wanderRadius = 2f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(-7f, 0f, 131f), yaw = 90f, wanderRadius = 2.5f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(7f, 0f, 129f), yaw = -90f, wanderRadius = 2.5f });
            L.theatres.Add(new EchoTheatrePlacement { name = "Echo Theatre (The Chosen)", position = new Vector3(0f, 0f, 124f), yaw = 0f,
                sceneId = EchoTheatreScenes.ChosenChildren, triggerRadius = 12f });
            L.Hint("Hint Nest", new Vector3(0f, 3f, 106.5f), new Vector3(28f, 6f, 4f), "リーネ", "……たくさん、いる。……息を、殺して。", null);

            // the little room behind the hollow wall
            L.Floor("Floor Hidden Cell", new Vector3(-19f, 0f, 116f), 8.6f, 9.4f, 2330);
            L.Wall("Hidden Cell West", new Vector3(-23.6f, 0f, 116f), 90f, 10.6f, 6f, 2331, 1.2f);
            L.Wall("Hidden Cell North", new Vector3(-19.2f, 0f, 121.1f), 0f, 9.6f, 6f, 2332, 1.2f);
            L.Wall("Hidden Cell South", new Vector3(-19.2f, 0f, 110.9f), 0f, 9.6f, 6f, 2333, 1.2f);
            Ceiling(L, "Ceiling Hidden Cell", new Vector3(-19f, 6f, 116f), 8.6f, 9.4f, 2334);
            L.ghosts.Add(new EchoGhostPlacement { name = "Echo Unchosen Child", position = new Vector3(-21f, 0f, 116f), yaw = 90f,
                speaker = "選ばれなかった子の残響", line = "「……わたしじゃなくて、よかった。……ごめんね、リーネ」" });

            // ---------------- E passage (x -5 .. 5, z 140 .. 156, ceiling 6)
            L.Arch("Arch D-E", new Vector3(0f, 0f, 140f), 0f, 29.2f, 7f, 5f, 6f, 2400);
            L.Floor("Floor E", new Vector3(0f, 0f, 148f), 10.4f, 17f, 2401);
            L.Wall("E West", new Vector3(-5.6f, 0f, 148f), 90f, 17.2f, 6f, 2402, 1.2f);
            L.Wall("E East", new Vector3(5.6f, 0f, 148f), 90f, 17.2f, 6f, 2403, 1.2f);
            Ceiling(L, "Ceiling E", new Vector3(0f, 6f, 148f), 10.4f, 17f, 2404);
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Passage)", position = new Vector3(-3.8f, 0f, 148f), yaw = 90f });

            // ---------------- F the sunken altar (x -13 .. 13, z 156 .. 186): the Silent Knight Orvan
            L.Arch("Arch E-F", new Vector3(0f, 0f, 156f), 0f, 27.2f, 12f, 5f, 6f, 2500);
            L.Floor("Floor F", new Vector3(0f, 0f, 171.2f), 26.4f, 31.4f, 2501);
            L.Wall("F West", new Vector3(-13.6f, 0f, 171.2f), 90f, 31.6f, 12f, 2502, 1.2f);
            L.Wall("F East", new Vector3(13.6f, 0f, 171.2f), 90f, 31.6f, 12f, 2503, 1.2f);
            L.Arch("F North", new Vector3(0f, 0f, 186.4f), 0f, 27.2f, 12f, 5f, 6.5f, 2504);
            L.waters.Add(new EchoWaterPlacement { name = "Altar Water West", position = new Vector3(-9.6f, 0f, 171f), size = new Vector2(7f, 29f) });
            L.waters.Add(new EchoWaterPlacement { name = "Altar Water East", position = new Vector3(9.6f, 0f, 171f), size = new Vector2(7f, 29f) });
            for (int i = 0; i < 4; i++)
                L.Pillar("Altar Pillar " + (i + 1), new Vector3(i % 2 == 0 ? -6f : 6f, 0f, i < 2 ? 164f : 178f), 1.8f, 9f, 2510 + i);
            L.Piece("Sunken Altar", new Vector3(0f, 0f, 170.5f), 0f, new EchoKitSpec { kind = EchoKitKind.Platform, size = new Vector3(5f, 1f, 1.6f), pointSpacing = 0.1f, seed = 2520 });
            L.bellDoors.Add(new EchoBellDoorPlacement
            {
                name = "Sealed Door (Sunken Altar)", position = new Vector3(0f, 0f, 186.4f), yaw = 0f, width = 5f, openingHeight = 6.5f,
                bells = new EchoPuzzleBellPlacement[0], sequence = new int[0],
            });
            L.theatres.Add(new EchoTheatrePlacement { name = "Echo Theatre (Orvan)", position = new Vector3(0f, 0f, 172f), yaw = 0f,
                sceneId = EchoTheatreScenes.OrvanMemory, triggerRadius = 0f });
            L.bosses.Add(new EchoBossPlacement
            {
                name = "Silent Knight Orvan", position = new Vector3(0f, 0f, 177f), yaw = 180f,
                sealedDoorName = "Sealed Door (Sunken Altar)", theatreName = "Echo Theatre (Orvan)",
                bossName = "沈黙の騎士　オルヴァン", awakenLine = "……水の底に、誰かいる。……オルヴァン。修道院の、鐘守り。", maxHealth = 11f,
            });

            // ---------------- G behind the sealed door
            L.Floor("Floor G", new Vector3(0f, 0f, 191.2f), 7.4f, 9f, 2600);
            L.Wall("G West", new Vector3(-4.3f, 0f, 191.4f), 90f, 9.4f, 8f, 2601, 1.2f);
            L.Wall("G East", new Vector3(4.3f, 0f, 191.4f), 90f, 9.4f, 8f, 2602, 1.2f);
            L.Wall("G End", new Vector3(0f, 0f, 196.3f), 0f, 9.8f, 8f, 2603, 1.2f);
            L.hasGoal = true;
            L.goalCenter = new Vector3(0f, 2f, 192f);
            L.goalSize = new Vector3(5f, 4f, 4f);
            L.goalTitle = "第二章　沈んだ修道院　―　完";
            L.goalSubtitle = "水の底で、暁鐘の心臓が脈打っている。";
            return L;
        }

        static void Ceiling(EchoStageLayout L, string ceilingName, Vector3 position, float sizeX, float sizeZ, int seed)
        {
            L.Piece(ceilingName, position, 0f, new EchoKitSpec { kind = EchoKitKind.Ceiling, size = new Vector3(sizeX, 0f, sizeZ), pointSpacing = 0.2f, seed = seed });
        }

        static EchoKitSpec Grave(int seed)
        {
            return new EchoKitSpec { kind = EchoKitKind.Gravestone, size = new Vector3(1.1f, 1.6f, 0.25f), pointSpacing = 0.07f, seed = seed };
        }

        static EchoKitSpec Coffin(int seed)
        {
            return new EchoKitSpec { kind = EchoKitKind.Coffin, size = new Vector3(1.3f, 1.1f, 2.6f), pointSpacing = 0.09f, seed = seed };
        }
    }
}
