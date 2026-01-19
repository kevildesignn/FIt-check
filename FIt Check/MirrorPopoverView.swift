import AVFoundation
import SwiftUI

struct MirrorPopoverView: View {
    @EnvironmentObject var cameraManager: CameraManager

    var body: some View {
        Group {
            switch cameraManager.authorization {
            case .authorized:
                VStack(spacing: 8) {
                    CameraPreviewView()
                        .environmentObject(cameraManager)
                        .frame(
                            minWidth: 320, idealWidth: 360, maxWidth: .infinity, minHeight: 200,
                            idealHeight: 240, maxHeight: .infinity
                        )
                        .overlay(alignment: .topTrailing) {
                            if cameraManager.availableDevices.count > 1 {
                                Picker(
                                    "Camera",
                                    selection: Binding(
                                        get: {
                                            cameraManager.selectedDevice?.uniqueID ?? ""
                                        },
                                        set: { newID in
                                            let device = cameraManager.availableDevices.first(
                                                where: { $0.uniqueID == newID })
                                            cameraManager.selectedDevice = device
                                        })
                                ) {
                                    ForEach(cameraManager.availableDevices, id: \.uniqueID) {
                                        device in
                                        Text(device.localizedName).tag(device.uniqueID)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .padding(6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(8)
                            }
                        }
                        .overlay(alignment: .topLeading) {
                            BackgroundPickerView()
                        }
                }
                .padding(6)
            case .notDetermined:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Requesting camera access…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .task { await cameraManager.requestAccess() }
                .frame(width: 320, height: 220)
            case .denied:
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .symbolRenderingMode(.hierarchical)
                    Text("Camera access is disabled")
                        .font(.headline)
                    Text("Enable camera access in System Settings > Privacy & Security > Camera.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Button("Open System Settings") {
                        Permissions.openCameraPrivacySettings()
                    }
                }
                .frame(width: 320, height: 220)
                .padding()
            }
        }
        .frame(width: 360, height: 240)
    }
}

#Preview {
    MirrorPopoverView()
        .environmentObject(CameraManager())
}
