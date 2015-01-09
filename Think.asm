


_ZN6Search5thinkEv:

virtual at rsp

  .pos	       rb sizeof.Pos
  .stateArray  rb (MAX_PLY+1)*sizeof.State
  .searchStack rb (MAX_PLY+1)*sizeof.Stack

  .lend rb 0
end virtual
.localsize = ((.lend-rsp) and (-16)) +8

		       push   rbp rbx rsi rdi r12 r13 r14 r15

			mov   eax, .localsize
		       call   __chkstk_ms
			sub   rsp, rax

		; start timer
			lea   rcx, [timerThread]	    ; 09E5 _ 48: 8B. 0D, 00000050(rel)
			mov   byte [rcx+TimerThread.run], 1			  ; 09F1 _ C6. 41, 41, 01
		       call   _ZN10ThreadBase10notify_oneEv	      ; 09F5 _ E8, 00000000(rel)

		; copy board to main thread
			lea   rbx, [BoardPosition]
			lea   rbp, [.pos]
			lea   rcx, [.stateArray]
			lea   rdx, [mainThread]
		       call   PositionCopy


		       call   VerifyPositionState
		       test   eax, eax
			 jz   .ProblemAtRoot

		;        lea   rdi, [Output]
		;        mov   rbx, [rbp+Pos.state]
		;       call   PrintPosition
		;       call   _WriteOut_Output


		; setup root moves
			lea   rdi, [MoveList]
			mov   rsi, rdi
			mov   rbx, qword [rbp+Pos.state]
		       call   Gen_Legal
			xor   eax, eax
		      stosq
			lea   rdi, [rootMoves+RootMoves.moves]
			xor   ecx, ecx
		@@:   movzx   eax, word [rsi+EMove.move]
			mov   word [rdi+RMove.move], ax
			mov   word [rdi+RMove.pvIdx], cx
			mov   word [rdi+RMove.score], -VALUE_INFINITE
			mov   word [rdi+RMove.pscore], -VALUE_INFINITE
			add   rsi, sizeof.EMove
			add   ecx, 1
			add   rdi, sizeof.RMove
		       test   eax, eax
			jnz   @b

			sub   ecx, 1
			xor   edx, edx
			mov   eax, dword [uciOptions+UciOptions.multiPv]
			cmp   eax, ecx
		      cmova   eax, ecx
			mov   dword [rootMoves+RootMoves.depth], r15d
			mov   dword [rootMoves+RootMoves.multiPv], eax
			mov   dword [rootMoves+RootMoves.multiPvIdx], edx
			mov   dword [rootMoves+RootMoves.size], ecx
			mov   dword [rootMoves+RootMoves.bestMoveChanges], edx


		; clear portion of search stack and set Pos.ss
			lea   rdi, [.searchStack]
			lea   r14, [rdi+2*sizeof.Stack]
			mov   qword [rbp+Pos.ssTable], rdi
			mov   qword [rbp+Pos.ss], r14
			mov   ecx, 5*sizeof.Stack/8
			xor   eax, eax
		  rep stosq

		; set up pos struct
			xor   eax, eax
			mov   qword [rbp+Pos.nodes], rax

		; set up hash table
			lea   rax, [hashTable]
			and   byte[rax+TT.date], -4
			add   byte[rax+TT.date], 4

		; iterative deepening
			xor   r15d, r15d
  .IdLoop:
			add   r15d, 1
			mov   dword [rootMoves+RootMoves.depth], r15d
			cmp   r15d, MAX_PLY
			jae   .IdLoopDone
			cmp   r15d, dword [Limits.depth]
			 ja   .IdLoopDone


			xor   r13d, r13d
   .PvLoop:
			mov   dword [rootMoves+RootMoves.multiPvIdx], r13d
			mov   ecx, -VALUE_INFINITE
			mov   edx, +VALUE_INFINITE
			mov   r8d, r15d
			mov   r9, r14
			xor   r10, r10
		       call   Search_Root

		; insert pvs back into transposition table
		      movzx   esi, word [rootMoves+RootMoves.moves+0*sizeof.RMove+RMove.pvIdx]
		       imul   esi, 2*(MAX_PLY+1)
			lea   rsi, [rootMoves+RootMoves.pvs+rsi]
			mov   r12, rsi
  .InsertPvDoLoop:
		      movzx   ecx, word [rsi]
		       test   ecx, ecx
			 jz   .InsertPvUndoLoop

		       call   GivesCheck
			mov   edx, eax
		      movzx   ecx, word [rsi]
		       call   DoMove_SetCheckInfo

			add   rsi, 2
			jmp   .InsertPvDoLoop
  .InsertPvUndoLoop:
			sub   rsi, 2
			cmp   rsi, r12
			 jb   .InsertPvDone

		      movzx   ecx, word [rsi]
		       call   UndoMove

			mov   rcx, qword [rbx+State.key]
			mov   r13, rcx
		       call   HashTable_Probe
			mov   rdi, rax
		      movzx   eax, word [rsi+RMove.move]
		       test   edx, edx
			 jz   .SaveMove
			cmp   ax, word [rdi+TTEntry.move]
			 je   .DontSaveMove
    .SaveMove:
			shr   r13, 48
			xor   edx, edx
	     HashTable_Save   rdi, r13w, edx, BOUND_NONE, 0, eax, 0
    .DontSaveMove:
			jmp   .InsertPvUndoLoop
  .InsertPvDone:
			mov   r13d, dword [rootMoves+RootMoves.multiPvIdx]
			add   r13d, 1
		       call   _GetTime
			cmp   r13d, dword [rootMoves+RootMoves.multiPv]
			 je   .Print
			sub   rax, qword[SearchStartTime]
			cmp   rax, 3000
			jbe   .NoPrint
	.Print:
		       call   PrintUciInfo
	.NoPrint:
			cmp   r13d, dword [rootMoves+RootMoves.multiPv]
			 jb   .PvLoop

			mov   r15d, dword [rootMoves+RootMoves.depth]
			cmp   byte [Signals.stop], 0
			 je   .IdLoop
.IdLoopDone:


		; stop timer
			lea   rcx, [timerThread]	    ; 09E5 _ 48: 8B. 0D, 00000050(rel)
			mov   byte [rcx+TimerThread.run], 0			  ; 09F1 _ C6. 41, 41, 01


		; print best move and ponder move
			lea   rdi, [Output]

			mov   rax, 'bestmove'
		      stosq
			mov   al, ' '
		      stosb
		      movzx   ecx, word [rootMoves+RootMoves.moves+0*sizeof.RMove+RMove.move]
		       call   PrintUciMove
			mov   qword [rdi], rax
			add   rdi, rdx

		      movzx   ecx, word [rootMoves+RootMoves.moves+0*sizeof.RMove+RMove.pvIdx]
		       imul   ecx, 2*(MAX_PLY+1)
		      movzx   ecx, word [rootMoves+RootMoves.pvs+rcx+2*1]
		       test   ecx, ecx
			 jz   .NoPonderMove
			mov   rax, ' ponder '
		      stosq
		       call   PrintUciMove
			mov   qword [rdi], rax
			add   rdi, rdx
   .NoPonderMove:
			mov   eax, 10
		      stosb
		       call   _WriteOut_Output


.Return:

			add   rsp, .localsize
			pop   r15 r14 r13 r12 rdi rsi rbx rbp
			ret


.ProblemAtRoot:
			lea   rdi, [Output]
		    stdcall   PrintString, 'problem at root'
			mov   al, 10
		      stosb
		       call   _WriteOut_Output
			jmp   .IdLoopDone




