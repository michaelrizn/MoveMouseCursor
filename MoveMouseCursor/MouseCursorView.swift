import SwiftUI

struct MouseCursorView: View {
    @State private var isClicking = false
    @State private var clickCount = 0
    @State private var nextClickIn: Double = 5.0
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("X")
                    .font(.system(size: 24))
                    .padding(.trailing, 20)
            }
            
            Text("Mouse Cursor Clicker")
                .padding()
            
            Button(action: {
                isClicking.toggle()
                if isClicking {
                    nextClickIn = 5.0
                    startClicking()
                } else {
                    timer?.invalidate()
                    timer = nil
                }
            }) {
                Text(isClicking ? "Stop Clicking" : "Start Clicking")
            }
            
            Text("Click Count: \(clickCount)")
                .font(.headline)
                .padding(.top, 10)
            
            Text(String(format: "Next Click in: %.2f seconds", nextClickIn))
                .font(.headline)
                .padding(.top, 5)
            
            Button("Quit") {
                NSApplication.shared.terminate(self)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
    
    private func startClicking() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            nextClickIn -= 0.01
            if nextClickIn <= 0 {
                moveCursorToX()
                self.simulateMouseClick()
                self.clickCount += 1
                nextClickIn = 5.0
            }
        }
    }
    
    private func moveCursorToX() {
        let source = CGEventSource(stateID: .hidSystemState)
        let xPosition = NSApplication.shared.windows.first?.frame.midX ?? 0
        let yPosition = NSApplication.shared.windows.first?.frame.midY ?? 0
        let mouseMove = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: xPosition, y: yPosition), mouseButton: .left)
        mouseMove?.post(tap: .cghidEventTap)
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
