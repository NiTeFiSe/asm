
;Here are two function for testing movegen
; PerftGen tests the move generating procedure
;   if DEBUG then TestPosition is run in each node
; PerftPick tests the move picking functions

PerftGen_Root:
		       push   rbx rsi rdi r14 r15
virtual at rsp
.time	  dq ?
.movelist rq MAX_MOVES
.lend	   db ?
end virtual
.localsize = .lend-rsp
			sub   rsp, .localsize

			mov   rbx, qword [rbp+Pos.state]
			mov   r15d, ecx
			xor   r14, r14

if DEBUG
			mov   byte [perft_ok], -1
		       call   TestPosition
		       test   eax, eax
			 jz   .TestFailed
end if

		       call   _GetTime
			mov   qword [.time], rax

			lea   rdi, [.movelist]
			mov   rsi, rdi
		       call   Gen_Legal
			xor   eax, eax
			mov   dword [rdi], eax
.MoveLoop:
			mov   ecx, dword [rsi]
		       test   ecx, ecx
			 jz   .MoveLoopDone
			lea   rdi, [Output]
		       call   PrintUciMove
			mov   qword [rdi], rax
			add   rdi, rdx
			mov   eax, ' : '
		      stosd
			sub   rdi, 1
			mov   ecx, dword [rsi]
		       call   GivesCheck
			mov   edx, eax
			mov   ecx, dword [rsi]
		       call   DoMove_SetCheckInfo
			lea   ecx, [r15-1]
		       call   PerftGen_Branch

			add   r14, rax
		       call   PrintUnsignedInteger
			mov   al, 10
		      stosb
			lea   rcx, [Output]
		       call   _WriteOut
			mov   ecx, dword [rsi]
		       call   UndoMove

if DEBUG
			cmp   byte [perft_ok], -1
			jne   .Done
end if

		       test   eax, eax
			 jz   .Error
			add   rsi, 8
			jmp   .MoveLoop
.MoveLoopDone:
		       call   _GetTime
			sub   rax, qword [.time]
			cmp   rax, 1
			adc   rax, 0
			mov   qword [.time], rax

			lea   rdi, [Output]
		    stdcall   PrintString, 'total: '
			mov   rax, r14
		       call   PrintUnsignedInteger
			mov   eax,'  ( '
		      stosd
			mov   rax, qword[.time]
		       call   PrintUnsignedInteger
			mov   rax,' ms  '
		      stosq
			sub   rdi, 3
			mov   eax, 1000
			mul   r14
			div   qword [.time]
		       call   PrintUnsignedInteger
			mov   rax,' nps ) ' + (10 shl 56)
		      stosq
			lea   rcx, [Output]
		       call   _WriteOut
.Done:
			mov   eax, r14d
			add   rsp, .localsize
			pop   r15 r14 rdi rsi rbx
			ret
.Error:
			lea   rdi, [Output]
			mov   al, 10
		      stosb
			mov   rcx, rdx
		       call   PrintString
			lea   rcx, [Output]
		       call   _WriteOut
			jmp   .Done

if DEBUG
.TestFailed:
			xor   r14d, r14d
			jmp   .Done

end if




		      align  16
PerftGen_Branch:
		       push   rbx rdi rsi r14 r15
virtual at rsp
.movelist rq MAX_MOVES
.lend	   db ?
end virtual
.localsize = .lend-rsp
			sub   rsp, .localsize
			mov   r15d, ecx


			xor   r14, r14

if DEBUG
			cmp   byte [perft_ok],-1
			jne   .DepthNDone
		       call   TestPosition
		       test   eax, eax
			 jz   .TestFailed
end if

			lea   rdi, [.movelist]
			mov   rsi, rdi
			lea   eax, [r14+1]
			cmp   r15d, 2
			 je   .Depth2
			sub   r15d, 1
			 jz   .Depth1
			 js   .Depth0


		       call   Gen_Legal
			xor   eax, eax
			mov   dword [rdi], eax
.DepthNLoop:
			mov   ecx, dword[rsi]
		       test   ecx, ecx
			 jz   .DepthNDone
		       call   GivesCheck
			mov   edx, eax
			mov   ecx, dword[rsi]
		       call   DoMove_SetCheckInfo
			mov   ecx, r15d
		       call   PerftGen_Branch
			add   r14, rax
			mov   ecx, dword [rsi]
		       call   UndoMove

if DEBUG
			cmp   byte [perft_ok], -1
			jne   .TestFailed
end if

			add   rsi, 8
			jmp  .DepthNLoop



		      align   8
.Depth2:
			sub   r15, 1
		       call   Gen_Legal
			xor   eax, eax
			mov   dword [rdi], eax
.Depth2Loop:
			mov   ecx, dword[rsi]
		       test   ecx, ecx
			 jz   .DepthNDone
		       call   GivesCheck
			mov   edx, eax
			mov   ecx, dword[rsi]
		       call   DoMove
			mov   ecx, r15d
		       call   PerftGen_Branch
			add   r14, rax
			mov   ecx, dword [rsi]
		       call   UndoMove
if DEBUG
			cmp   byte [perft_ok], -1
			jne   .TestFailed
end if
			add   rsi, 8
			jmp  .Depth2Loop


		      align   8
.Depth1:
		       call   Gen_Legal
			mov   r14, rdi
			sub   r14, rsi
			shr   r14d, 3

		      align   8
.DepthNDone:
			mov   rax, r14
.Depth0:
			add   rsp, .localsize
			pop   r15 r14 rsi rdi rbx
			ret








if DEBUG
.TestFailed:
			mov   byte [perft_ok], 0
			xor   r14, r14
			jmp   .DepthNDone
end if























PerftPick_Root:
		; in rbp address of Pos
		;    ecx depth

virtual at rsp
  .depth	rd 1
		rd 1
  .perftnodes	rq 1
  .movepick	rb sizeof.Pick
  .lend rb 1
end virtual
  .localsize = .lend - rsp

		       push   rbx rsi rdi r12 r13 r14 r15
			sub   rsp, .localsize

			xor   eax, eax
			sub   ecx, 1
			mov   dword [.depth], ecx
			mov   qword [.perftnodes], rax
			lea   rax, [rax+1]
		       test   ecx, ecx
			 js   .Return


			mov   rbx, [rbp+Pos.state]
			lea   rsi, [.movepick]
			mov   word [rsi+Pick.countermoves+2*0], 0
			mov   word [rsi+Pick.countermoves+2*1], 0
			mov   word [rsi+Pick.followupmoves+2*0], 0
			mov   word [rsi+Pick.followupmoves+2*1], 0
			mov   byte [rsi+Pick.recaptureSquare], 64
			xor   ecx, ecx
		       call   MovePick_Init
.GenNext:
		GetNextMove
			mov   r15d, eax
		       test   eax, eax
			 jz   .GenDone

			mov   ecx, eax
		       call   IsMoveLegal
		       test   rax, rax
			 jz   .GenNext

			mov   ecx, r15d
		       call   GivesCheck
			mov   edx, eax
			mov   ecx, r15d
			add   qword [rbp+Pos.nodes], 1
		       call   DoMove_SetCheckInfo

			mov   ecx, dword [.depth]
		       call   PerftPick_Branch
			add   qword [.perftnodes], rax

			mov   ecx, r15d
		       call   UndoMove

			jmp   .GenNext
.GenDone:


			mov   rax, qword[.perftnodes]

.Return:

			add   rsp, .localsize
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret



PerftPick_Branch:
		; in rbp address of Pos
		;    ecx depth

virtual at rsp
  .depth	rd 1
		rd 1
  .perftnodes	rq 1
  .movepick	rb sizeof.Pick
  .lend rb 1
end virtual
  .localsize = .lend - rsp

		       push   rbx rsi rdi r12 r13 r14 r15
			sub   rsp, .localsize

			xor   eax, eax
			sub   ecx, 1
			mov   dword [.depth], ecx
			mov   qword [.perftnodes], rax
			lea   rax, [rax+1]
		       test   ecx, ecx
			 js   .Return


			mov   rbx, [rbp+Pos.state]
			lea   rsi, [.movepick]
			mov   word [rsi+Pick.countermoves+2*0], 0
			mov   word [rsi+Pick.countermoves+2*1], 0
			mov   word [rsi+Pick.followupmoves+2*0], 0
			mov   word [rsi+Pick.followupmoves+2*1], 0
			mov   byte [rsi+Pick.recaptureSquare], 64
			xor   ecx, ecx
		       call   MovePick_Init
.GenNext:
		GetNextMove
			mov   r15d, eax
		       test   eax, eax
			 jz   .GenDone

			mov   ecx, eax
		       call   IsMoveLegal
		       test   rax, rax
			 jz   .GenNext

			mov   ecx, r15d
		       call   GivesCheck
			mov   edx, eax
			mov   ecx, r15d
			add   qword [rbp+Pos.nodes], 1
		       call   DoMove_SetCheckInfo

			mov   ecx, dword [.depth]
		       call   PerftPick
			add   qword [.perftnodes], rax

			mov   ecx, r15d
		       call   UndoMove

			jmp   .GenNext
.GenDone:


			mov   rax, qword[.perftnodes]

.Return:

			add   rsp, .localsize
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret

