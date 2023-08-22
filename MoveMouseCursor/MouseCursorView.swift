import SwiftUI

struct MouseCursorView: View {
    @State private var isClicking = false
    @State private var clickCount = 0
    @State private var nextClickIn: Double = 60.0
    @State private var customIntervalText = ""
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack {
            Text("Click Count: \(clickCount)")
                .font(.headline)
                .padding(.top, 10)
            
            Text(String(format: "Next Click in: %.2f seconds", nextClickIn))
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
                isClicking.toggle()
                if isClicking {
                    clickCount = 0
                    startClicking()
                } else {
                    timer?.invalidate()
                    timer = nil
                }
            }) {
                HStack {
                    Text(isClicking ? "Stop Clicking" : "Start Clicking")
                    Spacer()
                    Text("Control + 1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .keyboardShortcut("1", modifiers: [.control])
            .padding(.bottom, 10)
            
            Button("Quit") {
                NSApplication.shared.terminate(self)
            }
        }
        .padding()
        .frame(width: 300, height: 250)
    }
    
    private func startClicking() {
        if let interval = Double(customIntervalText), interval > 0 {
            nextClickIn = interval
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            nextClickIn -= 0.01
            if nextClickIn <= 0 {
                self.simulateMouseClick()
                self.clickCount += 1
                if let interval = Double(self.customIntervalText), interval > 0 {
                    self.nextClickIn = interval
                } else {
                    self.nextClickIn = 60.0
                }
            }
        }
    }
    
    private func setCustomInterval() {
        if let interval = Double(customIntervalText), interval > 0 {
            nextClickIn = interval
        }
    }
    
    private func simulateMouseClick() {
        let source = CGEventSource(stateID: .hidSystemState)
        let mousePos = CGPoint(x: NSApplication.shared.windows.first?.frame.midX ?? 0,
                               y: NSApplication.shared.windows.first?.frame.midY ?? 0)
        let mouseClick = CGEvent(mouseEventSource: source, mouseType: .otherMouseDown, mouseCursorPosition: mousePos, mouseButton: .center)
        mouseClick?.post(tap: .cghidEventTap)
        let mouseRelease = CGEvent(mouseEventSource: source, mouseType: .otherMouseUp, mouseCursorPosition: mousePos, mouseButton: .center)
        mouseRelease?.post(tap: .cghidEventTap)
    }
}

struct MouseCursorView_Previews: PreviewProvider {
    static var previews: some View {
        MouseCursorView()
    }
}
