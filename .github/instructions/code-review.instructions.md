---
applyTo: "**"
excludeAgent: "cloud-agent"
---

# Code Review Methodology

Both Claude in `.github/workflows/review-claude.yml` and GitHub Copilot code review read this file.

## Goal

- Catch risky changes early while keeping these boundaries intact: the hotkey and event-tap layer (`Sources/Lanterna/Hotkey`), window enumeration through Accessibility (`Sources/Lanterna/Window`), private API bridging (`Sources/PrivateAPIs`), the switcher panel UI (`Sources/Lanterna/UI`), and the configuration schema (`config/`, `Sources/Lanterna/Support/AppConfiguration*.swift`).
- Measure a review by the important findings it did not miss, not by how many it made. Unimportant findings are noise that buries the important ones.
- Also guard runtime quality: responsiveness (the panel targets a sub-30 ms show), memory use, recovery from lost permissions or a disabled event tap, and diagnosability through the diagnostic log.

## Constraints

- Do not state guesses as facts. Ask with `[ASK]` when there is no evidence.
- Limit findings to reproducible facts, with a file path and line number.
- Do not treat existing code as the standard just because it exists. Treat it as a gap from the ideal.
- Use `[MUST][ALERT]` for contradictions between documents or conflicting responsibilities.
- Do not aim for coverage. Do not invent findings to fill a checklist.
- Always check guardrails on paths the diff adds or changes (see the exception below), and report any that are missing.

---

## Finding filter (apply before writing any finding)

### Acceptance criteria

Write a finding only if all three hold. "Just mentioning it" counts as rejected.

1. It comes from this PR's diff: the diff breaks something, or makes an existing problem worse.
2. You can state a concrete failure scenario in one sentence, naming which input or state makes what misbehave. For a missing guardrail, one sentence answering "what happens when the permission is revoked, the tap is disabled, or the target app stops responding", "would anyone notice, and can it recover", or "what happens on relaunch or config reload" is enough.
3. You can point at evidence in the diff, a `path:line` you actually read.

### Rejection list

- Pre-existing problems outside the diff, meaning code the diff does not touch or make worse. The exception is a PR that adds a new path that hits the problem. Otherwise put it in the out-of-scope notes in one line, or say nothing.
- Risks built on assumptions ("if more callers are added later", "if someone misuses it") whose trigger you cannot show within the diff.
  - Exception for missing guardrails: on a path the diff adds or changes, report these even if the trigger is hypothetical. They can reach `[MUST]`.
    - handling of revoked Accessibility or Input Monitoring permission
    - recovery when the event tap is disabled by timeout or user input
    - timeouts on Accessibility calls to an unresponsive app
    - caps on anything that grows with time or window count (logs, caches, history)
    - blocking work on the main thread in the show or switch path
    - backward compatibility when reading an existing config file
    - a diagnostic log line where a failure would otherwise be silent
  - The list is illustrative, not closed. The serious runtime defects in the judgment guide count the same way, but acceptance criteria 1 and 3 still apply.
- Anything a tool already checks (SwiftFormat, SwiftLint, actionlint, shellcheck, pinact, `-warnings-as-errors`): naming, import order, formatting, unused code. Leave it to CI.
- General advice not tied to a concrete defect ("extracting this would help maintainability", "a type could enforce this", "a better name would read more clearly").
- Requests for more tests of the same shape on paths already tested. Flag missing tests only when an untested branch that can actually break exists.
- Readability or design preferences for code that works as specified and breaks no standard.
- Items the PR body says are deferred to another PR.
- Anything already raised or resolved in an earlier review.

### Volume

Do not cap the number of findings. Narrow them with the criteria and the rejection list; a cap drops real findings that passed the filter for no reason. If there seem to be too many, revisit the rejection list, not the count.

| Prefix | Use |
|--------|-----|
| `[MUST]` / `[MUST][ALERT]` | Only what should truly block the merge. Write all of them |
| `[IMO]` | Write every one that passes the filter. Non-blocking: the author may decline and still merge, and reviewers do not ask again |
| `[ASK]` | Only questions whose answer changes the merge decision |
| `[NITS]` | Not used; do not write minor findings |
| `[FYI]` | Not used; use the out-of-scope notes if needed |

Order findings by severity. With no `[MUST]` and no `[IMO]`, write "No significant findings" and stop. Zero findings is a normal result.

When several reviewers run in parallel, merge them into one post with duplicates removed, without cutting by count.

### Self-check before posting

Delete any finding for which you cannot answer:

1. If this merges unaddressed, what breaks, or who is affected, in one sentence?
2. Does the evidence point at a `path:line` in the diff?
3. Is it clear of the rejection list?

Then check the whole list once: can you pick the single most important finding? If the findings are too uneven in weight to choose, cut the lower ones.

---

## Scope

- Main targets: code, tests, CI workflows, scripts, the Nix flake, and related documentation in the diff.
- Focus areas, dug into only when the diff touches them:
  - Event handling: the listen-only CGEvent tap on `.flagsChanged`, Carbon hotkey registration, and their interaction with the system switcher shortcuts
  - Accessibility window enumeration, focus switching, and private API use in `Sources/PrivateAPIs`
  - Panel responsiveness: work done on the main actor between the hotkey and the panel appearing
  - Concurrency: actor isolation, `@MainActor` assumptions, and tests that wait on fixed real-time sleeps instead of on the event itself
  - Configuration: keybinding actions must be listed in the Swift code, `config/ConfigSchema.pkl` and `config/GenJsonSchema.pkl` alike, and the generated `config/schema-snapshot.json` and `config/config-schema.json` must match `scripts/regenerate-config.sh`
  - Permissions: the app declares Accessibility and Input Monitoring only; a change that needs Screen Recording or any other permission is a `[MUST]`
  - Vendored sources: hand edits in `Sources/CMigemo/` outside `migemo_utf8.c` and `include/migemo_utf8.h` are a `[MUST]`, because `scripts/vendor-cmigemo.sh` overwrites them
  - Packaging: the pinned `arm64-apple-macosx26.0` triple, bundle layout, code signing, and the cask in `Casks/`
- Report runtime-quality findings only for problems found. Do not list areas that are fine with checkmarks.

## Reference documents

| Priority | Document | Use |
|----------|----------|-----|
| 1 | `CONTRIBUTING.md` | Build, test and CI commands, vendored-source rules, language policy |
| 1 | `AGENTS.md` | Active technologies and required permissions |
| 2 | `README.md` | Product promises (permissions, memory, show latency) |
| 2 | `docs/src/content/docs/` | User-facing guide and usage pages that must match behavior |

## Review steps

1. Understand the purpose and reach of the change.
2. Settle the standards from the reference documents in priority order.
3. Check the boundaries: Hotkey, Window, PrivateAPIs, UI, configuration.
4. Check for bugs, spec mismatches, performance, security, and missing tests.
5. Apply the finding filter to every finding and keep the rest in severity order.
6. State remaining risks and open questions, then conclude.

## Judgment guide

- `[MUST]` is a blocker.
  - Incorrect behavior, a broken switch or hotkey, a crash, loss or corruption of the user's config, a serious boundary violation, a compatibility break, a security flaw (a new permission, unsafe private API use), a missing required test
  - Serious runtime defects: a visible regression of the show latency, unbounded memory growth, a state that cannot recover without relaunch, a failure that leaves no log
  - Use it only when you can say "merging this unfixed will cause an incident or rework". Otherwise drop it to `[IMO]`.
- `[IMO]` is non-blocking.
  - Design or maintainability suggestions tied to a concrete seed of a defect
  - The author may decline and still merge; reviewers do not ask again
  - "In general it should be like this" is not written even as `[IMO]` (see the rejection list)
- `[ASK]` is for questions that change the merge decision.
- `[MUST][ALERT]` is for contradictions, for example the Swift keybinding list disagreeing with the Pkl schema, or the docs pages describing behavior the code no longer has.
- `[NITS]` and `[FYI]` are not used.

## Out-of-scope notes

Optional, at most three lines. Keep pre-existing problems outside the diff out of the findings. If you write them, put bullets at the end with a `path` and a one-line summary each, without analysis or proposals. For something that deserves tracking, suggest filing a GitHub issue in one line.

## Output format

Output each section only when it has content.

1. Summary: what changed, in two or three lines
2. Findings: filtered findings in severity order, each as `[PREFIX] <title>` followed by evidence (`path:line`), impact and suggestion in three lines or fewer; if none passed, the single line "No significant findings"
3. Open Questions: only when there is an `[ASK]`
4. Out of scope: only when there is something, three lines at most
5. Decision: `Request changes`, `Approve with comments` or `Approve`

Do not output checklists or coverage tables that tick every area.
