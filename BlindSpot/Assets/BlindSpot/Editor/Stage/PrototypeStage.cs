using UnityEngine;

namespace BlindSpot.EditorTools
{
    /// <summary>
    /// テスト部屋のレイアウト。座標を直したら、メニューを押し直すだけで反映される。
    /// </summary>
    public static class PrototypeStage
    {
        public const string ScenePath = "Assets/BlindSpot/Scenes/Prototype.unity";

        public static StageLayout Build()
        {
            var layout = new StageLayout("Graybox_Room");
            const float height = 3f; // 天井の高さ

            // 20m 四方の部屋
            layout.Room("Room", 0f, 0f, 20f, 20f, height);

            // 素材の違う床
            layout.Patch("Surface_Carpet", -6f, 5f, 5f, 5f, SurfaceType.Carpet);
            layout.Patch("Surface_Glass", 6f, 5f, 4f, 4f, SurfaceType.Glass);
            layout.Patch("Surface_Water", 6f, -3f, 4f, 3f, SurfaceType.Water);
            layout.Patch("Surface_Metal", -6f, -3f, 3f, 6f, SurfaceType.Metal);

            // 障害物
            layout.Pillar("Pillar_1", -2f, 2f, 1f, height);
            layout.Pillar("Pillar_2", 2f, -2f, 1f, height);
            layout.Crate("Crate_1", 0f, 6f, new Vector3(2f, 1f, 1f));
            layout.Crate("Crate_2", 3f, 8f, new Vector3(1.2f, 1.2f, 1.2f));
            layout.Crate("Shelf", -8.5f, 0f, new Vector3(1f, 2f, 3f));

            // しゃがまないと通れない低い通路 (天板の下 1.2m)
            layout.LowPassage("LowPassage", 0f, -6f, 3f, 2f, 1.2f, height);

            // 隠れる場所: ロッカー2つ (背中を壁につけて置く) と机1つ
            layout.Locker("Locker_1", -9.65f, 4.5f, 90f);  // 西の壁ぎわ、扉は東向き
            layout.Locker("Locker_2", 9.65f, -6.5f, -90f); // 東の壁ぎわ、扉は西向き (怪物の巡回ルートの近く)
            layout.Desk("Desk_1", 4.5f, 1.5f, 0f);

            // 投げる物: スタート地点の近くに少し、部屋のあちこちに少し
            layout.Item(ThrowableType.Stone, 1.5f, -8.5f);
            layout.Item(ThrowableType.Stone, -1.5f, -8.2f);
            layout.Item(ThrowableType.Bottle, 4.5f, -8f);
            layout.Item(ThrowableType.Can, -4.5f, -8.5f);
            layout.Item(ThrowableType.Stone, 8f, 2f);
            layout.Item(ThrowableType.Bottle, -3f, 6.5f);
            layout.Item(ThrowableType.Can, 2f, 4f);

            // 怪物: 部屋の奥から出発し、部屋の中ほどを時計回りに巡回する
            // (南側はプレイヤーの出発点から 4.5m 離す。歩くと聞こえるが、しゃがめば聞こえない距離)
            layout.Monster(new Vector3(7.5f, 0f, 8f),
                new Vector3(7.5f, 0f, 8f),
                new Vector3(7.5f, 0f, -4f),
                new Vector3(-6.5f, 0f, -4f),
                new Vector3(-6.5f, 0f, 8f));

            // プレイヤーの出発点 (低い通路の手前、北を向く)
            layout.playerStart = new Vector3(0f, 0.05f, -8.5f);
            layout.playerYaw = 0f;
            return layout;
        }
    }
}
