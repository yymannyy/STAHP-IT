import AppKit
import SwiftUI

public final class OverlayPanel: NSPanel {
    public weak var controller: OverlayWindowController?
    
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .statusBar
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
    }
    
    public override var canBecomeKey: Bool {
        return false
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
}

@MainActor
final class OverlayPanelDelegate: NSObject, NSWindowDelegate {
    weak var controller: OverlayWindowController?
    weak var appState: AppState?
    
    init(controller: OverlayWindowController, appState: AppState) {
        self.controller = controller
        self.appState = appState
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        handleMove()
    }
    
    func windowDidMove(_ notification: Notification) {
        if let panel = notification.object as? OverlayPanel, let appState = appState {
            controller?.handleUserMovedPanel(panel, appState: appState)
        }
    }
    
    private func handleMove() {
        if let panel = controller?.panel, let appState = appState {
            controller?.handleUserMovedPanel(panel, appState: appState)
        }
    }
}

@MainActor
public final class OverlayWindowController: ObservableObject {
    public static let shared = OverlayWindowController()
    
    public fileprivate(set) var panel: OverlayPanel?
    private var delegate: OverlayPanelDelegate?
    
    public init() {}
    
    public func setup(appState: AppState) {
        if panel != nil {
            updatePosition(appState: appState)
            return
        }
        
        let initialFrame = calculateFrame(anchor: appState.storage.data.screenAnchor, appState: appState)
        let overlayPanel = OverlayPanel(contentRect: initialFrame)
        overlayPanel.controller = self
        
        let panelDelegate = OverlayPanelDelegate(controller: self, appState: appState)
        overlayPanel.delegate = panelDelegate
        self.delegate = panelDelegate
        
        let rootView = OverlayHUDView(appState: appState)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        overlayPanel.contentView = hostingView
        
        self.panel = overlayPanel
        
        if appState.isOverlayVisible {
            overlayPanel.orderFrontRegardless()
        }
    }
    
    public func updatePosition(appState: AppState) {
        guard let panel = panel else { return }
        let newFrame = calculateFrame(anchor: appState.storage.data.screenAnchor, appState: appState)
        panel.setFrame(newFrame, display: true, animate: true)
    }
    
    public func snapToAnchor(_ anchor: ScreenAnchor, appState: AppState) {
        appState.storage.data.screenAnchor = anchor
        appState.storage.data.overlayMode = (anchor == .notchTopCenter) ? .notch : .floating
        appState.storage.save()
        updatePosition(appState: appState)
    }
    
    public func handleUserMovedPanel(_ panel: OverlayPanel, appState: AppState) {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let screenFrame = screen.frame
        let panelFrame = panel.frame
        
        // Check for magnetic edge proximity
        let nearTopCenter = abs(panelFrame.midX - screenFrame.midX) < 140 && panelFrame.maxY >= (screenFrame.maxY - 50)
        let nearLeftEdge = panelFrame.minX <= (screenFrame.minX + 70) && panelFrame.midY > (screenFrame.minY + 100) && panelFrame.midY < (screenFrame.maxY - 100)
        let nearRightEdge = panelFrame.maxX >= (screenFrame.maxX - 70) && panelFrame.midY > (screenFrame.minY + 100) && panelFrame.midY < (screenFrame.maxY - 100)
        let nearTopLeft = panelFrame.minX <= (screenFrame.minX + 80) && panelFrame.maxY >= (screenFrame.maxY - 80)
        let nearTopRight = panelFrame.maxX >= (screenFrame.maxX - 80) && panelFrame.maxY >= (screenFrame.maxY - 80)
        let nearBottomCenter = abs(panelFrame.midX - screenFrame.midX) < 140 && panelFrame.minY <= (screenFrame.minY + 80)
        let nearBottomLeft = panelFrame.minX <= (screenFrame.minX + 80) && panelFrame.minY <= (screenFrame.minY + 80)
        let nearBottomRight = panelFrame.maxX >= (screenFrame.maxX - 80) && panelFrame.minY <= (screenFrame.minY + 80)
        
        var detectedAnchor: ScreenAnchor = .freeFloat
        
        if nearTopCenter {
            detectedAnchor = .notchTopCenter
        } else if nearLeftEdge {
            detectedAnchor = .leftEdge
        } else if nearRightEdge {
            detectedAnchor = .rightEdge
        } else if nearTopLeft {
            detectedAnchor = .topLeft
        } else if nearTopRight {
            detectedAnchor = .topRight
        } else if nearBottomCenter {
            detectedAnchor = .bottomCenter
        } else if nearBottomLeft {
            detectedAnchor = .bottomLeft
        } else if nearBottomRight {
            detectedAnchor = .bottomRight
        } else {
            detectedAnchor = .freeFloat
            appState.storage.data.overlayPositionX = panelFrame.origin.x
            appState.storage.data.overlayPositionY = panelFrame.origin.y
        }
        
        if appState.storage.data.screenAnchor != detectedAnchor {
            appState.storage.data.screenAnchor = detectedAnchor
            appState.storage.data.overlayMode = (detectedAnchor == .notchTopCenter) ? .notch : .floating
            appState.storage.save()
            updatePosition(appState: appState)
        }
    }
    
    public func calculateFrame(anchor: ScreenAnchor, appState: AppState) -> NSRect {
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        
        let margin: CGFloat = 16
        
        switch anchor {
        case .notchTopCenter:
            let windowWidth: CGFloat = 760
            let windowHeight: CGFloat = 180
            let xPos = screenFrame.midX - (windowWidth / 2)
            let yPos = screenFrame.maxY - windowHeight
            return NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight)
            
        case .leftEdge:
            let panelWidth: CGFloat = 52
            let panelHeight: CGFloat = 190
            let xPos = visibleFrame.minX + 4
            let yPos = visibleFrame.midY - (panelHeight / 2)
            return NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight)
            
        case .rightEdge:
            let panelWidth: CGFloat = 52
            let panelHeight: CGFloat = 190
            let xPos = visibleFrame.maxX - panelWidth - 4
            let yPos = visibleFrame.midY - (panelHeight / 2)
            return NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight)
            
        case .topLeft:
            let panelWidth: CGFloat = 290
            let panelHeight: CGFloat = 64
            let xPos = visibleFrame.minX + margin
            let yPos = visibleFrame.maxY - panelHeight - margin
            return NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight)
            
        case .topRight:
            let panelWidth: CGFloat = 290
            let panelHeight: CGFloat = 64
            let xPos = visibleFrame.maxX - panelWidth - margin
            let yPos = visibleFrame.maxY - panelHeight - margin
            return NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight)
            
        case .bottomCenter:
            let panelWidth: CGFloat = 300
            let panelHeight: CGFloat = 64
            let xPos = screenFrame.midX - (panelWidth / 2)
            let yPos = visibleFrame.minY + margin
            return NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight)
            
        case .bottomLeft:
            let panelWidth: CGFloat = 290
            let panelHeight: CGFloat = 64
            let xPos = visibleFrame.minX + margin
            let yPos = visibleFrame.minY + margin
            return NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight)
            
        case .bottomRight:
            let panelWidth: CGFloat = 290
            let panelHeight: CGFloat = 64
            let xPos = visibleFrame.maxX - panelWidth - margin
            let yPos = visibleFrame.minY + margin
            return NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight)
            
        case .freeFloat:
            let panelWidth: CGFloat = 290
            let panelHeight: CGFloat = 64
            let xPos = appState.storage.data.overlayPositionX ?? (visibleFrame.maxX - panelWidth - margin)
            let yPos = appState.storage.data.overlayPositionY ?? (visibleFrame.maxY - panelHeight - margin)
            return NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight)
        }
    }
    
    public func show() {
        if panel == nil {
            setup(appState: AppState.shared)
        }
        panel?.orderFrontRegardless()
    }
    
    public func hide() {
        panel?.orderOut(nil)
    }
    
    public func toggle(visible: Bool) {
        if visible {
            show()
        } else {
            hide()
        }
    }
}
