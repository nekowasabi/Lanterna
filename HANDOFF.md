# Handoff: auto-focus a single candidate

Branch `feat/auto-focus-single-candidate` on `nekowasabi/Lanterna`. No pull request.

## What a Mac still has to run

AF-1 through AF-10 and AF-12 through AF-15 need `bash scripts/test.sh` on macOS 26 arm64. This Linux VM cannot compile the app. Those items are not verified. AF-11 is a source check and does not compile.

Do not treat a green Linux lint run as a green Mac test run.

## Open question

Two paths do not arm a wait, and this change leaves them that way.

- A query edit that moves the shown count from zero to one does not arm. AF-9 locks that. Typing `mailx` cancels the wait, and deleting back to `mail` does not start another.
- A scope switch that lands on one row does not arm. `toggleScope` lays the list out again without changing the query text. A refresh that did not change the query starts a wait only when a wait is already armed and the row's identity changed.

Whether either path should arm is a product choice. The code does not guess.

## Revert

The previous tip of this branch, before the swallow stretch and the 400 millisecond wait, is `3c2c6eda49bf2cc0611094612fd4056d9992b44b`. Reverting the later commits on this branch restores that behavior. Do not force-push.
