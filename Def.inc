
  FileABB  equ 0x0101010101010101
  FileHBB  equ 0x8080808080808080
  Rank8BB  equ 0xFF00000000000000
  Rank7BB  equ 0x00FF000000000000
  Rank6BB  equ 0x0000FF0000000000
  Rank3BB  equ 0x0000000000FF0000
  Rank2BB  equ 0x000000000000FF00
  Rank1BB  equ 0x00000000000000FF

; cpu flags
 HAVE_POPCNT  fix 0x000001
 HAVE_AVX1    fix 0x000010
 HAVE_AVX2    fix 0x000020
 HAVE_BMI1    fix 0x000100
 HAVE_BMI2    fix 0x000200


; move types
 MOVE_TYPE_DPAWN  fix 1
 MOVE_TYPE_CASTLE fix 2
 MOVE_TYPE_EPCAP  fix 3
 MOVE_TYPE_PROM   fix 4

; piece types
 White	 fix 0
 Black	 fix 1
 Pawn	 fix 2
 Knight  fix 3
 Bishop  fix 4
 Rook	 fix 5
 Queen	 fix 6
 King	 fix 7

; piece values
PAWN_VALUE_MG	= 198
KNIGHT_VALUE_MG = 817
BISHOP_VALUE_MG = 826
ROOK_VALUE_MG	= 1270
QUEEN_VALUE_MG	= 2521

PAWN_VALUE_EG	= 256
KNIGHT_VALUE_EG = 846
BISHOP_VALUE_EG = 857
ROOK_VALUE_EG	= 1278
QUEEN_VALUE_EG	= 2558

VALUE_KNOWN_WIN = 10000

struct TT
  mem	 rq 1
  mask	 rq 1
  sizeMB rd 1
  date	 rb 1
	 rb 3
ends

struct Cluster
  entry rb 32
ends

ZOBRIST_SIDE = sizeof.Cluster

HistoryStats_Max = 10234

MAX_MOVES = 128

struct Pick
 cur		rq 1
 end		rq 1
 endBadCaptures rq 1
 endQuiets	rq 1
 stage		rq 1
 ;ss             rq 1
 ttMove 	rd 1
 captureThreshold rd 1
 countermoves	rw 2
 followupmoves	rw 2
 recaptureSquare rb 1
		rb 7
 killers	rq 6
 moves		rq MAX_MOVES
ends

struct Pos
  typeBB	rq 8
  board 	rb 64
  gamePly	rd 1
  sideToMove	rd 1
  startState	rq 1
  state 	rq 1
  ss		rq 1
  nodes 	rq 1
  thisThread	rq 1
ends

struct Stack
  splitPoint	rq 1
  pv		rq 1
  killers	rw 2
  ply		rw 1
  skipNullMove	rb 1
  reduction	rb 1
  staticEval	rw 1
  currentMove	rw 1
  ttMove	rw 1
  excludedMove	rw 1
ends

struct State
  key		 rq 1
  pawnKey	 rq 1
  materialKey	 rq 1
  psq		 rw 2
  npMaterial	 rw 2
  rule50	 rb 1  ; these should be together
  pliesFromNull  rb 1  ;
  castlingRights rb 1
  epSquare	 rb 1
  move		 rw 1
  capturedPiece  rb 1
  ksq		 rb 1
  checkersBB	 rq 1
  dcCandidates	 rq 1
  pinned	 rq 1
  checkSq	 rq 8
ends


SQ_A1 = 0+8*0
SQ_B1 = 1+8*0
SQ_C1 = 2+8*0
SQ_D1 = 3+8*0
SQ_E1 = 4+8*0
SQ_F1 = 5+8*0
SQ_G1 = 6+8*0
SQ_H1 = 7+8*0

SQ_A2 = 0+8*1
SQ_B2 = 1+8*1
SQ_C2 = 2+8*1
SQ_D2 = 3+8*1
SQ_E2 = 4+8*1
SQ_F2 = 5+8*1
SQ_G2 = 6+8*1
SQ_H2 = 7+8*1

SQ_A3 = 0+8*2
SQ_B3 = 1+8*2
SQ_C3 = 2+8*2
SQ_D3 = 3+8*2
SQ_E3 = 4+8*2
SQ_F3 = 5+8*2
SQ_G3 = 6+8*2
SQ_H3 = 7+8*2

SQ_A4 = 0+8*3
SQ_B4 = 1+8*3
SQ_C4 = 2+8*3
SQ_D4 = 3+8*3
SQ_E4 = 4+8*3
SQ_F4 = 5+8*3
SQ_G4 = 6+8*3
SQ_H4 = 7+8*3

SQ_A5 = 0+8*4
SQ_B5 = 1+8*4
SQ_C5 = 2+8*4
SQ_D5 = 3+8*4
SQ_E5 = 4+8*4
SQ_F5 = 5+8*4
SQ_G5 = 6+8*4
SQ_H5 = 7+8*4

SQ_A8 = 0+8*7
SQ_B8 = 1+8*7
SQ_C8 = 2+8*7
SQ_D8 = 3+8*7
SQ_E8 = 4+8*7
SQ_F8 = 5+8*7
SQ_G8 = 6+8*7
SQ_H8 = 7+8*7


;