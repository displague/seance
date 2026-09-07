# Solo with local AI

Implemented on 2026-09-06. This is a native GDScript prototype, not a production NPC
agent framework. The normal authored rehearsal remains independent of all helpers.

## Play on this machine

1. Leave LM Studio's local server running on port **1234**, with LFM2.5-2.6B or
   Granite 4.1-3B available. The game calls `/v1/models` and `/v1/chat/completions`.
2. Start `PLAY.cmd`, choose **Solo with local AI…**, check models and select one.
3. Optionally enable NPC voices and/or microphone transcription. Both default off.
4. Choose a role and begin. Inspect a guest with E, or open their journal details.
   Type a question and Send, or use the authored actions beside the conversation.
5. To speak, hold V/LB or the Record button, then release. Review and edit the
   transcript before pressing Send. Typing V in a text field does not record.

The Medium is a convenient first role. The Ghost can converse only through legal
listening channels: the Medium at a sitting, or a possessed vessel. NPC interaction
never impersonates a seat controlled by a human.

The dossier and Estate Guide show all three chapter openings. The register unseals
in investigation 2; the reliquary unseals in investigation 3. Inspect the register to
the reliquary's left in the Memorial Chapel. If Iris collected it, ask for puzzle
help or what she has found before requesting a disclosure. Collected documents stay
open with their full text; the puzzle can also link back to your recovered register.
A wrong answer leaves the puzzle panel open.

## Optional speech setup

The native helpers and six voice models are installed in ignored `tools/ai` on this
development machine. Reproduce the setup with:

```powershell
.\tools\setup-solo-ai.ps1 -InstallVoice -Start
```

This downloads native Windows Piper and whisper.cpp binaries, six Piper voices and
the English whisper.cpp base model. It may copy matching cached voice weights from
Sunrise read-only. It does not install Python or download an LLM. Review upstream
binary/voice licences before redistribution; see [asset provenance](ASSETS.md).

`-Start` starts only whisper.cpp on **127.0.0.1:8179**, in a hidden helper window,
if that port has no listener. Start LM Studio separately. The transcription service
remains running after the game exits; it is not a Windows service. To stop the helper
later, identify its exact process by that listening port and executable first.

The portable PCK does not include the helper binaries or weights. Beside this source
checkout it can find `../tools/ai`. For a separate installation, set
`SEANCE_AI_HELPERS` to the directory containing `piper/`, `voices/`, and the other
helper files. Native voice output launches Piper for each line; no Python process
is used. Offline text play does not require these files.

## What changes the game

- Guests have six separate authored identities, histories, manners and motives.
- In both solo modes, living NPCs walk to objects they value and collect them through the
  same rules as a player. The physician competes for his ledger; the heir seeks
  the signet and testament. New chapters reset their goal pass and unseal new
  opportunities; patrol/reconsideration continues after the initial plan is complete.
  The policy runs during investigation, not during séances or while reading a solo panel.
- Ask what a guest has found before asking for a specific privately held clue.
  Inheritance claims are already public. Ask about this investigation for their
  current priorities; later chapters introduce lineage and financial pressures.
- Showing evidence teaches that NPC privately. Relevant evidence can change their
  final accusation; some combinations also persuade a guest to reveal a held clue.
- NPCs can refuse a requested goal object, give an unwanted object, or propose an
  exchange for something they value. A trade requires explicit player acceptance
  and rechecks both owners before transferring anything.
- Lenore can be asked to give the locket to Iris. An eligible beneficiary holding
  Blackwell's ledger can surrender it in exchange for his heir-vote pledge.
- From the second investigation/sitting, ask a willing guest to examine and publish
  the final audit. It is a real queued errand, not instant testimony: they must reach
  the Conservatory during investigation three. The Ghost can ask through the Medium
  at sitting two or a possessed vessel during investigation three. Blackwell will
  not agree to expose his own audit, and no errand is offered after investigation ends.
- Repeating flattering lines does not farm trust or points. General AI conversation
  supplies character expression; only validated actions change game state.

This is bounded negotiation, not arbitrary player-written contracts or unrestricted
agent planning. Some motives still depend on other characters' choices and may be
unreachable in a particular solo sitting. NPC conversations are private and can be
opened through the journal without a distance check in this prototype.

## Knowledge, model output and consent

Sunrise's NPC/voice and knowledge-gating guidance informed the separation between
identity, accessible knowledge, actions and speech. No Sunrise runtime was copied
into a Python dependency and that checkout was not modified.

`NpcRules.context` exposes the NPC's authored public testimony, current permitted
options, the last 12 entries in that private conversation, and evidence both parties
already know. It does not send the entire case state, private ballot table, hidden
case solution, or other guests' conversations. History is bounded to 24 entries per
pair; there is no persistent cross-game memory or retrieval service.

The model selects a JSON-schema-constrained option or returns free speech. Every
option is revalidated against the current authoritative state. An actionable reply
uses the exact authored result after execution; accompanying model prose is discarded.
Gift, acceptance, showing private evidence and costly political deals are excluded
from the model's executable choices, so it cannot spend or disclose on the player's
behalf. Free generated speech is labelled **AI dialogue; not evidence**. It can still
hallucinate; these boundaries prevent mechanical rewards, not every misleading line.

Only HTTP loopback endpoints ending in `/v1` are accepted, with redirects disabled.
Requests are bounded in size and time. AI and speech opt-ins reset for a new launch;
only endpoint/model preferences persist. Opening ordinary menus does not contact
an LLM. Entering the AI setup explicitly checks the local model list.

Leaving, changing conversation target or cancelling invalidates pending replies.
Late replies cannot mutate another session. Model-probe and transcription callbacks
also carry generation tokens so old completions cannot cancel newer requests.
Unavailable servers and invalid model output leave authored actions usable.

## Audio and privacy

Each role has a different local Piper voice; the Ghost uses the game's spectral
filter. No voice cloning was performed. TTS writes a short-lived local WAV for
playback and removes that clip on completion/cancellation. Forced process termination
may leave a temporary clip in the OS cache; no recorded microphone file is created.

The microphone stream is created only for an explicitly enabled push-to-talk take.
Focus loss, cancellation, release or the 20-second limit closes capture before any
transcription request. A bounded 16 kHz mono buffer goes only to the local whisper.cpp
endpoint. The returned text is editable and never auto-sent to the NPC. Closing the
panel cancels pending speech work. LM Studio may keep its own request logs according
to its settings; the game does not control those external retention settings.

## Reproducible checks

The default `tools/check.ps1 -Rendered` gate uses no model and opens no microphone.
For explicit integration with the already running local services:

```powershell
.\tools\godot\Godot_console.exe --headless --path . --script res://tests/solo_live_test.gd --log-file artifacts/solo-live-lfm.log -- --live-local --model=lfm2.5-2.6b
.\tools\godot\Godot_console.exe --headless --path . --script res://tests/solo_live_test.gd --log-file artifacts/solo-live-granite.log -- --live-local --model=granite-4.1-3b
```

These tests query six role contexts, generate six actual PCM voice clips, negotiate
and accept an actual trade, request a non-canned personal reply, cancel inference,
and transcribe generated speech. They never open a physical microphone. Generated
QA clips and logs live under ignored `artifacts/`; they are not packaged assets.
Model behavior is stochastic: a passing receipt is not a general reliability claim.

Technical references: [LM Studio chat endpoint](https://lmstudio.ai/docs/developer/openai-compat/chat-completions),
[LFM model card](https://huggingface.co/LiquidAI/LFM2.5-2.6B),
[native Piper release](https://github.com/rhasspy/piper/releases/tag/2023.11.14-2),
and [whisper.cpp server](https://github.com/ggml-org/whisper.cpp/tree/master/examples/server).
