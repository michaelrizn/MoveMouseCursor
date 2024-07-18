import SwiftUI
import AppKit
import IOKit.pwr_mgt

class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    private var timer: Timer?
    @Published var isMoving = false
    @Published var nextMoveIn: Int = 60
    private var moveInterval: Int = 60
    private var moveCount: Int = 0
    private var moveLeft = true
    private var assertionID: IOPMAssertionID = 0

    init() {
        setupStatusBar()
        setupEventMonitor()
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusBarButton = statusItem?.button {
            statusBarButton.image = NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: "Движение курсора")
            statusBarButton.action = #selector(togglePopover)
            statusBarButton.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 250)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MouseCursorView().environmentObject(self))
        
        print("StatusBarController инициализирован")
    }
    
    @objc func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                closePopover(sender: nil)
            } else {
                showPopover()
            }
        }
    }
    
    func showPopover() {
        if let statusBarButton = statusItem?.button {
            popover?.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.minY)
            eventMonitor?.start()
        }
    }
    
    func closePopover(sender: Any?) {
        popover?.performClose(sender)
        eventMonitor?.stop()
    }
    
    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [NSEvent.EventTypeMask.leftMouseDown, NSEvent.EventTypeMask.rightMouseDown]) { [weak self] event in
            if let self = self, let popover = self.popover, popover.isShown {
                self.closePopover(sender: event)
            }
        }
    }
    
    func toggleMoving() {
        isMoving.toggle()
        if isMoving {
            startMoving()
        } else {
            stopMoving()
        }
        updateStatusBarIcon()
    }
    
    func startMoving() {
        nextMoveIn = moveInterval
        moveLeft = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        preventSleep()
    }
    
    func stopMoving() {
        timer?.invalidate()
        timer = nil
        nextMoveIn = moveInterval
        allowSleep()
    }
    
    private func updateTimer() {
        if nextMoveIn > 0 {
            nextMoveIn -= 1
        } else {
            simulateMouseMove()
            nextMoveIn = moveInterval
        }
        updateStatusBarIcon()
    }
    
    private func updateStatusBarIcon() {
        DispatchQueue.main.async {
            if self.isMoving {
                self.statusItem?.button?.title = "\(self.nextMoveIn)"
                self.statusItem?.button?.image = nil
            } else {
                self.statusItem?.button?.title = ""
                self.statusItem?.button?.image = NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: "Движение курсора")
            }
        }
    }
    
    private func simulateMouseMove() {
        let moveDistance: CGFloat = 1 // Изменение: движение на число пикселей, тип CGFloat
        let currentPosition = NSEvent.mouseLocation
        let screenFrame = NSScreen.main!.frame
        
        var newX = currentPosition.x + (moveLeft ? -moveDistance : moveDistance)
        
        // Проверяем, не вышли ли мы за границы экрана
        newX = max(0, min(newX, screenFrame.width - 1))
        
        // Преобразуем координаты в систему координат CGPoint
        let newPosition = CGPoint(x: newX, y: screenFrame.height - currentPosition.y)
        
        // Создаем событие мыши для перемещения курсора
        let mouseMoveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: newPosition, mouseButton: .left)
        mouseMoveEvent?.post(tap: .cghidEventTap)
        
        moveLeft.toggle() // Меняем направление для следующего движения
        moveCount += 1
    }
    
    private func preventSleep() {
        let reason = "MoveCursor is active" as CFString
        IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
    }
    
    private func allowSleep() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
    
    func setCustomInterval(_ interval: Int) {
        moveInterval = interval
        if !isMoving {
            nextMoveIn = interval
        }
    }
    
    func getClickCount() -> Int {
        return moveCount
    }
}

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
