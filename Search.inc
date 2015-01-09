

macro search NT, SpNode {

			; rbp: address of Pos
			; ecx: alpha
			; edx: beta
			; r8d: depth
			; r9:  address of Stack
			; r10d: cutNode

virtual at rsp

  .ss	     rq 1
  .tte	     rq 1

  .ttMove	  rd 1
  .ttValue	  rd 1
  .move 	  rd 1
  .excludedMove   rd 1
  .bestMove	  rd 1
  .ext		  rd 1
  .newDepth	  rd 1
  .predictedDepth rd 1
  .moveCount	  rd 1
  .quietCount	  rd 1
  .alpha	  rd 1
  .beta 	  rd 1
  .depth	  rd 1
  .bestValue	  rd 1
  .value	  rd 1
  .eval 	  rd 1
  .nullValue	  rd 1
  .futilityValue  rd 1
		  rd 2

  .inCheck		   rb 1
  .givesCheck		   rb 1
  .singularExtensionNode   rb 1
  .improving		   rb 1
  .captureOrPromotion	   rb 1
  .dangerous		   rb 1
  .doFullDepthSearch	   rb 1
  .cutNode		   rb 1
  .ttHit		   rb 1
			   rb 1
			   rb 1
			   rb 1
			   rb 1
			   rb 1
			   rb 1
			   rb 1

  .movepick	  rb sizeof.Pick
  .quietsSearched rw 64

  .lend rb 0
end virtual
.localsize = .lend-rsp

		       push   rbx rsi rdi r12 r13 r14 r15
			sub   rsp, .localsize


match =_ROOT_NODE, NT
\{
 .PvNode equ 1
 .RootNode equ 1
\}

match =_PV_NODE, NT
\{
 .PvNode equ 1
 .RootNode equ 0
\}

match =_NONPV_NODE, NT
\{
 .PvNode equ 0
 .RootNode equ 0
\}


		; at non root node alpha and beta are calculate in Step 3
	if .RootNode eq 1
			mov   dword [.alpha], ecx
			mov   dword [.beta], edx
	end if
			mov   dword [.depth], r8d
			mov   qword [.ss], r9
			mov   byte [.cutNode], r10l

			mov   rsi, r9
			mov   rbx, [rbp+Pos.state]

			sub   r8d, 1
			mov   dword [.newDepth], r8d


		; Step 1. initialize node
			xor   eax, eax
			mov   dword [.moveCount], eax
			mov   dword [.quietCount], eax
			mov   dword [.bestValue], -VALUE_INFINITE
		      movzx   eax, byte [r9+Stack.ply-1*sizeof.Stack]
			add   eax, 1
			mov   byte [r9+Stack.ply], al

		; used to send seldepth info to gui
	if .PvNode eq 1
		;        mov   r8d, dword [rbp+Pos.maxPly]
		;        cmp   r8d, eax
		;      cmovb   r8d, eax
		;        mov   dword [rbp+Pos.maxPly], r8d
	end if


	if .RootNode eq 0
		; Step 2. check for aborted search and immediate draws
			cmp   byte [rsi+Stack.ply], MAX_PLY
			jae   .AbortSearch_PlyBigger
			cmp   byte [Signals.stop], 0
			jne   .AbortSearch_PlySmaller
		; Step 3. mate distance pruning
			sub   eax, VALUE_MATE
			cmp   ecx, eax
		      cmovl   ecx, eax
			not   eax
			cmp   edx, eax
		      cmovg   edx, eax
			mov   dword [.alpha], ecx
			mov   dword [.beta], edx
			mov   eax, ecx
			cmp   ecx, edx
			jge   .Return
	end if

		; Step 4. transposition table look up
			mov   rcx, qword [rbx+State.key]
		       call   HashTable_Probe
			mov   qword [.tte], rax
			mov   byte [.ttHit], dl
			xor   ecx, ecx
			mov   r8d, VALUE_NONE
		       test   edx, edx
		     cmovnz   cx, word [rax+TTEntry.move]
	      ;       cmovnz   r8w, word [rax+TTEntry.value]
		      movsx   r8d, r8w
			mov   dword [.ttMove], ecx
			mov   word [rsi+Stack.ttMove], cx
			mov   dword [.ttValue], r8d


			xor   eax, eax
			mov   word [rsi+Stack.currentMove], ax

			lea   rsi, [.movepick]
			mov   word [rsi+Pick.countermoves+2*0], 0
			mov   word [rsi+Pick.countermoves+2*1], 0
			mov   word [rsi+Pick.followupmoves+2*0], 0
			mov   word [rsi+Pick.followupmoves+2*1], 0
			mov   byte [rsi+Pick.recaptureSquare], 64
			mov   ecx, dword[.ttMove]
		       call   MovePick_Init_Search


.MovePickLoop:

			lea   rsi, [.movepick]
		GetNextMove
			mov   dword [.move], eax
		       test   eax, eax
			 jz   .MovePickDone


		; at the root search only moves in the move list
	if .RootNode eq 1
			mov   edx, dword [rootMoves+RootMoves.multiPvIdx]
			lea   rdx, [rootMoves+RootMoves.moves+rdx*sizeof.RMove]
		@@:   movzx   ecx, word [rdx+RMove.move]
			lea   rdx, [rdx+sizeof.RMove]
		       test   ecx, ecx
			 jz   .MovePickLoop
			cmp   ecx, eax
			jne   @b

	    if DISPLAY_CURRMOVE
			lea   rdi, [Output]
			mov   rax, 'info cur'
		      stosq
			mov   rax, 'rmove '
		      stosq
			sub   rdi, 2
		       call   _PrintUciMove
			mov   al, 10
		      stosb
		       call   _WriteOut_Output
	    end if
	end if


		; check if move is legal
	if .RootNode eq 0
			mov   ecx, dword [.move]
		       call   IsMoveLegal
		       test   rax, rax
			 jz   .MovePickLoop
	end if
			mov   rax, qword [.ss]
			add   dword [.moveCount], 1
			mov   ecx, dword [.move]
			mov   word [rax+Stack.currentMove], cx
		       call   GivesCheck
			mov   edx, eax
			mov   byte [.givesCheck], al
			mov   ecx, dword [.move]
			add   qword [rbp+Pos.nodes], 1
		       call   DoMove_SetCheckInfo


		; Step 16. full depth search
	if .PvNode eq 1
			cmp   dword [.moveCount], 1
			 je   .DoFullPvSearch
	end if
			xor   r9, r9
			mov   r8d, dword [.newDepth]
			lea   r10, [QSearch_NonPv_InCheck]
			lea   r11, [QSearch_NonPv_NoCheck]
			cmp   byte [.givesCheck], 0
		     cmovne   r11, r10
			lea   rax, [Search_NonPv]
			cmp   r8d, 1
		      cmovl   rax, r11
		      cmovl   r8d, r9d
			mov   edx, dword [.alpha]
			neg   edx
			lea   ecx, [rdx-1]
			mov   r9, qword [.ss]
			add   r9, sizeof.Stack
		      movzx   r10d, byte [.cutNode]
			not   r10l
		       call   rax
			neg   eax
			mov   esi, eax
			mov   dword [.value], eax



	if .PvNode eq 1
			cmp   esi, dword [.alpha]
			jle   .SkipFullPvSearch
	    if .RootNode eq 0
			cmp   esi, dword [.beta]
			jge   .SkipFullPvSearch
	    end if
 .DoFullPvSearch:
			xor   r9, r9
			mov   r8d, dword [.newDepth]
			lea   r10, [QSearch_Pv_InCheck]
			lea   r11, [QSearch_Pv_NoCheck]
			cmp   byte [.givesCheck], 0
		     cmovne   r11, r10
			lea   rax, [Search_Pv]
			cmp   r8d, 1
		      cmovl   rax, r11
		      cmovl   r8d, r9d
			mov   ecx, dword [.beta]
			neg   ecx
			mov   edx, dword [.alpha]
			neg   edx
			mov   r9, qword [.ss]
			add   r9, sizeof.Stack
			mov   dword[r9+Stack.pv], 0
			xor   r10d, r10d
		       call   rax
			neg   eax
			mov   esi, eax
			mov   dword [.value], eax
 .SkipFullPvSearch:
	end if


		; Step 17. Undo move
			mov   ecx, dword [.move]
		       call   UndoMove

			mov   ecx, dword [.move]

			xor   eax, eax
			cmp   al, byte [Signals.stop]
			jne   .Return


		; for the root, check for new best move
	if .RootNode eq 1
		; find the move in the root move list
			lea   r8, [rootMoves+RootMoves.moves-sizeof.RMove]
.FindRootMove:
			lea   r8, [r8+sizeof.RMove]
		      movzx   eax, word [r8+RMove.move]
		     assert   ne, eax, 0, 'could not find root move'
			cmp   eax, ecx
			jne   .FindRootMove
		; update root move
			mov   word [r8+RMove.score], si
			cmp   dword [.moveCount], 1
			 je   .FoundRootMoveMoveCount1
			cmp   esi, dword [.alpha]
			 jg   .FoundRootMoveNewBestMove
.FoundRootMoveRet:

	end if


		; check for new best move
			cmp   esi, dword [.bestValue]
			jle   .NoNewBestValue
			mov   dword [.bestValue], esi
			cmp   esi, dword [.alpha]
			jle   .NoNewAlpha

			mov   dword [.bestMove], ecx
	if .PvNode eq 1
			mov   rdx, qword [.ss]
			lea   rdx, [rdx+Stack.pv]
			mov   word[rdx], cx
		@@:   movzx   eax, word [rdx+sizeof.Stack]
			add   rdx, 2
			mov   word[rdx], ax
		       test   eax, eax
			jnz   @b
	end if


	if .PvNode eq 1
			cmp   esi, dword [.beta]
			jge   .MovePickDone
			mov   dword [.alpha], esi
	else
		     assert   ge, esi, dword [.beta], 'did not fail high'
			jmp   .MovePickDone
	end if

.NoNewAlpha:
.NoNewBestValue:

			jmp   .MovePickLoop

.MovePickDone:
		      ;  mov   rbx, qword [rbp+Pos.state]
			mov   rax, qword [rbx+State.checkersBB]
			mov   r15d, dword [.bestValue]
			cmp   dword [.moveCount], 0
			 je   .Mate
			cmp   r15d, dword [.beta]
			 jg   .CheckQuietBestMove

.TTStore:

			mov   eax, r15d

.Return:

			add   rsp, .localsize
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret



		      align   8
.CheckQuietBestMove:
			mov   ecx, dword [.bestMove]
			mov   edx, ecx
			shr   ecx, 12
			and   edx, 63
		       test   rax, rax
			jnz   .TTStore
			cmp   ecx, MOVE_TYPE_EPCAP
			jae   .TTStore
			cmp   byte [rbp+Pos.board+rdx], 0
			jne   .TTStore
		       call  UpdateStats
			jmp   .TTStore


		      align   8
.Mate:
		      movzx   ecx, byte [rbp+Pos.sideToMove]
			neg   rax
			sbb   r15d, r15d
		      _andn   edx, r15d, dword [DrawValue+4*rcx]
			mov   rcx, qword [.ss]
		      movzx   ecx, byte[rcx+Stack.ply]
			sub   ecx, VALUE_MATE
			and   r15d, ecx
			 or   r15d, edx
			jmp   .TTStore


	if .RootNode eq 1
		      align   8
.FoundRootMoveNewBestMove:
			add   dword [rootMoves+RootMoves.bestMoveChanges], 1
.FoundRootMoveMoveCount1:
		; copy pv
		      movzx   r9d, word [r8+RMove.pvIdx]
		       imul   r9d, 2*(MAX_PLY+1)
			lea   r9, [rootMoves+RootMoves.pvs+r9]
			mov   rdx, qword[.ss]
			lea   rdx, [rdx+Stack.pv+1*sizeof.Stack]
			mov   r10d, esi
			mov   word [r9], cx
		@@:	add   r9, 2
		      movzx   eax, word [rdx]
			add   rdx, 2
			mov   word [r9], ax
		       test   eax, eax
			jnz   @b
		; move new best move to front of move list
			mov   r9d, dword [rootMoves+RootMoves.multiPvIdx]
			lea   r9, [rootMoves+RootMoves.moves+r9*sizeof.RMove]
			mov   rax, qword [r8]
			mov   rdx, qword [r9]
			mov   qword [r8], rdx
			mov   qword [r9], rax
			jmp   .FoundRootMoveRet
	end if


	if .RootNode eq 0
		      align  8
.AbortSearch_PlyBigger:
			mov   eax, dword [rbp+Pos.sideToMove]
			mov   eax, dword [DrawValue+4*rax]
			cmp   qword [rbx+State.checkersBB], 0
			 je   .Return
		       call   Evaluate
			jmp   .Return

		      align   8
.AbortSearch_PlySmaller:
			mov   eax, dword [rbp+Pos.sideToMove]
			mov   eax, dword [DrawValue+4*rax]
			jmp   .Return
	end if


}









