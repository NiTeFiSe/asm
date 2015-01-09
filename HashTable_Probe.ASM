

EmptyTTEntry = VALUE_NONE shl (8*TTEntry.value)


_HashTable_Probe:
		      align   8
.FoundRefresh:
			mov   rcx, qword [rax]
			and   cl, 3
			 or   cl, r11l
			mov   byte [rax+TTEntry.genBound], cl
			 or   edx, -1
			ret


		      align   8
.Found: 		mov   rcx, EmptyTTEntry
			xor   edx, edx
			ret


		      align   16
HashTable_Probe:
	; in:   rcx  key
	; out:  rax  address of entry
	;       rdx  edx == -1 if found
	;            edx == 0  if not found
	;       rcx  entry (8 bytes)
			mov   rax, qword [hashTable+TT.mask]
			and   rax, rcx
			shr   rcx, 48
			add   rax, qword [hashTable+TT.table]
		      movzx   r11d, byte [hashTable+TT.date]

			mov   rdx, qword [rax+8*3]
		       test   dx, dx
			 jz   _HashTable_Probe.Found
			cmp   dx, cx
			 je   _HashTable_Probe.FoundRefresh
			shr   rdx, 16
			add   rax, 8
		       test   dx, dx
			 jz   _HashTable_Probe.Found
			cmp   dx, cx
			 je   _HashTable_Probe.FoundRefresh
			shr   rdx, 16
			add   rax, 8
		       test   dx, dx
			 jz   _HashTable_Probe.Found
			cmp   dx, cx
			 je   _HashTable_Probe.FoundRefresh

		       push   rax rbx
		      movzx   ecx, word [rax-16+8*2]
		      movzx   ebx, word [rax-16+8*1]
		      movzx   eax, word [rax-16+8*0]
			xor   r10d, r10d

			mov   r8d, 1
			mov   edx, ebx
			and   edx, 0x0FC
			xor   r9d, r9d
			cmp   dl, r11l
			 je   @f
			mov   edx, ebx
			and   edx, 3
			cmp   edx, 3
		       sete   r8b
		@@:	mov   edx, eax
			and   edx, 0x0FC
			cmp   dl, r11l
		       sete   r9l
			sub   r8d, r9d
			cmp   bh, ah
		       setl   r9l
			mov   edx, 1
			cmp   r8l, r9l
		      cmovs   eax, ebx
		      cmovs   r10d, edx

			mov   r8d, 1
			mov   edx, ecx
			and   edx, 0x0FC
			xor   r9d, r9d
			cmp   dl, r11l
			 je   @f
			mov   edx, ecx
			and   edx, 3
			cmp   edx, 3
		       sete   r8l
		@@:	mov   edx, eax
			and   edx, 0x0FC
			cmp   dl, r11l
		       sete   r9l
			sub   r8d, r9d
			cmp   ch, ah
		       setl   r9l
			mov   edx, 2
			cmp   r8l, r9l
		      cmovs   r10d, edx

			pop   rbx rax

			mov   rcx, EmptyTTEntry
			xor   edx, edx
			lea   rax, [rax-16+8*r10]
			ret


