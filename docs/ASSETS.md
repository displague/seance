# Asset provenance

All manor geometry, UI ornament, shaders, sound synthesis, narrative, and code were created for this project. No Sunrise game assets or source code are included.

## Lord Ashwood portrait

`assets/art/lord_ashwood.png` was generated with the built-in image generation tool on 2026-09-05. It is used as a framed in-world painting.

Prompt: Original oil portrait texture for a gothic 3D social-deduction game: deceased Victorian occultist Lord Edmund Ashwood, gaunt aristocratic man about 65, swept-back silver hair, dark high-collared frock coat, faded oxblood waistcoat, gold signet ring, hand on a closed occult book. Traditional oil painting with fine canvas grain, cracked varnish and impasto highlights. Centered waist-up subject, vertical 2:3 composition. Nearly black forest-green background, ochre candlelight on half his face. Restrained umber, ivory, brass and charcoal. No frame, lettering, signature or watermark.

UI typography uses installed system fonts (Garamond/Georgia and Segoe UI) with Godot's built-in fallback; no proprietary font files are redistributed.

Godot is MIT licensed: https://godotengine.org/license/

## Rigged character bases

Generated on 2026-09-06 using Meshy 6, with the meshy-3d-generation skill's
preview → PBR refine → rig workflow. The skill guided task-ID persistence,
credit confirmation, polling, and download provenance. Credentials were read
from the explicitly supplied external Sunrise env file; no secrets were copied.

| Base | Preview task | Refine task | Rig task |
| --- | --- | --- | --- |
| Physician | `01a07458-4ec3-708b-a44b-8eee87942135` | `01a07459-6e7b-7392-b04e-08cfdb7d79b5` | `01a0745a-eb18-77b7-a95c-622688d37e6f` |
| Medium | `01a0745b-8aa8-72b2-a60a-c38bb8815110` | `01a0745d-5961-73fd-ad07-b008c83d5902` | `01a0745f-4bbc-7428-9716-4d235aa86d6a` |

Recorded actual charge: 20 preview + 10 refine + 5 rig per base, **70 credits total**.
The final balance reported by the completed pipeline was 947 credits; this is a
historical receipt, not a live account balance. No additional animation purchase
was made. The rig response supplied **walking and running**, not seven verified clips.

Runtime files are `assets/models/{medium,physician}/{character,walking,running}.glb`.
Both bases have 24 bones. Native CharacterMotion attaches the matching locomotion
clips, removes horizontal root motion, and derives a relaxed idle pose. The physician
base represents the three male roles; the medium base represents the three female
roles. The Ghost uses an original spectral shader. These are shared prototype
representations, not six unique final character assets.

Prompts and paid pipeline records are retained in:

- `tools/generate_characters.py` (exact original prompts and request settings).
- `meshy_output/20260906_013220_physician/metadata.json`.
- `meshy_output/20260906_013552_medium/metadata.json`.
- `meshy_output/history.json`.

Raw metadata, signed download URLs, intermediate models, and local engine binaries
are ignored by Git and excluded from the PCK. The public task IDs above preserve
provenance without distributing the full service response.

The female prompt requested trousers, but the generated result has a long skirt.
That result was inspected and retained for this prototype; clothing deformation,
hands, and six distinct character designs need a production art pass.

To resume a known task without intentionally buying another generation:

```powershell
..\sunrise\.venv\Scripts\python.exe tools/generate_characters.py `
  --env-file ..\sunrise\.env --role physician `
  --resume meshy_output/20260906_013220_physician
```

Do not remove `--resume` unless a new paid generation is intended. If a POST fails
before a task ID is returned, check the service task history before trying again.
The game never runs this tool. No Trellis, Lyria, or Blender-generated asset was used.

## Boot splash

`assets/art/boot_splash.png` is a 1600×900 PNG rendered by the project's offline
`tools/render_splash.gd`, using the original eye mark and installed Garamond/Segoe UI
fonts. It uses the same dark green, ivory, and brass palette as the game menu. No
new image-generation task, font-file redistribution, or paid asset purchase was used.

Regenerate with the graphical renderer:

```powershell
.\tools\godot\Godot_console.exe --path . --script res://tools/render_splash.gd
```

The boot image is loaded directly as PNG, before texture imports. Settings live under
`[application]` in `project.godot`: aspect-preserving stretching, linear filtering,
matching letterbox color, and an 800 ms minimum display time. `fullsize=true` is the
legacy 4.6 setting; `stretch_mode=1` is the 4.7 setting documented in the supplied
local `classes/class_projectsettings.rst` and `classes/class_renderingserver.rst`.

## Engine notices

`tools/build.ps1` generates `build/GODOT-NOTICES.txt` directly from the bundled
engine's license and third-party copyright information. Keep it with any shared
development bundle. Review asset-service account terms and platform provenance
requirements before a commercial release; this document does not assert clearance.
