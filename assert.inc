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