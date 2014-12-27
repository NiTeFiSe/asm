


		      align   16
UpdateStackPV:
		; ecx: move
		; rdx: address of Stack

			lea   rdx, [rdx+Stack.pv]
			mov   word[rdx], cx
.Next:
		      movzx   eax, word [rdx+sizeof.Stack]
			add   rdx, 2
			mov   word[rdx], ax
		       test   eax, eax
			jnz   .Next

			ret




		      align   16
UpdateStats:
			ret