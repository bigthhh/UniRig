#!/usr/bin/env python3
"""GLB/FBX model viewer - scans directories and serves 3D models with skeleton visualization."""

import json
import sys
from pathlib import Path

from werkzeug.utils import secure_filename
from flask import Flask, jsonify, request, send_from_directory, send_file

app = Flask(__name__, static_folder="static")

SUPPORTED_EXT = {".glb", ".fbx", ".obj"}
CONFIG_FILE = Path(__file__).parent / "dirs.json"
UPLOAD_DIR_FILE = Path(__file__).parent / "upload_dir.json"


def load_dirs():
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text())
    return []


def save_dirs(dirs):
    CONFIG_FILE.write_text(json.dumps(dirs, ensure_ascii=False, indent=2))


def load_upload_dir():
    if UPLOAD_DIR_FILE.exists():
        return json.loads(UPLOAD_DIR_FILE.read_text()).get("upload_dir", "")
    return ""


def save_upload_dir(d):
    UPLOAD_DIR_FILE.write_text(json.dumps({"upload_dir": d}, ensure_ascii=False, indent=2))


@app.route("/")
def index():
    return send_from_directory("static", "index.html")


@app.route("/api/dirs", methods=["GET"])
def get_dirs():
    return jsonify(load_dirs())


@app.route("/api/dirs", methods=["POST"])
def add_dir():
    dir_path = request.json.get("dir", "").strip()
    if not dir_path:
        return jsonify({"error": "Empty path"}), 400
    target = str(Path(dir_path).expanduser().resolve())
    if not Path(target).is_dir():
        return jsonify({"error": f"Not a directory: {target}"}), 400
    dirs = load_dirs()
    if target not in dirs:
        dirs.append(target)
        save_dirs(dirs)
    return jsonify(dirs)


@app.route("/api/dirs", methods=["DELETE"])
def remove_dir():
    dir_path = request.json.get("dir", "").strip()
    dirs = load_dirs()
    dirs = [d for d in dirs if d != dir_path]
    save_dirs(dirs)
    return jsonify(dirs)


@app.route("/api/scan")
def scan_all():
    dirs = load_dirs()
    results = []
    for d in dirs:
        p = Path(d)
        if not p.is_dir():
            continue
        for f in sorted(p.rglob("*")):
            if f.is_file() and f.suffix.lower() in SUPPORTED_EXT:
                results.append({
                    "name": str(f.relative_to(p)),
                    "ext": f.suffix.lower().lstrip("."),
                    "size": f.stat().st_size,
                    "path": str(f),
                    "dir": d,
                })
    return jsonify({"dirs": dirs, "files": results})


@app.route("/api/file")
def serve_file():
    file_path = request.args.get("path", "")
    if not file_path:
        return jsonify({"error": "Missing 'path' parameter"}), 400
    p = Path(file_path).expanduser().resolve()
    if not p.is_file():
        return jsonify({"error": f"File not found: {p}"}), 404
    if p.suffix.lower() not in SUPPORTED_EXT:
        return jsonify({"error": "Unsupported file type"}), 400
    return send_file(p, mimetype="application/octet-stream")


@app.route("/api/download")
def download_file():
    file_path = request.args.get("path", "")
    if not file_path:
        return jsonify({"error": "Missing 'path' parameter"}), 400
    p = Path(file_path).expanduser().resolve()
    if not p.is_file():
        return jsonify({"error": f"File not found: {p}"}), 404
    if p.suffix.lower() not in SUPPORTED_EXT:
        return jsonify({"error": "Unsupported file type"}), 400
    return send_file(p, as_attachment=True, download_name=p.name)


@app.route("/api/upload-dir", methods=["GET"])
def get_upload_dir():
    return jsonify({"upload_dir": load_upload_dir()})


@app.route("/api/upload-dir", methods=["POST"])
def set_upload_dir():
    dir_path = request.json.get("dir", "").strip()
    if not dir_path:
        return jsonify({"error": "Empty path"}), 400
    target = str(Path(dir_path).expanduser().resolve())
    if not Path(target).is_dir():
        return jsonify({"error": f"Not a directory: {target}"}), 400
    save_upload_dir(target)
    return jsonify({"upload_dir": target})


@app.route("/api/upload", methods=["POST"])
def upload_file():
    upload_dir = load_upload_dir()
    if not upload_dir or not Path(upload_dir).is_dir():
        return jsonify({"error": "Upload directory not configured or invalid"}), 400
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400
    f = request.files["file"]
    if not f.filename:
        return jsonify({"error": "Empty filename"}), 400
    ext = Path(f.filename).suffix.lower()
    if ext not in SUPPORTED_EXT:
        return jsonify({"error": f"Unsupported file type: {ext}"}), 400
    filename = secure_filename(f.filename)
    dest = Path(upload_dir) / filename
    f.save(str(dest))
    return jsonify({"ok": True, "path": str(dest), "name": filename})


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    print(f"Starting GLB/FBX viewer at http://localhost:{port}")
    app.run(host="0.0.0.0", port=port, debug=True)
