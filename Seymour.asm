; Seymour, Take 1
; A retro-nostalgic adventure remake
    
    #include includes\gfx-utils.asm
    #include includes\gfx-data.asm
    #include includes\gfx-character.asm
    #include includes\input-keyboard-handler.asm
    #include includes\input-gamepad-handler.asm
    #include includes\input-handler.asm
    #include includes\clock.asm
    #include includes\state-data.asm

    #ORG 0x80000

    CALLR .InitializeGraphics

    VDL 0b01111111

.MainLoop
    CALL .HasUpdateTimePassed       ; Updates the clock and also returns whether it passed the target frame time
    JR NZ, .MainLoop                ; We loop back until the allowed timeframe is reached

    CALLR .UpdateKeyboardInput              ; Update the keyboard input buffers to be able to determine changes
    CALLR .UpdateGamepadsInput              ; Update the gamepad input buffers to be able to determine changes
    CALLR .GetInputState                    ; Translates any relevant input into a generic state
    CALLR .HandleGlobalInput

    ; This ESC check cannot be moved to the global input handler since it cannot exit the application correctly. The escaping RET must
    ; come in at the top level (here)
    LD A, 27				        ; Escape key
	CALLR .InputKeyPressed          ; Check if the keycode in A has just been pressed
	RETIF Z                         ; Exit if pressed

    CALLR .UpdateCharacterAnimations

    CALLR .DrawCharacter            ; Draw the playing character
    VDL 0b00001000


    JR .MainLoop
