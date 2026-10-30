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

What the script publishes: a GitHub release `v<version>` targeting `main` with four
files and generated notes (install steps and the checksum):

| File | Used for |
|:--|:--|
| `Text-Assist-<version>.dmg` | First install by hand. |
| `Text-Assist-<version>.dmg.sha256` | Checksum of the DMG. |
| `Text-Assist-<version>.zip` | What the in-app updater downloads. |
| `appcast.xml` | The update feed: tells installed apps the newest version and where to get it. |

The ZIP and `appcast.xml` need Sparkle's `sign_update` and the private key from section 6
("Update signing key"); see "Appcast" there.

## 3. Verify a release

- The release page lists the DMG, the checksum file, the ZIP and `appcast.xml`, and shows as **Latest**.
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
open it with right-click, Open (the app is signed with a self-signed certificate, not notarized, so macOS blocks
a double-click the first time). In-app updates and Homebrew are tracked in epic #69.

## 6. Planned sections (filled in by their tasks)

These headings are placeholders so the guide keeps one shape; each task replaces its
section with the real steps.

### Update signing key

Every update the app downloads is checked against a public key built into the app. Only
the matching private key can sign an update the app will accept.

| | |
|:--|:--|
| Public key (`SUPublicEDKey`) | `mz2T+2yu4+J62XHpDoH7OqL1K0age+o6HxVENvWPvzc=` |
| Created | 2026-10-30, with Sparkle 2.10.1 `generate_keys` |
| Private key | In the maintainer's login Keychain (created by `generate_keys`). It is never in this repository. |
| Backup | A copy of the exported private key in the maintainer's password manager or other offline storage. |

The public key is not secret. It goes into `TextAssist/Info.plist` as `SUPublicEDKey`
(task #72).

**If the private key is lost, installed copies of the app can never be updated again, and
every user must reinstall by hand.** Do not generate a replacement key to "fix" this: a
new key cannot sign updates that old installs accept.

**Get the Sparkle tools** (once per machine; `generate_keys` and, later, `sign_update`
live in the release's `bin/` folder):

```sh
mkdir -p ~/sparkle-tools && cd ~/sparkle-tools
curl -L -o Sparkle-2.10.1.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.10.1/Sparkle-2.10.1.tar.xz
tar -xf Sparkle-2.10.1.tar.xz
```

**Check the key is there** (prints only the public key and must match the table above;
it never creates a new key when one exists):

```sh
~/sparkle-tools/bin/generate_keys -p
```

**Back up the private key** (once, and again if the Keychain item ever changes). Put the
file in a password manager or other offline storage, then delete the local copy:

```sh
~/sparkle-tools/bin/generate_keys -x ~/sparkle-private-key
rm ~/sparkle-private-key
```

**Restore it on a new machine** (needs the same file from the backup):

```sh
~/sparkle-tools/bin/generate_keys -f /path/to/sparkle-private-key
~/sparkle-tools/bin/generate_keys -p   # must print the public key from the table
```

Rules: never commit the private key or paste it into an issue, chat or log; agents never
generate, read or handle it. `Scripts/release.sh` signs updates through `sign_update`,
which reads the key from the Keychain (task #74), so releases are cut from the Mac that
holds it.

### Appcast

The app checks one fixed address:

```
https://github.com/GagikNav/textassist/releases/latest/download/appcast.xml
```

GitHub sends `releases/latest` to the newest **published** release. Draft and
pre-release versions are not served, so a draft release cannot be tested through this
address. Each release carries its own `appcast.xml` with a single item (the newest
version is all the app needs): version, build number, the ZIP's address and size, and its
signature.

What `release.sh` does for the update, after building and signing the app:

1. Zips the app (`ditto -c -k --sequesterRsrc --keepParent`) as `Text-Assist-<version>.zip`.
2. Signs the ZIP with Sparkle's `sign_update`, reading the private key from the login
   Keychain, then checks that the signature verifies.
3. Compares the app's `SUPublicEDKey` with the signing key. If they differ it stops,
   because installed copies would reject the update. If the app has no `SUPublicEDKey`
   yet (before the updater is built in), it only warns.
4. Writes `build/release/appcast.xml` (and checks it is well-formed XML with `xmllint`),
   then uploads DMG, checksum, ZIP and `appcast.xml` together.

`sign_update` is looked up in `$SPARKLE_BIN`, then `~/sparkle-tools/bin`, then the Sparkle
package folder under `build/DerivedData`. Set `SPARKLE_ED_KEY_FILE` to sign with a key file
instead of the Keychain (used for tests with a throwaway key; the guard in step 3 is skipped
then). `--no-sign` skips the ZIP and appcast.

Check a release: `gh release view v<version>` lists the four files, and
`curl -sL https://github.com/GagikNav/textassist/releases/latest/download/appcast.xml`
returns the new version. Withdrawing a release (section 4) as a pre-release makes `latest`,
and therefore the feed, go back to the previous release.

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

**Decision:** use a self-signed certificate, and switch at the first release that
contains the updater (#83; the steps are below). That release already needs a manual install,
so users re-grant Accessibility once there and not again. Revisit a Developer ID if the
app reaches people who cannot get past the Gatekeeper step. Keep ad-hoc signing for
local builds.

**How to confirm by hand (optional, about five minutes).** Build two versions with each
signing (`release.sh --skip-upload` twice), install the first in `/Applications`, grant
Accessibility, check Replace in TextEdit, quit, copy the second over it, relaunch and try
Replace again. With ad-hoc signing expect it to stop working (the System Settings entry
may still look enabled; toggle it off and on, or remove and re-add the app). With the
certificate expect it to keep working.

**Create the certificate (once, by the maintainer).** An agent must never generate or
handle the private key.

1. Open Keychain Access → menu **Keychain Access** → **Certificate Assistant** →
   **Create a Certificate…**.
2. Name: `Text Assist Release`. Identity Type: **Self Signed Root**. Certificate Type:
   **Code Signing**. Tick **Let me override defaults** and set the validity to about 3650
   days (10 years). Create it in the **login** keychain.
3. Check it: `security find-identity -v -p codesigning` lists `Text Assist Release`. (Some
   macOS versions show a self-signed root as not trusted; signing still works. If
   `codesign` complains, open the certificate, Trust → Code Signing → Always Trust.)

**Back it up.** In Keychain Access, open **My Certificates**, select `Text Assist Release`
(with its private key below it), and choose **File → Export Items…** as a `.p12` with a
strong password. Store the file and its password in the same password manager as the update
signing key. Never commit it.

**Restore on a new machine.** Copy the `.p12` over, double-click it (or
`security import Text-Assist-Release.p12 -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign`)
and enter the password. `security find-identity -v -p codesigning` must list it again.

**Use it.** Set the identity before running the release script:

```sh
export RELEASE_SIGN_IDENTITY="Text Assist Release"   # certificate name or SHA-1
Scripts/release.sh --bump patch --skip-upload
```

`release.sh` signs the archive and the final app with that identity, prints the
designated requirement (`codesign -dr -`), and stops if it has no `certificate leaf`, so a
release cannot silently go out ad-hoc. It also stops if the identity is not in the
Keychain. With `RELEASE_SIGN_IDENTITY` unset it signs ad-hoc as before, which is fine for
local builds. To compare two builds: run `codesign -dr - "build/release/Export/Text Assist.app"`
after each; the lines must be identical.

**If the certificate is lost.** A new certificate has a different requirement, so every
user re-grants Accessibility once. Keep the `.p12` backup safe.

### Homebrew
_To be written in #76 (installing and upgrading with `brew install --cask`)._
