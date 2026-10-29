# Project Agent Instructions

## Product Context

This repository is a native iOS photo-memory app built with Swift 6, SwiftUI, SwiftData, PhotosUI, Core Image, and RealityKit. It should feel like entering a collection of cozy medieval fantasy cottages full of photographed memories.

Before implementation work, read:

1. `docs/PRODUCT_DIRECTION.md`
2. `docs/IMPLEMENTATION_PLAN.md`
3. Only the relevant section of `docs/GITHUB_OPEN_SOURCE_RESEARCH.md`

Do not re-open broad product discussions when the documents already settle the decision.

## User-Facing Language

- Explain work to the user in Traditional Chinese.
- Use English for code identifiers, APIs, file names, and commit messages unless the user asks otherwise.
- User-facing UI copy should be localization-ready; Traditional Chinese is the primary design language.

## Conversation Boundary Policy

Proactively recommend a new conversation at a natural boundary when any of these becomes true:

- The current thread has crossed into a materially different phase, such as planning to implementation, a sprint boundary, or SwiftUI work to RealityKit asset work.
- Context compression has occurred and exact task details, decisions, or file state are becoming less reliable.
- The thread is carrying several unrelated workstreams and continuing would require repeatedly reconstructing old context.
- A new request would be cleaner and cheaper as a focused task with a fresh context window.
- The current task is complete and the next task has an independent goal.

Do not recommend a new conversation merely because a task is long, difficult, or has one failed build. Prefer continuing while the same objective and working context remain coherent.

When recommending a new conversation, tell the user directly and include a compact handoff:

- Why the boundary is useful.
- Current repository state.
- Files to read.
- Exact next Task ID or focused prompt.

The user wants this recommendation made without waiting to be asked.

## Token-Efficiency Rules

- One task means one vertical slice and one acceptance boundary.
- Use the Task ID and file scope in `docs/IMPLEMENTATION_PLAN.md`; do not restate the whole specification.
- Prefer `rg -n` for targeted searches instead of reading the whole repository.
- Avoid unrelated refactors; preserve existing user changes.
- Keep completion reports to Changed / Checks / Risks, with at most three concise lines each unless a failure needs detail.
- Stop after three unsuccessful attempts at the same root cause and report the blocker.

## Engineering Invariants

- Deployment target is iOS 18+; Swift 6 language mode.
- SwiftData stores metadata only. Original photos and derivatives live in the app container.
- Persist relative paths, never sandbox absolute URLs.
- Import files through staged writes and commit metadata last.
- Do not hold full-resolution `UIImage` objects in gallery lists or SwiftData models.
- Do not use synchronous image decoding, encoding, or disk I/O on the main actor.
- Do not introduce a generic carousel dependency for the core experience.
- Keep RealityKit and SwiftData out of Domain models.
- Verify on macOS/Xcode; never claim an iOS build or Instruments result from a Windows-only run.

## Visual Direction

The mandatory primary direction is **cozy medieval magic cottage / illuminated manuscript fantasy**, not generic high-fantasy RPG UI. Details are in `docs/PRODUCT_DIRECTION.md`.

