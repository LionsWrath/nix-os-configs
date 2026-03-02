# GitHub PR Workflow (Repository Policy)

Use pull requests for all changes.

## Standard flow

```bash
git checkout -b feature/<short-name>
# edit files
git add .
git commit -m "<clear change summary>"
git push -u origin feature/<short-name>
```

Then open PR against `main`.

## Review checklist

- Scope is clear and limited
- Breaking changes documented
- Security implications called out
- Rollback plan stated when applicable
- Configuration changes tested where possible

## Merge rule

- Do not push directly to `main`
- Merge only through reviewed PR
