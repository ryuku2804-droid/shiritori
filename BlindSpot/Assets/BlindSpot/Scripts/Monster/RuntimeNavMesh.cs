using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

namespace BlindSpot
{
    /// <summary>
    /// ゲーム開始時に、まわりのコライダーから NavMesh (怪物が歩ける範囲) を作る。
    /// AI Navigation パッケージを入れなくても動く (Unity 本体の NavMeshBuilder を使う)。
    /// </summary>
    [DefaultExecutionOrder(-1000)] // ほかのスクリプトの Awake より先に作っておく
    public class RuntimeNavMesh : MonoBehaviour
    {
        [Tooltip("NavMesh を作る範囲 (このオブジェクトの位置が中心)")]
        [SerializeField] Vector3 size = new Vector3(60f, 20f, 60f);

        [Tooltip("床や壁として使うレイヤー。Player と Monster は外すこと (動くものを障害物にしないため)")]
        [SerializeField] LayerMask includeLayers = ~0;

        [Tooltip("使うエージェントの種類。0 は標準の Humanoid (半径 0.5m・高さ 2m)")]
        [SerializeField] int agentTypeId = 0;

        NavMeshDataInstance instance;

        void Awake()
        {
            Build();
        }

        void OnDestroy()
        {
            if (instance.valid) instance.Remove();
        }

        /// <summary>NavMesh を作り直す。扉が開いたときなどにも呼べる。</summary>
        public void Build()
        {
            var bounds = new Bounds(transform.position, size);
            var sources = new List<NavMeshBuildSource>();
            NavMeshBuilder.CollectSources(bounds, includeLayers, NavMeshCollectGeometry.PhysicsColliders, 0,
                new List<NavMeshBuildMarkup>(), sources);

            NavMeshBuildSettings settings = NavMesh.GetSettingsByID(agentTypeId);
            NavMeshData data = NavMeshBuilder.BuildNavMeshData(settings, sources, bounds, Vector3.zero, Quaternion.identity);

            if (instance.valid) instance.Remove();
            instance = NavMesh.AddNavMeshData(data);
        }

        void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(0.3f, 0.8f, 1f, 0.5f);
            Gizmos.DrawWireCube(transform.position, size);
        }
    }
}
