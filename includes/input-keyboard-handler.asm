; Moves the current state to a previous state then captures the current state.
; Used by [] to determine whether specific keys have just been pressed or released.
; This should be run continuously in a main loop. Recommended: 60 times per second at most.
.UpdateKeyboardInput
    PUSH A, Z

    ; Copy current state to the previous state buffer
    LD ABC, .input_CSB
    LD DEF, .input_PSB
    MEMC ABC, DEF, 32
    MEMF ABC, 32, 0         ; Clear the input buffer to not have rezidues

    ; Grab current state
    LD Z, 0x10              ; ReadKeyboardPressedKeysAsCodes, ABC already contains the target address
    INT 0x02, Z             ; Trigger interrupt `Input/Read Keyboard Pressed Keys As Codes`

    POP A, Z
    RET

; checks whether a key state has changed from not pressed to pressed. Indicates a key has been pressed
; input: A - the keycode to look for
; output: Z flag is set if true, reset if false
.InputKeyPressed
    ; expects key code in register A
    ; if current state is keyDown and previous state is keyUp
    PUSH B, Z
    LD Z, A
    
    LD BCD, .input_CSB
    CALLR .input_keyDown
    RETIF NZ

    LD A, Z
    LD BCD, .input_PSB
    CALLR .input_keyDown
    INVF Z
    
    POP B, Z
    RET

; whether the state of key code received in A is keyDown (exists in the indicated buffer)
; input: A - the keycode to look for
; output: flag Z is set if code found, not set if otherwise
.KeyboardInputKeyDown
    PUSH B, Z
    LD BCD, .input_CSB
    CALLR .input_keyDown
    POP B, Z
    RET



; whether the state of key code received in A is keyDown (exists in the indicated buffer)
; input: A - the keycode to look for
; input: BCD - the address of the buffer to search
; output: flag Z is set if code found, not set if otherwise
.input_keyDown              
    LD EF, 32

.input_keyDown_next
    LD X, (BCD)
    CP X, A
    RETIF Z
    DEC EF
    INC BCD
    CP EF, 0
    JR NZ, .input_keyDown_next
    RESF Z
    RET



; Buffers
.input_CSB      ; current state buffer
    #DB [32] 0

.input_PSB      ; previous state buffer
    #DB [32] 0