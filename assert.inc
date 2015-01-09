

macro DebugPrint m {
local ..message, ..over
 if DEBUG
		       push   rdi rdi
			lea   rdi, [Output]
			lea   rcx, [..message]
			jmp   ..over
   ..message: db m
	      db 10,0
   ..over:
		       call   PrintString
		       call   _WriteOut_Output
			pop   rdi rdi
 end if
}



macro assert_nz m {

local .skip, .errorbox, .message
 if DEBUG

   jnz	.skip
   jmp	.errorbox

   .message: db m
	     db 0
   .errorbox:
	lea  rdi,[.message]
       call  _ErrorBox
       call  _ExitProcess

   .skip:

 end if

}

macro assert_z m {

local .skip, .errorbox, .message
 if DEBUG

    jz	.skip
   jmp	.errorbox

   .message: db m
	     db 0
   .errorbox:
	lea  rdi,[.message]
       call  _ErrorBox
       call  _ExitProcess

   .skip:

 end if

}

macro assert cc,a,b,m {

local .skip, .errorbox, .message
 if DEBUG

   cmp	a, b
   j#cc  .skip
   jmp	.errorbox

   .message: db m
	     db 0
   .errorbox:
	lea  rdi,[.message]
       call  _ErrorBox
       call  _ExitProcess

   .skip:

 end if

}
macro assert_ge a,b,m {

local .skip, .errorbox, .message
 if DEBUG

   cmp	a, b
   jge	.skip
   jmp	.errorbox

   .message: db m
	     db 0
   .errorbox:
	lea  rdi,[.message]
       call  _ErrorBox
       call  _ExitProcess

   .skip:

 end if

}