"""Publish selected Meshy provenance without secrets or signed download URLs."""

import hashlib
import json
from pathlib import Path

from generate_roster import ROSTER

ROOT = Path(__file__).resolve().parents[1]


def main():
    records = []
    for role in ROSTER:
        folder = ROOT / "meshy_output" / ("roster_v2_" + role)
        metadata = json.loads((folder / "metadata.json").read_text(encoding="utf-8"))
        tasks = {}
        for stage in ("preview", "refine", "rig"):
            item = metadata["stages"][stage]
            if item["result"]["status"] != "SUCCEEDED":
                raise ValueError(f"Incomplete paid stage: {role}/{stage}")
            tasks[stage] = item["task_id"]
        destination = ROOT / "assets" / "models" / "roster" / role
        hashes = {}
        for name in ("character.glb", "locomotion.res"):
            hashes[name] = hashlib.sha256((destination / name).read_bytes()).hexdigest()
        records.append(
            {
                "role": role,
                "model": metadata["ai_model"],
                "prompt": metadata["prompt"],
                "triangles_before_rig": metadata["faces"],
                "height_meters": metadata["height_meters"],
                "paid_tasks": tasks,
                "estimated_credits": metadata["estimated_credits"],
                "sha256": hashes,
            }
        )
    manifest = ROOT / "assets" / "models" / "roster" / "provenance.json"
    manifest.write_text(
        json.dumps({"profile": "roster_v2", "characters": records}, indent=2) + "\n",
        encoding="utf-8",
    )
    # Consolidate history only after the parallel generators have all finished.
    history_path = ROOT / "meshy_output" / "history.json"
    history = (
        json.loads(history_path.read_text(encoding="utf-8"))
        if history_path.exists()
        else {"version": 1, "projects": []}
    )
    if not isinstance(history, dict) or not isinstance(history.get("projects"), list):
        raise ValueError("Unexpected local history schema; preserve the existing file")
    history["projects"] = [
        entry for entry in history["projects"] if entry.get("profile") != "roster_v2"
    ]
    history["projects"].extend(
        json.loads(
            (ROOT / "meshy_output" / ("roster_v2_" + role) / "metadata.json").read_text(
                encoding="utf-8"
            )
        )
        for role in ROSTER
    )
    history_path.write_text(json.dumps(history, indent=2) + "\n", encoding="utf-8")
    print("PROVENANCE: six completed original characters; no service URLs copied")


if __name__ == "__main__":
    main()
