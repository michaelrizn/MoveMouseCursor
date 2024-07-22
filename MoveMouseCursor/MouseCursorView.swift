import SwiftUI
import Carbon

struct MouseCursorView: View {
    @EnvironmentObject var statusBarController: StatusBarController
    @State private var customIntervalText = ""
    @State private var globalHotKey: HotKey?
    
    var body: some View {
        VStack {
            Text("Move Count: \(statusBarController.getClickCount())")
                .font(.headline)
                .padding(.top, 10)
            
            Text("Next Move in: \(statusBarController.nextMoveIn) seconds")
                .font(.headline)
                .padding(.top, 5)
            
            HStack {
                Text("Custom Interval (sec):")
                TextField("Enter interval", text: $customIntervalText, onCommit: setCustomInterval)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                Button("Set", action: setCustomInterval)
            }
            .padding(.bottom, 10)
            
            Button(action: {
                statusBarController.toggleMoving()
            }) {
                HStack {
                    Text(statusBarController.isMoving ? "Stop Moving" : "Start Moving")
                    Spacer()
                    Text("control+1, global shift+option+1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .keyboardShortcut("1", modifiers: [.control])
            .padding(.bottom, 10)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 300, height: 250)
        .onAppear(perform: setupGlobalHotkey)
    }
    
    private func setCustomInterval() {
        if let interval = Int(customIntervalText), interval > 0 {
            statusBarController.setCustomInterval(interval)
        }
    }
    
    private func setupGlobalHotkey() {
        globalHotKey = HotKey(key: kVK_ANSI_1, modifiers: [.shift, .option])
        globalHotKey?.keyDownHandler = {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .toggleMoving, object: nil)
            }
        }
    }
}

class HotKey {
    private var carbonHotKey: EventHotKeyRef?
    var keyDownHandler: (() -> Void)?

    init(key: Int, modifiers: NSEvent.ModifierFlags) {
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.id = UInt32(key)

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        // Create an UnsafeMutablePointer to self
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            let hotKey = Unmanaged<HotKey>.fromOpaque(userData!).takeUnretainedValue()
            DispatchQueue.main.async {
                hotKey.keyDownHandler?()
            }
            return noErr
        }, 1, &eventType, selfPtr, nil)

        let modifierKeys = carbonFlags(from: modifiers)
        RegisterEventHotKey(UInt32(key), UInt32(modifierKeys), gMyHotKeyID, GetApplicationEventTarget(), 0, &carbonHotKey)
    }

    private func carbonFlags(from cocoaFlags: NSEvent.ModifierFlags) -> Int {
        var carbonFlags: Int = 0
        if cocoaFlags.contains(.command) { carbonFlags |= cmdKey }
        if cocoaFlags.contains(.option) { carbonFlags |= optionKey }
        if cocoaFlags.contains(.control) { carbonFlags |= controlKey }
        if cocoaFlags.contains(.shift) { carbonFlags |= shiftKey }
        return carbonFlags
    }

    deinit {
        if let carbonHotKey = carbonHotKey {
            UnregisterEventHotKey(carbonHotKey)
        }
    }
}

extension Notification.Name {
    static let toggleMoving = Notification.Name("toggleMoving")
}

struct MouseCursorView_Previews: PreviewProvider {
    static var previews: some View {
        MouseCursorView()
            .environmentObject(StatusBarController())
    }
}
