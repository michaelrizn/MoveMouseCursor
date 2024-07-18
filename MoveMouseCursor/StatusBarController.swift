import SwiftUI
import AppKit

class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    private var timer: Timer?
    @Published var isMoving = false
    @Published var nextMoveIn: Int = 60
    private var moveInterval: Int = 60
    private var clickCount: Int = 0

    init() {
        setupStatusBar()
        setupEventMonitor()
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusBarButton = statusItem?.button {
            statusBarButton.image = NSImage(systemSymbolName: "cursorarrow.rays", accessibilityDescription: "Движение курсора")
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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func stopMoving() {
        timer?.invalidate()
        timer = nil
        nextMoveIn = moveInterval
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
                self.statusItem?.button?.image = NSImage(systemSymbolName: "cursorarrow.rays", accessibilityDescription: "Движение курсора")
            }
        }
    }
    
    private func simulateMouseMove() {
        let currentMousePosition = NSEvent.mouseLocation
        let screenFrame = NSScreen.main!.frame
        
        // Вычисляем новую позицию курсора (например, сдвиг на 1 пиксель вправо)
        var newX = currentMousePosition.x + 1
        var newY = currentMousePosition.y
        
        // Проверяем, не вышли ли мы за границы экрана
        if newX >= screenFrame.width {
            newX = 0 // Перемещаем курсор в левую часть экрана
        }
        if newY >= screenFrame.height {
            newY = 0 // Перемещаем курсор в нижнюю часть экрана
        }
        
        // Преобразуем координаты в систему координат CGPoint
        let newPosition = CGPoint(x: newX, y: screenFrame.height - newY)
        
        // Перемещаем курсор
        CGWarpMouseCursorPosition(newPosition)
        
        clickCount += 1
    }
    
    func setCustomInterval(_ interval: Int) {
        moveInterval = interval
        if !isMoving {
            nextMoveIn = interval
        }
    }
    
    func getClickCount() -> Int {
        return clickCount
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
