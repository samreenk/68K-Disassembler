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
                CLR.L       D7
                
*Get the location of the test code
                LEA         TESTCODE,A2         ; load address of the testcode
                
*start the actual disassembly below
LOOPSTART       MOVE.W      (A2)+,D5    ;move the current code into D5, then increment - this cant probably be changed so you just read (A1) and increment later.. but that's a case for optimizing

*Compare the testinput wth the NOP code
*Need to change this to be a while there's still code... end of code should be 00000000 i think
*   basically, while current != SIMHALT == $00000000?
                CMPI.L      #NOMORECODE,D5      ;end of instructions, branch to program end
                BEQ         ENDCASE
                
NOPCMP          CMPI.W      #NOPCODE,D5          ; compare NOPCODE value to current instruction val
                BEQ         NOPCASE
                
RTSCMP          CMPI.W      #RTSCODE,D5             ;compare the RTS value to current instruction value
                BEQ         RTSCASE

                *So here JSR start byte is 4E
JSRCMP          CLR.L       D6              ;clear d6
                MOVE.W      #JSRSTARTBYTE,D6
                ROL         #8,D6
                CMP.W       D6,D5      ; compare the D6 (holds 4E00) to D5 (instruction)
                BLT         NEGCMP      ;if D5 is lower, then it's not a JSR
                CMPI.W      #$4F00,D5   ;compare again
                BLT         JSRCASE     ;if it's lower than 4F00, greater than 4DFF, it's a potential JSR
                
                *NEG start byte is 44
NEGCMP          CLR.L       D6          ;reset D6
                MOVE.W      NEGSTARTBYTE,D6     ;move the starting byte into D6
                ROL         #8,D6               ;rotate bytes so they're actually in the front, D6 is now 4400
                CMP.W       D6,D5               ;compare the instrcution code to 4400
                BLT         DATASTUFF           ;if D5 is less, it's not NEG
                CMPI.W      #$4500,D5
                BLT         NEGCASE             ;if it's less than 4500, greater or equal to 4400, check neg
                
                *ASL/ASR/LSL/LSR starts with $E
ALSLRCMP        CLR.L       D6          ;reset D6
                MOVE.W      #ALSRLSTARTNYBLE,D6     ;move the starting nybble into D6
                ROL         #8,D6                   ;do max rotation
                ROL         #4,D6                   ;do another rotation such that you have $E000
                MOVEM       D5,-(SP)                ;store the real D5 value for safekeeping
                AND.W       D6,D5                   ;AND D5 (instruction) with D6 ($E000)
                CMP.W       D6,D5                   ;if both D5 & D6 are equal, branch out to possible ALSLR checks
                BEQ         ALSLRPTONE              
                MOVEM       (SP)+,D5                ;otherwise, reload the stack as it should be and move on
                
                
                
DATASTUFF       BNE         DATACASE        ; if it's not any of the above, it's just data

LOOPEND         LEA         NEWLINE,A1           ;load carriage return val
                MOVE.L      #13,D0
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
                LEA         LONGEND,A1  ;load the .L
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
            
            
            *******************************************************************************************EDITING BELOW THIS LINE **************************************************
NEGADDREG       CMPI.W      #$4410,D5       
                BLT         MAYBEDATAREG    ;Below 4410 it could be a data reg
                CMPI.W      #$4420,D5       ;If 4410-441F, it's either NEG.B (An) or (An)+
                BLT         POSSIBLENEGB
                CMPI        #$4450,D5
                BLT         MAYBEDATAREG    ;below 4450 it could be a data reg
                CMPI.W      #$4460,D5       ;if 4450-445F, it's either NEG.W (An) or (An)+
                BLT         POSSIBLENEGW
                CMPI.W      #$4490,D5
                BLT         MAYBEDATAREG    ;below 4490 it could be a data reg
                CMPI.W      #$44A0,D5       ;if 4490-449F, it's either NEG.L (An) or (An)+
                BLT         POSSIBLENEGL
MAYBEDATAREG    *time to check for Data reg, neglected to do so earlier
                *possible values are 4400-7, 4440-7, 4480-7, being .B, .W and .L respectively
                CMPI.W      #$4408,D5       ;if less, than it's possibly .B Dx
                BLT         MAYBENEGBDX
                CMPI.W      #$4448,D5
                BLT         MAYBENEGWDX
                CMPI.W      #$4488,D5
                BLT         MAYBENEGLDX
                BRA         DATACASE        ;if it's none of the above, it's data
                
MAYBENEGBDX     CMPI.W      #$4400,D5        ;check if between 4400-4407
                BLT         DATACASE        ;if not it's data
                MOVE.L      #14,D0          ;otherwise it's NEG.B Dx
                TRAP        #15             ;print "NEG"
                LEA         BYTEEND,A1
                TRAP        #15             ;now printed "NEG.B  "
                LEA         DATAREG,A1
                TRAP        #15             ;now printed "NEG.B  D"
                SUBI.W      #$4400,D5       ;d5 is now going to store which reg you actually have since D5-4400 = reg value
                CLR.L       D1              ;prep D1 for storage
                MOVE.W      D5,D1           ;move the D5 value to D1
                MOVE.L      #3,D0           ;load trap task 3
                TRAP        #15             ;now printed "NEG.B  Dx"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;onto the next instruction
                
                
MAYBENEGWDX     CMPI.W      #$4440,D5       ;Check if it's between 4440-4447
                BLT         DATACASE        ;if not it's data
                MOVE.L      #14,D0          ;otherwise it's NEG.W Dx
                TRAP        #15             ;print "NEG"
                LEA         WORDEND,A1
                TRAP        #15             ;now printed "NEG.W  "
                LEA         DATAREG,A1
                TRAP        #15             ;now printed "NEG.W  D"
                SUBI.W      #$4440,D5       ;d5 is now going to store which reg you actually have since D5-4400 = reg value
                CLR.L       D1              ;prep D1 for storage
                MOVE.W      D5,D1           ;move the D5 value to D1
                MOVE.L      #3,D0           ;load trap task 3
                TRAP        #15             ;now printed "NEG.W  Dx"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;onto the next instruction
                
MAYBENEGLDX     CMPI.W      #$4480,D5        ;check if between 4480-4487
                BLT         DATACASE        ;if not it's data
                MOVE.L      #14,D0          ;otherwise it's NEG.L Dx
                TRAP        #15             ;print "NEG"
                LEA         LONGEND,A1
                TRAP        #15             ;now printed "NEG.L  "
                LEA         DATAREG,A1
                TRAP        #15             ;now printed "NEG.L  D"
                SUBI.W      #$4480,D5       ;d5 is now going to store which reg you actually have since D5-4400 = reg value
                CLR.L       D1              ;prep D1 for storage
                MOVE.W      D5,D1           ;move the D5 value to D1
                MOVE.L      #3,D0           ;load trap task 3
                TRAP        #15             ;now printed "NEG.L  Dx"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;onto the next instruction
                
                
POSSIBLENEGB    CMPI.W      #$4410,D5       ;this is final test if between 4410-441F
                BLT         DATACASE        ;if it's not, it's data
                *from here on out we know it's a NEG.B of (An) or (An)+. which depends on final nybble.
                *NEG is still stored in A1
                MOVE.L      #14,D0
                TRAP        #15             ;print "NEG"
                LEA         BYTEEND,A1      
                TRAP        #15             ;have now printed "NEG.B  "
                CLR.L       D6              ;make sure D6 is blank
                MOVE.W      D5,D6           ;move D5's value into D6 as a temp
                SUBI.W      #$4410,D6       ;this will make D6 have the value of 0-F. if it's 0-7, it's gonna be an A(n) thing, 8-F, (An)+
                CMPI.B      #$8,D6      
                BLT         NEGANCASE       ;it's less, so it's A(n).
                BRA         NEGINCANCASE    ;otherwise it's 8-F so (An)+ case


POSSIBLENEGW    CMPI.W      #$4450,D5   ;this is final test of it it's between 4450 and 445F
                BLT         DATACASE    ;if it's not, it's data
                *from here on out we know it's a NEG.W of (An) or (An)+. which depends on final nybble
                *NEG is still stored in A1
                MOVE.L      #14,D0
                TRAP        #15             ;print "NEG"
                LEA         WORDEND,A1      
                TRAP        #15             ;have now printed "NEG.W  "
                CLR.L       D6              ;make sure D6 is blank
                MOVE.W      D5,D6           ;move D5's value into D6 as a temp
                SUBI.W      #$4450,D6       ;this will make D6 have the value of 0-F. if it's 0-7, it's gonna be an A(n) thing, 8-F, (An)+
                CMPI.B      #$8,D6      
                BLT         NEGANCASE       ;it's less, so it's A(n).
                BRA         NEGINCANCASE    ;otherwise it's 8-F so (An)+ case

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
                SUBI.W      #$4490,D6       ;this will make D6 have the value of 0-F. if it's 0-7, it's gonna be an A(n) thing, 8-F, (An)+
                CMPI.B      #$8,D6      
                BLT         NEGANCASE       ;it's less, so it's A(n).
                BRA         NEGINCANCASE    ;otherwise it's 8-F so (An)+ case
                
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

            *the resulting output will be NEG.X (An)+
NEGINCANCASE    LEA         INDIRECTADAB,A1
                TRAP        #15             ;will now have printed "NEG.X  (A"
                *D6 will currently contain n+8.
                SUBI.W      #8,D6           ;fix that offset by subtracting 8
                CLR.L       D1              ;clear out D1
                MOVE.W      D6,D1           ;move the D6 value into D1 for trap task
                MOVE.L      #3,D0           ;load trap task 3
                TRAP        #15             ;have now printed "NEG.X  (An"
                LEA         INCREMENTEND,A1
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "NEG.X (An)+"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;onto the next instruction
                
                
*********************************************************************************  END OF NEG ISNTRUCTION DISASSAMEBLY **************************************************************************










********************************************************************************* START OF ASL/ASR/LSL/LSR DISSASSEMBLY ***************************************************************************

ALSLRPTONE      MOVEM       (SP)+,D5        ;reload the correct D5 (instruction) value you had altered prior
                MOVEM       D5,-(SP)        ;now save the correct value again
                
ALSLRMEMSHIFT   MOVE.W      #$E0D0,D6        ;check for a mem shift first
                CMP.W       D6,D5           ;if D5 is between E0D0 and E0EF, it's a mem ASR
                *NOTE it's not E0C0 because the min 3rd nybble is 1101, not 1100 due to available EA modes
                    *thus min you can have is E0D0
                BLT         ALSLRREGSHIFT   ;if not between, check if it's a reg shift
                MOVE.W      #$E0E8,D6
                *NOTE it's not E0FF because due to available EA modes, the max 3rd nybble is 1110, not 1111
                    *if you have 1110 as you're 3rd nybble, the 4th nybble has to start with 0, so the max
                    *4th nybble is 0111, thus the max value you can have is E0E7
                CMP.W       D6,D5
                BLT         ASRMEM          ;if it passes those checks, it's an ASR mem shift
                
                MOVE.W      #$E1D0,D6        ;If D5 is between E1D0 and E1EF, it's a mem ASL
                CMP.W       D6,D5
                BLT         ALSLRREGSHIFT   ;if not between, check if it's a reg shift
                MOVE.W      #$E1E8,D6
                CMP.W       D6,D5
                BLT         ASLMEM          ;if it passes those checks, it's an ASL mem shift
                
                MOVE.W      #$E2D0,D6        ;If D5 is between E2D0 and E2EF, it's a mem LSR
                CMP.W       D6,D5
                BLT         ALSLRREGSHIFT   ;if not between, check if it's a reg shift
                MOVE.W      #$E2E8,D6
                CMP.W       D6,D5
                BLT         LSRMEM          ;if it passes those checks, it's an LSR mem shift

                MOVE.W      #$E3D0,D6        ;If D5 is between E3D0 and E3EF, it's a mem LSL
                CMP.W       D6,D5
                BLT         ALSLRREGSHIFT   ;if not between, check if it's a reg shift
                MOVE.W      #$E3E8,D6
                CMP.W       D6,D5
                BLT         LSLMEM          ;if it passes those checks, it's an LSL mem shift
                BRA         ALSLRREGSHIFT   ;if it doesn't pass any of those checks, try seeing if it's a reg shift


                *Potentially a ASL/ASR/LSL/LSR register shift instruction, potentially data
                *Format of valid sutff will be $E(0-F)(0-A, even)(0-F)
                    *if the final nybble is 0-7, it's Logical Shift, 8-F is Arithmetic Shift
                    *if the second nybble is even, it's a Right Shift, if it's odd, it's a Left Shift
                    *for the 3rd nybble: 0,2 is .B     4,6 is .W       8,A is .L
ALSLRREGSHIFT   CLR.L       D6              ;start by checking validity of nybble 3 being below B
                MOVE.B      #$AF,D6         ;B0 is +1 of the max value allowed in the byte space
                CMP.B       D6,D5
                BGT         DATACASE
                CLR.B       D6              ; now check if the 3rd nybble is even, and then it is for sure a reg shift
                MOVE.B      D5,D6           ; 3rd nybble last bit MUST be 0 - plus you already know it's A or lower
                LSL.B       #3,D6           ; shift the bits left such that the last bit is the new MSB of the byte
                ANDI.B      #$80,D6         ;and with %1000|0000 to make things simpler and just worry about MSB
                CMP.B       #0,D6           ;if the byte is not equal to 0 at this point, it was an odd value
                BNE         DATACASE
                CLR.B       D6              ;next is to see which size shift it is
                MOVE.B      #$30,D6
                CMP.B       D6,D5           ;If D5's final byte is below 30 (ie, first nybble is 0 or 2)
                BLT         ALSLRREGBYTE    ;it's a .B shift
                CLR.B       D6
                MOVE.B      #$70,D6         ;if it's below 70 (ie, first nybble is 4 or 6)
                CMP.B       D6,D5           ;it's a .W shift
                BLT         ALSLRREGWORD
                CLR.B       D6
                MOVE.B      #$B0,D6         ;finally, it's going to be a long, but let's check anyway as a failsafe
                CMP.B       D6,D5
                BLT         ALSLRREGLONG
                BRA         DATACASE        ;this line should never be called
                
               
            *For the next cases, we need to determine the direction of the shift, then the register shifted
                *if the second nybble is even, it's a Right Shift, if it's odd, it's a Left Shift                 
ALSLRREGBYTE    CLR.L       D6
                MOVE.W      D5,D6           ;using similar logic to before, let's check if second nybble is even or odd 
                LSL.W       #7,D6
                ANDI.W      #$8000,D6
                CMP         #0,D6
                BEQ         ALSRBYTE        ;if it's even (=0), then it's either ASR or LSR
                BRA         ALSLBYTE        ;Otherwise it's ASL or LSL
                
                *next is to determine if it's a Arithmetic or Logical shift
                *if the final nybble is 0-7, it's Logical, otherwise Arithmetic
         *_SR.B D_
ALSRBYTE        CLR.L       D6              ;clear D6 out
                MOVE.B      D5,D6           ;move the last byte to D6
                *now we know the 3rd nybble is either 0 or 2... kinda useless so shifting
                LSL.B       #4,D6
                CMPI.B      #$80,D6     ;if >= Arithmetic, if lower, Logical
                BLT         LSRBYTE
        *Below two cases, it's for sure that instruction, so figure out if it's going to take a
         * register or immediate, based on the 3rd bit of the 3rd nybble. if it's 0 it's immediate, 1: data reg
          *if immediate, 2nd nybble's first 3 bits determine the amount, with 0 meaning 8
          *else if it's register, it determines which register
        *The final 3 bits of the last nybble determine the data reg being shifted.
ASRBYTE         LEA         ASRMESSAGE,A1       ;start by printing the ASR.B since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "ASR"
                LEA         BYTEEND,A1
                TRAP        #15                 ;printed "ASR.B  "
                
                
LSRBYTE         LEA         LSRMESSAGE,A1       ;start by printing the LSR.B since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "LSR"
                LEA         BYTEEND,A1
                TRAP        #15                 ;printed "LSR.B  "
                
        *_SL.B D_   
ALSLBYTE            

*eveyrthing above this can work for the below cases, just need to change what's being printed I think    
ALSLRREGWORD
ALSLRREGLONG


        *Almost confirmed for all cases below to be that particular instruction, just need to parse out the EA mode and Reg
            *last 6 bits - last byte comparisions needed. Min value $D0, max value $E7
       *ASR is going to be between E0D0, E0EF
ASRMEM          CLR.L       D6              ;clear D6
                MOVE.B      #$E0,D6
                CMP.B       D6,D5           ;check if D5 (instruciton) is between E0D0 and E0DF (checking if 3rd nybble is D)
                BLT         ASRTHREED
                CLR.B       D6              ;clear D6 again
                MOVE.B      #$E7,D6         ;check if D5 is between E0E0 and E0E7 otherwise
                CMP.B       D6,D5
                BGT         DATACASE        ;if it's greater, it's data
                
                *henseforth we know that the instruction is E0E(0-7), meaning -(An), where n is between 0-7
                    *n is determined by the last 3 bits
                CLR.B       D6              ;more D6 clearing
                MOVE.B      #$E0,D6         ;store minimum D5 value into D6
                SUB.B       D6,D5           ;D5.B now contains the register number (0-7)
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         ASRMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "ASR"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "ASR  "
                LEA         INDIRECTADDECB,A1
                TRAP        #15             ;have now printed "ASR  -(A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "ASR  -(An"
                LEA         CLOSEPAREN,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "ASR  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
           *ASR is going to be between E0D0-E0DF
ASRTHREED       CLR.B       D6              ;more D6 clearing
                MOVE.B      #$D0,D6         ;store minimum D5 value into D6
                SUB.B       D6,D5           ;D5.B now contains the register number (0-F)
                CMPI.B      #7,D5
                BGT         ASRMEMANPLUS    ;branch if reg value > 7
                *this is now for cases of ASR (An)
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         ASRMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "ASR"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "ASR  "
                LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "ASR  -(A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "ASR  -(An"
                LEA         CLOSEPAREN,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "ASR  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction

                
                *The below case is for ASR (An)+
ASRMEMANPLUS    SUBI.B      #8,D5           ;sub 8 from D5 to get register value
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         ASRMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "ASR"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "ASR  "
                LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "ASR  (A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "ASR  (An"
                LEA         INCREMENTEND,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "ASR  (An)+"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction



        *ASL is going to be between E1D0, E1EF
ASLMEM          CLR.L       D6              ;clear D6
                MOVE.B      #$E0,D6
                CMP.B       D6,D5           ;check if D5 (instruciton) is between E1D0 and E1DF (checking if 3rd nybble is D)
                BLT         ASLTHREED
                CLR.B       D6              ;clear D6 again
                MOVE.B      #$E7,D6         ;check if D5 is between E1E0 and E1E7 otherwise
                CMP.B       D6,D5
                BGT         DATACASE        ;if it's greater, it's data
                
                *henseforth we know that the instruction is E1E(0-7), meaning -(An), where n is between 0-7
                    *n is determined by the last 3 bits
                CLR.B       D6              ;more D6 clearing
                MOVE.B      #$E0,D6         ;store minimum D5 value into D6
                SUB.B       D6,D5           ;D5.B now contains the register number (0-7)
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         ASLMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "ASL"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "ASL  "
                LEA         INDIRECTADDECB,A1
                TRAP        #15             ;have now printed "ASL  -(A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "ASL  -(An"
                LEA         CLOSEPAREN,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "ASL  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
           *ASL is going to be between E1D0-E1DF
ASLTHREED       CLR.B       D6              ;more D6 clearing
                MOVE.B      #$D0,D6         ;store minimum D5 value into D6
                SUB.B       D6,D5           ;D5.B now contains the register number (0-F)
                CMPI.B      #7,D5
                BGT         ASLMEMANPLUS    ;branch if reg value > 7
                *this is now for cases of ASL (An)
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         ASLMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "ASL"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "ASL  "
                LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "ASL  -(A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "ASL  -(An"
                LEA         CLOSEPAREN,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "ASL  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction

                
                *The below case is for ASL (An)+
ASLMEMANPLUS    SUBI.B      #8,D5           ;sub 8 from D5 to get register value
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         ASLMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "ASL"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "ASL  "
                LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "ASL  (A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "ASL  (An"
                LEA         INCREMENTEND,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "ASL  (An)+"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction



        *LSR is going to be between E2D0,E2EF
LSRMEM          CLR.L       D6              ;clear D6
                MOVE.B      #$E0,D6
                CMP.B       D6,D5           ;check if D5 (instruciton) is between E2D0 and E2DF (checking if 3rd nybble is D)
                BLT         LSRTHREED
                CLR.B       D6              ;clear D6 again
                MOVE.B      #$E7,D6         ;check if D5 is between E2E0 and E2E7 otherwise
                CMP.B       D6,D5
                BGT         DATACASE        ;if it's greater, it's data
                
                *henseforth we know that the instruction is E2E(0-7), meaning -(An), where n is between 0-7
                    *n is determined by the last 3 bits
                CLR.B       D6              ;more D6 clearing
                MOVE.B      #$E0,D6         ;store minimum D5 value into D6
                SUB.B       D6,D5           ;D5.B now contains the register number (0-7)
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         LSRMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "LSR"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "LSR  "
                LEA         INDIRECTADDECB,A1
                TRAP        #15             ;have now printed "LSR  -(A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "LSR  -(An"
                LEA         CLOSEPAREN,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "LSR  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
           *LSR is going to be between E2D0-E2DF
LSRTHREED       CLR.B       D6              ;more D6 clearing
                MOVE.B      #$D0,D6         ;store minimum D5 value into D6
                SUB.B       D6,D5           ;D5.B now contains the register number (0-F)
                CMPI.B      #7,D5
                BGT         LSRMEMANPLUS    ;branch if reg value > 7
                *this is now for cases of LSR (An)
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         LSRMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "LSR"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "LSR  "
                LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "LSR  -(A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "LSR  -(An"
                LEA         CLOSEPAREN,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "LSR  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction

                
                *The below case is for ASR (An)+
LSRMEMANPLUS    SUBI.B      #8,D5           ;sub 8 from D5 to get register value
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         LSRMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "LSR"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "LSR  "
                LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "LSR  (A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "LSR  (An"
                LEA         INCREMENTEND,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "LSR  (An)+"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction




        *LSL is going to be between E3D0,E3EF
LSLMEM          CLR.L       D6              ;clear D6
                MOVE.B      #$E0,D6
                CMP.B       D6,D5           ;check if D5 (instruciton) is between E3D0 and E3DF (checking if 3rd nybble is D)
                BLT         LSLTHREED
                CLR.B       D6              ;clear D6 again
                MOVE.B      #$E7,D6         ;check if D5 is between E3E0 and E3E7 otherwise
                CMP.B       D6,D5
                BGT         DATACASE        ;if it's greater, it's data
                
                *henseforth we know that the instruction is E3E(0-7), meaning -(An), where n is between 0-7
                    *n is determined by the last 3 bits
                CLR.B       D6              ;more D6 clearing
                MOVE.B      #$E0,D6         ;store minimum D5 value into D6
                SUB.B       D6,D5           ;D5.B now contains the register number (0-7)
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         LSLMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "LSL"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "LSL  "
                LEA         INDIRECTADDECB,A1
                TRAP        #15             ;have now printed "LSL  -(A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "LSL  -(An"
                LEA         CLOSEPAREN,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "LSL  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
           *LSL is going to be between E3D0-E3DF
LSLTHREED       CLR.B       D6              ;more D6 clearing
                MOVE.B      #$D0,D6         ;store minimum D5 value into D6
                SUB.B       D6,D5           ;D5.B now contains the register number (0-F)
                CMPI.B      #7,D5
                BGT         LSLMEMANPLUS    ;branch if reg value > 7
                *this is now for cases of ASL (An)
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         LSLMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "LSL"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "LSL  "
                LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "LSL  -(A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "LSL  -(An"
                LEA         CLOSEPAREN,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "LSL  -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction

                
                *The below case is for LSL (An)+
LSLMEMANPLUS    SUBI.B      #8,D5           ;sub 8 from D5 to get register value
                CLR.L       D1
                MOVE.B      D5,D1           ;move reg value to D1 for printing later
                
                LEA         LSLMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15            ;have now printed "LSL"
                LEA         DOUBLESPACE,A1      ;since mem shifts don't specify sizes, add the double space
                TRAP        #15             ;have now printed "LSL  "
                LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "LSL  (A"
                MOVE.B      #3,D0
                TRAP        #15             ; have now printed "LSL  (An"
                LEA         INCREMENTEND,A1
                MOVE.B      #14,D0
                TRAP        #15             ;have now printed "LSL  (An)+"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction





********************************************************************************* END OF ASL/ASR/LSL/LSR DISSASSEMBLY ***************************************************************************





*Stop program
ENDCASE         SIMHALT             ; halt simulator


*currently tests: NOP, NEG, JSR, RTS
TESTCODE        *test for NOP below
                NOP
                *tests for NEG below
                NEG.B       D0      
                NEG.W       D1
                NEG.L       D3
                NEG.B       (A0)
                NEG.W       (A1)
                NEG.L       (A2)
                NEG.B       (A3)+
                NEG.W       (A4)+
                NEG.L       (A5)+
                NEG.B       -(A6)
                NEG.W       -(A7)
                NEG.L       -(A0)
                NEG.W       $FFFFFFFF
                NEG.L       $FFFFFFFF
                *tests for JSR below
                RTS
                JSR         ENDCASE     ;honestly not sure which mode this tests. (xxx).L?
                JSR         (A1)
                JSR         $FFFFFFFF  ;maybe?
                *still need more JSR tests
                
                *test for RTS
                RTS
                
                *Test for ASL, ASR, LSL, LSR
                ASL.B       #1,D0           ;reg shift
                ASL.W       D1,D2           ;reg shift
                ASL.L       D3,D4           ;reg shift
                ASL         (A0)            ;mem shift
                ASL         (A1)+           ;mem shift
                ASL         -(A2)           ;mem shift
                
                LSL.B       #2,D5           ;reg shift
                LSL.W       D6,D7           ;reg shift
                LSL.L       #3,D0           ;reg shift
                LSL         (A3)            ;mem shift
                LSL         (A4)+           ;mem shift
                LSL         -(A5)           ;mem shift
                
                ASR.B       #4,D1           ;reg shift
                ASR.W       D2,D3           ;reg shift
                ASR.L       D4,D5           ;reg shift
                ASR         (A6)            ;mem shift
                ASR         (A7)+           ;mem shift
                ASR         -(A0)           ;mem shift
                
                LSR.B       #5,D6           ;reg shift
                LSR.W       D7,D0           ;reg shift
                LSR.L       #6,D1           ;reg shift
                LSR         (A1)            ;mem shift
                LSR         (A2)+           ;mem shift
                LSR         -(A3)           ;mem shift
                

* Put variables and constants here

STACKADDRESS    EQU         $7000    ;marks the location of the start of the stack

*various instruction's hex values (or partial hex values) are stored here
NOPCODE         EQU         $4E71       ;hex version of the NOP
RTSCODE         EQU         $4E75       ;Hex version of RTS
JSRSTARTBYTE    EQU         $4E         ;next two digits are 10+ EA Mode first 2 digits, final four are EA Mode final digit(1) and EA register (3)
NEGSTARTBYTE    EQU         $44         ;starting byte of NEG - next two bits are size, next 3 are EA mode, last 3 are EA reg
ALSRLSTARTNYBLE EQU         $E          ;starting nybble for ASL/ASR/LSL/LSR. next nybble determines reg/mem shift

NOMORECODE      EQU         $FFFF   ;if A1 = this, then you've hit the end. I think



*Below are output messages
NOPMESSAGE      DC.L        'NOP',0
DATAMESSAGE     DC.L        'Data',0
NEGMESSAGE      DC.L        'NEG',0       
JSRMESSAGE      DC.L        'JSR  ',0       ;spaces are intentional for easier time adding the EAs after
RTSMESSAGE      DC.L        'RTS',0
ASRMESSAGE      DC.L        'ASR',0
ASLMESSAGE      DC.L        'ASL',0
LSRMESSAGE      DC.L        'LSR',0
LSLMESSAGE      DC.L        'LSL',0

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
NEWLINE         DC.L        '',CR           ;for making a newline
DOUBLESPACE     DC.L        '  ',0          ;needed to make a double space in some circumstances 

                END         START        ; last line of source












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
