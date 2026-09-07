"""Offline, resumable premium Ashwood roster. No runtime or credential dependency."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from dotenv import dotenv_values

from generate_characters import Pipeline, ROOT

TAIL = (
    " Full body, strict T pose, open empty hands away from torso, feet apart. "
    "Realistic adult proportions, detailed Gothic period game character. "
    "No props, no base, no scenery, no cape."
)
ROSTER = {
    "ghost": (
        1.83,
        "An elderly wealthy English occultist, gaunt angular face, swept silver hair, "
        "neat pointed beard, embroidered midnight blue velvet smoking jacket with gold "
        "celestial motifs, antique waistcoat, narrow charcoal trousers and polished boots. "
        "Regal tragic bearing. Solid living human, not transparent.",
    ),
    "medium": (
        1.70,
        "A 36 year old female spiritualist, thoughtful pale oval face, dark auburn "
        "hair in an elaborate braided bun. Fitted deep petrol teal high-neck brocade "
        "jacket, embroidered silver moons, lace cuffs, ivory blouse, tailored ankle "
        "length divided riding skirt with clearly separated trouser legs and black boots.",
    ),
    "heir": (
        1.81,
        "A handsome 28 year old male aristocratic heir, olive complexion, slick dark "
        "side-parted hair, clean shaven, confident sharp face. Elegant oxblood and black "
        "three piece pinstripe suit, double breasted waistcoat, ivory silk cravat, small "
        "gold watch chain across waistcoat, narrow tailored trousers, polished oxford shoes.",
    ),
    "widow": (
        1.74,
        "A dignified 48 year old woman, warm brown complexion, high cheekbones, "
        "black hair in sculpted updo. Ornate emerald and black brocade mourning gown, "
        "fitted high collar bodice, gold botanical embroidery, structured split overskirt "
        "ending at knees over separate black fitted trouser legs, lace cuffs, heeled boots. "
        "Rich couture fabric, no trailing cloth.",
    ),
    "doctor": (
        1.78,
        "A stern 57 year old male Victorian physician, long narrow weathered face, "
        "receding salt and pepper hair, trimmed grey moustache. Detailed charcoal wool "
        "frock jacket ending at hips, burgundy jacquard waistcoat, brass buttons, ivory "
        "high collar shirt, black tie, fitted dark trousers, worn leather ankle boots.",
    ),
    "keeper": (
        1.65,
        "A capable 32 year old female housekeeper, freckled fair skin, round kind "
        "face, copper red hair in a neat low bun. Navy blue fitted wool working dress "
        "ending above knees with ivory linen apron and lace collar, separate dark "
        "stocking covered legs, practical worn leather boots. Fine woven fabric and seams.",
    ),
}


def generate(role: str, key: str, resume: Path | None) -> None:
    height, description = ROSTER[role]
    folder = resume or ROOT / "meshy_output" / ("roster_v2_" + role)
    # Pipeline's initial prompt is superseded before it submits a task. Existing
    # raw downloads and task IDs remain in their own stable, resumable directory.
    pipeline = Pipeline("medium", key, folder)
    pipeline.role = role
    profile = {
        "role": role,
        "prompt": description + TAIL,
        "profile": "roster_v2",
        "estimated_credits": 40,
        "ai_model": "meshy-7",
        "height_meters": height,
    }
    if pipeline.meta.get("profile") == "roster_v2":
        if any(pipeline.meta.get(key) != value for key, value in profile.items()):
            raise ValueError(
                "Stored task provenance differs; do not change paid prompts on resume"
            )
    else:
        if pipeline.meta.get("stages"):
            raise ValueError(
                "Resume directory belongs to a different generation profile"
            )
        pipeline.meta.update(profile)
    pipeline.persist()
    preview = pipeline.stage(
        "preview",
        "/openapi/v2/text-to-3d",
        {
            "mode": "preview",
            "prompt": pipeline.meta["prompt"],
            "ai_model": "meshy-7",
            "ultra_mode": True,
            "should_remesh": True,
            "target_polycount": 65000,
            "topology": "triangle",
            "pose_mode": "t-pose",
            "target_formats": ["glb"],
        },
    )
    pipeline.download(preview["model_urls"]["glb"], "preview.glb")
    if preview.get("thumbnail_url"):
        pipeline.download(preview["thumbnail_url"], "preview.png")
    refined = pipeline.stage(
        "refine",
        "/openapi/v2/text-to-3d",
        {
            "mode": "refine",
            "preview_task_id": preview["id"],
            "enable_pbr": True,
            "ai_model": "meshy-7",
            "texture_resolution": "4k",
            "target_formats": ["glb"],
        },
    )
    pipeline.download(refined["model_urls"]["glb"], "refined.glb")
    if refined.get("thumbnail_url"):
        pipeline.download(refined["thumbnail_url"], "refined.png")
    # Verify the actual GLB index counts, not an absent API field's default.
    import struct

    raw = (folder / "refined.glb").read_bytes()
    chunk_length = struct.unpack_from("<I", raw, 12)[0]
    document = json.loads(raw[20 : 20 + chunk_length])
    faces = sum(
        document["accessors"][p["indices"]]["count"] // 3
        for mesh in document.get("meshes", [])
        for p in mesh["primitives"]
    )
    pipeline.meta["faces"] = faces
    pipeline.persist()
    if not 0 < faces <= 300000:
        raise ValueError("Verified rig face budget must be within 1..300000")
    rig = pipeline.stage(
        "rig",
        "/openapi/v1/rigging",
        {
            "input_task_id": refined["id"],
            "height_meters": height,
        },
    )
    result = rig["result"]
    pipeline.download(result["rigged_character_glb_url"], "character.glb")
    for kind in ("walking", "running"):
        pipeline.download(result["basic_animations"][kind + "_glb_url"], kind + ".glb")
    destination = ROOT / "assets" / "models" / "roster" / role
    destination.mkdir(parents=True, exist_ok=True)
    for name in ("character.glb", "walking.glb", "running.glb"):
        shutil.copy2(folder / name, destination / name)
    print(f"ROSTER COMPLETE: {role}, {faces} faces, {destination}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", type=Path, required=True)
    parser.add_argument("--role", choices=ROSTER, required=True)
    parser.add_argument("--resume", type=Path)
    args = parser.parse_args()
    if args.env_file.resolve().is_relative_to(ROOT):
        raise SystemExit("Use an explicit external credentials path.")
    config = dotenv_values(args.env_file)
    key = config.get("MESHY_API_TOKEN") or config.get("MESHY_API_KEY")
    if not key:
        raise SystemExit("External Meshy credential missing.")
    generate(args.role, key, args.resume)


if __name__ == "__main__":
    main()
