import AVFoundation
import SwiftUI

enum CameraBackgroundStyle: String, CaseIterable, Identifiable {
    case none = "None"
    case blur = "Blur"
    case black = "Black"
    case white = "White"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"
    case pink = "Pink"

    var id: String { self.rawValue }

    var color: NSColor? {
        switch self {
        case .none: return nil
        case .blur: return nil
        case .black: return .black
        case .white: return .white
        case .blue: return NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        case .green: return NSColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)
        case .purple: return NSColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0)
        case .pink: return NSColor(red: 0.9, green: 0.4, blue: 0.6, alpha: 1.0)
        }
    }
}

struct CameraPreviewView: NSViewRepresentable {
    @EnvironmentObject var cameraManager: CameraManager
    @AppStorage("selectedBackground") private var selectedBackgroundRaw: String =
        CameraBackgroundStyle
        .none.rawValue

    private var selectedBackground: CameraBackgroundStyle {
        CameraBackgroundStyle(rawValue: selectedBackgroundRaw) ?? .none
    }

    final class PreviewNSView: NSView {
        override var wantsUpdateLayer: Bool { true }
        let videoLayer = AVCaptureVideoPreviewLayer()
        let backgroundLayer = CALayer()
        let blurView = NSVisualEffectView()

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer?.masksToBounds = true
            layer?.cornerRadius = 12
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.shadowColor = NSColor.black.cgColor
            layer?.shadowOpacity = 0.2
            layer?.shadowRadius = 6
            layer?.shadowOffset = CGSize(width: 0, height: -1)

            // Add background layer
            backgroundLayer.frame = bounds
            self.layer?.addSublayer(backgroundLayer)

            // Add blur view (hidden by default)
            blurView.frame = bounds
            blurView.material = .hudWindow
            blurView.blendingMode = .behindWindow
            blurView.state = .active
            blurView.isHidden = true
            addSubview(blurView, positioned: .below, relativeTo: nil)

            videoLayer.videoGravity = .resizeAspectFill
            self.layer?.addSublayer(videoLayer)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layout() {
            super.layout()
            backgroundLayer.frame = bounds
            blurView.frame = bounds
            videoLayer.frame = bounds
            if let connection = videoLayer.connection, connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }

        func updateBackground(_ style: CameraBackgroundStyle) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)

            if style == .blur {
                blurView.isHidden = false
                backgroundLayer.backgroundColor = nil
            } else {
                blurView.isHidden = true
                backgroundLayer.backgroundColor = style.color?.cgColor
            }

            CATransaction.commit()
        }
    }

    func makeNSView(context: Context) -> PreviewNSView {
        let v = PreviewNSView(frame: .zero)
        v.videoLayer.session = cameraManager.session
        v.updateBackground(selectedBackground)
        if let connection = v.videoLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        return v
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        nsView.videoLayer.session = cameraManager.session
        nsView.updateBackground(selectedBackground)
        if let connection = nsView.videoLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
    }
}
