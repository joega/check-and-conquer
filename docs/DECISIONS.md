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

**Status:** Accepted  
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
**Decision:** Keep right-drag orbit and mouse-wheel inspection, but snap to a mirrored three-quarter board view after each committed move. White's default view looks from rank one toward Black; Black's mirrors it from rank eight. Close zoom smoothly raises its focal point to the character face level.
**Reason:** A free-orbit-only camera can leave the player viewing the board from an unhelpful angle, while a floor-centered close zoom obscures the character models. The turn-aware framing presents the relevant side and keeps close character inspection usable.
**Consequences:** `BoardCameraController` owns default side framing; `GameScreen` requests it after restart, undo, and move presentation. Capture camera transforms still restore first, then the normal board view snaps for the next decision.

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
