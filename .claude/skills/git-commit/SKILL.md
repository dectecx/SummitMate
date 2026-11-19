---
name: git-commit
description: Analyzes git changes and drafts structured Conventional Commits messages in English. Strictly enforces manual user commit without executing git commit directly.
---

# Git Commit Standard & Workflow

## Overview

This skill defines the Git commit message formatting rules and change-staging workflow for the SummitMate repository.

## Operational Constraints

1. **Never Execute `git commit` Directly**:
   - The assistant must never execute `git commit` or create commits automatically.
   - Output the exact suggested command and message for the user to review and execute manually.
2. **Language**: English only, unless explicitly instructed otherwise.
3. **No Internal Task IDs**: Do not include temporary task numbers, issue tracking IDs, or conversational references in the commit message.

## Commit Message Format

Follow the **Conventional Commits** specification:

```
<type>: <short summary>

[optional body with details]
```

### Commit Types

- `feat`: New feature or user-facing capability.
- `fix`: Bug fix or defect correction.
- `docs`: Documentation updates, schema markdown, or code comments.
- `refactor`: Code restructuring without behavioral changes or bug fixes.
- `test`: Adding, updating, or fixing unit, integration, or widget tests.
- `chore`: Build script, dependencies, code generation, or tooling maintenance.

### Formatting Guidelines

- **Short Changes**: A single concise line (e.g., `fix: prevent duplicate meal item insertion`).
- **Complex Changes**: Multi-line format:
  1. Summary line (imperative mood, present tense, max 72 characters, lowercase after prefix).
  2. One blank line.
  3. Bulleted list describing key modifications and architectural rationale.

### Example Multi-Line Commit Message

```text
feat: add meal plan day management to trip domain

- Introduce TripMealPlanDay entity and database tables in Go and Flutter
- Update TripMealItem references from day index to meal_plan_day_id
- Implement CASCADE deletion when a meal plan day is removed
```

## Workflow

1. **Inspect Working Tree**: Check `git status -s` and `git diff` to identify modified, added, and deleted files.
2. **Verify Change Boundaries**: Ensure changes are logically grouped and do not mix unrelated refactorings with feature additions.
3. **Draft Message**: Formulate the Conventional Commit message following the constraints above.
4. **Output Proposal**: Present the `git add <files>` command alongside the suggested commit message to the user.
