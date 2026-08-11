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
