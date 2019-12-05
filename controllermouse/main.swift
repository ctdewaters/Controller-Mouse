//
//  main.swift
//  Controller Mouse
//
//  Created by Collin DeWaters on 12/5/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import Foundation
import GameController
import Cocoa

let app = NSApplication.shared

class AppDelegate: NSObject, NSApplicationDelegate {
    //MARK: - NSApplicationDelegate
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.stop(nil)
    }
}

class ControllerManagerDelegateObject: ControllerManagerDelegate {
    
    //MARK: - Properties
    var timer: Timer?
    var lastLeftAnalogState: ControllerInput.DirectionalState?
    var cursorLocation: NSPoint?
    let mouseClickEventSource = CGEventSource(stateID: .hidSystemState)
    var shouldResetCursor = true
    
    //MARK: - Initialization
    init() {
        self.timer = Timer(timeInterval: 0.0001, repeats: true, block: { (timer) in
            guard let dState = self.lastLeftAnalogState else { return }

            guard !self.shouldResetCursor, var cursor = self.cursorLocation, let x = dState.xAxis, let y = dState.yAxis else {
                var mouseLocation = NSEvent.mouseLocation
                mouseLocation.y = (NSScreen.main?.frame ?? .zero).height - mouseLocation.y
                self.cursorLocation = mouseLocation
                self.shouldResetCursor = false
                return
            }

            guard abs(x) > 0, abs(y) > 0 else {
                //Reset the cursor location.
                self.shouldResetCursor = true
                return
            }

            let multiplier: CGFloat = 0.25
            cursor.x += CGFloat(x) * multiplier
            cursor.y += -CGFloat(y) * multiplier

            CGWarpMouseCursorPosition(cursor)

            self.cursorLocation = cursor
            self.shouldResetCursor = false
            
            print(cursor)
        })
    }
    
    //MARK: - ControllerManagerDelegate
    func controllerDidConnect(_ controller: GCController) {
        print(controller)
    }
    
    func controllerDidDisconnect(_ controller: GCController) {
        print(controller)
    }
        
    func controllerDirectionalInputValueDidChange(_ controller: GCController?, ofDPadType dPadType: Button, andState directionalState: ControllerInput.DirectionalState) {
        
        if dPadType == .leftAnalog {
            self.lastLeftAnalogState = directionalState
        }
    }
    
    func controllerButtonDidPress(_ controller: GCController?, ofButtonType buttonType: Button, andState buttonState: ControllerInput.ButtonState) {
        guard let isPressed = buttonState.isPressed else { return }
        
        var event: CGEvent?

        if buttonType == .A {
            // Simulating left clicks.
            if isPressed {
                // Pressed
                event = CGEvent(mouseEventSource: self.mouseClickEventSource, mouseType: .leftMouseDown, mouseCursorPosition: self.cursorLocation ?? .zero, mouseButton: .left)
            }
            else {
                // Released
                event = CGEvent(mouseEventSource: self.mouseClickEventSource, mouseType: .leftMouseUp, mouseCursorPosition: self.cursorLocation ?? .zero, mouseButton: .left)
            }
        }
        if buttonType == .B {
            if isPressed {
                event = CGEvent(mouseEventSource: self.mouseClickEventSource, mouseType: .rightMouseDown, mouseCursorPosition: self.cursorLocation ?? .zero, mouseButton: .right)
            }
            else {
                event = CGEvent(mouseEventSource: self.mouseClickEventSource, mouseType: .rightMouseUp, mouseCursorPosition: self.cursorLocation ?? .zero, mouseButton: .right)
            }
        }
        
        event?.post(tap: .cghidEventTap)
    }
}

public func toggleDockIcon(showIcon state: Bool) -> Bool {
    // Get transform state.
    var transformState: ProcessApplicationTransformState
    if state {
        transformState = ProcessApplicationTransformState(kProcessTransformToForegroundApplication)
    }
    else {
        transformState = ProcessApplicationTransformState(kProcessTransformToUIElementApplication)
    }

    // Show / hide dock icon.
    var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
    let transformStatus: OSStatus = TransformProcessType(&psn, transformState)
    return transformStatus == 0
}


let delegate = AppDelegate()
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()

_ = toggleDockIcon(showIcon: false)


let delegateObject = ControllerManagerDelegateObject()
let controllerManager = ControllerManager(withDelegate: delegateObject)

RunLoop.main.add(delegateObject.timer!, forMode: .default)
RunLoop.main.run()
