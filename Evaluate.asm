



		      align   16
Evaluate:
		       push   rbx
			mov   rbx, qword [rbp+Pos.state]
		      movsx   eax, word [rbx+State.psq+2*0]
			mov   ecx, dword [rbp+Pos.sideToMove]
			neg   ecx
			xor   eax, ecx
			sub   eax, ecx

			pop   rbx
			ret