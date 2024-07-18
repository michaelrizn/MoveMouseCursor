import SwiftUI

struct MouseCursorView: View {
    @EnvironmentObject var statusBarController: StatusBarController
    @State private var customIntervalText = ""
    
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
                    Text("Control + 1")
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
    }
    
    private func setCustomInterval() {
        if let interval = Int(customIntervalText), interval > 0 {
            statusBarController.setCustomInterval(interval)
        }
    }
}

struct MouseCursorView_Previews: PreviewProvider {
    static var previews: some View {
        MouseCursorView()
            .environmentObject(StatusBarController())
    }
}
