
.InitializeGraphics

    LD A, 0x02              ; SetVideoPagesCount
    LD B, 7                 ; set 7 video pages
    INT 0x01, A             ; Trigger interrupt Video with function SetVideoPagesCount

    CALLR .SetVideoAutoControlMode  ; Set the video mode so we can control WHEN we actually draw on the screen with VDL

    LD B, 0
.ContinueClearingVideo
    CALLR .ClearVideoPage
    INC B
    CP B, 7
    JR NZ, .ContinueClearingVideo

    CALLR .LoadUIFrame
    CALLR .LoadSeymourCharacterAnimations
    CALLR .ResetLayer0Palette

    RET

; Loading the UI frame directly in the video buffer. This can be done this way since the width
; of the image to be loaded matches the width of the video frame. If this would have not been the
; case, the proper way is to load in memory and then draw them with DrawSprite (int 0x01, fn 0x10)
.LoadUIFrame
    LD A, 0x34
    LD BCD, .uiFramePath
    LD EFG, 0xF21340        ; Load the palette directly to video layer 7's palette
    LD HIJ, 0xF22840        ; Load the image data directly into the video buffer since it matches the w/h
    LD KLMN, 0xFFFFFF00     ; the RGBA color that will be interpreted as the transparent color from the provided RGB.
    INT 0x04, A

    RET

.LoadSeymourCharacterAnimations
    ; Load walking tilesheet
    LD A, 0x34
    LD BCD, .sprSeymourWalkPath
    LD EFG, 0xF21C40        ; Load the palette directly to video layer 4's palette
    LD HIJ, .sprSeymourWalkSheet        ; Load the image data into the memory
    LD KLMN, 0xFFFFFF00     ; the RGBA color that will be interpreted as the transparent color from the provided RGB.
    INT 0x04, A

    LD Z, F                 ; Keep the numbers of found colors

    ; merge idle, jumping tilesheet
    LD A, 0x36
    LD BCD, .sprSeymourIdleJumpPath
    LD EFG, 0xF21C40        ; Load the palette directly to video layer 4's palette
    LD H, Z
    LD IJK, .sprSeymourIdleJumpSheet        ; Load the image data into the memory
    LD LMNO, 0x00000000     ; the RGBA color that will be interpreted as the transparent color from the provided RGB.
    ;INT 0x04, A

    RET

; Sets the video buffer mode to manual for all video pages
.SetVideoAutoControlMode
    LD A, 0x33
    LD B, 0b00000000
    INT 0x01, A
    RET

; Clear specified video page. Expects B to have the index of the page to clear
.ClearVideoPage
    LD A, 0x05              ; ClearVideoPage function index
    LD C, 0                 ; the color which will be used to fill that memory page (0 - transparent).
    INT 0x01, A             ; Trigger interrupt Video with the function index stored in A to clear the page

    RET

; For now, we just clear layer zero by replacing the first color of the palette with some dark gray.
.ResetLayer0Palette
    LD ABC, 0xF22540
    LD24 (ABC), 0x0F0F0F

    RET