# CamControl

Makes the iPhone Camera Control button (iPhone 16 or later, iOS 18+) run an action you choose: open an app, run a shortcut, open a URL, or trigger a Shortcuts automation.

- **Unlocked:** the app opens and runs the action.
- **Lock Screen:** iOS asks for Face ID or your passcode, then the action runs. If Face ID has already unlocked the phone, it runs straight away.

## How it works

| Piece | Role |
|---|---|
| `Shared/CaptureIntent.swift` | The `CameraCaptureIntent` that makes the app a Camera Control option. It's compiled into both the app and the extension. When the phone is unlocked, `perform()` tells the app to run the action. |
| `CaptureExtension/` | Lock Screen capture extension (`com.apple.securecapture`). iOS only ever launches this from the Lock Screen, so it immediately asks to open the app. |
| `App/` | The action list and editor, plus the splash shown while an action runs |

The app never uses the camera. iOS still requires camera permission before it will let you pick the app for Camera Control.

## Install

### From a release

Download `CamControl.ipa` from the [Releases](../../releases) page. It's unsigned, so install it with a tool that signs it with your Apple ID, such as Sideloadly or AltStore.

### Build it yourself

To sign with your own Apple ID, create `Config/Signing.local.xcconfig` (it's gitignored):

```
DEVELOPMENT_TEAM = YOUR_TEAM_ID
BUNDLE_ID_PREFIX = com.yourname.camcontrol
```

Then, to build a signed IPA for a connected, registered iPhone:

```bash
xcodegen generate
xcodebuild -project CameraControlShortcut.xcodeproj -scheme CameraControlShortcut -configuration Release -destination 'generic/platform=iOS' -derivedDataPath build/dd -allowProvisioningUpdates build
cd build && rm -rf Payload && mkdir Payload && cp -R dd/Build/Products/Release-iphoneos/CameraControlShortcut.app Payload/ && zip -qry CamControl.ipa Payload
```

Install the IPA with Finder (select the iPhone in the sidebar and drag the IPA onto it) or with `xcrun devicectl device install app --device <UDID> build/CamControl.ipa`.

To build an unsigned IPA instead (what the releases contain):

```bash
xcodebuild -project CameraControlShortcut.xcodeproj -scheme CameraControlShortcut -configuration Release -destination 'generic/platform=iOS' -archivePath build/CamControl.xcarchive CODE_SIGNING_ALLOWED=NO archive
cd build && rm -rf Payload && mkdir Payload && cp -R CamControl.xcarchive/Products/Applications/CameraControlShortcut.app Payload/ && zip -qry CamControl.ipa Payload
```

### After installing

1. Open CamControl and allow camera access.
2. Go to *Settings → Camera → Camera Control → Launch Camera* and choose **CamControl**. It stays greyed out until camera access is granted.

## Notes

- **Open App** only works for apps with a URL scheme (e.g. `myapp://`). For any other app, make a shortcut with an *Open App* step and use **Run Shortcut**.
- **Run Shortcut** briefly shows the Shortcuts app while it runs.
- **Shortcuts Automation** avoids that: create a personal automation in Shortcuts for *App → CamControl → Is Opened → Run Immediately*. On a press, CamControl shows its splash for a second, then goes to the Home Screen while the automation runs. The automation also runs whenever you open CamControl yourself.
- When Camera Control launches the app, iOS expects it to use the camera. CamControl listens for capture events instead, so iOS doesn't kill it.
