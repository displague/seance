# Appearance and a fair cosmetic economy

## Product boundary

Every role, ability, clue, ritual, task, possession channel and environmental effect
is gameplay, and is available without cosmetic purchases. No purchased item changes
scores, movement, visibility permissions, cooldowns, voice filtering or evidence.
Blood/slime and reduced-flash preferences are free accessibility/presentation settings.

The intended commercial model is a mix of included looks, gameplay-earned cosmetics,
and optional premium outfits. A permanent story-chapter reward track is a possible
future presentation, not a live battle pass. No store, checkout, paid currency,
real-money pricing, subscription, loot box or premium entitlement has been implemented.

## Implemented in this prototype

- Six distinct free Ashwood base models, one per role.
- Two additional free Heritage models: Medium and Physician (the original rigs).
- A free silver brooch for each role. The gold brooch is an earned cosmetic.
- Local Remembrance: 20 per completed sitting plus 2 per score point, capped at
  50 per sitting. The gold brooch unlock costs 60 and applies to all roles.
- Per-role outfit and brooch preferences, stored in `user://wardrobe.cfg`.
  Saving preferences does not save an unfinished case.
- The host selects the assigned role's preference, not merely the requested role's
  preference, when a requested seat is occupied. Snapshots contain only allowlisted
  public appearance IDs, not account balances or the player's unused preferences.
- World models, guest-list portraits and character-detail portraits use the same
  avatar builder and snapshot. Equipment changes apply at the next sitting.

Remembrance is deliberately a **local prototype economy**. Local profiles and peer
hosts can be modified; neither is trustworthy proof of a purchase. Final-score
receipts prevent ordinary duplicate snapshot awards, not adversarial farming or
account fraud. A commercial version requires authenticated accounts, server-owned
entitlements and reward ledgers, verified platform purchase receipts, idempotent
grants, refund/revocation handling, and an offline ownership policy before payment UI
is enabled. Never reuse the peer's cosmetic claim as a paid-entitlement verifier.

## Appearance direction

The current selection is curated complete models, not independent skin/hair/eye
sliders. The generated assets contain a single shared PBR material, including face,
hair and clothing. Global recoloring would also discolor garments or skin. Reliable
parameter controls require authored material regions/masks, a stable skeleton,
matching portrait rendering, and deformation QA for each supported combination.

Add new faces, hairstyles and garment variants to the catalog by stable IDs. Do not
accept client-provided resource paths, shaders, arbitrary tint values or scales.
Base human skin/eye/hair choices, if added, should be available as identity options;
premium items can be elaborate authored garments and accessories. Cosmetic variants
must retain role recognition and comparable silhouettes/contrast. The ghost keeps
the same gameplay illumination regardless of its cosmetic appearance.

The Meshy source prompts request rig-friendly separated limbs, but not every output
obeyed: the widow has a trailing gown, and several idle hand poses need refinement.
These assets need an art/rigging pass before selling any outfit. They are not a
claim that paid skin inventory or production-quality character animation is ready.
