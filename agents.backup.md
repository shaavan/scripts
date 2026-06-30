# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

See [CONTRIBUTING.md](CONTRIBUTING.md) for build commands, testing, code style, and development workflow.

## Skills

At the very beginning of every new thread, before any other response, reasoning,
or action, load and activate the `caveman` skill in `ultra` mode. Ensure
`caveman::ultra` remains active for every response throughout the thread unless
the user explicitly disables or changes it.

## Workspace Structure

See [README.md](README.md) for the workspace layout and [ARCH.md](ARCH.md) for some additional remark regarding important parts of LDK's architecture.

## Development Rules

- Always ensure tests pass before committing. To this end, you should run
  `cargo test` for all affected crates and/or features. Upon completion
  of the full task you might prompt the user whether they want you to run the
  full CI tests via `./ci/ci-tests.sh`. Note however that this script will run
  for a very long time, so please don't timeout when you do.
- Run `cargo +1.75.0 fmt --all` after every code change
- Never add new dependencies unless explicitly requested
- Please always disclose the use of any AI tools in commit messages and PR descriptions using a `Co-Authored-By:` line.
- When adding new `.rs` files, please ensure to always add the licensing header as found, e.g., in `lightning/src/lib.rs` and other files.
- When adding comments, do not refer to internal logic in other modules, instead
  make sure comments make sense in the context they're in without needing other
  context.
- Try to keep code DRY - if new code you add is duplicate with other code,
  deduplicate it.


## Personal Instructions

### Commit Rules

#### Conservative Work Mode

When the user says to "work conservatively":

- Follow explicit instructions in the current request over these defaults, and
  treat the "top commit" as the current `HEAD` commit.
- Read the current branch, worktree status, and relevant commit stack before
  making changes.
- Apply only the part of the solution relevant to the current request. Preserve
  unrelated worktree changes.
- If the resulting worktree changes belong to the top commit, leave them
  uncommitted and provide the complete updated commit message in the response.
  Do not amend the commit.
- If the resulting changes form a new atomic commit, commit them with a complete,
  verified commit message following the rules below.
- If changes belong to an earlier non-top commit, leave them uncommitted and
  explain where they belong. Do not rewrite history unless explicitly asked.
- Do not combine mixed or unclear worktree changes into a commit. Report the
  ambiguity instead.
- Run the required formatter and `git diff --check`, but do not run tests unless
  explicitly requested. State that tests were not run.
- Do not amend, rebase, reset, squash, or cherry-pick unless explicitly asked.

#### Preferred PR Style

- Structure PRs as a readable sequence of small commits: introduce the
  foundational API first, thread it through callers second, activate behavior
  third, and add focused tests last.
- Keep each commit atomic enough that a reviewer can understand its purpose
  without reading later commits. If a commit intentionally does not change
  behavior yet, say that in the commit message body.
- In commit messages, explain the problem or stale behavior first, then the
  chosen approach, then any important invariant, lock-ordering rule, or
  compatibility constraint the commit preserves.
- Use simple, direct language in both comments and commit messages. Prefer
  short paragraphs that explain why the code is shaped a certain way over
  broad claims or implementation narration.
- For non-obvious state selection, explicitly document why each state is
  included or skipped. For example, say why a `Used` state needs action and why
  a `Ready` state can be left to an existing refresh or rotation path.
- For lock-sensitive behavior, avoid doing heavy work while holding locks.
  Prefer marking work as pending and processing it after locks are released,
  with comments explaining why the deferral exists.
- When adding a new path parallel to an existing one, reuse the canonical
  helper for the shared behavior and make the new path differ only in the
  selection or trigger logic.

#### PR and Stack Structure

- Read the full existing PR commit range and its diffs before changing it. Treat
  the commit series as a reviewable narrative, not merely a record of when work
  happened.
- Build a feature in dependency order:
  1. Introduce the foundational type, trait, or API.
  2. Thread dependencies through production APIs and all affected test, fuzz,
     binding, and helper scaffolding without enabling new behavior.
  3. Add the smallest coherent behavior change.
  4. Add focused unit or component tests.
  5. Repeat plumbing, behavior, and test stages for the next subsystem.
  6. Finish with end-to-end coverage after both producer and consumer sides are
     implemented.
- Keep plumbing separate from logical behavior even when this makes the
  plumbing commit large. Mechanical breadth is acceptable when the commit has
  one purpose and prepares the next behavior commit.
- Land prerequisite semantic refactors before features that depend on them.
  When one API represents two concepts, split those concepts explicitly instead
  of adding more boolean or implicit-state handling at call sites.
- Separate independently reviewable sides of a protocol flow. For example,
  implement and test construction or payee behavior before implementing and
  testing verification or payer behavior.
- Place each new commit immediately after the nearest logically related commit,
  not automatically at `HEAD`. Reorder the local stack when needed, but avoid
  unrelated history rewriting.
- Attach a correction directly to the commit it fixes. Use a fixup commit while
  iterating, then autosquash when appropriate so the final stack reads cleanly.
- Every commit must represent one logical change, avoid unrelated cleanup, and
  leave the tree compiling with its applicable tests passing.

#### Change-Writing Pattern

- Design foundational APIs before threading them through callers. Provide a
  clear unsupported or no-op implementation when callers need a default path.
- Pass new dependencies explicitly through generic parameters or constructors;
  keep one canonical implementation path rather than duplicating conversion,
  validation, or state logic across call sites.
- Update every affected layer in a plumbing commit, including downstream crates,
  fuzz targets, test utilities, and alternate construction paths. Do not leave
  hidden follow-up compile fixes for later commits.
- Preserve existing behavior during plumbing and refactor commits. Activate new
  behavior only in the dedicated feature commit.
- Keep behavior changes narrow. Reuse the newly introduced abstraction, expose
  only APIs required by the feature, and document public behavior and errors.
- Prefer semantic result and error distinctions over collapsed generic errors
  when callers must react differently to unsupported, invalid, insufficient, or
  excessive values.
- Cover the standard path plus meaningful failure and boundary paths. Include
  missing support, insufficient or excessive values, quantity scaling,
  alternate key or construction paths, and end-to-end flow when relevant.
- Small tests tightly coupled to a small behavior change may share a
  `[feat/test]` commit. Substantial test additions belong in a following `[test]`
  commit so behavior and coverage remain independently reviewable.
- Test public behavior at the narrowest useful layer first, then add integration
  coverage for the complete workflow. Preserve negative coverage for behavior
  that must continue to fail.

#### Commit Messages

- Use a concise imperative title in the form `[tag] <what changed>`. Use tags
  such as `[feat]`, `[plumb]`, `[test]`, `[feat/test]`, `[refactor]`, `[fixup]`,
  or `[docs]` according to the commit's role.
- Make titles describe the user-visible capability or structural purpose, not
  filenames or implementation mechanics. Use consistent domain terminology and
  capitalization across the stack.
- Structure the body as context and motivation, then the change and approach,
  then its role in the stack or important constraints. Omit a section when it
  adds no useful information.
- Explain why a plumbing or refactor commit exists and what later behavior it
  enables. Explicitly state when logic is intentionally deferred to the next
  commit because that helps reviewers understand an otherwise mechanical diff.
- For behavior commits, describe the old limitation, the new behavior, and the
  invariant or failure condition enforced. For test commits, name the positive,
  negative, boundary, and end-to-end paths covered rather than listing test
  function names.
- Do not repeat the title, narrate obvious code, or include incidental process
  details such as conflict resolution. Keep the message proportional to the
  change and readable both alone and in sequence.
- Wrap commit-message lines at 80 characters and separate paragraphs with blank
  lines. Read the commit after writing it, to ensure it's correctly wrapped.
- Write commit messages in a temporary file, verify their wrapping, paragraph
  breaks, and trailers, then pass the file to Git with `-F`.
- Disclose AI assistance in every AI-assisted commit with a short
  `AI-assisted:` note when useful and the required `Co-Authored-By:` trailer.

#### PR Update Messages

When the user says "write the update message between `pr<N>.<T1>` and
`pr<N>.<T2>`":

- Compare the two local tags and identify only reviewer-relevant behavioral or
  structural changes.
- Return the message as Markdown in a fenced `md` block using this heading:
  `**Updated** [*.<T1> → .<T2>*](https://github.com/shaavan/rust-lightning/compare/pr<N>.<T1>..pr<N>.<T2>)`.
- Use only as many short, high-signal bullets as needed. Combine related
  implementation and test changes instead of listing every changed file or
  commit.

#### Work Session Narratives

When the user asks for the "narrative flow of today's work":

- Write chronological prose rather than a changelog, checklist, or bullet list.
- Start from the issue or point in the session named by the user and follow the
  reasoning through investigation, implementation, review feedback, and the
  final direction.
- Include important nuances: approaches tried, why they were insufficient or
  replaced, invariants discovered, regressions found, and how each correction
  changed the final design.
- Distinguish exploratory or superseded work from changes that remain in the
  final stack. Do not present every attempted fix as part of the final solution.
- Explain how the commits fit together when commit structure was part of the
  work, but avoid listing hashes unless requested.
- Mention formatting and test outcomes when relevant, including when tests were
  intentionally not run or were run by the user from an external log.
- Use simple, direct language. Do not include links or file references unless
  the user asks for them.


### Coding Style Rules

  - When adding a new function, whether it is part of the main logic or a helper, always include in-code comments and documentation that explain its purpose.
  - Prefer `match` over conditionals when it makes the code clearer. If using `match` would make the code more awkward or harder to follow, use conditionals instead.
  - Prefer improving readability through clearer local code structure before extracting new helpers. Use concise, descriptive names and add brief comments where the intent, control flow, or edge case being handled is not immediately obvious.
  - Use comments to explain why the code is written a certain way or what special case it handles. Do not add comments that only restate obvious operations.

### Serialization and Persistence Compatibility

- Treat all `Writeable`, `Readable`, TLV fields, enum discriminants, and macro-based serialization layouts as stable persisted or wire formats unless the code or task explicitly states otherwise.
- Never change an existing TLV type number, enum discriminant, or serialized field meaning for already-shipped data structures without explicit user approval.
- When adding serialized fields, use a new unused TLV type or a versioned compatibility path; do not repurpose an existing one.
- Before editing any `impl_writeable_*`, `write_tlv_fields!`, `read_tlv_fields!`, or serialized enum definition, inspect the existing layout and preserve backward compatibility.
- For any serialization-format change, explicitly call out the compatibility impact in your summary and add or run tests that cover deserialization compatibility where feasible.
- If there is any uncertainty whether a serialized type is already released, persisted, or used on the wire, assume that it is and preserve compatibility.

### Invariant Preservation

- Before changing validation, parsing, serialization, payment/state transitions, or security-sensitive logic, identify the invariant being preserved and verify how the old code enforced it.
- When relaxing a check for one case, explicitly verify that other cases still require the original check. Do not generalize from one subtype of input to all inputs without confirming each case in code.
- For behavior changes, preserve or add negative tests for inputs that must still fail.
- If a change affects attacker-controlled, persisted, serialized, or externally supplied data, treat it as high-risk and verify old and new behavior concretely before finalizing.

### Helper Reuse and Invariants

- Before adding branch logic or reimplementing validation or state logic inline, first check whether an existing helper already expresses the intended invariant.
- Prefer the highest-level existing helper whose semantics match the requirement rather than reconstructing part of its logic locally.
- If you do not use an existing nearby helper that appears relevant, briefly justify why it is not correct for the case before introducing custom logic.
- When fixing a regression, avoid minimal local patches that duplicate existing logic unless reusing the helper would be clearly incorrect.
- For protocol, parsing, serialization, persistence, and validation code, prefer existing canonical helpers and compatibility paths over local reimplementation.
