"""BlindSpot/Assets 以下を .unitypackage にまとめる。

使い方:
    python3 BlindSpot/tools/make_unitypackage.py <出力.unitypackage>

- GUID はファイルのパスから毎回同じ値を作る。次のステップのパッケージを読み込むと、
  同じファイルは「上書き(変更)」、新しいファイルは「追加(新規)」として扱われる。
- 足りない .meta ファイルは Assets 側にも書き出す (フォルダを直接コピーする場合も GUID がそろうように)。
"""
import hashlib
import io
import pathlib
import sys
import tarfile

ROOT = pathlib.Path(__file__).resolve().parent.parent  # BlindSpot/
ASSETS = ROOT / "Assets"

SCRIPT_META = """fileFormatVersion: 2
guid: {guid}
MonoImporter:
  externalObjects: {{}}
  serializedVersion: 2
  defaultReferences: []
  executionOrder: 0
  icon: {{instanceID: 0}}
  userData:
  assetBundleName:
  assetBundleVariant:
"""

FOLDER_META = """fileFormatVersion: 2
guid: {guid}
folderAsset: yes
DefaultImporter:
  externalObjects: {{}}
  userData:
  assetBundleName:
  assetBundleVariant:
"""


def guid_of(unity_path):
    return hashlib.md5(("blindspot:" + unity_path).encode("utf-8")).hexdigest()


def add_bytes(tar, name, data):
    info = tarfile.TarInfo(name)
    info.size = len(data)
    info.mode = 0o644
    tar.addfile(info, io.BytesIO(data))


def ensure_meta(path, unity_path):
    """Assets 側に .meta が無ければ作る。あればその GUID を使う。"""
    meta = path.with_name(path.name + ".meta")
    if meta.exists():
        text = meta.read_text(encoding="utf-8")
    else:
        template = FOLDER_META if path.is_dir() else SCRIPT_META
        text = template.format(guid=guid_of(unity_path))
        meta.write_text(text, encoding="utf-8")
    guid = next(line.split(":", 1)[1].strip() for line in text.splitlines() if line.startswith("guid:"))
    return guid, text


def main(out_path):
    entries = sorted(p for p in (ASSETS / "BlindSpot").rglob("*") if not p.name.endswith(".meta"))
    entries.insert(0, ASSETS / "BlindSpot")
    with tarfile.open(out_path, "w:gz") as tar:
        for path in entries:
            unity_path = path.relative_to(ROOT).as_posix()  # Assets/BlindSpot/...
            guid, meta_text = ensure_meta(path, unity_path)
            add_bytes(tar, f"{guid}/pathname", unity_path.encode("utf-8"))
            add_bytes(tar, f"{guid}/asset.meta", meta_text.encode("utf-8"))
            if path.is_file():
                add_bytes(tar, f"{guid}/asset", path.read_bytes())
            print(("  " if path.is_file() else "D ") + unity_path)
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "BlindSpot.unitypackage")
