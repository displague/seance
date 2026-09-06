"""Project asset build tool only; the game itself is entirely native GDScript.

Meshy skill workflow: preview -> PBR refine -> humanoid rig -> download.
No automatic POST retries. Resume stored task IDs without spending twice.
Reads only the explicitly supplied credentials file; never writes credentials.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import time
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import dotenv_values

ROOT = Path(__file__).resolve().parents[1]
PROMPTS = {
    "physician": (
        "A realistic adult Victorian male physician age 55, tall slender ordinary human "
        "proportions, stern lined face, short swept back grey hair, clean shaven. Fitted "
        "charcoal black high collar jacket ending at hips, muted dark burgundy waistcoat, "
        "white shirt, fitted black trousers, polished black ankle boots. Two empty open "
        "hands, five fingers each, two arms extended horizontally in strict T pose, two "
        "legs apart. Elegant gothic murder mystery game character, detailed realistic "
        "PBR fabrics and skin. No props, no hat, no cane, no base, no scenery, no cape."
    ),
    "medium": (
        "A realistic adult Victorian female spiritualist age 35, tall slender natural "
        "human proportions, pale thoughtful face, dark brown hair in a neat bun. Fitted "
        "dark teal high collar jacket ending at hips, ivory blouse, antique brass buttons, "
        "fitted dark charcoal riding trousers and black ankle boots. Two empty open "
        "hands, five fingers each, arms extended horizontally in strict T pose, legs "
        "apart. Elegant gothic murder mystery character, realistic detailed PBR "
        "fabrics and skin. No props, no skirt, no hat, no base, no scenery, no cape."
    ),
}


class Pipeline:
    def __init__(self, role: str, key: str, resume: Path | None):
        self.role = role
        self.session = requests.Session()
        self.headers = {"Authorization": f"Bearer {key}"}
        self.folder = resume or ROOT / "meshy_output" / (
            datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_") + role
        )
        self.folder.mkdir(parents=True, exist_ok=True)
        self.meta_file = self.folder / "metadata.json"
        self.meta = (
            json.loads(self.meta_file.read_text())
            if self.meta_file.exists()
            else {
                "role": role,
                "prompt": PROMPTS[role],
                "stages": {},
                "files": [],
                "estimated_credits": 35,
                "ai_model": "meshy-6",
            }
        )

    def persist(self):
        self.meta_file.write_text(json.dumps(self.meta, indent=2), encoding="utf-8")

    def request(self, method: str, path: str, **kwargs):
        response = self.session.request(
            method,
            "https://api.meshy.ai" + path,
            headers=self.headers,
            timeout=45,
            **kwargs,
        )
        if not response.ok:
            raise RuntimeError(f"Meshy {method} {path}: HTTP {response.status_code}")
        return response.json()

    def stage(self, name: str, endpoint: str, payload: dict):
        stage = self.meta["stages"].get(name)
        if not stage:
            # Persist each task ID immediately; a subsequent run resumes it.
            result = self.request("POST", endpoint, json=payload)
            stage = {"task_id": result["result"], "endpoint": endpoint}
            self.meta["stages"][name] = stage
            self.persist()
            print(f"{self.role}: {name} created {stage['task_id']}", flush=True)
        start = time.monotonic()
        delay = 5.0
        while time.monotonic() - start < 1800:
            task = self.request("GET", endpoint + "/" + stage["task_id"])
            print(
                f"{self.role}: {name} {task['status']} {task.get('progress', 0)}%",
                flush=True,
            )
            if task["status"] == "SUCCEEDED":
                stage["result"] = task
                self.persist()
                return task
            if task["status"] in {"FAILED", "CANCELED"}:
                stage["result"] = task
                self.persist()
                raise RuntimeError(
                    f"{self.role} {name}: {task['status']}; inspect metadata"
                )
            time.sleep(15 if task.get("progress", 0) >= 95 else delay)
            delay = min(30, delay * 1.5)
        raise TimeoutError("Task is still processing; resume this folder later.")

    def download(self, url: str, name: str):
        target = self.folder / name
        if target.exists() and target.stat().st_size > 100:
            return target
        partial = target.with_suffix(target.suffix + ".part")
        # CDN download deliberately receives no credential header.
        with requests.get(url, stream=True, timeout=300) as response:
            response.raise_for_status()
            with partial.open("wb") as output:
                for chunk in response.iter_content(1024 * 1024):
                    output.write(chunk)
        if partial.stat().st_size <= 100:
            raise ValueError(
                "Asset download is unexpectedly small; retained partial file"
            )
        partial.replace(target)
        self.meta["files"].append(name)
        self.persist()
        print(
            f"{self.role}: saved {name} ({target.stat().st_size // 1024} KiB)",
            flush=True,
        )
        return target

    def run(self):
        preview = self.stage(
            "preview",
            "/openapi/v2/text-to-3d",
            {
                "mode": "preview",
                "prompt": PROMPTS[self.role],
                "ai_model": "meshy-6",
                "topology": "triangle",
                "target_polycount": 20000,
                "should_remesh": True,
                "pose_mode": "t-pose",
                "target_formats": ["glb"],
            },
        )
        self.download(preview["model_urls"]["glb"], "preview.glb")
        if preview.get("thumbnail_url"):
            self.download(preview["thumbnail_url"], "thumbnail.png")
        refined = self.stage(
            "refine",
            "/openapi/v2/text-to-3d",
            {
                "mode": "refine",
                "preview_task_id": self.meta["stages"]["preview"]["task_id"],
                "enable_pbr": True,
                "ai_model": "meshy-6",
                "remove_lighting": True,
            },
        )
        self.download(refined["model_urls"]["glb"], "refined.glb")
        if refined.get("thumbnail_url"):
            self.download(refined["thumbnail_url"], "refined_thumbnail.png")
        if refined.get("face_count", preview.get("face_count", 20000)) > 300000:
            raise ValueError("Rigging face budget exceeded")
        rigged = self.stage(
            "rig",
            "/openapi/v1/rigging",
            {
                "input_task_id": self.meta["stages"]["refine"]["task_id"],
                "height_meters": 1.78 if self.role == "physician" else 1.70,
            },
        )
        result = rigged["result"]
        rig_path = self.download(result["rigged_character_glb_url"], "rigged.glb")
        destination = ROOT / "assets" / "models" / self.role
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(rig_path, destination / "character.glb")
        for key, url in result.get("basic_animations", {}).items():
            if key.endswith("_glb_url") and "armature" not in key and url:
                filename = (
                    re.sub(r"[^a-z0-9_]", "", key.removesuffix("_glb_url")) + ".glb"
                )
                source = self.download(url, filename)
                shutil.copy2(source, destination / filename)
        print(f"COMPLETE {self.role}: {destination}", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", type=Path, required=True)
    parser.add_argument("--role", choices=list(PROMPTS), required=True)
    parser.add_argument("--resume", type=Path)
    args = parser.parse_args()
    if args.env_file.resolve().is_relative_to(ROOT):
        raise SystemExit(
            "Credentials must be supplied from outside the game repository"
        )
    config = dotenv_values(args.env_file)
    key = config.get("MESHY_API_TOKEN") or config.get("MESHY_API_KEY")
    if not key:
        raise SystemExit("No Meshy credential in the supplied environment file")
    pipeline = Pipeline(args.role, key, args.resume)
    pipeline.run()
    folders = ROOT / "meshy_output"
    projects = [
        json.loads(path.read_text(encoding="utf-8"))
        for path in folders.glob("*/metadata.json")
    ]
    (folders / "history.json").write_text(
        json.dumps({"version": 1, "projects": projects}, indent=2), encoding="utf-8"
    )
    print(
        "Remaining balance:", pipeline.request("GET", "/openapi/v1/balance")["balance"]
    )


if __name__ == "__main__":
    main()
