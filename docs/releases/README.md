# Release notes per tag

`docs/releases/<tag>.md` (for example `docs/releases/v0.2.0-alpha.2.md`) is prepended to that tag's
release on the Releases page by `.github/workflows/release-linux.yml`, above GitHub's generated
changelog (the merged pull requests and commits since the previous tag).

Write here what the generated list can't say: what changed for players, what to download and how
to run it, the requirements, and the known issues - the shape the upstream project's own release
notes have. The file is optional: without one, the release carries the generated changelog alone.

Start from `v0.2.0-alpha.2.md`, the notes for the current version.