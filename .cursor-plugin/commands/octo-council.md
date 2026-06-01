---
description: "Multi-LLM council for advice, decision support, implementation plans, and gated implementation"
---

# Council

Use `/octo:council <task>` when the user wants a structured council of multiple LLM personas to advise, critique, synthesize, and optionally hand off an approved implementation plan.

## MANDATORY COMPLIANCE

Run the real Octopus runner by default. Your council execution action must resolve the plugin root and call:

```bash
"$CLAUDE_PLUGIN_ROOT/scripts/orchestrate.sh" council $ARGUMENTS
```

If `CLAUDE_PLUGIN_ROOT` is unset, use `${HOME}/.claude-octopus/plugin/scripts/orchestrate.sh`.

PROHIBITED: Do not simulate a council, role-play multiple personas inside one model, or answer directly unless the user explicitly passes `--simulate` or `--single-model`. If simulation is requested, label it as `single-model simulation` in the response and preserve the runner's `summary.json` path.

Run through `skill-council` for preflight, research-first handling, artifact review, and gate handling, but do not let the skill replace the shell runner. Do not skip provider/cost preflight, quorum checks, run artifacts, or implementation gates.

When clarification or options are needed, use an interactive multiple-choice prompt with 2-4 mutually exclusive choices. Do not end the response with a loose question or a list of questions.

## Examples

```text
/octo:council --depth quick --goal advice "Should we use Redis here?"
/octo:council --goal decision --domain architecture "Should this service stay monolithic?"
/octo:council --goal implement --implement plan-only "Refactor the auth flow"
/octo:council --dry-run --members 7 --persona finance-analyst "Review this pricing strategy"
```

## Flags

- `--goal advice|decision|plan|implement|review`
- `--domain auto|architecture|product|security|business|research|docs`
- `--style balanced|adversarial|implementation|executive|red-team`
- `--depth quick|standard|deep`
- `--members auto|3|5|7`
- `--persona <name>[,<name>]`
- `--implement never|after-approval|plan-only`
- `--worktree auto|on|off`
- `--benchmark auto|on|off`
- `--providers auto|claude,codex,gemini,opencode,openrouter`
- `--max-cost <usd>`
- `--simulate`
- `--single-model`
- `--research-first`
- `--corpus-mode off|append|require`
- `--dry-run`
- `--json`
- `--output-dir <path>`
