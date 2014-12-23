


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

		      align   8
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

		      align   8
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