---
name: run-harmonize
description: Runs the project's Harmonize architectural lint rules and explains how to fix violations from the JSON report. Use after you write or change Swift code, or when asked to run lint rules, check the architecture, or fix Harmonize violations.
---

# Run Harmonize rules

Harmonize is a Swift architectural linter. Its rules are unit tests. This skill runs the rules and interprets the results. It works in any project that uses Harmonize.

## Find the rules package

1. Find the repository root: the directory that contains `.harmonize.yaml`.
2. Find the Swift package that contains the rules: a `Package.swift` with a test target that depends on `Harmonize`. Run `grep -rl --include=Package.swift "Harmonize" .` and ignore the Harmonize library itself.

If the project has its own runner script or skill (for example `run-harmonize.sh` or a project `run-harmonize` skill), use it. It can filter the output or use a prebuilt workspace. The rest of this skill is the portable fallback.

## Run

Run from the repository root. Send the log to a file. Request the JSON report with one environment variable:

```bash
mkdir -p .harmonize-out
HARMONIZE_VIOLATIONS_FILE="$PWD/.harmonize-out/violations.json" \
swift test --package-path <rules-package> > .harmonize-out/test.log 2>&1
echo "exit code: $?"
```

- To run one rule, add `--filter <RuleTestClassName>` to the `swift test` command.
- With `xcodebuild`, name the variable `TEST_RUNNER_HARMONIZE_VIOLATIONS_FILE`. The prefix makes the variable reach the test process.
- Always pass an absolute path for the output file.
- Add `.harmonize-out/` to `.gitignore`.
- The test run fails on violations as usual. Harmonize writes the JSON file when the process exits.

## Interpret the result

Read the log only when this section tells you to.

- Exit code 0: all rules pass. `violations.json` contains `[]`.
- Exit code not 0, and `violations.json` has entries: read the file. Each entry has:
  - `ruleId` and `title`: the rule that failed.
  - `file`, `line`, `column`, `name`: the location of the violating declaration.
  - `message`: the rationale of the rule.
  - `howToFix`: how to correct the code.
- An entry with `"kind": "assertion"` is a rule-level failure, for example a stale baseline. A stale baseline entry is a known violation that now passes the rule. Remove the entry from the `baseline` list of the rule. Do not change production code for it.
- Exit code not 0, and `violations.json` is missing or `[]`: the rules did not run, or a test failed outside Harmonize. Search the log for `error:`. Fix the build first.

## Fix violations

1. For each violation, apply `howToFix`. If you need the examples, open the rule page of the generated skill: `references/*/<ruleId>.md`. If the project has no generated skill, open the rule source. Its file name is the rule id in PascalCase, unless the rule sets an explicit `id`.
2. Fix the production code. Change the rule only when the task is to change the rule.
3. Do not hide a new violation with a `baseline` entry. Use the baseline only for violations that existed before the rule.
4. Run the fixed rule alone with `--filter <RuleName>`. Then run the full suite.

## Learn the rules before you write code

If the project has a generated `harmonize` skill, use it before you write code. Its `SKILL.md` lists one reference file per layer. Open the file of the layer you will change. It lists the rules of that layer. Each rule links to a page with the rationale, the fix, and a bad and a good example. The skill does not list rules with `.deferred` disclosure, but Harmonize enforces them. Their test failures explain the fix.

The skill is generated from the rule sources. The generator does not build or run the tests:

```bash
swift package --package-path <rules-package> --allow-writing-to-package-directory \
  --allow-writing-to-directory <skills-dir> harmonize-skills
```

The output directory and the skill name come from `.harmonize.yaml` (`skills: { output: ..., name: ... }`). Projects usually run this from a pre-commit hook when rule files change. A CI check makes sure that the committed skill is current.
