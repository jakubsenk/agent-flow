# Phase 0: Input

The user ran the ceos-agents scaffold pipeline on a project (`licence-ceos-agents-yt2`) and has the following feedback about issues to fix:

1. **Design quality is mediocre** — the generated application's visual design/UI isn't great. How to improve it next time?
2. **Stories not linked as subtasks in YouTrack** — Epics were closed in YT, but stories aren't linked with parent/subtask relationships (parent for / subtask of). They're only mentioned in the epic's description text.
3. **Stories not closed after completion** — Step 8b relies on YouTrack cascading close from epic to sub-issues, but if stories aren't actually sub-issues, they won't cascade-close.
4. **No comments on issues** — Neither epics nor stories have any comment about what was actually done or implemented.
5. **Czech without diacritics** — The pipeline used Czech language but dropped all diacritics (hacky, carky), producing e.g. "uzivatel" instead of "uzivatel".
6. **Positive**: Application is functional, makes sense, met the requirements.
