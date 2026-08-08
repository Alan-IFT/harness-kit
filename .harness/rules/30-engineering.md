## Software engineering basics

16. Commit messages in imperative mood, ≤72 char subject, body explains the why.
17. PR-able diffs: each commit is a coherent unit; don't bundle unrelated changes.
18. No commit of files in `参考/` (private reference folder, in `.gitignore`).
19. No commit of secrets, `.env`, or local user paths.
20. One implementation per script. Windows support was removed in v0.49.0, so there is no `.ps1` twin to keep in step; `verify_all` F.1 FAILs if one reappears under a scripts directory.
