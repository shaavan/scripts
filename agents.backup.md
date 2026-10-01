# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

See [CONTRIBUTING.md](CONTRIBUTING.md) for build commands, testing, code style, and development workflow.

## Skills

At the very beginning of every new thread, before any other response, reasoning,
or action, load and activate the `caveman` skill in `ultra` mode. Ensure
`caveman::ultra` remains active for every response throughout the thread unless
the user explicitly disables or changes it.


## Personal Instructions

### Commit Rules

#### Conservative Work Mode

Work conservatively by default for every task. The user may explicitly opt out
of this mode for a task. Explicit instructions in the current request take
precedence over these defaults.

##### Before changing anything

- Treat the "top commit" as the current `HEAD` commit.
- Read the current branch, worktree status, and relevant commit stack before
  making changes.
- Apply only the part of the solution relevant to the current request.
- Preserve unrelated worktree changes.

##### Default output behavior

- Do not create, amend, reword, squash, reset, rebase, cherry-pick, or otherwise
  rewrite commits unless the user explicitly asks for that Git operation.
- By default, leave code changes uncommitted and report:
  - what changed,
  - where the changes belong in the stack,
  - what formatter/checks were run,
  - what tests were not run.
- If the changes belong to the top commit, leave them uncommitted and provide
  the complete updated commit message in the response.
- If only a commit message update is needed, provide the proposed message in
  text. Do not amend or reword the commit unless explicitly asked.
- If changes belong to an earlier non-top commit, leave them uncommitted and
  explain which commit they belong to.
- If changes are mixed or unclear, leave them uncommitted and report the
  ambiguity.

##### When committing is allowed

- Commit only when the user explicitly asks to create a commit.
- If the user asks to create a commit and the changes form one new atomic commit,
  commit them with a complete, verified commit message following the rules below.
- If the user asks to create a commit but the changes should be split, explain
  the split first unless the requested split is already clear.
- If the user asks for a "feat commit", "test commit", "fixup commit", or similar,
  that counts as permission to create that specific commit only.

##### Checks

- Run the required formatter and `git diff --check`.
- Do not run tests unless explicitly requested.
- State which tests were not run.

## Instructions for creating a plan

When writing a commit-by-commit plan:

1. Resolve and state the exact base commit (excluded) and head commit (included)
   of the relevant commit range, then read every commit message and full diff
   before preparing the plan. Do not assign work from commit titles alone.

2. Include every commit in the range exactly once and in ancestry order from the
   base to the head. Number entries starting from 1.

3. Format every heading exactly as:

   `Commit <number>: <exact original commit title> (<commit hash>)`

   Preserve the title and hash from the existing stack.

4. Place the instructions for a commit directly below its heading. Write them as
   clear, unambiguous, imperative implementation instructions.

5. For each commit requiring a follow-up, describe only work that belongs in that
   commit. Include production behavior, validation and failure behavior,
   compatibility requirements, public or internal documentation, serialization
   changes, or tests only when that category belongs in the commit under rule 7.

6. Assign a correction to the commit where it logically belongs in the final
   reviewable history, not merely the commit that last touched the affected
   line. The corrected stack must remain coherent at every commit.

7. When an issue spans multiple commits, split it explicitly:
   - place production changes in the relevant feature commit,
   - place regression coverage in the corresponding test commit,
   - place documentation changes in the commit that introduced the documented
     API or behavior.

   Do not duplicate the same implementation work across multiple entries.

8. If an earlier commit introduces infrastructure that is valid at that point,
   but a later commit uses it incorrectly, assign the correction to the later
   commit. Do not unnecessarily rewrite the earlier commit.

9. Name affected types, functions, fields, TLV types, or behaviors when known.
   State what must remain unchanged when that distinction prevents ambiguity.

10. If a commit requires no follow-up, write exactly:

    `NO CHANGES NEEDED`

    Do not add explanation or use another variation of this marker.

11. Keep all original commit titles and commit messages unchanged by default. If
    a planned follow-up would make the original commit message materially
    incomplete or inaccurate, explicitly instruct that the commit message needs
    rewriting and state what the rewritten message must cover. Do not propose a
    rewrite when the original message remains accurate.

12. Before presenting the plan, verify that:
    - the stated base and head resolve to the inspected commit range,
    - every commit in the range is present,
    - no commit appears more than once,
    - every identified issue has an owner,
    - production and test work are assigned separately where appropriate,
    - no instructions conflict across commits,
    - every unchanged commit uses the exact required marker.

## Instructions for following a plan

When the user provides a commit and instruction:

1. Confirm the current branch, worktree status, relevant commit stack, and
   expected position in the plan.
2. Read the supplied commit and instruction. Verify that the commit title and
   hash match the instruction and that it is the next commit expected by the
   plan. If any value does not match, stop and report the mismatch.
3. Determine whether an equivalent current commit is already present. If so,
   use it as the target without cherry-picking the supplied commit. Otherwise,
   cherry-pick the supplied commit and use the resulting commit as the target.
4. Resolve cherry-pick conflicts conservatively, only as required by the
   instruction. If a conflict cannot be resolved from the instruction, stop
   without resolving it speculatively.
5. If the instruction says `NO CHANGES NEEDED`, leave the target unchanged,
   create no follow-up commit, and proceed directly to the reporting step.
6. Preserve the target commit's title and message. If the instruction requires
   a rewritten commit message, record the complete updated message in a
   separate `squash!` commit without amending the target commit.
7. Implement only the requested changes for the target commit.
8. Run `cargo +1.75.0 fmt --all` and `git diff --check`.
9. Do not run tests unless the user explicitly requests them.
10. Overwrite the single repository-local file `.git/commit-msg` for the next
    commit message. Keep `.git/commit-msg` listed in `.git/info/exclude`.
11. Create an immediate autosquash-compatible follow-up commit with a properly
    wrapped message. If the instruction does not require a rewritten commit
    message, use the exact target commit title with the `fixup!` prefix:

   ```text
   fixup! <exact title of target commit>

   Instructions:

   <verbatim instruction body, excluding the commit heading>
   ```

   If the instruction requires a rewritten commit message, use the exact target
   commit title with the `squash!` prefix:

   ```text
   squash! <exact title of target commit>

   Updated commit message:

   <complete updated commit message>

   Instructions:

   <verbatim instruction body, excluding the commit heading>
   ```

12. Leave every `fixup!` and `squash!` commit separate while following the plan.
    Do not run the final autosquash rebase unless the user explicitly requests
    it.
13. Report the target commit and whether it was cherry-picked or already
    present, the follow-up commit type and hash or that none was required, the
    worktree status, and any conflict requiring the next instruction.

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
- For branch-heavy validation logic, prefer short comments that state the
  protocol invariant before the branch group, such as why a value is absent,
  externally supplied, derived from creation time, or allowed only as a
  confirmation of an existing value.
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

- Use a concise title in the form `[tag] <what is done>`. Use tags such as
  `[feat]`, `[plumb]`, `[test]`, `[feat/test]`, `[refactor]`, `[fixup]`, or
  `[docs]` according to the commit's role.
- Treat every PR revision as work in progress. Write each commit message as a
  self-contained description of the commit against its base branch, irrespective
  of earlier versions of the PR. Do not narrate how the commit changed from a
  previous revision or refer to superseded implementation details.
- Make titles describe what the commit does, not filenames or incidental
  implementation mechanics. Use consistent domain terminology and capitalization
  across the stack.
- Use the body mainly to explain why the commit exists. Include enough of the
  approach for the reviewer to understand the shape of the change, but avoid
  narrating code that is obvious from the diff.
- Keep commit bodies simple, direct, and readable. Prefer short paragraphs in
  plain language over dense summaries or broad claims.
- Maintain the PR narrative across commits. Each body should make clear how this
  commit fits in the stack and what is intentionally left to a later commit when
  that matters.
- Explain why a plumbing or refactor commit exists and what later behavior it
  enables. Explicitly state when logic is intentionally deferred to the next
  commit because that helps reviewers understand an otherwise mechanical diff.
- For behavior commits, describe the old limitation, the new behavior, and the
  invariant or failure condition enforced. For test commits, name the positive,
  negative, boundary, and end-to-end paths covered rather than listing test
  function names.
- Do not repeat the title, narrate obvious code, or include incidental process
  details such as conflict resolution. Keep the message proportional to the
  commit's complexity and readable both alone and in sequence.
- Wrap commit-message lines at 80 characters and separate paragraphs with blank
  lines. Read the commit after writing it, to ensure it's correctly wrapped.
- Write commit messages in a temporary file, verify their wrapping, paragraph
  breaks, and trailers, then pass the file to Git with `-F`.
- Disclose AI assistance in every AI-assisted commit with a short
  `AI-assisted:` note and the required `Co-Authored-By:` trailer.
- If AI was used, add the `AI-assisted:` line immediately before the
  `Co-Authored-By:` trailer, in the following form:
  `AI-assisted: <how it was used. For example: Used to plan, write and test the commit>`

#### PR Update Messages

When the user says "write the update message between `pr<N>.<T1>` and
`pr<N>.<T2>`":

- Compare the two local tags and identify only reviewer-relevant behavioral or
  structural changes.
- Return the message as Markdown in a fenced `md` block using this heading:
  `**Updated** [*.<T1> → .<T2>*](https://git.rust-bitcoin.org/shaavan/rust-lightning/compare/pr<N>.<T1>..pr<N>.<T2>)`.
- Use only as many short, high-signal bullets as needed. Combine related
  implementation and test changes instead of listing every changed file or
  commit.
- Prefer two simple bullets when that captures the update. Keep each bullet on
  one line without manual wrapping unless it becomes hard to read.

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
  - Write documentation for understanding, not merely brevity. Explain the purpose of a constant, helper, or policy; the invariant it preserves; and any important tradeoff behind its chosen behavior. Do not make comments terse when doing so removes context a reviewer needs to understand why the code exists or why specific values were chosen.
  - Prefer `match` over conditionals when it makes the code clearer. If using `match` would make the code more awkward or harder to follow, use conditionals instead.
  - Prefer improving readability through clearer local code structure before extracting new helpers. Use concise, descriptive names and add brief comments where the intent, control flow, or edge case being handled is not immediately obvious.
  - Use comments to explain why the code is written a certain way or what special case it handles. Do not add comments that only restate obvious operations.
  - For state-machine or validation ordering, write comments from the reviewer's perspective: first state the ordering or invariant being protected, then explain the bug it prevents. Prefer concrete phrases such as "associate the invoice with its pending payment" and "abandon the correct payment" over generic wording like "handle the state correctly."

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
