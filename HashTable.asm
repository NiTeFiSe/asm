HashTable_Allocate:	; in: ecx = size in MB

	       push   rbx rsi rdi

		lea   rsi, [HashTable]

		mov   edx, 4	 ; minimum 2^4 MB
		mov   ebx, 16	 ; maximum 2^16 MB
		bsr   eax, ecx
	      cmovz   eax, edx
		cmp   eax, ebx
	      cmova   eax, edx
		xor   ebx, ebx
		bts   rbx, rax
		mov   dword[rsi+TT.sizeMB], ebx

		mov   rcx,qword[rsi+TT.mem]
	       call   _VirtualFree

		shl   rbx, 20	; rbx = # of bytes in HashTable
		mov   rcx, rbx
	       call   _VirtualAlloc
		sub   rbx, sizeof.Cluster
		mov   qword[rsi+TT.mem], rax
		mov   qword[rsi+TT.mask], rbx
		mov   byte[rsi+TT.date], 0


		pop   rdi rsi rbx
		ret



HashTable_Clear:
	       push   rdi
		mov   rdi, qword [HashTable+TT.mem]
		mov   ecx, dword [HashTable+TT.sizeMB]
		shl   rcx,20-3
		xor   eax,eax
	  rep stosq
		pop   rdi
		ret


HashTable_Free:
		mov   rcx, qword [HashTable+TT.mem]
		jmp   _VirtualFree

