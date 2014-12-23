;;;;;;;;;;;;;;;;;;
;  IsMoveLegal   ;
;;;;;;;;;;;;;;;;;;

		      align   16
IsMoveLegal:
		; in: rbp  address of Pos
		;     rbx  address of State - pinned member must be filled in
		;     ecx  move - assumed to pass IsMovePseudoLegal test
		; out: eax =  0 if move is not pseudo legal
		;      eax = -1 if move is pseudo legal

		       push   r13 r14 r15

			mov   r15, qword [rbx+State.pinned]
			mov   r13d, dword [rbp+Pos.sideToMove]
			mov   r11, qword [rbp+Pos.typeBB+8*King]
			and   r11, qword [rbp+Pos.typeBB+8*r13]
			bsf   r14, r11

		; load next move
			mov   eax, ecx
			and   eax, 64*64-1

		; edx = move type
			mov   edx, ecx
			shr   edx, 12

		; ecx = source square
			shr   ecx, 6
			and   ecx, 63

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
			and   r11, qword[LineMasks+8*rax]
			neg   r11
			sbb   eax, eax
			pop   r15 r14 r13
			ret

		      align   8
.Legal:
			 or   eax, -1
			pop   r15 r14 r13
			ret

		      align   8
.Illegal:
			xor   eax, eax
			pop   r15 r14 r13
			ret

		      align   8
.KingMove:
		; if they have an attacker to king's destination square, then move is illegal
			and   eax, 63
			mov   ecx, r13d
			shl   ecx, 6+3
			mov   rcx, qword [PawnAttacks+rcx+8*rax]

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
			 or   eax, -1
			pop   r15 r14 r13
			ret


		      align   8
.EpCapture:
		; for ep captures, just make the move and test if our king is attacked
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
			 or   eax, -1
			pop   r15 r14 r13
			ret