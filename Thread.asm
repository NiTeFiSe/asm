CopyPositionToThread:

		; in: rbp address of destination Pos
		;     rbx address of source Pos

		       push   rsi rdi

		; copy typeBB and board
			lea   rsi, [rbx+Pos.typeBB]
			lea   rdi, [rbp+Pos.typeBB]
			mov   ecx, 128/8
		  rep movsq

		; copy gamePly and sideToMove
			mov   rax, qword [rbx+Pos.gamePly]
			mov   qword [rbp+Pos.gamePly], rax

		; copy relevent State elements
			mov   rcx, [rbx+Pos.state]
			mov   esi, 99
		      movzx   eax, [rcx+State.rule50]
			cmp   esi, eax
		      cmova   esi, eax
		      movzx   eax, [rcx+State.pliesFromNull]
			cmp   esi, eax
		      cmova   esi, eax

		       imul   esi, sizeof.State
			mov   rdi, qword [rbp+Pos.stateTable]
			lea   rax, [rdi+rsi]
			mov   qword [rbp+Pos.state], rax
			lea   ecx, [rsi+sizeof.State]
			neg   rsi
			add   rsi, qword [rbx+Pos.state]
			shr   ecx, 3
		  rep movsq

			pop   rdi rsi
			ret




SearchThread:
			and   rsp, -32

		; put the Pos structure on the stack
			sub   rsp, sizeof.Pos
			mov   rbp, rsp

		; allocate space for search stack
			mov   ecx, (MAX_PLY+4)*sizeof.Stack
		       call   _VirtualAlloc
			mov   qword [rbp+Pos.ssTable], rax

		; allocate space for states
			mov   ecx, (MAX_PLY+100)*sizeof.State
		       call   _VirtualAlloc
			mov   qword [rbp+Pos.stateTable], rax

		; allocate space for pawn hash
			mov   ecx, 1024
		       call   _VirtualAlloc
			mov   qword [rbp+Pos.pawnsTable], rax

		; allocate space for material hash
			mov   ecx, 1024
		       call   _VirtualAlloc
			mov   qword [rbp+Pos.materialTable], rax


.WaitForWork:
			mov  byte [SearchThreadState],THREAD_STATE_WAIT

			mov   rcx, [SearchThreadStartEvent]
			 or   edx, -1
		       call   _WaitEvent

			mov  byte[SearchThreadState],THREAD_STATE_SEARCH

			jmp  .Search


		      align   8
.Search:


			lea   rbx, [BoardPosition]
		       call   CopyPositionToThread

			xor   r15d, r15d

		; clear portion of search stack and set Pos.ss
			mov   rdi, qword [rbp+Pos.ssTable]
			lea   r14, [rdi+2*sizeof.Stack]
			mov   qword [rbp+Pos.ss], r14
			mov   ecx, sizeof.Stack/8
			xor   eax, eax
		  rep stosq

		;



       .IdLoop:
			add   r15d, 1

			mov   ecx, -VALUE_INFINITE
			mov   edx, +VALUE_INFINITE
			mov   r8d, r15d
			mov   r9, r14
			xor   r10, r10
		       call   Search_Root

		       call   PrintUciInfo

			cmp   byte [Signals.stop], 0
			 je   .IdLoop


			lea  rdi, [Output]

			mov  rax, 'bestmove'
		      stosq
			mov  al, ' '
		      stosb
		      movzx  ecx, word [BestMove]
		       call  PrintUciMove
			mov  qword [rdi], rax
			add  rdi, rdx

			mov  rax, ' ponder '
		      stosq
		      movzx  ecx, word [PonderMove]
		       call  PrintUciMove
			mov  qword [rdi], rax
			add  rdi, rdx

			mov  eax,10
		      stosb
			lea  rcx,[Output]
		       call  _WriteOut

			jmp  .WaitForWork