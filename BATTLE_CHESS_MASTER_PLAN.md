# Check & Conquer — Master Project Plan

> **Public title:** Check & Conquer
> **Product concept:** A modern, original 3D chess game inspired by the *idea* of animated combat chess: normal chess rules, but captures trigger character combat sequences.  
> **Primary engine:** Godot 4.x (latest stable at project start)  
> **Chess AI:** Stockfish 19 or latest stable, launched as a separate UCI process  
> **Initial asset strategy:** Quaternius CC0 humanoid characters/outfits + Universal Animation Libraries; Mixamo or other permissively licensed sources only as optional gap-fillers  
> **Implementation philosophy:** Chess state is authoritative. Animation is presentation. Combat never changes chess results.

---

## 0. Executive summary

Build a desktop chess game in which every piece is represented by a 3D character. Legal chess moves are governed by a deterministic chess domain layer. An optional Stockfish process supplies computer moves. When a capture occurs, the normal board transition is staged as a short fight: the attacker approaches a standardized combat anchor, plays an attack animation, the victim plays a hit/death reaction, camera/audio/VFX emphasize impact, and the surviving piece finishes on the destination square.

The project must be built as a sequence of vertical slices. Do **not** begin by making a complete chess application, acquiring dozens of art assets, or authoring custom animations. The first decisive milestone is a tiny Godot scene containing one attacker, one victim, and one button that produces a convincing capture sequence from reusable animations. Once that works, connect the same presentation system to a fully tested chess domain layer and then to Stockfish.

The difficult part is not chess AI. The difficult part is turning inconsistent 3D source assets into a reliable, data-driven presentation pipeline. The architecture below isolates that risk.

---

## 1. Product principles and non-negotiable decisions

These are established decisions. Agents should not reopen them unless implementation evidence shows a material problem.

1. **This is standard chess.** Combat is visual only.
2. **Use Godot, not a browser-first 3D stack, for the initial implementation.** Godot provides skeletal animation, retargeting, state machines, cameras, audio, particles, import tooling, and desktop packaging in one environment.
3. **Do not fork En Croissant for V1.** It is useful architectural reference material but contains far more application surface than this game needs.
4. **Use Stockfish as a separate executable speaking UCI over stdin/stdout.** Do not modify Stockfish.
5. **Implement or adopt a dedicated chess-rules layer separate from Stockfish.** Stockfish is the opponent/evaluator, not the UI legality engine.
6. **Six visual archetypes, not 32 unique models:** Pawn, Knight, Bishop, Rook, Queen, King. White/black are material/outfit variants.
7. **In-place character animation by default.** Move character roots in Godot code/tweens. Avoid depending on imported root motion in V1.
8. **Combat uses standardized anchors.** Choreographies assume known attacker/victim positions, orientations, and distance.
9. **Start with reusable generic attacks and reactions.** Bespoke two-character “signature kills” are a later content phase.
10. **All animation/choreography is data-driven.** No giant `if attacker == KNIGHT and victim == PAWN` code forest.
11. **Original identity only.** Do not copy original *Battle Chess* characters, specific kills, audio, UI, logos, names, or other protectable expression. “Battle Chess” is a descriptive reference in planning, not the shipping name.
12. **Linux desktop is the first development target.** Keep code portable to Windows/macOS and avoid Linux-only game logic.
13. **A playable ugly vertical slice is more valuable than a beautiful incomplete framework.**

---

## 2. Definition of success

### Prototype success

A user can launch the game, start a human-vs-computer match, select a legal piece, make a legal move, see the opponent respond through Stockfish, and see any capture rendered as a staged 3D combat animation without corrupting chess state.

### V1 success

- Full standard chess rules.
- Human vs Stockfish.
- Human vs human on one machine.
- Six recognizable 3D piece archetypes for each side.
- At least one visually coherent generic capture treatment per attacker archetype.
- Multiple victim reactions/deaths chosen deterministically or pseudo-randomly from valid options.
- Camera, sound, and small VFX layer for captures.
- Check, checkmate, stalemate, promotion, castling, and en passant all work.
- Difficulty presets that weaken Stockfish using supported UCI mechanisms.
- Restart, undo where allowed, game-over UI, and basic settings.
- Clean desktop build.
- No dependency on Blender for ordinary runtime content integration.

### Not required for V1

- Online multiplayer.
- Accounts/cloud backend.
- Opening explorer.
- Deep analysis UI.
- PGN database/library features.
- 36 unique capture movies.
- Photorealism.
- Procedural combat physics.
- AI-generated assets at runtime.
- Mobile/web ports.

---

## 3. Technical architecture

Keep game logic layered. Domain code must remain testable without loading 3D scenes.

```text
+-----------------------------------------------------------+
|                         GAME UI                           |
| menus | board input | settings | difficulty | game over  |
+----------------------------+------------------------------+
                             |
                             v
+-----------------------------------------------------------+
|                    TURN / GAME CONTROLLER                 |
| phase state machine | move orchestration | undo/restart   |
+------------+-------------------------+--------------------+
             |                         |
             v                         v
+--------------------------+   +----------------------------+
|   CHESS DOMAIN LAYER     |   |    PRESENTATION LAYER      |
| BoardState               |   | BoardView                  |
| legal move generation    |   | PieceActor                 |
| make/unmake move         |   | BattleDirector             |
| FEN / UCI / PGN          |   | CameraDirector             |
| check/mate/draw rules    |   | Audio/VFX                  |
+------------+-------------+   +-------------+--------------+
             |                               |
             v                               v
+--------------------------+   +----------------------------+
|      STOCKFISH UCI       |   |       ASSET LIBRARY        |
| subprocess adapter       |   | models / rigs / clips      |
| handshake/options        |   | choreography resources     |
| position/go/bestmove     |   | materials / SFX / VFX      |
+--------------------------+   +----------------------------+
```

### 3.1 Domain-state authority

The chess domain is always authoritative.

When a player requests `Nf3xe5`:

1. `ChessGame.try_move(from, to, promotion)` validates the request.
2. Domain applies the move and returns a structured `MoveResult` containing the before/after facts required by presentation.
3. Input is locked.
4. `BoardPresenter.present_move(move_result)` animates the already-determined outcome.
5. When presentation emits `finished`, the next logical turn begins.
6. If presentation fails, the board can be rebuilt directly from the authoritative domain state.

Animation can fail visually without damaging the game.

### 3.2 Core move result

Use a structure equivalent to:

```gdscript
class_name MoveResult

var uci: String
var from_square: Vector2i
var to_square: Vector2i
var moving_piece: PieceSnapshot
var captured_piece: PieceSnapshot
var is_capture: bool
var is_castle: bool
var rook_from: Vector2i
var rook_to: Vector2i
var is_en_passant: bool
var en_passant_capture_square: Vector2i
var is_promotion: bool
var promotion_piece_type: int
var gives_check: bool
var is_checkmate: bool
var is_stalemate: bool
var game_result: String
```

Do not make the presentation layer re-derive chess facts from visual actors.

### 3.3 Turn phases

Use an explicit state machine such as:

```text
BOOT
  -> READY
  -> PLAYER_INPUT
  -> PRESENTING_PLAYER_MOVE
  -> ENGINE_THINKING
  -> PRESENTING_ENGINE_MOVE
  -> PLAYER_INPUT
  -> GAME_OVER
```

Additional transient states are fine, but do not permit simultaneous human input and engine/presentation mutation.

---

## 4. Godot scene architecture

Recommended baseline:

```text
scenes/
  app/
    Main.tscn
    GameScreen.tscn
  board/
    ChessBoard.tscn
    Square.tscn
  actors/
    PieceActor.tscn
    PawnActor.tscn          # optional inherited specializations
    KnightActor.tscn
    BishopActor.tscn
    RookActor.tscn
    QueenActor.tscn
    KingActor.tscn
  presentation/
    BattleStage.tscn
    CameraRig.tscn
    CaptureVFX.tscn
  ui/
    MainMenu.tscn
    InGameHUD.tscn
    PromotionDialog.tscn
    GameOverDialog.tscn
```

### PieceActor responsibilities

Each actor should expose behavior, not chess rules:

```gdscript
face_world_position(target)
move_to_world_position(target, duration)
play_state(name)
play_clip(name)
set_side(side)
attach_weapon(scene)
show_piece()
hide_piece()
reset_pose()
```

A PieceActor should know its archetype and visual configuration, but **not** whether a chess move is legal.

### Suggested visual actor node tree

```text
PieceActor (Node3D)
├── ModelRoot (Node3D)
│   └── ImportedCharacter
│       ├── Skeleton3D
│       └── MeshInstance3D...
├── AnimationPlayer
├── AnimationTree
├── WeaponSocket / attachment helper
├── SelectionRing
├── Shadow helper (optional)
├── AudioStreamPlayer3D
└── DebugAnchorVisuals (editor/debug only)
```

---

## 5. The asset pipeline — the critical subsystem

### 5.1 Preferred source assets

Start with a single compatible ecosystem where possible.

**Quaternius** is the preferred prototype source because the currently available packs provide:

- CC0 game-ready humanoid base characters.
- A humanoid rig intended for retargeting.
- Modular fantasy outfits compatible with the base rig.
- Universal Animation Library 1.
- Universal Animation Library 2 with 130+ additional animations and melee/armed combos.
- glTF/GLB and FBX formats and Godot-oriented exports.

Reference pages:

- https://quaternius.com/packs/universalbasecharacters.html
- https://quaternius.com/packs/modularcharacteroutfitsfantasy.html
- https://quaternius.com/packs/universalanimationlibrary.html
- https://quaternius.com/packs/universalanimationlibrary2.html

Optional animation gap filler:

- Adobe Mixamo FAQ/license reference: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html

Do not introduce a second skeleton ecosystem until the first two-character combat slice works.

### 5.2 Asset intake rules

Every imported asset must have a metadata record before becoming a dependency.

Create `assets/THIRD_PARTY_ASSETS.md` with:

```text
Asset name
Source URL
Creator
License
Date acquired
Original archive/file name
Project files derived from it
Modifications performed
Attribution required? yes/no
Redistribution restrictions
```

CC0 assets still get recorded for provenance.

### 5.3 Canonical humanoid requirements

For V1 humanoid characters:

- One known humanoid skeleton profile.
- Consistent bind/rest pose after import.
- Godot `SkeletonProfileHumanoid` mapping where applicable.
- Consistent world scale.
- Character forward axis normalized.
- Feet placed on local ground plane.
- Weapon sockets mapped consistently.
- No animation clip may silently translate the actor root unless explicitly approved.

Godot reference:
https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html

### 5.4 In-place locomotion rule

V1 animations should be in-place whenever practical.

The game controls translation:

```text
Actor root: moves from board square toward combat anchor
Skeleton: plays walk/run cycle in place
```

This avoids fighting imported root motion and makes chess-square alignment deterministic.

### 5.5 Animation naming convention

Normalize imported source names during intake.

```text
idle.neutral
idle.combat
locomotion.walk.forward
locomotion.walk.backward
attack.sword.slash_01
attack.sword.overhead_01
attack.spear.thrust_01
attack.magic.cast_01
attack.heavy.smash_01
reaction.hit.chest_01
reaction.hit.head_01
reaction.stagger_01
death.backward_01
death.forward_01
death.kneel_01
victory.short_01
```

Never let source-pack filenames become permanent gameplay API names.

### 5.6 AnimationTree state baseline

Godot `AnimationTree`/`AnimationNodeStateMachine` should provide at least:

```text
idle
walk
combat_idle
attack
hit
stagger
death
victory
```

Godot supports programmatic state travel through `AnimationTree`; use that rather than scattering direct `AnimationPlayer.play()` calls throughout gameplay code.

References:
- https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- https://docs.godotengine.org/en/stable/classes/class_animationnodestatemachine.html

---

## 6. Character art strategy

### 6.1 Six archetypes

The visual language should make every type recognizable at board-camera distance.

| Piece | Visual silhouette | Primary combat language |
|---|---|---|
| Pawn | small/simple infantry | spear/short sword/shield; nervous but scrappy |
| Knight | mounted-looking or heavily knight-coded warrior | sword/lance; fast committed strikes |
| Bishop | robed cleric/mage | staff/magic/ranged casting |
| Rook | massive armored brute / tower motif | hammer/maul/shield bash; heavy impacts |
| Queen | elegant, dangerous spellblade/mage | fast magic + blade; controlled dominance |
| King | regal veteran warrior | sword/scepter; deliberate defensive power |

The Knight does not have to be literally mounted in V1. A visually obvious armored knight is much easier to animate with the shared humanoid rig.

### 6.2 Side differentiation

White and black should initially share geometry but differ through:

- dominant material palette,
- cloth/metal accent colors,
- selection ring/team indicators,
- optional helmet/accessory variants.

Do not double the animation pipeline by creating separate rigs for each side.

### 6.3 Art style target

Prototype with stylized low-poly/semi-low-poly fantasy art. Benefits:

- compatible with Quaternius assets,
- readable silhouettes,
- lower animation defects are less visually punishing,
- runs well on ordinary desktop integrated graphics,
- easier to add VFX without uncanny realism,
- feasible for a small/agent-led team.

A later art-direction pass may replace characters while keeping the same rig/choreography contract.

---

## 7. Combat choreography architecture

### 7.1 Combat anchors

Every generic capture is staged using anchors relative to the destination square.

Example local convention:

```text
               victim anchor
                    X
                    |
                 1.5 m
                    |
                    X
              attacker anchor
```

`BattleDirector` chooses orientation based on approach direction, then converts anchors to world transforms.

Store distances/configuration in resources, not magic numbers.

### 7.2 Generic choreography data

Create a resource/data type approximately like:

```gdscript
class_name CaptureChoreography
extends Resource

@export var id: StringName
@export var attacker_archetypes: Array[StringName]
@export var victim_archetypes: Array[StringName]
@export var attacker_clip: StringName
@export var victim_hit_clip: StringName
@export var victim_death_clip: StringName
@export var approach_distance_m: float = 1.5
@export var approach_duration_s: float = 0.45
@export var impact_time_s: float = 0.70
@export var cleanup_time_s: float = 1.80
@export var camera_shot: StringName
@export var impact_sfx: StringName
@export var vfx_profile: StringName
@export var weapon_profile: StringName
```

Prefer typed `.tres` Godot Resources for production data; JSON is acceptable for early experimentation but should not fragment type safety.

### 7.3 Generic capture sequence

Baseline algorithm:

```text
1. Freeze board input.
2. Identify attacker/victim actors from MoveResult.
3. Hide/de-emphasize board UI.
4. Move attacker and victim to compatible staging transforms if needed.
5. Cut/blend camera to capture shot.
6. Attacker enters combat idle.
7. Play attacker attack clip.
8. At choreography impact marker:
   - victim plays hit/death clip
   - play impact SFX
   - spawn particle/VFX
   - optional tiny camera shake
9. Victim becomes hidden or dissolves after death beat.
10. Attacker moves/snaps to exact destination square transform.
11. Restore attacker idle.
12. Return board camera.
13. Emit `presentation_finished`.
```

### 7.4 Event timing

Avoid long chains of hard-coded `await get_tree().create_timer(...)` in gameplay code.

Preferred order of maturity:

1. Data timestamps in `CaptureChoreography` for prototype.
2. Animation method/call tracks or named markers/signals for impact and completion.
3. Signature sequences can have dedicated `AnimationPlayer` timeline assets.

The BattleDirector should await named events, not infer state from frame rate.

### 7.5 Fallback choreography

Every attacker type must have a fallback capture that works against every humanoid victim.

Example:

```text
Pawn:   spear thrust + generic backward death
Knight: sword overhead + generic backward death
Bishop: magic cast + generic stagger/death
Rook:   heavy smash + knockback/death
Queen:  spell/blade strike + dramatic death
King:   sword slash + forward/backward death
```

This guarantees all legal captures are presentable before matchup-specific content exists.

### 7.6 Signature captures

Later, a signature capture can override generic choreography by matchup:

```text
capture/knight_vs_rook_01
capture/pawn_vs_queen_01
capture/bishop_vs_knight_01
```

Resolver priority:

```text
exact matchup signature
  -> attacker-specific compatible capture
  -> universal fallback capture
```

A signature sequence may use two synchronized actor clips plus a dedicated camera timeline.

---

## 8. Camera, audio, and VFX — cheap quality multipliers

Good staging can make ordinary animation clips feel custom.

### CameraDirector

Provide a few reusable shot profiles:

```text
board_default
capture_medium
capture_low_angle
capture_over_shoulder
capture_rook_heavy
capture_magic
check_reaction
checkmate_king
```

Do not let arbitrary choreography code directly manipulate the camera. Ask the CameraDirector for a shot by ID.

### Impact package

At the attack impact marker combine:

- weapon/body hit sound,
- very short camera impulse,
- small spark/dust/magic particle,
- victim reaction animation,
- optional 50–100 ms animation speed accent or hit-stop only if it feels good.

Each should remain independently disableable for debugging/accessibility.

### Audio

V1 needs:

- board ambience (optional),
- selection/move UI sounds,
- footsteps (later),
- weapon impacts,
- magic impacts,
- death/reaction sounds kept restrained,
- check/checkmate stingers.

Do not block the vertical slice on voice acting.

---

## 9. Chess domain layer

### 9.1 Scope

Implement pure chess rules in code with no dependency on visuals or Stockfish.

Required:

- board representation,
- side to move,
- pseudo-legal move generation,
- legal move filtering based on king safety,
- captures,
- pawn double move,
- en passant,
- promotion to Q/R/B/N,
- castling rights and legality,
- check,
- checkmate,
- stalemate,
- fifty-move rule,
- threefold repetition,
- insufficient material detection,
- FEN import/export,
- UCI move import/export,
- PGN export for completed games (PGN import may be later).

### 9.2 Representation

Choose correctness and debuggability over cleverness. A 64-square array with compact piece values is sufficient.

Avoid premature bitboard optimization. Stockfish handles AI search; our domain layer only needs fast human-scale move generation.

### 9.3 Make/unmake

Implement `make_move` and `unmake_move` or immutable/copy state semantics robustly enough to test king safety and perft. Maintain explicit undo records for:

- captured piece,
- castling rights,
- en passant square,
- halfmove clock,
- fullmove number,
- promotion,
- rook movement during castle.

### 9.4 Chess correctness tests

Minimum automatic tests:

Starting-position perft:

```text
depth 1 = 20
depth 2 = 400
depth 3 = 8,902
depth 4 = 197,281
```

Also add focused positions/tests for:

- castling through check prohibited,
- castling while in check prohibited,
- en passant exposing own king prohibited,
- promotion capture,
- underpromotion,
- pinned piece behavior,
- check evasion,
- stalemate,
- checkmate,
- repetition bookkeeping,
- fifty-move rule.

Do not proceed to “full game” milestone if domain tests are failing.

---

## 10. Stockfish integration

### 10.1 Version policy

At the time this plan was authored (2026-09-10), Stockfish 19 is the latest stable release, announced 2026-09-05. Agents should verify the latest stable official release at implementation time.

Official references:
- https://stockfishchess.org/download/
- https://official-stockfish.github.io/docs/stockfish-wiki/Developers.html

### 10.2 Process boundary

Stockfish runs as a separate executable.

Adapter responsibilities:

```text
spawn
stdin writes
stdout line reader
uci handshake
isready synchronization
setoption
ucinewgame
position fen ...
position startpos moves ...
go movetime ... / go depth ...
parse info lines when desired
parse bestmove
stop
quit
process crash detection/restart
```

Never parse output from the main UI thread in a way that stalls rendering.

### 10.3 Handshake

Expected startup contract:

```text
spawn stockfish
-> send `uci`
<- wait for `uciok`
-> configure options
-> send `isready`
<- wait for `readyok`
```

Before a new match:

```text
ucinewgame
isready
```

Before engine move:

```text
position fen <authoritative FEN>
go movetime <N>
```

Parse:

```text
bestmove e7e5
```

Domain layer then independently validates/applies the returned UCI move.

### 10.4 Difficulty

Use supported Stockfish weakening features rather than artificial random legal moves where possible.

Stockfish documents `UCI_LimitStrength` / `UCI_Elo` and `Skill Level`. `UCI_Elo` takes precedence when limit strength is enabled.

Create player-facing presets such as:

```text
Novice
Apprentice
Soldier
Knight
Captain
Warlord
Master
Maximum
```

Map these to tested UCI settings. Exact Elo labels should not make unsupported precision claims. If using approximate ratings, label them appropriately.

### 10.5 Distribution/license

Stockfish is GPLv3. Keep it at arm's length as a separate process. If distributing the binary, include the required GPL license/source availability information for the exact Stockfish binary being distributed. Do not modify Stockfish unless there is a strong reason.

Record exact binary/version/hash in `THIRD_PARTY_ASSETS.md` or a dedicated `THIRD_PARTY_SOFTWARE.md`.

---

## 11. Board interaction

### V1 controls

- Left click selectable piece.
- Highlight legal destinations.
- Click destination to request move.
- Click selected piece or Escape to cancel.
- Promotion opens four-choice UI.
- Optional board rotate button.

### Ray picking

Use square colliders or deterministic ray-plane conversion. Prefer reliable board-square picking over clicking animated mesh geometry.

### Selection state

The board controller asks the chess domain for legal moves. It does not ask PieceActor.

Visual highlights:

```text
selected
legal quiet move
legal capture
last move from/to
king in check
```

Keep these presentation-only.

---

## 12. Special move presentation

### Castling

No battle. Animate king and rook in sequence or near-simultaneously, then snap to exact squares.

### En passant

The victim actor is not on the destination square. `MoveResult.en_passant_capture_square` explicitly identifies the actor to remove. For V1, a generic pawn capture may stage the victim nearby, then attacker finishes on the legal destination.

### Promotion

After move/capture presentation:

1. Pawn reaches destination.
2. Promotion visual transition.
3. Swap actor archetype to selected promoted piece while preserving side and destination.

V1 can use a brief glow/dissolve rather than a unique transformation animation.

### Check

Optional short cue only; do not make every check a long interruptive cutscene.

### Checkmate

Use a dedicated end-state sequence:

- final move/capture completes,
- losing king reaction/kneel,
- winning side victory beat,
- game-over UI.

Do not literally animate king death if the desired tone is chess-like rather than execution-like.

---

## 13. Save, replay, undo

### Minimum

Store move history and enough state to restart/undo locally.

### Suggested records

```text
GameSession
- starting_fen
- move_uci[]
- move_san[] (once SAN support exists)
- result
- timestamps optional
- player configuration
- engine configuration
- random choreography seed
```

A fixed choreography random seed makes replays deterministic.

### Undo

For local human-vs-human: one ply.
For human-vs-engine: normally undo both the human move and engine reply.
During any undo, stop current engine calculation and presentation, then rebuild the visual board from domain state.

---

## 14. Testing strategy

### Unit tests

Prioritize deterministic logic:

- chess rules/perft,
- FEN roundtrip,
- UCI parse/format,
- choreography resolver priority,
- board-square ↔ world-position mapping,
- difficulty config mapping.

### Integration tests

- Spawn Stockfish and complete handshake.
- Submit known FEN and receive a legal `bestmove`.
- Kill Stockfish unexpectedly; adapter reports failure without freezing game.
- Full scripted 4-ply game updates domain and board actors correctly.
- Capture event removes exactly one victim actor and leaves attacker on exact destination.

### Visual smoke tests

Create deterministic debug scenes/buttons:

```text
DebugCombatLab.tscn
- attacker dropdown
- victim dropdown
- choreography dropdown
- play button
- reset button
- slow-motion toggle
- anchor visualization toggle
```

This scene is essential. It lets humans and agents iterate on animation without playing chess to reach a specific capture.

### Headless CI

Run domain and non-rendering integration tests headlessly where possible. Rendering-quality validation remains an interactive/manual or screenshot/video review task.

---

## 15. Debug tooling agents must build early

Do not hide art-pipeline problems inside a full match.

Required debug tooling:

1. **Combat Lab** — manually pair any attacker/victim and play choreography.
2. **Animation Browser** — select character + normalized clip and preview.
3. **Rig Inspector** — show skeleton mapping status, weapon sockets, forward axis, root translation.
4. **Board Debug Overlay** — square coordinates, actor IDs, logical piece state.
5. **Engine Console** — optional developer panel showing UCI lines and engine state.
6. **Position Loader** — paste FEN and immediately rebuild the board.
7. **Move Injector** — execute a legal UCI move for testing.

These tools reduce agent iteration cost enormously.

---

## 16. Repository structure

Recommended:

```text
warchessed/
├── AGENTS.md
├── README.md
├── LICENSE                  # project license decision; do not confuse with third-party licenses
├── project.godot
├── BATTLE_CHESS_MASTER_PLAN.md
├── KICKOFF_PROMPT.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── ASSET_PIPELINE.md
│   ├── ROADMAP.md
│   ├── ACCEPTANCE_CRITERIA.md
│   ├── DECISIONS.md
│   └── THIRD_PARTY_SOFTWARE.md
├── assets/
│   ├── characters/
│   ├── animations/
│   ├── materials/
│   ├── audio/
│   ├── vfx/
│   └── THIRD_PARTY_ASSETS.md
├── data/
│   ├── pieces/
│   ├── choreography/
│   ├── camera/
│   └── difficulty/
├── scenes/
│   ├── app/
│   ├── board/
│   ├── actors/
│   ├── presentation/
│   ├── ui/
│   └── debug/
├── scripts/
│   ├── chess/
│   ├── engine/
│   ├── game/
│   ├── presentation/
│   ├── actors/
│   ├── ui/
│   └── debug/
├── tests/
│   ├── chess/
│   ├── engine/
│   └── presentation/
├── third_party/
│   └── stockfish/
└── tools/
```

Do not commit giant source asset archives casually. Establish a source-asset policy once the initial pack is chosen.

---

## 17. Milestone roadmap

Detailed acceptance criteria live in `docs/ROADMAP.md` and `docs/ACCEPTANCE_CRITERIA.md`. The governing order is:

### M0 — Repository/bootstrap

Goal: Godot project launches, tests can run, agent conventions are established.

### M1 — Combat vertical slice

Goal: One humanoid attacker defeats one humanoid victim convincingly in `DebugCombatLab` using imported/retargeted animations.

**This is the highest-risk proof. Do it before full chess.**

### M2 — Chess domain correctness

Goal: Fully tested chess rules and FEN/UCI handling, including start-position perft through depth 4.

### M3 — Interactive board

Goal: 3D board driven by domain state with selection/legal highlights, human-vs-human moves, all special moves.

### M4 — Stockfish opponent

Goal: Reliable subprocess UCI adapter, difficulty settings, complete human-vs-engine game.

### M5 — Presentation integration

Goal: Every quiet move animates; every capture routes through BattleDirector; no visual event can corrupt state.

### M6 — Six archetypes

Goal: Pawn/Knight/Bishop/Rook/Queen/King visual personalities and fallback attack choreography.

### M7 — Game UX/polish

Goal: menus, game over, restart/undo, settings, camera/audio/VFX polish, packaging.

### M8 — Signature battle content

Goal: replace selected generic captures with custom memorable matchup sequences.

### M9 — Optional productization

Possible later work: Steam packaging, achievements, analysis/replay mode, online play, user themes, workshop/mod support.

---

## 18. Agent execution protocol

This section is intentionally prescriptive.

### 18.1 Root agent duties

The root agent owns:

- understanding this master spec,
- keeping architecture coherent,
- decomposing milestones,
- assigning independent tasks to workers/worktrees when useful,
- reviewing merges,
- running milestone acceptance checks,
- updating project docs when evidence changes a decision.

### 18.2 Delegation boundaries

Parallelize work that has clean contracts. Examples:

```text
Worker A: chess domain + tests
Worker B: Godot board/picking + debug overlay
Worker C: Stockfish UCI adapter + process tests
Worker D: asset intake / retargeting / AnimationTree prototype
Worker E: Combat Lab + BattleDirector
```

Do **not** parallelize two workers that are both inventing the same core interface. Root agent defines or approves the interface first.

### 18.3 Small PR/worktree rule

Each task should end in a reviewable change with:

- problem statement,
- changed files,
- verification performed,
- known limitations,
- screenshots/video notes when visual,
- docs/decision updates when architecture changed.

Avoid giant “implemented game” branches.

### 18.4 No speculative framework building

Agents must not spend several turns building abstractions for hypothetical future features. Each abstraction must support the current milestone or a clearly imminent next milestone.

### 18.5 Visual tasks

For 3D/animation tasks, code tests alone are insufficient. The worker must leave:

- deterministic debug scene/setup,
- exact reproduction steps,
- screenshots or short capture if the environment permits,
- any visible defects written into the task notes.

### 18.6 Escalation

Agents should pause a milestone and surface a decision only when one of these is true:

- a source asset cannot legally be redistributed,
- the chosen rig cannot be retargeted without destructive/manual work,
- a cross-platform subprocess limitation changes Stockfish architecture,
- a proposed change would couple presentation into chess logic,
- performance is below target and profiling points to an architectural cause,
- a feature would copy protectable expression from an existing game.

Routine implementation choices should be made autonomously and documented.

---

## 19. Recommended model allocation in Codex

Model availability changes, so do not encode this as a hard requirement. Current guidance as of 2026-09-10:

### GPT-6 Astra

Use for:

- initial repository/bootstrap architecture,
- cross-cutting design decisions,
- difficult Godot import/retargeting debugging,
- multi-agent decomposition,
- hard integration failures,
- final milestone review.

### GPT-5.6 Sol

Use for:

- substantial feature implementation,
- chess domain correctness work,
- BattleDirector/animation architecture,
- UCI adapter,
- refactors spanning multiple subsystems.

### GPT-5.6 Terra

Use for:

- well-scoped feature tickets,
- UI work,
- tests,
- debug tooling,
- documentation updates,
- straightforward scene/script implementation.

### GPT-5.6 Luna

Use for:

- mechanical edits,
- renames,
- repetitive resource generation,
- lint/test fixes with narrow scope,
- documentation formatting,
- bulk asset metadata once the schema is established.

### GPT-5.5

Capable fallback for complex production workflows, but when Astra/Sol are available there is little reason to prefer 5.5 for the hardest project-wide work.

Official model guidance:
- https://developers.openai.com/api/docs/models
- https://developers.openai.com/api/docs/guides/latest-model

The important variable is not model brand; it is **task specification + repository context + deterministic acceptance criteria**.

---

## 20. Performance targets

V1 should target:

- 1920×1080 desktop.
- 60 fps on a modern integrated-GPU desktop class machine using stylized assets.
- No per-frame chess engine work.
- No expensive skeletal processing for hidden/dead actors.
- Reasonable texture sizes; avoid 4K materials on low-poly prototype characters.
- One primary active capture staging sequence at a time.

Profile before optimizing. The board has at most 32 live piece actors, so a sane low-poly humanoid scene should be tractable.

---

## 21. Accessibility and settings

Include architecture hooks for:

- master/music/SFX volume,
- camera shake amount/off,
- capture animation speed or “quick captures” mode,
- skip current capture animation,
- board coordinates toggle,
- fullscreen/windowed,
- resolution/render scaling if needed.

A player who wants chess without waiting through every animation should be able to speed up or skip captures.

---

## 22. IP and licensing guardrails

### Existing Battle Chess IP

This project is a spiritual-successor concept, not a remake asset project.

Do not copy:

- title/logo/trademark presentation,
- character designs,
- specific comedic kill choreography,
- audio,
- board art,
- UI,
- source code,
- ripped sprites/models/animations.

General concepts such as “chess captures trigger animated fights” can inspire original implementation, but shipping identity and content must be independently designed.

### Godot

Follow Godot's license/attribution requirements applicable to the chosen release.

### Stockfish

GPLv3; separate executable; include required license/source information when distributing.

### Quaternius

Preferred listed prototype packs are CC0 according to their pack pages. Record provenance anyway.

### Mixamo

Optional. Confirm current Adobe terms immediately before shipping and do not redistribute source animation assets outside what the license allows.

### AI-generated art

If introduced later, maintain provenance and provider terms, and require a human visual review for consistency/originality.

---

## 23. Risks and mitigations

| Risk | Why it matters | Mitigation |
|---|---|---|
| Retargeted clips deform badly | core visual blocker | prove one character/clip pair in M1 before chess expansion |
| Different assets have mismatched scale/axes | staging looks broken | canonical import checklist + Rig Inspector |
| Generic attacks do not contact victim | kills feel fake | combat anchors + impact markers + camera/VFX hide small gaps |
| Root motion drifts pieces off squares | corrupt presentation | in-place clips + code-controlled root translation |
| Chess rules subtle bug | destroys trust | perft + focused special-rule tests |
| Stockfish process hangs/crashes | game freezes | async adapter, timeout/restart, domain validation |
| Full-strength engine frustrates players | poor game experience | difficulty presets using UCI weakening |
| Art style becomes inconsistent | looks like asset soup | one source ecosystem initially; art bible later |
| Custom animation workload explodes | project stalls | generic fallback first; signature kills only after V1 |
| Agent changes architecture casually | project drift | AGENTS.md + decision log + milestone acceptance gates |
| Existing-game IP copied accidentally | legal/product risk | original characters/choreography/name; explicit guardrail |

---

## 24. Definition of Done for any task

A task is not done merely because code exists.

It is done when:

1. behavior matches the task acceptance criteria,
2. appropriate tests pass,
3. the project still boots,
4. no new errors/warnings are introduced without explanation,
5. visual tasks have a deterministic reproduction scene/path,
6. architecture docs are updated if contracts changed,
7. third-party asset/software provenance is updated if dependencies changed,
8. temporary debug hacks are either removed or clearly isolated,
9. the root agent can review the change without reconstructing the author's intent.

---

## 25. First implementation sequence — exact order

Do this in order unless blocked.

### Step 1 — bootstrap

- Create Godot 4.x latest-stable project.
- Set basic window/render configuration.
- Add test harness.
- Add folder structure.
- Copy this plan, AGENTS.md, roadmap, and decision log into repo.
- Create a flat/simple 8×8 test board only if useful for spatial scale.

### Step 2 — acquire one compatible humanoid + three clips

Obtain from preferred CC0 source:

- one humanoid fantasy character,
- idle,
- one attack,
- one death/hit reaction.

Record provenance.

### Step 3 — prove Godot import/retargeting

- Import glTF/GLB/FBX.
- Map humanoid skeleton.
- Preview all three animations.
- Normalize scale/orientation.
- Create AnimationTree state transitions.

### Step 4 — create Combat Lab

- attacker actor,
- victim actor,
- reset/play button,
- fixed anchors,
- camera shot,
- attack impact event,
- victim death,
- attacker settle.

### Step 5 — make capture look acceptable

Do not proceed until:

- feet are not wildly sliding,
- strike roughly contacts target,
- victim reaction timing reads correctly,
- camera angle hides minor mismatch,
- reset is deterministic,
- 20 consecutive plays do not drift state.

### Step 6 — build chess domain in parallel

Now it is safe to dedicate a separate worker to full rules + perft tests.

### Step 7 — build board presenter

- 64 squares,
- logical-to-world mapping,
- piece actor placement,
- selection/legal highlights,
- human-vs-human.

### Step 8 — build Stockfish adapter

- separate process,
- handshake,
- set position,
- receive legal move,
- error handling,
- difficulty mapping.

### Step 9 — integrate move presentation

- quiet move → locomotion/slide.
- capture → BattleDirector.
- special moves.
- authoritative domain state always wins.

### Step 10 — add all six archetypes

One at a time. For each:

- model/outfit,
- weapon,
- idle/combat idle,
- locomotion,
- primary attack,
- fallback capture choreography.

### Step 11 — polish the game loop

- menu,
- difficulty,
- restart/undo,
- check/game-over cues,
- audio settings,
- skip/fast capture,
- packaging.

### Step 12 — only then create signature kills

Pick the most fun/high-frequency matchups and replace generic captures selectively.

---

## 26. First-day acceptance demonstration

The project should strive to produce this as early as possible:

1. Launch `DebugCombatLab`.
2. Two stylized medieval humanoids stand on an empty board-like platform.
3. Press **Play Capture**.
4. Attacker approaches.
5. Camera moves to a medium shot.
6. Attacker performs one real imported attack clip.
7. A timed impact sound/VFX fires.
8. Victim performs a real imported death clip.
9. Victim disappears.
10. Attacker settles at the target position.
11. Press **Reset** and repeat without drift.

If this looks even moderately convincing, the project is technically validated.

---

## 27. Future signature-animation production options

When generic choreography is no longer enough, use this escalation ladder:

1. Recombine existing clips + better staging/camera.
2. Trim/retime/edit clips in Godot.
3. Retarget another compatible library clip.
4. Use Blender only to adjust a specific clip/contact pose.
5. Video-to-mocap / motion-capture pipeline for an original motion.
6. Commission an animator for a bounded two-character sequence on the project's canonical rig.

Never make “learn Blender animation” a prerequisite for general project progress.

For commissioned signature captures, provide the animator:

```text
canonical attacker rig
canonical victim rig
weapon/socket conventions
start transforms
end transforms
clip FPS/sample rate
required duration window
timing marker for impact
required looping/non-looping flags
file format/export preset
```

Then runtime only needs to play the delivered clips through the same choreography contract.

---

## 28. Potential post-V1 feature directions

Do not implement these early; they are recorded so architecture does not accidentally preclude them.

- alternate visual armies/themes sharing the same skeleton contract,
- replay viewer with capture replays,
- “fast chess” mode with reduced animation lengths,
- local tournaments,
- engine analysis after game,
- PGN import to watch famous games as battles,
- spectator mode: Stockfish vs Stockfish,
- custom asset/mod packs,
- online multiplayer,
- Steam achievements,
- optional stylized gore-free / family-friendly presentation profiles,
- cinematic “signature kill” packs.

A particularly strong later feature is **PGN cinematic replay**: because presentation consumes deterministic `MoveResult` events, any valid recorded game can become an animated battle replay without changing chess logic.

---

## 29. Source/reference appendix

### OpenAI / Codex

- https://openai.com/codex/
- https://help.openai.com/en/articles/11369540
- https://developers.openai.com/api/docs/models
- https://developers.openai.com/api/docs/guides/latest-model

### Godot animation/retargeting

- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html
- https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- https://docs.godotengine.org/en/stable/classes/class_animationnodestatemachine.html

### Stockfish

- https://stockfishchess.org/download/
- https://official-stockfish.github.io/docs/stockfish-wiki/Developers.html
- https://official-stockfish.github.io/docs/stockfish-wiki/Stockfish-FAQ.html

### Quaternius

- https://quaternius.com/packs/universalbasecharacters.html
- https://quaternius.com/packs/modularcharacteroutfitsfantasy.html
- https://quaternius.com/packs/universalanimationlibrary.html
- https://quaternius.com/packs/universalanimationlibrary2.html

### Mixamo

- https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html

---

## 30. Final instruction to the implementing agents

Do not optimize for how much code is produced. Optimize for **successive proof**.

The critical chain is:

```text
one convincing capture
    ↓
correct chess domain
    ↓
interactive board
    ↓
Stockfish move
    ↓
chess event drives capture
    ↓
six complete archetypes
    ↓
polished game
    ↓
signature animations
```

If a milestone fails, fix that layer before adding surface area. If an art asset is problematic, swap the asset rather than contaminating the architecture with exceptions. If animation is imperfect, use staging, camera, timing, sound, and VFX before reaching for custom animation tooling.

The end goal is not a technology demo. It is a chess game whose combat presentation feels deliberate, funny, dramatic, and replayable while the underlying chess remains completely correct.
