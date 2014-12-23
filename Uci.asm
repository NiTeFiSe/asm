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
		    stdcall   CmpString, 'position'
		       test   eax, eax
			jnz   UciPosition
		    stdcall   CmpString, 'quit'
		       test   eax, eax
			jnz   UciQuit
UciUnknown:
			lea   rdi, [Output]
		    stdcall   PrintString, 'unknown command'
			mov   al, 10
		      stosb
			lea   rcx, [Output]
		       call   _WriteOut
			jmp   UciGetInput

UciPick:
		       call   TestPick
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
			cmp   rbx, qword [rbp+Pos.startState]
			jbe   UciShow
		      movzx   ecx, word [rbx+State.move]
		       call   UndoMove
			sub   r15d, 1
			jns   .Undo
			jmp   UciShow

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


ParseOptions:
		       int3


