about another chess enigine:
- it is a rewrite of stockfish into asm
- assemble with fasm (www.flatassembler.com)
- all of the nonsense that results from c++ coders wrestling with a compiler is avoided here
- hopefully it gather interest from other asm coders or prospetive asm coders

assemble options:
- HAVE (most important) indicates avaiable instructions, program does a runtime check to see if these really are avaiable
- DEBUG turns on some printing and asserts
- DISPLAY_CURRMOVE displays the current move while searching the root

about the code so far:
- in a baby state so far
- the thread code from stockfish has been preserved for the most part
  - the global variable Threads has been renamed threadPool
  - the vector of threads in threadPool have been given static allocation
  - the silly function start_routine has been eliminated
- the global variable rootMoves has been given static allocation
- the move generation and picking function have been rewritten
  - the CheckInfo structure has been merged into the State structure
  - the sequence of State structures has been reworked as a simple array instead of a linked list
    - this will incure a copy cost at split points when this is written
    - but 50 move rule checking is easier
  - there are two version of do_move, for setting ci or not
- the evaluation function is not written yet
  - just piece values and mobility with some pawn stuff
  - most changes to stockfish occure in evaluation, so not motivated to write this
- the search function is not fully written yet
- the qsearch function is fully written :)

register conventions:
- follows MS x64 calling convention for the most part
- uses rdi/rsi for strings were appropriate
- rbp is generally used to hold the Pos structure
- rbx is generally used to hold the current State structure
- rsi is used in the search function to hold the Stack or the Pick structures

os:
- winodws
- uses only window kernel functions for now
- linux port should be easy, as it should involve only a rewrite of Windows.asm and minimal changes to ace.a

