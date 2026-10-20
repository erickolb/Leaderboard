# Leaderboard for iOS

**Latest published app: [1.2 (build 4)](https://github.com/erickolb/Leaderboard/releases/tag/leaderboard-v1.2-build4)** — personal SideStore prerelease for iOS 26 or later.

[Download page and Add to SideStore](https://erickolb.github.io/Leaderboard/) · [SideStore source](https://erickolb.github.io/Leaderboard/apps.json) · [Setup and publishing guide](docs/sidestore.md)

The download page and source automatically track published IPAs, including personal prereleases. The release above is the current baseline; use the download page for subsequent versions.

A small native SwiftUI app for creating ranked lists, adding items, dragging them into order, and sharing the result as numbered text to Notes or any other app. It also includes a Share Extension for adding an Amazon Music album to an existing list.

## Requirements

- Xcode 26 or newer on a supported Mac
- iOS 26 or newer (physical-device testing targets iOS 26.6.2)

## Build an IPA for SideStore from Windows

The Mac needs Xcode and SSH-key access, but does not need Codex or an Apple signing account for this build. The script sends the current working files, including uncommitted changes, to a new directory under `~/LeaderboardBuilds` and downloads the finished IPA.

```powershell
.\scripts\build-on-mac.ps1 -BuildNumber 4
```

The default build host is `erickolb@barovia.chateaulore.net`. `HostKeyAlias` defaults to `barovia.local`, the name under which this Mac's SSH key was originally recorded. Increment the build number for each new distributed build. Each run retains its isolated Mac build directory and log for troubleshooting; these can be removed after the build is no longer needed.

Alternatively, run directly on a Mac:

```sh
BUILD_NUMBER=4 bash scripts/build-ipa.sh
```

The output is `dist/Leaderboard.ipa`. It has temporary ad-hoc signatures that preserve the App Group entitlements; it cannot be installed directly. SideStore supplies the device-valid signatures and provisioning profiles. No Apple password or distribution certificate is needed on the build Mac.

On the iPhone, save the IPA in Files, enable LocalDevVPN on Wi-Fi, and import it from SideStore's My Apps screen. Keep the share extension, with its own App ID/profile when offered. Refresh SideStore itself before the first installation. The app and extension resolve their shared App Group from their installed profiles so a signing-team suffix is supported.

Before relying on the build, check list persistence, sharing an Amazon Music album into a list, a SideStore refresh, and updating over an existing installation without deleting it. Device signing, App Group access, and data retention after a real update require physical-device validation.

To run the unit tests on the Mac, keep local simulator signing enabled so SwiftData can access the App Group:

```sh
xcodebuild -project Leaderboard.xcodeproj -scheme Leaderboard \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGNING_ALLOWED=YES test
```

## Run it

1. Open `Leaderboard.xcodeproj` in Xcode.
2. Select the `Leaderboard` scheme and an iPhone simulator.
3. Press Run.

## One-time signing setup for direct Xcode installation

The app and Share Extension use an App Group so both can access the same on-device lists.

1. Select the `Leaderboard` target, choose Signing & Capabilities, and select your development team.
2. Change `me.erickolb.Leaderboard` to a bundle identifier you own.
3. Repeat for `LeaderboardShare`, using the same prefix and an extension suffix.
4. Add the App Groups capability to both targets and create/select one shared group.
5. Replace `group.me.erickolb.Leaderboard` with that group in `Leaderboard/SharedModelContainer.swift` and both `.entitlements` files.

The renamed app uses new bundle identifiers and a new App Group. Register the group for both targets when using direct Xcode signing. SideStore manages provisioning for its own installations. Existing lists from a previously named installation are not migrated automatically.

The project uses SwiftData, so lists and their items persist automatically on the device. No account, server, or Apple Notes access is required.

## Included in this prototype

- Create and delete named lists
- Add and edit list items
- Drag to reorder using the standard Edit button and move handles
- Swipe to delete items
- Persistent on-device storage
- Share a numbered plain-text ranking via the iOS share sheet
- Share an Amazon Music album into Leaderboard, edit the detected `Artist — Album` text, choose a list, and append it
- App icon artwork supplied by Magnific on Flaticon, with attribution available from the in-app menu

Amazon Music’s share payload can vary. Leaderboard first tries the shared title and link metadata, then leaves the detected text editable so an album can always be added.

## Attribution

[Score board icons created by Magnific - Flaticon](https://www.flaticon.com/free-icons/score-board)
