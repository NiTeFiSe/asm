align 16
tt_.text.hot:
tt__ZNK18TranspositionTable5probeEy:
	mov	r8, qword [rcx] 			
	xor	eax, eax				
	sub	r8, 1					
	and	r8, rdx 				
	shr	rdx, 48 				
	shl	r8, 5					
	add	r8, qword [rcx+8H]			
	cmp	word [r8+18H], dx			
	jnz	tt_008					 
tt_006:  lea	 rax, [r8+rax*8]			 
	movzx	edx, byte [rax] 			
	and	edx, 03H				
	or	edx, dword [rcx+18H]			
	mov	byte [rax], dl				
tt_007:  ret						 
tt_008:  
	cmp	word [r8+1AH], dx			
	mov	al, 1					
	jz	tt_006					 
	xor	al, al					
	cmp	word [r8+1CH], dx			
	jnz	tt_007					 
	mov	al, 2					
	jmp	tt_006					 
	nop						

	align	16
tt__ZNK18TranspositionTable5probeEyP7TTEntry:
	mov	rax, qword [rcx]			
	sub	rax, 1					
	and	rax, rdx				
	shr	rdx, 48 				
	shl	rax, 5					
	add	rax, qword [rcx+8H]
	mov	r9, qword [rax+18H]

	cmp	r9w, dx
	je	tt_009
	add	rax, 8
	shr	r9, 16
	cmp	r9w, dx
	je	tt_009
	add	rax, 8
	shr	r9, 16
	cmp	r9w, dx
	je	tt_009
	xor	eax, eax				
	ret

	align	8
tt_009:
	mov	rdx, qword [rax]
	mov	qword [r8], rdx
	and	edx, 03H
	or	dl, byte [rcx+18H]
	mov	byte [rax], dl
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
