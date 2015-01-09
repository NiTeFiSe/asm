


_ZN5Mutex4lockEv:
	jmp	qword [rel __imp_EnterCriticalSection]; 0000 _ 48: 8B. 05, 00000000(rel)

_ZN5Mutex6unlockEv:
	jmp	qword [rel __imp_LeaveCriticalSection]; 0000 _ 48: 8B. 05, 00000000(rel)


ThreadBase__notify_one:
; rcx address of ThreadBase
	push	rsi					; 0180 _ 56
	push	rbx					; 0181 _ 53
	sub	rsp, 8*5				; 0182 _ 48: 83. EC, 28
	lea	rbx, [rcx+ThreadBase.l] 			  ; 0186 _ 48: 8D. 59, 08
	mov	rsi, rcx				; 018A _ 48: 89. CE
	mov	rcx, rbx				; 018D _ 48: 89. D9
	call	_ZN5Mutex4lockEv			; 0190 _ E8, 00000000(rel)
	mov	rcx, qword [rsi+ThreadBase.sleepCondition]		      ; 0195 _ 48: 8B. 4E, 30
	call	[rel __imp_SetEvent]		   ; 0199 _ FF. 15, 00000000(rel)
	mov	rcx, rbx				; 019F _ 48: 89. D9
	add	rsp, 8*5				 ; 01A2 _ 48: 83. C4, 28
	pop	rbx					; 01A6 _ 5B
	pop	rsi					; 01A7 _ 5E
	jmp	_ZN5Mutex6unlockEv



_ZN10ThreadBase8wait_forERVKb:
	push	rdi					; 0000 _ 57
	push	rsi					; 0001 _ 56
	push	rbx					; 0002 _ 53
	sub	rsp, 32 				; 0003 _ 48: 83. EC, 20
	lea	rbx, [rcx+ThreadBase.l] 			  ; 0007 _ 48: 8D. 59, 08
	mov	rsi, rcx				; 000B _ 48: 89. CE
	mov	rdi, rdx				; 000E _ 48: 89. D7
	add	rsi, 48 				; 0011 _ 48: 83. C6, 30
	mov	rcx, rbx				; 0015 _ 48: 89. D9
	call	_ZN5Mutex4lockEv			; 0018 _ E8, 00000000(rel)
	jmp	?_058					; 001D _ EB, 0B

?_057:	mov	rdx, rbx				; 001F _ 48: 89. DA
	mov	rcx, rsi				; 0022 _ 48: 89. F1
	call	_ZN17ConditionVariable4waitER5Mutex	; 0025 _ E8, 00000000(rel)
?_058:	mov	al, byte [rdi]				; 002A _ 8A. 07
	test	al, al					; 002C _ 84. C0
	jz	?_057					; 002E _ 74, EF
	mov	rcx, rbx				; 0030 _ 48: 89. D9
	add	rsp, 32 				; 0033 _ 48: 83. C4, 20
	pop	rbx					; 0037 _ 5B
	pop	rsi					; 0038 _ 5E
	pop	rdi					; 0039 _ 5F
	jmp	_ZN5Mutex6unlockEv			; 003A _ E9, 00000000(rel)



_ZN17ConditionVariable4waitER5Mutex:; Function begin
; rcx address of conditionalvariable
; rdx address of lock
	push	rsi					; 0000 _ 56
	push	rbx					; 0001 _ 53
	sub	rsp, 40 				; 0002 _ 48: 83. EC, 28
	mov	rsi, rcx				; 0006 _ 48: 89. CE
	mov	rbx, rdx				; 0009 _ 48: 89. D3
	mov	rcx, rdx				; 000C _ 48: 89. D1
	call	near [rel __imp_LeaveCriticalSection]	; 000F _ FF. 15, 00000000(rel)
	mov	rcx, qword [rsi]			; 0015 _ 48: 8B. 0E
	or	edx, 0FFFFFFFFH 			; 0018 _ 83. CA, FF
	call	near [rel __imp_WaitForSingleObject]	; 001B _ FF. 15, 00000000(rel)
	mov	rax, qword [rel __imp_EnterCriticalSection]; 0021 _ 48: 8B. 05, 00000000(rel)
	mov	rcx, rbx				; 0028 _ 48: 89. D9
	add	rsp, 40 				; 002B _ 48: 83. C4, 28
	pop	rbx					; 002F _ 5B
	pop	rsi					; 0030 _ 5E
; Note: Prefix valid but unnecessary
; Note: Prefix bit or byte has no meaning in this context
	jmp	rax					; 0031 _ 48: FF. E0





_ZN11TimerThread9idle_loopEv:; Function begin
	push	r13					; 0070 _ 41: 55
	push	r12					; 0072 _ 41: 54
	push	rbp					; 0074 _ 55
	push	rdi					; 0075 _ 57
	push	rsi					; 0076 _ 56
	push	rbx					; 0077 _ 53
	sub	rsp, 40 				; 0078 _ 48: 83. EC, 28
	mov	rbx, rcx				; 008A _ 48: 89. CB
	jmp	?_005					; 0094 _ EB, 4A

?_003:	lea	rsi, [rbx+8H]				; 0096 _ 48: 8D. 73, 08
	mov	rcx, rsi				; 009A _ 48: 89. F1
	call	_ZN5Mutex4lockEv			; 009D _ E8, 00000000(rel)
	movzx	edx, byte [rbx+TimerThread.exit]		     ; 00A2 _ 0F B6. 53, 40
	test	dl, dl					; 00A6 _ 84. D2
	jnz	?_004					; 00A8 _ 75, 23
	cmp	byte [rbx+TimerThread.run], 1			    ; 00AA _ 80. 7B, 41, 01
	sbb	ecx, ecx				; 00AE _ 19. C9
	and	ecx, 7FFFFFFAH				; 00B0 _ 81. E1, 7FFFFFFA
	lea	edi, [rcx+5H]				; 00B6 _ 8D. 79, 05
	mov	rcx, rsi				; 00B9 _ 48: 89. F1
	call	qword [__imp_LeaveCriticalSection]				       ; 00BC _ 41: FF. D5
	mov	rcx, qword [rbx+30H]			; 00BF _ 48: 8B. 4B, 30
	mov	edx, edi				; 00C3 _ 89. FA
	call	qword [__imp_WaitForSingleObject]				      ; 00C5 _ 41: FF. D4
	mov	rcx, rsi				; 00C8 _ 48: 89. F1
	call	qword [__imp_EnterCriticalSection]				       ; 00CB _ FF. D5
?_004:	mov	rcx, rsi				; 00CD _ 48: 89. F1
	call	_ZN5Mutex6unlockEv			; 00D0 _ E8, 00000000(rel)
	cmp	byte [rbx+TimerThread.run], 0			    ; 00D5 _ 80. 7B, 41, 00
	jz	?_005					; 00D9 _ 74, 05
	call	_Z10check_timev 			; 00DB _ E8, 00000000(rel)
?_005:	movzx	eax, byte [rbx+TimerThread.exit]		     ; 00E0 _ 0F B6. 43, 40
	test	al, al					; 00E4 _ 84. C0
	jz	?_003					; 00E6 _ 74, AE
	add	rsp, 40 				; 00E8 _ 48: 83. C4, 28
	pop	rbx					; 00EC _ 5B
	pop	rsi					; 00ED _ 5E
	pop	rdi					; 00EE _ 5F
	pop	rbp					; 00EF _ 5D
	pop	r12					; 00F0 _ 41: 5C
	pop	r13					; 00F2 _ 41: 5D
	ret						; 00F4 _ C3



_ZN10MainThread9idle_loopEv:; Function begin
	push	rbp					; 0100 _ 55
	push	rdi					; 0101 _ 57
	push	rsi					; 0102 _ 56
	push	rbx					; 0103 _ 53
	sub	rsp, 40 				; 0104 _ 48: 83. EC, 28
	mov	rbp, qword [rel __imp_SetEvent] 	; 0108 _ 48: 8B. 2D, 00000000(rel)
	lea	rsi, [rcx+8H]				; 010F _ 48: 8D. 71, 08
	lea	rdi, [rcx+30H]				; 0113 _ 48: 8D. 79, 30
	mov	rbx, rcx				; 0117 _ 48: 89. CB
?_006:	mov	rcx, rsi				; 011A _ 48: 89. F1
	call	_ZN5Mutex4lockEv			; 011D _ E8, 00000000(rel)
	mov	byte [rbx+5BDH], 0			; 0122 _ C6. 83, 000005BD, 00
?_007:	movzx	eax, byte [rbx+5BDH]			; 0129 _ 0F B6. 83, 000005BD
	test	al, al					; 0130 _ 84. C0
	jnz	?_008					; 0132 _ 75, 1E
	movzx	edx, byte [rbx+40H]			; 0134 _ 0F B6. 53, 40
	test	dl, dl					; 0138 _ 84. D2
	jnz	?_008					; 013A _ 75, 16
	mov	rcx, qword [rel ?_052]			; 013C _ 48: 8B. 0D, 00000048(rel)
	call	rbp					; 0143 _ FF. D5
	mov	rdx, rsi				; 0145 _ 48: 89. F2
	mov	rcx, rdi				; 0148 _ 48: 89. F9
	call	_ZN17ConditionVariable4waitER5Mutex	; 014B _ E8, 00000000(rel)
	jmp	?_007					; 0150 _ EB, D7
; _ZN10MainThread9idle_loopEv End of function

?_008:	; Local function
	mov	rcx, rsi				; 0152 _ 48: 89. F1
	call	_ZN5Mutex6unlockEv			; 0155 _ E8, 00000000(rel)
	movzx	ecx, byte [rbx+40H]			; 015A _ 0F B6. 4B, 40
	test	cl, cl					; 015E _ 84. C9
	jnz	?_009					; 0160 _ 75, 15
	mov	byte [rbx+5BCH], 1			; 0162 _ C6. 83, 000005BC, 01
	call	_ZN6Search5thinkEv			; 0169 _ E8, 00000000(rel)
	mov	byte [rbx+5BCH], 0			; 016E _ C6. 83, 000005BC, 00
	jmp	?_006					; 0175 _ EB, A3

?_009:	; Local function
	add	rsp, 40 				; 0177 _ 48: 83. C4, 28
	pop	rbx					; 017B _ 5B
	pop	rsi					; 017C _ 5E
	pop	rdi					; 017D _ 5F
	pop	rbp					; 017E _ 5D
	ret						; 017F _ C3














