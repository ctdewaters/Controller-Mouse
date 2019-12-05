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
    
    //MARK: - Initialization
    init() {}
    
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

toggleDockIcon(showIcon: false)


let delegateObject = ControllerManagerDelegateObject()
let controllerManager = ControllerManager(withDelegate: delegateObject)


let timer = Timer(timeInterval: 0.001, repeats: true) { (timer) in
    guard let dState = delegateObject.lastLeftAnalogState else { return }

    guard var cursor = delegateObject.cursorLocation, let x = dState.xAxis, let y = dState.yAxis else { delegateObject.cursorLocation = NSEvent.mouseLocation; return }

    guard abs(x) > 0, abs(y) > 0 else { return }

    cursor.x += CGFloat(x)
    cursor.y += -CGFloat(y)

    CGWarpMouseCursorPosition(cursor)

    delegateObject.cursorLocation = cursor
}


RunLoop.main.add(timer, forMode: .default)
RunLoop.main.run()
