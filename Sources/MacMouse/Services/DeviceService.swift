import Foundation
import IOKit.hid

struct MouseDevice: Identifiable, Equatable, Sendable {
    let id: UInt64
    let name: String
}

@MainActor
final class DeviceService: ObservableObject {
    @Published private(set) var devices: [MouseDevice] = []
    var onDisconnect: (() -> Void)?
    private var manager: IOHIDManager?

    func start() {
        guard manager == nil else { return }
        let value = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(0))
        manager = value
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(value, { context, _, _, device in
            guard let context else { return }
            MainActor.assumeIsolated {
                Unmanaged<DeviceService>.fromOpaque(context).takeUnretainedValue().connected(device)
            }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(value, { context, _, _, device in
            guard let context else { return }
            MainActor.assumeIsolated {
                Unmanaged<DeviceService>.fromOpaque(context).takeUnretainedValue().disconnected(device)
            }
        }, context)
        IOHIDManagerScheduleWithRunLoop(value, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let matching = [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                       kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse] as [String: Int]
        // Enumeration only: no device open, seize, input report or value callback.
        IOHIDManagerSetDeviceMatching(value, matching as CFDictionary)
        if let set = IOHIDManagerCopyDevices(value) as? Set<IOHIDDevice> {
            for device in set { connected(device) }
        }
    }

    func stop() {
        guard let manager else { return }
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerRegisterDeviceMatchingCallback(manager, nil, nil)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, nil, nil)
        self.manager = nil
    }

    private func identifier(_ device: IOHIDDevice) -> UInt64 {
        var id: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(IOHIDDeviceGetService(device), &id)
        return id
    }
    private func connected(_ device: IOHIDDevice) {
        func property(_ key: String) -> Any? { IOHIDDeviceGetProperty(device, key as CFString) }
        let name = property(kIOHIDProductKey) as? String ?? "Mouse esterno"
        let builtIn = (property("Built-In") as? NSNumber)?.boolValue ?? false
        guard !builtIn, !name.localizedCaseInsensitiveContains("trackpad") else { return }
        let mouse = MouseDevice(id: identifier(device), name: name)
        devices.removeAll { $0.id == mouse.id }
        devices.append(mouse)
        devices.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    private func disconnected(_ device: IOHIDDevice) {
        let id = identifier(device)
        let existed = devices.contains { $0.id == id }
        devices.removeAll { $0.id == id }
        if existed { onDisconnect?() }
    }
}
