"""ステップ1の学習用解説。make_source_page.py が読み込む。

書式:
  テキスト中の `コード` はコード表示、**太字** は強調になる。
  lesson = {
      "title": 見出し,
      "code": 説明対象のコード片 (省略可),
      "meaning": このコードの意味,
      "why": なぜこう書くか,
      "alts": [{"label": 別の書き方の名前, "code": コード, "why_not": 使わない理由}],
  }
"""

SETUP = [
    {
        "title": "Unity プロジェクトを作る",
        "body": "Unity Hub で「New project」を押し、**Unity 6** の **Universal 3D** テンプレートで作成します。",
    },
    {
        "title": "Input System を確認する",
        "body": "`Window > Package Manager` の「In Project」に **Input System** があるか確認します。無ければ「Unity Registry」からインストールします。"
                "次に `Edit > Project Settings > Player > Other Settings` で **Active Input Handling** を「Input System Package (New)」か「Both」にします。",
    },
    {
        "title": "フォルダを作る",
        "body": "`Assets/BlindSpot/Scripts/Noise`、`Scripts/Player`、`Scripts/Debug`、`Assets/BlindSpot/Editor` を作ります。",
    },
    {
        "title": "スクリプトを作って貼る",
        "body": "下のファイル一覧の順に作ります。フォルダで右クリック → `Create > MonoBehaviour Script` で**同じ名前**のファイルを作り、中身を全部消して「コピー」したコードを貼ります。"
                "6つそろうまでは Console に赤字が出ることがありますが、全部そろえば消えます。",
    },
    {
        "title": "テスト部屋を作る",
        "body": "新しいシーンを保存してから、メニュー `BlindSpot > ステップ1: テスト部屋とプレイヤーを作成` を押し、もう一度 Ctrl+S で保存します。",
    },
    {
        "title": "遊んで確かめる",
        "body": "Game ビューと Scene ビューを並べ、Scene ビューの Gizmos を ON にして再生します。WASD で移動、Shift で走る、Ctrl か C でしゃがむ、Esc でマウス解放、F1 で情報表示の切替です。"
                "歩くと約5m、しゃがむと約1.5m、走ると約12m の円が出れば成功です。",
    },
]

STUDY_TIPS = [
    "まず貼って動かします。動くものを見てから読むと、コードの意味がつかみやすくなります。",
    "次に Inspector の数値を変えて遊びます。歩幅や距離を変えると、どの値が何に効くかが体でわかります。",
    "慣れてきたら、1ファイルだけ解説を見ずに打ち直してみます(写経)。打てなかったところが、まだ理解していないところです。",
    "各ファイルの最後にある「やってみよう」は、作品の機能にそのままつながる小さな改造課題です。",
]

BASICS = [
    {
        "title": "namespace(名前空間)",
        "code": "namespace BlindSpot\n{\n    public class PlayerController : MonoBehaviour { ... }\n}",
        "meaning": "クラスを `BlindSpot` という名前の箱に入れています。外から使うときの正式な名前は `BlindSpot.PlayerController` になります。",
        "why": "`PlayerController` はとてもよくある名前で、無料アセットにも同じ名前のクラスがよく入っています。箱に入れておけば、同じ名前でもぶつかりません。",
        "alts": [
            {"label": "namespace を書かない", "code": "public class PlayerController : MonoBehaviour { ... }",
             "why_not": "小さな練習ならこれでも動きます。ただ、アセットを入れた瞬間に「同じ名前のクラスが2つある」というエラーが出ることがあり、直すのが面倒です。"},
        ],
    },
    {
        "title": "MonoBehaviour と呼ばれる順番",
        "code": "void Awake()  { ... } // 生成された直後に1回\nvoid OnEnable() { ... } // 有効になるたび\nvoid Start()  { ... } // 最初の Update の直前に1回\nvoid Update() { ... } // 毎フレーム",
        "meaning": "`MonoBehaviour` を継承したクラスはゲームオブジェクトに付けられるようになり、Unity が決まった順番でこれらの関数を呼びます。",
        "why": "このプロジェクトでは、**自分の準備は Awake**(GetComponent や入力の作成)、**他のオブジェクトに頼る準備は Start** と分けています。Awake の時点では他のオブジェクトの準備がまだ終わっていない可能性があるからです。",
        "alts": [
            {"label": "全部 Start で準備する", "code": "void Start() { controller = GetComponent<CharacterController>(); }",
             "why_not": "多くの場合は動きます。ただ、OnEnable は Start より先に呼ばれるので、OnEnable で使う入力を Start で作ると null エラーになります。"},
        ],
    },
    {
        "title": "[SerializeField] private と public",
        "code": "[SerializeField] float walkSpeed = 2.5f;",
        "meaning": "`private` のまま、Inspector にだけ表示して編集できるようにする書き方です(C# では何も書かないと private になります)。",
        "why": "Inspector で調整したいけれど、**他のスクリプトから勝手に書き換えられたくない**値に使います。あとで「誰が速度を変えたのか」を探す手間が減ります。",
        "alts": [
            {"label": "public にする", "code": "public float walkSpeed = 2.5f;",
             "why_not": "Inspector に出る点は同じですが、どのスクリプトからでも書き換えられるようになります。チュートリアルでよく見ますが、作品が大きくなるとバグの原因を追いにくくなります。"},
        ],
    },
    {
        "title": "プロパティ { get; private set; }",
        "code": "public MoveState State { get; private set; } = MoveState.Idle;",
        "meaning": "外からは**読めるけれど書けない**値です。書き換えられるのはこのクラスの中だけです。",
        "why": "怪物 AI や UI はプレイヤーの状態を知りたいだけで、変更する必要はありません。読み取り専用にしておくと、まちがって書き換えるコードが書けなくなります。",
        "alts": [
            {"label": "public フィールド", "code": "public MoveState State;",
             "why_not": "どこからでも `player.State = MoveState.Run;` と書けてしまいます。"},
            {"label": "ゲッター関数", "code": "MoveState state;\npublic MoveState GetState() { return state; }",
             "why_not": "意味は同じです。C# ではプロパティの方が短く、慣習なのでこちらを使います。"},
        ],
    },
]

FILE_LESSONS = {
    "NoiseSystem.cs": {
        "summary": "ゲーム全体の「音」を集めて配る放送局です。音を出す側は `Emit` を呼ぶだけ、聞く側は `OnNoise` を購読するだけで済みます。お互いのことを知らなくてよいのがポイントです。",
        "lessons": [
            {
                "title": "enum で音の種類を決める",
                "code": "public enum NoiseType { Footstep, Throw, GlassBreak, Cough, Device, Other }",
                "meaning": "取りうる値を名前付きで列挙した型です。`NoiseType.Footstep` のように使います。",
                "why": "選べる値が決まっているものは enum にすると、打ちまちがいがコンパイル時にエラーになり、エディタの補完も効きます。",
                "alts": [
                    {"label": "文字列で表す", "code": "NoiseSystem.Emit(pos, 5f, \"footstep\");",
                     "why_not": "`\"footstp\"` と打ちまちがえてもエラーにならず、怪物が反応しないバグになります。"},
                    {"label": "数字で表す", "code": "const int FOOTSTEP = 0;",
                     "why_not": "動きますが、ログに `0` と出ても何の音かわかりません。"},
                ],
            },
            {
                "title": "readonly struct で音の情報をまとめる",
                "code": "public readonly struct NoiseEvent\n{\n    public readonly Vector3 Position;\n    public readonly float Radius;\n    ...\n}",
                "meaning": "位置・距離・種類・発生源・時刻をひとまとめにした「値」です。`readonly` は、作ったあとで中身を変えられないという意味です。",
                "why": "1つの音を、怪物や UI など複数の相手が受け取ります。誰かが途中で `Radius` を書き換えると、ほかの相手に届く音まで変わってしまうので、変えられないようにしています。"
                       "また struct(値型)は class と違って、作るたびにメモリのゴミが出ません。足音は1秒に何回も鳴るので、ゴミが少ない方がカクつきにくくなります。",
                "alts": [
                    {"label": "class にする", "code": "public class NoiseEvent { ... }",
                     "why_not": "動きます。ただ、足音のたびにメモリが確保され、ガベージコレクション(ゴミ掃除)が起きる回数が増えます。"},
                    {"label": "引数をバラバラに渡す", "code": "public static event Action<Vector3, float, NoiseType> OnNoise;",
                     "why_not": "あとで「発生源」などの項目を足すと、購読しているすべての関数の引数を直す必要があります。struct なら項目を足しても受け取る側はそのままで済みます。"},
                ],
            },
            {
                "title": "距離の比較に sqrMagnitude を使う",
                "code": "float r = Radius * hearingMultiplier;\nreturn (listener - Position).sqrMagnitude <= r * r;",
                "meaning": "「距離 ≦ 半径」を「距離の2乗 ≦ 半径の2乗」として比べています。結果は同じです。",
                "why": "距離を求めるには平方根の計算が要りますが、2乗どうしで比べれば平方根が要りません。怪物が増えても軽く済みます。",
                "alts": [
                    {"label": "Vector3.Distance", "code": "return Vector3.Distance(listener, Position) <= r;",
                     "why_not": "読みやすく、正直なところ今の規模なら速さの差はほぼありません。よく呼ばれる判定なので、慣習として2乗で比べています。読みやすさを優先して Distance で書いても問題ありません。"},
                ],
            },
            {
                "title": "static class と static event(放送の仕組み)",
                "code": "public static class NoiseSystem\n{\n    public static event Action<NoiseEvent> OnNoise;\n    public static void Emit(...) { ... OnNoise?.Invoke(e); }\n}",
                "meaning": "`static` はシーンに置かなくても、どこからでも `NoiseSystem.Emit(...)` で呼べるという意味です。`event` は「この出来事が起きたら知らせてほしい」関数を登録しておく名簿です。",
                "why": "音を出す側(足音・投擲物・咳・番号錠…)は、誰が聞いているか知らなくてよくなります。聞く側は `NoiseSystem.OnNoise += 関数;` と登録するだけです。この形を **オブザーバーパターン** と呼びます。"
                       "`event` を付けると、外部からは `+=` と `-=` しかできなくなります。ほかのスクリプトが勝手に音を発火させたり、名簿を空にしたりできません。",
                "alts": [
                    {"label": "シングルトンの MonoBehaviour", "code": "public class NoiseManager : MonoBehaviour\n{\n    public static NoiseManager Instance;\n    void Awake() { Instance = this; }\n}",
                     "why_not": "よく使われる方法です。ただ、シーンに置き忘れると `Instance` が null になってエラーになります。NoiseSystem は Inspector で設定する値が無いので、シーンに置く理由がありません。"},
                    {"label": "怪物を探して直接呼ぶ", "code": "foreach (var m in FindObjectsByType<Monster>(FindObjectsSortMode.None))\n    m.Hear(pos, radius);",
                     "why_not": "足音のスクリプトが怪物のことを知らなければならず、ほかの聞き手(UI など)を足すたびにここを書き換えることになります。毎回シーン全体を探すので重くもなります。"},
                    {"label": "UnityEvent", "code": "public UnityEvent<NoiseEvent> onNoise;",
                     "why_not": "Inspector でつなぐのには便利ですが、static には使えません。コードから登録するなら C# の event の方が軽くて簡単です。"},
                ],
            },
            {
                "title": "?.Invoke(null 条件演算子)",
                "code": "OnNoise?.Invoke(e);",
                "meaning": "名簿に誰もいない(null)ときは何もせず、いれば全員を呼びます。",
                "why": "誰も購読していない状態で呼ぶと、NullReferenceException になるからです。",
                "alts": [
                    {"label": "if で確認する", "code": "if (OnNoise != null) OnNoise(e);",
                     "why_not": "意味は同じです。`?.` の方が短いのでこちらを使っています。"},
                ],
            },
            {
                "title": "Nullable(NoiseEvent?)",
                "code": "public static NoiseEvent? LastNoise { get; private set; }",
                "meaning": "`?` を付けると、struct でも「まだ無い(null)」を表せます。",
                "why": "ゲーム開始直後はまだ音が鳴っていません。「音が無い」と「位置 0,0,0 で半径 0 の音」を区別したいので、null を使えるようにしています。",
                "alts": [
                    {"label": "bool で別に持つ", "code": "public static bool HasLastNoise;\npublic static NoiseEvent LastNoise;",
                     "why_not": "動きますが、値が2つに分かれるので、片方だけ更新し忘れるミスが起きやすくなります。"},
                ],
            },
            {
                "title": "#if でデバッグ表示を製品版から外す",
                "code": "#if UNITY_EDITOR || DEVELOPMENT_BUILD\n    if (ShowDebugCircles) DrawCircle(...);\n#endif",
                "meaning": "エディタ上か開発ビルドのときだけ、この行をコンパイルします。itch.io に出す製品版には入りません。",
                "why": "円を描く処理は開発中だけ使うものなので、製品版では処理そのものを消しておきます。",
                "alts": [
                    {"label": "OnDrawGizmos で描く", "code": "void OnDrawGizmos() { Gizmos.DrawWireSphere(pos, radius); }",
                     "why_not": "Gizmos は MonoBehaviour にしか書けないので、static class では使えません。`Debug.DrawLine` はどこからでも呼べて、表示時間も指定できます。"},
                ],
            },
            {
                "title": "プレイ開始時に static をリセットする",
                "code": "[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]\nstatic void ResetStatics() { OnNoise = null; LastNoise = null; }",
                "meaning": "再生ボタンを押した直後に、Unity が自動でこの関数を呼びます。",
                "why": "再生開始を速くする設定(Enter Play Mode Options でドメインリロードを無効にする設定)を使うと、static 変数が前回のプレイの値のまま残ります。前回プレイの怪物が名簿に残るとエラーになるので、毎回空にしています。",
                "alts": [],
            },
        ],
        "next": [
            ("壁越しの音を小さくする", "`Physics.Linecast(音の位置, 怪物の位置)` で間に壁があるか調べ、あれば半径を半分にして聞こえにくくします。"),
            ("音の UI(画面下の波紋)", "`NoiseSystem.OnNoise += 関数;` で購読し、自分の足音が鳴るたびに画面下へ波紋を出します。仕様にある機能そのものです。"),
            ("投擲物", "石の `OnCollisionEnter` で `NoiseSystem.Emit(位置, 8f, NoiseType.Throw)` を呼ぶだけで、怪物がそちらへ向かうようになります(ステップ3)。"),
            ("やってみよう", "`ColorOf` の色を変えて、足音の円を自分の好きな色にしてみましょう。"),
        ],
    },
    "SurfaceMaterial.cs": {
        "summary": "床に付けて「この床はカーペット」のように素材を指定する小さなコンポーネントです。足音の大きさの倍率と、床ごとの効果音を持ちます。",
        "lessons": [
            {
                "title": "床の種類をコンポーネントで持たせる",
                "code": "public class SurfaceMaterial : MonoBehaviour\n{\n    public SurfaceType type = SurfaceType.Default;\n    ...\n}",
                "meaning": "床のゲームオブジェクトに付けて、Inspector で種類を選びます。",
                "why": "1つの床に「種類・倍率・効果音」のように、複数の情報を持たせられます。床の側に情報があるので、マップを作る人は床を選んで種類を選ぶだけで済みます。",
                "alts": [
                    {"label": "タグで判定", "code": "if (hit.collider.CompareTag(\"Carpet\")) ...",
                     "why_not": "タグは1つのオブジェクトに1つしか付けられないので、「Interactable」など別のタグと両立できません。倍率や効果音も持たせられません。"},
                    {"label": "レイヤーで判定", "code": "if (hit.collider.gameObject.layer == carpetLayer) ...",
                     "why_not": "レイヤーは全部で32個しかなく、物理や描画の設定にも使います。素材の数だけ消費するのはもったいないです。"},
                    {"label": "Physics Material の名前で判定", "code": "if (hit.collider.sharedMaterial.name == \"Carpet\") ...",
                     "why_not": "文字列の比較で打ちまちがいに弱いうえ、滑りやすさ(物理)と音の設定が混ざってしまいます。"},
                ],
            },
            {
                "title": "switch で倍率を返す",
                "code": "switch (type)\n{\n    case SurfaceType.Carpet: return 0.5f;\n    ...\n    default: return 1f;\n}",
                "meaning": "種類ごとに倍率を返します。`default` は、どの case にも当たらなかったときの値です。",
                "why": "5種類しかなく、まず動かして調整する段階なので、1か所にまとめて見やすくしています。",
                "alts": [
                    {"label": "switch 式(C# 8 以降)", "code": "return type switch\n{\n    SurfaceType.Carpet => 0.5f,\n    SurfaceType.Metal  => 1.8f,\n    _ => 1f,\n};",
                     "why_not": "Unity 6 で使えて、意味もまったく同じです。こちらの方が短く書けます。この解説では、ネットの情報で多く見かける書き方にそろえました。好みで書き換えて構いません。"},
                    {"label": "Dictionary", "code": "static Dictionary<SurfaceType, float> table = new() { { SurfaceType.Carpet, 0.5f }, ... };",
                     "why_not": "動きますが、種類が決まっていて数も少ないなら switch で十分です。Dictionary は、種類が実行中に増えるような場合に向いています。"},
                ],
            },
            {
                "title": "=> で書くプロパティ",
                "code": "public float Multiplier => overrideMultiplier ? customMultiplier : GetDefaultMultiplier(type);",
                "meaning": "`Multiplier` を読むたびに右側の式を計算して返します。`条件 ? A : B` は、条件が true なら A、false なら B という意味です。",
                "why": "1行で書ける計算なので、短い形にしています。",
                "alts": [
                    {"label": "get を書く", "code": "public float Multiplier\n{\n    get\n    {\n        if (overrideMultiplier) return customMultiplier;\n        return GetDefaultMultiplier(type);\n    }\n}",
                     "why_not": "意味は同じです。処理が長くなったらこちらの書き方に切り替えます。"},
                ],
            },
            {
                "title": "Inspector 用の属性",
                "code": "[Tooltip(\"この床の素材\")]\n[Min(0f)] public float customMultiplier = 1f;",
                "meaning": "`Tooltip` は Inspector で項目にマウスを乗せたときの説明、`Min` は入力できる最小値です。",
                "why": "数か月後の自分が値の意味を忘れても、Inspector を見ればわかります。倍率がマイナスになるような入力ミスも防げます。",
                "alts": [],
            },
        ],
        "next": [
            ("ScriptableObject で素材データを作る", "素材が増えてきたら、倍率・効果音・水しぶきのパーティクルなどを1つのアセット(`SurfaceProfile`)にまとめます。床はそのアセットを指定するだけになります。"),
            ("水たまりをトリガーにする", "床の板ではなく、`isTrigger` の箱で範囲を作り、入っている間だけ Water 扱いにする方法もあります。"),
            ("やってみよう", "`SurfaceType` に `Gravel`(砂利)を追加して、倍率を 1.4 にしてみましょう。enum に1行、switch に1行足すだけです。"),
        ],
    },
    "PlayerController.cs": {
        "summary": "一人称操作の本体です。入力を読み、視点を回し、しゃがみの高さを変え、CharacterController で動かし、最後に移動状態(Idle/Crouch/Walk/Run)を決めます。",
        "lessons": [
            {
                "title": "RequireComponent",
                "code": "[RequireComponent(typeof(CharacterController))]\npublic class PlayerController : MonoBehaviour",
                "meaning": "このスクリプトを付けると、CharacterController も自動で付きます。外すこともできなくなります。",
                "why": "CharacterController が無いと必ずエラーになるので、付け忘れそのものを防いでいます。",
                "alts": [],
            },
            {
                "title": "CharacterController で動かす",
                "code": "controller.Move((horizontalVelocity + Vector3.up * verticalVelocity) * Time.deltaTime);",
                "meaning": "壁や床との当たり判定をしながら、指定した量だけ動かします。段差は `stepOffset` まで自動で乗り越えます。",
                "why": "ステルスゲームでは、押した分だけ正確に動き、勝手に滑ったり跳ねたりしないことが大切です。",
                "alts": [
                    {"label": "Rigidbody で動かす", "code": "rb.linearVelocity = move * speed;",
                     "why_not": "物理で動くので、坂で滑ったり物にぶつかって弾かれたりします。ゲームの手触りを調整するのが難しくなります。物を押す・吹き飛ぶといった動きが必要なゲームならこちらが向いています。"},
                    {"label": "Transform を直接動かす", "code": "transform.position += move * speed * Time.deltaTime;",
                     "why_not": "当たり判定をしないので、壁をすり抜けます。"},
                    {"label": "SimpleMove", "code": "controller.SimpleMove(move * speed);",
                     "why_not": "重力を自動で処理してくれますが、落下の速さなどを自分で制御できません。今回は自分で重力を計算しています。"},
                ],
            },
            {
                "title": "入力をコードの中で作る",
                "code": "moveAction = new InputAction(\"Move\", InputActionType.Value);\nmoveAction.AddCompositeBinding(\"2DVector\")\n    .With(\"Up\", \"<Keyboard>/w\") ...;\nmoveAction.AddBinding(\"<Gamepad>/leftStick\");",
                "meaning": "「Move」という入力を作り、WASD とゲームパッドの左スティックを割り当てています。どちらで操作しても `moveAction.ReadValue<Vector2>()` で同じように読めます。",
                "why": "スクリプト1つで完結し、コピペするだけで動きます。キーボードとゲームパッドの違いを意識せずに書けます。",
                "alts": [
                    {"label": "キーを直接読む", "code": "if (Keyboard.current.wKey.isPressed) move.y += 1;",
                     "why_not": "手軽ですが、ゲームパッド用のコードを別に書く必要があり、キーを変えるたびにコードを直すことになります。"},
                    {"label": ".inputactions アセット + PlayerInput", "code": "// Project で Input Actions アセットを作り、\n// PlayerInput コンポーネントで割り当てる",
                     "why_not": "**本番ではこちらが有利です**。キーコンフィグ画面を作れるからです。今は、コピペだけで動く手軽さを優先しています。キーコンフィグを作る段階で、こちらへ移行します。"},
                    {"label": "旧 Input Manager", "code": "float h = Input.GetAxis(\"Horizontal\");",
                     "why_not": "古いチュートリアルでよく見る書き方です。Active Input Handling が新しい Input System だけになっていると、エラーで動きません。"},
                ],
            },
            {
                "title": "入力の Enable / Disable / Dispose",
                "code": "void OnEnable()  { moveAction.Enable(); ... }\nvoid OnDisable() { moveAction.Disable(); ... }\nvoid OnDestroy() { moveAction.Dispose(); ... }",
                "meaning": "`Enable` すると入力を受け付けはじめ、`Disable` で止まり、`Dispose` で後片付けします。",
                "why": "`Enable` を忘れると、値がずっと 0 のままになります。後片付けをしないと、シーンを切り替えたときにメモリが残ります。",
                "alts": [],
            },
            {
                "title": "マウスには deltaTime を掛けない",
                "code": "Vector2 mouse = mouseLookAction.ReadValue<Vector2>() * mouseSensitivity;\nVector2 pad = padLookAction.ReadValue<Vector2>() * gamepadLookSpeed * Time.deltaTime;",
                "meaning": "マウスの値は「このフレームで動いた量(ピクセル)」、スティックの値は「どれだけ傾いているか」です。",
                "why": "マウスの移動量は、フレームの長さがすでに反映された値です。そこへ deltaTime を掛けると、**フレームレートで感度が変わる**よくあるバグになります。スティックは傾けている間ずっと回したいので、時間(deltaTime)を掛けます。",
                "alts": [
                    {"label": "両方に deltaTime を掛ける", "code": "Vector2 look = input * sensitivity * Time.deltaTime;",
                     "why_not": "ネットでよく見かけますが、マウスの場合は60fpsと144fpsで感度が変わってしまいます。"},
                ],
            },
            {
                "title": "体は左右、カメラは上下に回す",
                "code": "transform.Rotate(0f, look.x, 0f);                 // 体: 左右\npitch = Mathf.Clamp(pitch - look.y, -maxPitch, maxPitch);\ncameraRoot.localRotation = Quaternion.Euler(pitch, 0f, 0f); // カメラ: 上下",
                "meaning": "左右の回転は体ごと回し、上下の回転はカメラだけ回します。上下の角度は `pitch` に保存し、±85°で止めます。",
                "why": "体ごと上を向くと、前進したときに空へ向かって進もうとしてしまいます。上下の角度を自分の変数に持っておくと、範囲の制限が簡単になります。",
                "alts": [
                    {"label": "eulerAngles を読んで制限する", "code": "var e = cameraRoot.localEulerAngles;\ne.x = Mathf.Clamp(e.x - look.y, -85, 85);",
                     "why_not": "eulerAngles は 0〜360 で返ってくるので、-10° が 350° になります。Clamp すると 85° に飛ぶバグになります。"},
                ],
            },
            {
                "title": "MoveTowards でなめらかに加速する",
                "code": "horizontalVelocity = Vector3.MoveTowards(horizontalVelocity, targetVelocity, acceleration * Time.deltaTime);",
                "meaning": "今の速度を、目標の速度へ「1秒に acceleration ずつ」近づけます。",
                "why": "急にトップスピードにならず、急に止まりもしないので、少しだけ重さが出ます。決まった時間で必ず目標に届くので、調整もしやすいです。",
                "alts": [
                    {"label": "Lerp", "code": "horizontalVelocity = Vector3.Lerp(horizontalVelocity, targetVelocity, 10f * Time.deltaTime);",
                     "why_not": "よく使われますが、毎回「残りの何割」だけ近づくので、目標に完全には届きません。届くまでの時間もフレームレートで少し変わります。"},
                    {"label": "そのまま代入", "code": "horizontalVelocity = targetVelocity;",
                     "why_not": "キビキビしたゲームならこれでも構いません。今回は、足音が止まるタイミングを自然にしたいので加速を入れています。"},
                ],
            },
            {
                "title": "重力と接地",
                "code": "if (controller.isGrounded && verticalVelocity < 0f) verticalVelocity = -2f;\nverticalVelocity += gravity * Time.deltaTime;",
                "meaning": "落下速度を毎フレーム増やし、地面にいるときは小さな下向きの値に戻します。",
                "why": "0 に戻すと、地面から少し浮いたと判定されて `isGrounded` が false と true を行き来します。少しだけ下向きの力を残すことで、地面に押し付け続けています。",
                "alts": [],
            },
            {
                "title": "移動状態を決める if の順番",
                "code": "if (IsCrouching) State = MoveState.Crouch;\nelse if (!moving) State = MoveState.Idle;\nelse if (running) State = MoveState.Run;\nelse State = MoveState.Walk;",
                "meaning": "上から順に調べ、最初に当てはまったものに決めます。",
                "why": "**順番が優先順位**になっています。しゃがみは止まっていても動いていても Crouch にしたいので、一番上に置いています。",
                "alts": [],
            },
            {
                "title": "立ち上がれるかを CheckCapsule で調べる",
                "code": "return !Physics.CheckCapsule(bottom, top, r, obstacleMask, QueryTriggerInteraction.Ignore);",
                "meaning": "立ったときの体の形(カプセル)の範囲に、何かが重なっていないか調べます。",
                "why": "低い通路でしゃがみをやめても、天井にめり込まないようにするためです。`obstacleMask` から Player レイヤーを外しているのは、自分の体と重なっていると判定させないためです。",
                "alts": [
                    {"label": "真上に Raycast を1本打つ", "code": "Physics.Raycast(transform.position, Vector3.up, standHeight)",
                     "why_not": "線1本なので、頭の端だけが天井にかかっているときに見逃します。"},
                ],
            },
        ],
        "next": [
            ("スタミナ", "`running` の間だけゲージを減らし、0 になったら走れないようにします。息切れの音を鳴らせば、それも `NoiseSystem.Emit` で怪物に聞こえるようにできます。"),
            ("隠れる", "ロッカーに入ったら `InputEnabled = false` にしてカメラを中へ移します(ステップ3)。"),
            ("ヘッドボブ(歩くときのカメラの揺れ)", "`FootstepNoise.OnStep` を購読し、1歩ごとにカメラを少し上下させます。"),
            ("やってみよう", "`crouchToggle` を ON にして、しゃがみの切り替え方式を試してみましょう。どちらが好みか決めたら、オプション画面で選べるようにするのも次の課題になります。"),
        ],
    },
    "FootstepNoise.cs": {
        "summary": "プレイヤーが歩いた距離を数え、歩幅に達するたびに足音を1回鳴らします。床の素材を調べて「基本距離 × 床の倍率」を計算し、NoiseSystem に知らせます。",
        "lessons": [
            {
                "title": "時間ではなく、歩いた距離で鳴らす",
                "code": "distanceSinceStep += moved;\nif (distanceSinceStep >= setting.stride) { distanceSinceStep = 0f; Step(setting); }",
                "meaning": "動いた距離を足していき、歩幅を超えたら1歩と数えます。",
                "why": "ゆっくり動けば足音は少なく、速く動けば多くなります。実際の足の動きと一致します。「そっと動けば静か」が自然に表現できます。",
                "alts": [
                    {"label": "一定時間ごとに鳴らす", "code": "timer += Time.deltaTime;\nif (timer > 0.5f) { timer = 0; Step(); }",
                     "why_not": "壁に向かって歩いて動いていないときでも鳴ってしまいます。速さと足音の間隔も合いません。"},
                ],
            },
            {
                "title": "前のフレームとの位置の差で動いた量を測る",
                "code": "Vector3 delta = pos - lastPosition;\nlastPosition = pos;\ndelta.y = 0f;",
                "meaning": "前のフレームの位置を覚えておき、今の位置との差を「動いた量」とします。上下の動き(y)は数えません。",
                "why": "壁にこすれて止まった場合なども含めて、**実際に動いた量**が取れます。",
                "alts": [
                    {"label": "controller.velocity を使う", "code": "float moved = controller.velocity.magnitude * Time.deltaTime;",
                     "why_not": "これでもほぼ同じになります。位置の差なら PlayerController の中身に頼らずに済むので、こちらにしています。"},
                ],
            },
            {
                "title": "[Serializable] struct で設定をまとめる",
                "code": "[Serializable]\npublic struct StepSetting { public float stride; public float baseRadius; public float volume; }\n[SerializeField] StepSetting walk = new StepSetting(0.7f, 5f, 0.4f);",
                "meaning": "`[Serializable]` を付けると、自作の struct も Inspector に折りたたみで表示されます。",
                "why": "しゃがみ・歩き・走りの3つに同じ形の設定があるので、まとめると Inspector が見やすくなります。",
                "alts": [
                    {"label": "float を9個並べる", "code": "[SerializeField] float crouchStride, crouchRadius, crouchVolume, walkStride, ...;",
                     "why_not": "動きますが、Inspector が縦に長くなり、どれがどれだか見分けにくくなります。"},
                    {"label": "配列にして enum で引く", "code": "[SerializeField] StepSetting[] settings; // [0]=Idle, [1]=Crouch ...",
                     "why_not": "enum の順番を入れ替えた瞬間に、設定がずれる事故が起きます。"},
                ],
            },
            {
                "title": "足元の床を Raycast で調べる",
                "code": "if (Physics.Raycast(origin, Vector3.down, out RaycastHit hit, groundCheckDistance + 0.1f, groundMask, QueryTriggerInteraction.Ignore))\n    currentSurfaceComponent = hit.collider.GetComponentInParent<SurfaceMaterial>();",
                "meaning": "足元の少し上から下へ見えない線を飛ばし、当たった床に付いている `SurfaceMaterial` を取り出します。",
                "why": "`GetComponentInParent` は、床そのものか、その親にあれば見つけます。床を細かく分けても、親に1つ付けておけば済みます。トリガー(見えない判定用の箱)は床ではないので無視しています。",
                "alts": [
                    {"label": "OnControllerColliderHit", "code": "void OnControllerColliderHit(ControllerColliderHit hit) { ... }",
                     "why_not": "壁にぶつかったときにも呼ばれるので、床だけを選ぶ処理が必要になります。"},
                ],
            },
            {
                "title": "自分専用のイベント OnStep",
                "code": "public event Action<StepInfo> OnStep;\n...\nOnStep?.Invoke(new StepInfo(pos, radius, player.State, CurrentSurface));",
                "meaning": "このプレイヤーの足音が鳴るたびに知らせる名簿です。",
                "why": "NoiseSystem はすべての音を流しますが、カメラの揺れや足音の UI が欲しいのは**プレイヤー自身の足音だけ**です。用途によって、聞く場所を分けています。",
                "alts": [],
            },
            {
                "title": "PlayOneShot とピッチの揺らぎ",
                "code": "audioSource.pitch = UnityEngine.Random.Range(0.92f, 1.08f);\naudioSource.PlayOneShot(clip, volume);",
                "meaning": "`PlayOneShot` は前の音を止めずに重ねて鳴らします。ピッチ(音の高さ)を毎回少し変えています。",
                "why": "同じ音がまったく同じ高さで繰り返されると、機械っぽく聞こえるからです。`UnityEngine.Random` と書いているのは、`using System;` があると `System.Random` と名前がぶつかるためです。",
                "alts": [
                    {"label": "audioSource.Play()", "code": "audioSource.clip = clip;\naudioSource.Play();",
                     "why_not": "前の音が途中で切れます。足音のように短い音を続けて鳴らす場合は、PlayOneShot が向いています。"},
                ],
            },
        ],
        "next": [
            ("左右の足で音を変える", "1歩ごとに bool を反転させ、左足用と右足用の効果音を交互に鳴らします。"),
            ("床ごとのエフェクト", "水の床なら1歩ごとに水しぶきのパーティクルを出します。`StepInfo.Surface` を見て切り替えます。"),
            ("やってみよう", "`run` の `baseRadius` を 12 から 20 にして、走ることがどれだけ危険になるかを Scene ビューの円で確かめてみましょう。"),
        ],
    },
    "DebugHud.cs": {
        "summary": "試作中に状態を確認するための、画面左上の文字表示です。作品が完成したら外します。",
        "lessons": [
            {
                "title": "OnGUI(IMGUI)で表示する",
                "code": "void OnGUI()\n{\n    GUI.Box(new Rect(10, 10, 360, 190), GUIContent.none);\n    GUI.Label(new Rect(20, 15, 350, 185), text, style);\n}",
                "meaning": "Unity の古い UI の仕組みで、コードだけで画面に文字や箱を描けます。",
                "why": "Canvas もオブジェクトも要らず、数行で表示できます。**試作のデバッグ表示**に一番手早い方法です。",
                "alts": [
                    {"label": "uGUI(Canvas + TextMeshPro)", "code": "[SerializeField] TMP_Text label;\nlabel.text = ...;",
                     "why_not": "見た目にこだわれる製品向けの UI です。デバッグ表示には準備の手間が多すぎます。タイトル画面や息止めゲージなど、製品の UI ではこちらか UI Toolkit を使います。"},
                ],
            },
            {
                "title": "文字列補間 $\"...\"",
                "code": "$\"速度: {player.HorizontalSpeed:F2} m/s\\n\"",
                "meaning": "`{ }` の中に変数を書くと、その値が文字列に入ります。`:F2` は小数点以下2桁、`\\n` は改行です。",
                "why": "文字と値が混ざった文章を、読みやすく書けます。",
                "alts": [
                    {"label": "+ でつなぐ", "code": "\"速度: \" + player.HorizontalSpeed.ToString(\"F2\") + \" m/s\\n\"",
                     "why_not": "意味は同じですが、長くなるほど読みにくくなります。"},
                    {"label": "string.Format", "code": "string.Format(\"速度: {0:F2} m/s\", player.HorizontalSpeed)",
                     "why_not": "意味は同じです。番号と値の対応を目で追う必要があります。"},
                ],
            },
            {
                "title": "is によるパターンマッチ",
                "code": "NoiseSystem.LastNoise is NoiseEvent n ? $\"...{n.Radius}...\" : \"\"",
                "meaning": "`LastNoise` が null でなければ、中身を `n` という名前で取り出して使います。",
                "why": "「null かどうかの確認」と「中身の取り出し」を1回で書けます。",
                "alts": [
                    {"label": "HasValue と Value", "code": "if (NoiseSystem.LastNoise.HasValue) { var n = NoiseSystem.LastNoise.Value; ... }",
                     "why_not": "意味は同じです。少し長くなります。"},
                ],
            },
            {
                "title": "style を OnGUI の中で1回だけ作る",
                "code": "if (style == null) { style = new GUIStyle(GUI.skin.label) { fontSize = 16 }; }",
                "meaning": "最初に OnGUI が呼ばれたときだけ文字の見た目を作り、あとは使い回します。",
                "why": "`GUI.skin` は OnGUI の中でしか使えないので、Awake では作れません。毎回作るとゴミが出るので、1回だけにしています。",
                "alts": [],
            },
        ],
        "next": [
            ("怪物の状態を表示する", "ステップ2で、怪物が今「巡回・調査・追跡」のどれなのかを表示に足します。AI の調整がずっと楽になります。"),
            ("やってみよう", "表示に `player.IsGrounded` を追加して、地面にいるかどうかが出るようにしてみましょう。"),
        ],
    },
    "GrayboxRoomBuilder.cs": {
        "summary": "Unity エディタのメニューから、テスト部屋とプレイヤーを自動で組み立てるエディタ拡張です。ゲーム本体には含まれません。手作業の設定ミスを防ぐのが目的です。",
        "lessons": [
            {
                "title": "Editor フォルダと using UnityEditor",
                "code": "using UnityEditor;\nnamespace BlindSpot.EditorTools { ... }",
                "meaning": "`UnityEditor` はエディタの中でしか使えない機能です。`Editor` という名前のフォルダに置いたスクリプトは、ビルドしたゲームには含まれません。",
                "why": "外に置くと、ビルドしたときに「UnityEditor が見つからない」というエラーになります。",
                "alts": [
                    {"label": "#if UNITY_EDITOR で囲む", "code": "#if UNITY_EDITOR\nusing UnityEditor;\n...\n#endif",
                     "why_not": "これでも動きます。ゲーム本体のスクリプトに、エディタ専用の処理を少しだけ混ぜたいときに使います。ファイル丸ごとエディタ用なら、Editor フォルダの方がわかりやすいです。"},
                ],
            },
            {
                "title": "MenuItem でメニューを足す",
                "code": "[MenuItem(\"BlindSpot/ステップ1: テスト部屋とプレイヤーを作成\")]\npublic static void Build() { ... }",
                "meaning": "static 関数にこの属性を付けると、上のメニューバーに項目が増え、クリックで関数が呼ばれます。",
                "why": "何度でも同じ部屋を作り直せます。手順を説明するより、ボタン1つの方が確実です。",
                "alts": [],
            },
            {
                "title": "Undo に対応させる",
                "code": "Undo.RegisterCreatedObjectUndo(root, \"Create Graybox Room\");\nUndo.DestroyObjectImmediate(oldRoot);",
                "meaning": "作ったものや消したものを Undo の履歴に記録します。",
                "why": "Ctrl+Z で元に戻せるようにするためです。エディタ拡張では大切なマナーです。",
                "alts": [
                    {"label": "DestroyImmediate", "code": "Object.DestroyImmediate(oldRoot);",
                     "why_not": "消えますが、Ctrl+Z で戻せません。まちがって消したら終わりです。"},
                ],
            },
            {
                "title": "SerializedObject で private の設定を書き込む",
                "code": "var so = new SerializedObject(pc);\nso.FindProperty(\"cameraRoot\").objectReferenceValue = camRoot.transform;\nso.ApplyModifiedPropertiesWithoutUndo();",
                "meaning": "Inspector で値を入れるのと同じ方法で、`[SerializeField] private` の項目に値を入れています。",
                "why": "そのための public を作らずに済みます。シーンの保存にも正しく反映されます。",
                "alts": [
                    {"label": "フィールドを public にする", "code": "pc.cameraRoot = camRoot.transform;",
                     "why_not": "エディタ拡張のためだけに、ゲーム中のどこからでも書き換えられる状態になってしまいます。"},
                ],
            },
            {
                "title": "レイヤーマスク(ビット演算)",
                "code": "int maskWithoutPlayer = ~(1 << playerLayer);",
                "meaning": "レイヤーマスクは、32個のオン・オフ(ビット)で表されます。`1 << 8` は「8番だけオン」です。`~` で全部を反転させると、「8番以外ぜんぶオン」になります。",
                "why": "床や天井を調べるときに、自分の体(Player レイヤー)を当たり判定から外すためです。",
                "alts": [
                    {"label": "LayerMask.GetMask", "code": "int mask = ~LayerMask.GetMask(\"Player\");",
                     "why_not": "意味は同じで、こちらの方が読みやすいです。今回は、直前で作ったレイヤーの番号が手元にあるので、番号から作りました。普段のコードなら GetMask で構いません。"},
                ],
            },
            {
                "title": "マテリアルをアセットとして保存する",
                "code": "mat = new Material(shader);\nAssetDatabase.CreateAsset(mat, path);",
                "meaning": "作ったマテリアルを `.mat` ファイルとしてプロジェクトに保存します。",
                "why": "メモリ上で作っただけのマテリアルは、シーンを保存して開き直すと消え、ピンク色(マテリアルが無い状態)になります。",
                "alts": [
                    {"label": "new Material だけ", "code": "renderer.sharedMaterial = new Material(shader);",
                     "why_not": "その場では見えますが、保存して開き直すと消えます。"},
                ],
            },
        ],
        "next": [
            ("ステップ2で拡張する", "メニューに「怪物を配置」を足し、怪物のカプセル・巡回ポイント・NavMesh(怪物が歩ける範囲)を自動で作ります。"),
            ("自分だけの部屋ジェネレーター", "`Box(...)` の呼び出しを書き換えれば、部屋の形を自由に変えられます。病棟の廊下のような細長い部屋を作ってみましょう。"),
            ("やってみよう", "`SurfacePatch` をもう1つ足して、部屋の真ん中に金属の床を置いてみましょう。"),
        ],
    },
}

# ---------------- 説明の練習 ----------------

# W キーを押してから、音が怪物に届くまでの流れ
FLOW = [
    ("PlayerController", "W キーの入力を `moveAction` から読み、`CharacterController.Move` で体を前へ動かす。前進中に Shift を押していれば `State` を Run にする。"),
    ("FootstepNoise", "毎フレーム「前のフレームからどれだけ動いたか」を足していき、歩幅を超えたら1歩と数える。"),
    ("SurfaceMaterial", "足元へ Raycast を飛ばして床の `SurfaceMaterial` を見つけ、その床の倍率(金属なら 1.8)を取り出す。"),
    ("FootstepNoise", "「状態ごとの基本距離 × 床の倍率」で、足音の届く距離を決める(走り 12m × 金属 1.8 = 21.6m)。"),
    ("NoiseSystem", "`NoiseSystem.Emit` で音を放送する。`OnNoise` に登録している全員へ届き、Scene ビューに円が描かれる。"),
    ("(ステップ2)怪物", "`OnNoise` で音を受け取り、自分が半径の内側にいれば音の場所へ向かう。"),
]

# ファイルごと: 一言でいうと / 30秒で説明するなら / 確認の質問
EXPLAIN = {
    "NoiseSystem.cs": {
        "one": "ゲームの中の音を、聞きたい相手全員に配る放送局。",
        "talk": "音を出す側は `Emit` に「どこで・どのくらい遠くまで・何の音か」を渡すだけで、誰が聞いているかは知りません。"
                "聞く側は `OnNoise` に登録しておけば、音が鳴るたびに知らせが来ます。"
                "出す側と聞く側がお互いを知らなくていいので、投擲物や咳などの音を、あとから同じやり方で簡単に足せます。",
        "quiz": [
            ("足音のスクリプトは、怪物がどこにいるか知っている?", "知りません。NoiseSystem に投げるだけです。誰が聞くかは NoiseSystem に登録した側の問題です。"),
            ("NoiseEvent を class ではなく struct にしたのはなぜ?", "足音は1秒に何度も鳴ります。struct なら作るたびにメモリのゴミが出ないので、カクつきの原因になりにくいからです。"),
            ("`OnNoise?.Invoke(e)` の `?` が無いと何が起きる?", "誰も登録していないときに NullReferenceException(エラー)になります。"),
        ],
    },
    "SurfaceMaterial.cs": {
        "one": "床に貼る「この床は何でできているか」の名札。",
        "talk": "床のオブジェクトに付けて、カーペット・ガラス・水・金属などを選びます。"
                "素材ごとに足音の倍率が決まっていて、カーペットなら半分、金属なら 1.8 倍です。"
                "タグではなくコンポーネントにしたのは、倍率や効果音など、複数の情報を1つの床に持たせたいからです。",
        "quiz": [
            ("SurfaceMaterial が付いていない床を歩いたら、倍率はいくつ?", "1(Default 扱い)です。FootstepNoise 側で、見つからなければ 1 を使っています。"),
            ("タグで床の種類を判定しないのはなぜ?", "タグは1つのオブジェクトに1つしか付けられず、倍率や効果音のような値も持てないからです。"),
        ],
    },
    "PlayerController.cs": {
        "one": "入力を読んで、体を動かし、今「止まり・しゃがみ・歩き・走り」のどれかを決める係。",
        "talk": "毎フレーム、入力を読んで、視点を回し、しゃがみの高さを変え、CharacterController で動かします。"
                "最後に今の移動状態を `State` として決め、外から読めるようにしています。"
                "CharacterController を使うのは、物理に振り回されず、押した分だけ正確に動くからです。ステルスでは、この正確さが大切です。",
        "quiz": [
            ("マウスの値に Time.deltaTime を掛けないのはなぜ?", "マウスの値は「そのフレームで動いた量」で、フレームの長さがすでに含まれているからです。掛けると、フレームレートで感度が変わってしまいます。"),
            ("左右は体を回し、上下はカメラだけ回すのはなぜ?", "体ごと上を向くと、前進したときに空へ向かって進もうとするからです。"),
            ("State を外から書き換えられないようにしているのはなぜ?", "怪物や UI は状態を読むだけでいいので、まちがって書き換えるバグを防ぐためです(`{ get; private set; }`)。"),
        ],
    },
    "FootstepNoise.cs": {
        "one": "歩いた距離を数えて、1歩ごとに足音を鳴らし、その音を NoiseSystem に知らせる係。",
        "talk": "前のフレームとの位置の差から、実際に動いた距離を足していき、歩幅を超えたら1歩とします。"
                "1歩ごとに足元の床を調べ、「状態の基本距離 × 床の倍率」で音の届く距離を決めて、NoiseSystem に渡します。"
                "時間ではなく距離で鳴らすので、ゆっくり動けば足音は少なくなり、「そっと歩けば静か」が自然に表現できます。",
        "quiz": [
            ("しゃがんで金属の床を歩いたとき、足音の届く距離は?", "1.5m × 1.8 = 2.7m です。"),
            ("壁に向かって W を押し続けたら、足音は鳴る?", "鳴りません。位置が変わらないので、歩いた距離が増えないからです。"),
            ("OnStep と NoiseSystem.OnNoise はどう使い分ける?", "OnNoise はすべての音が流れる放送です。OnStep はこのプレイヤーの足音だけです。カメラの揺れなど「自分の足音にだけ反応したいもの」は OnStep を使います。"),
        ],
    },
    "DebugHud.cs": {
        "one": "試作中だけ使う、画面左上の状態表示。",
        "talk": "移動状態や足元の床、最後に鳴った音の距離を文字で表示します。"
                "OnGUI という古い UI の仕組みを使っているのは、Canvas などを用意しなくても数行で表示できるからです。"
                "製品版の UI には使わず、完成したら外します。",
        "quiz": [
            ("ゲームのタイトル画面も OnGUI で作るべき?", "作りません。見た目の調整がしにくく重いので、製品の UI は uGUI か UI Toolkit で作ります。"),
        ],
    },
    "GrayboxRoomBuilder.cs": {
        "one": "メニューのボタン1つで、テスト部屋とプレイヤーを組み立てるエディタ専用の道具。",
        "talk": "Unity のメニューに項目を足し、押すと部屋・素材付きの床・プレイヤー・レイヤー設定をまとめて作ります。"
                "Editor フォルダに置くので、ゲーム本体には含まれません。"
                "手作業の設定ミスを無くすことと、何度でも同じ状態を作り直せることが目的です。",
        "quiz": [
            ("このファイルを Editor フォルダの外に置くとどうなる?", "ゲームをビルドするときに「UnityEditor が見つからない」エラーになります。"),
            ("`~(1 << playerLayer)` は何を表している?", "「Player レイヤー以外の全部」というレイヤーマスクです。床を調べるときに、自分の体を除外するために使います。"),
        ],
    },
}
