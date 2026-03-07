# Contributing to Markviewz

Thanks for your interest in contributing! This document covers our workflow, standards, and expectations.

## Git Workflow

We follow a **git flow** branching model:

- **`main`** — stable, release-ready code. Never commit directly to main.
- **`develop`** — integration branch for features. PRs from feature branches target develop.
- **`feature/*`** — new features branch off develop (e.g., `feature/syntax-highlighting`)
- **`bugfix/*`** — bug fixes branch off develop (e.g., `bugfix/dark-mode-contrast`)
- **`release/*`** — release prep branches off develop, merges to main and develop
- **`hotfix/*`** — urgent fixes branch off main, merge to both main and develop

### Workflow

1. Create a GitHub issue describing the work
2. Branch from `develop` using the naming convention above
3. Make your changes with clear, focused commits
4. Open a PR against `develop` referencing the issue (e.g., "Closes #12")
5. Address review feedback
6. Squash-merge when approved

## Issues

Every change — feature, bug fix, refactor, docs update — starts with a GitHub issue. This keeps our work trackable and discussable.

- Use the provided issue templates
- Label issues appropriately (`enhancement`, `bug`, `documentation`, etc.)
- Assign yourself when you start working on an issue

## Pull Requests

- One PR per issue, one issue per PR
- Use the PR template
- Keep PRs focused — avoid mixing unrelated changes
- All PRs require review before merging
- Reference the issue number in the PR description

## Code Standards

### Swift

- Follow standard Swift conventions and naming guidelines
- Use SwiftUI idioms where applicable
- Keep files focused — one primary type per file
- No force unwraps (`!`) unless there is a clear invariant

### General

- Keep it simple. This is a lightweight viewer — resist feature creep.
- No Electron, no web servers, no heavyweight dependencies
- Test on both light and dark mode
- Verify the install script works end-to-end

## Quality Checks

Before submitting a PR:

1. `swift build` passes with no warnings
2. `swift build -c release` produces a working binary
3. `./install.sh` completes successfully
4. Manual test: open a `.md` file, verify rendering

## Reporting Bugs

Use the bug report issue template. Include:

- macOS version
- How you installed (install.sh, manual build)
- Steps to reproduce
- Expected vs. actual behavior
- Sample `.md` file if relevant

## Feature Requests

Use the feature request issue template. Describe:

- The problem you're trying to solve
- Your proposed solution
- Why it fits Markviewz's scope (lightweight, read-only, viewer)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
