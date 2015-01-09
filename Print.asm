PrintUciScore:

			cmp   ecx, +VALUE_MATE-MAX_PLY
			jge   .pMate
			cmp   ecx, -VALUE_MATE+MAX_PLY
			jle   .nMate

			mov   eax, 'cp '
		      stosd
			sub   rdi, 1
		       test   ecx, ecx
			jns   @f
			mov   al, '-'
			neg   ecx
		      stosb
		@@:	mov   eax, ecx
			mov   rdx, (100*(1 shl 32))/PAWN_VALUE_MG
			mul   rdx
			shr   rax, 32
		       call   PrintUnsignedInteger
			ret

.pMate:
			mov   rax, 'mate '
		      stosq
			sub   rdi, 3
			mov   eax, VALUE_MATE+1
			sub   eax, ecx
			shr   eax, 1
		       call   PrintUnsignedInteger
			ret

.nMate:
			mov   rax, 'mate -'
		      stosq
			sub   rdi, 2
			mov   eax, VALUE_MATE
			add   eax, ecx
			shr   eax, 1
		       call   PrintUnsignedInteger
			ret



PrintUciInfo:

		       push   rbx rdi rsi r12 r13 r14 r15

			lea   rdi, [Output]

		       call   _GetTime
			mov   rbx, rax

			xor   r13, r13
.MultiPvLoop:

			cmp   r13d, dword [rootMoves+RootMoves.multiPvIdx]
			 ja   .Continue


			mov   rax, 'info dep'
		      stosq
			mov   eax, 'th '
		      stosd
			sub   rdi, 1
			mov   eax, dword [rootMoves+RootMoves.depth]
		       call   PrintUnsignedInteger


			mov   rax, ' time '
		      stosq
			sub   rdi, 2
			mov   rax, rbx
			sub   rax, qword [SearchStartTime]
			mov   r15, rax
			cmp   rax, 1
			adc   r15, 0
		       call   PrintUnsignedInteger

			mov   rax, ' score '
		      stosq
			sub   rdi, 1
		      movsx   ecx, word [rootMoves+RootMoves.moves+r13*sizeof.RMove+RMove.score]
		       call   PrintUciScore

			mov   rax, ' nodes '
		      stosq
			sub   rdi, 1
			mov   rax, qword [rbp+Pos.nodes]
		       call   PrintUnsignedInteger

			mov   rax, ' nps '
		      stosq
			sub   rdi, 3
			mov   eax, 1000
			mul   qword [rbp+Pos.nodes]
			div   r15
		       call   PrintUnsignedInteger

			mov   al, ' '
		      stosb
			mov   rax, 'multipv '
		      stosq
			lea   eax, [r13+1]
		       call   PrintUnsignedInteger

			mov   eax, ' pv'
		      stosd
			sub   rdi, 1
		      movzx   esi, word [rootMoves+RootMoves.moves+r13*sizeof.RMove+RMove.pvIdx]
		       imul   esi, 2*(MAX_PLY+1)
			lea   rsi, [rootMoves+RootMoves.pvs+rsi]
		      movzx   ecx, word [rsi]
		@@:	add   rsi, 2
			mov   al,' '
		      stosb
		       call   PrintUciMove
			mov   qword [rdi], rax
			add   rdi, rdx
		      movzx   ecx, word [rsi]
		       test   ecx, ecx
			jnz   @b

			mov   al, 10
		      stosb

.Continue:
			add   r13d, 1
			cmp   r13d, dword [rootMoves+RootMoves.multiPv]
			 jb   .MultiPvLoop

		       call   _WriteOut_Output

			pop   r15 r14 r13 r12 rsi rdi rbx
			ret




PrintUciMove:
		; in:  ecx  move
		; out: rax  move string
		;      edx  byte length of move string  4 or 5 for promotions

			mov   eax, 'NULL'
		       test   ecx, (1 shl 12)-1
			 jz   .Return

			xor   eax, eax
			mov   edx, ecx
			and   edx, 7
			add   edx, 'a'
			shl   edx, 16
			 or   eax, edx

			mov   edx, ecx
			shr   edx, 3
			and   edx, 7
			add   edx, '1'
			shl   edx, 24
			 or   eax, edx

			mov   edx, ecx
			shr   edx, 6
			and   edx, 7
			add   edx, 'a'
			 or   eax, edx

			mov   edx, ecx
			shr   edx, 6+3
			and   edx, 7
			add   edx, '1'
			shl   edx, 8
			 or   eax, edx

			mov   edx, ecx
			shr   edx, 12
			cmp   edx, MOVE_TYPE_PROM+4
			jae   .Return
			cmp   edx,MOVE_TYPE_PROM
			jae   .Promotion
	.Return:
			mov   edx,4
			ret

	.Promotion:
			and   edx, 3
		      movzx   edx, byte [@f+rdx]
			shl   rdx, 32
			 or   rax, rdx
			mov   edx, 5
			ret

	@@: db 'nbrq'


_PrintUciMove:
		       call   PrintUciMove
			mov   qword [rdi], rax
			add   rdi, rdx
			ret




