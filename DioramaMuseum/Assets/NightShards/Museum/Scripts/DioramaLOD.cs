using UnityEngine;

namespace NightShards.Museum
{
    // ジオラマの重さを調整する。プレイヤー (カメラ) に付ける。
    //   ・近いジオラマほどレイを細かく進め (_Steps を多く)、遠いほど粗くする
    //   ・画面に映っていないジオラマと、遠すぎるジオラマは描かない
    //   ・鑑賞中の作品だけは、いちばん細かく描く
    public class DioramaLOD : MonoBehaviour
    {
        [Tooltip("この距離 (m) より近いと、いちばん細かく描く")]
        [SerializeField] float nearDistance = 2f;
        [Tooltip("この距離 (m) より遠いと、いちばん粗く描く")]
        [SerializeField] float farDistance = 12f;
        [Tooltip("この距離 (m) より遠いジオラマは描かない (別の部屋のものなど)")]
        [SerializeField] float hideDistance = 22f;
        [Tooltip("レイを進める回数 (近い / 遠い)")]
        [SerializeField] Vector2Int steps = new Vector2Int(110, 40);
        [Tooltip("影を調べる回数 (近い / 遠い)")]
        [SerializeField] Vector2Int shadowSteps = new Vector2Int(16, 0);

        public Camera viewCamera;
        public ExhibitViewer viewer;

        static readonly int StepsId = Shader.PropertyToID("_Steps");
        static readonly int ShadowStepsId = Shader.PropertyToID("_ShadowSteps");

        readonly Plane[] planes = new Plane[6];
        MaterialPropertyBlock block;

        void LateUpdate()
        {
            if (viewCamera == null) return;
            if (block == null) block = new MaterialPropertyBlock();
            GeometryUtility.CalculateFrustumPlanes(viewCamera, planes);
            Vector3 eye = viewCamera.transform.position;

            foreach (var stand in ExhibitStand.All)
            {
                if (stand == null || stand.Diorama == null) continue;
                Renderer r = stand.Diorama;

                float dist = Vector3.Distance(eye, r.bounds.center);
                bool onScreen = GeometryUtility.TestPlanesAABB(planes, r.bounds);
                bool show = onScreen && dist < hideDistance;
                if (r.enabled != show) r.enabled = show;
                if (!show) continue; // 描かないものは、値も更新しない

                float k = Mathf.InverseLerp(nearDistance, farDistance, dist);
                bool focused = viewer != null && viewer.Current == stand;
                if (focused) k = 0f;

                r.GetPropertyBlock(block); // _Biome や _Seed を消さないように、今の値を読んでから書き足す
                block.SetFloat(StepsId, Mathf.Round(Mathf.Lerp(steps.x, steps.y, k)));
                block.SetFloat(ShadowStepsId, Mathf.Round(Mathf.Lerp(shadowSteps.x, shadowSteps.y, k)));
                r.SetPropertyBlock(block);
            }
        }

        // 再生をやめたときなどに、隠したジオラマを元に戻す
        void OnDisable()
        {
            foreach (var stand in ExhibitStand.All)
                if (stand != null && stand.Diorama != null) stand.Diorama.enabled = true;
        }
    }
}
