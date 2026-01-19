import Foundation
import AVFoundation
import Combine
import AppKit

// Runtime diagnostic for missing usage string
// Shows a console warning (and a DEBUG alert) if NSCameraUsageDescription is missing.

@MainActor
final class CameraManager: ObservableObject {
    enum AuthorizationState {
        case notDetermined
        case authorized
        case denied
    }

    @Published private(set) var authorization: AuthorizationState = .notDetermined
    @Published private(set) var isRunning: Bool = false
    @Published var availableDevices: [AVCaptureDevice] = []
    @Published var selectedDevice: AVCaptureDevice? {
        didSet { Task { await configureSession() } }
    }

    let session = AVCaptureSession()

    private var videoInput: AVCaptureDeviceInput?

    // Dedicated serial queue for all session operations to avoid blocking main thread and ensure AVFoundation thread-safety
    private let sessionQueue = DispatchQueue(label: "CameraManager.sessionQueue")

    // Notification tokens
    private var deviceWasConnectedObserver: NSObjectProtocol?
    private var deviceWasDisconnectedObserver: NSObjectProtocol?

    // MARK: - Diagnostics
    private var hasWarnedMissingUsageString = false
    private var hasCameraUsageString: Bool {
        if let value = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String {
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }

    private func warnIfMissingUsageString() {
        guard !hasWarnedMissingUsageString else { return }
        if !hasCameraUsageString {
            hasWarnedMissingUsageString = true
            NSLog("[Mirror] Missing NSCameraUsageDescription in Info.plist. macOS will deny camera access and the app will not appear in Privacy & Security > Camera. Add NSCameraUsageDescription to your target's Info.")
            #if DEBUG
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Missing NSCameraUsageDescription"
            alert.informativeText = "Add NSCameraUsageDescription to your target's Info. Without it, macOS will auto‑deny camera access and your app will not appear in Privacy & Security > Camera."
            alert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
            #endif
        }
    }

    init() {
        session.sessionPreset = .high

        // Observe device connection changes to keep device list fresh without polling
        deviceWasConnectedObserver = NotificationCenter.default.addObserver(forName: .AVCaptureDeviceWasConnected, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.loadDevices() }
        }
        deviceWasDisconnectedObserver = NotificationCenter.default.addObserver(forName: .AVCaptureDeviceWasDisconnected, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.loadDevices() }
        }

        Task { await refreshAuthorizationAndDevices() }
        warnIfMissingUsageString()
    }

    deinit {
        if let o = deviceWasConnectedObserver { NotificationCenter.default.removeObserver(o) }
        if let o = deviceWasDisconnectedObserver { NotificationCenter.default.removeObserver(o) }
    }

    func refreshAuthorizationAndDevices() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            authorization = .notDetermined
        case .authorized:
            authorization = .authorized
        case .denied, .restricted:
            authorization = .denied
        @unknown default:
            authorization = .denied
        }
        await loadDevices()
        if selectedDevice == nil { selectedDevice = availableDevices.first }
    }

    func requestAccess() async {
        NSApp.activate(ignoringOtherApps: true)
        warnIfMissingUsageString()
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            authorization = .authorized
            await loadDevices()
            if selectedDevice == nil { selectedDevice = availableDevices.first }
            return
        }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        authorization = granted ? .authorized : .denied
        await loadDevices()
        if selectedDevice == nil { selectedDevice = availableDevices.first }
    }

    private func loadDevices() async {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified)
        let devices = discovery.devices.sorted { ($0.localizedName, $0.uniqueID) < ($1.localizedName, $1.uniqueID) }
        availableDevices = devices
        // Keep selected device if still available
        if let selected = selectedDevice, !devices.contains(where: { $0.uniqueID == selected.uniqueID }) {
            selectedDevice = devices.first
        }
    }

    func startSessionIfAuthorized() {
        switch authorization {
        case .authorized:
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                guard !self.session.isRunning else { return }
                self.configureSessionSync()
                self.session.startRunning()
                DispatchQueue.main.async { self.isRunning = true }
            }
        case .notDetermined:
            Task { [weak self] in
                await self?.requestAccess()
                guard let self = self, self.authorization == .authorized else { return }
                self.sessionQueue.async {
                    guard !self.session.isRunning else { return }
                    self.configureSessionSync()
                    self.session.startRunning()
                    DispatchQueue.main.async { self.isRunning = true }
                }
            }
        case .denied:
            break
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async { self.isRunning = false }
            }
        }
    }

    private func configureSession() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                self?.configureSessionSync()
                continuation.resume()
            }
        }
    }

    private func configureSessionSync() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // Remove previous input
        if let input = videoInput {
            session.removeInput(input)
            videoInput = nil
        }

        guard let device = selectedDevice ?? availableDevices.first else { return }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                videoInput = input
            }
        } catch {
            NSLog("[Mirror] Failed to create device input: \(error)")
            return
        }
    }
}

