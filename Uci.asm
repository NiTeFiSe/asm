UciLoop:
		       push   rbp rsi rdi r12 r13 r14 r15

			lea   rsi, [szStartPosition]
			lea   rbp, [BoardPosition]
		       call   ParseFEN

			lea   rdi, [Output]
			lea   rcx, [szGreeting]
		       call   PrintString
			jmp   UciWriteOut

UciQuit:
			lea   rcx, [threadPool]
		       call   _ZN10ThreadPool23wait_for_think_finishedEv

			pop   r15 r14 r13 r12 rdi rsi rbp
			ret


UciWriteOut:
			lea   rcx, [Output]
		       call   _WriteOut
UciGetInput:
			lea   rsi, [Input]
		       call   _ReadIn
			cmp   byte [rsi], ' '
			 jb   UciGetInput

		       call   SkipSpaces

		    stdcall   CmpString, 'uci'
		       test   eax, eax
			jnz   UciUci
		    stdcall   CmpString, 'setoption'
		       test   eax, eax
			jnz   UciSetOption
		    stdcall   CmpString, 'go'
		       test   eax, eax
			jnz   UciGo
		    stdcall   CmpString, 'position'
		       test   eax, eax
			jnz   UciPosition
		    stdcall   CmpString, 'quit'
		       test   eax, eax
			jnz   UciQuit
		    stdcall   CmpString, 'isready'
		       test   eax, eax
			jnz   UciIsReady

		    stdcall   CmpString, 'pick'
		       test   eax, eax
			jnz   UciPick
		    stdcall   CmpString, 'show'
		       test   eax, eax
			jnz   UciShow
		    stdcall   CmpString, 'undo'
		       test   eax, eax
			jnz   UciUndo
		    stdcall   CmpString, 'check'
		       test   eax, eax
			jnz   UciCheck
		    stdcall   CmpString, 'isok'
		       test   eax, eax
			jnz   UciIsOk
		    stdcall   CmpString, 'perftp'
		       test   eax, eax
			jnz   UciPerftP
		    stdcall   CmpString, 'perft'
		       test   eax, eax
			jnz   UciPerft
		    stdcall   CmpString, 'moves'
		       test   eax, eax
			jnz   UciMoves
		    stdcall   CmpString, 'test'
		       test   eax, eax
			jnz   UciTest
		    stdcall   CmpString, 'eval'
		       test   eax, eax
			jnz   UciEval
UciUnknown:
			lea   rdi, [Output]
		    stdcall   PrintString, 'unknown command'
			mov   al, 10
		      stosb
			jmp   UciWriteOut


UciIsReady:
			lea   rdi, [Output]
		    stdcall   PrintString, 'readyok'
			jmp   UciWriteOut


UciPick:
		       call   TestPick
			jmp   UciGetInput



UciGo:
 ;                       cmp   byte [TimerThreadState], TIMER_STATE_TICKING
 ;                       jne   .TimerGoodToGo
 ;                       mov   rcx, qword [TimerThreadEndEvent]
 ;                      call   _SetEvent
 ;.TimerGoodToGo:
			mov   byte [Signals.stop], 0
		       call   ParseGo
			jmp   UciGetInput

UciPerftP:
			xor   eax, eax
			mov   qword [rbp+Pos.nodes], rax
			lea   rax, [SearchStack]
			mov   qword [rbp+Pos.ss], rax

		       call   SkipSpaces
		       call   ParseInteger
			mov   ecx, eax
		       call   PerftPick_Root
			jmp   UciGetInput



UciPerft:
		       call   SkipSpaces
		       call   ParseInteger
			mov   ecx, eax
		       call   PerftGen_Root

  if DEBUG
			cmp   byte [perft_ok], -1
			 je   UciGetInput
			lea   rdi, [Output]
		    stdcall   PrintString, 'failed'
			mov   al, 10
		      stosb
			jmp   UciWriteOut
  else
			jmp   UciGetInput
  end if



UciUci:
			lea   rdi, [Output]
			lea   rcx, [szUCIresponse]
		       call   PrintString
			jmp   UciWriteOut

UciShow:
			lea   rdi, [Output]
		       call   PrintPosition
			jmp   UciWriteOut

UciEval:
		       call   Evaluate
			lea   rdi, [Output]
			mov   ecx, eax
		       call   PrintUciScore
			mov   al, 10
		      stosb
			jmp   UciWriteOut

UciCheck:
			mov   rbx, qword [rbp+Pos.state]
		       call   SetPositionState
			lea   rdi, [Output]
		       call   PrintPosition
			mov   al, 10
		      stosb
			jmp   UciWriteOut

UciIsOk:
			mov   rbx, qword [rbp+Pos.state]
		       call   IsPositionOk
			lea   rdi, [Output]
			mov   rcx, rdx
		       call   PrintString
			jmp   UciWriteOut

UciUndo:
			mov   rbx, qword [rbp+Pos.state]
		       call   SkipSpaces
		       call   ParseInteger
			mov   r15d, eax
			cmp   r15d, 1
			adc   r15d, 0
			sub   r15d, 1
.Undo:
			cmp   rbx, qword [rbp+Pos.stateTable]
			jbe   UciShow
		      movzx   ecx, word [rbx+State.move]
		       call   UndoMove
			sub   r15d, 1
			jns   .Undo
			jmp   UciShow

UciSetOption:
		       call   ParseSetOption
			jmp   UciGetInput
UciMoves:
		       call   ParseMoves
			jmp   UciShow


UciTest:
		       call   TestPosition
		       test   eax, eax
			 jz   UciGetInput
			lea   rdi,[Output]
		    stdcall   PrintString, 'passed'
			mov   al, 10
		      stosb

		    stdcall   PrintString, 'Gen_Captures:   '
			mov   r15, rdi
			mov   rbx, qword [rbp+Pos.state]
			lea   rdi, [MoveList]
		       call   Gen_Captures
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

			jmp   UciWriteOut


UciPosition:
		       call   SkipSpaces
			cmp   byte [rsi], ' '
			 jb   UciUnknown
		    stdcall   CmpString, 'startpos'
		       test   eax, eax
			jnz   .Start
		    stdcall   CmpString, 'fen'
		       test   eax, eax
			jnz   .Fen
			jmp   UciUnknown
.Moves:
		       call   SkipSpaces
		    stdcall   CmpString, 'moves'
		       test   eax, eax
			 jz   UciGetInput
		       call   ParseMoves
			jmp   UciGetInput
.Start:
			mov   r15, rsi
			lea   rsi, [szStartPosition]
			lea   rbp, [BoardPosition]
		       call   ParseFEN
			mov   rsi, r15
			jmp   .Moves
.Fen:
		       call   SkipSpaces
		       call   ParseFEN
			jmp   .Moves


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseMoves:	       push   rbx rsi rdi

.GenMoves:
			lea   rdi, [MoveList]
			mov   rbx, qword [rbp+Pos.state]
		       call   Gen_Legal

.GetMoves:	       call   SkipSpaces
			cmp   byte [rsi], ' '
			 jb   .Done

		      lodsd
		      movzx   edx, byte [rsi]
			cmp   dl, ' '
			jbe   @f
			add   rsi, 1
			shl   rdx, 32
			 or   rax, rdx
		  @@:	mov   r14, rax

			lea   r15, [MoveList]
		  @@:	mov   ecx, dword [r15]
			add   r15, 8
		       test   ecx, ecx
			 jz  .Failed
		       call  PrintUciMove
			cmp  rax, r14
			jne  @b
	   .Found:
			mov   ecx, dword [r15-8]
			mov   word [rbx+State.move+sizeof.State], cx
		       call   GivesCheck
			mov   ecx, dword [r15-8]
		       call   DoMove_SetCheckInfo
			jmp  .GenMoves

.Done:			pop  rdi rsi rbx
			ret

.Failed:		lea  rdi,[szParseError]
		       call  _WriteOut
			lea  rsi,[szStartPosition]
		       call  ParseFEN
			pop  rdi rsi rbx
			ret







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseGo:	       push   rbx

			xor   eax, eax
			mov   ecx, 60000
			mov   qword [MoveTime], rax
			mov   qword [WTime], rcx
			mov   qword [BTime], rcx
			mov   qword [WInc], rax
			mov   qword [BInc], rax
			mov   dword [MovesToGo], 32
			mov   dword [Limits.depth], -1

	 .ReadLoop:
		       call   SkipSpaces
			cmp   byte [rsi], ' '
			 jb   .ReadLoopDone
		    stdcall   CmpString, 'wtime'
		       test   eax, eax
			jnz   .wtime
		    stdcall   CmpString, 'btime'
		       test   eax, eax
			jnz   .btime
		    stdcall   CmpString, 'winc'
		       test   eax, eax
			jnz   .winc
		    stdcall   CmpString, 'binc'
		       test   eax, eax
			jnz   .binc
		    stdcall   CmpString, 'movestogo'
		       test   eax, eax
			jnz   .movestogo
		    stdcall   CmpString, 'ponder'
		       test   eax, eax
			jnz   .ponder
		    stdcall   CmpString, 'movetime'
		       test   eax, eax
			jnz   .movetime
		    stdcall   CmpString, 'depth'
		       test   eax, eax
			jnz   .depth
		    stdcall   CmpString, 'infinite'
		       test   eax, eax
			jnz   .infinite
		       call   SkipToken
			jmp   .ReadLoop
	.ReadLoopDone:

			mov   rax, qword [MoveTime]
		       test   rax, rax
			jnz   .Return

			mov   ecx, dword [rbp+Pos.sideToMove]
		       fild   dword [MovesToGo]
		       fild   qword [WTime+8*rcx]
		       fild   qword [WInc+8*rcx]
		       fld1
		      fsubr   st0, st3
		      fmulp   st1, st0
		      faddp   st1, st0
		     fdivrp   st1, st0
		       push   rax
		      fistp   qword [rsp]
			pop   rax

    .Return:		xor   ecx, ecx
		       test   rax, rax
		      cmovs   rax, rcx
			mov   qword [AlottedTime], rax


			lea   rcx, [threadPool]
		       call   _ZN10ThreadPool14start_thinkingERK

	       ;        call   _GetTime
	       ;         mov   qword [SearchStartTime], rax
	       ;
	       ;         mov   rcx, qword [SearchThreadStartEvent]
	       ;        call   _SetEvent
	       ;         mov   rcx, qword [TimerThreadStartEvent]
	       ;        call   _SetEvent

			pop   rbx
			ret


	.wtime:        call  SkipSpaces
		       call  ParseInteger
			mov  qword [WTime], rax
			jmp  .ReadLoop

	.btime:        call  SkipSpaces
		       call  ParseInteger
			mov  qword [BTime], rax
			jmp  .ReadLoop

	.winc:	       call  SkipSpaces
		       call  ParseInteger
			mov  qword [WInc], rax
			jmp  .ReadLoop

	.binc:	       call  SkipSpaces
		       call  ParseInteger
			mov  qword [BInc], rax
			jmp  .ReadLoop

	.ponder:       call  SkipSpaces
			jmp  .ReadLoop

	.depth:        call  SkipSpaces
		       call  ParseInteger
			mov  dword [Limits.depth], eax
			jmp  .ReadLoop

	.infinite:     call  SkipSpaces
			 or  eax,-1
			mov  qword [MoveTime], rax
			jmp  .ReadLoop

	.movetime:     call  SkipSpaces
		       call  ParseInteger
			mov  qword [MoveTime], rax
			jmp  .ReadLoop

	.movestogo:    call  SkipSpaces
		       call  ParseInteger
			cmp  eax,1
			adc  eax,1
			mov  dword [MovesToGo], eax
			jmp  .ReadLoop
