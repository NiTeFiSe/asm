	      align   16
ProbeHashTable: 	; in:  rcx  key
			; out: rax  address of entry
			;      rdx  entry data
		mov   rax, qword [HashTable+TT.mask]
		and   rax, rcx
		shr   rcx, 48
		shl   rax, 5
		add   rax, qword [HashTable+TT.mem]
		mov   rdx, qword [rax+24]

		cmp   dx, cx
		 je   .found
		add   rax, 8
		shr   rdx, 16
		cmp   dx, cx
		 je   .found
		add   rax, 8
		shr   rdx, 16
		cmp   dx, cx
		 je   .found
		xor   eax, eax
		ret
.found:
		mov   ecx, 3
		mov   rdx, qword [rax]
		and   ecx, edx
		 or   cl, byte [HashTable+TT.date]
		mov   byte [rax], cl
		ret

ALIGN	16
tt__ZN18TranspositionTable5storeEy5Value5Bound5Depth4MoveS0_:
	push	r15					
	push	r14					
	push	r13					
	push	r12					
	push	rbp					
	push	rdi					
	push	rsi					
	push	rbx					
	sub	rsp, 40 				
	mov	rax, qword [rcx]			
	sub	rax, 1					
	and	rax, rdx				
	shr	rdx, 48 				
	shl	rax, 5					
	add	rax, qword [rcx+8H]			
	mov	r10, qword [rax+18H]

	movzx	edi, byte [rsp+90H]
	or	r9b, byte [rcx+18H]
	movzx	ebp, word [rsp+0A0H]
	shl	edi,8*1
	or	r9d,edi
	mov	ebx, dword [rsp+98H]
	shl	ebx,8*2
	or	r9d,ebx
	movzx	r8d,r8w
	shl	r8,8*4
	or	r9,r8
	shl	rbp,8*6
	or	r9,rbp

	xor	r15d, r15d
	test	r10w, r10w
	je	tt_022
	cmp	r10w, dx
	je	tt_017

	mov	r15d, 1
	shr	r10,16
	test	r10w, r10w
	je	tt_022
	cmp	r10w, dx
	je	tt_017

	mov	r15d, 2
	shr	r10,16
	test	r10w, r10w
	je	tt_022
	cmp	r10w, dx
	je	tt_017

	mov	r8,rax
	mov	r10d,edx
	movzx	r11d,byte[rcx+18H]

	movzx	eax,word[r8+8*0]
	movzx	ebx,word[r8+8*1]
	movzx	ecx,word[r8+8*2]
	xor	r15d,r15d

	mov	r12d,1
	mov	edx,ebx
	and	edx,0x0FC
	cmp	dl,r11l
	je	@f
	mov	edx,ebx
	and	edx,3
	cmp	edx,3
	sete	r12b
@@:	xor	r13d,r13d
	mov	edx,eax
	and	edx,0x0FC
	cmp	edx,r11d
	sete	r13b
	sub	r12d,r13d
	xor	r13d,r13d
	cmp	bh,ah
	setl	r13b
	mov	edx,1
	sub	r12d,r13d
	cmovs	eax,ebx
	cmovs	r15d,edx

	mov	r12d,1
	mov	edx,ecx
	and	edx,0x0FC
	cmp	dl,r11l
	je	@f
	mov	edx,ecx
	and	edx,3
	cmp	edx,3
	sete	r12b
@@:	xor	r13d,r13d
	mov	edx,eax
	and	edx,0x0FC
	cmp	edx,r11d
	sete	r13b
	sub	r12d,r13d
	xor	r13d,r13d
	cmp	ch,ah
	setl	r13b
	mov	edx,2
	sub	r12d,r13d
      cmovs	r15d,edx

	mov	word [r8+2*r15+18H], r10w
	mov	qword[r8+8*r15], r9
tt_015:
	add	rsp, 40
	pop	rbx					
	pop	rsi					
	pop	rdi					
	pop	rbp					
	pop	r12					
	pop	r13					
	pop	r14					
	pop	r15					
	ret

	align	16
tt_022:
	mov	word [rax+r15*2+18H], dx
tt_017:

	test	ebx, ebx
	jnz	@f
	movzx	ebx, word [rax+r15*8+2H]
	shl	ebx,8*2
	or	r9,rbx
    @@:
	mov	qword [rax+8*r15], r9
	jmp	tt_015
