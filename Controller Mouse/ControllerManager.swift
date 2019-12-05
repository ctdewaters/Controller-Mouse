//
//  GameControllerManager.swift
//  ControllerMouse
//
//  Created by Collin DeWaters on 12/4/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import GameController

//MARK: - Game Controller Manager
/// `ControllerManager`: Handles the game controllers connected to this device, as well as their inputs.
class ControllerManager {
    //MARK: - Properties
    /// The delegate instance.
    var delegate: ControllerManagerDelegate?
    
    /// The currently connected controllers.
    var controllers: [GCController] {
        let controllers = GCController.controllers()
        controllers.first?.playerIndex = GCControllerPlayerIndex.index1
        return controllers
    }
    
    /// The main controller (Player 1).
    var player1Controller: GCController? {
        return self.controllers.filter { $0.playerIndex == GCControllerPlayerIndex.index1 }.first
    }
    
    /// The player 2 controller.
    var player2Controller: GCController? {
        return self.controllers.filter { $0.playerIndex == GCControllerPlayerIndex.index2 }.first
    }
    
    /// The player 3 controller.
    var player3Controller: GCController? {
        return self.controllers.filter { $0.playerIndex == GCControllerPlayerIndex.index3 }.first
    }
    
    /// The  player 4 controller.
    var player4Controller: GCController? {
        return self.controllers.filter { $0.playerIndex == GCControllerPlayerIndex.index4 }.first
    }
        
    //MARK: - Initialization
    init(withDelegate delegate: ControllerManagerDelegate?) {
        //Set the delegate property.
        self.delegate = delegate
        
        //Add connect and disconnect notification observers.
        NotificationCenter.default.addObserver(self, selector: #selector(self.controllerDidConnect(_:)), name: Notification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.controllerDidDisconnect(_:)), name: Notification.Name.GCControllerDidDisconnect, object: nil)
        
        //Update the initial controllers with the response handlers.
        self.updateControllersWithResponseHandlers()
        
        //TODO: - Add indexing of controllers here.
    }
    
    //MARK: - Controller Did Connect & Disconnect
    /// This function observes for the `controllerDidConnect` notification, and then calls the approprate delegate function.
    @objc private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        
        //Update the response handlers, since we have a new controller object.
        self.updateControllersWithResponseHandlers()

        //Run the delegate function.
        self.delegate?.controllerDidConnect(controller)
        
        //TODO: - Index new controller here.
    }
    
    /// This function observes for the `controllerDidDisconnect` notification, and then calls the approprate delegate function.
    @objc private func controllerDidDisconnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        
        // Run the delgate function.
        self.delegate?.controllerDidDisconnect(controller)
    }
    
    //MARK: - Controller Input Handlers
    /// Updates the response handlers for each controller in the `controllers` collection.
    private func updateControllersWithResponseHandlers() {
        for button in Button.all {
            self.addButtonPressedHandler(toAllControllersWithButtonType: button)
            self.addButtonValueChangedHandler(toAllControllersWithButtonType: button)
            self.addDirectionalValueChangedHandler(toAllControllersWithButtonType: button)
        }
        
        self.addPauseHandlerToAllControllers()
        self.addValueChangedHandlerToAllControllers()
    }
    
    /// Adds a controller paused handler to all connected controllers.
    private func addPauseHandlerToAllControllers() {
        for controller in self.controllers {
            // P.S.) I know this is deprecated, but the pause button on the Xbox controller
            // does not work with the Game Controller framework at this stage 😢.
            
            // TODO: - Update this implementation to a non deprecated method when possible.
            controller.controllerPausedHandler = { [unowned self] controller in
                self.delegate?.controllerDidPause(controller)
            }
        }
    }
    
    /// Adds a general value changed handler to all controllers. This handler is called when any button's value changes on a controller.
    private func addValueChangedHandlerToAllControllers() {
        for controller in self.controllers {
            controller.extendedGamepad?.valueChangedHandler = { [unowned self] (gamepad, controllerElement) -> Void in
                let input = gamepad.controllerInput
                self.delegate?.controllerDidChangeInput(controller, toCurrent: input)
            }
        }
    }
    
    /// Adds a handler (closure) to run the associated delegate function when a given button type is pressed (applied to all controllers).
    /// - Parameters:
    ///   - button: The button type.
    private func addButtonPressedHandler(toAllControllersWithButtonType button: Button) {
        // Ensure the button is not directional.
        guard button.isButton else { return }
                
        //Add the handler to all current controllers.
        for controller in self.controllers {
            if let controllerButton = button.input(inController: controller) as? GCControllerButtonInput {
                controllerButton.pressedChangedHandler = { [unowned self] buttonInput, value, isPressed in
                    self.delegate?.controllerButtonDidPress(controller, ofButtonType: button, andState: controllerButton.buttonState)
                }
            }
        }
    }
    
    /// Adds a handler (closure) to run the associated delegate function when a given button type is pressed (applied to all controllers) or it's pressure value is changed.
    /// - Parameters:
    ///   - button: The button type.
    private func addButtonValueChangedHandler(toAllControllersWithButtonType button: Button) {
        // Ensure the button is not directional.
        guard button.isButton else { return }
                
        //Add the handler to all current controllers.
        for controller in self.controllers {
            if let controllerButton = button.input(inController: controller) as? GCControllerButtonInput {
                controllerButton.valueChangedHandler = { [unowned self] buttonInput, value, isPressed in
                    self.delegate?.controllerButtonValueDidChange(controller, ofButtonType: button, andState: controllerButton.buttonState)
                }
            }
        }
    }
    
    /// Adds a handler (closure) to run the associated delegate function when a given directional button type's value changes (applied to all controllers).
    /// - Parameters:
    ///   - button: The directional button type.
    private func addDirectionalValueChangedHandler(toAllControllersWithButtonType button: Button) {
        // Ensure the button is directional.
        guard !button.isButton else { return }
                
        //Add the handler to all current controllers.
        for controller in self.controllers {
            if let dPad = button.input(inController: controller) as? GCControllerDirectionPad {
                dPad.valueChangedHandler = { [unowned self] directionalPad, xValue, yValue in
                    self.delegate?.controllerDirectionalInputValueDidChange(controller, ofDPadType: button, andState: dPad.directionalState)
                }
            }
        }
    }
}

//MARK: - ControllerManagerDelegate
protocol ControllerManagerDelegate {
    func controllerDidConnect(_ controller: GCController)
    func controllerDidDisconnect(_ controller: GCController)
    
    
    /// Called when any input on the controller's value changes.
    /// - Parameters:
    ///   - controller: The controller reciving input.
    ///   - currentInput: The current input value of all controls on the controller.
    func controllerDidChangeInput(_ controller: GCController?, toCurrent currentInput: ControllerInput)
    
    /// Called when a button's pressure value changes on a controller.
    /// - Parameters:
    ///   - controller: The controller recieving the user input.
    ///   - buttonType: The button recieving the input.
    ///   - buttonState: The state of the button recieiving the input.
    func controllerButtonValueDidChange(_ controller: GCController?, ofButtonType buttonType: Button, andState buttonState: ControllerInput.ButtonState)
    
    /// Called when a button's `isPressed` value changes.
    /// - Parameters:
    ///   - controller: The controller recieving the user input.
    ///   - buttonType: The button recieving the input.
    ///   - buttonState: The state of the button recieving the input.
    func controllerButtonDidPress(_ controller: GCController?, ofButtonType buttonType: Button, andState buttonState: ControllerInput.ButtonState)
    
    /// Called when a directional input is recieved on the controller
    /// - Parameters:
    ///   - controller: The controller reciving the input.
    ///   - dPadType: The directional pad reciving the input.
    ///   - directionalState: The state of the directional input.
    func controllerDirectionalInputValueDidChange(_ controller: GCController?, ofDPadType dPadType: Button, andState directionalState: ControllerInput.DirectionalState)
    
    func controllerDidPause(_ controller: GCController?)
}

//MARK: - ControllerManagerDelegate Optionals
extension ControllerManagerDelegate {
    func controllerDidChangeInput(_ controller: GCController?, toCurrent currentInput: ControllerInput) {}
    func controllerButtonValueDidChange(_ controller: GCController?, ofButtonType buttonType: Button, andState buttonState: ControllerInput.ButtonState) {}
    func controllerButtonDidPress(_ controller: GCController?, ofButtonType buttonType: Button, andState buttonState: ControllerInput.ButtonState) {}
    func controllerDirectionalInputValueDidChange(_ controller: GCController?, ofDPadType dPadType: Button, andState directionalState: ControllerInput.DirectionalState) {}
    func controllerDidPause(_ controller: GCController?) {}
}

//MARK: - Controller Input
/// `ControllerInput`: Contains a snapshot of the inputs of either a `GCController` object, or an on-screen control.
struct ControllerInput {
    //MARK: - Face Buttons
    /// The A button.
    var buttonA: ButtonState?
    
    /// The B button.
    var buttonB: ButtonState?
    
    /// The X button.
    var buttonX: ButtonState?
    
    /// The Y button.
    var buttonY: ButtonState?
    
    //MARK: - Trigger and Shoulder Buttons
    /// The right shoulder.
    var rightShoulder: ButtonState?
    
    /// The right trigger.
    var rightTrigger: ButtonState?
    
    /// The left shoulder.
    var leftShoulder: ButtonState?
    
    /// The left trigger.
    var leftTrigger: ButtonState?
    
    //MARK: - Directional Buttons & Analog Sticks
    /// The values of the directional pad.
    var dPad: DirectionalState?
    
    /// The values of the left analog stick.
    var leftAnalogStick: DirectionalState?
    
    /// The values of the right analog stick?
    var rightAnalogStick: DirectionalState?
    
    //MARK: - Creation From Game Controllers
    static func from(extendedGamepad: GCExtendedGamepad) -> ControllerInput {
        return ControllerInput(buttonA: extendedGamepad.buttonA.buttonState, buttonB: extendedGamepad.buttonB.buttonState, buttonX: extendedGamepad.buttonX.buttonState, buttonY: extendedGamepad.buttonY.buttonState, rightShoulder: extendedGamepad.rightShoulder.buttonState, rightTrigger: extendedGamepad.rightTrigger.buttonState, leftShoulder: extendedGamepad.leftShoulder.buttonState, leftTrigger: extendedGamepad.leftTrigger.buttonState, dPad: extendedGamepad.dpad.directionalState, leftAnalogStick: extendedGamepad.leftThumbstick.directionalState, rightAnalogStick: extendedGamepad.rightThumbstick.directionalState)
    }

    //MARK: - Button State & Directional State
    
    /// `ButtonState`: Contains information about the state of a button on the controller or on screen control.
    struct ButtonState {
        /// If true, the button is pressed.
        var isPressed: Bool?
        
        /// The force of the press on the button.
        var value: Float?
    }
    
    /// `DirectionalState`: Contains information about directional buttons or analog sticks.
    struct DirectionalState {
        /// The value of the X axis.
        var xAxis: Float?
        
        /// The value of the Y axis.
        var yAxis: Float?

        /// If true, up is pressed.
        var up: Bool?
        
        /// If true, right is pressed.
        var right: Bool?
        
        /// If true, down is pressed.
        var down: Bool?
        
        /// If true, left is pressed.
        var left: Bool?
    }
}

//MARK: - Button
/// `Button`: Represents a button on a controller.
enum Button: String {
    case A, B, X, Y, rightShoulder, leftShoulder, rightTrigger, leftTrigger, dPad, leftAnalog, rightAnalog, leftAnalogButton, rightAnalogButton, pause
    
    static var all: [Button] {
        return [.A, .B, .X, .Y, .rightShoulder, .leftShoulder, .rightTrigger, .leftTrigger, .dPad, .leftAnalog, .rightAnalog, .leftAnalogButton, .rightAnalogButton, .pause]
    }
    
    /// Returns true if the button is non-directional.
    var isButton: Bool {
        switch self {
        case .A, .B, .X, .Y, .rightShoulder, .leftShoulder, .leftTrigger, .rightTrigger, .leftAnalogButton, .rightAnalogButton :
            return true
        default :
            return false
        }
    }
    
    /// Returns the appropriate input for a given controller from this value.
    /// - Parameter controller: The controller to retrieve the input from.
    func input(inController controller: GCController) -> GCControllerElement? {
        guard let extendedGamepad = controller.extendedGamepad else { return nil }
        switch self {
        case .A :
            return extendedGamepad.buttonA
        case .B :
            return extendedGamepad.buttonB
        case .X :
            return extendedGamepad.buttonX
        case .Y :
            return extendedGamepad.buttonY
        case .rightShoulder :
            return extendedGamepad.rightShoulder
        case .leftShoulder :
            return extendedGamepad.leftShoulder
        case .rightTrigger :
            return extendedGamepad.rightTrigger
        case .leftTrigger :
            return extendedGamepad.leftTrigger
        case .dPad :
            return extendedGamepad.dpad
        case .leftAnalog :
            return extendedGamepad.leftThumbstick
        case .rightAnalog :
            return extendedGamepad.rightThumbstick
        case .leftAnalogButton :
            return extendedGamepad.leftThumbstickButton
        case .rightAnalogButton :
            return extendedGamepad.rightThumbstickButton
        case .pause :
            return extendedGamepad.buttonMenu
        }
    }
}

extension GCExtendedGamepad {
    var controllerInput: ControllerInput {
        return ControllerInput(buttonA: self.buttonA.buttonState, buttonB: self.buttonB.buttonState, buttonX: self.buttonX.buttonState, buttonY: self.buttonY.buttonState, rightShoulder: self.rightShoulder.buttonState, rightTrigger: self.rightTrigger.buttonState, leftShoulder: self.leftShoulder.buttonState, leftTrigger: self.leftTrigger.buttonState, dPad: self.dpad.directionalState, leftAnalogStick: self.leftThumbstick.directionalState, rightAnalogStick: self.rightThumbstick.directionalState)
    }
}

extension GCControllerButtonInput {
    var buttonState: ControllerInput.ButtonState {
        return ControllerInput.ButtonState(isPressed: self.isPressed, value: self.value)
    }
}

extension GCControllerDirectionPad {
    var directionalState: ControllerInput.DirectionalState {
        return ControllerInput.DirectionalState(xAxis: self.xAxis.value, yAxis: self.yAxis.value, up: self.up.isPressed, right: self.right.isPressed, down: self.down.isPressed, left: self.left.isPressed)
    }
}
