
UciOptions_Init:
			lea   rax, [uciOptions]
			mov   dword [rax+UciOptions.hash], 16
			mov   dword [rax+UciOptions.multiPv], 1
			mov   dword [rax+UciOptions.minSplitDepth], 0
			mov   dword [rax+UciOptions.threads], 1
			ret


ParseSetOption:
		       push   rbx
	.Read:
		       call   SkipSpaces
			cmp   byte[rsi], ' '
			 jb   .Error
		    stdcall   CmpString, 'name'
		       test   eax, eax
			 jz   .Error
		       call   SkipSpaces

		    stdcall   CmpStringCaseLess,'Hash'
			lea   rbx, [.Hash]
		       test   eax, eax
			jnz   .CheckValue
		    stdcall   CmpStringCaseLess,'Threads'
			lea   rbx, [.Threads]
		       test   eax, eax
			jnz   .CheckValue
		    stdcall   CmpStringCaseLess,'MultiPv'
			lea   rbx, [.MultiPv]
		       test   eax, eax
			jnz   .CheckValue
.Error:
			lea   rdi, [Output]
		    stdcall   PrintString, 'error in reading setoption'
			mov   al, 10
		      stosb
		       call   _WriteOut_Output
			pop   rbx
			ret
.CheckValue:
		       call   SkipSpaces
		    stdcall   CmpString, 'value'
		       test   eax, eax
			 jz   .Error
		       call   SkipSpaces
			jmp   rbx

.Hash:
		       call   ParseInteger
	      ClampUnsigned   eax, 1, 1 shl MAX_HASH_LOG2MB
			mov   ecx, eax
			mov   dword [uciOptions+UciOptions.hash], eax
		       call   HashTable_Allocate
			pop   rbx
			ret
.Threads:
		       call   ParseInteger
	      ClampUnsigned   eax, 1, MAX_THREADS
			mov   dword [uciOptions+UciOptions.threads], eax
		       call   _ZN10ThreadPool16read_uci_optionsEv
			pop   rbx
			ret

.MultiPv:
		       call   ParseInteger
	      ClampUnsigned   eax, 1, MAX_MOVES
			mov   dword [uciOptions+UciOptions.multiPv], eax
			pop   rbx
			ret
