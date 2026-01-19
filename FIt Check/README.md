# Camera Preview App

A macOS SwiftUI app that previews camera input with selectable background styles (blur, black, white, and vibrant colors). Built with AVFoundation and SwiftUI.

## Features
- Camera preview using `AVCaptureVideoPreviewLayer`
- Background styles: None, Blur, Black, White, Blue, Green, Purple, Pink
- Mirrored preview and portrait orientation

## Requirements
- macOS with a camera
- Xcode
- Camera access permissions

## Getting Started
1. Open the Xcode project/workspace in Xcode.
2. Build and run the app.
3. Choose a background style from settings (stored with `@AppStorage`).

## Notes
- The preview is mirrored for a more natural self-view.
- Background blur uses `NSVisualEffectView` with `.hudWindow` material.
