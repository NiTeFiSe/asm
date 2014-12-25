


		      align   16
UpdateStackPV:
		; ecx: move
		; rdx: address of Stack

			lea   rdx, [rdx+Stack.pv]
			mov   word[rdx], cx

.Next:
		      movzx   eax, word [rdx+sizeof.Stack]
		       test   eax, eax
			 jz   .Return
			add   rdx, 2
			mov   word[rdx], ax
			jmp   .Next

.Return:
			ret




		      align   16
UpdateStats:
			ret