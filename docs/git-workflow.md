# GitFlow workflow

Status: required project policy. Repository created on 2026-10-06.

## Repository identity

Public repository: https://github.com/AIBeCe/AirDCObjC, created using the user's `Momachilles` account. `develop` was initialized first; `feature/project-documentation` starts from that baseline. Repository setup and documentation commits do not authorize product implementation or release publication.

## Branches

- `develop`: development integration branch.
- `main`: production release branch; no direct feature development.
- `feature/*`: branch from `develop`, implement a bounded approved point/phase, review, and merge into `develop`.
- `bugfix/*`: branch from `develop`, review, and merge into `develop`.
- `release/*`: branch from `develop`; release preparation merges into `main` and back into `develop`.
- `hotfix/*`: branch from `main`; production fixes merge into both long-lived branches.

Every new feature, point, or phase starts from `develop`. Continuing fixes for the same unmerged feature stay on its existing branch; do not create a replacement branch merely for another review round.

The initial documentation feature starts from `develop`. Establish only the minimum bootstrap required for branch ancestry; do not put unfinished framework implementation on `main`. First production content and release tag reach `main` through a reviewed release flow.

## Work sequence

1. Inspect current branch and worktree state without discarding user changes.
2. Read established design and the relevant phase plan once; inspect exact changed sections as needed.
3. Analyze and present one implementation point with actual proposed code and tests.
4. Obtain explicit approval before edits; stop if evidence invalidates the approved design.
5. Implement on the relevant feature branch, verify and review material changes.
6. Make small cohesive commits and update progress/coverage documents with durable facts.
7. Integrate only after required checks and review. Remote publishing and releases follow their specific authorization.

Preserve persistent worker/reviewer ownership and use direct follow-up routing for routine review/fix cycles as required by the supplied AGENTS.md. Root retains architectural, scope and approval authority.

Do not commit acquired dependencies, generated binaries, private profiles, credentials, temporary logs or raw build evidence. Version source, tooling, exact input policies and meaningful normalized documentation.
