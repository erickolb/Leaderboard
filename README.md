# AlbumRank for iOS

A small native SwiftUI app for creating ranked lists, adding items, dragging them into order, and sharing the result as numbered text to Notes or any other app. It also includes a Share Extension for adding an Amazon Music album to an existing list.

## Requirements

- Xcode 15 or newer
- iOS 17 or newer

## Run it

1. Open `AlbumRank.xcodeproj` in Xcode.
2. Select the `AlbumRank` scheme and an iPhone simulator.
3. Press Run.

## One-time signing setup

The app and Share Extension use an App Group so both can access the same on-device lists.

1. Select the `AlbumRank` target, choose Signing & Capabilities, and select your development team.
2. Change `com.example.AlbumRank` to a bundle identifier you own.
3. Repeat for `AlbumRankShare`, using the same prefix and an extension suffix.
4. Add the App Groups capability to both targets and create/select one shared group.
5. Replace `group.com.example.AlbumRank` with that group in `AlbumRank/SharedModelContainer.swift` and both `.entitlements` files.

The project uses SwiftData, so lists and their items persist automatically on the device. No account, server, or Apple Notes access is required.

## Included in this prototype

- Create and delete named lists
- Add and edit list items
- Drag to reorder using the standard Edit button and move handles
- Swipe to delete items
- Persistent on-device storage
- Share a numbered plain-text ranking via the iOS share sheet
- Share an Amazon Music album into AlbumRank, edit the detected `Artist — Album` text, choose a list, and append it
- App icon artwork supplied by Magnific on Flaticon, with attribution available from the in-app menu

Amazon Music’s share payload can vary. AlbumRank first tries the shared title and link metadata, then leaves the detected text editable so an album can always be added.

## Attribution

[Dvd icons created by Magnific - Flaticon](https://www.flaticon.com/free-icons/dvd)
