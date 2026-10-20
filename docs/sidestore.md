# SideStore source

Open https://erickolb.github.io/Leaderboard/ in Safari on your iPhone and tap **Add to SideStore**. Alternatively, add `https://erickolb.github.io/Leaderboard/apps.json` manually in SideStore's Sources screen.

Install Leaderboard from the source using your existing Apple account. Keep the share extension when prompted. If updating a local IPA installation, do not delete the existing app first: deleting it can remove your lists. Keep LocalDevVPN connected as required by your SideStore setup. Source updates and periodic signing refreshes are separate operations.

## Publishing

Publish a GitHub release tagged `leaderboard-vVERSION-buildNUMBER` (for example `leaderboard-v1.2-build4`) with exactly one `Leaderboard.ipa` asset. Upload the asset while the release is a draft, then publish. Both published prereleases and stable releases are included, because this repository distributes personal sideloaded builds. Drafts are excluded.

The Pages workflow runs on pushes to main, release publication/edits/removal, or manual dispatch. It reads the app and extension Info.plists from published IPAs, verifies identity, version, build and size, sorts versions numerically, and publishes the feed and current download page together. The newest build of each marketing version is retained. Increment the marketing version for broadly compatible update discovery; the feed also includes buildVersion. The App Group entitlement is declared for both app and share extension. Review feed permissions if signing entitlements change.

If deployment fails, the previous site remains available. Correct the release metadata or IPA and rerun **Publish download page**. Never replace a published IPA with a different version under the same tag. No server or container deployment is involved.
