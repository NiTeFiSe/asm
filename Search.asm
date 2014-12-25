


		     align   16
Search_Root:
		    search   ROOT_NODE



		     align   16
Search_PV:
		    search   PV_NODE


		     align   16
Search_NonPV:
		    search   NONPV_NODE




Search:
		; in rbp address of Pos
		;    ecx depth

virtual at rsp
  .depth	rd 1
  .move 	rd 1
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
			 js   .QSearch


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
			mov   dword [.move], eax
		       test   eax, eax
			 jz   .GenDone

			mov   ecx, eax
		       call   IsMoveLegal
		       test   rax, rax
			 jz   .GenNext

			mov   ecx, dword [.move]
		       call   GivesCheck
			mov   edx, eax
			mov   ecx, dword [.move]
			add   qword [rbp+Pos.nodes], 1
		       call   DoMove_SetCheckInfo

			mov   ecx, dword [.depth]
		       call   PerftPick_Branch
			add   qword [.perftnodes], rax

			mov   ecx, dword [.move]
		       call   UndoMove

			jmp   .GenNext
.GenDone:



			mov   rax, qword[.perftnodes]

.Return:

			add   rsp, .localsize
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret

.QSearch:
			mov   rbx, qword [rbp+Pos.state]
		       call   Evaluate
			add   rsp, .localsize
			pop   r15 r14 r13 r12 rdi rsi rbx
			ret
