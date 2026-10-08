using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    public struct EchoEnemyPlacement
    {
        public Vector3 position;
        public float yaw;
        public float wanderRadius;
    }

    /// <summary>A Hollow Armor and the route it walks back and forth (world space).</summary>
    public struct EchoArmorPlacement
    {
        public Vector3 position;
        public float yaw;
        public Vector3[] route;
    }

    /// <summary>A wall with an empty room behind it (sound puzzle). Same sizes as a Wall kit piece.</summary>
    public struct EchoHollowWallPlacement
    {
        public string name;
        public Vector3 position;
        public float yaw;
        public Vector3 size;
        public int seed;
    }

    public struct EchoPuzzleBellPlacement
    {
        public Vector3 position;
        public float yaw;
    }

    /// <summary>
    /// A door that sings a melody; ring the bells in that order to open it. Bell i plays note i.
    /// sequence holds indexes into bells.
    /// </summary>
    public struct EchoBellDoorPlacement
    {
        public string name;
        public Vector3 position;
        public float yaw;
        public float width;
        public float openingHeight;
        public EchoPuzzleBellPlacement[] bells;
        public int[] sequence;
    }

    /// <summary>An echo theatre: a past scene replayed by golden figures (see EchoTheatreScenes).</summary>
    public struct EchoTheatrePlacement
    {
        public string name;
        public Vector3 position;
        public float yaw;
        public string sceneId;
        /// <summary>A bell strike inside this distance starts it (0 = only started by a boss falling).</summary>
        public float triggerRadius;
    }

    /// <summary>The Silent Knight. It opens the named door and plays the named theatre when it falls.</summary>
    public struct EchoBossPlacement
    {
        public string name;
        public Vector3 position;
        public float yaw;
        public string sealedDoorName;
        public string theatreName;
    }

    /// <summary>A zone that shows a line of story and / or an instruction while the knight is inside.</summary>
    public struct EchoHintPlacement
    {
        public string name;
        public Vector3 center;
        public Vector3 size;
        public string speaker;
        public string line;
        public string instruction;
    }

    /// <summary>A memory echo (残響): a kneeling gold figure that speaks when the knight comes close.</summary>
    public struct EchoGhostPlacement
    {
        public string name;
        public Vector3 position;
        public float yaw;
        public string speaker;
        public string line;
    }

    /// <summary>Everything that makes up one stage. Built into a scene by the editor menu.</summary>
    public class EchoStageLayout
    {
        public string name;
        public Vector3 playerSpawn;
        public float playerYaw;
        public readonly List<EchoPiecePlacement> pieces = new List<EchoPiecePlacement>();
        public readonly List<EchoShrinePlacement> shrines = new List<EchoShrinePlacement>();
        public readonly List<EchoEnemyPlacement> listeners = new List<EchoEnemyPlacement>();
        public readonly List<EchoArmorPlacement> armors = new List<EchoArmorPlacement>();
        public readonly List<EchoHollowWallPlacement> hollowWalls = new List<EchoHollowWallPlacement>();
        public readonly List<EchoBellDoorPlacement> bellDoors = new List<EchoBellDoorPlacement>();
        public readonly List<EchoTheatrePlacement> theatres = new List<EchoTheatrePlacement>();
        public readonly List<EchoBossPlacement> bosses = new List<EchoBossPlacement>();
        public readonly List<EchoHintPlacement> hints = new List<EchoHintPlacement>();
        public readonly List<EchoGhostPlacement> ghosts = new List<EchoGhostPlacement>();
        public bool hasGoal;
        public Vector3 goalCenter;
        public Vector3 goalSize;
        public string goalTitle;
        public string goalSubtitle;

        public void Piece(string pieceName, Vector3 position, float yaw, EchoKitSpec spec, bool gold = false)
        {
            pieces.Add(new EchoPiecePlacement { name = pieceName, position = position, yaw = yaw, spec = spec, gold = gold });
        }

        /// <summary>Masonry wall. yaw 0 = runs along X, yaw 90 = runs along Z.</summary>
        public void Wall(string wallName, Vector3 center, float yaw, float width, float height, int seed, float thickness = 1.2f)
        {
            Piece(wallName, center, yaw, new EchoKitSpec { kind = EchoKitKind.Wall, size = new Vector3(width, height, thickness), pointSpacing = 0.15f, seed = seed });
        }

        public void Arch(string wallName, Vector3 center, float yaw, float width, float height, float openingW, float openingH, int seed,
                         float thickness = 1.4f, bool battlements = false)
        {
            Piece(wallName, center, yaw, new EchoKitSpec
            {
                kind = EchoKitKind.ArchWall, size = new Vector3(width, height, thickness), openingWidth = openingW, openingHeight = openingH,
                battlements = battlements, pointSpacing = 0.15f, seed = seed,
            });
        }

        public void Floor(string floorName, Vector3 center, float sizeX, float sizeZ, int seed)
        {
            Piece(floorName, center, 0f, new EchoKitSpec { kind = EchoKitKind.Floor, size = new Vector3(sizeX, 0f, sizeZ), pointSpacing = 0.2f, seed = seed });
        }

        public void Pillar(string pillarName, Vector3 position, float diameter, float height, int seed)
        {
            Piece(pillarName, position, 0f, new EchoKitSpec { kind = EchoKitKind.Pillar, size = new Vector3(diameter, height, 0f), pointSpacing = 0.11f, seed = seed });
        }

        public void Hint(string hintName, Vector3 center, Vector3 size, string speaker, string line, string instruction)
        {
            hints.Add(new EchoHintPlacement { name = hintName, center = center, size = size, speaker = speaker, line = line, instruction = instruction });
        }
    }

    /// <summary>
    /// 序章「崩れた鐘楼」(Prologue: The Fallen Belfry).
    ///
    ///   1 Ruined belfry   - wake up among the shards of the great bell (walk)
    ///   2 Corridor        - rubble, learn to run
    ///   3 Great hall      - too big to see with footsteps: learn the bell strike; a bell keeper's echo;
    ///                       a Hollow Armor walks between the pillars without a sound wave of its own
    ///   4 Cloister        - first shrine; a Listener wanders: learn to stand still and sneak
    ///                       a bricked-up doorway in its west wall answers a bell strike: break it for a hidden echo
    ///   5 Chapel          - second shrine before it; a Listener guards it: learn to fight; the priest's echo;
    ///                       the way out is a singing door - ring three bells in the order it sings
    ///   6 Gate stairs     - reach the great gate: end of the prologue
    /// The path runs roughly north (+Z), from z = 0 to z = 140.
    /// </summary>
    public static class EchoPrologueLayout
    {
        public static EchoStageLayout Build()
        {
            var L = new EchoStageLayout { name = "Prologue - The Fallen Belfry", playerSpawn = new Vector3(0f, 0.05f, -3f), playerYaw = 0f };

            // ---------------- 1 ruined belfry
            L.Piece("Ruined Belfry", Vector3.zero, 0f, new EchoKitSpec
            {
                kind = EchoKitKind.Tower, size = new Vector3(16f, 10f, 0f), ruined = true, door = true, pointSpacing = 0.13f, seed = 101,
            });
            L.Floor("Floor Belfry", Vector3.zero, 17f, 17f, 102);
            L.Piece("Great Bell Shard 1", new Vector3(-4f, 0f, -2f), 30f, new EchoKitSpec { kind = EchoKitKind.BellFragment, size = new Vector3(6f, 4f, 0f), pointSpacing = 0.09f, seed = 103 }, true);
            L.Piece("Great Bell Shard 2", new Vector3(3.6f, 0f, 2.5f), -70f, new EchoKitSpec { kind = EchoKitKind.BellFragment, size = new Vector3(4.5f, 3.2f, 0f), pointSpacing = 0.09f, seed = 104 }, true);
            L.Piece("Rubble Belfry", new Vector3(-3.5f, 0f, 4f), 20f, new EchoKitSpec { kind = EchoKitKind.Rubble, size = new Vector3(2.5f, 1.6f, 2f), pointSpacing = 0.11f, seed = 105 });
            L.Hint("Hint Wake", new Vector3(0f, 3f, -1f), new Vector3(12f, 6f, 10f), "リーネ", "……兄さん。聞こえる？",
                   "W A S D：歩く　―　足音が響くと、まわりが一瞬だけ見える");

            // ---------------- 2 corridor (x -3.5 .. 3.5, z 7 .. 38)
            L.Floor("Floor Corridor", new Vector3(0f, 0f, 22.4f), 7.4f, 31.6f, 201);   // overlaps the hall floor under the arch
            L.Wall("Corridor West", new Vector3(-4.1f, 0f, 21.5f), 90f, 33f, 7f, 202);
            L.Wall("Corridor East", new Vector3(4.1f, 0f, 21.5f), 90f, 33f, 7f, 203);
            L.Piece("Rubble Corridor 1", new Vector3(2f, 0f, 18f), 10f, new EchoKitSpec { kind = EchoKitKind.Rubble, size = new Vector3(3f, 2.2f, 2.4f), pointSpacing = 0.11f, seed = 204 });
            L.Piece("Rubble Corridor 2", new Vector3(-2.2f, 0f, 29f), -15f, new EchoKitSpec { kind = EchoKitKind.Rubble, size = new Vector3(2.6f, 1.8f, 2.2f), pointSpacing = 0.11f, seed = 205 });
            L.Hint("Hint Run", new Vector3(0f, 3f, 13f), new Vector3(7f, 6f, 8f), null, null,
                   "Shift：走る　―　波は遠くまで届くが、足音も大きくなる");

            // ---------------- 3 great hall (x -14 .. 14, z 38 .. 68)
            L.Floor("Floor Hall", new Vector3(0f, 0f, 53f), 28.4f, 30.4f, 301);
            L.Arch("Hall South", new Vector3(0f, 0f, 38f), 0f, 29.4f, 9f, 5f, 7f, 302);
            L.Wall("Hall East", new Vector3(14.2f, 0f, 53f), 90f, 31.4f, 9f, 303, 1.4f);
            // the west wall has a bricked-up doorway (z 50.5 .. 55.5) with a hidden room behind it
            L.Wall("Hall West South", new Vector3(-14.2f, 0f, 43.9f), 90f, 13.2f, 9f, 304, 1.4f);
            L.Wall("Hall West North", new Vector3(-14.2f, 0f, 62.1f), 90f, 13.2f, 9f, 307, 1.4f);
            L.Wall("Hall West Lintel", new Vector3(-14.2f, 4.5f, 53f), 90f, 5f, 4.5f, 308, 1.4f);
            L.hollowWalls.Add(new EchoHollowWallPlacement { name = "Hollow Wall (Hall)", position = new Vector3(-14.2f, 0f, 53f), yaw = 90f, size = new Vector3(5f, 4.5f, 1.4f), seed = 309 });
            // the hidden room (x -21 .. -15, z 50 .. 56): a little girl's echo
            L.Floor("Floor Hidden Room", new Vector3(-17.5f, 0f, 53f), 7.4f, 7.4f, 330);
            L.Wall("Hidden Room West", new Vector3(-21.2f, 0f, 53f), 90f, 7.6f, 5f, 331, 1.2f);
            L.Wall("Hidden Room North", new Vector3(-17.8f, 0f, 56.6f), 0f, 7.6f, 5f, 332, 1.2f);
            L.Wall("Hidden Room South", new Vector3(-17.8f, 0f, 49.4f), 0f, 7.6f, 5f, 333, 1.2f);
            L.ghosts.Add(new EchoGhostPlacement { name = "Echo Young Rine", position = new Vector3(-19.4f, 0f, 53f), yaw = 90f,
                speaker = "幼いリーネの残響", line = "「兄さん、鐘の音って、どうしてこんなに悲しいの？」" });
            L.Wall("Hall North", new Vector3(-6f, 0f, 68f), 0f, 17f, 9f, 305, 1.4f);
            L.Arch("Hall North Gate", new Vector3(8f, 0f, 68f), 0f, 12f, 9f, 5f, 7f, 306);
            for (int i = 0; i < 3; i++)
            {
                L.Pillar("Hall Pillar W" + i, new Vector3(-7f, 0f, 45f + i * 8f), 1.6f, 8f, 310 + i);
                L.Pillar("Hall Pillar E" + i, new Vector3(7f, 0f, 45f + i * 8f), 1.6f, 8f, 320 + i);
            }
            L.Hint("Hint Strike", new Vector3(0f, 4f, 41.5f), new Vector3(28f, 8f, 7f), null, null,
                   "Space：鐘打ち　―　大きな波を出す。波は、この場所に残る記憶も呼び起こす");
            L.theatres.Add(new EchoTheatrePlacement { name = "Echo Theatre (The Offering)", position = new Vector3(0f, 0f, 53f), yaw = 0f,
                sceneId = EchoTheatreScenes.HallRitual, triggerRadius = 16f });
            L.ghosts.Add(new EchoGhostPlacement { name = "Echo Bell Keeper", position = new Vector3(-9.5f, 0f, 63f), yaw = 135f,
                speaker = "鐘守りの残響", line = "「鐘が……割れる……！　アルドレン、どこだ……！」" });
            // the Hollow Armor walks a loop between the pillar rows; the side aisles stay out of its reach
            L.armors.Add(new EchoArmorPlacement
            {
                position = new Vector3(-3.5f, 0f, 47f), yaw = 0f,
                route = new[] { new Vector3(-3.5f, 0f, 47f), new Vector3(-3.5f, 0f, 60f), new Vector3(3.5f, 0f, 60f), new Vector3(3.5f, 0f, 47f) },
            });
            L.Hint("Hint Armor", new Vector3(0f, 4f, 47.5f), new Vector3(28f, 8f, 4f), "リーネ", "……鎧が歩いてる。中には、誰もいないのに。",
                   "抜け殻の鎧は波を出さない　―　金属のきしむ音を聞いて、自分の波で姿を確かめる");
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Hall)", position = new Vector3(11.8f, 0f, 62.5f), yaw = 180f });

            // ---------------- 4 cloister (x 2 .. 26, z 68 .. 100)
            L.Floor("Floor Cloister", new Vector3(14f, 0f, 84f), 24.4f, 32.4f, 401);
            L.Wall("Cloister West", new Vector3(2f, 0f, 84f), 90f, 33f, 8f, 402);
            L.Wall("Cloister East", new Vector3(26f, 0f, 84f), 90f, 33f, 8f, 403);
            L.Wall("Cloister South", new Vector3(20f, 0f, 68f), 0f, 12.4f, 8f, 404);
            L.Arch("Cloister North Gate", new Vector3(14f, 0f, 100f), 0f, 24.4f, 8f, 5f, 6.5f, 405);
            L.Pillar("Cloister Pillar 1", new Vector3(8f, 0f, 76f), 1.4f, 7f, 410);
            L.Pillar("Cloister Pillar 2", new Vector3(20f, 0f, 76f), 1.4f, 7f, 411);
            L.Pillar("Cloister Pillar 3", new Vector3(8f, 0f, 92f), 1.4f, 7f, 412);
            L.Pillar("Cloister Pillar 4", new Vector3(20f, 0f, 92f), 1.4f, 7f, 413);
            L.Wall("Cloister Low Wall 1", new Vector3(14f, 0f, 84f), 0f, 7f, 2.4f, 414, 1f);
            L.Wall("Cloister Low Wall 2", new Vector3(8.5f, 0f, 84f), 90f, 4f, 2.4f, 415, 1f);
            L.Piece("Cloister Barrel 1", new Vector3(22f, 0f, 72f), 0f, new EchoKitSpec { kind = EchoKitKind.Barrel, size = new Vector3(1.3f, 1.8f, 0f), pointSpacing = 0.08f, seed = 416 });
            L.Piece("Cloister Barrel 2", new Vector3(23.3f, 0f, 73.2f), 50f, new EchoKitSpec { kind = EchoKitKind.Barrel, size = new Vector3(1.2f, 1.6f, 0f), pointSpacing = 0.08f, seed = 417 });
            L.Piece("Cloister Crate 1", new Vector3(5f, 0f, 96f), 15f, new EchoKitSpec { kind = EchoKitKind.Crate, size = new Vector3(1.6f, 1.6f, 1.6f), pointSpacing = 0.09f, seed = 418 });
            L.Piece("Cloister Crate 2", new Vector3(6.8f, 0f, 96.8f), -10f, new EchoKitSpec { kind = EchoKitKind.Crate, size = new Vector3(1.3f, 1.3f, 1.3f), pointSpacing = 0.09f, seed = 419 });
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(14f, 0f, 90f), yaw = 180f, wanderRadius = 7f });
            L.Hint("Hint Listener", new Vector3(8f, 3f, 71.5f), new Vector3(10f, 6f, 6f), "リーネ", "……何かいる。目の見えない、音だけを聞くもの。",
                   "聴き手は音でしか追ってこない。立ち止まれば見つからない　―　R：石を投げる（落ちた所で音がして、聴き手はそこへ向かう）");
            L.shrines.Add(new EchoShrinePlacement { name = "Bell Shrine (Cloister)", position = new Vector3(22.5f, 0f, 95.5f), yaw = 180f });

            // ---------------- 5 chapel (x 4 .. 24, z 100 .. 124)
            L.Floor("Floor Chapel", new Vector3(14f, 0f, 112f), 20.4f, 24.4f, 501);
            L.Wall("Chapel West", new Vector3(4f, 0f, 112f), 90f, 25f, 8f, 502);
            L.Wall("Chapel East", new Vector3(24f, 0f, 112f), 90f, 25f, 8f, 503);
            L.Arch("Chapel North Gate", new Vector3(14f, 0f, 124f), 0f, 20.4f, 8f, 5f, 6.5f, 504);
            // the altar stands against the west wall, leaving the aisle to the north gate free
            L.Piece("Chapel Altar", new Vector3(6.6f, 0f, 112f), 90f, new EchoKitSpec { kind = EchoKitKind.Platform, size = new Vector3(7f, 1.2f, 2.6f), pointSpacing = 0.1f, seed = 505 });
            L.Pillar("Chapel Pillar 1", new Vector3(10f, 0f, 104.5f), 1.4f, 7f, 510);
            L.Pillar("Chapel Pillar 2", new Vector3(18f, 0f, 104.5f), 1.4f, 7f, 511);
            L.Pillar("Chapel Pillar 3", new Vector3(10f, 0f, 119.5f), 1.4f, 7f, 512);
            L.Pillar("Chapel Pillar 4", new Vector3(18f, 0f, 119.5f), 1.4f, 7f, 513);
            L.listeners.Add(new EchoEnemyPlacement { position = new Vector3(14f, 0f, 112f), yaw = 180f, wanderRadius = 3.5f });
            L.Hint("Hint Fight", new Vector3(14f, 3f, 103f), new Vector3(16f, 6f, 5f), null, "左クリック：斬る　E：強く斬る　Q：パリィ",
                   "聴き手の叫びは赤い輪になって広がり、触れると死ぬ　―　輪が届く瞬間に Q（パリィ）で跳ね返す。柱の陰なら届かない");
            // the north gate is shut by a singing door: three bells answer it
            L.bellDoors.Add(new EchoBellDoorPlacement
            {
                name = "Bell Door (Chapel)", position = new Vector3(14f, 0f, 124f), yaw = 0f, width = 5f, openingHeight = 6.5f,
                bells = new[]
                {
                    new EchoPuzzleBellPlacement { position = new Vector3(21.6f, 0f, 107f), yaw = -90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(21.6f, 0f, 117f), yaw = -90f },
                    new EchoPuzzleBellPlacement { position = new Vector3(6.4f, 0f, 120.5f), yaw = 90f },
                },
                sequence = new[] { 1, 2, 0 },
            });
            L.Hint("Hint Bell Door", new Vector3(14f, 3f, 120.5f), new Vector3(8f, 6f, 5f), "リーネ", "……扉が歌ってる。鐘の声を、同じ順に返して。",
                   "扉に近づくと、鐘が順に鳴る　―　音がした方向を覚えて、同じ順番で鐘を鳴らす");
            L.ghosts.Add(new EchoGhostPlacement { name = "Echo Priest", position = new Vector3(9.6f, 0f, 112f), yaw = -90f,
                speaker = "司祭の残響", line = "「今年、暁鐘に捧げる声は ― リーネ」" });

            // ---------------- 6 stairs to the great gate (x 9 .. 19, z 124 .. 140)
            L.Floor("Floor Gate", new Vector3(14f, 0f, 132f), 10.4f, 16.4f, 601);
            L.Wall("Gate West", new Vector3(9f, 0f, 132f), 90f, 17f, 12f, 602);
            L.Wall("Gate East", new Vector3(19f, 0f, 132f), 90f, 17f, 12f, 603);
            L.Piece("Gate Stairs", new Vector3(14f, 0f, 128f), 0f, new EchoKitSpec { kind = EchoKitKind.Stairs, size = new Vector3(6f, 2.4f, 5f), steps = 8, pointSpacing = 0.11f, seed = 604 });
            L.Piece("Gate Landing", new Vector3(14f, 0f, 135.25f), 0f, new EchoKitSpec { kind = EchoKitKind.Platform, size = new Vector3(10f, 2.4f, 9.5f), pointSpacing = 0.13f, seed = 605 });
            L.Arch("Great Gate", new Vector3(14f, 2.4f, 140.5f), 0f, 10.4f, 10f, 6f, 8.5f, 606, 1.6f, true);
            L.hasGoal = true;
            L.goalCenter = new Vector3(14f, 4.4f, 137.5f);
            L.goalSize = new Vector3(6f, 5f, 4f);
            L.goalTitle = "序章　崩れた鐘楼　―　完";
            L.goalSubtitle = "門の向こうに、灰の城下町が眠っている。";
            return L;
        }
    }

    /// <summary>
    /// The title screen: the knight stands among the shards of the great bell, broken pillars and
    /// an arch behind him. Only pieces; the title scene has no enemies or goal.
    /// </summary>
    public static class EchoTitleLayout
    {
        public static readonly Vector3 CameraPosition = new Vector3(0f, 3.2f, 16f);
        public static readonly Vector3 CameraTarget = new Vector3(0f, 2.1f, -1f);

        public static EchoStageLayout Build()
        {
            var L = new EchoStageLayout { name = "Title", playerSpawn = new Vector3(0f, 0f, 0f), playerYaw = 0f };
            L.Floor("Floor Title", new Vector3(0f, 0f, -2f), 30f, 26f, 9001);
            L.Arch("Title Arch", new Vector3(0f, 0f, -12f), 0f, 18f, 11f, 5f, 7.5f, 9002, 1.4f, true);
            L.Pillar("Title Pillar 1", new Vector3(-7.5f, 0f, -4f), 1.5f, 7f, 9003);
            L.Pillar("Title Pillar 2", new Vector3(7.5f, 0f, -4f), 1.5f, 5.5f, 9004);
            L.Pillar("Title Pillar 3", new Vector3(-4.5f, 0f, -8.5f), 1.5f, 8.5f, 9005);
            L.Pillar("Title Pillar 4", new Vector3(4.5f, 0f, -8.5f), 1.5f, 6.5f, 9006);
            L.Piece("Title Bell Shard 1", new Vector3(-3.8f, 0f, -2.5f), 40f, new EchoKitSpec { kind = EchoKitKind.BellFragment, size = new Vector3(6f, 4f, 0f), pointSpacing = 0.09f, seed = 9007 }, true);
            L.Piece("Title Bell Shard 2", new Vector3(4.2f, 0f, -1.5f), -60f, new EchoKitSpec { kind = EchoKitKind.BellFragment, size = new Vector3(4.5f, 3.2f, 0f), pointSpacing = 0.09f, seed = 9008 }, true);
            L.Piece("Title Rubble 1", new Vector3(-6.5f, 0f, 1.5f), 25f, new EchoKitSpec { kind = EchoKitKind.Rubble, size = new Vector3(2.6f, 1.4f, 2.2f), pointSpacing = 0.11f, seed = 9009 });
            L.Piece("Title Rubble 2", new Vector3(6.8f, 0f, 2.5f), -15f, new EchoKitSpec { kind = EchoKitKind.Rubble, size = new Vector3(2.2f, 1.2f, 2f), pointSpacing = 0.11f, seed = 9010 });
            return L;
        }
    }

    /// <summary>The original test courtyard as a stage layout.</summary>
    public static class EchoPrototypeStage
    {
        public static EchoStageLayout Build()
        {
            var L = new EchoStageLayout { name = "Prototype Courtyard", playerSpawn = EchoPrototypeLayout.PlayerSpawn, playerYaw = 0f };
            L.pieces.AddRange(EchoPrototypeLayout.Pieces());
            L.shrines.AddRange(EchoPrototypeLayout.Shrines());
            L.listeners.Add(new EchoEnemyPlacement { position = EchoPrototypeLayout.ListenerSpawn, yaw = 180f, wanderRadius = 9f });
            return L;
        }
    }

    /// <summary>A kneeling figure in a hooded robe (memory echoes). Local space, facing +Z, about 3 units tall.</summary>
    public static class EchoGhostBody
    {
        public static void Build(EchoPointBuilder b)
        {
            b.spacing = 0.07f;
            // robe over the kneeling body: torso tube flaring into the robe on the floor
            b.Tube(new Vector3(0f, 0.05f, -0.15f), new Vector3(0f, 0.9f, -0.1f), new Vector3(0f, 1.8f, 0.05f), new Vector3(0f, 2.45f, 0.15f),
                   t => Mathf.Lerp(0.95f, 0.38f, Mathf.Pow(t, 0.7f)), 0.85f, 7, 0.05f);
            // head bowed inside a hood
            b.Ellipsoid(new Vector3(0f, 2.75f, 0.3f), new Vector3(0.3f, 0.34f, 0.34f), Quaternion.Euler(30f, 0f, 0f), 0.9f);
            // knees showing under the robe at the front
            for (int side = -1; side <= 1; side += 2)
                b.Ellipsoid(new Vector3(side * 0.3f, 0.32f, 0.75f), new Vector3(0.24f, 0.22f, 0.4f), Quaternion.identity, 0.8f);
            // arms raised, hands clasped in prayer in front of the chest
            Vector3 hands = new Vector3(0f, 2.0f, 0.75f);
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 shoulder = new Vector3(side * 0.42f, 2.3f, 0.15f);
                b.Tube(shoulder, shoulder + new Vector3(side * 0.05f, -0.35f, 0.15f), hands + new Vector3(side * 0.18f, -0.15f, -0.1f), hands + new Vector3(side * 0.04f, 0f, 0f),
                       t => Mathf.Lerp(0.15f, 0.08f, t), 0.8f);
            }
            b.Ellipsoid(hands + Vector3.up * 0.08f, new Vector3(0.1f, 0.16f, 0.08f), Quaternion.identity, 1f);
        }
    }
}
