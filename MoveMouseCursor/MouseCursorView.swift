import SwiftUI

struct MouseCursorView: View {
    @State private var isMoving = false
    @State private var moveCount = 0
    @State private var nextMoveIn: Double = 5.0
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack {
            Text("Mouse Cursor Mover")
                .padding()
            
            Button(action: {
                isMoving.toggle()
                if isMoving {
                    nextMoveIn = 5.0
                    moveCursor()
                } else {
                    timer?.invalidate()
                    timer = nil
                }
            }) {
                Text(isMoving ? "Stop Moving" : "Start Moving")
            }
            
            Text("Move Count: \(moveCount)")
                .font(.headline)
                .padding(.top, 10)
            
            Text(String(format: "Next Move in: %.2f seconds", nextMoveIn))
                .font(.headline)
                .padding(.top, 5)
            
            Button("Quit") {
                NSApplication.shared.terminate(self)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
    
    private func moveCursor() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            nextMoveIn -= 0.01
            if nextMoveIn <= 0 {
                self.moveCursorRandomly()
                self.moveCount += 1
                nextMoveIn = 5.0
            }
        }
    }
    
    private func moveCursorRandomly() {
        let currentPos = NSEvent.mouseLocation
        let xOffset = Int.random(in: -1...1)
        let yOffset = Int.random(in: -1...1)
        let newPos = CGPoint(x: currentPos.x + CGFloat(xOffset), y: currentPos.y + CGFloat(yOffset))
        CGDisplayMoveCursorToPoint(0, newPos)
        usleep(1000) // Add a small delay to ensure accurate movement
    }
}
