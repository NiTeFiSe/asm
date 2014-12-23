

SeeSign:
			mov   rax, 0111111111111111111111111111111111b
			mov   r8d, ecx
			shr   r8d, 6
			and   r8d, 63	; r8d = from
			mov   r9d, ecx
			and   r9d, 63	; r9d = to
		      movzx   r10d, byte [rbp+Pos.board+r8]	; r10 = FROM PIECE
		      movzx   r11d, byte [rbp+Pos.board+r9]	; r11 = TO PIECE
			and   r10d, 7
			and   r11d, 7
			lea   r10d, [r10+8*r11]
			 bt   rax, r10
			 jc   See
			mov   eax, VALUE_KNOWN_WIN
			ret