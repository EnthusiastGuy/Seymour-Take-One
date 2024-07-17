; Character control strategy:
; Character posesses a coordinate system (x, y, r) pointing to the x, y and room index of where the character is.
; There is also a bounding box that encloses the feet and goes up to the head.
; Controls only modify flag states:
;   Left - sets 'left' flag
;   Right - sets 'right' flag
;   Jump - sets 'jump' flag
;   Up - sets 'up' flag
;   Down - sets 'down' flag
;   Action - sets 'action' flag
; All control flags are 'attempts', they get further evaluated against the enviroment in the next step.
; Other flag states:
;   - Underwater;
;   - Floating;
;   - Ladder;
;   - Cloud;
; Further evaluation:
;   - Are there any solid pixels below the bounding box?
;   - Is character deep in water?
;   - Is character at water surface?


; Evaluations:
; Graphics:
;                                   NON-LADDER                                          LADDER [id]
;                       UNDERWATER          NOT UNDERWATER              UNDERWATER          NOT UNDERWATER
;   --------------------------------------------------------------------------------------------------------------------
;   LEFT                SwimLeft            LeftNonUnderwater           SwimLeft            LeftNonUnderwater 
;   RIGHT               SwimRight           RightNonUnderwater          SwimRight           RightNonUnderwater
;   JUMP                SwimUp              Jump                        SwimUp              Jump
;   UP                  SwimUp              Jump                        LadderUp [id]       LadderUp [id]
;   DOWN                SwimDown            N.A.                        LadderDown [id]     LadderDown [id]
;   LEFT+JUMP           SwimLeft            JumpLeft                    SwimLeft            JumpLeft
;   RIGHT+JUMP          SwimRight           JumpRight                   SwimRight           JumpRight
;
;
;   - left -> evaluate left side of the bounding box. If not solid, go through. If solid up to a height of 4 pixels, go through. If solid beyond 4 pixels, don't go
;   - right -> evaluate right side of the bounding box. The rest is same as above
;   - 

; Collision
; =============
; One of the layers will exclusively handle pixel perfect collisions. That is, all tiles drawn there also generate collision.
; For non collidable scenery, other video layers will be used.
; Layers:
;   - far static background     (far scenery - refreshed on room load)
;   - far dynamic background    (birds, moving clouds - refreshed frequently)
;   - static collision tiles           (tiles that player can stand on - refreshed on room load)
;   - player                    (player character is exclusively drawn here - refreshed very often)
;   - front static tiles + static UI    (tiles with no collision that are drawn in front of the player - refreshed on room load)
;   - front dynamic tiles + dynamic UI (text bubbles, power-up animations etc... - refreshed frequently)
;   - Menu UI   (refreshed frequently)
;   - lighting (? - refreshed frequently)

; Collision situations:
;   - static, dynamic collision - pixel perfect;
;   - clouds - pixel perfect;
;   - vertical/horizontal platforms - pixel perfect;
;   - ladders - rectangles;
;   - water - rectangles.



.DrawCharacter2

    ; animation states: 0 - idle, 1 - walk left, 2 - walk right, 3 - jump left, 4 - jump right, 5 - jump up, 8 - dying
    ; situations:
    ;   - idle -> idle expressions
    ;   - idle -> walk left/right
    ;   - idle -> jump left/right
    ;   - idle -> jump up
    ;   - walk left/right -> idle
    ;   - jump left/right -> idle
    ;   - jump up -> idle
    ;   - walk left/right -> jump left/right
    ;   - 

    ; Traditional animations:
    ;   - idle front;
    ;   - idle jump;
    ;   - walk left/right;
    ;   - jump left/right;
    ; New animations:
    ;   - Run left/right (?);
    ;   - Climb ladder up/down facing player;
    ;   - Climb ladder up/down facing away from player;
    ;   - Climb ladder up/down sideways;
    ;   - Idle underwater;
    ;   - Idle water surface;
    ;   - Swim up/down;
    ;   - Swim left/right (underwater);
    ;   - Swim left/right (water surface);
    ;   - Walk left/right (water bottom floor);
    ;   - Vertical climb/descend (?);
    ;   - Slope slide;

    RET



.DrawCharacter
    PUSH A, Z                       ; Preserving the registers since we have an enclosing loop that uses some of them
    LD B, 3
    CALLR .ClearVideoPage

    ; Defining interrupt input
    LD A, 0x0E                      ; DrawTileMapSprite function index
    LD BCD, .sprSeymourWalkSheet    ; the source address (in RAM) of the tile map.
    ;LD BCD, .sprSeymourIdleJumpSheet    ; the source address (in RAM) of the tile map.
    LD EF, 192                      ; the width of the tilemap in pixels. This is used by the drawtilemapsprite interrupt to understand when's the next row of pixels
            ;LD EF, 39
                                    ; so it can travel vertically for its next sprite's row
    LD H, (.StateWalkFrameIndex)    ; Position on the correct current frame to draw
    LD G, 0
    MUL GH, 24
            ;LD GH, 0
    LD IJ, 0
    LD KL, 24                       ; the width of the sprite within the tile map.
    LD MN, 22                       ; the height of the sprite within the tile map.
            ;LD KL, 39
    LD O, 3                         ; the target video page where the sprite is to be drawn.

    LD PQ, (.StateCharacterPositionX)                      ; Character X
    LD RS, (.StateCharacterPositionY)                      ; Character Y

    LD T, (.StateCharacterAnimationIndex)
    AND T, 0b00000001

    ;LD T, 0b00000001                ; reset effect bits. Bit 0 - flip horizontal, bit 1 - flip vertical. The rest of the bits are not used.
    INT 0x01, A                     ; Trigger interrupt Video with the function index stored in A to draw the tile

    POP A, Z                        ; We return the previous values to registers before

    RET

.UpdateWalkState


    RET

.CharacterEnterIdleState
    
    RET

.UpdateCharacterAnimations
    ; If the .StateCharacterAnimationIndex is 1 or 2 (walk left or right) and previous state was different:
    ; - reset animation update time to now
    ; - update the StatePreviousCharacterAnimationIndex with whatever is now.

    LD A, (.StateCharacterAnimationIndex)
    LD B, (.StatePreviousCharacterAnimationIndex)

    CP A, B
    JP Z, .updateCharacterNoChange
    CALLR .CharacterAnimationStateChanged
    LD (.StatePreviousCharacterAnimationIndex), A

.updateCharacterNoChange
    ; Get the NOW time
    LD N, 0x03                          ; ReadClock
    LD O, 0x00                          ; Milliseconds
    LD PQR, .CurrentTimeMS  ; Set the destination address to .LastAnimationUpdateTimeMS
    INT 0x00, N                         ; Machine interrupt

    LD FGHI, (.LastAnimationUpdateTimeMS)       ; Load the previous time
    LD JKLM, (.CurrentTimeMS)                   ; Load the new time

    SUB JKLM, FGHI                              ; Calculate the delta between the current and previous clock ms
    LD OPQR, (.sprSeymourWalkFrameTimeMs)       ; Get the value of the target frame rate
    CP JKLM, OPQR                               ; Compare the delta with the target frame time
    JR GTE, .incrementAnimationFrame                    ; If the  delta is GTE than the target, we jump

    RET


.incrementAnimationFrame
    LD JKLM, (.CurrentTimeMS)
    LD (.LastAnimationUpdateTimeMS), JKLM
    LD A, (.StateWalkFrameIndex)
    INC A
    CP A, 8
    JR NZ, .incrementAnimationFrameDone
    LD A, 0
.incrementAnimationFrameDone    
    LD (.StateWalkFrameIndex), A

    RET


.CharacterAnimationStateChanged
    LD N, 0x03                          ; ReadClock
    LD O, 0x00                          ; Milliseconds
    LD PQR, .LastAnimationUpdateTimeMS  ; Set the destination address to .LastAnimationUpdateTimeMS
    INT 0x00, N                         ; Machine interrupt

    RET


.LastAnimationUpdateTimeMS
    #DB 0x00000000                      ; 32 bits for clock ms

.CurrentTimeMS
    #DB 0x00000000