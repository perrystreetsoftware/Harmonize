---
name: run-harmonize
description: Runs the project's Harmonize architectural lint rules and explains how to fix violations from the machine-readable JSON output. Use after you write or change Swift code, or when asked to run lint rules, check the architecture, or fix Harmonize violations.
---

# Run Harmonize rules

Harmonize is a Swift architectural linter. Its rules are unit tests. This skill runs the rules and interprets the results. It works in any project that uses Harmonize.

## Find the rules package

1. Find the repository root: the directory that contains `.harmonize.yaml`.
2. Find the Swift package that contains the rules: a `Package.swift` with a test target that depends on `Harmonize`. Run `grep -rl --include=Package.swift "Harmonize" .` and ignore the Harmonize library itself.

If the project has its own runner script or skill (for example `run-harmonize.sh` or a project `run-harmonize` skill), use it. It can filter the output or use a prebuilt workspace. The rest of this skill is the portable fallback. It explains the output in both cases.

## Run

Run from the repository root. Request machine-readable output with two environment variables:

```bash
HARMONIZE_VIOLATIONS_FILE="$PWD/.harmonize-out/violations.json" \
HARMONIZE_RULE_CATALOG_FILE="$PWD/.harmonize-out/rules.json" \
swift test --package-path <rules-package>
```

- To run one rule, append `--filter <RuleTestClassName>`.
- With `xcodebuild`, prefix each variable with `TEST_RUNNER_` (for example `TEST_RUNNER_HARMONIZE_VIOLATIONS_FILE`). The variable then reaches the test process.
- Always pass absolute paths for the output files.
- The test run fails on violations as usual. Harmonize writes the JSON files when the process exits.

## Interpret the result

- Exit code 0: all rules pass. `violations.json` is empty or absent.
- Non-zero exit code with violations: read `violations.json`. Do not scrape the build log. Each entry has:
  - `ruleId`: the rule that failed. Look it up in `rules.json` for the full metadata.
  - `file`, `line`, `column`, `name`: the location of the violating declaration.
  - `message`: the rationale of the rule.
  - `howToFix`: how to correct the code.
- An entry with `"kind": "assertion"` is a rule-level failure, for example a stale baseline. A stale baseline entry is a known violation that now passes the rule. Remove the entry from the `baseline` list of the rule. Do not change production code for it.
- Compilation errors: the rules did not run. Fix the build first.

## Fix violations

1. For each violation, apply `howToFix`. If you need more context, find the rule by `ruleId` in `rules.json`. The `definedIn` field gives the source file. Read its rationale and examples.
2. Fix the production code. Change the rule only when the task is to change the rule.
3. Do not hide a new violation with a `baseline` entry. Use the baseline only for violations that existed before the rule.
4. Run the fixed rule alone with `--filter <RuleName>`. Then run the full suite.

## Learn the rules before you write code

If the project has a generated `harmonize` skill, use it before you write code. Its `SKILL.md` lists one reference file per layer. Open the file of the layer you will change. It lists the rules of that layer. Each rule links to a page with the rationale, the fix, and a bad and a good example. The skill does not list rules with `.deferred` disclosure, but Harmonize enforces them. Their test failures explain the fix.

`rules.json` lists every rule that ran, with the full metadata. Use it to look up a `ruleId`.

The skill is generated from the rule sources. The generator does not build or run the tests:

```bash
swift package --package-path <rules-package> --allow-writing-to-package-directory \
  --allow-writing-to-directory <skills-dir> harmonize-skills
```

The output directory and the skill name come from `.harmonize.yaml` (`skills: { output: ..., name: ... }`). Projects usually run this from a pre-commit hook when rule files change. A CI check makes sure that the committed skill is current.
