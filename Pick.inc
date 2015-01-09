macro GetNextMove {

			mov   rdx, qword [rsi+Pick.stage]
		       push   r14 r15
			mov   r14, qword [rsi+Pick.cur]
			mov   r15, qword [rsi+Pick.end]
		       push   rdi r12 r13
		       call   rdx
			mov   qword [rsi+Pick.cur], r14
			mov   qword [rsi+Pick.end], r15
			pop   r13 r12 rdi r15 r14
			mov   qword [rsi+Pick.stage], rdx


}



macro InsertionSort begin, end, p, q {
local .Outer, .Inner, .InnerDone, .OuterDone
			lea   p, [begin+8]
			cmp   p, end
			jae   .OuterDone

.Outer:
			mov   rax, qword [p]
			mov   edx, dword [p+4]
			mov   q, p

			cmp   q, begin
			jbe   .InnerDone
			mov   rcx, qword [q-8+0]
			cmp   edx, dword [q-8+4]
			jle   .InnerDone
 .Inner:
			mov   qword [q], rcx
			sub   q, 8

			cmp   q, begin
			jbe   .InnerDone
			mov   rcx, qword [q-8+0]
			cmp   edx, dword [q-8+4]
			 jg   .Inner

 .InnerDone:
			add   p, 8
			cmp   p, end
			 jb   .Outer
.OuterDone:

}



;template<class BidirIt, class UnaryPredicate>
;BidirIt partition(BidirIt first, BidirIt last, UnaryPredicate p)
;{
;    while (1) {
;        while ((first != last) && p(*first)) {
;            ++first;
;        }
;        if (first == last--) break;
;        while ((first != last) && !p(*last)) {
;            --last;
;        }
;        if (first == last) break;
;        std::iter_swap(first++, last);
;    }
;    return first;
;}
macro Partition first, last {
local .Outer, .Inner1, .Inner1Done, .Inner2, .Inner2Done, .OuuterDone

.Outer:

			cmp   first, last
			jae   .Inner1Done
			cmp   dword [first+4], 0
			jle   .Inner1Done
 .Inner1:
			add   first, 8
			cmp   first, last
			jae   .Inner1Done
			cmp   dword [first+4], 0
			 jg   .Inner1
 .Inner1Done:
			sub   last, 8
			cmp   first, last
			jae   .OuterDone

			cmp   first, last
			jae   .Inner2Done
			cmp   dword [first+4], 0
			 jg   .Inner2Done
 .Inner2:
			sub   last, 8
			cmp   first, last
			jae   .Inner2Done
			cmp   dword [first+4], 0
			jle   .Inner2
 .Inner2Done:
			cmp   first, last
			jae   .OuterDone

			mov   rax, qword[first]
			mov   rcx, qword[last]
			mov   qword[first], rcx
			mov   qword[last], rax
			jmp   .Outer

.OuterDone:







}




macro PickBest	beg, start, end {
local .Next, .Done
			mov   eax, dword [beg+0]
			mov   ecx, dword [beg+4]
			mov   rdx, beg
			add   beg, 8
			mov   start, beg
			cmp   beg, end
			jae   .Done
.Next:
			mov   eax, dword [start+4]
			cmp   eax, ecx
		      cmovg   rdx, start
		      cmovg   ecx, eax
			add   start, 8
			cmp   start, end
			 jb   .Next
			mov   rax, qword [rdx]
			mov   rcx, qword [beg-8]
			mov   qword [rdx], rcx
			mov   qword [beg-8], rax
.Done:

}


SeeSignBitMask = 0

_from = 0
while _from < 8
 _to = 0
 while _to < 8

   _fromvalue = 0
   if Pawn <= _from & _from <= Queen
    _fromvalue = _from
   end if

   _tovalue = 0
   if Pawn <= _to & _to <= Queen
    _tovalue = _to
   end if

   if _fromvalue > _tovalue
    SeeSignBitMask = SeeSignBitMask or (1 shl (_from+8*_to))
   end if


;if fromvalue <= tovalue
;no set
;end if

  _to = _to+1
 end while
 _from = _from+1
end while

macro SeeSign JmpTo {
local .Positive

; ecx move (preserved)

			mov   r8d, ecx
			shr   r8d, 6
			and   r8d, 63	; r8d = from
			mov   r9d, ecx
			and   r9d, 63	; r9d = to
		      movzx   r10d, byte [rbp+Pos.board+r8]	; r10 = FROM PIECE
		      movzx   r11d, byte [rbp+Pos.board+r9]	; r11 = TO PIECE
			mov   r8, SeeSignBitMask
			and   r10d, 7
			and   r11d, 7
			lea   r10d, [r10+8*r11]
			mov   eax, VALUE_KNOWN_WIN
			 bt   r8, r10
if JmpTo eq
			jnc   .Positive
else
			jnc   JmpTo
end if
		       call   See
.Positive:
}


macro ScoreCaptures start, end {
local .WhileLoop, .WhileTest, .Done

			cmp   start, end
			jae   .Done
.WhileLoop:
			mov   eax, dword [start+0]
			lea   start, [start+8]
			mov   edx, eax
			shr   eax, 12
			and   edx, 63
		      movzx   edx, byte [rbp+Pos.board+rdx]
			mov   ecx, edx
			and   ecx, 7
			mov   edx, dword [PieceValue_MG+4*rdx]
			sub   edx, ecx
			add   edx, [ScoreCaptures_MoveTypeValues+4*rax]
			mov   dword [start-4], edx
.WhileTest:		cmp   start, end
			 jb   .WhileLoop
.Done:
}



macro ScoreQuiets start, end {
local .WhileLoop, .WhileTest, .Done

			cmp   start, end
			jae   .Done
.WhileLoop:
			mov   eax, dword [start+0]
			lea   start, [start+8]
			mov   edx, eax
			shr   eax, 6
			and   eax, 63
			and   edx, 63
		      movzx   eax, [rbp+Pos.board+rax]
			shl   eax, 8
			lea   rdx, [History+4*rdx]
			mov   eax, [rax+rdx]
			mov   dword [start-4], eax
.WhileTest:
			cmp   start, end
			 jb   .WhileLoop
.Done:


}


macro ScoreEvasions start, end, histtab {
local .WhileLoop, .WhileTest, .Done, .Positive, .Capture, .Negative

			cmp   start, end
			jae   .Done
.WhileLoop:
			mov   ecx, [start]
			lea   start, [start+8]
		    SeeSign   .Positive
		       test   eax, eax
			 js   .Negative

 .Positive:
			mov   r8d, ecx
			shr   r8d, 6
			mov   eax, ecx
			shr   eax, 12
			and   r8d, 63
			and   ecx, 63
		      movzx   r11d, byte [rbp+Pos.board+rcx]	 ; r11 = TO PIECE
		      movzx   edx, byte [rbp+Pos.board+r8]
			lea   rcx, [histtab+4*rcx]
		       test   r11d, r11d
			jnz   .Capture
			cmp   eax, MOVE_TYPE_EPCAP
			 je   .Capture

			shl   edx, 8
			mov   eax, dword [rdx+rcx]
			mov   dword [start-4], eax
			cmp   start, end
			 jb   .WhileLoop
			jmp   .Done

 .Capture:
			and   edx, 7
			mov   eax, dword [PieceValue_MG+4*r11]
			sub   eax, edx
			add   eax, HistoryStats_Max
			mov   dword [start-4], eax
			cmp   start, end
			 jb   .WhileLoop
			jmp   .Done

 .Negative:
			sub   eax, HistoryStats_Max
			mov   dword [start-4], eax
			cmp   start, end
			 jb   .WhileLoop
			jmp   .Done



.WhileTest:
			cmp   start, end
			 jb   .WhileLoop
.Done:



}




