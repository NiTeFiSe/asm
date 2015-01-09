TestPosition:
		       push   rbx rsi rdi r12 r13 r14 r15

virtual at rsp
.movelist rq 128
.lend db ?
end virtual
.localsize = .lend-rsp
			sub   rsp, .localsize

			mov   rbx, qword [rbp+Pos.state]
		       call   SetCheckInfo

			lea   rdi, [.movelist]
			mov   rsi, rdi
		       call   Gen_Legal
			xor   eax, eax
			mov   dword[rdi], eax
			jmp   .MoveTest
	.MoveLoop:
			mov   ecx, dword [rsi]
		       call   IsMovePseudoLegal
		       test   rax, rax
			 jz   .LegalFail1
			mov   ecx, dword [rsi]
		       call   IsMoveLegal
		       test   rax, rax
			 jz   .LegalFail2
			add   rsi, 8
	.MoveTest:
			mov   ecx, dword [rsi]
		       test   ecx, ecx
			jnz   .MoveLoop

			mov   r15d, 300
.RandomLoop:
		       call   GetRand
			shr   eax, 1
			mov   esi, eax
			 jz   .RandomLoop
			lea   rcx, [.movelist]
			jmp   .WhileTest
 .WhileLoop:
			cmp   eax, esi
			 je   .RandomLoop
			add   rcx, 8
 .WhileTest:
			mov   eax, dword[rcx]
		       test   eax, eax
			jnz   .WhileLoop
			mov   ecx, esi
		       call   IsMovePseudoLegal
		       test   rax, rax
			jnz   .RandomFail1

.RandomFail1Ret:
			sub   r15d, 1
			jns   .RandomLoop

			 or   eax, -1
.Return:
			add   rsp, .localsize
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret

.ReturnFail:
			mov   al, 10
		      stosb
		       call   PrintPosition
			lea   rcx, [Output]
		       call   _WriteOut
			xor   eax, eax
			jmp   .Return

.LegalFail1:
			lea   rdi,[Output]
			mov   ecx, dword [rsi]
		       call   PrintLongMove
		    stdcall   PrintString, ' failed IsMovePsuedoLegal'
			jmp   .ReturnFail

.LegalFail2:
			lea   rdi,[Output]
			mov   ecx, dword [rsi]
		       call   PrintLongMove
		    stdcall   PrintString, ' failed IsMoveLegal'
			jmp   .ReturnFail


.RandomFail1:
			mov   ecx, esi
		       call   IsMoveLegal
		       test   rax, rax
			jnz   .RandomFail2

			jmp   .RandomFail1Ret

	   ;             lea   rdi,[Output]
	   ;             mov   ecx, esi
	   ;            call   PrintLongMove
	   ;         stdcall   PrintString, ' passed IsMovePsuedoLegal'
	   ;             jmp   .ReturnFail

.RandomFail2:
			lea   rdi,[Output]
			mov   ecx, esi
		       call   PrintLongMove
		    stdcall   PrintString, ' passed IsMoveLegal'
			jmp   .ReturnFail





SetPositionState:

		; in: rbp  address of Pos

		       push   rbx rsi rdi r12 r13 r14 r15
			sub   rsp, 64
			mov   rbx, qword [rbp+Pos.state]

			mov   rax, Zobrist_Side
			mov   r15d, dword [rbp+Pos.sideToMove]
		      movzx   ecx, byte [rbx+State.epSquare]
		      movzx   edx, byte [rbx+State.castlingRights]
			neg   r15
			and   r15, Zobrist_Side
			xor   r15, qword [Zobrist_Castling+8*rdx]
			cmp   ecx, 64
			jae   @f
			and   ecx, 7
			xor   r15, qword [Zobrist_Ep+8*rcx]
			@@:

			xor   r14, r14
			xor   r13, r13

		      _pxor   xmm0, xmm0, xmm0	; npMaterial
		    _movdqa   dqword [rsp], xmm0

			xor   esi, esi
	.NextSquare:
		      movzx   eax, byte [rbp+Pos.board+rsi]
			mov   edx, eax
			and   edx, 7	; edx = piece type
			 jz   .Empty

		       imul   ecx, eax, 64*8
		      _movq   xmm1, qword [Scores_Pieces+rcx+8*rsi]
		     _paddw   xmm0, xmm0, xmm1

			xor   r15, qword [Zobrist_Pieces+rcx+8*rsi]
			cmp   edx, Pawn
			jne   @f
			xor   r14, qword [Zobrist_Pieces+rcx+8*rsi]
		 @@:
		      movzx   edx, byte [rsp+rax]
			xor   r13, qword [Zobrist_Pieces+rcx+8*rdx]
			add   edx, 1
			mov   byte [rsp+rax], dl
	.Empty:
			add   esi, 1
			cmp   esi, 64
			 jb   .NextSquare

			mov   qword [rbx+State.key], r15
			mov   qword [rbx+State.pawnKey], r14
			mov   qword [rbx+State.materialKey], r13
		      _movq   qword [rbx+State.psq], xmm0

			mov   ecx, dword [rbp+Pos.sideToMove]
			mov   rdx, qword [rbp+Pos.typeBB+8*King]
			and   rdx, qword [rbp+Pos.typeBB+8*rcx]
			bsf   rdx, rdx
		       call   AttackersTo_Side
			mov   qword [rbx+State.checkersBB], rax

		       call   SetCheckInfo

			add   rsp, 64
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret



VerifyPositionState:

		; in: rbp  address of Pos

		       push   rbx rsi rdi r12 r13 r14 r15
			sub   rsp, 64
			mov   rbx, qword [rbp+Pos.state]

			mov   rax, Zobrist_Side
			mov   r15d, dword [rbp+Pos.sideToMove]
		      movzx   ecx, byte [rbx+State.epSquare]
		      movzx   edx, byte [rbx+State.castlingRights]
			neg   r15
			and   r15, Zobrist_Side
			xor   r15, qword [Zobrist_Castling+8*rdx]
			cmp   ecx, 64
			jae   @f
			and   ecx, 7
			xor   r15, qword [Zobrist_Ep+8*rcx]
			@@:

			xor   r14, r14
			xor   r13, r13

		      _pxor   xmm0, xmm0, xmm0	; npMaterial
		    _movdqa   dqword [rsp], xmm0

			xor   esi, esi
	.NextSquare:
		      movzx   eax, byte [rbp+Pos.board+rsi]
			mov   edx, eax
			and   edx, 7	; edx = piece type
			 jz   .Empty

		       imul   ecx, eax, 64*8
		      _movq   xmm1, qword [Scores_Pieces+rcx+8*rsi]
		     _paddw   xmm0, xmm0, xmm1

			xor   r15, qword [Zobrist_Pieces+rcx+8*rsi]
			cmp   edx, Pawn
			jne   @f
			xor   r14, qword [Zobrist_Pieces+rcx+8*rsi]
		 @@:
		      movzx   edx, byte [rsp+rax]
			xor   r13, qword [Zobrist_Pieces+rcx+8*rdx]
			add   edx, 1
			mov   byte [rsp+rax], dl
	.Empty:
			add   esi, 1
			cmp   esi, 64
			 jb   .NextSquare

			cmp   qword [rbx+State.key], r15
			jne   .Failed
			cmp   qword [rbx+State.pawnKey], r14
			jne   .Failed
			cmp   qword [rbx+State.materialKey], r13
			jne   .Failed
		      _movq   rax, xmm0
			cmp   qword [rbx+State.psq], rax
			jne   .Failed

			mov   ecx, dword [rbp+Pos.sideToMove]
			mov   rdx, qword [rbp+Pos.typeBB+8*King]
			and   rdx, qword [rbp+Pos.typeBB+8*rcx]
			bsf   rdx, rdx
		       call   AttackersTo_Side
			cmp   qword [rbx+State.checkersBB], rax
			jne   .Failed

			 or   eax,-1
			add   rsp, 64
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret

.Failed:
			xor   eax, eax
			add   rsp, 64
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret




IsPositionOk:		; in: rbp position (POS)
			; out: eax =  0 if position is illegal
			;      eax = -1 if position is legal

		       push   rbx rdi
			mov   rbx, qword [rbp+Pos.state]


  .VerifyKings:
			lea   rdi,[szErrorKings]
			mov   rax, qword [rbp+Pos.typeBB+8*White]
			and   rax, qword [rbp+Pos.typeBB+8*King]
		    _popcnt   rax, rax,r8
			cmp   eax, 1
			jne   .Failed
			mov   rax, qword [rbp+Pos.typeBB+8*Black]
			and   rax, qword [rbp+Pos.typeBB+8*King]
		    _popcnt   rax, rax, r8
			cmp   eax, 1
			jne   .Failed

  .VerifyPawns:
			lea   rdi,[szErrorPawns]
			mov   rax, 0xFF000000000000FF
		       test   rax, qword [rbp+Pos.typeBB+8*Pawn]
			jnz   .Failed

  .VerifyPieces:
			lea   rdi,[szErrorPieces]
			mov   rcx, qword [rbp+Pos.typeBB+8*White]
			mov   r9, rcx
			and   rcx, qword [rbp+Pos.typeBB+8*King]
		    _popcnt   rdx, r9, r8
      irps p, Pawn Knight Bishop Rook Queen {
			mov   rax, qword [rbp+Pos.typeBB+8*p]
			and   rax, r9
			 or   rcx, rax
		    _popcnt   rax, rax, r8
			sub   edx, eax
      }
			sub   edx, 1
			jnz   .Failed
			cmp   rcx, r9
			jne   .Failed

			mov   rcx, qword [rbp+Pos.typeBB+8*Black]
			mov   r9, rcx
			and   rcx, qword [rbp+Pos.typeBB+8*King]
		    _popcnt   rdx, r9, r8
      irps p, Pawn Knight Bishop Rook Queen {
			mov   rax, qword [rbp+Pos.typeBB+8*p]
			and   rax, r9
			 or   rcx, rax
		    _popcnt   rax, rax, r8
			sub   edx, eax
      }
			sub   edx, 1
			jnz   .Failed
			cmp   rcx, r9
			jne   .Failed



  .VerifyWhiteOO:
			lea   rdi,[szErrorCastling]
			mov   rcx, qword [rbp+Pos.typeBB+8*White]
			and   rcx, qword [rbp+Pos.typeBB+8*King]
			mov   rdx, qword [rbp+Pos.typeBB+8*White]
			and   rdx, qword [rbp+Pos.typeBB+8*Rook]
		       test   byte [rbx+State.castlingRights], 1
			 jz   .VerifyWhiteOOO
			 bt   rcx, SQ_E1
			jnc   .Failed
			 bt   rdx, SQ_H1
			jnc   .Failed

  .VerifyWhiteOOO:     test   byte [rbx+State.castlingRights], 2
			 jz   .VerifyBlackOO
			 bt   rcx, SQ_E1
			jnc   .Failed
			 bt   rdx, SQ_A1
			jnc   .Failed

  .VerifyBlackOO:	mov   rcx, qword [rbp+Pos.typeBB+8*Black]
			and   rcx, qword [rbp+Pos.typeBB+8*King]
			mov   rdx, qword [rbp+Pos.typeBB+8*Black]
			and   rdx, qword [rbp+Pos.typeBB+8*Rook]
		       test   byte[rbx+State.castlingRights], 4
			 jz   .VerifyBlackOOO
			 bt   rcx, SQ_E8
			jnc   .Failed
			 bt   rdx, SQ_H8
			jnc   .Failed

  .VerifyBlackOOO:     test   byte [rbx+State.castlingRights], 8
			 jz   .VerifyCastlingDone
			 bt   rcx, SQ_E8
			jnc   .Failed
			 bt   rdx, SQ_A8
			jnc   .Failed

  .VerifyCastlingDone:
			lea   rdi, [szErrorBoardMatch]
			xor   edx, edx
    .VerifyBoard:
		      movzx   eax, byte [rbp+Pos.board+rdx]
		       test   eax, eax
			 jz   @f
			cmp   eax, 16
			jae   .Failed
			mov   ecx, eax
			and   eax, 7
			 jz   .Failed
			cmp   eax, 1
			 je   .Failed
			and   ecx, 8
			mov   r8, [rbp+Pos.typeBB+8*rax]
			and   r8, [rbp+Pos.typeBB+rcx]
			 bt   r8, rdx
			jnc   .Failed
		@@:	add   edx, 1
			cmp   edx, 64
			 jb   .VerifyBoard

 .VerifyEp:
			lea   rdi, [szErrorEpSquare]
		      movzx   ecx, byte [rbx+State.epSquare]
			cmp   ecx, 64
			jae   .VerifyEpDone
			mov   rax, Rank3BB+Rank6BB
			 bt   rax, rcx
			jnc  .Failed
		    ; make sure square behind ep square is empty
		      movzx   eax, byte [rbp+Pos.sideToMove]
			xor   eax, 1
			mov   rdx, qword [rbp+Pos.typeBB+8*rax]
			shl   eax, 4
			lea   eax, [rax+rcx-8]
			 bt   qword [rbp+Pos.typeBB+8*Black], rax
			 jc   .Failed
			 bt   qword [rbp+Pos.typeBB+8*White], rax
			 jc   .Failed
		    ; and square in front is occupied by one of their pawns
		      movzx   eax, byte [rbp+Pos.sideToMove]
			and   rdx, qword [rbp+Pos.typeBB+8*Pawn]
			shl   eax, 4
			lea   eax, [rax+rcx-8]
			 bt   rdx, rax
			jnc   .Failed
		    ; and opposing pawn can capture eqsquare
		      movzx   eax, byte [rbp+Pos.sideToMove]
			mov   rdx, qword[rbp+Pos.typeBB+8*rax]
			and   rdx, qword [rbp+Pos.typeBB+8*Pawn]
			xor   eax, 1
			shl   eax, 6+3
		       test   rdx, qword [WhitePawnAttacks+rax+8*rcx]
			 jz   .Failed
  .VerifyEpDone:

 .VerifyKingCapture:
		    ; make sure we can't capture their king
			lea   rdi, [szErrorKingCapture]
		      movzx   ecx, byte [rbp+Pos.sideToMove]
			xor   ecx, 1
			mov   rdx, qword [rbp+Pos.typeBB+8*King]
			and   rdx, qword [rbp+Pos.typeBB+8*rcx]
			bsf   rdx, rdx
		       call   AttackersTo_Side
		       test   rax, rax
			jnz   .Failed

.Done:
			lea   rdx, [szOK]
			 or   eax, -1
			pop   rdi rbx
			ret
.Failed:
			mov  rdx, rdi
			xor  eax, eax
			pop  rdi rbx
			ret



;;;;;;;;;;;;;; fen ;;;;;;;;;;;;;;;;;;

PrintPosition:	; in: rbp address of Pos
		; io: rdi string

		       push   rbx rsi r13 r14 r15
			mov   rbx, [rbp+Pos.state]

			xor   ecx, ecx
		@@:	xor   ecx, 0111000b
		      movzx   eax, byte [rbp+Pos.board+rcx]
			mov   edx, '  ' + (10 shl 16)
			mov   dl, byte [PieceToChar+rax]
			mov   eax, '* ' + (10 shl 16)
			cmp   cl, byte [rbx+State.epSquare]
		     cmovne   eax, edx
		      stosd
			xor   ecx, 0111000b
			lea   eax, [rcx+1]
			and   eax, 7
			neg   eax
			sbb   rdi, 1
			add   ecx, 1
			cmp   ecx, 64
			 jb   @b

		    stdcall   PrintString,'isok:           '
		       call   IsPositionOk
			mov   rcx, rdx
		       call   PrintString

		    stdcall   PrintString,'sideToMove:     '
			mov   eax, dword [rbp+Pos.sideToMove]
			sub   eax, 1
			and   eax, 'w' - 'b'
			add   eax, 'b'
			mov   ah, 10
		      stosw

		    stdcall   PrintString,'castlingRights: '
		      movzx   ecx, byte[rbx+State.castlingRights]
			mov   byte [rdi], 'K'
			shr   ecx, 1
			adc   rdi, 0
			mov   byte [rdi], 'Q'
			shr   ecx, 1
			adc   rdi, 0
			mov   byte [rdi], 'k'
			shr   ecx, 1
			adc   rdi, 0
			mov   byte [rdi], 'q'
			shr   ecx, 1
			adc   rdi, 0
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'epSquare:       '
		      movzx   ecx, byte [rbx+State.epSquare]
		       call   PrintSquare
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'rule50:         '
		      movzx   rax, byte [rbx+State.rule50]
		       call   PrintUnsignedInteger
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'pliesFromNull:  '
		      movzx   rax, byte [rbx+State.pliesFromNull]
		       call   PrintUnsignedInteger
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'capturedPiece:  '
		      movzx   eax, byte [rbx+State.capturedPiece]
			mov   al, byte [PieceToChar+rax]
		      stosb
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'key:            '
		       movq   xmm0, qword[rbx+State.key]
		       call   PrintHex64
		     movdqu   dqword[rdi], xmm1
			add   rdi, 16
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'pawnKey:        '
		       movq   xmm0, qword[rbx+State.pawnKey]
		       call   PrintHex64
		     movdqu   dqword[rdi], xmm1
			add   rdi, 16
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'materialKey:    '
		       movq   xmm0, qword[rbx+State.materialKey]
		       call   PrintHex64
		     movdqu   dqword[rdi], xmm1
			add   rdi, 16
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'psq:            '
			mov   eax, 'mg: '
		      stosd
		      movsx   rax, word[rbx+State.psq+2*0]
		       call   PrintSignedInteger
			mov   ax, '  '
		      stosw
			mov   eax, 'eg: '
		      stosd
		      movsx   rax, word[rbx+State.psq+2*1]
		       call   PrintSignedInteger
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'npMaterial:     '
			mov   eax,'w: '
		      stosd
			sub  rdi, 1
		      movsx  rax, word[rbx+State.npMaterial+2*0]
		       call   PrintSignedInteger
			mov   eax, ' b: '
		      stosb
		      stosd
		      movsx  rax, word[rbx+State.npMaterial+2*1]
		       call   PrintSignedInteger
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'checkersBB:     '
			mov   rsi, qword[rbx+State.checkersBB]
		@@:    test   rsi, rsi
			 jz   @f
			bsf   rcx, rsi
		      _blsr   rsi, rsi, rax
		       call   PrintSquare
			mov   al, ' '
		      stosb
			jmp  @b
		@@:	mov   al, 10
		      stosb

		       ; jmp   .MoveListDone
		    stdcall   PrintString, 'Gen_Legal:      '
			mov   r15, rdi
			mov   rbx, qword [rbp+Pos.state]
			lea   rdi, [MoveList]
		       call   Gen_Legal
			mov   qword [rdi], 0
			mov   rdi, r15
			lea   rsi, [MoveList]
			xor   r14d, r14d
.MoveList:
		      lodsq
			mov   ecx, eax
		       test   eax, eax
			 jz   .MoveListDone
		       call   PrintUciMove
			mov   qword [rdi], rax
			add   rdi, rdx
			add   r14d, 1
			and   r14d, 7
			 jz   .MoveListNL
			mov   al, ' '
		      stosb
			jmp   .MoveList
.MoveListNL:
			mov   al, 10
		      stosb
			mov   rax,'        '
		      stosq
		      stosq
			jmp   .MoveList
.MoveListDone:
			mov   al, 10
		      stosb



			pop   r15 r14 r13 rsi rbx
			ret





ParseFEN:
		; in: rsi address of fen string
		;     rbp address of Pos

		       push   rbx rdi r15


			xor   eax, eax
			mov   ecx, (sizeof.Pos/8)
			mov   rdi, rbp
		  rep stosq

			lea   rbx, [StateList]
			mov   qword [rbp+Pos.state], rbx
			mov   qword [rbp+Pos.stateTable], rbx

			xor   eax, eax
			mov   ecx, (sizeof.State/8)
			mov   rdi, rbx
		  rep stosq


		       call  SkipSpaces

			xor  eax,eax
			xor  ecx,ecx
			jmp  .ExpectPiece

.ExpectPieceOrSlash:
		       test   ecx,7
			jnz   .ExpectPiece
		      lodsb
			cmp   al, '/'
			jne   .Failed
	.ExpectPiece:
		      lodsb

			mov   edx, 8*White+Pawn
			cmp   al, 'P'
			 je   .FoundPiece
			mov   edx, 8*White+Knight
			cmp   al, 'N'
			 je   .FoundPiece
			mov   edx, 8*White+Bishop
			cmp   al, 'B'
			 je   .FoundPiece
			mov   edx, 8*White+Rook
			cmp   al, 'R'
			 je   .FoundPiece
			mov   edx, 8*White+Queen
			cmp   al, 'Q'
			 je   .FoundPiece
			mov   edx, 8*White+King
			cmp   al, 'K'
			 je   .FoundPiece

			mov   edx, 8*Black+Pawn
			cmp   al, 'p'
			 je   .FoundPiece
			mov   edx, 8*Black+Knight
			cmp   al, 'n'
			 je   .FoundPiece
			mov   edx, 8*Black+Bishop
			cmp   al, 'b'
			 je   .FoundPiece
			mov   edx, 8*Black+Rook
			cmp   al, 'r'
			 je   .FoundPiece
			mov   edx, 8*Black+Queen
			cmp   al, 'q'
			 je   .FoundPiece
			mov   edx, 8*Black+King
			cmp   al, 'k'
			 je   .FoundPiece

			sub   eax, '0'
			 js   .Failed
			cmp   eax, 8
			 ja   .Failed
	.Spaces:
			add   ecx, eax
			jmp   .PieceDone

	.FoundPiece:
			xor   ecx, 0111000b
			mov   edi, edx
			and   edi, 7
			bts   qword[rbp+Pos.typeBB+8*rdi], rcx
			mov   edi, edx
			shr   edi, 3
			bts   qword[rbp+Pos.typeBB+8*rdi], rcx
			mov   byte[rbp+Pos.board+rcx], dl
			xor   ecx, 0111000b
			add   ecx, 1
	.PieceDone:
			cmp   ecx, 64
			 jb   .ExpectPieceOrSlash

	.Turn:
		       call   SkipSpaces
		      lodsb
			xor   ecx, ecx
			cmp   al, 'b'
		       sete   cl
			mov   dword[rbp+Pos.sideToMove], ecx

	.Castling:
		       call   SkipSpaces
		      lodsb
			cmp   al, '-'
			 je   .EpSquare
			cmp   al, 'K'
			jne   @f
			 or   byte[rbx+State.castlingRights], 1
		      lodsb
		@@:	cmp   al, 'Q'
			jne   @f
			 or   byte[rbx+State.castlingRights], 2
		      lodsb
		@@:	cmp   al, 'k'
			jne   @f
			 or   byte[rbx+State.castlingRights], 4
		      lodsb
		@@:	cmp   al, 'q'
			jne   @f
			 or   byte[rbx+State.castlingRights], 8
		@@:

	.EpSquare:
		       call   SkipSpaces
		       call   ParseSquare
			mov   byte [rbx+State.epSquare], al
			cmp   eax, 64
			jae   .FiftyMoves

			mov   rdx, qword [rbp+Pos.typeBB+8*Pawn]
			mov   ecx, dword [rbp+Pos.sideToMove]
			and   rdx, qword [rbp+Pos.typeBB+8*rcx]
			xor   ecx, 1
			shl   ecx, 6+3
		       test   rdx, qword [WhitePawnAttacks+rcx+8*rax]
			jnz   .FiftyMoves
			mov   byte [rbx+State.epSquare], 64

	.FiftyMoves:
		       call   SkipSpaces
		       call   ParseInteger
			mov   byte [rbx+State.rule50], al

	.MoveNumber:
		       call   SkipSpaces
		       call   ParseInteger
			mov   dword [rbp+Pos.gamePly], eax
			sub   eax, 1
			adc   eax, 0
			shl   eax, 1
			add   eax, dword[rbp+Pos.sideToMove]

		;       call   VerifyPosition
		;       test   eax,eax
		;         jz  .Failed

			call  SetPositionState

			 or   eax, -1
			pop   r15 rdi rbx
			ret

	.Failed:
			xor   eax, eax
			pop   r15 rdi rbx
			ret


PrintFen:



