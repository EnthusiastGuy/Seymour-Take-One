; Handles gamepads input. Provides methods to get the state of all buttons/thumbs/triggers etc

.UpdateGamepadsInput
    PUSH A, Z
    
    ; Copy current state to the previous state buffer
    LD ABC, .gamepads_input_CSB
    LD DEF, .gamepads_input_PSB
    MEMC ABC, DEF, 41
    MEMF ABC, 41, 0         ; Clear the input buffer to not have rezidues

    ; Grab current state
    LD Z, 0x14              ; ReadGamePadsState, ABC already contains the target address
    INT 0x02, Z             ; Trigger interrupt `Input/Read GamePads State`

    POP A, Z
    RET

; A, B buttons 'pressed' state
; =============================

; checks if button A has just been pressed on specified controller
; input:    A - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonAPressed
    PUSH A, Z
    LD X, 0b00010000
    LD Y, 1
    CALLR .is_state_button_pressed
    POP A, Z
    RET

; checks if button B has just been pressed on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonBPressed
    PUSH A, Z
    LD X, 0b00100000
    LD Y, 1
    CALLR .is_state_button_pressed
    POP A, Z
    RET

; DPad 'down' state
; =============================

; checks if button DPad Up is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadUpDown
    PUSH A, Z
    LD X, 0b00000001
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button DPad Down is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadDownDown
    PUSH A, Z
    LD X, 0b00000010
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button DPad Left is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadLeftDown
    PUSH A, Z
    LD X, 0b00000100
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if button DPad Right is in down state on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsButtonDPadRightDown
    PUSH A, Z
    LD X, 0b00001000
    LD Y, 1
    CALLR .is_state_button_down
    POP A, Z
    RET



; Left thumbstick 'down' state
; =============================

; checks if left thumb joystick is pointing up on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbLeftPointingUp
    PUSH A, Z
    LD X, 0b00000001
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if left thumb joystick is pointing down on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbLeftPointingDown
    PUSH A, Z
    LD X, 0b00000010
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if left thumb joystick is pointing left on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbLeftPointingLeft
    PUSH A, Z
    LD X, 0b00000100
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET

; checks if left thumb joystick is pointing right on specified controller
; input:    A register - the index of the controller to check button on
; output:   Z flag is set if true
.IsThumbLeftPointingRight
    PUSH A, Z
    LD X, 0b00001000
    LD Y, 2
    CALLR .is_state_button_down
    POP A, Z
    RET



; ==================== Private utility functions ====================

; generic functionality that checks whether the bit pointed by the X
; register is set thereby indicating respective button is down
; input:    A contains the controller id (0 - 3)
;           X contains the binary sequence to point to button bit
; output:   Z flag is set if bit is set
.is_state_button_down
    LD BCD, .gamepads_input_CSB
    ADD BCD, Y
    MUL A, 10
    ADD BCD, A
    LD A, (BCD)
    INV A
    AND A, X
    CP A, 0
    RET

; generic functionality that checks whether the bit pointed by the X
; register is set in current state but reset in previous thereby indicating
; respective button has just been pressed
; input:    A contains the controller id (0 - 3)
;           X contains the binary sequence to point to button bit
; output:   Z flag is set if bit is set
.is_state_button_pressed
    LD BCD, .gamepads_input_CSB
    ADD BCD, Y
    MUL A, 10
    ADD BCD, A
    LD A, (BCD)
	INV A
    AND A, X
	ADD BCD, 41	; Add 41 bytes so we get to the "previous" buffer
	LD B, (BCD)
	AND B, X
	ADD A, B
    CP A, 0
    RET










; ==================== State buffers structure ====================

; - 1 connection and status byte:
; ANY[n] - is any button pressed on controller [n]
; CON[n] - is controller [n] connected
; Yes: 1, No: 0
;   b7  |    b6  |    b5  |    b4  |    b3  |    b2  |    b1  |    b0
;-----------------------------------------------------------------------
; ANY3  |  ANY2  |  ANY1  |  ANY0  |  CON3  |  CON2  |  CON1  |  CON0

; For each controller
; 10 bytes per controller (max 4 controllers) consisting of:

; - first byte for DPad + ABXY butons pressed:
;
;   b7  |    b6  |    b5  |    b4  |    b3  |    b2  |    b1  |    b0
;-----------------------------------------------------------------------
; Btn.Y |  Btn.X |  Btn.B |  Btn.A |DP.Right| DP.Left| DP.Down|  DP.Up

; - second byte for ThumbStick left and right. They register just the simple
; direction, without the progressive value:
;
;     b7    |      b6    |      b5    |      b4    |      b3    |      b2    |      b1    |      b0
;------------------------------------------------------------------------------------------------------
;TRght.Right| TRght.Left | TRght.Down |  TRght.Up  | TLft.Right |  TLft.Left |  TLft.Down |  TLft.Up

; - third byte for misc buttons:
; None means that no button is pressed, the inverse of "any button pressed"
;
;     b7    |      b6    |      b5    |      b4    |      b3    |      b2    |      b1    |      b0
;------------------------------------------------------------------------------------------------------
;    None   |  BigButton |     Back   |    Start   |  RTrigger  |  LTrigger  |  RShoulder |  LShoulder

; - fourth byte for left/right stick presses and misc flags
; b0:   Left stick is pressed
; b1:   Right stick is pressed
; b2:   Any of A, B, X, Y pressed
; b3:   Any of the DPad buttons pressed
; b4:   Any of L/R Shoulder pressed
; b5:   Any of L/R Trigger pressed
; b6:   Any left thumb direction actioned
; b7:   Any right thumb direction actioned

; - fifth byte contains the Left Trigger Z value (0 to 255)
; - sixth byte contains the Right Trigger Z value (0 to 255)
; - seventh byte contains the left thumb X value (-128 to 127)
; - eight byte contains the left thumb Y value (-128 to 127)
; - ninth byte contains the right thumb X value (-128 to 127)
; - tenth byte contains the right thumb Y value (-128 to 127)

.gamepads_input_CSB      ; current state buffer
    #DB [41] 0

.gamepads_input_PSB      ; previous state buffer
    #DB [41] 0
