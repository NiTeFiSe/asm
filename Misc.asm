

Rand64:
	       call   GetRand
		mov   ecx, eax
	       call   GetRand
		shl   eax, 16
		 or   ecx, eax
	       call   GetRand
		shl   rax, 32
		 or   rcx, rax
	       call   GetRand
		shl   rax, 48
		 or   rax, rcx
		ret





GetRand:      ; get 16 random bits in ax
		     movdqa  xmm0,dqword[RandSeed]
		     movdqa  xmm1,xmm0
		     movdqa  xmm2,xmm0
		     pslldq  xmm1,1
		     psrldq  xmm2,15
			por  xmm1,xmm2
		     movdqa  xmm2,xmm0
		      psllq  xmm2,1
			por  xmm1,xmm2
		     movdqa  xmm2,xmm0
		     movdqa  xmm3,xmm0
		     psrldq  xmm2,1
		     pslldq  xmm3,15
			por  xmm2,xmm3
		     movdqa  xmm3,xmm0
		      psrlq  xmm3,1
		       pxor  xmm2,xmm3
			por  xmm0,xmm1
		       pxor  xmm0,xmm2
		   pmovmskb  eax,xmm0
		      paddq  xmm0,dqword[RandInc]
		     movdqa  dqword[RandSeed],xmm0
			ret




AppendNoWhiteSpace:
		 @@:  lodsb
		      stosb
			cmp  al,' '
			 ja  @b
			sub  rdi,1
			ret


Append:
		 @@:  lodsb
		      stosb
			cmp  al,0
			jne  @b
			sub  rdi,1
			ret

AppendNewLine:
		 @@:  lodsb
		      stosb
			cmp  al,0
			jne  @b
			mov  byte[rdi-1],10
			ret


PrintString:
.Next:		      movzx  eax,byte[rcx]
			lea  rcx,[rcx+1]
			cmp  al,0
			 je  .Done
		      stosb
			jmp  .Next
.Done:			ret


CmpString:	   ; if beginning of string at rsi matches null terminated string at rcx
		   ;    then advance rsi to end of match and return non zero,
		   ;    else return zero and do nothing
		       push  rsi
.Next:		      movzx  eax,byte[rcx]
			lea  rcx,[rcx+1]
			cmp  al,0
			 je  .Found
			cmp  al,byte[rsi]
			lea  rsi,[rsi+1]
			 je  .Next
.NoMatch:		pop  rsi
			xor  eax,eax
			ret
.Found: 		pop  rax
			 or  eax,-1
			ret


CmpStringCaseLess:
		   ; if beginning of string at rsi matches null terminated string at rcx
		   ;    then advance rsi to end of match and return non zero,
		   ;    else return zero and do nothing
		       push  rsi
.Next:		      movzx  eax,byte[rcx]
			mov  edx,eax
			cmp  eax,64
			 jb  @f
			cmp  eax,128
			jae  @f
		      movzx  edx,byte[.SwitchCase+rax-64]
		@@:	lea  rcx,[rcx+1]
			cmp  al,0
			 je  .Found
			cmp  al,byte[rsi]
			lea  rsi,[rsi+1]
			 je  .Next
			cmp  dl,byte[rsi-1]
			 je  .Next

.NoMatch:		pop  rsi
			xor  eax,eax
			ret
.Found: 		pop  rax
			 or  eax,-1
			ret

.SwitchCase:	db '@abcdefghijklmnopqrstuvwxyz[\]^_'
		db '`ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~',127




		@@:	add  rsi,1
SkipSpaces:	; skip spaces of string at rsi
			cmp  byte[rsi],' '
			 je @b
			ret




		@@:	add  rsi,1
SkipToken:   ; skip characters of string at rsi
		      movzx  eax,byte[rsi]
			 bt  [.TokenCharacters],rax
			 jc @b
			ret
 .TokenCharacters:  dd 00000000000000000000000000000000b
		    dd 00000011111111110000000000000000b
		    dd 00000111111111111111111111111110b
		    dd 00000111111111111111111111111110b




PrintLongMove:

		       push   rcx
		       call   PrintUciMove
			mov   qword [rdi], rax
			add   rdi, rdx
			mov   al, ' '
		      stosb
			pop   rax
			shr   eax,12
		       call   PrintUnsignedInteger
			ret



PrintUciInfo:
		;
		       push   rdi rsi

			lea   rdi, [Output]

			mov   rax, 'time '
		      stosq
			sub   rdi, 3
		       call   _GetTime
			sub   rax, qword [SearchStartTime]
		       call   PrintUnsignedInteger
			mov   al,' '
		      stosb

			mov   ax, 'pv'
		      stosw

			mov   rsi, qword [rbp+Pos.ss]
			lea   rsi, [rsi+Stack.pv]

		      movzx   ecx, word [rsi]
  .NextMove:
			add   rsi, 2
			mov   al,' '
		      stosb
		       call   PrintUciMove
			mov   qword [rdi], rax
			add   rdi, rdx

		      movzx   ecx, word [rsi]
		       test   ecx, ecx
			jnz   .NextMove

			mov   al, 10
		      stosb
			lea   rcx, [Output]
		       call   _WriteOut

			pop   rsi rdi
			ret

PrintUciMove:
		; in:  ecx  move
		; out: rax  move string
		;      edx  byte length of move string  4 or 5 for promotions

			mov  eax,'NULL'
		       test  ecx,(1 shl 12)-1
			 jz  .Return

			xor  eax,eax
			mov  edx,ecx
			and  edx,7
			add  edx,'a'
			shl  edx,16
			 or  eax,edx

			mov  edx,ecx
			shr  edx,3
			and  edx,7
			add  edx,'1'
			shl  edx,24
			 or  eax,edx

			mov  edx,ecx
			shr  edx,6
			and  edx,7
			add  edx,'a'
			 or  eax,edx

			mov  edx,ecx
			shr  edx,6+3
			and  edx,7
			add  edx,'1'
			shl  edx,8
			 or  eax,edx

			mov  edx,ecx
			shr  edx,12
			cmp  edx,MOVE_TYPE_PROM+4
			jae  .Return
			cmp  edx,MOVE_TYPE_PROM
			jae  .Promotion
	.Return:
			mov  edx,4
			ret

	.Promotion:
			and  edx,3
		      movzx  edx,byte[@f+rdx]
			shl  rdx,32
			 or  rax,rdx
			mov  edx,5
			ret

	@@: db 'nbrq'



;;;;;;;;;;;; bitboard ;;;;;;;;;;;;;;;;;;;

PrintBitBoard:	 ; in: rcx bitboard
		 ; io: rdi string
			xor  edx,edx
       .NextBit:	 bt  rcx,rdx
			sbb  eax,eax
			add  edx,1
			and  eax,'X'-'.'
			add  eax,'. ' + (10 shl 16)
		      stosd
			mov  eax,edx
			and  eax,7
			neg  eax
			sbb  rdi,1
			cmp  edx,64
			 jb  .NextBit
			ret



;;;;;;;;;;;;; square ;;;;;;;;;;;;;;;;

PrintSquare:
		cmp   ecx, 64
		jae   .none
		mov   eax, ecx
		and   eax, 7
		add   eax, 'a'
	      stosb
		mov   eax, ecx
		shr   eax, 3
		add   eax, '1'
	      stosb
		ret

.none:
		mov  al,'-'
	      stosb
		ret

ParseSquare:
		xor   eax, eax
	      lodsb
		mov   ecx, eax
		sub   ecx, 'a'
		 js   .none
		cmp   ecx, 8
		jae   .none

		xor   eax, eax
	      lodsb
		sub   eax, '1'
		 js   .none
		cmp   eax, 8
		jae   .none

		shl   eax, 3
		 or   eax, ecx
		ret
.none:
		mov   eax, 64
		ret











;;;;;;;;;;;;;;;; numbers ;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseInteger:	    ; in: rsi string
		    ; out: rax signed integer
		       push  rcx rdx
			xor  ecx,ecx
			xor  eax,eax
			xor  edx,edx
			cmp  byte[rsi],'-'
			 je  .neg
			cmp  byte[rsi],'+'
			 je  .pos
			jmp  .next
	 .neg:		not  rdx
	 .pos:		add  rsi,1
	 .next: 	mov  cl,byte[rsi]
		       test  cl,cl
			 jz  .done
			sub  cl,'0'
			 js  .done
			cmp  cl,9
			 ja  .done
			add  rsi,1
		       imul  rax,10
			add  rax,rcx
			jmp  .next
	.done:		xor  rax,rdx
			sub  rax,rdx
			pop  rdx rcx
			ret

PrintUnsignedInteger:; in: rax unsigned integer
		     ; out: rdi string
		       push  rbp rcx rdx
			mov  ecx,10
			mov  rbp,rsp
		.l1:	xor  edx,edx
			div  rcx
		       push  rdx
		       test  rax,rax
			jnz  .l1
		.l2:	pop  rax
			add  al,'0'
		      stosb
			cmp  rsp,rbp
			 jb  .l2
			pop  rdx rcx rbp
			ret


PrintSignedInteger:  ; in: rax signed integer
		     ; out: rdi string
		       push  rbp rcx rdx
			mov  ecx,10
			mov  rbp,rsp
		       test  rax,rax
			jns  .l1
			mov  byte[rdi],'-'
			add  rdi,1
			neg  rax
		.l1:	xor  edx,edx
			div  rcx
		       push  rdx
		       test  rax,rax
			jnz  .l1
		.l2:	pop  rax
			add  al,'0'
		      stosb
			cmp  rsp,rbp
			 jb  .l2
			pop  rdx rcx rbp
			ret


PrintHex64:
		     movdqa  xmm3,dqword[.Sum1]
		     movdqa  xmm4,dqword[.Comp1]
		     movdqa  xmm2,dqword[.Mask1]
		     movdqa  xmm5,dqword[.Num1]
		     movdqa  xmm1,xmm0
		      psrlq  xmm0,4
		       pand  xmm0,xmm2
		       pand  xmm1,xmm2
		  punpcklbw  xmm0,xmm1
		     movdqa  xmm1,xmm0
		    pcmpgtb  xmm0,xmm4
		       pand  xmm0,xmm5
		      paddb  xmm1,xmm3
		      paddb  xmm1,xmm0
			ret

align 16
  .Sum1  dq 3030303030303030h, 3030303030303030h
  .Mask1 dq 0f0f0f0f0f0f0f0fh, 0f0f0f0f0f0f0f0fh
  .Comp1 dq 0909090909090909h, 0909090909090909h
  .Num1  dq 0707070707070707h, 0707070707070707h









