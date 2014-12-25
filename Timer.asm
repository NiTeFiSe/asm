TimerThread:
			and   rsp,-32
			sub   rsp,32

.Wait:
			mov   byte[TimerThreadState],TIMER_STATE_WAITING
			mov   rcx, qword [TimerThreadStartEvent]
			 or   edx, -1
		       call   _WaitEvent
			mov   byte [TimerThreadState], TIMER_STATE_TICKING

			mov   rcx, qword [TimerThreadEndEvent]
			mov   edx, dword [AlottedTime]
		       call   _WaitEvent

			mov  byte[Signals.stop],-1

			jmp  .Wait


