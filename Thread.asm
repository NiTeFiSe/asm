CopyPositionToThread:

			ret




SearchThread:
			and  rsp,-32

		; put the Pos structure on the stack
			sub  rsp, sizeof.Pos
			mov  rbp, rsp

		; allocate space for array of Stack structures
			mov   ecx, (MAX_PLY+4)*sizeof.Stack
		       call   _VirtualAlloc
			mov   qword [rbp+Pos.ssBase], rax

		; allocate space for array of State structures
			mov   ecx, (MAX_PLY+100)*sizeof.State
		       call   _VirtualAlloc
			mov   qword [rbp+Pos.stateBase], rax



.WaitForWork:
			mov  byte [SearchThreadState],THREAD_STATE_WAIT

			mov   rcx, [SearchThreadStartEvent]
			 or   edx, -1
		       call   _WaitEvent

			mov  byte[SearchThreadState],THREAD_STATE_SEARCH

			jmp  .Search


.Search:



		@@:
		     invoke  __imp_Sleep,20
			cmp   byte [Signals.stop], 0
			 je   @b


			lea  rdi,[Output]

			mov  rax,'bestmove'
		      stosq
			mov  al,' '
		      stosb
		      movzx  ecx,word[BestMove]
		       call  PrintUciMove
			mov  qword[rdi],rax
			add  rdi,rdx

			mov  rax,' ponder '
		      stosq
		      movzx  ecx,word[PonderMove]
		       call  PrintUciMove
			mov  qword[rdi],rax
			add  rdi,rdx

			mov  eax,10
		      stosb
			lea  rcx,[Output]
		       call  _WriteOut

			jmp  .WaitForWork