



		      align   16
Evaluate:
		       push   rbx
			mov   rbx, qword [rbp+Pos.state]
		      movsx   eax, word [rbx+State.psq+2*0]
			pop   rbx
			ret