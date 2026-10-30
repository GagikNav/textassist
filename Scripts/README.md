# Release Script

`release.sh` builds a universal macOS release of Text Assist, packages it as a
DMG, calculates a SHA-256 checksum, and can publish both files as a GitHub
Release. It is intended to be run manually by a maintainer from the main
checkout; it is not a CI script.

## Requirements

- macOS with Xcode and `xcodebuild` available
- [`create-dmg`](https://github.com/create-dmg/create-dmg), install with
  `brew install create-dmg`
- [`gh`](https://cli.github.com/) and [`jq`](https://jqlang.github.io/jq/)
  installed; `gh` must be authenticated unless using `--skip-upload`
- A configured `origin` remote for the GitHub repository

The release contains a universal app for Apple Silicon (`arm64`) and Intel
(`x86_64`), targeting macOS 13 and later. It is ad-hoc signed and is not
notarized. Gatekeeper may block the first launch; the release notes include
ways to open the app.

## Usage

Run the script from a clean-enough main checkout on the `main` branch:

```sh
Scripts/release.sh <version> [options]
Scripts/release.sh --bump patch|minor|major [options]
```

Exactly one of `<version>` or `--bump` is required. A version must be `X.Y.Z`; the
corresponding Git tag is `v<version>`. `--bump` raises the highest existing `v*` tag
(refreshed from `origin`) by one patch, minor or major step. `MARKETING_VERSION` in the
Xcode project is stale and is no longer used as a default. For example:

```sh
Scripts/release.sh 1.2.0 --draft
Scripts/release.sh --bump patch --draft
```

After building, the script checks that the app reports the requested version and
build number. See [Docs/releasing.md](../Docs/releasing.md) for the versioning
scheme and the full release steps.

The script refuses to run from a task worktree or a branch other than `main`,
and stops if the version tag or GitHub Release already exists. A dirty working
tree produces a warning rather than stopping the release, so commit or inspect
your changes before continuing.

| Option | Effect |
| --- | --- |
| `--bump LEVEL` | Next version from the highest `v*` tag (`patch`, `minor` or `major`). |
| `--skip-upload` | Build the DMG and checksum without creating a GitHub Release. |
| `--no-sign` | Skip ad-hoc signing. Intended for local testing only. |
| `--draft` | Create the GitHub Release as a draft. |
| `-h`, `--help` | Print the command usage. |

## Outputs

Build artifacts are written under `build/release/`:

- `Text-Assist-<version>.dmg`
- `Text-Assist-<version>.dmg.sha256`
- The archived and exported app, plus Xcode logs

Without `--skip-upload`, the script creates a GitHub Release named
`Text Assist v<version>` targeting `main`, and uploads the DMG. The generated
release notes include installation guidance and the DMG checksum.

## Other Scripts

- `run.sh` builds the Debug app and opens it; pass `--no-open` to only build.
- `build-dmg.sh` archives and packages the app locally, without publishing a
  GitHub Release.
