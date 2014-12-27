
struct Pos
  typeBB	rq 8
  board 	rb 64
  gamePly	rd 1
  sideToMove	rd 1
  nodes 	rq 1
  ss		rq 1
  ssTable	rq 1
  state 	rq 1
  stateTable	rq 1
  pawnsTable	rq 1
  materialTable rq 1
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

struct Stack
  splitPoint	rq 1
  killers	rw 2
		rb 1
  ply		rb 1
  skipNullMove	rb 1
  reduction	rb 1
  staticEval	rw 1
  currentMove	rw 1
  ttMove	rw 1
  excludedMove	rw 1
  pv		rw MAX_PLY+1
ends

struct TT
  mem	 rq 1
  mask	 rq 1
  sizeMB rd 1
  date	 rb 1
	 rb 3
ends

struct Cluster
  entry0  rq 1
  entry1  rq 1
  entry2  rq 1
  key0	  rw 1
  key1	  rw 1
  key2	  rw 1
	  rw 1
ends


struct Pick
 cur		rq 1
 end		rq 1
 endBadCaptures rq 1
 endQuiets	rq 1
 stage		rq 1
 ttMove 	rd 1
 captureThreshold rd 1
 countermoves	rw 2
 followupmoves	rw 2
 recaptureSquare rb 1
		rb 7
 killers	rq 6
 moves		rq MAX_MOVES
ends
