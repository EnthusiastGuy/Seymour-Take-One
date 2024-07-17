; This manages all data that represent a game state. Everything here is part of a save-game.

.StateDataStart
    #DB 0x01                    ; State version

.StateCharacterRoomId
    #DB 0x0000

.StateCharacterPositionX
    #DB 0x0050

.StateCharacterPositionY
    #DB 0x0080

.StateCharacterAnimationIndex
    #DB 0x00                    ; 0 - idle, 1 - walk left, 2 - walk right, 3 - jump left, 4 - jump right, 5 - jump up

.StatePreviousCharacterAnimationIndex
    #DB 0x00

.StateWalkFrameIndex
    #DB 00

.StateDataEnd
    #DB 0xFF                    ; Dummy

; StatePlayerMovement: Stores control flags (1 bit per flag):
;   Left - sets 'left' flag
;   Right - sets 'right' flag
;   Jump - sets 'jump' flag
;   Up - sets 'up' flag
;   Down - sets 'down' flag
;   Action - sets 'action' flag
.StatePlayerMovement
    #DB 0x00
