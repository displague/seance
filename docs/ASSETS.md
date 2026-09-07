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
base represented the three male roles; the medium base represented the three female
roles. The Ghost uses an original spectral shader. These were shared prototype
representations in the initial 0.1 build. The new roster below replaces that shared
mapping; these two rigs remain as free Heritage appearance options.

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

## Six-character Meshy 7 Ultra roster

Generated on 2026-09-06 with explicit user authorization to use existing Meshy credits.
Original text prompts are frozen in `tools/generate_roster.py` and the sanitized
`assets/models/roster/provenance.json`. The latter records SHA-256 hashes, verified
triangle counts, height requests and completed paid task IDs. No community model
was downloaded; the user-linked Ornate Green Gown by kaesar3d was a style reference.

| Role | Preview task | Refine task | Rig task | Triangles before rig |
| --- | --- | --- | --- | ---: |
| Widow | 01a07828-9cf8-76fa-bed4-f05faed46d2c | 01a0782a-3218-74ff-a9c0-4f1ae4340f5e | 01a0782b-b006-77bd-89ee-f7e5107d97d7 | 67,539 |
| Ghost | 01a0782d-7f4c-731e-a73f-c0e9a65a3039 | 01a0782f-3aae-7289-9640-7504d663edfe | 01a07831-2d7b-73f7-a4f1-adba66f76ae7 | 66,708 |
| Medium | 01a0782d-a7d6-7344-a0ef-dbf8cb914762 | 01a0782f-75b0-76e5-8230-646e401d14a6 | 01a07831-68d2-7116-ad75-39b64485877a | 66,203 |
| Heir | 01a0782d-d081-73c7-9c84-2991a42ef5ea | 01a0782f-65e1-76fc-81c6-365a8360fd11 | 01a07831-58ca-7114-aa20-de6206ca64eb | 65,950 |
| Physician | 01a0782d-f93a-778e-a070-9a862fc24e2c | 01a0782f-7a66-7451-a4ea-331b4c694c90 | 01a07831-abe7-752d-a2c9-87f3b7113d45 | 66,384 |
| Housekeeper | 01a0782e-21b0-7792-ac57-27db3e116606 | 01a0782f-ef7a-757e-8037-38789c07ac7a | 01a07831-a919-727e-8584-a55300ce2c3c | 66,001 |

Requested Meshy 7 Ultra, 65,000-triangle remesh, T pose and 4K PBR refinement.
Charges: 25 preview + 10 refine + 5 rig = 40 per character, **240 total**.
Balance verified after all six finished: **707**, down from 947. This is a historical
receipt, not a continually refreshed account balance. Walk and run were included;
no additional animation was purchased. All eight selectable rigs have 24 bones.

Runtime uses `assets/models/roster/<role>/character.glb` and `locomotion.res`.
`tools/bake_roster.gd` extracts only the animation tracks, eliminating repeated
4K textures in walk/run GLBs from the runtime package. Original service files and
complete responses remain in ignored `meshy_output/roster_v2_<role>/`. Intermediate
walk/run copies beside the model are ignored and excluded from export.

All six outputs were inspected in Godot's rendered portrait sheet. Generation did
not reliably follow separated-leg/T-pose directions: the widow's gown trails, and
some idle hands/poses and garment deformation remain unsuitable for a retail skin.
The higher triangle count alone does not make these production-quality AAA assets.

Offline regeneration sequence (the generator resumes the same stored task IDs):

```powershell
..\sunrise\.venv\Scripts\python.exe tools/generate_roster.py --env-file ..\sunrise\.env --role widow
.\tools\godot\Godot_console.exe --headless --path . --editor --import --quit
.\tools\godot\Godot_console.exe --headless --path . --script res://tools/bake_roster.gd
..\sunrise\.venv\Scripts\python.exe tools/record_roster.py
```

Only create missing roles when a new paid task is intended. Never retry an uncertain
POST without checking task history. The Meshy skill supplied the resumable pipeline,
geometry-budget verification and task provenance; Sunrise assets were not modified.

## Original adaptive score and effects

`tools/compose_score.py` deterministically composes three synchronized 32-second
stereo WAV stems (bowed harmonic bed, felt-piano-style notes, glass/bass tension) plus
wind and thunder, using oscillators and seeded noise. No sampled commercial music,
Suno track, Lyria call or paid audio generation was used. Python/NumPy is offline only;
`scripts/music.gd` performs native crossfading, voice ducking and volume control.

Brooch geometry, spirit illumination and the animated weeping-wall shader are
original code-native assets. They do not use external image assets. Blood versus
slime changes presentation only, and reduced flashes suppress the lightning pulse.

## Engine notices

`tools/build.ps1` generates `build/GODOT-NOTICES.txt` directly from the bundled
engine's license and third-party copyright information. Keep it with any shared
development bundle. Review asset-service account terms and platform provenance
requirements before a commercial release; this document does not assert clearance.

## Optional local NPC speech — development only

Added 2026-09-06. Authored character dialogue/personas are original project text in
`scripts/npc_data.gd`; free responses are generated by the user's local LM Studio
model. No paid speech API, cloned user voice, or Sunrise runtime is used.

Native helpers and voice weights are separate optional downloads under ignored
`tools/ai`; they are **not included in Seance.pck or committed as original assets**.
`tools/setup-solo-ai.ps1` records each upstream voice MODEL_CARD beside the ONNX and
configuration. It may copy cached weights from Sunrise read-only. Runtime Piper
generates transient WAVs; integration-test clips are ignored `artifacts/npc-*.wav`.

| Role | Piper model | Dataset licence statement in downloaded card |
| --- | --- | --- |
| Medium | en_US-lessac-medium | Links to Lessac Blizzard 2013 terms; review required |
| Julian | en_US-joe-medium | CC0 dataset; fine-tuned from Lessac |
| Lenore | en_US-amy-medium | Refers to mimic3-voices; review required |
| Blackwell | en_GB-alan-medium | Refers to mimic3 apope_low; review required |
| Iris | en_US-ljspeech-medium | Public-domain LJ Speech dataset |
| Edmund | en_US-danny-low | Refers to mimic3-voices; fine-tuned from Ryan low; review required |

Cards describe datasets/training lineage, not a blanket clearance of model weights,
speaker rights or generated output. Complete commercial redistribution review or
replace these development voices with commissioned/licensed performances before
shipping. The initially considered `en_US-ryan-high` had a noncommercial dataset
licence and was replaced in the active cast by Joe; any unused local cached copy
is not referenced or packaged. No assertion is made that all remaining voice rights
are cleared.

Voice ONNX SHA-256 receipts:

```text
lessac 5EFE09E69902187827AF646E1A6E9D269DEE769F9877D17B16B1B46EEAAF019F
joe    58AFCE0321B8D9C46D7CDF9C16500CC55A793B4220212DBA6B70FB788B3BAF06
amy    B3A6E47B57B8C7FBE6A0CE2518161A50F59A9CDD8A50835C02CB02BDD6206C18
alan   0A309668932205E762801F1EFC2736CD4B0120329622ADF62BE09E56339D3330
ljspeech 6F52A751E2349ABE7A76735EB09DC1875298C77EA2342FFD2FEF79FF81B87F22
danny  56A9AE9499E961514F060AAC2866CB323A21E5989592FC4F208E56FDC323AB64
piper.exe 96F3DA3811151580073E40BB4DD20EB0FB8115F5F5F76E2FB54282B3EDFA5C1F
whisper-server.exe 9EB6EE297215F07BA77A6D588A6A2715F2235F665528529C377B775BBAB3CD2D
ggml-base.en.bin A03779C86DF3323075F5E796CB2CE5029F00EC8869EEE3FDFB897AFE36C6D002
```

Sources: [Piper Windows release 2023.11.14-2](https://github.com/rhasspy/piper/releases/tag/2023.11.14-2),
[Piper voice models and cards](https://huggingface.co/rhasspy/piper-voices/tree/main),
[whisper.cpp](https://github.com/ggml-org/whisper.cpp), and
[English base speech model](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-base.en.bin).
The installed whisper.cpp Windows archive reported release `b4938`. Binary/library
notices and voice/model terms must accompany any eventual redistributed helper pack;
the current portable bundle intentionally excludes them.
