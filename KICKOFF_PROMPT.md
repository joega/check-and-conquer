# Codex Kickoff Prompt

Copy/paste this into the first root Codex session after placing this project pack at the repository root.

---

You are the root implementation agent for **Check & Conquer**.

Read these files completely before changing code:

1. `BATTLE_CHESS_MASTER_PLAN.md`
2. `AGENTS.md`
3. `docs/ROADMAP.md`
4. `docs/ASSET_PIPELINE.md`
5. `docs/ACCEPTANCE_CRITERIA.md`
6. `docs/DECISIONS.md`

Your job is to carry the project forward autonomously, milestone by milestone, while preserving the architecture and acceptance gates described there.

Begin with **M0 Bootstrap**, then immediately prioritize **M1 Combat vertical slice**. The animation/retargeting pipeline is the highest-risk unknown and must be proven before a full chess application is built.

Use subagents/worktrees whenever tasks have clean boundaries and parallelism will help. In particular, once the M1 asset pipeline is materially proven, the chess-domain work in M2 can proceed in parallel with presentation/debug-tool refinement. Do not have multiple agents redefine the same central interface concurrently.

Bias toward action. Make routine implementation decisions without asking me. Stop and surface a decision only for the escalation cases in `AGENTS.md` / the master plan: licensing ambiguity, fundamental asset-rig incompatibility, a cross-platform constraint that changes architecture, an IP concern, or evidence that a non-negotiable architectural decision is materially wrong.

For each task:

- inspect the relevant code/docs first,
- implement the smallest coherent vertical increment,
- run meaningful tests/verification,
- create or preserve deterministic debug paths for visual work,
- update docs/decision/provenance records when needed,
- report what changed, verification, limitations, and the next best task.

Do not build speculative frameworks. Do not add online accounts, backend services, deep chess-analysis UI, or custom 36-matchup animations during V1 work.

The first meaningful demonstration we want is:

> Launch `DebugCombatLab`; press one button; a rigged fantasy attacker approaches a victim, performs an imported attack animation, an impact event triggers sound/VFX and a synchronized victim death reaction, the victim is removed, the attacker settles at the target transform, and Reset can repeat this 20 times without drift.

If internet/browser access is available, use only official or clearly licensed sources and record provenance. Preferred initial art/animation sources are the Quaternius CC0 packs named in `docs/ASSET_PIPELINE.md`. Do not download or copy assets from the original Battle Chess.

Proceed now. Start by inspecting the repository state and completing M0. Do not merely restate the plan.
