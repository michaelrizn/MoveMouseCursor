import SwiftUI

struct MouseCursorView: View {
    @State private var cursorPosition: CGPoint = .zero
    
    var body: some View {
        Text("Mouse Cursor Mover")
            .padding()
            .onAppear {
                moveCursor()
            }
    }
    
    private func moveCursor() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            moveCursorToLeft()
        }
    }
    
    private func moveCursorToLeft() {
        let initialPosition = NSEvent.mouseLocation
        var newCursorPosition = initialPosition
        newCursorPosition.x -= 1
        CGWarpMouseCursorPosition(newCursorPosition)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            moveCursorToRight()
        }
    }
    
    private func moveCursorToRight() {
        let initialPosition = NSEvent.mouseLocation
        var newCursorPosition = initialPosition
        newCursorPosition.x += 1
        CGWarpMouseCursorPosition(newCursorPosition)
        
        // Recursive call to repeat the movement
        moveCursorToLeft()
    }
}
