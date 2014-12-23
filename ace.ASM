format PE64 console
entry Start
;org 0x04000

DEBUG = 0

include 'win64axp.inc'
include 'Def.inc'
include 'Functions.inc'

 ; special instruction sets
 ;  HAVE_POPCNT   popcnt
 ;  HAVE_AVX1     256 bit floating point                (probable only used for memory copy)
 ;  HAVE_AVX2     256 bit integer + fused multiply add  (probably not used)
 ;  HAVE_BMI1     andn
 ;  HAVE_BMI2     pext + pdep                           (nice for move generation)
 ; just add the ones you have into HAVE:
HAVE = 0 + HAVE_POPCNT + HAVE_AVX1; + HAVE_AVX2 + HAVE_BMI1 + HAVE_BMI2


section '.data' data readable writeable


align 16
 RandSeed   dd 0x23498764,0x1F8A58B3,0x12345C78,0x8D654321
 RandInc    dd 0x23498764,0x1F8A58B3,0x12345C78,0x8D654321

align 8
BitBoard_Rank8	   dq 1111111100000000000000000000000000000000000000000000000000000000b
BitBoard_Rank1	   dq 0000000000000000000000000000000000000000000000000000000011111111b
BitBoard_FileA	   dq 0000000100000001000000010000000100000001000000010000000100000001b
BitBoard_FileH	   dq 1000000010000000100000001000000010000000100000001000000010000000b
BitBoard_Corners   dq 0111111011111111111111111111111111111111111111111111111101111110b
if ~(HAVE and HAVE_POPCNT)
Mask55	  dq 0x5555555555555555
Mask33	  dq 0x3333333333333333
Mask0F	  dq 0x0F0F0F0F0F0F0F0F
Mask01	  dq 0x0101010101010101
end if

align 8
Gen_QuietChecks_JmpTable:
		dq 0;Gen_QuietChecks_Jmp.PopSkip
		dq 0;Gen_QuietChecks_Jmp.PopSkip
		dq Gen_QuietChecks.PopSkip
		dq Gen_QuietChecks_Jmp.AttacksFromKnight
		dq Gen_QuietChecks_Jmp.AttacksFromBishop
		dq Gen_QuietChecks_Jmp.AttacksFromRook
		dq Gen_QuietChecks_Jmp.AttacksFromQueen
		dq Gen_QuietChecks_Jmp.AttacksFromKing
;GivesCheck_JmpTable:
;                dq 0
;                dq 0
;                dq GivesCheck.Castling
;                dq GivesCheck.EpCapture
;                dq GivesCheck.PromKnight
;                dq GivesCheck.PromBishop
;                dq GivesCheck.PromRook
;                dq GivesCheck.PromQueen

IsMovePseudoLegal_JmpTable:
		dq IsMovePseudoLegal.NoPiece
		dq IsMovePseudoLegal.NoPiece
		dq IsMovePseudoLegal.Pawn
		dq IsMovePseudoLegal.Knight
		dq IsMovePseudoLegal.Bishop
		dq IsMovePseudoLegal.Rook
		dq IsMovePseudoLegal.Queen
		dq IsMovePseudoLegal.King




;0xF386
;1111 001110 000110

align 1
 szUCIresponse	      db 'id name fasm chess engine',10
		      db 'id author tthsqe',10
		      db 'option name Hash type spin min 16 max 65536 default 128',10
		      db 'option name MultiPV type spin min 1 max 64 default 1',10
		      db 'option name Ponder type check default false',10
		      db 'option name Threads type spin min 1 max 8 default 1',10
		      db 'uciok',10,0
 szCPUError	      db 'Error: processor does not support ',0
   .POPCNT	      db 'POPCNT',0
   .AVX1	      db 'AVX1',0
   .AVX2	      db 'AVX2',0
   .BMI1	      db 'BMI1',0
   .BMI2	      db 'BMI2',0
 szReadyOK	      db 'readyok',10,0
 szOK		      db 'ok',10,0
 szError	      db 'error',10,0
 szErrorKings	      db 'error - king count',10,0
 szErrorPawns	      db 'error - pawns on 1st or 8th',10,0
 szErrorCastling      db 'error - castling',10,0
 szErrorBoardMatch    db 'error - bitboards do not match',10,0
 szErrorEpSquare      db 'error - ep square',10,0
 szErrorPieces	      db 'error - pieces',10,0
 szErrorKingCapture   db 'error - king capture',10,0

; szCommandTestBit     db 'test',0
; szCommandMove        db 'move',0
 szParseError	      db 'command parsing error',10,0
 szIllegal	      db 'illegal position',10,0
 szIsMate	      db 'it is checkmate',10,0
 szPerftProblem       db 'perft problem',10,0
 szMoveNotPseudoLegal db 'move is not pseudo legal',10,0
 szMovePseudoLegal    db 'move is pseudo legal',10,0
 szMoveLegal	      db 'move is legal',10,0
 szMoveIllegal	      db 'move is illegal',10,0
 szInternalError      db 'internal error',10,0
 szGreeting	      db 'fasm chess engine based on stockfish',10,0
 szStartPosition      db 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',0
 PieceToChar	      db '.?PNBRQK??pnbrqk'


if DEBUG
perft_ok db ?
end if

;include 'Pst.inc'

include 'psqr.inc'

align 16
 hThreadArray	 rq 64


align 8
 Counter	dq ?
 Frequency	dq ?
 Period 	dq ?
 ProcessAffinityMask dq ?
 SystemAffinityMask  dq ?
 hStdOut	  dq ?
 hStdIn 	  dq ?
 hStdError	  dq ?
 hSearchThread	 dq ?
 hTimerThread	 dq ?
 AlottedTime	 dq ?
 MoveTime	 dq ?
 WTime		 dq ?
 BTime		 dq ?
 WInc		 dq ?
 BInc		 dq ?
 MovesToGo	 dq ?
 temp		 dq ?

align 4
 MultiPV      dd ?
 Ponder       dd ?
 Threads      dd ?

align 4
 RootDepth	   dd ?
 Score		   dd ?
 BestMove	   dw ?
 PonderMove	   dw ?
 SearchThreadStartEvent  dd ?
 TimerThreadStartEvent	 dd ?
 TimerThreadEndEvent	 dd ?

align 1
 PerftProblem	    db ?
 SearchThreadState  db ?
 TimerThreadState   db ?



section '.rdata' data readable writeable

align 8
 History	  rd 64*64

align 8
 KillerMoves	       rd 64


;;;;;;;;;;;;;;;;;;;;;;;; structures for position searcing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 16
 HashTable  rb sizeof.TT
align 32
 BoardPosition	 rb sizeof.Pos

align 32
 StateList	 rb 1024*sizeof.State

align 32
 SearchStack	 rb 1024*sizeof.Stack

align 8
 MoveList	 rd 1024
 MoveList1	 rd 1024

align 16
 Input		 rb 8*1024
 Output 	 rb 4*1024



section '.bss' data readable writeable


;;;;;;;;;;;;;;;;;;;;;;;; data for move generation  ;;;;;;;;;;;;;;;;;;;;;;;;;;

align 4096
 SlidingAttackMasks  rb 212*1024*4
 BishopAttacksPEXT   rq 64     ; bitboards
 BishopAttacksMOFF   rd 64     ; addresses, only 32 bits needed
 BishopAttacksPDEP   rq 64     ; bitboards
 RookAttacksPEXT     rq 64     ; bitboards
 RookAttacksMOFF     rd 64     ; addresses, only 32 bits needed
 RookAttacksPDEP     rq 64     ; bitboards
if ~(HAVE and HAVE_BMI2)
 BishopAttacksIMUL   rq 64
 RookAttacksIMUL     rq 64
 BishopAttacksSHIFT  rb 64
 RookAttacksSHIFT    rb 64
end if

BetweenBB:
 BetweenMasks	     rq 64*64
 LineMasks	     rq 64*64
PawnAttacks:
 WhitePawnAttacks    rq 64     ; bitboards
 BlackPawnAttacks    rq 64     ; bitboards
;PawnMoves:
; WhitePawnMoves      rq 64     ; bitboards
; BlackPawnMoves      rq 64     ; bitboards

; WhitePawnPromRank   rq 1      ; bitboard
; WhitePawnHomeRank   rq 1      ; bitboard
; BlackPawnPromRank   rq 1      ; bitboard
; BlackPawnHomeRank   rq 1      ; bitboard
 KnightAttacks	     rq 64     ; bitboards
 KingAttacks	     rq 64     ; bitboards
; SquareDistance      rb 64*64
 FileBB 	     rq 8
; CastlingMasks       rb 64     ; masks, 8 bits
; CastlingOOClear     rq 2
; CastlingOOOClear    rq 2
; CastlingOOCheck     rq 2
; CastlingOOOCheck    rq 2
; CastlingOOMove      rd 2
; CastlingOOOMove     rd 2

;;;;;;;;;;;;;;;;;;;; DoMove data ;;;;;;;;;;;;;;;;;;;;;;;;

align 64
Scores_Pieces:	  rq 16*64
Zobrist_Pieces:   rq 16*64
Zobrist_Castling: rq 16
Zobrist_Ep:	  rq 8
PieceValue_MG:	  rd 16
PieceValue_EG:	  rd 16
ScoreCaptures_MoveTypeValues rd 8

CastlingMasks:	  rb 64
IsNotPawnMasks:   rb 16
IsNotPieceMasks:  rb 16
IsPawnMasks:	  rb 16



;;;;;;;;;;;;;;;;;;;; data for evaluation ;;;;;;;;;;;;;;;;;;;;;;;

align 64
 SwapValues	     rd 8
 WhitePassedPawns    rq 64    ; bitboards
 BlackPassedPawns    rq 64    ; bitboards
 IsolatedPawns	     rq 64    ; bitboards
 KPKEndgameTable     rq 48*64 ; bit table for lookup

section '.code' code readable executable

include 'gen_macro.inc'
include 'pick_macro.inc'



include 'search.asm'

include 'SetCheckInfo.asm'
include 'AttackersTo.asm'
include 'DoMove.asm'
include 'DoMove_SetCheckInfo.asm'
include 'GivesCheck.asm'
include 'UndoMove.asm'
include 'Gen_NonEvasions.asm'
include 'Gen_Legal.asm'
include 'Gen_Evasions.asm'

include 'Castling.asm'
include 'PerftGen.asm'
include 'PerftPick.asm'

include 'Gen_Quiets.asm'
include 'Gen_QuietChecks.asm'
include 'Gen_Captures.asm'

include 'IsMoveLegal.asm'
include 'IsMovePseudoLegal.asm'
include 'MovePick.asm'
include 'See.asm'

;include 'tt_hot.inc'


include 'Position.asm'
include 'HashTable.asm'
include 'Uci.asm'

include 'Misc.asm'

include 'Windows.asm'
include 'Init.asm'

Start:

		and   rsp, -32
		sub   rsp, 32

	; get stuff from os
	       call   _SetStdHandles
	       call   _SetFrequency
	       call   _SetAffinityMasks
	       call   _CheckCPU

	; initialize stuff
		mov   ecx, 128
	       call   HashTable_Allocate
	       call   Initialize_MoveGen
	       call   Initialize_DoMove
	       call   InitializeTables

	; loop
	       call   UciLoop

	; clean up
	       call   HashTable_Free
		xor   ecx, ecx
	       call   _ExitProcess

section '.idata' import data readable writeable

 library kernel,'KERNEL32.DLL'

import kernel,\
	__imp_CreateThread,'CreateThread',\
	__imp_GetProcAddress,'GetProcAddress',\
	__imp_GetCurrentProcess,'GetCurrentProcess',\
	__imp_GetProcessAffinityMask,'GetProcessAffinityMask',\
	__imp_EnterCriticalSection,'EnterCriticalSection',\
	__imp_LeaveCriticalSection,'LeaveCriticalSection',\
	__imp_CloseHandle,'CloseHandle',\
	__imp_WaitForSingleObject,'WaitForSingleObject',\
	__imp_SetEvent,'SetEvent',\
	__imp_QueryPerformanceFrequency,'QueryPerformanceFrequency',\
	__imp_GetStdHandle,'GetStdHandle',\
	__imp_ReadFile,'ReadFile',\
	__imp_CreateEventA,'CreateEventA',\
	__imp_VirtualFree,'VirtualFree',\
	__imp_ExitProcess,'ExitProcess',\
	__imp_ExitThread,'ExitThread',\
	__imp_InitializeCriticalSection,'InitializeCriticalSection',\
	__imp_DeleteCriticalSection,'DeleteCriticalSection',\
	__imp_QueryPerformanceCounter,'QueryPerformanceCounter',\
	__imp_LoadLibrary,'LoadLibraryA',\
	__imp_VirtualAlloc,'VirtualAlloc',\
	__imp_WriteFile,'WriteFile'

