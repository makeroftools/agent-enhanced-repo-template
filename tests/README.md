# Tests

This directory contains the smoke-test suite for the Copier template.

## Files
- `generate_and_check.sh` — generates a project with recommended answers and asserts the
  required structure and protocols are present.

## Running
From the template root:

```
uv run copier copy --defaults --data-file tests/answers.yml . /tmp/check-output
bash tests/generate_and_check.sh /tmp/check-output
```

The script exits non-zero on any structural failure.

## Environmental note: `.copier-answers.yml`

In this environment, Copier 9.17.1 does **not** auto-write `.copier-answers.yml` when
running `copier copy` (reproduced with a barebones template, so it is environmental, not
a template defect). Because `copier update` needs that answers file for `_src_path` /
`_commit`, a true end-to-end update cannot be bootstrapped here. To run a real update
test, either use an environment where Copier writes the answers file, or generate the
answers file manually and run `uv run copier update --defaults --trust <proj>` against a
pushed tag (e.g. `v0.1.0`).
