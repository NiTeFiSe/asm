
_SetStdHandles: ; no arguments
			sub   rsp,8*5
			mov   ecx,STD_INPUT_HANDLE
		       call   [__imp_GetStdHandle]
			mov   qword[hStdIn], rax
			mov   ecx,STD_OUTPUT_HANDLE
		       call   [__imp_GetStdHandle]
			mov   qword[hStdOut], rax
			mov   ecx,STD_ERROR_HANDLE
		       call   [__imp_GetStdHandle]
			mov   qword[hStdError], rax
			add   rsp, 8*5
			ret


_SetFrequency:
			sub   rsp, 8*5
			lea   rcx, [Frequency]
		       call   qword [__imp_QueryPerformanceFrequency]
			mov   dword [rsp], 64
			mov   dword [rsp+8], 1000
		       fild   dword [rsp]
		       fild   dword [rsp+8]
		     fscale
		       fstp   st1
		       fild   qword [Frequency]
		      fdivp   st1, st0
		      fistp   qword [Period]
			add   rsp, 8*5
			ret

_SetAffinityMasks:
		       push  rbp
		     invoke  __imp_GetCurrentProcess
		     invoke  __imp_GetProcessAffinityMask,eax,ProcessAffinityMask,SystemAffinityMask
			pop  rbp
			ret



_GetTime:	; out: rax  time in ms
		;      rdx  fractional part of time in ms
			sub   rsp,8*9
			lea   rcx, [rsp+8*8]
		       call   qword [__imp_QueryPerformanceCounter]
			mov   rax, qword [rsp+8*8]
			mul   qword [Period]
		       xchg   rax, rdx
			add   rsp, 8*9
			ret




_VirtualAlloc:	; rcx is size
			sub   rsp, 8*5
			mov   rdx, rcx
			xor   ecx, ecx
			mov   r8d, MEM_COMMIT
			mov   r9d, PAGE_READWRITE
		       call   qword [__imp_VirtualAlloc]
			add   rsp, 8*5
			ret


_VirtualFree:	; rcx is address
			sub   rsp, 8*5
			xor   edx, edx
			mov   r8d, MEM_RELEASE
		       test   rcx, rcx
			 jz   @f
		       call   qword [__imp_VirtualFree]
		   @@:	add   rsp, 8*5
			ret



_WriteOut: ; in: rcx  address of string start
	   ;     rdi  address of string end
		sub   rsp, 8*9
		mov   r8, rdi
		sub   r8, rcx
		mov   rdx, rcx
		mov   qword [rsp+8*4], 0
		mov   rcx, qword [hStdOut]
		lea   r9, [rsp+8*8]
	       call   [__imp_WriteFile]
		add   rsp, 8*9
		ret


_WriteError: ; in: rcx  address of string start
	     ;     rdx  address of string end
		sub   rsp, 8*9
		mov   r8d, edx
		sub   r8d, ecx
		mov   rdx, rcx
		mov   qword [rsp+8*4], 0
		mov   rcx, qword [hStdError]
		lea   r9, [rsp+8*8]
	       call   [__imp_WriteFile]
		add   rsp, 8*9
		ret



_ReadIn:     ; in: rsi  address to write string
	     ; out: eax =  0 if not file end
	     ;      eax = -1 if file end
	       push   rsi
		sub   rsp, 8*8
.read:
		mov   rdx, rsi
		mov   qword [rsp+20H], 0
		lea   r9, [rsp+30H]
		mov   r8d, 1
		mov   rcx, qword [hStdIn]
	       call   [__imp_ReadFile]
		mov   dl, byte [rsi]
		add   rsi, 1
	       test   eax, eax
		 jz   @f
		 or   eax,-1
		cmp   dword [rsp+30H], 0
		 jz   .return
	@@:	cmp   dl, ' '
		jae   .read

		mov   byte [rsi-1], 0
		xor   eax, eax
.return:
		add   rsp, 8*8
		pop   rsi
		ret






	      align   16
_ExitProcess:	; rcx is exit code
			jmp  qword[__imp_ExitProcess]

	      align   16
_ExitThread:	; rcx is exit code
			jmp  qword[__imp_ExitThread]




_ErrorBox:	; rdi points to null terminated string to write to message box
			sub  rsp,8*7
			lea  rcx,[.user32]
		       call  qword[__imp_LoadLibrary]
			mov  rcx,rax
			lea  rdx,[.MessageBoxA]
		       call  qword[__imp_GetProcAddress]
			xor  ecx,ecx
			mov  rdx,rdi
			lea  r8,[.caption]
			mov  r9d,MB_OK
		       call  rax
			add  rsp,8*7
			ret

.user32: db 'user32.dll',0
.MessageBoxA: db 'MessageBoxA',0
.caption: db 'error',0


_CheckCPU:
		       push  rbp rbx r15

if HAVE and HAVE_POPCNT
			lea  r15,[szCPUError.POPCNT]
			mov  eax,1
			xor  ecx,ecx
		      cpuid
			and  ecx,(1 shl 23)
			cmp  ecx,(1 shl 23)
			jne  .Failed
end if

if HAVE and HAVE_AVX1
			lea  r15,[szCPUError.AVX1]
			mov  eax,1
			xor  ecx,ecx
		      cpuid
			and  ecx,(1 shl 27)+(1 shl 28)
			cmp  ecx,(1 shl 27)+(1 shl 28)
			jne  .Failed
			mov  ecx,0
		     xgetbv
			and  eax,0x06
			cmp  eax,0x06
			jne  .Failed
end if

if HAVE and HAVE_AVX2
			lea  r15,[szCPUError.AVX2]
			mov  eax,7
			xor  ecx,ecx
		      cpuid
			and  ebx,(1 shl 5)
			cmp  ebx,(1 shl 5)
			jne  .Failed
end if

if HAVE and HAVE_BMI1
			lea  r15,[szCPUError.BMI1]
			mov  eax,7
			xor  ecx,ecx
		      cpuid
			and  ebx,(1 shl 3)
			cmp  ebx,(1 shl 3)
			jne  .Failed
end if

if HAVE and HAVE_BMI2
			lea  r15,[szCPUError.BMI2]
			mov  eax,7
			xor  ecx,ecx
		      cpuid
			and  ebx,(1 shl 8)
			cmp  ebx,(1 shl 8)
			jne  .Failed
end if

			pop  r15 rbx rbp
			ret

	.Failed:	lea  rdi,[Output]
			lea  rsi,[szCPUError]
		       call  Append
			mov  rsi,r15
		       call  Append
			xor  eax,eax
		      stosd
			lea  rdi,[Output]
		       call  _ErrorBox
			xor  ecx,ecx
		       call  _ExitProcess



