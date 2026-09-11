# Architecture Decision Log

Do not silently reverse decisions. Add a dated entry explaining evidence and consequences.

## ADR-001 — Godot for V1

**Status:** Accepted  
**Decision:** Use Godot 4.x latest stable for desktop V1.  
**Reason:** Integrated 3D skeletal animation, retargeting, AnimationTree, cameras, VFX/audio, editor/debug scenes, and packaging make the character-animation problem substantially easier than a browser-first stack.

## ADR-002 — Do not fork En Croissant

**Status:** Accepted  
**Decision:** Build a purpose-specific game. Use En Croissant only as conceptual/reference material when useful.  
**Reason:** Its database/training/import/analysis surface is unnecessary for the product and would create coupling and licensing/maintenance complexity.

## ADR-003 — Stockfish as separate UCI process

**Status:** Accepted  
**Decision:** Launch official Stockfish executable and communicate over stdin/stdout using UCI.  
**Reason:** Clean separation, standard integration path, straightforward process supervision, and clearer GPL boundary.

## ADR-004 — Chess domain independent from Stockfish

**Status:** Accepted  
**Decision:** The application owns legal move generation and complete game state.  
**Reason:** UI needs legal destinations and deterministic state even when Stockfish is absent/crashed; engine should be opponent/evaluator only.

## ADR-005 — Domain state authoritative

**Status:** Accepted  
**Decision:** Chess outcome is committed/known before animation and presentation cannot alter it.  
**Reason:** Combat is theater. Visual failure must not corrupt game correctness.

## ADR-006 — In-place animation default

**Status:** Accepted  
**Decision:** Move PieceActor roots through code and use in-place skeletal clips for V1.  
**Reason:** Exact board-square placement and reusable staging outweigh root-motion realism at this stage.

## ADR-007 — Quaternius-first prototype asset ecosystem

**Status:** Accepted, pending first import validation  
**Decision:** Prove M1 using compatible Quaternius CC0 humanoid/fantasy/animation packs before adding other asset ecosystems.  
**Reason:** Consistent rig + permissive license + existing Godot/retargeting orientation reduce unknowns.

## ADR-008 — Generic captures before signature kills

**Status:** Accepted  
**Decision:** Every attacker must have a fallback capture against every victim before any requirement for 36 unique matchup movies.  
**Reason:** Prevents content workload from blocking a complete game.

## ADR-009 — Working title only

**Status:** Superseded by ADR-012
**Decision:** Use “Project Warboard” internally until naming/product review.  
**Reason:** Avoid treating an existing game title/identity as ours.

## ADR-010 — Bootstrap engine and renderer

**Status:** Accepted
**Date:** 2026-09-10
**Decision:** Pin the initial project to Godot 4.7.2 stable and use the Compatibility renderer for the bootstrap and prototype scenes.
**Reason:** 4.7.2 was the latest stable Godot 4 release at project bootstrap, and it is installed on the Linux development machine. The Compatibility renderer keeps the earliest debug scenes broadly runnable while M1 validates the asset pipeline; renderer choice can be revisited with measured visual requirements.
**Consequences:** `project.godot` declares Godot 4.7 features and the Compatibility renderer. Production quality tuning is deferred until imported character assets can be tested.

## ADR-011 — Turn-aware default board camera

**Status:** Accepted
**Date:** 2026-09-10
**Decision:** Keep right-drag orbit, middle-drag pan, and mouse-wheel inspection, but snap quiet moves to the human player’s board side. White's tuned default is tilt +33°, spin +180°, zoom 34 m, and pan (0, 0); choosing Black mirrors it from rank eight. Close zoom smoothly raises its focal point to the character face level.
**Reason:** A free-orbit-only camera can leave the player viewing the board from an unhelpful angle, while a floor-centered close zoom obscures the character models. Keeping Stockfish on the far side lets the human read the board from one stable perspective.
**Consequences:** `BoardCameraController` owns default side framing; `GameScreen` requests the selected player side after restart, undo, review, and quiet move presentation. A capture retains the player's current camera transform through the death beat, preserving the tactical board context and avoiding a camera zoom or reset.

## ADR-012 — Provisional public name: Warboard

**Status:** Superseded by ADR-013
**Date:** 2026-09-10
**Decision:** Present the game as “Warboard” in its runtime title, main menu, and public README. Keep the longer “Project Warboard” phrase only in historical/internal planning material.
**Reason:** The public repository and player-facing materials need one consistent name, while the original working-title policy remains preserved in the decision record.
**Consequences:** The Godot application name and main menu read “Warboard.” This is a provisional product identity and does not replace a jurisdiction-specific trademark review before commercial release.

## ADR-013 — Retire the Warboard shipping title

**Status:** Accepted  
**Date:** 2026-09-10  
**Decision:** Do not use “Warboard” as the shipping title. Keep it only as the temporary repository/development codename until a replacement is selected, then rename player-facing identity and release metadata together.  
**Reason:** A separately developed chess/strategy game is already publicly listed on Steam under the identical title, with a public demo and planned 2027 release. The overlap is close enough to create avoidable player confusion and product-identity risk.  
**Evidence:** [Warboard on Steam](https://store.steampowered.com/app/4445900/Warboard/) (IBELF Studios; accessed 2026-09-10).  
**Consequences:** The remaining shipping-title acceptance item is blocked on selecting and clearing a replacement. A preliminary web search is not trademark clearance; a chosen name still requires jurisdiction-appropriate review before commercial release.

## Pending decisions

Record after M1 evidence:

- exact Godot stable version pinned,
- renderer selection,
- canonical actor forward axis,
- canonical character scale,
- exact Quaternius files used,
- testing framework/plugin,
- project source license,
- binary packaging strategy for Stockfish per platform.

## ADR-014 — Provisional public name: Warchessed

**Status:** Accepted
**Date:** 2026-09-10
**Decision:** Present the game as “Warchessed” in the runtime title, main menu, Linux package name, and public README. Retain `warboard` only in the repository URL, historic records, and legacy settings migration.
**Reason:** The name immediately communicates animated combat chess and is more distinctive than a generic fantasy title. An exact-term preliminary web search on 2026-09-10 returned no public game or trademark results.
**Consequences:** Existing `user://warboard_settings.cfg` values load when no `user://warchessed_settings.cfg` exists, and subsequent saves use the new path. This preliminary screen is not trademark clearance; jurisdiction-appropriate review is still required before commercial release.

## ADR-015 — Campaign arenas are presentation skins over standard chess

**Status:** Accepted
**Date:** 2026-09-11
**Decision:** Introduce a sequential five-location campaign with Mountain Fortress Terrace as its first arena, followed by Arcane Sky Citadel, Frozen Keep, Lava Forge, and the final Forest Ruins. Keep campaign progress in a pure game-layer object and keep arena identity in presentation/session state.
**Reason:** Multiple locations create a strong long-term progression structure without allowing visual scenes to affect authoritative chess. A reusable grand-arena frame also prevents each new location from re-solving camera, board, and combat staging.
**Consequences:** Wins only unlock the next arena after an authoritative human checkmate. Each arena supplies original panorama art, lighting, a physical local terrace ring, and themed markers through `ArenaCatalog`; chess position, Stockfish, piece coordinates, and capture choreography remain shared.

## ADR-016 — Procedural arena audio and per-character stance variation

**Status:** Accepted
**Date:** 2026-09-11
**Decision:** Use original runtime-synthesized looping music profiles for each arena, weapon-family procedural effects for combat, and deterministic actor-specific idle stance selection from the licensed animation library.
**Reason:** The demo needs a coherent soundtrack and readable weapon feedback now, without acquiring unreviewed audio packs or coupling audio choices to chess logic. Per-character stance phase and gesture variation removes the mechanical synchronized idle that made the board look staged.
**Consequences:** `ArenaAudioDirector` is presentation-only and derives only from arena ID and BattleDirector events. Board landing, bow, arcane, sword, spear, and hammer/wall effects have distinct triggers. `PieceActor` can be rebuilt from state while retaining a deterministic stance choice based on its projected position and identity.
