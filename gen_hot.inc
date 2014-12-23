




























; generate_CAPTURES generates all pseudo-legal captures and queen
; promotions. Returns a pointer to the end of the move list.

		      align  16
Gen_Captures:
		       push  rsi r12 r13 r14 r15
			mov   r14, qword[rbp+Pos.typeBB+8*White]
			 or   r14, qword[rbp+Pos.typeBB+8*Black]
			cmp  byte[rbp+Pos.sideToMove],0
			jne  Gen_Captures_Black
Gen_Captures_White:
			mov  r15,qword[rbp+Pos.typeBB+8*Black]
	       generate_all  White, CAPTURES
			pop  r15 r14 r13 r12 rsi
			ret
	       generate_jmp  White, CAPTURES

Gen_Captures_Black:
			mov  r15,qword[rbp+Pos.typeBB+8*White]
	       generate_all  Black, CAPTURES
			pop  r15 r14 r13 r12 rsi
			ret
	       generate_jmp  Black, CAPTURES






; generate_QUIETS generates all pseudo-legal non-captures and
; underpromotions. Returns a pointer to the end of the move list.

		      align  16
Gen_Quiets:
		       push   rsi r12 r13 r14 r15
			mov   rdi, rcx
			mov   r15, qword [rbp+Pos.typeBB+8*White]
			 or   r15, qword [rbp+Pos.typeBB+8*Black]
			mov   r14, r15
			not   r15
			cmp   byte [rbp+Pos.sideToMove], 0
			jne   Gen_Quiets_Black
Gen_Quiets_White:
	       generate_all   White, QUIETS
			pop   r15 r14 r13 r12 rsi
			ret
	       generate_jmp   White, QUIETS

Gen_Quiets_Black:
	       generate_all   Black, QUIETS
			pop   r15 r14 r13 r12 rsi
			ret
	       generate_jmp   Black, QUIETS








; generate_NON_EVASIONS generates all pseudo-legal captures and
; non-captures. Returns a pointer to the end of the move list.

		      align   16
Gen_NonEvasions:
		       push   rsi r12 r13 r14 r15
		      movzx   eax, byte [rbp+Pos.sideToMove]
			mov   r15, qword [rbp+Pos.typeBB+8*rax]
			not   r15
			mov   r14, qword[rbp+Pos.typeBB+8*White]
			 or   r14, qword[rbp+Pos.typeBB+8*Black]
		       test   eax, eax
			jne   Gen_NonEvasions_Black
Gen_NonEvasions_White:
	       generate_all   White, NON_EVASIONS
			pop   r15 r14 r13 r12 rsi
			ret
	       generate_jmp   White, NON_EVASIONS

		      align   16
Gen_NonEvasions_Black:
	       generate_all   Black, NON_EVASIONS
			pop   r15 r14 r13 r12 rsi
			ret
	       generate_jmp   Black, NON_EVASIONS









; generate<QUIET_CHECKS> generates all pseudo-legal non-captures and knight
; underpromotions that give check. Returns a pointer to the end of the move list.


		      align  16
Gen_QuietChecks:
		       push   rsi r12 r13 r14 r15

			mov   r15, qword [rbp+Pos.typeBB+8*White]
			 or   r15, qword [rbp+Pos.typeBB+8*Black]

			mov   r14, qword [rbx+State.dcCandidates]
		       test   r14, r14
			 jz   .PopLoopDone
.PopLoop:
			bsf   r13, r14
		      _blsr   r14, r14, rax
		      movzx   r12d, byte[rbp+Pos.typeBB+r13]
			and   r12d, 7
			jmp   qword [Gen_QuietChecks_JmpTable+8*r12]
.AttacksFromRet:
			shl   r13d, 6
		       test   rsi, rsi
			 jz   .MoveLoopDone
 .MoveLoop:
			bsf   rax, rsi
			 or   eax, r13d
			mov   dword [rdi], eax
			lea   rdi, [rdi+8]
		      _blsr   rsi, rsi, rdx
			jnz   .MoveLoop
 .MoveLoopDone:


.PopSkip:
		       test   r14, r14
			jnz   .PopLoop

.PopLoopDone:
			not   r15
			mov   r14, qword[rbp+Pos.typeBB+8*White]
			 or   r14, qword[rbp+Pos.typeBB+8*Black]
			cmp   byte [rbp+Pos.sideToMove], 0
			jne   Gen_QuietChecks_Black

		      align   8
Gen_QuietChecks_White:
	       generate_all   White, QUIET_CHECKS
			pop   r15 r14 r13 r12 rsi
			ret
	       generate_jmp   White, QUIET_CHECKS

		      align   8
Gen_QuietChecks_Black:
	       generate_all   Black, QUIET_CHECKS
			pop   r15 r14 r13 r12 rsi
			ret
	       generate_jmp   Black, QUIET_CHECKS





Gen_QuietChecks_Jmp:
		      align   8
.AttacksFromKnight:
			mov   rsi, qword [KnightAttacks+8*r13]
		      _andn   rsi, r15, rsi
			jmp   Gen_QuietChecks.AttacksFromRet

		      align   8
.AttacksFromKing:
			mov   rsi, qword [KingAttacks+8*r13]
		      _andn   rsi, r15, rsi
		      movzx   ecx, byte [rbx+State.ksq]
			mov   rax, qword [RookAttacksPDEP+8*rcx]
			 or   rax, qword [BishopAttacksPDEP+8*rcx]
		      _andn   rsi, rax, rsi
			jmp   Gen_QuietChecks.AttacksFromRet

		      align   8
.AttacksFromBishop:
	      BishopAttacks   rsi, r13, r15, rax
		      _andn   rsi, r15, rsi
			jmp   Gen_QuietChecks.AttacksFromRet

		      align   8
.AttacksFromRook:
		RookAttacks   rsi, r13, r15, rax
		      _andn   rsi, r15, rsi
			jmp   Gen_QuietChecks.AttacksFromRet

		      align   8
.AttacksFromQueen:
	      BishopAttacks   rsi, r13, r15, rax
		RookAttacks   rdx, r13, r15, rax
			 or   rsi, rdx
		      _andn   rsi, r15, rsi
			jmp   Gen_QuietChecks.AttacksFromRet












; generate<EVASIONS> generates all pseudo-legal check evasions when the side
; to move is in check. Returns a pointer to the end of the move list.

		      align   16
Gen_Evasions:
		       push   rsi r12 r13 r14 r15
			mov   r13d, dword [rbp+Pos.sideToMove]

; r14 = our king square
			mov   r14, qword [rbp+Pos.typeBB+8*King]
			and   r14, qword [rbp+Pos.typeBB+8*r13]
			bsf   r14, r14

; rsi = their sliding checkers
			mov   rsi, qword [rbp+Pos.typeBB+8*Pawn]
			 or   rsi, qword [rbp+Pos.typeBB+8*Knight]
		      _andn   rsi, rsi, qword [rbx+State.checkersBB]

; r12 = sliderAttacks
			mov   r9, r14
			shl   r9, 6+3
			xor   r12, r12
			bsf   rdx, rsi
			 jz   .SlidersDone
.NextSlider:
		      _blsr   rsi, rsi, r8
			mov   rax, [LineMasks+r9+8*rdx]
			btr   rax, rdx
			 or   r12, rax
			bsf   rdx, rsi
			jnz   .NextSlider
.SlidersDone:

; generate moves for the king to safe squares
			mov   rsi, qword [rbp+Pos.typeBB+8*r13]
		      _andn   rsi, rsi, qword [KingAttacks+8*r14]
		      _andn   r12, r12, rsi
			shl   r14d, 6
			bsf   rax, r12
			 jz   .KingMoveDone
.NextKingMove:
		      _blsr   r12, r12, r8
			 or   eax, r14d
			mov   dword [rdi], eax
			lea   rdi, [rdi+8]
			bsf   rax, r12
			jnz   .NextKingMove
.KingMoveDone:

; if there are multiple checkers, only king moves can be evasions
			mov   rcx, qword [rbx+State.checkersBB]
		      _blsr   rax, rcx
			jnz   Gen_Evasions_White.Ret
			bsf   rax, rcx
			mov   r15, qword[BetweenMasks+r9+8*rax]
			 or   r15, rcx

			mov   r14, qword[rbp+Pos.typeBB+8*White]
			 or   r14, qword[rbp+Pos.typeBB+8*Black]
		       test   r13d,r13d
			jnz   Gen_Evasions_Black
Gen_Evasions_White:
	       generate_all   White, EVASIONS
.Ret:			pop   r15 r14 r13 r12 rsi
			ret
	       generate_jmp   White, EVASIONS

Gen_Evasions_Black:
	       generate_all   Black, EVASIONS
			pop   r15 r14 r13 r12 rsi
			ret
	       generate_jmp   Black, EVASIONS














		      align   16

Gen_Legal:
		       push   rsi r12 r13 r14 r15

; r15  = pinned pieces
; r14d = our king square
; r13d = side
; r11 = our king bitboard

		; generate moves
			mov   rax, qword [rbx+State.checkersBB]
			mov   rsi, rdi
		       test   rax, rax
			jnz   .InCheck
	.NotInCheck:   call   Gen_NonEvasions
			jmp   .GenDone
	.InCheck:      call   Gen_Evasions
	.GenDone:	xor   ecx, ecx
			mov   qword[rdi], rcx
			mov   rdi, rsi

			mov   r15, qword [rbx+State.pinned]
			mov   r13d, dword [rbp+Pos.sideToMove]
			mov   r11, qword [rbp+Pos.typeBB+8*King]
			and   r11, qword [rbp+Pos.typeBB+8*r13]
			bsf   r14, r11

			jmp   .TestNext

		;      align   8


		; remove illegal moves
		      align   16
	.Legal:
			mov   dword [rdi], r12d
			lea   rdi, [rdi+8]

	.Illegal:
	.TestNext:
		; load next move
			mov   eax, dword [rsi]
			lea   rsi, [rsi+8]
			mov   r12d, eax

		; edx = move type
			mov   edx, eax
			shr   edx, 12

		; ecx = source square
			mov   ecx, eax
			shr   ecx, 6
			and   ecx, 63

		; end of list
			and   eax, (64*64)-1
			 jz   .TestDone

		; pseudo legal castling moves are always legal
			cmp   edx, MOVE_TYPE_CASTLE
			 je   .Legal

		; ep captures require special attention
			cmp   edx, MOVE_TYPE_EPCAP
			 je   .EpCapture

		; if we are moving king, have to check destination square
			cmp   ecx, r14d
			 je   .KingMove

		; if piece is not pinned, then move is legal
			 bt   r15, rcx
			jnc   .Legal

		; if something is pinned, its movement should be aligned with our king
		       test   r11, qword[LineMasks+8*rax]
			 jz   .Illegal
			mov   dword [rdi], r12d
			lea   rdi, [rdi+8]
			jmp   .TestNext

		      align   16
.TestDone:
			pop   r15 r14 r13 r12 rsi
			ret

		      align  8
		; if they have an attacker to king's destination square, then move is illegal
.KingMove:
			and   eax, 63
			mov   ecx, r13d
			shl   ecx, 6+3
			mov   rcx, qword [WhitePawnAttacks+rcx+8*rax]

			mov   r9, qword [rbp+Pos.typeBB+8*r13]
			xor   r13d, 1
			mov   r10, qword [rbp+Pos.typeBB+8*r13]
			 or   r9, r10
			xor   r13d, 1
	; pawn
			and   rcx, qword [rbp+Pos.typeBB+8*Pawn]
		       test   rcx, r10
			jnz   .Illegal
	; king
			mov   rdx, qword [KingAttacks+8*rax]
			and   rdx, qword [rbp+Pos.typeBB+8*King]
		       test   rdx, r10
			jnz   .Illegal
	; knight
			mov   rdx, qword [KnightAttacks+8*rax]
			and   rdx, qword [rbp+Pos.typeBB+8*Knight]
		       test   rdx, r10
			jnz   .Illegal
	; bishop + queen
	      BishopAttacks   rdx, rax, r9, r8
			mov   r8, qword [rbp+Pos.typeBB+8*Bishop]
			 or   r8, qword [rbp+Pos.typeBB+8*Queen]
			and   r8, r10
		       test   rdx, r8
			jnz   .Illegal
	; rook + queen
		RookAttacks   rdx, rax, r9, r8
			mov   r8, qword [rbp+Pos.typeBB+8*Rook]
			 or   r8, qword [rbp+Pos.typeBB+8*Queen]
			and   r8, r10
		       test   rdx, r8
			jnz   .Illegal

			mov   dword [rdi], r12d
			lea   rdi, [rdi+8]
			jmp   .TestNext


		      align  8

	; for ep captures, just make the move and test if our king is attacked
.EpCapture:
			xor   r13d, 1
			mov   r10, qword [rbp+Pos.typeBB+8*r13]
			xor   r13d, 1
	; all pieces
			mov   rdx, qword [rbp+Pos.typeBB+8*White]
			 or   rdx, qword [rbp+Pos.typeBB+8*Black]
	; remove source square
			btr   rdx, rcx
	; add destination square (ep square)
			and   eax, 63
			bts   rdx, rax
	; get queens
			mov   r9, qword [rbp+Pos.typeBB+8*Queen]
	; remove captured pawn
			lea   ecx, [2*r13-1]
			lea   ecx, [rax+8*rcx]
			btr   rdx, rcx
	; check for rook attacks
		RookAttacks   rax, r14, rdx, r8
			mov   rcx, qword [rbp+Pos.typeBB+8*Rook]
			 or   rcx, r9
			and   rcx, r10
		       test   rax, rcx
			jnz   .Illegal
	; check for bishop attacks
	      BishopAttacks   rax, r14, rdx, r8
			mov   rcx, qword [rbp+Pos.typeBB+8*Bishop]
			 or   rcx, r9
			and   rcx, r10
		       test   rax, rcx
			jnz   .Illegal
			mov   dword [rdi], r12d
			lea   rdi, [rdi+8]
			jmp   .TestNext










; castling functions


		      align   16
CastleOOLegal_White:
	      CastlingOOJmp   White, .Done
			 or   eax, -1
			ret
		      align   8
 .Done: 		xor   eax, eax
			ret


		      align   16
CastleOOLegal_Black:
	      CastlingOOJmp   Black, .Done
			 or   eax, -1
			ret
		      align   8
 .Done: 		xor   eax, eax
			ret


		      align   16
CastleOOOLegal_White:
	     CastlingOOOJmp   White, .Done
			 or   eax, -1
			ret
		      align   8
 .Done: 		xor   eax, eax
			ret


		      align   16
CastleOOOLegal_Black:
	     CastlingOOOJmp   Black, .Done
			 or   eax, -1
			ret
		      align   8
 .Done: 		xor   eax, eax
			ret

