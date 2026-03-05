;====================================================================
; TIC-TAC-TOE on AT89C51
; X=Player1, O=Player2/AI  |  B=current player
; Cells: 1:R0 2:R1 3:R2 / 4:R3 5:R4 6:R5 / 7:R6 8:R7 9:DPL
;====================================================================
MODEAI   BIT 20h
AIMOVED  BIT 21h
MODELAST BIT 22h
DEBCNT   EQU 30H
DLY1     EQU 31H
DLY2     EQU 32H

      org  0000h
      jmp  Start

;====================================================================
; START
;====================================================================
      org  100h
Start:
      MOV  IE,#00000000B
      MOV  P0,#0FFH
      MOV  P1,#00H
      MOV  P3,#0FFH
      CLR  P2.0
      CLR  P2.2
      SETB P2.1
      SETB P2.3
      SETB P2.4
      SETB P2.5
      SETB P2.6
      SETB P2.7
      SETB P3.7
      MOV  A,#38H
      LCALL CMD
      MOV  A,#0CH
      LCALL CMD
      LCALL CLRLCD
      LCALL RESETGRID
      CLR  MODEAI
      SETB MODELAST
      MOV  B,#'X'
      LCALL DRAWBOARD

EMPTYLOOP:
      LCALL CHECKMODEBTN
      LCALL SCANKEY
      JZ   EMPTYLOOP
      LCALL HANDLEKEY
      LJMP EMPTYLOOP

;====================================================================
; RESETGRID
;====================================================================
RESETGRID:
      MOV R0,#00H
      MOV R1,#00H
      MOV R2,#00H
      MOV R3,#00H
      MOV R4,#00H
      MOV R5,#00H
      MOV R6,#00H
      MOV R7,#00H
      MOV DPL,#00H
      RET

;====================================================================
; SCANKEY: Rows=P2.1,P2.3,P2.4  Cols=P2.5,P2.6,P2.7
; Returns A=1..9, or 0 if none
;====================================================================
SCANKEY:
      SETB P2.1
      SETB P2.3
      SETB P2.4
      SETB P2.5
      SETB P2.6
      SETB P2.7
      CLR  P2.1
      LCALL SMALLDEB
      JNB  P2.5,KEY1
      JNB  P2.6,KEY2
      JNB  P2.7,KEY3
      SETB P2.1
      CLR  P2.3
      LCALL SMALLDEB
      JNB  P2.5,KEY4
      JNB  P2.6,KEY5
      JNB  P2.7,KEY6
      SETB P2.3
      CLR  P2.4
      LCALL SMALLDEB
      JNB  P2.5,KEY7
      JNB  P2.6,KEY8
      JNB  P2.7,KEY9
      SETB P2.4
      MOV  A,#00H
      RET
KEY1: MOV A,#01H
      LJMP WAITREL
KEY2: MOV A,#02H
      LJMP WAITREL
KEY3: MOV A,#03H
      LJMP WAITREL
KEY4: MOV A,#04H
      LJMP WAITREL
KEY5: MOV A,#05H
      LJMP WAITREL
KEY6: MOV A,#06H
      LJMP WAITREL
KEY7: MOV A,#07H
      LJMP WAITREL
KEY8: MOV A,#08H
      LJMP WAITREL
KEY9: MOV A,#09H
WAITREL:
      LCALL SMALLDEB
REL1: SETB P2.1
      SETB P2.3
      SETB P2.4
      JNB  P2.5,REL1
      JNB  P2.6,REL1
      JNB  P2.7,REL1
      RET
SMALLDEB:
      MOV  DEBCNT,#30
D1:   DJNZ DEBCNT,D1
      RET

;====================================================================
; CHECKMODEBTN: P3.7 active LOW, toggles MODEAI and resets game
;====================================================================
CHECKMODEBTN:
      JB   MODELAST,CMB_LAST1
CMB_UPDATE:
      MOV  C,P3.7
      MOV  MODELAST,C
      RET
CMB_LAST1:
      JB   P3.7,CMB_UPDATE
      LCALL SMALLDEB
      JB   P3.7,CMB_UPDATE
      CPL  MODEAI
      LCALL RESETGRID
      MOV  B,#'X'
      LCALL SHOWTURN
      LCALL DRAWBOARD
CMB_WAITREL:
      JNB  P3.7,CMB_WAITREL
      LCALL SMALLDEB
      LJMP CMB_UPDATE

;====================================================================
; HANDLEKEY: A=1..9
;====================================================================
HANDLEKEY:
      CJNE A,#01H,HK2
      CJNE R0,#00H,HK_INV
      MOV  R0,B
      LJMP HK_PLAYED
HK2:  CJNE A,#02H,HK3
      CJNE R1,#00H,HK_INV
      MOV  R1,B
      LJMP HK_PLAYED
HK3:  CJNE A,#03H,HK4
      CJNE R2,#00H,HK_INV
      MOV  R2,B
      LJMP HK_PLAYED
HK4:  CJNE A,#04H,HK5
      CJNE R3,#00H,HK_INV
      MOV  R3,B
      LJMP HK_PLAYED
HK5:  CJNE A,#05H,HK6
      CJNE R4,#00H,HK_INV
      MOV  R4,B
      LJMP HK_PLAYED
HK6:  CJNE A,#06H,HK7
      CJNE R5,#00H,HK_INV
      MOV  R5,B
      LJMP HK_PLAYED
HK7:  CJNE A,#07H,HK8
      CJNE R6,#00H,HK_INV
      MOV  R6,B
      LJMP HK_PLAYED
HK8:  CJNE A,#08H,HK9
      CJNE R7,#00H,HK_INV
      MOV  R7,B
      LJMP HK_PLAYED
HK9:  CJNE A,#09H,HK_RET
      MOV  A,DPL
      CJNE A,#00H,HK_INV
      MOV  DPL,B
      LJMP HK_PLAYED
HK_INV:
      LCALL INVALIDMSG
      LCALL DRAWBOARD
      RET
HK_PLAYED:
      MOV  A,B
      CJNE A,#'X',HK_SETX
      MOV  B,#'O'
      LJMP HK_AFTERTURN
HK_SETX:
      MOV  B,#'X'
HK_AFTERTURN:
      LCALL SHOWTURN
      LCALL DRAWBOARD
      LCALL CHECKWIN
      JB   MODEAI,HK_AI
      RET
HK_AI:
      MOV  A,B
      CJNE A,#'O',HK_RET
      LCALL AIPLAY
      LCALL DRAWBOARD
      LCALL CHECKWIN
HK_RET:
      RET

;====================================================================
; AIPLAY: O tries Win -> Block -> Center -> Corner -> Edge
;====================================================================
AIPLAY:
      CLR  AIMOVED

;--- WIN ---
; Row1
      CJNE R0,#'O',AW_R1_2
      CJNE R1,#'O',AW_R1_2
      CJNE R2,#00H,AW_R1_2
      MOV  R2,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_R1_2:
      CJNE R0,#'O',AW_R1_3
      CJNE R2,#'O',AW_R1_3
      CJNE R1,#00H,AW_R1_3
      MOV  R1,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_R1_3:
      CJNE R1,#'O',AW_R2_1
      CJNE R2,#'O',AW_R2_1
      CJNE R0,#00H,AW_R2_1
      MOV  R0,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Row2
AW_R2_1:
      CJNE R3,#'O',AW_R2_2
      CJNE R4,#'O',AW_R2_2
      CJNE R5,#00H,AW_R2_2
      MOV  R5,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_R2_2:
      CJNE R3,#'O',AW_R2_3
      CJNE R5,#'O',AW_R2_3
      CJNE R4,#00H,AW_R2_3
      MOV  R4,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_R2_3:
      CJNE R4,#'O',AW_R3_1
      CJNE R5,#'O',AW_R3_1
      CJNE R3,#00H,AW_R3_1
      MOV  R3,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Row3
AW_R3_1:
      MOV  A,DPL
      CJNE R6,#'O',AW_R3_2
      CJNE R7,#'O',AW_R3_2
      CJNE A,#00H,AW_R3_2
      MOV  DPL,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_R3_2:
      MOV  A,DPL
      CJNE R6,#'O',AW_R3_3
      CJNE A,#'O',AW_R3_3
      CJNE R7,#00H,AW_R3_3
      MOV  R7,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_R3_3:
      MOV  A,DPL
      CJNE R7,#'O',AW_C1_1
      CJNE A,#'O',AW_C1_1
      CJNE R6,#00H,AW_C1_1
      MOV  R6,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Col1
AW_C1_1:
      CJNE R0,#'O',AW_C1_2
      CJNE R3,#'O',AW_C1_2
      CJNE R6,#00H,AW_C1_2
      MOV  R6,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_C1_2:
      CJNE R0,#'O',AW_C1_3
      CJNE R6,#'O',AW_C1_3
      CJNE R3,#00H,AW_C1_3
      MOV  R3,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_C1_3:
      CJNE R3,#'O',AW_C2_1
      CJNE R6,#'O',AW_C2_1
      CJNE R0,#00H,AW_C2_1
      MOV  R0,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Col2
AW_C2_1:
      CJNE R1,#'O',AW_C2_2
      CJNE R4,#'O',AW_C2_2
      CJNE R7,#00H,AW_C2_2
      MOV  R7,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_C2_2:
      CJNE R1,#'O',AW_C2_3
      CJNE R7,#'O',AW_C2_3
      CJNE R4,#00H,AW_C2_3
      MOV  R4,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_C2_3:
      CJNE R4,#'O',AW_C3_1
      CJNE R7,#'O',AW_C3_1
      CJNE R1,#00H,AW_C3_1
      MOV  R1,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Col3
AW_C3_1:
      MOV  A,DPL
      CJNE R2,#'O',AW_C3_2
      CJNE R5,#'O',AW_C3_2
      CJNE A,#00H,AW_C3_2
      MOV  DPL,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_C3_2:
      MOV  A,DPL
      CJNE R2,#'O',AW_C3_3
      CJNE A,#'O',AW_C3_3
      CJNE R5,#00H,AW_C3_3
      MOV  R5,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_C3_3:
      MOV  A,DPL
      CJNE R5,#'O',AW_D1_1
      CJNE A,#'O',AW_D1_1
      CJNE R2,#00H,AW_D1_1
      MOV  R2,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Diag1
AW_D1_1:
      MOV  A,DPL
      CJNE R0,#'O',AW_D1_2
      CJNE R4,#'O',AW_D1_2
      CJNE A,#00H,AW_D1_2
      MOV  DPL,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_D1_2:
      MOV  A,DPL
      CJNE R0,#'O',AW_D1_3
      CJNE A,#'O',AW_D1_3
      CJNE R4,#00H,AW_D1_3
      MOV  R4,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AW_D1_3:
      CJNE R4,#'O',AW_D2_1
      CJNE R0,#00H,AW_D2_1
      MOV  A,DPL
      CJNE A,#'O',AW_D2_1
      MOV  R0,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Diag2
AW_D2_1:
      CJNE R2,#'O',AB_START
      CJNE R4,#'O',AB_START
      CJNE R6,#00H,AB_START
      MOV  R6,#'O'
      SETB AIMOVED
      LJMP AI_DONE

;--- BLOCK ---
AB_START:
; Row1
      CJNE R0,#'X',AB_R1_2
      CJNE R1,#'X',AB_R1_2
      CJNE R2,#00H,AB_R1_2
      MOV  R2,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_R1_2:
      CJNE R0,#'X',AB_R1_3
      CJNE R2,#'X',AB_R1_3
      CJNE R1,#00H,AB_R1_3
      MOV  R1,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_R1_3:
      CJNE R1,#'X',AB_R2_1
      CJNE R2,#'X',AB_R2_1
      CJNE R0,#00H,AB_R2_1
      MOV  R0,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Row2
AB_R2_1:
      CJNE R3,#'X',AB_R2_2
      CJNE R4,#'X',AB_R2_2
      CJNE R5,#00H,AB_R2_2
      MOV  R5,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_R2_2:
      CJNE R3,#'X',AB_R2_3
      CJNE R5,#'X',AB_R2_3
      CJNE R4,#00H,AB_R2_3
      MOV  R4,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_R2_3:
      CJNE R4,#'X',AB_R3_1
      CJNE R5,#'X',AB_R3_1
      CJNE R3,#00H,AB_R3_1
      MOV  R3,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Row3
AB_R3_1:
      MOV  A,DPL
      CJNE R6,#'X',AB_R3_2
      CJNE R7,#'X',AB_R3_2
      CJNE A,#00H,AB_R3_2
      MOV  DPL,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_R3_2:
      MOV  A,DPL
      CJNE R6,#'X',AB_R3_3
      CJNE A,#'X',AB_R3_3
      CJNE R7,#00H,AB_R3_3
      MOV  R7,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_R3_3:
      MOV  A,DPL
      CJNE R7,#'X',AB_C1_1
      CJNE A,#'X',AB_C1_1
      CJNE R6,#00H,AB_C1_1
      MOV  R6,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Col1
AB_C1_1:
      CJNE R0,#'X',AB_C1_2
      CJNE R3,#'X',AB_C1_2
      CJNE R6,#00H,AB_C1_2
      MOV  R6,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_C1_2:
      CJNE R0,#'X',AB_C1_3
      CJNE R6,#'X',AB_C1_3
      CJNE R3,#00H,AB_C1_3
      MOV  R3,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_C1_3:
      CJNE R3,#'X',AB_C2_1
      CJNE R6,#'X',AB_C2_1
      CJNE R0,#00H,AB_C2_1
      MOV  R0,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Col2
AB_C2_1:
      CJNE R1,#'X',AB_C2_2
      CJNE R4,#'X',AB_C2_2
      CJNE R7,#00H,AB_C2_2
      MOV  R7,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_C2_2:
      CJNE R1,#'X',AB_C2_3
      CJNE R7,#'X',AB_C2_3
      CJNE R4,#00H,AB_C2_3
      MOV  R4,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_C2_3:
      CJNE R4,#'X',AB_C3_1
      CJNE R7,#'X',AB_C3_1
      CJNE R1,#00H,AB_C3_1
      MOV  R1,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Col3
AB_C3_1:
      MOV  A,DPL
      CJNE R2,#'X',AB_C3_2
      CJNE R5,#'X',AB_C3_2
      CJNE A,#00H,AB_C3_2
      MOV  DPL,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_C3_2:
      MOV  A,DPL
      CJNE R2,#'X',AB_C3_3
      CJNE A,#'X',AB_C3_3
      CJNE R5,#00H,AB_C3_3
      MOV  R5,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_C3_3:
      MOV  A,DPL
      CJNE R5,#'X',AB_D1_1
      CJNE A,#'X',AB_D1_1
      CJNE R2,#00H,AB_D1_1
      MOV  R2,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Diag1
AB_D1_1:
      MOV  A,DPL
      CJNE R0,#'X',AB_D1_2
      CJNE R4,#'X',AB_D1_2
      CJNE A,#00H,AB_D1_2
      MOV  DPL,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_D1_2:
      MOV  A,DPL
      CJNE R0,#'X',AB_D1_3
      CJNE A,#'X',AB_D1_3
      CJNE R4,#00H,AB_D1_3
      MOV  R4,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AB_D1_3:
      CJNE R4,#'X',AB_D2_1
      CJNE R0,#00H,AB_D2_1
      MOV  A,DPL
      CJNE A,#'X',AB_D2_1
      MOV  R0,#'O'
      SETB AIMOVED
      LJMP AI_DONE
; Diag2
AB_D2_1:
      CJNE R2,#'X',AI_FALLBACK
      CJNE R4,#'X',AI_FALLBACK
      CJNE R6,#00H,AI_FALLBACK
      MOV  R6,#'O'
      SETB AIMOVED
      LJMP AI_DONE

;--- Center / Corners / Edges ---
AI_FALLBACK:
      CJNE R4,#00H,AI_CORNERS
      MOV  R4,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AI_CORNERS:
      CJNE R0,#00H,AI_C3
      MOV  R0,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AI_C3:
      CJNE R2,#00H,AI_C7
      MOV  R2,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AI_C7:
      CJNE R6,#00H,AI_C9
      MOV  R6,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AI_C9:
      MOV  A,DPL
      CJNE A,#00H,AI_EDGES
      MOV  DPL,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AI_EDGES:
      CJNE R1,#00H,AI_E4
      MOV  R1,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AI_E4:
      CJNE R3,#00H,AI_E6
      MOV  R3,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AI_E6:
      CJNE R5,#00H,AI_E8
      MOV  R5,#'O'
      SETB AIMOVED
      LJMP AI_DONE
AI_E8:
      CJNE R7,#00H,AI_DONE
      MOV  R7,#'O'
      SETB AIMOVED
AI_DONE:
      JB   AIMOVED,AI_SETX
      RET
AI_SETX:
      MOV  B,#'X'
      RET

;====================================================================
; CHECKWIN: all 8 lines then draw check
;====================================================================
CHECKWIN:
; Row1
      MOV A,R0
      CJNE A,#'X',L1_O
      MOV A,R1
      CJNE A,#'X',L1_O
      MOV A,R2
      CJNE A,#'X',L1_O
      LJMP XWIN
L1_O: MOV A,R0
      CJNE A,#'O',L2_X
      MOV A,R1
      CJNE A,#'O',L2_X
      MOV A,R2
      CJNE A,#'O',L2_X
      LJMP OWIN
; Row2
L2_X: MOV A,R3
      CJNE A,#'X',L2_O
      MOV A,R4
      CJNE A,#'X',L2_O
      MOV A,R5
      CJNE A,#'X',L2_O
      LJMP XWIN
L2_O: MOV A,R3
      CJNE A,#'O',L3_X
      MOV A,R4
      CJNE A,#'O',L3_X
      MOV A,R5
      CJNE A,#'O',L3_X
      LJMP OWIN
; Row3
L3_X: MOV A,R6
      CJNE A,#'X',L3_O
      MOV A,R7
      CJNE A,#'X',L3_O
      MOV A,DPL
      CJNE A,#'X',L3_O
      LJMP XWIN
L3_O: MOV A,R6
      CJNE A,#'O',C1_X
      MOV A,R7
      CJNE A,#'O',C1_X
      MOV A,DPL
      CJNE A,#'O',C1_X
      LJMP OWIN
; Col1
C1_X: MOV A,R0
      CJNE A,#'X',C1_O
      MOV A,R3
      CJNE A,#'X',C1_O
      MOV A,R6
      CJNE A,#'X',C1_O
      LJMP XWIN
C1_O: MOV A,R0
      CJNE A,#'O',C2_X
      MOV A,R3
      CJNE A,#'O',C2_X
      MOV A,R6
      CJNE A,#'O',C2_X
      LJMP OWIN
; Col2
C2_X: MOV A,R1
      CJNE A,#'X',C2_O
      MOV A,R4
      CJNE A,#'X',C2_O
      MOV A,R7
      CJNE A,#'X',C2_O
      LJMP XWIN
C2_O: MOV A,R1
      CJNE A,#'O',C3_X
      MOV A,R4
      CJNE A,#'O',C3_X
      MOV A,R7
      CJNE A,#'O',C3_X
      LJMP OWIN
; Col3
C3_X: MOV A,R2
      CJNE A,#'X',C3_O
      MOV A,R5
      CJNE A,#'X',C3_O
      MOV A,DPL
      CJNE A,#'X',C3_O
      LJMP XWIN
C3_O: MOV A,R2
      CJNE A,#'O',D1_X
      MOV A,R5
      CJNE A,#'O',D1_X
      MOV A,DPL
      CJNE A,#'O',D1_X
      LJMP OWIN
; Diag1
D1_X: MOV A,R0
      CJNE A,#'X',D1_O
      MOV A,R4
      CJNE A,#'X',D1_O
      MOV A,DPL
      CJNE A,#'X',D1_O
      LJMP XWIN
D1_O: MOV A,R0
      CJNE A,#'O',D2_X
      MOV A,R4
      CJNE A,#'O',D2_X
      MOV A,DPL
      CJNE A,#'O',D2_X
      LJMP OWIN
; Diag2
D2_X: MOV A,R2
      CJNE A,#'X',D2_O
      MOV A,R4
      CJNE A,#'X',D2_O
      MOV A,R6
      CJNE A,#'X',D2_O
      LJMP XWIN
D2_O: MOV A,R2
      CJNE A,#'O',CHECK_DRAW
      MOV A,R4
      CJNE A,#'O',CHECK_DRAW
      MOV A,R6
      CJNE A,#'O',CHECK_DRAW
      LJMP OWIN
; Draw check
CHECK_DRAW:
      MOV A,R0
      JZ  NOT_DRAW
      MOV A,R1
      JZ  NOT_DRAW
      MOV A,R2
      JZ  NOT_DRAW
      MOV A,R3
      JZ  NOT_DRAW
      MOV A,R4
      JZ  NOT_DRAW
      MOV A,R5
      JZ  NOT_DRAW
      MOV A,R6
      JZ  NOT_DRAW
      MOV A,R7
      JZ  NOT_DRAW
      MOV A,DPL
      JZ  NOT_DRAW
      LJMP DRAWMSG
NOT_DRAW:
      RET

;====================================================================
; WIN / DRAW MESSAGES
;====================================================================
XWIN:
      LCALL CLRLCD
      MOV  A,#80H
      LCALL CMD
      JB   MODEAI,XWIN_AI
      MOV  A,#'X'
      LCALL DWR
      LCALL PRINTWINMESS
      RET
XWIN_AI:
      MOV A,#'Y'
      LCALL DWR
      MOV A,#'O'
      LCALL DWR
      MOV A,#'U'
      LCALL DWR
      MOV A,#' '
      LCALL DWR
      MOV A,#'W'
      LCALL DWR
      MOV A,#'O'
      LCALL DWR
      MOV A,#'N'
      LCALL DWR
      LJMP INFT

OWIN:
      LCALL CLRLCD
      MOV  A,#80H
      LCALL CMD
      JB   MODEAI,OWIN_AI
      MOV  A,#'O'
      LCALL DWR
      LCALL PRINTWINMESS
      RET
OWIN_AI:
      MOV A,#'A'
      LCALL DWR
      MOV A,#'I'
      LCALL DWR
      MOV A,#' '
      LCALL DWR
      MOV A,#'W'
      LCALL DWR
      MOV A,#'O'
      LCALL DWR
      MOV A,#'N'
      LCALL DWR
INFT: LJMP INFT

PRINTWINMESS:
      MOV A,#' '
      LCALL DWR
      MOV A,#'P'
      LCALL DWR
      MOV A,#'L'
      LCALL DWR
      MOV A,#'A'
      LCALL DWR
      MOV A,#'Y'
      LCALL DWR
      MOV A,#'E'
      LCALL DWR
      MOV A,#'R'
      LCALL DWR
      MOV A,#' '
      LCALL DWR
      MOV A,#'W'
      LCALL DWR
      MOV A,#'O'
      LCALL DWR
      MOV A,#'N'
      LCALL DWR
      RET

DRAWMSG:
      LCALL CLRLCD
      MOV  A,#80H
      LCALL CMD
      MOV  A,#'D'
      LCALL DWR
      MOV  A,#'R'
      LCALL DWR
      MOV  A,#'A'
      LCALL DWR
      MOV  A,#'W'
      LCALL DWR
DRAWLOOP: LJMP DRAWLOOP

;====================================================================
; INVALIDMSG
;====================================================================
INVALIDMSG:
      LCALL CLRLCD
      MOV  A,#80H
      LCALL CMD
      MOV  A,#'I'
      LCALL DWR
      MOV  A,#'N'
      LCALL DWR
      MOV  A,#'V'
      LCALL DWR
      MOV  A,#'A'
      LCALL DWR
      MOV  A,#'L'
      LCALL DWR
      MOV  A,#'I'
      LCALL DWR
      MOV  A,#'D'
      LCALL DWR
      LCALL DELAY
      LCALL DELAY
      RET

;====================================================================
; SHOWTURN
;====================================================================
SHOWTURN:
      LCALL CLRLCD
      MOV  A,#80H
      LCALL CMD
      JB   MODEAI,ST_AI
      MOV  A,#'T'
      LCALL DWR
      MOV  A,#'U'
      LCALL DWR
      MOV  A,#'R'
      LCALL DWR
      MOV  A,#'N'
      LCALL DWR
      MOV  A,#':'
      LCALL DWR
      MOV  A,#' '
      LCALL DWR
      MOV  A,B
      LCALL DWR
      LJMP ST_WAIT
ST_AI:
      MOV  A,B
      CJNE A,#'O',ST_YOU
      MOV  A,#'A'
      LCALL DWR
      MOV  A,#'I'
      LCALL DWR
      MOV  A,#' '
      LCALL DWR
      MOV  A,#'T'
      LCALL DWR
      MOV  A,#'U'
      LCALL DWR
      MOV  A,#'R'
      LCALL DWR
      MOV  A,#'N'
      LCALL DWR
      LJMP ST_WAIT
ST_YOU:
      MOV  A,#'Y'
      LCALL DWR
      MOV  A,#'O'
      LCALL DWR
      MOV  A,#'U'
      LCALL DWR
      MOV  A,#'R'
      LCALL DWR
      MOV  A,#' '
      LCALL DWR
      MOV  A,#'T'
      LCALL DWR
      MOV  A,#'U'
      LCALL DWR
      MOV  A,#'R'
      LCALL DWR
      MOV  A,#'N'
      LCALL DWR
ST_WAIT:
      LCALL DELAY
      LCALL DELAY
      RET

;====================================================================
; LCD PRIMITIVES
; Data: P1 | RS: P2.0 | E: P2.2 | RW: GND
;====================================================================
DWR:
      MOV  P1,A
      SETB P2.0
      SETB P2.2
      LCALL DELAY
      CLR  P2.2
      RET

CMD:
      MOV  P1,A
      CLR  P2.0
      SETB P2.2
      LCALL DELAY
      CLR  P2.2
      RET

DELAY:
      MOV  DLY1,#110
DLY_L1:
      MOV  DLY2,#150
DLY_L2:
      DJNZ DLY2,DLY_L2
      DJNZ DLY1,DLY_L1
      RET

CLRLCD:
      MOV  A,#01H
      LCALL CMD
      MOV  A,#06H
      LCALL CMD
      RET

;====================================================================
; DRAWBOARD
;====================================================================
DRAWBOARD:
      LCALL CLRLCD
      MOV  A,#80H
      LCALL CMD
      LCALL DRAW2SP
      MOV  A,R0
      LCALL DWR
      LCALL DRAWSEP
      MOV  A,R1
      LCALL DWR
      LCALL DRAWSEP
      MOV  A,R2
      LCALL DWR
      MOV  A,#0C0H
      LCALL CMD
      LCALL DRAW2SP
      MOV  A,R3
      LCALL DWR
      LCALL DRAWSEP
      MOV  A,R4
      LCALL DWR
      LCALL DRAWSEP
      MOV  A,R5
      LCALL DWR
      LCALL DRAW2SP
      MOV  A,#' '
      LCALL DWR
      MOV  A,R6
      LCALL DWR
      LCALL DRAWSEP
      MOV  A,R7
      LCALL DWR
      LCALL DRAWSEP
      MOV  A,DPL
      LCALL DWR
      RET

DRAW2SP:
      MOV  A,#' '
      LCALL DWR
      MOV  A,#' '
      LCALL DWR
      RET

DRAWSEP:
      LCALL DRAW2SP
      MOV  A,#'|'
      LCALL DWR
      LCALL DRAW2SP
      RET

;====================================================================
      END
