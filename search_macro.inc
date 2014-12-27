ROOT_NODE  = 0
PV_NODE    = 1
NONPV_NODE = 2


macro search NT, SpNode {

			; rbp: address of Pos
			; ecx: alpha
			; edx: beta
			; r8d: depth
			; r9:  address of Stack
			; r10d: cutNode

virtual at rsp


  .ttMove	 rd 1
  .move 	 rd 1
  .excludedMove  rd 1
  .bestMove	 rd 1

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
  .ttValue	  rd 1
  .eval 	  rd 1
  .nullValue	  rd 1
  .futilityValue  rd 1

		  rd 2

  .ss	  rq 1

  .inCheck		   rb 1
  .givesCheck		   rb 1
  .singularExtensionNode   rb 1
  .improving		   rb 1
  .captureOrPromotion	   rb 1
  .dangerous		   rb 1
  .doFullDepthSearch	   rb 1
  .cutNode		   rb 1

  .movepick	rb sizeof.Pick
  .quietsSearched rw 64

  .lend rb 0
end virtual

.localsize = .lend-rsp
		       push   rbx rsi rdi r12 r13 r14 r15
			sub   rsp, .localsize


match =ROOT_NODE, NT
\{
 PvNode equ 1
\}

match =PV_NODE, NT
\{
 PvNode equ 1
\}

match =NONPV_NODE, NT
\{
 PvNode equ 0
\}



			mov   dword [.alpha], ecx
			mov   dword [.beta], edx
			mov   dword [.depth], r8d
			mov   qword [.ss], r9
			mov   byte [.cutNode], r10l

			sub   r8d, 1
			mov   dword [.newDepth], r8d


			mov   rsi, qword[.ss]
			xor   eax, eax
			mov   word [rsi+Stack.currentMove], ax
			mov   dword [.moveCount], eax
			mov   dword [.quietCount], eax
			mov   dword [.bestValue], -VALUE_INFINITE
		      movzx   ecx, byte [rsi+Stack.ply-1*sizeof.Stack]
			add   ecx, 1
			mov   byte [rsi+Stack.ply],cl

			mov   rbx, [rbp+Pos.state]
			lea   rsi, [.movepick]
			mov   word [rsi+Pick.countermoves+2*0], 0
			mov   word [rsi+Pick.countermoves+2*1], 0
			mov   word [rsi+Pick.followupmoves+2*0], 0
			mov   word [rsi+Pick.followupmoves+2*1], 0
			mov   byte [rsi+Pick.recaptureSquare], 64
			xor   ecx, ecx
		       call   MovePick_Init


.MovePickLoop:
			lea   rsi, [.movepick]
		GetNextMove
			mov   dword [.move], eax
		       test   eax, eax
			 jz   .MovePickDone

	if NT in <ROOT_NODE, PV_NODE>
			mov   rax, qword [.ss]
			mov   dword[rax+Stack.pv+1*sizeof.Stack], 0
	end if

		; check if move is legal
	if NT in <PV_NODE, NONPV_NODE>
			mov   ecx, dword [.move]
		       call   IsMoveLegal
		       test   rax, rax
			 jz   .MovePickLoop
	end if

			add   dword [.moveCount], 1

			mov   ecx, dword [.move]
		       call   GivesCheck
			mov   edx, eax
			mov   ecx, dword [.move]
			add   qword [rbp+Pos.nodes], 1
		       call   DoMove_SetCheckInfo

			lea   r11, [QSearch]
	if NT in <ROOT_NODE, PV_NODE>
			lea   rax, [Search_PV]
	else
			lea   rax, [Search_NonPV]
	end if
			cmp   dword [.newDepth], 1
		      cmovl   rax, r11
			mov   ecx, dword [.beta]
			neg   ecx
			mov   edx, dword [.alpha]
			neg   edx
			mov   r8d, dword [.newDepth]
			mov   r9, qword [.ss]
			add   r9, sizeof.Stack
			xor   r10, r10
		       call   rax
			neg   eax
			mov   esi, eax
			mov   dword [.value], eax

			mov   ecx, dword [.move]
		       call   UndoMove

			cmp   esi, dword [.bestValue]
			jle   .NoNewBestValue
			mov   dword [.bestValue], esi
			cmp   esi, dword [.alpha]
			jle   .NoNewAlpha

			mov   ecx, dword [.move]
			mov   dword [.bestMove], ecx
	if PvNode eq 1
			mov   rdx, qword [.ss]
		       call   UpdateStackPV
	end if


	if PvNode eq 1
			cmp   esi, dword [.beta]
			jge   .MovePickDone
			mov   dword [.alpha], esi
	else
		  assert_ge   esi, dword [.beta], 'did not fail high'
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


}