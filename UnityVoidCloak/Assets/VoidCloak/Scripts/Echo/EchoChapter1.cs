using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// 第一章「灰の城下町」(Chapter 1: The Ash Town).
    ///
    ///   A Gate street      - through the collapsed town gate into streets of burnt houses
    ///   B Main street      - two Listeners; burnt-out houses to hide in; a boy's echo
    ///   C Market square    - wide open: stalls, a well, a Hollow Armor walking round it, a Listener;
    ///                        a hollow wall in the west row hides a courtyard (the mother's echo)
    ///   D Narrow alley     - tall houses, a Hollow Armor walking up and down; ruins to step into
    ///   E Cathedral square - a Listener guards four bells; the cathedral door sings their order
    ///   F Under the door   - stairs down into the dark
    ///   G The crypt hall   - the Silent Knight Gareth. Four pillars to hide behind from his rings.
    ///                        When he falls, the sealed door opens and his memory plays: Aldren broke the bell.
    /// The path runs north (+Z) from z = 0 to z = 289.
    /// </summary>
    public static class EchoChapter1Layout
    {
        public static EchoStageLayout Build()
        {
            var L = new EchoStageLayout { name = "Chapter 1 - The Ash Town", playerSpawn = new Vector3(0f, 0.05f, 3f), playerYaw = 0f };

            // ---------------- A gate street (x -6 .. 6, z 0 .. 44)
            L.Wall("Collapsed Town Gate", new Vector3(0f, 0f, -1.2f), 0f, 14f, 12f, 1001, 1.4f);
            L.Piece("Rubble Gate", new Vector3(-2.5f, 0f, 0.9f), 15f, Rubble(3.4f, 2.2f, 2.4f, 1002));
            L.Floor("Floor A", new Vector3(0f, 0f, 22f), 12.4f, 45f, 1003);
            HouseRow(L, "A West", new Vector3(-6f, 0f, 0f), 90f, 7f, new[] { 10f, 12f, 9f, 13f }, new[] { 9f, 11f, 8f, 10f }, 1010, 2);
            HouseRow(L, "A East", new Vector3(6f, 0f, 0f), -90f, 7f, new[] { 12f, 8f, 13f, 11f }, new[] { 10f, 8f, 12f, 9f }, 1020, -1);
            L.Piece("Rubble A", new Vector3(2.2f, 0f, 15f), -20f, Rubble(3f, 1.6f, 2.4f, 1030));
            L.Piece("Barrel A1", new Vector3(-4.8f, 0f, 36f), 0f, Barrel(1.2f, 1.7f, 1031));
            L.Piece("Crate A1", new Vector3(4.6f, 0f, 30f), 20f, Crate(1.5f, 1032));
            L.Hint("Hint Town", new Vector3(0f, 3f, 7f), new Vector3(12f, 6f, 10f), "リーネ", "……ここが、城下町。みんな、灰になってしまった。", null);

            // ---------------- B main street (x -7 .. 7, z 44 .. 104)
            L.Floor("Floor B", new Vector3(0f, 0f, 74f), 14.4f, 60.4f, 1100);
            HouseRow(L, "B West", new Vector3(-7f, 0f, 44f), 90f, 8f, new[] { 12f, 10f, 14f, 11f, 13f }, new[] { 10f, 12f, 9f, 11f, 10f }, 1110, 1);
            HouseRow(L, "B East", new Vector3(7f, 0f, 44f), -90f, 8f, new[] { 9f, 13f, 12f, 10f, 16f }, new[] { 11f, 9f, 12f, 10f, 8f }, 1120, 3);
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Main Street)", position = new Vector3(-5f, 0f, 47.5f), yaw = 90f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(-1f, 0f, 63f), yaw = 180f, wanderRadius = 5f });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(2f, 0f, 92f), yaw = 180f, wanderRadius = 5f });
            L.ghosts.Add(new EchoGhostPlacement { name = "Echo Boy", position = new Vector3(5f, 0f, 71f), yaw = -90f,
                speaker = "少年の残響", line = "「母さん、鐘が鳴らないよ。……夜が、終わらないよ」" });
            L.Piece("Barrel B1", new Vector3(5.6f, 0f, 53f), 0f, Barrel(1.2f, 1.7f, 1130));
            L.Piece("Barrel B2", new Vector3(5.4f, 0f, 54.6f), 0f, Barrel(1.1f, 1.5f, 1131));
            L.Piece("Crate B1", new Vector3(-5.6f, 0f, 81f), 10f, Crate(1.4f, 1132));
            L.Piece("Rubble B", new Vector3(-3f, 0f, 99f), 30f, Rubble(3f, 1.5f, 2.4f, 1133));

            // ---------------- C market square (x -22 .. 22, z 104 .. 148)
            L.Floor("Floor C", new Vector3(0f, 0f, 126f), 44.4f, 44.4f, 1200);
            // the square's south corners, beside the end of the main street
            HouseRow(L, "C South West", new Vector3(-22f, 0f, 104f), 0f, 8f, new[] { 7f }, new[] { 10f }, 1210, -1);
            HouseRow(L, "C South East", new Vector3(15f, 0f, 104f), 0f, 8f, new[] { 7f }, new[] { 11f }, 1215, -1);
            // west row with a gap at z 118 .. 123 closed by a hollow wall
            HouseRow(L, "C West 1", new Vector3(-22f, 0f, 96f), 90f, 8f, new[] { 12f, 10f }, new[] { 10f, 12f }, 1220, -1, true);
            HouseRow(L, "C West 2", new Vector3(-22f, 0f, 123f), 90f, 8f, new[] { 11f, 14f }, new[] { 11f, 9f }, 1225, -1, true);
            L.hollowWalls.Add(new EchoHollowWallPlacement { name = "Hollow Wall (Market)", position = new Vector3(-22.6f, 0f, 120.5f), yaw = 90f, size = new Vector3(5f, 5f, 1.2f), seed = 1230 });
            L.Wall("Market Gap Lintel", new Vector3(-22.6f, 5f, 120.5f), 90f, 5f, 5f, 1231, 1.2f);
            HouseRow(L, "C East", new Vector3(22f, 0f, 96f), -90f, 8f, new[] { 14f, 12f, 14f, 12f }, new[] { 10f, 12f, 9f, 11f }, 1240, 2);
            // north row with the alley entrance at x -3.5 .. 3.5
            HouseRow(L, "C North West", new Vector3(-3.5f, 0f, 148f), 180f, 8f, new[] { 8f, 10f, 8.5f }, new[] { 11f, 9f, 12f }, 1250, -1);
            HouseRow(L, "C North East", new Vector3(30f, 0f, 148f), 180f, 8f, new[] { 9f, 9.5f, 8f }, new[] { 10f, 12f, 9f }, 1255, -1);
            L.Piece("Market Well", new Vector3(0f, 0f, 126f), 0f, new EchoKitSpec { kind = EchoKitKind.Well, size = new Vector3(3.4f, 1.1f, 0f), pointSpacing = 0.09f, seed = 1260 });
            L.theatres.Add(new EchoTheatrePlacement { name = "Echo Theatre (The Night The Bell Stopped)", position = new Vector3(0f, 0f, 126f), yaw = 0f,
                sceneId = EchoTheatreScenes.MarketNight, triggerRadius = 14f });
            Stall(L, "Stall 1", new Vector3(-12f, 0f, 110f), 0f, 1261);
            Stall(L, "Stall 2", new Vector3(12f, 0f, 110f), 0f, 1262);
            Stall(L, "Stall 3", new Vector3(-17f, 0f, 128f), 90f, 1263);
            Stall(L, "Stall 4", new Vector3(-17f, 0f, 138f), 90f, 1264);
            Stall(L, "Stall 5", new Vector3(17f, 0f, 124f), -90f, 1265);
            Stall(L, "Stall 6", new Vector3(17f, 0f, 136f), -90f, 1266);
            L.Piece("Crate C1", new Vector3(-9.6f, 0f, 109.2f), 15f, Crate(1.3f, 1270));
            L.Piece("Barrel C1", new Vector3(14.6f, 0f, 109f), 0f, Barrel(1.1f, 1.6f, 1271));
            L.armors.Add(new EchoArmorPlacement
            {
                position = new Vector3(-8f, 0f, 116f), yaw = 90f,
                route = new[] { new Vector3(-8f, 0f, 116f), new Vector3(8f, 0f, 116f), new Vector3(8f, 0f, 138f), new Vector3(-8f, 0f, 138f) },
            });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(13f, 0f, 142f), yaw = 180f, wanderRadius = 4f });
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Market)", position = new Vector3(-18.5f, 0f, 106.5f), yaw = 0f });
            L.ghosts.Add(new EchoGhostPlacement { name = "Echo Merchant", position = new Vector3(-13.5f, 0f, 133f), yaw = 90f,
                speaker = "商人の残響", line = "「……あの夜、鐘守りの若者が、剣を抜いて鐘楼へ走っていった」" });
            L.Hint("Hint Market", new Vector3(0f, 3f, 107f), new Vector3(14f, 6f, 5f), "リーネ", "……広い。音が、遠くまで逃げていく。", null);

            // the hidden courtyard behind the hollow wall: a passage between two houses, then a yard
            L.Floor("Floor Market Passage", new Vector3(-26.1f, 0f, 120.5f), 8.4f, 5.2f, 1280);
            L.Floor("Floor Hidden Yard", new Vector3(-34.5f, 0f, 120.5f), 8.6f, 13.4f, 1281);
            L.Wall("Hidden Yard West", new Vector3(-39.2f, 0f, 120.5f), 90f, 14.6f, 6f, 1282, 1.2f);
            L.Wall("Hidden Yard North", new Vector3(-34.6f, 0f, 127.6f), 0f, 10f, 6f, 1283, 1.2f);
            L.Wall("Hidden Yard South", new Vector3(-34.6f, 0f, 113.4f), 0f, 10f, 6f, 1284, 1.2f);
            L.ghosts.Add(new EchoGhostPlacement { name = "Echo Mother", position = new Vector3(-36.5f, 0f, 120.5f), yaw = 90f,
                speaker = "鐘守りの母の残響", line = "「リーネが、選ばれた……。アルドレン、お願い。あの子を守って」", memoryId = 2 });

            // ---------------- D narrow alley (x -3.5 .. 3.5, z 148 .. 196)
            L.Floor("Floor D", new Vector3(0f, 0f, 172f), 7.4f, 48.4f, 1300);
            HouseRow(L, "D West", new Vector3(-3.5f, 0f, 156f), 90f, 10.5f, new[] { 10f, 9f, 11f, 10f }, new[] { 13f, 12f, 14f, 12f }, 1310, 1);
            HouseRow(L, "D East", new Vector3(3.5f, 0f, 156f), -90f, 10.5f, new[] { 12f, 9f, 10f, 9f }, new[] { 12f, 14f, 12f, 13f }, 1320, 2);
            L.armors.Add(new EchoArmorPlacement
            {
                position = new Vector3(0f, 0f, 160f), yaw = 0f,
                route = new[] { new Vector3(0f, 0f, 160f), new Vector3(0f, 0f, 192f) },
            });
            L.Piece("Barrel D1", new Vector3(2.5f, 0f, 170f), 0f, Barrel(1.1f, 1.6f, 1330));
            L.Piece("Crate D1", new Vector3(-2.4f, 0f, 184f), -10f, Crate(1.3f, 1331));
            L.Hint("Hint Alley", new Vector3(0f, 3f, 152f), new Vector3(7f, 6f, 6f), "リーネ", "……狭い。足音が、壁に跳ね返ってる。", null);

            // ---------------- E cathedral square (x -14 .. 14, z 196 .. 236)
            L.Floor("Floor E", new Vector3(0f, 0f, 216.8f), 28.4f, 41.6f, 1400);
            HouseRow(L, "E West", new Vector3(-14f, 0f, 196f), 90f, 8f, new[] { 10f, 14f, 16f }, new[] { 12f, 10f, 13f }, 1410, -1);
            HouseRow(L, "E East", new Vector3(14f, 0f, 196f), -90f, 8f, new[] { 13f, 12f, 15f }, new[] { 11f, 13f, 10f }, 1420, -1);
            L.Arch("Cathedral Front", new Vector3(0f, 0f, 236.7f), 0f, 29f, 18f, 6f, 9f, 1430, 1.4f, true);
            L.Piece("Cathedral Tower West", new Vector3(-10.5f, 0f, 241f), 0f, new EchoKitSpec { kind = EchoKitKind.Tower, size = new Vector3(7f, 20f, 0f), roofHeight = 9f, door = false, pointSpacing = 0.16f, seed = 1431 });
            L.Piece("Cathedral Tower East", new Vector3(10.5f, 0f, 241f), 0f, new EchoKitSpec { kind = EchoKitKind.Tower, size = new Vector3(7f, 20f, 0f), roofHeight = 9f, door = false, pointSpacing = 0.16f, seed = 1432 });
            L.bellDoors.Add(new EchoBellDoorPlacement
            {
                name = "Bell Door (Cathedral)", position = new Vector3(0f, 0f, 236.7f), yaw = 0f, width = 6f, openingHeight = 9f,
                bells = new[]
                {
                    new EchoPuzzleBellPlacement { position = new Vector3(-11.5f, 0f, 203f), yaw = 90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(11.5f, 0f, 208f), yaw = -90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(-11.5f, 0f, 224f), yaw = 90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(11.5f, 0f, 229f), yaw = -90f },
                },
                sequence = new[] { 2, 0, 3, 1 },
            });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(0f, 0f, 216f), yaw = 180f, wanderRadius = 6f });
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Cathedral)", position = new Vector3(11f, 0f, 199f), yaw = -90f });
            L.ghosts.Add(new EchoGhostPlacement { name = "Echo Bell Keeper 2", position = new Vector3(6.5f, 0f, 232f), yaw = 180f,
                speaker = "鐘守りの残響", line = "「割れた暁鐘の心臓は、大聖堂の下へ沈んだ……」" });
            L.Hint("Hint Cathedral", new Vector3(0f, 3f, 231.5f), new Vector3(10f, 6f, 5f), "リーネ", "……大聖堂の扉。鐘が、四つ。", null);

            // ---------------- F stairs down under the cathedral (x -3.5 .. 3.5, z 237 .. 253)
            L.Piece("Crypt Stairs", new Vector3(0f, -3f, 241.5f), 180f, new EchoKitSpec { kind = EchoKitKind.Stairs, size = new Vector3(6f, 3f, 8f), steps = 10, pointSpacing = 0.11f, seed = 1500 });
            L.Piece("Crypt Landing", new Vector3(0f, -3f, 249f), 0f, new EchoKitSpec { kind = EchoKitKind.Floor, size = new Vector3(6.4f, 0f, 7.6f), pointSpacing = 0.2f, seed = 1501 });
            L.Wall("Crypt West", new Vector3(-3.7f, -3f, 245.4f), 90f, 16f, 15f, 1502, 1.2f);
            L.Wall("Crypt East", new Vector3(3.7f, -3f, 245.4f), 90f, 16f, 15f, 1503, 1.2f);

            // ---------------- G the crypt hall: the Silent Knight (x -13 .. 13, z 253 .. 280, floor at y = -3)
            L.Floor("Floor Crypt Hall", new Vector3(0f, -3f, 266.7f), 26.4f, 28.6f, 1600);   // z 252.4 .. 281: under both doorways
            L.Wall("Crypt Hall West", new Vector3(-13.8f, -3f, 266.4f), 90f, 28.2f, 12f, 1601, 1.2f);
            L.Wall("Crypt Hall East", new Vector3(13.8f, -3f, 266.4f), 90f, 28.2f, 12f, 1602, 1.2f);
            L.Wall("Crypt Hall South West", new Vector3(-8.45f, -3f, 252.6f), 0f, 9.5f, 12f, 1603, 1.2f);
            L.Wall("Crypt Hall South East", new Vector3(8.45f, -3f, 252.6f), 0f, 9.5f, 12f, 1604, 1.2f);
            L.Arch("Crypt Hall North", new Vector3(0f, -3f, 280.4f), 0f, 28.8f, 12f, 5f, 6.5f, 1605);
            for (int i = 0; i < 4; i++)
            {
                float px = i % 2 == 0 ? -6.5f : 6.5f, pz = i < 2 ? 259f : 273f;
                L.Pillar("Crypt Hall Pillar " + (i + 1), new Vector3(px, -3f, pz), 1.8f, 8f, 1610 + i);
            }
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Crypt)", position = new Vector3(-10.5f, -3f, 256f), yaw = 90f });
            L.bellDoors.Add(new EchoBellDoorPlacement
            {
                name = "Sealed Door (Crypt)", position = new Vector3(0f, -3f, 280.4f), yaw = 0f, width = 5f, openingHeight = 6.5f,
                bells = new EchoPuzzleBellPlacement[0], sequence = new int[0],
            });
            L.theatres.Add(new EchoTheatrePlacement { name = "Echo Theatre (Gareth)", position = new Vector3(0f, -3f, 266f), yaw = 0f,
                sceneId = EchoTheatreScenes.GarethMemory, triggerRadius = 0f });
            L.bosses.Add(new EchoBossPlacement { name = "Silent Knight Gareth", position = new Vector3(0f, -3f, 272f), yaw = 180f,
                sealedDoorName = "Sealed Door (Crypt)", theatreName = "Echo Theatre (Gareth)" });

            // ---------------- H the way on, behind the sealed door
            L.Floor("Floor Crypt Exit", new Vector3(0f, -3f, 284.8f), 7.4f, 8.2f, 1620);
            L.Wall("Crypt Exit West", new Vector3(-4.3f, -3f, 285.2f), 90f, 9.2f, 10f, 1621, 1.2f);
            L.Wall("Crypt Exit East", new Vector3(4.3f, -3f, 285.2f), 90f, 9.2f, 10f, 1622, 1.2f);
            L.Wall("Crypt Exit End", new Vector3(0f, -3f, 289.5f), 0f, 9.8f, 10f, 1623, 1.2f);
            L.hasGoal = true;
            L.goalCenter = new Vector3(0f, -1f, 286f);
            L.goalSize = new Vector3(5f, 4f, 4f);
            L.goalTitle = "第一章　灰の城下町　―　完";
            L.goalSubtitle = "大聖堂の下から、沈んだ鐘の音が聞こえる。";
            return L;
        }

        /// <summary>
        /// A row of houses along a street. edgeStart = where the row starts on the street edge;
        /// yaw = which way the fronts face (90 = +X, -90 = -X, 0 = +Z, 180 = -Z). The row runs along +Z
        /// for fronts facing ±X, along +X for 0 and along -X for 180.
        /// ruinedIndex = which house is burnt out and can be entered (-1 = none).
        /// backVisible = also build the back wall and back roof slope (only where a place behind the row can be reached).
        /// </summary>
        static void HouseRow(EchoStageLayout L, string rowName, Vector3 edgeStart, float yaw, float depth, float[] widths, float[] heights,
                             int seed, int ruinedIndex, bool backVisible = false)
        {
            Quaternion q = Quaternion.Euler(0f, yaw, 0f);
            Vector3 front = q * Vector3.forward;
            Vector3 along = Mathf.Abs(front.x) > 0.5f ? Vector3.forward : (front.z > 0f ? Vector3.right : Vector3.left);
            float at = 0f;
            for (int i = 0; i < widths.Length; i++)
            {
                float w = widths[i];
                Vector3 centre = edgeStart + along * (at + w * 0.5f) - front * (depth * 0.5f);
                bool ruined = i == ruinedIndex;
                L.Piece(rowName + " " + (i + 1) + (ruined ? " (ruined)" : ""), centre, yaw, new EchoKitSpec
                {
                    kind = EchoKitKind.House, size = new Vector3(w, heights[i], depth), roofHeight = Mathf.Min(depth * 0.6f, 5f),
                    door = true, ruined = ruined, frontOnly = !backVisible, pointSpacing = 0.18f, seed = seed + i,
                });
                at += w;
            }
        }

        static void Stall(EchoStageLayout L, string stallName, Vector3 position, float yaw, int seed)
        {
            L.Piece(stallName, position, yaw, new EchoKitSpec { kind = EchoKitKind.Stall, size = new Vector3(4f, 3.4f, 2.6f), pointSpacing = 0.1f, seed = seed });
        }

        static EchoKitSpec Rubble(float x, float y, float z, int seed)
        {
            return new EchoKitSpec { kind = EchoKitKind.Rubble, size = new Vector3(x, y, z), pointSpacing = 0.11f, seed = seed };
        }

        static EchoKitSpec Barrel(float diameter, float height, int seed)
        {
            return new EchoKitSpec { kind = EchoKitKind.Barrel, size = new Vector3(diameter, height, 0f), pointSpacing = 0.08f, seed = seed };
        }

        static EchoKitSpec Crate(float size, int seed)
        {
            return new EchoKitSpec { kind = EchoKitKind.Crate, size = new Vector3(size, size, size), pointSpacing = 0.09f, seed = seed };
        }
    }
}
