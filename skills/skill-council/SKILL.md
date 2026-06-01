---
name: skill-council
description: "Run a configurable multi-LLM council with personas, budget caps, synthesis, veto gates, and optional implementation handoff."
---

# Council

Use this skill for `/octo:council` and council-style requests.

## EXECUTION CONTRACT: MANDATORY

`/octo:council` is a runner-backed workflow. Execute the real shell runner by default:

```bash
"${CLAUDE_PLUGIN_ROOT:-$HOME/.claude-octopus/plugin}/scripts/orchestrate.sh" council <user arguments>
```

Do not simulate a council, role-play all members inside the current model, or answer directly in place of the runner. A single-model simulation must be explicitly requested with `--simulate` or `--single-model`; when used, label the output as `single-model simulation` and keep the generated `summary.json` path visible. Otherwise, missing provider quorum is a partial/failed council, not permission to silently downgrade.

## Phase 0: Preflight

Collect or infer:

- goal: `advice`, `decision`, `plan`, `implement`, or `review`
- domain: `auto`, `architecture`, `product`, `security`, `business`, `research`, or `docs`
- style: `balanced`, `adversarial`, `implementation`, `executive`, or `red-team`
- depth: `quick`, `standard`, or `deep`
- members: `auto`, `3`, `5`, or `7`
- budget cap in USD
- providers and provider availability
- pinned personas
- implementation permission and worktree isolation
- whether research must happen before council fanout (`--research-first`)
- whether findings, research, synthesis, and plans must be appended to the project corpus (`--corpus-mode append|require`)

Show the selected council, provider availability, benchmark freshness, quorum requirement, and cost estimate before provider fanout. Re-check the budget before critique, revision, synthesis, and implementation planning so the run stops before the next phase would exceed `--max-cost`. If the run is a dry run, stop after this preflight and write `summary.json`.

If `--research-first` is set, gather local corpus evidence first, then current external sources when allowed. Store concise findings as run artifacts before provider fanout. If `--corpus-mode append` or `--corpus-mode require` is set, append the research notes, findings, synthesis, and implementation plan to the project's durable corpus conventions before claiming completion; `require` must stop when no corpus workspace is available.

## Quorum

- quick requires at least one non-chair response plus a synthesis-capable chair
- standard and deep require at least two non-chair responses plus a synthesis-capable chair
- if the chair fails, retry once with the highest-scoring synthesis-capable fallback
- if quorum is lost, stop by default and present partial artifacts instead of pretending consensus exists

## Council Procedure

1. **Independent advice:** ask each selected persona for recommendation, assumptions, risks, implementation notes, and confidence.
2. **Cross-critique:** for standard/deep runs, semi-anonymize responses and ask members to critique gaps, assumptions, and risks.
3. **Revision:** for deep runs or high disagreement, let members revise their positions after critique.
4. **Chair synthesis:** produce agreement, disagreement, minority reports, risk register, implementation path, confidence, and conditions that would change the recommendation.
5. **Ratify / veto:** verifier, red-team, security, legal, finance, and medical roles can veto implementation for critical risks.

## Implementation Gates

- **Gate A:** user accepts the council synthesis or asks for revision.
- **Gate B:** user accepts the concrete implementation plan generated from the synthesis.
- **Gate C:** execution proceeds through existing Octopus implementation safety behavior. This is a one-shot authorization for the accepted plan, not per-file approval, unless existing safety hooks detect destructive or risky actions.

Never implement from council output without explicit approval. Preserve disagreement, summarize risks, and keep vetoes visible in the final answer and artifacts.

## Interactive Choice Handling

When the user needs to clarify scope, select a depth/provider/corpus option, approve a gate, or decide between follow-up actions, use an interactive multiple-choice prompt with 2-4 mutually exclusive choices. Put the recommended choice first. Do not end with a free-form question or a set of questions; present the choice interaction and wait for the answer.
