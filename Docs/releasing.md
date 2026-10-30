# Releasing Text Assist

How versions work and how to cut a release. Releases are made by hand from the main
checkout with `Scripts/release.sh`; there is no CI. For script options and prerequisites
see the [release script guide](../Scripts/README.md).

## 1. Versioning scheme

| Thing | Rule |
|:--|:--|
| Version | Semantic version `X.Y.Z` (for example `0.2.1`). |
| Git tag / GitHub release | `v<version>` (for example `v0.2.1`), release title `Text Assist v0.2.1`. |
| `CFBundleShortVersionString` | `X.Y.Z`, the version users see. |
| `CFBundleVersion` | Number of commits on `main` (`git rev-list --count HEAD`). It must always increase; update tools compare this number, not the version text. |
| What changes the version | Before 1.0: **minor** for new features or visible changes, **patch** for fixes. From 1.0 on: standard semantic versioning (major for breaking changes). |

The tag and the script are the source of truth. `MARKETING_VERSION` in
`TextAssist.xcodeproj/project.pbxproj` is still `1.0`; it is not edited (the project file
is off limits to agents) and the script overrides it at build time. Debug builds
therefore report `1.0`.

Rules that keep the build number increasing:

- Cut releases only from `main` (the script enforces this).
- Do not rewrite the history of `main`. Squash merges are fine; force-pushes are not.
- Never reuse a version number. If a release is bad, withdraw it (section 4) and publish
  the next version.

## 2. Cut a release

Prerequisites: Xcode command line tools, `brew install create-dmg gh jq`, and
`gh auth login`.

1. Merge everything for the release to `main` and pull it:
   ```sh
   git checkout main && git pull
   ```
2. Pick the version. Either name it, or bump from the highest existing `v*` tag:
   ```sh
   Scripts/release.sh --bump patch --skip-upload   # builds 0.x.(y+1) locally, publishes nothing
   ```
   `--bump patch|minor|major` refreshes tags from `origin` first (a release created on
   GitHub only exists as a tag on the remote). Pass an explicit `X.Y.Z` instead of
   `--bump` to choose the number yourself. The script refuses to run with neither.
3. Check the result in `build/release/`: `Text-Assist-<version>.dmg` and its `.sha256`.
   The script already checks that the built app reports the requested version and build
   number, and that the binary contains both `arm64` and `x86_64`.
4. Publish. A draft lets you look at the release page before anyone can see it:
   ```sh
   Scripts/release.sh <version> --draft
   ```
   Then open the draft on GitHub, edit the notes, and press **Publish release**. Without
   `--draft` the release is public immediately.
5. Do the checks in section 3.

What the script publishes today: a GitHub release `v<version>` targeting `main` with
`Text-Assist-<version>.dmg`, `Text-Assist-<version>.dmg.sha256` and generated notes
(install steps and the checksum). The ZIP and `appcast.xml` used for in-app updates are
added by the update-feed task and documented in section 6.

## 3. Verify a release

- The release page lists the DMG and the checksum file, and shows as **Latest**.
- `gh release view v<version>` shows the right tag; `git fetch --tags` then
  `git tag --list 'v*'` shows it locally.
- Download the DMG, check it: `shasum -a 256 -c Text-Assist-<version>.dmg.sha256`.
- Install it to `/Applications`, open it (first launch: right-click, Open), and check the
  version with:
  ```sh
  defaults read "/Applications/Text Assist.app/Contents/Info" CFBundleShortVersionString CFBundleVersion
  ```

## 4. Withdraw a bad release

Always publish a fixed, higher version afterwards; never reuse the number.

- Quickest, keeps the files: mark it as a pre-release. GitHub's `latest` then points to the
  previous release again.
  ```sh
  gh release edit v<version> --prerelease
  ```
- Remove it completely, including the tag:
  ```sh
  gh release delete v<version> --cleanup-tag --yes
  git tag -d v<version>   # local copy, if you have one
  ```

## 5. How users install today

Download the DMG from the latest release, drag **Text Assist** to **Applications**, then
open it with right-click, Open (the app is ad-hoc signed and not notarized, so macOS blocks
a double-click the first time). In-app updates and Homebrew are tracked in epic #69.

## 6. Planned sections (filled in by their tasks)

These headings are placeholders so the guide keeps one shape; each task replaces its
section with the real steps.

### Update signing key
_To be written in #71 (Sparkle key: where the public and private keys live, backup, and
what happens if the private key is lost)._

### Appcast
_To be written in #74 (the ZIP and `appcast.xml` that the release script uploads, and how
the app finds the newest release)._

### Signing and permissions

Text Assist needs the Accessibility permission to read the selection and to Replace.
macOS records that permission against the app's **code requirement** and checks it again
every time the app runs. If a new version no longer satisfies the requirement that was
recorded, macOS treats it as a different app and the permission stops working.

**What was measured (spike #77, macOS 27.0.1).** Two versions of the app (9.0.1 and 9.0.2,
same source, different version and build number) were built and signed in each way, and
`codesign -v --test-requirement` checked whether the second satisfied the requirement of
the first:

| Signing | Requirement (`codesign -dr -`) | Version 2 satisfies version 1's? |
|:--|:--|:--|
| Ad-hoc (`release.sh` today) | `cdhash H"f7f3…"`, the build's own hash, different for every version | **No** |
| Stable self-signed certificate | `identifier "com.gagik.TextAssist" and certificate leaf = H"<certificate hash>"` | **Yes** |
| Certificate version 1 vs ad-hoc version 2 (switching once) | certificate requirement against an ad-hoc build | No (one-time reset) |

The controls (each build against its own requirement) passed.

**What was not measured.** The check shows the requirement macOS compares; it did not
change the Accessibility setting, because granting it is a system security setting that
only the person at the machine may change. To confirm on a real machine, see "How to
confirm by hand" below.

**Options**

| Option | Cost | Accessibility after an update | Gatekeeper on first manual install |
|:--|:--|:--|:--|
| Keep ad-hoc signing | Free | Expected to be lost after every update; users re-grant each time | Blocks; right-click, Open |
| Self-signed certificate, same one for every release | Free; one certificate to create and back up | Kept | Blocks; right-click, Open |
| Apple Developer ID plus notarization | Paid yearly; `notarytool` step in `release.sh` | Kept | No block; also allows the official Homebrew cask repository |

**Recommendation:** use a self-signed certificate now, and switch at the first release
that contains the updater (tracked in #83). That release already needs a manual install,
so users re-grant Accessibility once there and not again. Revisit a Developer ID if the
app reaches people who cannot get past the Gatekeeper step. Keep ad-hoc signing for
local builds.

**How to confirm by hand (optional, about five minutes).** Build two versions with each
signing (`release.sh --skip-upload` twice), install the first in `/Applications`, grant
Accessibility, check Replace in TextEdit, quit, copy the second over it, relaunch and try
Replace again. With ad-hoc signing expect it to stop working (the System Settings entry
may still look enabled; toggle it off and on, or remove and re-add the app). With the
certificate expect it to keep working.

**If the certificate is lost.** A new certificate has a different requirement, so every
user re-grants Accessibility once. Back up the exported certificate next to the update
signing key.

### Homebrew
_To be written in #76 (installing and upgrading with `brew install --cask`)._
