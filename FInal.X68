*-----------------------------------------------------------
* Title      : FINAL Project
* Written by : Steffan Achtmann
* Date       : 5-15-16
* Description: Final Project CSS 422
*-----------------------------------------------------------
START:          ORG         $1000      ; first instruction of program


*Do the initalizations
                LEA         STACKADDRESS,SP     ;initalize stack pointer
* Initialize the data registers used
                CLR.L       D0
                CLR.L       D1
                CLR.L       D2
                CLR.L       D3
                CLR.L       D5
                CLR.L       D6
                
*Get the location of the test code
                LEA         TESTCODE,A2         ; load address of the testcode
                
*start the actual disassembly below
LOOPSTART       MOVE.W      (A2)+,D5    ;move the current code into D5, then increment - this cant probably be changed so you just read (A1) and increment later.. but that's a case for optimizing

*Compare the testinput wth the NOP code
*Need to change this to be a while there's still code... end of code should be 00000000 i think
*   basically, while current != SIMHALT == $00000000?
                CMPI.L      #NOMORECODE,D5      ;end of instructions, branch to program end
                BEQ         ENDCASE
                
                CMPI.W      #NOPCODE,D5          ; compare NOPCODE value to current instruction val
                BEQ         NOPCASE
                
                CMPI.W      #RTSCODE,D5             ;compare the RTS value to current instruction value
                BEQ         RTSCASE

                CMPI.B      #JSRSTARTBYTE,D5      ; compare the JSR starting byte to current instruction byte
                BEQ         JSRCASE
                
                CMPI.B      #NEGSTARTBYTE,D5
                BEQ         NEGCASE
                
                BNE         DATACASE        ; if it's not any of the above, it's just data

LOOPEND         LEA         CR,A1           ;load carriage return val
                MOVE.L      #14,D0
                TRAP        #15             ;print out a new line so next instruction isn't on same line
                BRA         LOOPSTART       ;go back into the loop and check the next instruction value












**********************************************************************************************************************START OF NOP INSTRUCTION DISSASSEMBLY********************************************************************

*Mateched NOP
NOPCASE         LEA         NOPMESSAGE,A1       ;if the word matches NOP, display NOP
                MOVE.B      #14,D0
                TRAP        #15
                BRA         LOOPEND       ;Go do the next instruction now


**********************************************************************************************************************END OF NOP INSTRUCTION DISSASSEMBLY********************************************************************





**********************************************************************************************************************START OF DATA INSTRUCTION DISSASSEMBLY********************************************************************

*matched Data
DATACASE        MOVEM       D5,-(SP)         ;save the register values
                LEA         DATAMESSAGE,A1      ;if the word matches anything else, display data
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM       (SP)+,D5            ;reload the register values    
                BRA         LOOPEND       ;Go do the next instruction now




**********************************************************************************************************************END OF DATA INSTRUCTION DISSASSEMBLY********************************************************************






**********************************************************************************************************************START OF RTS INSTRUCTION DISSASSEMBLY********************************************************************


*matched RTS                
RTSCASE         MOVEM       D5,-(SP)        ;save register values
                LEA         RTSMESSAGE,A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM       (SP)+,D5
                BRA         LOOPEND       ;Go do the next instruction now




**********************************************************************************************************************END OF RTS INSTRUCTION DISSASSEMBLY********************************************************************



**********************************************************************************************************************START OF JSR INSTRUCTION DISSASSEMBLY********************************************************************

                
*Matched JSR
JSRCASE         MOVEM       D5,-(SP)         ;save the register values
                LEA         JSRMESSAGE,A1   ;load JSR message, but don't print until you're sure it's JSR
* you currently know that the starting byte is the same, but don't know the end byte info
*for this to actually be JSR, the next nybble is 10XX, followed by XXXX
    * this is going to be 10 + EA mode (3) + EA register (3)
*possible values will be $4E9(0-7), or $4EB8/$4EB9
    *check the last two first, that'll be easiest to tell, other one make sure it's lower than 4E98
                CMPI.W      #$4EB8,D5      ;4EB8 is (xxx).W 
                BEQ         JSRXXXW
                CMPI.W      #$4EB9,D5         ;4EB9 is (xxx).L
                BEQ         JSRXXXL
                CMPI.W      #$4E98,D5       ;if D5 is less than 4E98, than it's an address register JSR
                BLT         JSRADREG
                CMPI.W      #$4E97,D5
                BGT         DATACASE        ;if it's greater than 4E97, it's data
                
RETURNFROMJSR   MOVEM       (SP)+,D5        ;reload register values - return to this point after a branch

                BRA         LOOPEND       ;Go do the next instruction now
                
        *JSR (xxx).W case   
JSRXXXW         MOVE.L      #14,D0
                TRAP        #15     ;first print the "JSR  "          
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "JSR  $"
                MOVEM       (SP)+,D5        ;reload register values since you're altering D5 value next
                MOVE.W      (A2)+,D5        ;grab the next word of data from the input
                MOVE.L      #16,D2          ;set up your D2 for outputting hex
                MOVE.L      #15,D0          ;load trap task 15
                CLR.L       D1              ;clear D1
                MOVE.W      D5,D1           ;move the data from D5 to D1
                TRAP        #15             ;have now printed out "JSR  $XXXX" where XXXX is a word of data in hex
                
                BRA         LOOPEND                
 

               *JSR (xxx).L case
JSRXXXL         MOVE.L      #14,D0
                TRAP        #15     ;first print the "JSR  "
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "JSR  $"
                MOVEM       (SP)+,D5        ;reload register values since you're altering D5 value next
                MOVE.L      (A2)+,D5        ;grab the next long of data from the input
                MOVE.L      #16,D2          ;set up your D2 for outputting hex
                MOVE.L      #15,D0          ;load trap task 15
                CLR.L       D1              ;clear D1
                MOVE.L      D5,D1           ;move the data from D5 to D1
                TRAP        #15             ;have now printed out "JSR  $XXXXXXXX" where XXXXXXXX is a long of data in hex
                
                BRA         LOOPEND

          
JSRADREG        MOVEM       D5,-(SP)    ;you'll actually do some data reg stuff this time, so save it
                MOVE.L      #14,D0
                TRAP        #15     ;first print the "JSR  "
                LEA         ADDRESSA,A1
                TRAP        #15     ;print the "A" part of the address reg
                
                *print whatever the result of 97-last byte of D5 is as the register used
                SUBI.B      #97,D5
                MOVE.B      D5,D1       ;move the result to D1
                MOVE.L      #3,D0       ;Trap task 3 prints signed number in D1.L
                TRAP        #15         ;have now printed Ax
                MOVEM       (SP)+,D5        ;reload the data reg
                BRA         RETURNFROMJSR
                
                
                
***********************************************************************************************************END OF JSR INSTRUCTION DISSASSEMBLY ****************************************************************





************************************************************************************************************START OF NEG INSTRUCTION DISSASSEMBLY ***************************************************************


*matched NEG
NEGCASE         LEA         NEGMESSAGE,A1           ;load the NEG message, don't print until you know it's actually NEG though
                MOVEM       D5,-(SP)    ;save the D5 value
                *Check now to see which NEG case it is, or if it's even NEG
                *Possible 3rd Nybbles are: 0,1,2,3,5,6,7,9,A,B
                    *If 2,6,A possible 4th nybbles are:
                        *0-7, will be -(An)
                        *2 is a .B, 6 is .W, A is .L
                    *If 1,3,5,7,9,B possible 4th nybbles are:
                        *0-F. gonna depend on previous Nybble
                        *if prev (3rd) nybble was 3,7,B
                            *final nybble will be 8 or F for (xxx).w or (xxx.).l respectively
                            *3 is .B, 7 is .W, B is .L
                        *if prev (3rd) nybble was 1,5,9
                            *final nybble will be 0-7 for (An)
                            *or 8-F for (An)+
                            *1 is .B, 5 is .W, 9 is .L
                CMPI.W      #$4427,D5        ;if it's less than this & greater than $441F, it's 
                BGT         NEGDECREGWORD        ;going to be NEG.B where the reg is of type -(An)
                CMPI.W      #$4420,D5        ;and the value of n is going to be the result of
                BLT         NEGDECREGWORD        ;the D5-$4420
                
                
                *We now have for sure NEG.B -(An). The label isn't neccessary, but helps for readibility
NEGDECREGBYTE   SUBI.W      #$4420,D5       ;this will screw up D5's value and make it the n val
                MOVE.L      #14,D0
                TRAP        #15         ;print the NEG
                LEA         BYTEEND,A1
                TRAP        #15         ;append the .B so we've now printed "NEG.B  "
                LEA         INDIRECTADDECB,A1   ;load indirect address stuff
                TRAP        #15         ;we now have "NEG.B  -(A"                
                CLR.L       D1          ;clear out D1
                MOVE.B      D5,D1       ;move D5 (n value) into D1
                MOVE.L      #3,D0       ;load trap task 3
                TRAP        #15         ;have now printed "NEG.B  -(An"
                LEA         CLOSEPAREN,A1       ;load ')' to print
                MOVE.L      #14,D0              ;set to print
                TRAP        #15             ;have now printed "NEG.B  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the data reg
                BRA         LOOPEND      ;onto the next instruction
                
                
                
                *not for sure neg reg word yet. doing checks here for it
NEGDECREGWORD   CMPI.W      #$4467,D5       ;a NEG.W will be between 4460-4467
                BGT         NEGDECREGLONG
                CMPI.W      #$4460,D5
                BLT         NEGDECREGLONG
                *now we know that it's a neg dec reg word
                SUBI.W      #$4460,D5       ;this will screw up D5's value and make it the n val
                MOVE.L      #14,D0
                TRAP        #15         ;print the NEG
                LEA         WORDEND,A1
                TRAP        #15         ;append the .W so we've now printed "NEG.W  "
                LEA         INDIRECTADDECB,A1   ;load indirect address stuff
                TRAP        #15         ;we now have "NEG.W  -(A"                
                CLR.L       D1          ;clear out D1
                MOVE.B      D5,D1       ;move D5 (n value) into D1
                MOVE.L      #3,D0       ;load trap task 3
                TRAP        #15         ;have now printed "NEG.W  -(An"
                LEA         CLOSEPAREN,A1       ;load ')' to print
                MOVE.L      #14,D0              ;set to print
                TRAP        #15             ;have now printed "NEG.W  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the data reg
                BRA         LOOPEND      ;onto the next instruction
                
                
                
                *not for sure neg reg long yet. doing checks
NEGDECREGLONG   CMPI.W      #$44A7,D5       ; a NEG.L will be between 44A0-44A7
                BGT         NEGXXX
                CMPI.W      #$44A0,D5
                BLT         NEGXXX
                *now if you're still here it is for sure neg dec long
                SUBI.W      #$44A0,D5       ;this will screw up D5's value and make it the n val
                MOVE.L      #14,D0
                TRAP        #15         ;print the NEG
                LEA         LONGEND,A1
                TRAP        #15         ;append the .L so we've now printed "NEG.L  "
                LEA         INDIRECTADDECB,A1   ;load indirect address stuff
                TRAP        #15         ;we now have "NEG.L  -(A"                
                CLR.L       D1          ;clear out D1
                MOVE.B      D5,D1       ;move D5 (n value) into D1
                MOVE.L      #3,D0       ;load trap task 3
                TRAP        #15         ;have now printed "NEG.L  -(An"
                LEA         CLOSEPAREN,A1       ;load ')' to print
                MOVE.L      #14,D0              ;set to print
                TRAP        #15             ;have now printed "NEG.L  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the data reg
                BRA         LOOPEND      ;onto the next instruction
                
                
                *not sure if it's (XXX).W quite yet
NEGXXX          CMPI.W      #$4438,D5 ;B,8F  If it's 4438 or 443F, it's a NEG.B (xxx).W or .L
                BEQ         NEGXXXBW
                CMPI.W      #$443F,D5
                BEQ         NEGXXXBL
                CMPI.W      #$4478,D5        ;if it's 4478 or 447F, it's NEG.W (xxx).W or .L
                BEQ         NEGXXXWW
                CMPI.W      #$447F,D5
                BEQ         NEGXXXWL
                CMPI.W      #$44B8,D5       ;if it's 44B8 or 44BF, it's NEG.L (xxx).W or .L
                BEQ         NEGXXXLW
                CMPI.W      #$44BF,D5
                BEQ         NEGXXXLL
                BRA         NEGADDREG       ;if it's not these, move onto final test cases (An) and (An)+
        
        *For the below NEGXXXzz, it has been confirmed to be that particular instruction
*NEG.B $XXXX        
NEGXXXBW        MOVE.L      #14,D0      ;the NEG is still loaded, so print it now
                TRAP        #15         ;have now printed "NEG"
                LEA         BYTEEND,A1  ;load the .B
                TRAP        #15             ;have now printed "NEG.B  "
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "NEG.B  $"
                *now you need to print out the word which is the address value. so you need to take the next Word of data and print it out
                MOVEM       (SP)+,D5        ;reload the stack since you're changing D5 system-wide next
                MOVE.W      (A2)+,D5        ;you're grabbing the next Word of data into D5 now
                MOVE.B      #16,D2          ;move 16 into D2.B so that you can display data in Base 16
                MOVE.L      D5,D1           ;move the current value of data into D1
                MOVE.L      #15,D0          ;load trap task 15
                TRAP        #15             ;have now printed "NEG.B  $XXXX" where XXXX is a word of data representing a absolute address

                BRA         LOOPEND         ;move onto the next instruction 
                
*NEG.B $XXXXXXXX                
NEGXXXBL        MOVE.L      #14,D0      ;the NEG is still loaded, so print it now
                TRAP        #15         ;have now printed "NEG"
                LEA         BYTEEND,A1  ;load the .B
                TRAP        #15             ;have now printed "NEG.B  "
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "NEG.B  $"
                *now you need to print out the word which is the address value. so you need to take the next Word of data and print it out
                MOVEM       (SP)+,D5        ;reload the stack since you're changing D5 system-wide next
                MOVE.L      (A2)+,D5        ;you're grabbing the next Long of data into D5 now
                MOVE.B      #16,D2          ;move 16 into D2.B so that you can display data in Base 16
                MOVE.L      D5,D1           ;move the current value of data into D1
                MOVE.L      #15,D0          ;load trap task 15
                TRAP        #15             ;have now printed "NEG.B  $XXXXXXXX" where XXXXXXXX is a long of data representing a absolute address

                BRA         LOOPEND         ;move onto the next instruction 
                
*NEG.W $XXXX                
NEGXXXWW        MOVE.L      #14,D0      ;the NEG is still loaded, so print it now
                TRAP        #15         ;have now printed "NEG"
                LEA         WORDEND,A1  ;load the .W
                TRAP        #15             ;have now printed "NEG.W  "
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "NEG.W  $"
                *now you need to print out the word which is the address value. so you need to take the next Word of data and print it out
                MOVEM       (SP)+,D5        ;reload the stack since you're changing D5 system-wide next
                MOVE.W      (A2)+,D5        ;you're grabbing the next Word of data into D5 now
                MOVE.B      #16,D2          ;move 16 into D2.B so that you can display data in Base 16
                MOVE.L      D5,D1           ;move the current value of data into D1
                MOVE.L      #15,D0          ;load trap task 15
                TRAP        #15             ;have now printed "NEG.W  $XXXX" where XXXX is a word of data representing a absolute address

                BRA         LOOPEND         ;move onto the next instruction 
                
*NEG.W $XXXXXXXX                
NEGXXXWL        MOVE.L      #14,D0      ;the NEG is still loaded, so print it now
                TRAP        #15         ;have now printed "NEG"
                LEA         WORDEND,A1  ;load the .W
                TRAP        #15             ;have now printed "NEG.W  "
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "NEG.W  $"
                *now you need to print out the word which is the address value. so you need to take the next Word of data and print it out
                MOVEM       (SP)+,D5        ;reload the stack since you're changing D5 system-wide next
                MOVE.L      (A2)+,D5        ;you're grabbing the next long of data into D5 now
                MOVE.B      #16,D2          ;move 16 into D2.B so that you can display data in Base 16
                MOVE.L      D5,D1           ;move the current value of data into D1
                MOVE.L      #15,D0          ;load trap task 15
                TRAP        #15             ;have now printed "NEG.W  $XXXXXXXX" where XXXXXXXX is a long of data representing a absolute address

                BRA         LOOPEND         ;move onto the next instruction
                
*NEG.L $XXXX                
NEGXXXLW        MOVE.L      #14,D0      ;the NEG is still loaded, so print it now
                TRAP        #15         ;have now printed "NEG"
                LEA         LONGEND,A1  ;load the .L
                TRAP        #15             ;have now printed "NEG.L  "
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "NEG.L  $"
                *now you need to print out the word which is the address value. so you need to take the next Word of data and print it out
                MOVEM       (SP)+,D5        ;reload the stack since you're changing D5 system-wide next
                MOVE.W      (A2)+,D5        ;you're grabbing the next Word of data into D5 now
                MOVE.B      #16,D2          ;move 16 into D2.B so that you can display data in Base 16
                MOVE.L      D5,D1           ;move the current value of data into D1
                MOVE.L      #15,D0          ;load trap task 15
                TRAP        #15             ;have now printed "NEG.L  $XXXX" where XXXX is a word of data representing a absolute address

                BRA         LOOPEND         ;move onto the next instruction

*NEG.L $XXXXXXXX
NEGXXXLL        MOVE.L      #14,D0      ;the NEG is still loaded, so print it now
                TRAP        #15         ;have now printed "NEG"
                LEA         WORDEND,A1  ;load the .L
                TRAP        #15             ;have now printed "NEG.L  "
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "NEG.L  $"
                *now you need to print out the word which is the address value. so you need to take the next Word of data and print it out
                MOVEM       (SP)+,D5        ;reload the stack since you're changing D5 system-wide next
                MOVE.L      (A2)+,D5        ;you're grabbing the next long of data into D5 now
                MOVE.B      #16,D2          ;move 16 into D2.B so that you can display data in Base 16
                MOVE.L      D5,D1           ;move the current value of data into D1
                MOVE.L      #15,D0          ;load trap task 15
                TRAP        #15             ;have now printed "NEG.L  $XXXXXXXX" where XXXXXXXX is a word of data representing a absolute address

                BRA         LOOPEND         ;move onto the next instruction

 *if prev (3rd) nybble was 1,5,9
                            *final nybble will be 0-7 for (An)
                            *or 8-F for (An)+
                            *1 is .B, 5 is .W, 9 is .L
            *Not sure yet if it is the instruction, but these are the final tests for NEG.X (An) or (An)+
            *Make sure to check from low->high and always BLT
NEGADDREG       CMPI.W      #$4420,D5       ;If 4410-441F, it's either NEG.B (An) or -(An)
                BLT         POSSIBLENEGB
                CMPI.W      #$4460,D5       ;if 4450-445F, it's either NEG.W (An) or -(An)
                BLT         POSSIBLENEGW
                CMPI.W      #$44A0,D5       ;if 4490-449F, it's either NEG.L (An) or -(An)
                BLT         POSSIBLENEGL
                BRA         DATACASE        ;if it's none of the above, it's data
                
POSSIBLENEGB    CMPI.W      #$4410,D5       ;this is final test if between 4410-441F
                BLT         DATACASE        ;if it's not, it's data
                *from here on out we know it's a NEG.B of (An) or -(An). which depends on final nybble.
                *NEG is still stored in A1
                MOVE.L      #14,D0
                TRAP        #15             ;print "NEG"
                LEA         BYTEEND,A1      
                TRAP        #15             ;have now printed "NEG.B  "
                CLR.L       D6              ;make sure D6 is blank
                MOVE.W      D5,D6           ;move D5's value into D6 as a temp
                SUBI.W      #$4410,D6       ;this will make D6 have the value of 0-F. if it's 0-7, it's gonna be an A(n) thing, 8-F, -(An)
                CMPI.B      #$8,D6      
                BLT         NEGANCASE       ;it's less, so it's A(n).
                BRA         NEGDECANCASE    ;otherwise it's 8-F so -(An) case


POSSIBLENEGW    CMPI.W      #$4450,D5   ;this is final test of it it's between 4450 and 445F
                BLT         DATACASE    ;if it's not, it's data
                *from here on out we know it's a NEG.W of (An) or -(An). which depends on final nybble
                *NEG is still stored in A1
                MOVE.L      #14,D0
                TRAP        #15             ;print "NEG"
                LEA         WORDEND,A1      
                TRAP        #15             ;have now printed "NEG.W  "
                CLR.L       D6              ;make sure D6 is blank
                MOVE.W      D5,D6           ;move D5's value into D6 as a temp
                SUBI.W      #$4450,D6       ;this will make D6 have the value of 0-F. if it's 0-7, it's gonna be an A(n) thing, 8-F, -(An)
                CMPI.B      #$8,D6      
                BLT         NEGANCASE       ;it's less, so it's A(n).
                BRA         NEGDECANCASE    ;otherwise it's 8-F so -(An) case

POSSIBLENEGL    CMPI.W      #$4490,D5   ;this is final test of it it's between 4490 and 449F
                BLT         DATACASE    ;if it's not, it's data
                *from here on out we know it's a NEG.L of (An) or -(An). which depends on final nybble
                *NEG is still stored in A1
                MOVE.L      #14,D0
                TRAP        #15             ;print "NEG"
                LEA         LONGEND,A1      
                TRAP        #15             ;have now printed "NEG.L  "
                CLR.L       D6              ;make sure D6 is blank
                MOVE.W      D5,D6           ;move D5's value into D6 as a temp
                SUBI.W      #$4490,D6       ;this will make D6 have the value of 0-F. if it's 0-7, it's gonna be an A(n) thing, 8-F, -(An)
                CMPI.B      #$8,D6      
                BLT         NEGANCASE       ;it's less, so it's A(n).
                BRA         NEGDECANCASE    ;otherwise it's 8-F so -(An) case
                
         *the resulting output will be NEG.X (An)       
NEGANCASE       LEA         INDIRECTADAB,A1
                TRAP        #15             ;will now have printed "NEG.X  (A"
                MOVE.B      #16,D2          ;load D2 for trap task to display hex
                MOVE.L      #15,D0          ;load trap task 15
                MOVE.L      D6,D1           ;move the value in D6 (n) into D1
                TRAP        #15             ;have now printed "NEG.X  (An"
                LEA         CLOSEPAREN,A1   
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "NEG.X  (An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;onto the next instruction

            *the resulting output will be NEG.X -(An)
NEGDECANCASE    LEA         INDIRECTADDECB,A1
                TRAP        #15             ;will now have printed "NEG.X  -(A"
                MOVE.B      #16,D2          ;load D2 for trap task to display hex
                MOVE.L      #15,D0          ;load trap task 15
                MOVE.L      D6,D1           ;move the value in D6 (n) into D1
                TRAP        #15             ;have now printed "NEG.X  -(An"
                LEA         CLOSEPAREN,A1   
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "NEG.X  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;onto the next instruction
                
                
*********************************************************************************  END OF NEG ISNTRUCTION DISASSAMEBLY **************************************************************************


*Stop program
ENDCASE         SIMHALT             ; halt simulator


*currently tests: NOP, NEG, JSR, MOVE.L (not implemented yet)
TESTCODE        NOP
                MOVE.L      #14,D7
                NEG.B       D7
                JSR         ENDCASE

* Put variables and constants here

STACKADDRESS    EQU         $7000    ;marks the location of the start of the stack

*various instruction's hex values (or partial hex values) are stored here
NOPCODE         EQU         $4E71       ;hex version of the NOP
RTSCODE         EQU         $4E76       ;Hex version of RTS
JSRSTARTBYTE    EQU         $4E         ;next two digits are 10+ EA Mode first 2 digits, final four are EA Mode final digit(1) and EA register (3)
NEGSTARTBYTE    EQU         $44         ;starting byte of NEG - next two bits are size, next 3 are EA mode, last 3 are EA reg

NOMORECODE      EQU         $FFFFFFFF   ;if A1 = this, then you've hit the end. I think



*Below are output messages
NOPMESSAGE      DC.L        'NOP',0
DATAMESSAGE     DC.L        'Data',0
NEGMESSAGE      DC.L        'NEG',0       
JSRMESSAGE      DC.L        'JSR  ',0       ;spaces are intentional for easier time adding the EAs after
RTSMESSAGE      DC.L        'RTS',0

ADDRESSA        DC.L        'A',0           ;for printing ADDRESS (A) registers
INDIRECTADAB    DC.L        '(A',0          ;Beginning of the Indirect ADdress - used for start of increment as well
INDIRECTADDECB  DC.L        '-(A',0         ;Beginning of INDIRECT ADdress DECrement
INCREMENTEND    DC.L        ')+',0          ;END of INCREMENT address line

CLOSEPAREN      DC.L        ')',0           ;for closing Indirect Address normal and Decrement
DOLLARSIGN      DC.L        '$',0           ;for absolute address stuff (xxx).w/l

BYTEEND         DC.L        '.B  ',0          ;for instructions that are sized - this is a bite-sized one
WORDEND         DC.L        '.W  ',0          ;same, but word
LONGEND         DC.L        '.L  ',0          ;same, but long

DATAREG         DC.L        'D',0           ;D for data reg... this can probably be done better

CR              EQU         $0D             ;carriage return

                END         START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
