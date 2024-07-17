; Manages the input coming from the player

; Transfers the input from player to the game state

; Translate inputs to flags:
;   bit 0 - left is pressed
;   bit 1 - right is pressed
;   bit 2 - up is pressed
;   bit 3 - down is pressed
;   bit 4 - jump is pressed
;   bit 5 - action is pressed

;   bit 6 - keyboard was used
;   bit 7 - controller was used

.GetInputState

    LD X, 0                         ; Storing the flags temporarily in register X

    LD A, 37				        ; Arrow left
	CALLR .KeyboardInputKeyDown     ; Check if the keycode in A is pressed
	JR NZ, .eval_right_key
    SET X, 0                        ; Sets bit zero since left key is evaluated as pressed
    SET X, 6                        ; Sets bit six since a character control key on keyboard was pressed

.eval_right_key
    LD A, 39				        ; Arrow right
	CALLR .KeyboardInputKeyDown     ; Check if the keycode in A is pressed
	JR NZ, .eval_up_key
    SET X, 1                        ; Sets bit one since right key is evaluated as pressed
    SET X, 6                        ; Sets bit six since a character control key on keyboard was pressed

.eval_up_key
    LD A, 38				        ; Arrow up
	CALLR .KeyboardInputKeyDown     ; Check if the keycode in A is pressed
	JR NZ, .eval_down_key
    SET X, 2                        ; Sets bit two since up key is evaluated as pressed
    SET X, 6                        ; Sets bit six since a character control key on keyboard was pressed

.eval_down_key
    LD A, 40				        ; Arrow down
	CALLR .KeyboardInputKeyDown     ; Check if the keycode in A is pressed
	JR NZ, .eval_space_key
    SET X, 3                        ; Sets bit three since down key is evaluated as pressed
    SET X, 6                        ; Sets bit six since a character control key on keyboard was pressed

.eval_space_key
    LD A, 32				        ; Space
	CALLR .KeyboardInputKeyDown     ; Check if the keycode in A is pressed
	JR NZ, .eval_zero_key
    SET X, 4                        ; Sets bit four since jump key is evaluated as pressed
    SET X, 6                        ; Sets bit six since a character control key on keyboard was pressed

.eval_zero_key
    LD A, 48				        ; Zero
	CALLR .KeyboardInputKeyDown     ; Check if the keycode in A is pressed
	JR NZ, .finished_keyboard_eval
    SET X, 5                        ; Sets bit five since action key is evaluated as pressed
    SET X, 6                        ; Sets bit six since a character control key on keyboard was pressed

.finished_keyboard_eval
    

; Gamepad evaluation
    LD A, 0                             ; gamepad zero

    CALLR .IsButtonDPadLeftDown         ; check if gamepad's DPad left direction is pressed
	JR NZ, .eval_gamepad_thumb_left
    SET X, 0                            ; Sets bit zero since left is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_thumb_left
    CALLR .IsThumbLeftPointingLeft      ; check if gamepad's left thumbstick points to the left direction
	JR NZ, .eval_gamepad_dpad_right
    SET X, 0                            ; Sets bit zero since left is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_dpad_right
    CALLR .IsButtonDPadRightDown        ; check if gamepad's DPad right direction is pressed
	JR NZ, .eval_gamepad_thumb_right
    SET X, 1                            ; Sets bit zero since right is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_thumb_right
    CALLR .IsThumbLeftPointingRight     ; check if gamepad's left thumbstick points to the right direction
	JR NZ, .eval_gamepad_dpad_up
    SET X, 1                            ; Sets bit zero since right is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_dpad_up
    CALLR .IsButtonDPadUpDown           ; check if gamepad's DPad up direction is pressed
	JR NZ, .eval_gamepad_thumb_up
    SET X, 2                            ; Sets bit zero since up is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_thumb_up
    CALLR .IsThumbLeftPointingDown        ; check if gamepad's DPad up direction is pressed -   TODO fix API inversion
	JR NZ, .eval_gamepad_dpad_down
    SET X, 2                            ; Sets bit zero since up is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_dpad_down
    CALLR .IsButtonDPadDownDown           ; check if gamepad's DPad down direction is pressed
	JR NZ, .eval_gamepad_thumb_down
    SET X, 3                            ; Sets bit zero since down is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_thumb_down
    CALLR .IsThumbLeftPointingUp      ; check if gamepad's DPad down direction is pressed - TODO fix API inversion
	JR NZ, .eval_gamepad_B_down
    SET X, 3                            ; Sets bit zero since down is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_B_down
    CALLR .IsButtonBPressed             ; check if gamepad's B buton has been pressed
	JR NZ, .eval_gamepad_A_down
    SET X, 4                            ; Sets bit zero since jump is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed

.eval_gamepad_A_down
    CALLR .IsButtonAPressed             ; check if gamepad's A buton has been pressed
	JR NZ, .finished_gamepad_eval
    SET X, 5                            ; Sets bit zero since action is evaluated as pressed
    SET X, 7                            ; Sets bit seven since a character control key on gamepad was pressed



.finished_gamepad_eval
    LD (.StatePlayerMovement), X    ; Load up the state into the designated memory location

    RET

.HandleGlobalInput
    LD X, (.StatePlayerMovement)

    
    BIT X, 0
    CALLR Z, .MoveLeft

    BIT X, 1
    CALLR Z, .MoveRight

    BIT X, 2
    CALLR Z, .Jump

    BIT X, 3
    CALLR Z, .MoveDown

    BIT X, 4
    CALLR Z, .Jump

    RET

.MoveLeft
    LD (.StateCharacterAnimationIndex), 0x01
    SUB16 (.StateCharacterPositionX), 1

    RET

.MoveRight
    LD (.StateCharacterAnimationIndex), 0x02
    ADD16 (.StateCharacterPositionX), 1

    RET

.Jump
    LD (.StateCharacterAnimationIndex), 0x05
    DEC16 (.StateCharacterPositionY)

    RET

.MoveDown
    INC16 (.StateCharacterPositionY)

    RET
