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
                
*Ask for the address to disassemble from

STARTINGQ       LEA         WHERETOSTART,A1
                MOVE.B      #13,D0
                TRAP        #15
                *MOVE.B      #13,D0
                LEA         WHERETOSTARTPT,A1
                TRAP        #15
                LEA         WHERETOSTARTPTO,A1
                TRAP        #15
                LEA         WHERETOSTARTPTT,A1
                TRAP        #15
GETTHEINPUT     MOVE.B      #2,D0
                TRAP        #15         ;string of input is now stored in (A1)
                CLR.L       D1          ;make sure D1 stays empty
                
STRINGTONUMB    ADDI.B      #1,D4       ;break the cycle after D4 hits 8 
                MOVE.B      (A1)+,D3    ;TRANSLATE a byte at a time from string to hex 
                                        ;only check a nybble at a time though
                CMPI.B      #$46,D3      ;upper bound for hex 
                BHI         MAKEZERO        ;if higher, invalid inpt
                CMPI.B      #$41,D3      ;lower bound for hex
                BCC         HEXTRANSLATE
                CMPI.B      #$40,D3      ;upper bound for decimal
                BHI         MAKEZERO    ;if higher, invalid input - this shouldnt happen since checks for hex were earlier$
                CMPI.B      #$30,D3      ;lower bound for decimal
                BCC         DECIMALTRANS
                BRA         MAKEZERO       ;invalid input, lowet han #30

MAKEZERO        LSL.L       #4,D1
                ADD.B       #0,D1           ;just put a 0 for invalid input
                CMPI.B      #$8,D4
                BEQ         CHECKEVEN
                BRA         STRINGTONUMB

DECIMALTRANS    SUBI.B      #$30,D3          ;get the actual dec val
                LSL.L       #4,D1
                ADD.B       D3,D1           ;move it to d1 which holds actual address
                CMPI.B      #$8,D4
                BEQ         CHECKEVEN       ;see if you've examined every byte yet, branch here if you have
                BRA         STRINGTONUMB    

HEXTRANSLATE    SUBI.B      #$37,D3          ;get the actual hex val
                LSL.L       #4,D1
                ADD.B       D3,D1
                CMPI.B      #$8,D4
                BEQ         CHECKEVEN
                BRA         STRINGTONUMB         
                
CHECKEVEN       MOVE.B      D1,D2           ;TEST if even
                ANDI.B      #$01,D2
                CLR.B       D4              ;clear in case you need to re-do input gathering
                CMPI.B      #0,D2
                BEQ         STARTDONE       ;if it's 0, it's even
REINPUT         LEA         NOTEVEN,A1
                MOVE.B      #13,D0
                TRAP        #15
                BRA         STARTINGQ
STARTDONE       
                CLR.L       D0
                MOVEA.L      D1,A2
                *LEA         (A1),A2
                CLR.L       D1
                
                
                
*Get the location of the test code
                *LEA         TESTCODE,A2         ; load address of the testcode
                
*start the actual disassembly below
LOOPSTART       ADDI.B 		#1,D7
				CMPI.B 		#31,D7
				BEQ 		WAITFORINPUT
				CLR.L       D5              ;clear out D5 in prep for the next instruction's load
                MOVE.W      (A2)+,D5    ;move the current code into D5, then increment - this cant probably be changed so you just read (A1) and increment later.. but that's a case for optimizing

*Compare the testinput wth the NOP code
*Need to change this to be a while there's still code... end of code should be 00000000 i think
*   basically, while current != SIMHALT == $00000000?
                *CMPI.L      #NOMORECODE,D5      ;end of instructions, branch to program end
                *BEQ         ENDCASE
                
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
                MOVE.W      #NEGSTARTBYTE,D6     ;move the starting byte into D6
                ROL         #8,D6               ;rotate bytes so they're actually in the front, D6 is now 4400
                CMP.W       D6,D5               ;compare the instrcution code to 4400
                BCS         ALSLRCMP           ;if D5 is less, it's not NEG
                CMPI.W      #$4500,D5
                BCS         NEGCASE             ;if it's less than 4500, greater or equal to 4400, check neg
                 
                *ASL/ASR/LSL/LSR starts with $E
ALSLRCMP        CLR.L       D6          ;reset D6
                MOVE.W      #ALSRLSTARTNYBLE,D6     ;move the starting nybble into D6
                LSL         #8,D6                   ;do max rotation
                LSL         #4,D6                   ;do another rotation such that you have $E000
                MOVEM       D5,-(SP)                ;store the real D5 value for safekeeping
                AND.W       D6,D5                   ;AND D5 (instruction) with D6 ($E000)
                CMP.W       D6,D5                   ;if both D5 & D6 are equal, branch out to possible ALSLR checks
                BEQ         ALSLRPTONE              
                MOVEM       (SP)+,D5                ;otherwise, reload the stack as it should be and move on
                
                *BRA start byte is $60
BRACMP          CLR.L       D6                      ;clear out D6
                MOVE.W      #BRASTARTBYTE,D6        ;move starting byte to D6
                LSL         #8,D6                   ;move the byte to the starting position of the word
                CMP.W       D6,D5
                BCS         CMPEORCMP               ;if it's less than that, go to next non-branch comparison
                CLR.W       D6
                MOVE.W      #$6100,D6
                CMP.W       D6,D5                   ;check if it's lower than $6100
                BCS         BRACASE                 ;if it's between $6000 and $6100, it's a BRA
                
                *BCS start byte is $65
BCSCMP          CLR.W       D6                      ;clear out D6
                MOVE.W      #BCSSTARTBYTE,D6        ;put the start byte into D6
                LSL         #8,D6                   ;rotate that byte to the front of the word
                CMP.W       D6,D5                   
                BCS         CMPEORCMP               ;if it's less than that, go to next non-branch comparison
                CLR.W       D6
                MOVE.W      #$6600,D6
                CMP.W       D6,D5                   ;check if it's lower than $6100
                BCS         BCSCASE                 ;if it's between $6500 and $6600, it's a BCS

                *BVC start byte is $68
BVCCMP          CLR.W       D6                      ;clear out D6
                MOVE.W      #BVCSTARTBYTE,D6        ;put the start byte into D6
                LSL         #8,D6                   ;rotate that byte to the front of the word
                CMP.W       D6,D5                   
                BCS         CMPEORCMP                ;if it's less than that, go to next non-branch comparison
                CLR.W       D6
                MOVE.W      #$6900,D6
                CMP.W       D6,D5                   ;check if it's lower than $6900
                BCS         BVCCASE                 ;if it's between $6800 and $6900, it's a BCS

                *BGE start byte is $6C
BGECMP          CLR.W       D6                      ;clear out D6
                MOVE.W      #BGESTARTBYTE,D6        ;put the start byte into D6
                LSL         #8,D6                   ;rotate that byte to the front of the word
                CMP.W       D6,D5                   
                BCS         CMPEORCMP                ;if it's less than that, go to next non-branch comparison
                CLR.W       D6
                MOVE.W      #$6D00,D6
                CMP.W       D6,D5                   ;check if it's lower than $6D00
                BCS         BGECASE                 ;if it's between $6C00 and $6D00, it's a BCS

                *BLT start byte is $6D
BLTCMP          CLR.W       D6                      ;clear out D6
                MOVE.W      #BLTSTARTBYTE,D6        ;put the start byte into D6
                LSL         #8,D6                   ;rotate that byte to the front of the word
                CMP.W       D6,D5                   
                BCS         CMPEORCMP                ;if it's less than that, next non-branch comparison
                CLR.W       D6
                MOVE.W      #$6E00,D6
                CMP.W       D6,D5                   ;check if it's lower than $6E00
                BCS         BLTCASE                 ;if it's between $6D00 and $6E00, it's a BCS

                *EOR and CMP have the same start nybble (B). if the second nybble is odd, it's EOR, otherwise CMP
CMPEORCMP       CLR.W       D6                      ;clear out D6
                MOVE.W      #CMPEORNYBBLE,D6        ;move the nybble into D6
                LSL         #8,D6
                LSL         #4,D6                   ;move the nybble to the front of the word
                CMP         D6,D5
                BCS         CMPICMP               ;if it's less than $B000, it's neither so check the next instruction
                CLR.W       D6
                MOVE.W      #$C000,D6
                CMP         D6,D5                   ;check if D5 is less than $C000 - that is, it's between $B000-BFFFF
                BCC         CMPICMP                ;if it's greater or equl than $C000, go to next instruction 
                *now check if the second nybble of D5 is even or odd, since it's def EOR or CMP
				CLR.W 		D6
				MOVE.W 		D5,D6
				ANDI.W 		#$0100,D6 				;if after the ANDI, the result is 0, it means that D5's second nybble is even.  else it's odd
				CMP.W 		#$0000, D6
				BEQ			CMPCASE
				BRA 		EORCASE
                
                *start byte for CMPI is $0C
CMPICMP         CLR.W       D6
                MOVE.W      #CMPISTARTBYTE,D6
                LSL         #8,D6               ;move the start byte to the front of the word
                CMPI.W      #$0D00,D5          ;if D5 is equal or higher to that, it's not CMPI
                BCC         ORCMP
                CMP.W       D6,D5               ;otherwise just make sure it's equal to $0C00 or higher
                BCC         CMPICASE
                
		*OR start nybble is $8
ORCMP			CLR.W 		D6
				MOVE.W 		#ORSTARTNYBBLE,D6		;move starting nybble to D6
				LSL 		#8,D6
				LSL 		#4,D6 					;move the nybble to the front
				CMPI.W 		#$8FC0,D5				;max OR value is $8FBF
				BCC 		DATACASE 				;normally I'd branch to the next operation, but I know that the max val of the next case (ORI) is lower			******************SAMREEN YOU SHOULD CHECK THIS TO SEE IF IT STILL WORKS WITH YOUR CASE **************
				CMP.W 		D6,D5					;min OR value is $8000
				BCC			ORCASE					;if it's $8000 or higher (and sub $8FC0), it's OR
				
				

		*ORI start byte is $00
ORICMP			CLR.W 		D6
				MOVE.W 		#ORISTARTBYTE,D6
				LSL 		#8,D6 				;move starting byte to front of word
				CMPI.W 		#$00C0,D5
				BCC			DATACASE			;max ORI value is $00BF
				BRA 		ORICASE				;min ORI value is $0000, so you don't really need to test.
				
DATASTUFF       BRA         DATACASE        ; if it's not any of the above, it's just data			**************MAY BECOME UNNEEDED *********************************************************************************************************

LOOPEND         LEA         NEWLINE,A1           ;load carriage return val
                MOVE.L      #13,D0
                TRAP        #15             ;print out a new line so next instruction isn't on same line
                BRA         LOOPSTART       ;go back into the loop and check the next instruction value
               
				*this is used to display only 30 lines at a time, then it waits for the user to enter something before doing the next lines
WAITFORINPUT	LEA 		NEEDINPUT,A1
				MOVE.L 		#13,D0
				TRAP 		#15 		;display the message about needing input
				CLR.B 		D1 			;prep for trap task 7
				MOVE.L 		#7,D0
				TRAP 		#15 		;set up the task to wait for user input. D1.B should now equal 0.
TRAPAGAIN		MOVE.L 		#5,D0
				TRAP 		#15 		;the program is now set to check for user input
				CMPI.B 		#0,D1
				BEQ 		TRAPAGAIN 	;if there's no input, repeat till input
				MOVE.L 		#13,D0
				LEA 		NEWLINE,A1
				TRAP 		#15			;set it up so a new line seperates the input from the new dissassembled stuff
				CLR.B 		D1			;otherwise there was input, so you're good
				CLR.B 		D7			;clear out D7 so it can loop through again
				BRA 		LOOPSTART	;and we begin once more
				








**********************************************************************************************************************START OF NOP INSTRUCTION DISSASSEMBLY********************************************************************

*Mateched NOP
NOPCASE         LEA         NOPMESSAGE,A1       ;if the word matches NOP, display NOP
                MOVE.B      #14,D0
                TRAP        #15
                BRA         LOOPEND       ;Go do the next instruction now


**********************************************************************************************************************END OF NOP INSTRUCTION DISSASSEMBLY********************************************************************





**********************************************************************************************************************START OF DATA INSTRUCTION DISSASSEMBLY********************************************************************

*matched Data
DATACASE        CLR.L 		D1
                LEA         DOLLARSIGN,A1
                MOVE.L      #14,D0
                TRAP        #15
                MOVE.W 		(A2)+,D1
                MOVE.L      #15,D0
				MOVE.L 		#16,D2	
                TRAP        #15  
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
                MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				CLR.L 		D3
				MOVE.L      #16,D2          ;set up your D2 for outputting hex
                MOVE.L      #15,D0          ;load trap task 15
				MOVE.W      (A2)+,D3		;move the next word into D3
				CMP.W 		#$8000,D3		;check if you need to sign extend
				BCC 		JSRADDF
                CLR.L       D1              ;clear D1
                MOVE.L      D3,D1           ;move the data from D3 to D1

JSRABSWTRAP		TRAP 		#15				;have now printed "JSR $xxxx"
                
                BRA         LOOPEND         ;go to the next instruction
				
JSRADDF 		MOVE.L 		#$FFFFFFFF,D1 	;set the sign extension up
				MOVE.W 		D3,D1 			;move the rest of the word, then onto the print task
				BRA 		JSRABSWTRAP
               
 

               *JSR (xxx).L case
JSRXXXL         MOVE.L      #14,D0
                TRAP        #15     ;first print the "JSR  "
                LEA         DOLLARSIGN,A1
                TRAP        #15             ;have now printed "JSR  $"
                MOVEM       (SP)+,D5        ;reload register values since you're altering D5 value next
                CLR.L       D5
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
                LEA         INDIRECTADAB,A1
                TRAP        #15     ;print the "(A" part of the address reg
                
                *print whatever the result of anding to save the last 3 bits of the byte is
                ANDI.B      #$07,D5
                MOVE.B      D5,D1       ;move the result to D1
                MOVE.L      #3,D0       ;Trap task 3 prints signed number in D1.L
                TRAP        #15         ;have now printed (Ax
                LEA         CLOSEPAREN,A1
                MOVE.L      #14,D0
                TRAP        #15
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
                
                
                *not sure if it's (XXX).W quite yet - could be NEGADDREG which is (An) or (An)+
				*so i'm gonna check and branch to that code first
NEGXXX          MOVE.B 		D5,D4			;idc about anything except the byte's first nybble's last 2 bits
				ANDI.B 		#$30,D4			;so i isolate them
				CMPI.B 		#$10,D4			;if you're left with 0010 0000 after that, it's (An) or (An)+
				BEQ 		NEGADDREG
				;else it's either data or abs address
				CMPI.B 		#$0,D4
				BEQ 		NEGADDREG		;this also checks for data regs - thanks past me
				MOVE.B 		D5,D4 			;now it's def a abs address, so lets isolate the register to see which one, after we see the size
				MOVE.L 		#14,D0			;in neither of these cases have we printed "NEG" yet, but it's loaded into A1 still
				TRAP 		#15 			;now we've printed "NEG"
				
				ANDI.B 		#$C0,D4			;alright lets check for size now
				CMPI.B		#0,D4 			;if 0 it's a byte op
				BEQ 		NEGXXXBYTE
				CMPI.B 		#$40,D4
				BEQ 		NEGXXXWORD		; 0100 0000 = .W
NEGXXXLONG		LEA 		LONGEND,A1 	;else it's a long
				TRAP 		#15			;have printed "NEG.L  "
				BRA 		NEGXXXREGCHK
NEGXXXBYTE		LEA 		BYTEEND,A1
				TRAP 		#15 			;have printed "NEG.B  "
				BRA 		NEGXXXREGCHK
NEGXXXWORD		LEA 		WORDEND,A1
				TRAP		#15				;have printed "NEG.W  "
				
NEGXXXREGCHK	LEA 		DOLLARSIGN,A1 	;lets print the dollar now
				TRAP		#15 			;now printed "NEG.x  $"
				MOVE.L 		#16,D2 			;For trap task #15
				MOVE.L 		#15,D0			;preload this for later
				MOVE.B 		D5,D4
				ANDI.B 		#$07,D4 		;only care about last 3 bits
				CMPI.B 		#0,D4			;if result is 0, its (xxx).W
				BEQ 		NEGXXXW
				*else it's a xxx.L
NEGXXXL			MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				MOVE.L      (A2)+,D1		;move the whole long into D1
				TRAP 		#15				;printed "NEG.x  $xxxxxxx"

				BRA 		LOOPEND
				
NEGXXXW			MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				CLR.L 		D3
				MOVE.W      (A2)+,D3		;move the next word into D1
				CMP.W 		#$8000,D3		;check if you need to sign extend
				BCC 		NEGADDF
				CLR.L 		D1
				MOVE.W 		D3, D1			;Move into D1 to print

				

NEGABSWTRAP		TRAP 		#15				;have now printed "NEG.x  $xxxx"
                
                BRA         LOOPEND         ;go to the next instruction
				
NEGADDF 		MOVE.L 		#$FFFFFFFF,D1 	;set the sign extension up
				MOVE.W 		D3,D1 			;move the rest of the word, then onto the print task
				BRA 		NEGABSWTRAP
				
				
				

 *if prev (3rd) nybble was 1,5,9
                            *final nybble will be 0-7 for (An)
                            *or 8-F for (An)+
                            *1 is .B, 5 is .W, 9 is .L
            *Not sure yet if it is the instruction, but these are the final tests for NEG.X (An) or (An)+
            *Make sure to check from low->high and always BLT
            
            
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
                MOVE.B      #$AF,D6         ;AF is the max value allowed in the byte space
                CMP.B       D6,D5
                BHI         DATACASE
                CLR.B       D6              ; now check if the 3rd nybble is even, and then it is for sure a reg shift
                MOVE.B      D5,D6           ; 3rd nybble last bit MUST be 0 - plus you already know it's A or lower
                LSL.B       #3,D6           ; shift the bits left such that the last bit is the new MSB of the byte
                ANDI.B      #$80,D6         ;and with %1000|0000 to make things simpler and just worry about MSB
                CMP.B       #0,D6           ;if the byte is not equal to 0 at this point, it was an odd value
                BNE         DATACASE
                CLR.B       D6              ;next is to see which size shift it is
                MOVE.B      #$30,D6
                CMP.B       D6,D5           ;If D5's final byte is below 30 (ie, first nybble is 0 or 2)
                BCS         ALSLRREGBYTE    ;it's a .B shift
                CLR.B       D6
                MOVE.B      #$70,D6         ;if it's below 70 (ie, first nybble is 4 or 6)
                CMP.B       D6,D5           ;it's a .W shift
                BCS         ALSLRREGWORD
                CLR.B       D6
                MOVE.B      #$B0,D6         ;finally, it's going to be a long, but let's check anyway as a failsafe
                CMP.B       D6,D5
                BCS         ALSLRREGLONG
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
                LSL.B       #4,D6
                CMPI.B      #$80,D6     ;if >= Arithmetic, if lower, Logical
                BLT         LSRBYTE
                BRA         ASRBYTE
        *Below two cases, it's for sure that instruction, so figure out if it's going to take a
         * register or immediate, based on the 3rd bit of the 3rd nybble. if it's 0 it's immediate, 1: data reg
        *The final 3 bits of the last nybble determine the data reg being shifted.
ASRBYTE         LEA         ASRMESSAGE,A1       ;start by printing the ASR.B since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "ASR"
                LEA         BYTEEND,A1
                TRAP        #15                 ;printed "ASR.B  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         ASRBYTEIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         ASRBYTEREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
ASRBYTEIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "ASR.B  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACEASRBI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACEASRBI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "ASR.B  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASR.B  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASR.B  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASR.B  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
ASRBYTEREG      CLR.B       D6              ;remember you've already printed "ASR.B  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "ASR.B  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed ASR.B  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASR.B  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASR.B  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASR.B  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction


                
                
LSRBYTE         LEA         LSRMESSAGE,A1       ;start by printing the LSR.B since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "LSR"
                LEA         BYTEEND,A1
                TRAP        #15                 ;printed "LSR.B  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         LSRBYTEIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         LSRBYTEREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
LSRBYTEIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "LSR.B  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACELSRBI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACELSRBI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "LSR.B  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSR.B  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSR.B  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSR.B  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
LSRBYTEREG      CLR.B       D6              ;remember you've already printed "LSR.B  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "LSR.B  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed LSR.B  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSR.B  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSR.B  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSR.B  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
        *_SL.B D_   
ALSLBYTE        CLR.L       D6              ;clear D6 out
                MOVE.B      D5,D6           ;move the last byte to D6
                LSL.B       #4,D6
                CMPI.B      #$80,D6     ;if >= Arithmetic, if lower, Logical
                BLT         LSLBYTE
                BRA         ASLBYTE
        *Below two cases, it's for sure that instruction, so figure out if it's going to take a
         * register or immediate, based on the 3rd bit of the 3rd nybble. if it's 0 it's immediate, 1: data reg
        *The final 3 bits of the last nybble determine the data reg being shifted.
ASLBYTE         LEA         ASLMESSAGE,A1       ;start by printing the ASL.B since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "ASL"
                LEA         BYTEEND,A1
                TRAP        #15                 ;printed "ASL.B  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         ASLBYTEIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         ASLBYTEREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
ASLBYTEIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "ASL.B  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACEASLBI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACEASLBI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "ASL.B  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASL.B  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASL.B  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASL.B  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
ASLBYTEREG      CLR.B       D6              ;remember you've already printed "ASL.B  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "ASL.B  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed ASL.B  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASL.B  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASL.B  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASL.B  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction


                
                
LSLBYTE         LEA         LSLMESSAGE,A1       ;start by printing the LSL.B since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "LSL"
                LEA         BYTEEND,A1
                TRAP        #15                 ;printed "LSL.B  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         LSLBYTEIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         LSLBYTEREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
LSLBYTEIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "LSL.B  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACELSRBI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACELSLBI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "LSL.B  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSL.B  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSL.B  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSL.B  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
LSLBYTEREG      CLR.B       D6              ;remember you've already printed "LSL.B  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "LSL.B  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed LSL.B  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSL.B  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSL.B  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSL.B  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction

*eveyrthing above this can work for the below cases, just need to change what's being printed I think    
            *For the next cases, we need to determine the direction of the shift, then the register shifted
                *if the second nybble is even, it's a Right Shift, if it's odd, it's a Left Shift                 
ALSLRREGWORD    CLR.L       D6
                MOVE.W      D5,D6           ;using similar logic to before, let's check if second nybble is even or odd 
                LSL.W       #7,D6
                ANDI.W      #$8000,D6
                CMP         #0,D6
                BEQ         ALSRWORD        ;if it's even (=0), then it's either ASR or LSR
                BRA         ALSLWORD        ;Otherwise it's ASL or LSL
                
                *next is to determine if it's a Arithmetic or Logical shift
                *if the final nybble is 0-7, it's Logical, otherwise Arithmetic
         *_SR.B D_
ALSRWORD        CLR.L       D6              ;clear D6 out
                MOVE.B      D5,D6           ;move the last byte to D6
                LSL.B       #4,D6
                CMPI.B      #$80,D6     ;if >= Arithmetic, if lower, Logical
                BLT         LSRWORD
                BRA         ASRWORD
        *Below two cases, it's for sure that instruction, so figure out if it's going to take a
         * register or immediate, based on the 3rd bit of the 3rd nybble. if it's 0 it's immediate, 1: data reg
        *The final 3 bits of the last nybble determine the data reg being shifted.
ASRWORD         LEA         ASRMESSAGE,A1       ;start by printing the ASR.W since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "ASR"
                LEA         WORDEND,A1
                TRAP        #15                 ;printed "ASR.W  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         ASRWORDIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         ASRWORDREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
ASRWORDIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "ASR.W  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACEASRWI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACEASRWI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "ASR.W  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASR.W  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASR.W  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASR.W  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
ASRWORDREG      CLR.B       D6              ;remember you've already printed "ASR.W  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "ASR.W  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed ASR.W  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASR.W  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASR.W  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASR.W  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction


                
                
LSRWORD         LEA         LSRMESSAGE,A1       ;start by printing the LSR.W since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "LSR"
                LEA         WORDEND,A1
                TRAP        #15                 ;printed "LSR.W  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         LSRWORDIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         LSRWORDREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
LSRWORDIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "LSR.W  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACELSRWI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACELSRWI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "LSR.W  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSR.W  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSR.W  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSR.W  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
LSRWORDREG      CLR.B       D6              ;remember you've already printed "LSR.W  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "LSR.W  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed LSR.W  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSR.W  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSR.W  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSR.W  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
        *_SL.W D_   
ALSLWORD        CLR.L       D6              ;clear D6 out
                MOVE.B      D5,D6           ;move the last byte to D6
                LSL.B       #4,D6
                CMPI.B      #$80,D6     ;if >= Arithmetic, if lower, Logical
                BLT         LSLWORD
                BRA         ASLWORD
        *Below two cases, it's for sure that instruction, so figure out if it's going to take a
         * register or immediate, based on the 3rd bit of the 3rd nybble. if it's 0 it's immediate, 1: data reg
        *The final 3 bits of the last nybble determine the data reg being shifted.
ASLWORD         LEA         ASLMESSAGE,A1       ;start by printing the ASL.W since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "ASL"
                LEA         WORDEND,A1
                TRAP        #15                 ;printed "ASL.W  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         ASLWORDIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         ASLWORDREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
ASLWORDIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "ASL.W  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACEASLWI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACEASLWI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "ASL.W  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASL.W  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASL.W  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASL.W  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
ASLWORDREG      CLR.B       D6              ;remember you've already printed "ASL.W  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "ASL.W  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed ASL.W  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASL.W  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASL.W  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASL.W  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction


                
                
LSLWORD         LEA         LSLMESSAGE,A1       ;start by printing the LSL.W since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "LSL"
                LEA         WORDEND,A1
                TRAP        #15                 ;printed "LSL.W  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         LSLWORDIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         LSLWORDREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
LSLWORDIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "LSL.W  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACELSRWI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACELSLWI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "LSL.W  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSL.W  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSL.W  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSL.W  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
LSLWORDREG      CLR.B       D6              ;remember you've already printed "LSL.W  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "LSL.W  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed LSL.W  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSL.W  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSL.W  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSL.W  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction

				
			*Longs
ALSLRREGLONG	CLR.L       D6
                MOVE.W      D5,D6           ;using similar logic to before, let's check if second nybble is even or odd 
                LSL.W       #7,D6
                ANDI.W      #$8000,D6
                CMP         #0,D6
                BEQ         ALSRLONG        ;if it's even (=0), then it's either ASR or LSR
                BRA         ALSLLONG        ;Otherwise it's ASL or LSL
                
                *next is to determine if it's a Arithmetic or Logical shift
                *if the final nybble is 0-7, it's Logical, otherwise Arithmetic
         *_SR.B D_
ALSRLONG        CLR.L       D6              ;clear D6 out
                MOVE.B      D5,D6           ;move the last byte to D6
                LSL.B       #4,D6
                CMPI.B      #$80,D6     ;if >= Arithmetic, if lower, Logical
                BLT         LSRLONG
                BRA         ASRLONG
        *Below two cases, it's for sure that instruction, so figure out if it's going to take a
         * register or immediate, based on the 3rd bit of the 3rd nybble. if it's 0 it's immediate, 1: data reg
        *The final 3 bits of the last nybble determine the data reg being shifted.
ASRLONG         LEA         ASRMESSAGE,A1       ;start by printing the ASR.L since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "ASR"
                LEA         LONGEND,A1
                TRAP        #15                 ;printed "ASR.L  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         ASRLONGIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         ASRLONGREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
ASRLONGIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "ASR.L  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACEASRLI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACEASRLI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "ASR.L  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASR.L  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASR.L  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASR.L  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
ASRLONGREG      CLR.B       D6              ;remember you've already printed "ASR.L  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "ASR.L  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed ASR.L  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASR.L  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASR.L  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASR.L  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction


                
                
LSRLONG         LEA         LSRMESSAGE,A1       ;start by printing the LSR.L since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "LSR"
                LEA         LONGEND,A1
                TRAP        #15                 ;printed "LSR.L  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         LSRLONGIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         LSRLONGREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
LSRLONGIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "LSR.L  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACELSRLI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACELSRLI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "LSR.L  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSR.L  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSR.W  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSR.L  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
LSRLONGREG      CLR.B       D6              ;remember you've already printed "LSR.L  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "LSR.L  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed LSR.L  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSR.L  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSR.L  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSR.L  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
        *_SL.L D_   
ALSLLONG        CLR.L       D6              ;clear D6 out
                MOVE.B      D5,D6           ;move the last byte to D6
                LSL.B       #4,D6
                CMPI.B      #$80,D6     ;if >= Arithmetic, if lower, Logical
                BLT         LSLLONG
                BRA         ASLLONG
        *Below two cases, it's for sure that instruction, so figure out if it's going to take a
         * register or immediate, based on the 3rd bit of the 3rd nybble. if it's 0 it's immediate, 1: data reg
        *The final 3 bits of the last nybble determine the data reg being shifted.
ASLLONG         LEA         ASLMESSAGE,A1       ;start by printing the ASL.L since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "ASL"
                LEA         LONGEND,A1
                TRAP        #15                 ;printed "ASL.L  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         ASLLONGIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         ASLLONGREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
ASLLONGIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "ASL.L  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACEASLLI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACEASLLI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "ASL.L  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASL.L  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASL.L  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASL.L  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
ASLLONGREG      CLR.B       D6              ;remember you've already printed "ASL.L  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "ASL.L  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed ASL.L  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "ASL.L  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "ASL.L  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "ASL.L  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction


                
                
LSLLONG         LEA         LSLMESSAGE,A1       ;start by printing the LSL.L since you know it's that
                MOVE.L      #14,D0
                TRAP        #15                 ;printed "LSL"
                LEA         LONGEND,A1
                TRAP        #15                 ;printed "LSL.L  "
                CLR.B       D6                  ;it was previously holding a modified D5 byte
                MOVE.B      D5,D6               ;and now it'll hold a differently modified D5 byte
                LSL.B       #2,D6               ;move the 3rd bit of the 3rd (1st) nybble to the front
                ANDI.B      #$80,D6             ;clear out all data from D6 except the first bit
                CMPI.B      #0,D6
                BEQ         LSLLONGIMM          ;if the result is 0, it's immediate shift, otherwise it's reg shift
                BRA         LSLLONGREG
                
            *if immediate, 2nd nybble's first 3 bits determine the amount to shift by, with 0 meaning 8    
LSLLONGIMM      CLR.B       D6
                MOVE.W      D5,D6               ;move word of D5 into D6
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         POUNDSIGN,A1        ;trap task #14 is still loaded
                TRAP        #15                 ;have now printed "LSL.L  #"
                CMPI.W      #0,D6               ;if D6 contains 0, replace it with 8
                BNE         NOREPLACELSRLI      ;skip the below code if it's not 8
                CLR.B       D6
                MOVE.B      #$8,D6              ;add 8 to D6 because it used to contain 0
NOREPLACELSLLI  MOVE.L      D6,D1               ;start doing the printing stuff, since if you needed to replace you did, if you didnt, you skipped that
                MOVE.W      #3,D0               ;load up trap task 3
                TRAP        #15                 ;have now printed "LSL.L  #n
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSL.L  #n, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSL.L  #n, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSL.L  #n, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
                
            *2nd nybbles first 3 bits determine data register value containing the shift
LSLLONGREG      CLR.B       D6              ;remember you've already printed "LSL.L  " by this point
                MOVE.W      D5,D6           ;now you need to check the first 3 bits of the second nybble
                LSR.W       #1,D6               ;move that 2nd nybble's value from first 3 bits to last 3 bits
                LSR.W       #8,D6               ;move those bits to the end of the word
                CLR.L       D4
                MOVE.W      #$0007,D4           ;move a value you want to AND with D6 into D4
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                LEA         DATAREG,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "LSL.L  D"
                CLR.L       D1
                MOVE.W      D6,D1
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed LSL.L  Dn
                LEA         COMMASPACE,A1
                MOVE.L      #14,D0              ;load trap task 14 again
                TRAP        #15                 ;have now printed "LSL.L  Dn, "
                LEA         DATAREG,A1
                TRAP        #15                 ;have now printed "LSL.L  Dn, D"
                *next you have to get the data reg being shifted, which is determined by the last 3 bits of the instruction
                CLR.B       D6                  ;back to our friend D6
                MOVE.W      D5,D6
                CLR.W       D4                  ;clear D4
                MOVE.W      #$0007,D4           ;same logic as an above step
                AND.W       D4,D6               ;after the AND, D6'll only have the number you want left within it
                MOVE.L      D6,D1               ;move that value into D1 for tap task
                MOVE.L      #3,D0
                TRAP        #15                 ;have now printed "LSL.L  Dn, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction

				
				
				
				
				
				

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







********************************************************************************* START OF BRA/BCS/BGE/BLT/BVC DISSASSEMBLY ***************************************************************************

BRACASE         MOVEM		D5,-(SP) 		;save D5 value in case you need to alter it later
				*grab the instruction's location by 'rolling back' A2
				MOVE.W		-(A2),D3			;move A2 back - the data stored isn't important
				CLR.L 		D3					;that's how unimportant it is
				MOVE.L		A2,D3				;the address, however, is important, so we'll keep it in D3
				*MOVE.L		(A2)+,D6			;now put A2 back where it was
				CLR.L       D0              ;clear out D0 for the trap task later
                LEA         BRAMESSAGE,A1   ;load BRA message
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "BRA"
                LEA         DOUBLESPACE,A1  ;load the spacing
                TRAP        #15             ;have now printed "BRA  "
				LEA			DOLLARSIGN,A1
				TRAP 		#15				;have now printed "BRA  $"
                *now check to see if it's a 8 bit disp, 16 bit, or 32 bit
                CLR.L       D6
                MOVE.W      #$60FF,D6
                CMP         D5,D6
                BEQ         THRTYTOBITDISP    ;if it's equal to $60FF, then it's a 32-bit displacement
                CLR.W       D6
                MOVE.W      #$6000,D6
                CMP         D5,D6 
                BEQ         SIXTEENBITDISP      ;if it's equal to $6000, then it's a 16-bit displacement
                *if it's passed these tests, it's just an 8 bit displacement, so just print out the difference between the prev instruction loc
EIGHBITDISP		CLR.W		D6
				MOVE.B		D5,D6				;store the displacement value into D6
                CMPI.B      #$80,D6
                BCC         ESUB
                NEG.B       D6                  ;negate D6 cuz displacement is two's complement form
				ADD.W		D6,D3				;add the displacement from the instruction stored in D6 to the address value stored in D3 - note this is a signed addition
                
ERETURN         ADDI.W      #2,D3
                MOVE.L      #15,D0              ;also note since you want signed addition, and this is 8 bit (byte) disp, only add the byte values
                MOVE.B      #16,D2              ;Not going to lie, unsure what happens if it overflows... or if it even can overflow
                MOVE.L      D3,D1
                TRAP        #15                 ;have now printed "Bcc  $xxxxxxxx"
                
                MOVE.L      (A2)+,D3            ;you don't need this, but you do need to push A2 forward again
                MOVEM       (SP)+,D5            ;reload D5
                BRA         LOOPEND             ;next instruction time
                
ESUB            NEG.B       D6
                SUB.W       D6,D3
                BRA         ERETURN
				
					

BCSCASE         MOVEM		D5,-(SP) 		;save D5 value in case you need to alter it later
				*grab the instruction's location by 'rolling back' A2
				MOVE.W		-(A2),D3			;move A2 back - the data stored isn't important
				CLR.L 		D3					;that's how unimportant it is
				MOVE.L		A2,D3				;the address, however, is important, so we'll keep it in D3
				*MOVE.L		(A2)+,D6			;now put A2 back where it was
				CLR.L       D0              ;clear out D0 for the trap task later
                LEA         BCSMESSAGE,A1   ;load BCS message
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "BCS"
                LEA         DOUBLESPACE,A1  ;load the spacing
                TRAP        #15             ;have now printed "BCS  "
				LEA			DOLLARSIGN,A1
				TRAP 		#15				;have now printed "BCS  $"
                *now check to see if it's a 8 bit disp, 16 bit, or 32 bit
                CLR.L       D6
                MOVE.W      #$65FF,D6
                CMP         D5,D6
                BEQ         THRTYTOBITDISP    ;if it's equal to $65FF, then it's a 32-bit displacement
                CLR.W       D6
                MOVE.W      #$6500,D6
                CMP         D5,D6 
                BEQ         SIXTEENBITDISP      ;if it's equal to $6500, then it's a 16-bit displacement
                BRA         EIGHBITDISP         ;otheriwse it's an 8 bit displacement

BGECASE         MOVEM		D5,-(SP) 		;save D5 value in case you need to alter it later
				*grab the instruction's location by 'rolling back' A2
				MOVE.W		-(A2),D3			;move A2 back - the data stored isn't important
				CLR.L 		D3					;that's how unimportant it is
				MOVE.L		A2,D3				;the address, however, is important, so we'll keep it in D3
				*MOVE.L		(A2)+,D6			;now put A2 back where it was
				CLR.L       D0              ;clear out D0 for the trap task later
                LEA         BGEMESSAGE,A1   ;load BGE message
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "BGE"
                LEA         DOUBLESPACE,A1  ;load the spacing
                TRAP        #15             ;have now printed "BGE  "
				LEA			DOLLARSIGN,A1
				TRAP 		#15				;have now printed "BGE  $"
                *now check to see if it's a 8 bit disp, 16 bit, or 32 bit
                CLR.L       D6
                MOVE.W      #$6CFF,D6
                CMP         D5,D6
                BEQ         THRTYTOBITDISP    ;if it's equal to $6CFF, then it's a 32-bit displacement
                CLR.W       D6
                MOVE.W      #$6C00,D6
                CMP         D5,D6 
                BEQ         SIXTEENBITDISP      ;if it's equal to $6C00, then it's a 16-bit displacement
                BRA         EIGHBITDISP         ;otheriwse it's an 8 bit displacement


BLTCASE         MOVEM		D5,-(SP) 		;save D5 value in case you need to alter it later
				*grab the instruction's location by 'rolling back' A2
				MOVE.W		-(A2),D3			;move A2 back - the data stored isn't important
				CLR.L 		D3					;that's how unimportant it is
				MOVE.L		A2,D3				;the address, however, is important, so we'll keep it in D3
				*MOVE.L		(A2)+,D6			;now put A2 back where it was
				CLR.L       D0              ;clear out D0 for the trap task later
                LEA         BLTMESSAGE,A1   ;load BLT message
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "BLT"
                LEA         DOUBLESPACE,A1  ;load the spacing
                TRAP        #15             ;have now printed "BLT  "
				LEA			DOLLARSIGN,A1
				TRAP 		#15				;have now printed "BLT  $"
                *now check to see if it's a 8 bit disp, 16 bit, or 32 bit
                CLR.L       D6
                MOVE.W      #$6DFF,D6
                CMP         D5,D6
                BEQ         THRTYTOBITDISP    ;if it's equal to $6DFF, then it's a 32-bit displacement
                CLR.W       D6
                MOVE.W      #$6D00,D6
                CMP         D5,D6 
                BEQ         SIXTEENBITDISP      ;if it's equal to $6D00, then it's a 16-bit displacement
                BRA         EIGHBITDISP         ;otheriwse it's an 8 bit displacement


BVCCASE         MOVEM		D5,-(SP) 		;save D5 value in case you need to alter it later
				*grab the instruction's location by 'rolling back' A2
				MOVE.W		-(A2),D3			;move A2 back - the data stored isn't important
				CLR.L 		D3					;that's how unimportant it is
				MOVE.L		A2,D3				;the address, however, is important, so we'll keep it in D3
				*MOVE.L		(A2)+,D6			;now put A2 back where it was
				CLR.L       D0              ;clear out D0 for the trap task later
                LEA         BVCMESSAGE,A1   ;load BVC message
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "BVC"
                LEA         DOUBLESPACE,A1  ;load the spacing
                TRAP        #15             ;have now printed "BVC  "
				LEA			DOLLARSIGN,A1
				TRAP 		#15				;have now printed "BVC  $"
                *now check to see if it's a 8 bit disp, 16 bit, or 32 bit
                CLR.L       D6
                MOVE.W      #$68FF,D6
                CMP         D5,D6
                BEQ         THRTYTOBITDISP    ;if it's equal to $68FF, then it's a 32-bit displacement
                CLR.W       D6
                MOVE.W      #$6800,D6
                CMP         D5,D6 
                BEQ         SIXTEENBITDISP      ;if it's equal to $6800, then it's a 16-bit displacement
                BRA         EIGHBITDISP         ;otheriwse it's an 8 bit displacement


SIXTEENBITDISP  CLR.W       D6          ;16 bit displacement means the next word will have the displacement data
                MOVE.L      (A2)+,D6    ;move the next word from the instruction set into d6
                *if the first bit of the word is 1, it's negative, so check for that first before doing NEG
                *if the first bit of the word IS 1, then instead of doing ADD after NEG, do SUB
                CMPI.W      #$8000,D6
                BCC         SSUB
                NEG.W       D6          ;neg D6 cuz displacement is in two's complement form
                ADD.W       D6,D3       ;add that displacement value to the original address location, stored in D3

SRETURN         ADDI.W      #2,D3
                MOVE.L      #15,D0      ;see EIGHBITDISP notes on the above addition
                MOVE.B      #16,D2
                MOVE.L      D3,D1
                TRAP        #15                 ;have now printed "Bcc  $xxxxxxxx"
                
                MOVEM       (SP)+,D5            ;reload D5
                BRA         LOOPEND             ;next instruction time
                
SSUB            NEG.W       D6
                SUB.W       D6,D3
                BRA         SRETURN
                

THRTYTOBITDISP  CLR.W       D6          ;32 bit displacement means the next long will have the displacement data
                MOVE.L      (A2)+,D6    ;move the next long from the instruction set into d6
                CMPI.L      #$80000000,D6
                BCC         TSUB
                NEG.L       D6          ;neg D6 cuz displacement is in two's complement form
                ADD.L       D6,D3       ;add that displacement value to the original address location, stored in D3
                
TRETURN         ADDI.L      #2,D3
                MOVE.L      #15,D0
                MOVE.B      #16,D2
                MOVE.L      D3,D1
                TRAP        #15                 ;have now printed "Bcc  $xxxxxxxx"
                
                MOVEM       (SP)+,D5            ;reload D5
                BRA         LOOPEND             ;next instruction time
                
TSUB            NEG.L       D6
                SUB.L       D6,D3
                BRA         TRETURN

********************************************************************************* END OF BRA/BCS/BGE/BLT/BVC DISSASSEMBLY ***************************************************************************










********************************************************************************* START OF CMP DISSASSEMBLY ***************************************************************************

CMPCASE			MOVEM		D5,-(SP)			;save the D5 value
				CLR.L 		D6
				MOVE.L 		#14,D0				;for the trap task
				LEA 		CMPMESSAGE,A1
				TRAP 		#15 				;have now printed "CMP"
				*get the 3rd nybble's first two values (or byte's first nybble), cmp those to see if it's B, W, or L
				MOVE.B 		D5,D6
				ANDI.B 		#$C0,D6
				LSR.B 		#6,D6 				;move the first two values to the end of the byte
				CMPI.B 		#0,D6
				BEQ			CMPBYTE
				CMPI.B 		#1,D6
				BEQ			CMPWORD
				BRA 		CMPLONG
CMPBYTE			LEA			BYTEEND,A1
				TRAP 		#15					;have now printed "CMP.B  "
				BRA			CMPWHICH
CMPWORD			LEA			WORDEND,A1
				TRAP 		#15					;have now printed "CMP.W  "
				BRA 		CMPWHICH
CMPLONG			LEA			LONGEND,A1
				TRAP 		#15					;have now printed "CMP.L  ", and don't need to branch, it'll go there anyway
				
				*Now lets figure out which EA mode - based on the last 2 bits of the 3rd nybble (or first nybble of the byte)
CMPWHICH		CLR.L 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$30,D6			;just save the 3rd/4th bits
				CMPI.B 		#0,D6
				BEQ 		CMPDNORAN 		;either Dn or An*
				CMPI.B 		#$10,D6
				BEQ			CMPINCORIND		;it's (An)+ OR (An)
				CMPI.B 		#$20,D6
				BEQ			CMPDEC 		;It's -(An)
				BRA 		CMPIMMORABS		;either xxx.W/L or immediate
	
CMPDNORAN		CLR.B 		D6				;next determine if it's Dn or An based on the first bit of the last nybble
				MOVE.B 		D5,D6
				ANDI 		#$08,D6
				CMPI.B 		#0,D6
				BEQ 		CMPDN			;if it's 0 after the AND, it's a data reg
				LEA			ADDRESSA,A1		;otherwise it's an An*
				TRAP 		#15 			;now printed "CMP.x  A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "CMP.x  An"
				BRA 		CMPREG
				
CMPDN			LEA			DATAREG,A1
				TRAP 		#15 			;now printed "CMP.x  D"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "CMP.x  Dn"
				BRA			CMPREG
				
CMPDEC			LEA			INDIRECTADDECB,A1		;otherwise it's -(An)
				TRAP 		#15 			;now printed "CMP.x  -(A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "CMP.x  -(An"
				MOVE.L		#14,D0
				LEA 		CLOSEPAREN,A1
				TRAP 		#15 			;have now printed "CMP.x  -(An)"
				BRA 		CMPREG
				
CMPINCORIND		CLR.B 		D6				;depends on first bit of 4th nybble - if it's 0, it's (An)
				MOVE.B 		D5,D6
				ANDI.B 		#$08,D6
				BEQ 		CMPIND			;otherwise it's (An)+
				LEA			INDIRECTADAB,A1
				TRAP 		#15 			;now printed "CMP.x  (A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "CMP.x  (An"
				MOVE.L		#14,D0
				LEA 		INCREMENTEND,A1
				TRAP 		#15 			;have now printed "CMP.x  (An)+"
				BRA 		CMPREG

CMPIND 			LEA			INDIRECTADAB,A1
				TRAP 		#15 			;now printed "CMP.x  (A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "CMP.x  (An"
				MOVE.L		#14,D0
				LEA 		CLOSEPAREN,A1
				TRAP 		#15 			;have now printed "CMP.x  (An)"
				BRA 		CMPREG
				
				*For immediate data, I'm assuming it follows the same logic as the CMPI instruction
					*if Size == B, data is low order byte of immediate word
					*size == W, data is entire immediate word
					*size == L, data is next two immediate words
CMPIMMORABS		;check what the last 3 bits equal to determine what to print out now
                CLR.L       D6
                MOVE.B      D5,D6
                ANDI.B      #$07,D6
                CMPI.B      #0,D6
                BEQ         CMPABSWORD
                CMPI.B      #1, D6
                BEQ         CMPABSLONG
                *now you know it's an immediate, so it's going to get a little odd.
                *Check which size it is again
                *get the 3rd nybble's first two values (or byte's first nybble), cmp those to see if it's B, W, or L
				MOVE.B 		D5,D6
				ANDI.B 		#$C0,D6
				LSR.B 		#6,D6 				;move the first two values to the end of the byte
                LEA         POUNDSIGN,A1
                MOVE.L      #14,D0
                TRAP        #15                 ;have now printed "CMP.x  #"
                MOVE.L      #3,D0              ;load trap task 3 for later
				CMPI.B 		#0,D6
				BEQ			CMPBYTEIMM
				CMPI.B 		#1,D6
				BEQ			CMPWORDIMM
				BRA 		CMPLONGIMM
                
CMPBYTEIMM		CLR.L       D1
                CLR.W       D6
                MOVE.W      (A2)+,D6            ;grab the byte of the next word.
                MOVE.B      D6,D1
                TRAP        #15                 ;have now printed "CMP.x  #xx"
				BRA			CMPREG
                
CMPWORDIMM		CLR.L       D1
                CLR.W       D6
                MOVE.W      (A2)+,D6            ;grab the next word.
                MOVE.W      D6,D1
                TRAP        #15                 ;have now printed "CMP.x  #xxxx"
				BRA 		CMPREG
                
CMPLONGIMM	    CLR.L       D1
                CLR.L       D6
                MOVE.L      (A2)+,D6            ;grab the long of the next word.
                MOVE.L      D6,D1
                TRAP        #15                 ;have now printed "CMP.x  #xxxxxxxx"
				BRA         CMPREG
                

CMPABSWORD      MOVE.L      #14,D0     
                LEA 		DOLLARSIGN,A1
				TRAP 		#15 			;have now printed "CMP.x  $"
				MOVE.B 		#16,D2 			;allows for trap task #15 to display hex numbers
				MOVE.L 		#15,D0			;load trap task 15 for later
				
                MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				CLR.L 		D3
				MOVE.W      (A2)+,D3		;move the next word into D3
				CMP.W 		#$8000,D3		;check if you need to sign extend
				BCC 		CMPADDF
				CLR.L 		D1
				MOVE.W 		D3, D1			;Move into D1 to print

				

CMPABSWTRAP		TRAP 		#15				;have now printed "CMP.x  $xxxx"
				BRA 		CMPREG
				
CMPADDF 		MOVE.L 		#$FFFFFFFF,D1 	;set the sign extension up
				MOVE.W 		D3,D1 			;move the rest of the word, then onto the print task
				BRA 		CMPABSWTRAP

                
CMPABSLONG      MOVE.L      #14,D0     
                LEA 		DOLLARSIGN,A1
				TRAP 		#15 			;have now printed "CMP.x  $"
				MOVE.B 		#16,D2 			;allows for trap task #15 to display hex numbers
				MOVE.L 		#15,D0			;load trap task 15 for later
                MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				MOVE.L      (A2)+,D1		;move the whole long into D1
				TRAP 		#15				;have now printed "CMP.x  Dn, $xxxxxxxx"		
				BRA 		CMPREG
                
CMPREG			MOVE.L      #14,D0
                LEA         COMMASPACE,A1
                TRAP        #15             ;have now printed "CMP.x  ea, "
                CLR.B 		D6
				MOVE.W 		D5,D6
				ANDI.W 		#$0E00,D6		;clear out the whole thing except the register value (2nd nybble first 3 bits)
				LSR.W 		#8,D6
				LSR.W 		#1,D6 			;move those bits to the end of the word
				LEA			DATAREG,A1
				Trap		#15				;have now printed "CMP.x  ea, D"
				CLR.L		D1
				MOVE.B 		D6,D1			;move that number to D1 to print later
				MOVE.L		#3,D0
				TRAP 		#15				;Have now printed "CMP.x  ea, Dn"

				MOVEM       (SP)+,D5        ;reload the stack
				BRA 		LOOPEND



********************************************************************************* END OF CMP DISSASSEMBLY ***************************************************************************










********************************************************************************* START OF EOR DISSASSEMBLY ***************************************************************************

EORCASE			MOVEM		D5,-(SP)			;save the D5 value
				CLR.L 		D6
				MOVE.L 		#14,D0				;for the trap task
				LEA 		EORMESSAGE,A1
				TRAP 		#15 				;have now printed "EOR"
				*get the 3rd nybble's first two values (or byte's first nybble), cmp those to see if it's B, W, or L
				MOVE.B 		D5,D6
				ANDI.B 		#$C0,D6
				LSR.B 		#6,D6 				;move the first two values to the end of the byte
				CMPI.B 		#0,D6
				BEQ			EORBYTE
				CMPI.B 		#1,D6
				BEQ			EORWORD
				BRA 		EORLONG
EORBYTE			LEA			BYTEEND,A1
				TRAP 		#15					;have now printed "EOR.B  "
				BRA			EORREG
EORWORD			LEA			WORDEND,A1
				TRAP 		#15					;have now printed "EOR.W  "
				BRA 		EORREG
EORLONG			LEA			LONGEND,A1
				TRAP 		#15					;have now printed "EOR.L  ", and don't need to branch, it'll go there anyway
EORREG			CLR.B 		D6
				MOVE.W 		D5,D6
				ANDI.W 		#$0E00,D6		;clear out the whole thing except the register value (2nd nybble first 3 bits)
				LSR.W 		#8,D6
				LSR.W 		#1,D6 			;move those bits to the end of the word
				LEA			DATAREG,A1
				Trap		#15				;have now printed "EOR.x  D"
				CLR.L		D1
				MOVE.B 		D6,D1			;move that number to D1 to print later
				MOVE.L		#3,D0
				TRAP 		#15				;Have now printed "EOR.x  Dn"
				MOVE.L 		#14,D0
				LEA 		COMMASPACE,A1
				TRAP 		#15 			;have now printed "EOR.x  Dn, "
				
				*Now lets figure out which EA mode - based on the last 2 bits of the 3rd nybble (or first nybble of the byte)
				MOVE.B 		D5,D6
				ANDI.B 		#$30,D6			;just save the 3rd/4th bits
				CMPI.B 		#0,D6
				BEQ 		EORDNORAN 		;either Dn or An* - JK just Dn
				CMPI.B 		#$10,D6
				BEQ			EORINCORAN		;either (An) or (An)+
                CMPI.B      #$20,D6         ;if the 3/4th bits are 10, it's -(An)
                BEQ         EORDEC
				BRA 		EORABS			;either xxx.W/L
	
EORDNORAN		CLR.B 		D6				;next determine if it's Dn or An based on the first bit of the last nybble
				MOVE.B 		D5,D6           ; the above is somewhat wrong - An* is not valid, it's always Dn if it's here
				ANDI 		#$08,D6         ; or data i suppose
				CMPI.B 		#0,D6
				BEQ 		EORDN			;if it's 0 after the AND, it's a data reg - actually it always will
				BRA 		DATACASE		;otherwise it's DATA

				
EORDN			LEA			DATAREG,A1
				TRAP 		#15 			;now printed "EOR.x  Dn, D"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "EOR.x  Dn, Dn"
				
				MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
				
EORINCORAN		CLR.B 		D6				;next determine if it's (An) or (An)+ based on the first bit of the last nybble
				MOVE.B 		D5,D6           ;
				ANDI 		#$08,D6
				CMPI.B 		#0,D6
				BEQ 		EORAN			;if it's 0 after the AND, it's (An)
				LEA			INDIRECTADAB,A1		;otherwise it's (An)+
				TRAP 		#15 			;now printed "EOR.x  Dn, (A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "EOR.x  Dn, (An"
				MOVE.L		#14,D0
				LEA 		INCREMENTEND,A1
				TRAP 		#15 			;have now printed "EOR.x  Dn, (An)+"
				
				MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
EORDEC          LEA			INDIRECTADDECB,A1		;it's -(An)
				TRAP 		#15 			;now printed "EOR.x  Dn, -(A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "EOR.x  Dn, -(An"
				MOVE.L		#14,D0
				LEA 		CLOSEPAREN,A1
				TRAP 		#15 			;have now printed "EOR.x  Dn, -(An)"
				
				MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
				
EORAN			LEA			INDIRECTADAB,A1
				TRAP 		#15 			;now printed "EOR.x  Dn, (A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "EOR.x  Dn, (An"
				MOVE.L		#14,D0
				LEA 		CLOSEPAREN,A1
				TRAP 		#15 			;have now printed "EOR.x  Dn, (An)"
				
				MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
				
EORABS			CLR.B 		D6 				;check what the last 3 bits equal to determine what to print out now
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6
				LEA 		DOLLARSIGN,A1
				TRAP 		#15 			;have now printed "EOR.x  Dn, $"
				MOVE.B 		#16,D2 			;allows for trap task #15 to display hex numbers
				MOVE.L 		#15,D0			;load trap task 15 for later
				CMPI.B 		#0,D6			;if the last 3 bits were 0, it's (xxx).W
				BEQ         EORABSWORD					;else it's just (xxx).L
				MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				MOVE.L      (A2)+,D1		;move the whole long into D1
				TRAP 		#15				;have now printed "EOR.x  Dn, $xxxxxxxx"
				
				BRA 		LOOPEND			;go to next instruction
				
EORABSWORD		MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				CLR.L 		D3
				MOVE.W      (A2)+,D3		;move the next word into D3
				CMP.W 		#$8000,D3		;check if you need to sign extend
				BCC 		EORADDF
				CLR.L 		D1
				MOVE.W 		D3,D1 			;else just move into D1 to print

				

EORABSWTRAP		TRAP 		#15				;have now printed "EOR.x  Dn, $xxxx"
                
                BRA         LOOPEND         ;go to the next instruction
				
EORADDF 		MOVE.L 		#$FFFFFFFF,D1 	;set the sign extension up
				MOVE.W 		D3,D1 			;move the rest of the word, then onto the print task
				BRA 		EORABSWTRAP
				



********************************************************************************* END OF EOR DISSASSEMBLY ***************************************************************************













********************************************************************************* START OF CMPI DISSASSEMBLY ***************************************************************************

CMPICASE        MOVEM       D5,-(SP)        ;save D5 incase you change it at some point
                *CMPI's 3rd nybble (byte's first nybble) has to be B or lower
                CLR.W       D6
                MOVE.B      D5,D6
                ANDI.B      #$F0,D6
                CMPI.B      #$C0,D6
                BCC         DATACASE        ;if it's C or higher, it's data
                LEA         CMPIMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "CMPI"
                *now let's check the size, which will impact what you print next in addition to the qualifier
                *first two bits of the byte's first nybble determine size
                ANDI.B      #$C0,D6         ;D6 still has the full first nybble stored, so just clear out the last two bits of the first nybble
                LSR         #6,D6           ;move those first two bits to the end
                CMPI.B      #0,D6
                BEQ         CMPIBYTE        ; if it ==0, it's a byte 
                CMPI.B      #1,D6
                BEQ         CMPIWORD        ;if it == 1, it's a word
CMPILONG        LEA         LONGEND,A1      ;else it's a long
                TRAP        #15             ;Have now printed "CMPI.L  "
                LEA         POUNDSIGN,A1    
                TRAP        #15             ;have now printed "CMPI.L  #"
                MOVE.L      #15,D0              ;load trap task 15 for later
                MOVE.B      #10,D2              ;make sure it prints in decimal
                CLR.L       D1
                CLR.W       D6
                MOVE.L      (A2)+,D6            ;grab the next long.
                MOVE.L      D6,D1
                TRAP        #15                 ;have now printed "CMPI.L  #xxxxxxxx"
                BRA         CMPIEA
                

CMPIWORD        LEA         WORDEND,A1      ;else it's a long
                TRAP        #15             ;Have now printed "CMPI.W  "
                LEA         POUNDSIGN,A1    
                TRAP        #15             ;have now printed "CMPI.W  #"
                MOVE.L      #15,D0              ;load trap task 15 for later
                MOVE.B      #10,D2              ;make sure it prints in decimal
                CLR.L       D1
                CLR.W       D6
                MOVE.W      (A2)+,D6            ;grab the next word.
                MOVE.W      D6,D1
                TRAP        #15                 ;have now printed "CMPI.W  #xxxx"
                BRA         CMPIEA

CMPIBYTE        LEA         BYTEEND,A1      ;else it's a long
                TRAP        #15             ;Have now printed "CMPI.B  "
                LEA         POUNDSIGN,A1    
                TRAP        #15             ;have now printed "CMPI.B  #"
                MOVE.L      #15,D0              ;load trap task 15 for later
                MOVE.B      #10,D2              ;make sure it prints in decimal
                CLR.L       D1
                CLR.W       D6
                MOVE.W      (A2)+,D6            ;grab the byte from the next word.
                MOVE.B      D6,D1
                TRAP        #15                 ;have now printed "CMPI.L  #xx"
                BRA         CMPIEA
                
CMPIEA          LEA         COMMASPACE,A1
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "CMPI.x  #x, "
                *next is to figure out which type of EA it is and print that out
                *the last 2 bits of the byte's first nybble help determine the mode
                CLR.B       D6
                MOVE.B      D5,D6
                ANDI.B      #$30,D6
                CMPI.B      #0,D6           ;if == 0, it's a data reg
                BEQ         CMPIDN
                CMPI.B      #$10,D6         ;if == 0001 0000, it's (An) or (An)+
                BEQ         CMPIINCORAN
                CMPI.B      #$20,D6         ;if it's == 0010 0000, it's -(An)
				BEQ 		CMPIDEC
                BRA         CMPIABS         ;else it's an absolute
                
CMPIDN          LEA         DATAREG,A1
                TRAP        #15             ;have now printed "CMPI.x  #x, D"
                CLR.B       D6
                MOVE.B      D5,D6           ;last 3 bits of the byte determine the reg
                ANDI.B      #07,D6
                MOVE.L      #3,D0           ;load trap task 3
                CLR.L       D1
                MOVE.B      D6,D1
                TRAP        #15             ;have now printed "CMPI.x  #x, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction        
                
CMPIINCORAN     CLR.B       D6              ;determine which [(An) or (An)+] it is based on the first bit of the last nybble
                MOVE.B      D5,D6
                ANDI.B      #$08,D6
                CMPI.B      #8,D6
                BEQ         CMPIINC         ;if its == 0000 1000, it's (An)+
CMPIAN          LEA         INDIRECTADAB,A1 ;otherwise it's (An), so start printing out stuff
                TRAP        #15             ;have now printed "CMPI.x  #x, (A"
                CLR.B       D6
                MOVE.B      D5,D6           ;last 3 bits of the byte determine the reg
                ANDI.B      #07,D6
                MOVE.L      #3,D0           ;load trap task 3
                CLR.L       D1
                MOVE.B      D6,D1
                TRAP        #15             ;have now printed "CMPI.x  #x, (An"
                MOVE.L      #14,D0
                LEA         CLOSEPAREN,A1
                TRAP        #15             ;have now printed "CMPI.x  #x, (An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction 

CMPIINC         LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "CMPI.x  #x, (A"
                CLR.B       D6
                MOVE.B      D5,D6           ;last 3 bits of the byte determine the reg
                ANDI.B      #07,D6
                MOVE.L      #3,D0           ;load trap task 3
                CLR.L       D1
                MOVE.B      D6,D1
                TRAP        #15             ;have now printed "CMPI.x  #x, (An"
                MOVE.L      #14,D0
                LEA         INCREMENTEND,A1
                TRAP        #15             ;have now printed "CMPI.x  #x, (An)+"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction 

CMPIDEC         LEA         INDIRECTADDECB,A1 
                TRAP        #15             ;have now printed "CMPI.x  #x, (-A"
                CLR.B       D6
                MOVE.B      D5,D6           ;last 3 bits of the byte determine the reg
                ANDI.B      #07,D6
                MOVE.L      #3,D0           ;load trap task 3
                CLR.L       D1
                MOVE.B      D6,D1
                TRAP        #15             ;have now printed "CMPI.x  #x, -(An"
                MOVE.L      #14,D0
                LEA         CLOSEPAREN,A1
                TRAP        #15             ;have now printed "CMPI.x  #x, -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction 
                
CMPIABS         CLR.B       D6
                MOVE.B      D5,D6           ;determine if it's (xxx).W or (xxx).L based on the last 3 bits
                ANDI.B      #07,D6
                MOVE.L      #14,D0
                LEA 		DOLLARSIGN,A1
				TRAP 		#15 			;have now printed "CMPI.x  #x, $"
                MOVE.B 		#16,D2 			;allows for trap task #15 to display hex numbers
				MOVE.L 		#15,D0			;load trap task 15 for later
                CLR.L       D1              ;clear D1 for later too
                CMPI.B      #0,D6
                BEQ         CMPIABSWORD     ;if the last 3 bits are 0, it's (xxx).W
                *else it's (xxx).L
				MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				MOVE.L      (A2)+,D1		;move the whole long into D1
				TRAP 		#15				;have now printed "CMPI.x  #x, $xxxxxxxx"
                
                BRA         LOOPEND         ;go to the next instruction
                
CMPIABSWORD     MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				CLR.L 		D3
				MOVE.W      (A2)+,D3		;move the next word into D1
				CMP.W 		#$8000,D3		;check if you need to sign extend
				BCC 		CMPIADDF
				CLR.L 		D1
				MOVE.W 		D3, D1			;Move into D1 to print

				

CMPIABSWTRAP	TRAP 		#15				;have now printed "CMPI.x  #x, $xxxx"
                
                BRA         LOOPEND         ;go to the next instruction
				
CMPIADDF 		MOVE.L 		#$FFFFFFFF,D1 	;set the sign extension up
				MOVE.W 		D3,D1 			;move the rest of the word, then onto the print task
				BRA 		CMPIABSWTRAP
                
                BRA         LOOPEND         ;go to the next instruction

********************************************************************************* END OF CMPI DISSASSEMBLY ***************************************************************************








********************************************************************************* START OF OR DISSASSEMBLY ***************************************************************************


ORCASE			MOVEM		D5,-(SP)			;save the D5 value
				CLR.L 		D6
				MOVE.L 		#14,D0				;for the trap task
				LEA 		ORMESSAGE,A1
				TRAP 		#15 				;have now printed "OR"
				*get the 3rd nybble's first two values (or byte's first nybble), cmp those to see if it's B, W, or L
				MOVE.B 		D5,D6
				ANDI.B 		#$C0,D6
				LSR.B 		#6,D6 				;move the first two values to the end of the byte
				CMPI.B 		#0,D6
				BEQ			ORBYTE
				CMPI.B 		#1,D6
				BEQ			ORWORD
				BRA 		ORLONG
ORBYTE			LEA			BYTEEND,A1
				TRAP 		#15					;have now printed "OR.B  "
				BRA			ORREGCHECK
ORWORD			LEA			WORDEND,A1
				TRAP 		#15					;have now printed "OR.W  "
				BRA 		ORREGCHECK
ORLONG			LEA			LONGEND,A1
				TRAP 		#15					;have now printed "OR.L  ", and don't need to branch, it'll go there anyway
ORREGCHECK		*Check which type of OR op it is - if the 2nd nybble 4th bit is 0, it's OR <ea>, DN
				*otherwise it's OR Dn, <ea> which will follow the same logic as EOR, except without the possibility of <Ea>=Dn
				MOVE.W 		D5,D6
				ANDI.W 		#$0100,D6 		;isolate 4th bit of 2nd nybble
				CMPI.W 		#0,D6
				BEQ 		OROCASE			;branch to the OR Other CASE
				CLR.W 		D6 				;otherwise reset D6 for normal interaction
				MOVE.W 		D5,D6
				ANDI.W 		#$0E00,D6		;clear out the whole thing except the register value (2nd nybble first 3 bits)
				LSR.W 		#8,D6
				LSR.W 		#1,D6 			;move those bits to the end of the word
				LEA			DATAREG,A1
				Trap		#15				;have now printed "OR.x  D"
				CLR.L		D1
				MOVE.B 		D6,D1			;move that number to D1 to print later
				MOVE.L		#3,D0
				TRAP 		#15				;Have now printed "OR.x  Dn"
				MOVE.L 		#14,D0
				LEA 		COMMASPACE,A1
				TRAP 		#15 			;have now printed "OR.x  Dn, "
				
				*Now lets figure out which EA mode - based on the last 2 bits of the 3rd nybble (or first nybble of the byte)
				MOVE.B 		D5,D6
				ANDI.B 		#$30,D6			;just save the 3rd/4th bits
				CMPI.B 		#0,D6
				BEQ 		DATACASE		;it can't be a Dn or An*
				CMPI.B 		#$10,D6
				BEQ			ORINCORAN		;either (An) or (An)+
                CMPI.B      #$20,D6         ;if the 3/4th bits are 10, it's -(An)
                BEQ         ORDEC
				BRA 		ORABS		;either xxx.W/L

				
ORINCORAN		CLR.B 		D6				;next determine if it's (An) or (An)+ based on the first bit of the last nybble
				MOVE.B 		D5,D6           ;
				ANDI 		#$08,D6
				CMPI.B 		#0,D6
				BEQ 		ORAN			;if it's 0 after the AND, it's (An)
				LEA			INDIRECTADAB,A1		;otherwise it's (An)+
				TRAP 		#15 			;now printed "OR.x  Dn, (A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "OR.x  Dn, (An"
				MOVE.L		#14,D0
				LEA 		INCREMENTEND,A1
				TRAP 		#15 			;have now printed "OR.x  Dn, (An)+"
				
				MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
                
ORDEC          	LEA			INDIRECTADDECB,A1		;it's -(An)
				TRAP 		#15 			;now printed "OR.x  Dn, -(A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "OR.x  Dn, -(An"
				MOVE.L		#14,D0
				LEA 		CLOSEPAREN,A1
				TRAP 		#15 			;have now printed "OR.x  Dn, -(An)"
				
				MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
				
ORAN			LEA			INDIRECTADAB,A1
				TRAP 		#15 			;now printed "OR.x  Dn, (A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "OR.x  Dn, (An"
				MOVE.L		#14,D0
				LEA 		CLOSEPAREN,A1
				TRAP 		#15 			;have now printed "OR.x  Dn, (An)"
				
				MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
				
ORABS			CLR.B 		D6 				;check what the last 3 bits equal to determine what to print out now
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6
				LEA 		DOLLARSIGN,A1	;else it's ABS so print the $
				TRAP 		#15 			;have now printed "OR.x  Dn, $"
				MOVE.B 		#16,D2 			;allows for trap task #15 to display hex numbers
				MOVE.L 		#15,D0			;load trap task 15 for later
				CMPI.B 		#0,D6			;if the last 3 bits were 0, it's (xxx).W
				BEQ         ORABSWORD		;else it's just (xxx).L
				MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				MOVE.L      (A2)+,D1		;move the whole long into D1
				TRAP 		#15				;have now printed "OR.x  Dn, $xxxxxxxx"
				
				BRA 		LOOPEND			;go to next instruction
				
ORABSWORD		MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				CLR.L 		D3
				MOVE.W      (A2)+,D3		;move the next word into D1
				CMP.W 		#$8000,D3		;check if you need to sign extend
				BCC 		ORADDF
				CLR.L 		D1
				MOVE.W 		D3, D1			;Move into D1 to print

				

ORABSWTRAP		TRAP 		#15				;have now printed "OR.x  Dn, $xxxx"
                
                BRA         LOOPEND         ;go to the next instruction
				
ORADDF 			MOVE.L 		#$FFFFFFFF,D1 	;set the sign extension up
				MOVE.W 		D3,D1 			;move the rest of the word, then onto the print task
				BRA 		ORABSWTRAP


				
				

				*This case will be almost the same as before, HOWEVER the modes allowed are ALL
					*or <EA>, dN
OROCASE			*Now lets figure out which EA mode - based on the last 2 bits of the 3rd nybble (or first nybble of the byte)
				MOVE.B 		D5,D6
				ANDI.B 		#$30,D6			;just save the 3rd/4th bits
				CMPI.B 		#0,D6
				BEQ 		ORODNDATA 		;either Dn or data
				CMPI.B 		#$10,D6
				BEQ			OROINCORAN		;either (An) or (An)+
                CMPI.B      #$20,D6         ;if the 3/4th bits are 10, it's -(An)
                BEQ         ORODEC
				BRA 		OROABSIMM		;either xxx.W/L, or an immediate
				
OROREG			MOVE.L 		#14,D0
				LEA 		COMMASPACE,A1
				TRAP 		#15 			;have now printed "OR.x  ea, "
				CLR.B 		D6
				MOVE.W 		D5,D6
				ANDI.W 		#$0E00,D6		;clear out the whole thing except the register value (2nd nybble first 3 bits)
				LSR.W 		#8,D6
				LSR.W 		#1,D6 			;move those bits to the end of the word
				LEA			DATAREG,A1
				Trap		#15				;have now printed "OR.x  ea, D"
				CLR.L		D1
				MOVE.B 		D6,D1			;move that number to D1 to print later
				MOVE.L		#3,D0
				TRAP 		#15				;Have now printed "OR.x  ea, Dn"
				
				MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction
				
	
ORODNDATA		CLR.B 		D6				;next determine if it's Dn or data based on the first bit of the last nybble
				MOVE.B 		D5,D6     
				ANDI 		#$08,D6         
				CMPI.B 		#0,D6
				BEQ 		ORODN			;if it's 0 after the AND, it's a data reg
				BRA 		DATACASE		;otherwise it's DATA

				
ORODN			LEA			DATAREG,A1
				TRAP 		#15 			;now printed "OR.x  D"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "OR.x  Dn"
				BRA 		OROREG
				
OROINCORAN		CLR.B 		D6				;next determine if it's (An) or (An)+ based on the first bit of the last nybble
				MOVE.B 		D5,D6           ;
				ANDI 		#$08,D6
				CMPI.B 		#0,D6
				BEQ 		OROAN			;if it's 0 after the AND, it's (An)
				LEA			INDIRECTADAB,A1		;otherwise it's (An)+
				TRAP 		#15 			;now printed "OR.x  (A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "OR.x  (An"
				MOVE.L		#14,D0
				LEA 		INCREMENTEND,A1
				TRAP 		#15 			;have now printed "OR.x  (An)+"
				BRA 		OROREG
                
ORODEC          LEA			INDIRECTADDECB,A1		;it's -(An)
				TRAP 		#15 			;now printed "OR.x  -(A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "OR.x  -(An"
				MOVE.L		#14,D0
				LEA 		CLOSEPAREN,A1
				TRAP 		#15 			;have now printed "OR.x  -(An)"
				BRA 		OROREG
				
OROAN			LEA			INDIRECTADAB,A1
				TRAP 		#15 			;now printed "OR.x  (A"
				CLR.B 		D6
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6  		;leave just the last 3 bits non-zero to tell which reg it is
				CLR.B 		D1
				MOVE.B 		D6,D1 			;move the number to D1 to print
				MOVE.L 		#3,D0
				TRAP 		#15				;have now printed "OR.x  (An"
				MOVE.L		#14,D0
				LEA 		CLOSEPAREN,A1
				TRAP 		#15 			;have now printed "OR.x  (An)"
				BRA 		OROREG
				
OROABSIMM		CLR.B 		D6 				;check what the last 3 bits equal to determine what to print out now
				MOVE.B 		D5,D6
				ANDI.B 		#$07,D6
				CMPI.B 		#04,D6
				BEQ 		OROIMM			;if last nybble == 0100, it's an immediate
				LEA 		DOLLARSIGN,A1	;else it's ABS so print the $
				TRAP 		#15 			;have now printed "OR.x  $"
				MOVE.B 		#16,D2 			;allows for trap task #15 to display hex numbers
				MOVE.L 		#15,D0			;load trap task 15 for later
				CMPI.B 		#0,D6			;if the last 3 bits were 0, it's (xxx).W
				BEQ         ORABSWORD		;else it's just (xxx).L
				MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				MOVE.L      (A2)+,D1		;move the whole long into D1
				TRAP 		#15				;have now printed "OR.x  $xxxxxxxx"
				
				BRA 		OROREG
				
OROABSWORD		MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				CLR.L 		D3
				MOVE.W      (A2)+,D3		;move the next word into D1
				CMP.W 		#$8000,D3		;check if you need to sign extend
				BCC 		OROADDF
				CLR.L 		D1
				MOVE.W 		D3, D1			;Move into D1 to print

				

OROABSWTRAP		TRAP 		#15				;have now printed "OR.x  $xxxx"
                
                BRA         OROREG         ;go to the next instruction
				
OROADDF 		MOVE.L 		#$FFFFFFFF,D1 	;set the sign extension up
				MOVE.W 		D3,D1 			;move the rest of the word, then onto the print task
				BRA 		OROABSWTRAP


				
				
				
OROIMM 			MOVE.B 		D5,D6
				ANDI.B 		#$C0,D6
				LSR.B 		#6,D6 				;move the first two values to the end of the byte
				LEA 		POUNDSIGN,A1
				TRAP 		#15 			;have now printed "ORO.x  #"
				MOVE.L      #3,D0              ;load trap task 3 for later
				CMPI.B 		#0,D6
				BEQ			OROBYTEIMM
				CMPI.B 		#1,D6
				BEQ			OROWORDIMM
				BRA 		OROLONGIMM
                
OROBYTEIMM		CLR.L       D1
                CLR.W       D6
                MOVE.W      (A2)+,D6            ;grab the byte of the next word.
                MOVE.B      D6,D1
                TRAP        #15                 ;have now printed "OR.x  #xx"
				BRA 		OROREG
                
OROWORDIMM		CLR.L       D1
                CLR.W       D6
                MOVE.W      (A2)+,D6            ;grab the next word.
                MOVE.W      D6,D1
                TRAP        #15                 ;have now printed "OR.x  #xxxx"
				BRA 		OROREG
                
OROLONGIMM	    CLR.L       D1
                CLR.L       D6
                MOVE.L      (A2)+,D6            ;grab the long of the next word.
                MOVE.L      D6,D1
                TRAP        #15                 ;have now printed "OR.x  #xxxxxxxx"
				BRA 		OROREG


********************************************************************************* END OF OR DISSASSEMBLY ***************************************************************************









********************************************************************************* START OF ORI DISSASSEMBLY ***************************************************************************


ORICASE			MOVEM       D5,-(SP)        ;save D5 incase you change it at some point
                *ORI's 3rd nybble (byte's first nybble) has to be B or lower
                CLR.W       D6
                MOVE.B      D5,D6
                ANDI.B      #$F0,D6
                CMPI.B      	#$C0,D6
                BCC         DATACASE        ;if it's C or higher, it's data
                LEA         ORIMESSAGE,A1
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "ORI"
                *now let's check the size, which will impact what you print next in addition to the qualifier
                *first two bits of the byte's first nybble determine size
                ANDI.B      #$C0,D6         ;D6 still has the full first nybble stored, so just clear out the last two bits of the first nybble
                LSR         #6,D6           ;move those first two bits to the end
                CMPI.B      #0,D6
                BEQ         ORIBYTE        ; if it ==0, it's a byte 
                CMPI.B      #1,D6
                BEQ         ORIWORD        ;if it == 1, it's a word
ORILONG        	LEA         LONGEND,A1      ;else it's a long
                TRAP        #15             ;Have now printed "ORI.L  "
                LEA         POUNDSIGN,A1    
                TRAP        #15             ;have now printed "ORI.L  #"
                MOVE.L      #15,D0              ;load trap task 15 for later
                MOVE.B      #10,D2              ;make sure it prints in decimal
                CLR.L       D1
                CLR.W       D6
                MOVE.L      (A2)+,D6            ;grab the next long.
                MOVE.L      D6,D1
                TRAP        #15                 ;have now printed "ORI.L  #xxxxxxxx"
                BRA         ORIEA
                

ORIWORD        	LEA         WORDEND,A1      ;else it's a long
                TRAP        #15             ;Have now printed "ORI.W  "
                LEA         POUNDSIGN,A1    
                TRAP        #15             ;have now printed "ORI.W  #"
                MOVE.L      #15,D0              ;load trap task 15 for later
                MOVE.B      #10,D2              ;make sure it prints in decimal
                CLR.L       D1
                CLR.W       D6
                MOVE.W      (A2)+,D6            ;grab the next word.
                MOVE.W      D6,D1
                TRAP        #15                 ;have now printed "ORI.W  #xxxx"
                BRA         ORIEA

ORIBYTE        	LEA         BYTEEND,A1      ;else it's a long
                TRAP        #15             ;Have now printed "ORI.B  "
                LEA         POUNDSIGN,A1    
                TRAP        #15             ;have now printed "ORI.B  #"
                MOVE.L      #15,D0              ;load trap task 15 for later
                MOVE.B      #10,D2              ;make sure it prints in decimal
                CLR.L       D1
                CLR.W       D6
                MOVE.W      (A2)+,D6            ;grab the byte from the next word.
                MOVE.B      D6,D1
                TRAP        #15                 ;have now printed "ORI.L  #xx"
                BRA         ORIEA
                
ORIEA          	LEA         COMMASPACE,A1
                MOVE.L      #14,D0
                TRAP        #15             ;have now printed "ORI.x  #x, "
                *next is to figure out which type of EA it is and print that out
                *the last 2 bits of the byte's first nybble help determine the mode
                CLR.B       D6
                MOVE.B      D5,D6
                ANDI.B      #$30,D6
                CMPI.B      #0,D6           ;if == 0, it's a data reg
                BEQ         ORIDN
                CMPI.B      #$10,D6         ;if == 0001 0000, it's (An) or (An)+
                BEQ         ORIINCORAN
                CMPI.B      #$20,D6         ;if it's == 0010 0000, it's -(An)
				BEQ 		ORIDEC
                BRA         ORIABS         ;else it's an absolute
                
ORIDN          	LEA         DATAREG,A1
                TRAP        #15             ;have now printed "ORI.x  #x, D"
                CLR.B       D6
                MOVE.B      D5,D6           ;last 3 bits of the byte determine the reg
                ANDI.B      #07,D6
                MOVE.L      #3,D0           ;load trap task 3
                CLR.L       D1
                MOVE.B      D6,D1
                TRAP        #15             ;have now printed "ORI.x  #x, Dn"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction        
                
ORIINCORAN     	CLR.B       D6              ;determine which [(An) or (An)+] it is based on the first bit of the last nybble
                MOVE.B      D5,D6
                ANDI.B      #$08,D6
                CMPI.B      #8,D6
                BEQ         ORIINC         ;if its == 0000 1000, it's (An)+
ORIAN          	LEA         INDIRECTADAB,A1 ;otherwise it's (An), so start printing out stuff
                TRAP        #15             ;have now printed "ORI.x  #x, (A"
                CLR.B       D6
                MOVE.B      D5,D6           ;last 3 bits of the byte determine the reg
                ANDI.B      #07,D6
                MOVE.L      #3,D0           ;load trap task 3
                CLR.L       D1
                MOVE.B      D6,D1
                TRAP        #15             ;have now printed "ORI.x  #x, (An"
                MOVE.L      #14,D0
                LEA         CLOSEPAREN,A1
                TRAP        #15             ;have now printed "ORI.x  #x, (An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction 

ORIINC         	LEA         INDIRECTADAB,A1
                TRAP        #15             ;have now printed "ORI.x  #x, (A"
                CLR.B       D6
                MOVE.B      D5,D6           ;last 3 bits of the byte determine the reg
                ANDI.B      #07,D6
                MOVE.L      #3,D0           ;load trap task 3
                CLR.L       D1
                MOVE.B      D6,D1
                TRAP        #15             ;have now printed "ORI.x  #x, (An"
                MOVE.L      #14,D0
                LEA         INCREMENTEND,A1
                TRAP        #15             ;have now printed "ORI.x  #x, (An)+"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction 

ORIDEC         	LEA         INDIRECTADDECB,A1 
                TRAP        #15             ;have now printed "ORI.x  #x, (-A"
                CLR.B       D6
                MOVE.B      D5,D6           ;last 3 bits of the byte determine the reg
                ANDI.B      #07,D6
                MOVE.L      #3,D0           ;load trap task 3
                CLR.L       D1
                MOVE.B      D6,D1
                TRAP        #15             ;have now printed "ORI.x  #x, -(An"
                MOVE.L      #14,D0
                LEA         CLOSEPAREN,A1
                TRAP        #15             ;have now printed "ORI.x  #x, -(An)"
                
                MOVEM       (SP)+,D5        ;reload the stack
                BRA         LOOPEND         ;go to next instruction 
                
ORIABS         	CLR.B       D6
                MOVE.B      D5,D6           ;determine if it's (xxx).W or (xxx).L based on the last 3 bits
                ANDI.B      #$07,D6
                MOVE.L      #14,D0
                LEA 		DOLLARSIGN,A1
				TRAP 		#15 			;have now printed "ORI.x  #x, $"
                MOVE.B 		#16,D2 			;allows for trap task #15 to display hex numbers
				MOVE.L 		#15,D0			;load trap task 15 for later
                CLR.L       D1              ;clear D1 for later too
                CMPI.B      #0,D6
                BEQ         ORIABSWORD     ;if the last 3 bits are 0, it's (xxx).W
                *else it's (xxx).L
				MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				MOVE.L      (A2)+,D1		;move the whole long into D1
				TRAP 		#15				;have now printed "ORI.x  #x, $xxxxxxxx"
                
                BRA         LOOPEND         ;go to the next instruction
                
ORIABSWORD     	MOVEM       (SP)+,D5        ;reload the stack since you're about to alter D5's location anyway
				CLR.L 		D3
				MOVE.W      (A2)+,D3		;move the next word into D1
				CMP.W 		#$8000,D3		;check if you need to sign extend
				BCC 		ORIADDF
				CLR.L 		D1
				MOVE.W 		D3, D1			;Move into D1 to print

				

ORIABSWTRAP		TRAP 		#15				;have now printed "ORI.x  #x, $xxxx"
                
                BRA         LOOPEND         ;go to the next instruction
				
ORIADDF 		MOVE.L 		#$FFFFFFFF,D1 	;set the sign extension up
				MOVE.W 		D3,D1 			;move the rest of the word, then onto the print task
				BRA 		ORIABSWTRAP


********************************************************************************* END OF ORI DISSASSEMBLY ***************************************************************************








*Stop program
ENDCASE         SIMHALT             ; halt simulator


*currently tests: NOP, NEG, JSR, RTS, ASL, ASR, LSL, LSR
TESTCODE		*DATA TEST*
				NEGX 		D0
				NOT.B 		(A0)
				MOVEM 		(SP)+,D5
				
				*tests for CMP*
				CMP.B 		#1,D0    
				CMP.W 		$FFFF.W,D1 
				CMP.B 		$0123.W,D7
				CMP.L 		$FFFFFFFF,D2
				CMP.B 		-(A0),D3  
				CMP.W 		(A1)+,D4
				CMP.L 		(A2),D5
				CMP.L 		A3,D6
				CMP.L 		D7,D0
				
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
                NEG.B       $ABCDEFFF
                NEG.W       $FFFFFFFF
                NEG.L       $FFFFFFFF
                NEG.B       $FFFF.W
                NEG.W       $ABCD.W
                NEG.L       $1234.W			
				
				*tests for EOR*
				EOR.W 		D0,$FFFFFFFF	
				EOR.L 		D1,$FFFF.W		
				EOR.B 		D7,$0123.W		
                EOR.B		D2,D3 
				EOR.B		D4,(A0)         
				EOR.W		D5,-(A1)        
				EOR.L		D6,(A2)+ 
				
				*tests for JSR below
                JSR         (A1)
                JSR         $FFFFFFFF
                JSR         $FFFF.W
				JSR 		$0123.W
				
                
                *Tests for Branching*
                *16 bit disp?
                BRA         $00001000
                BCS         $00001000
                BGE         $00001000
                BLT         $00001000
                BVC         $00001000
                *8 bit disp
                BRA         $00002FF0
                BCS         $00002FF0
                BGE         $00002FF0
                BLT         $00002FF0
                BVC         $00002FF0
                *32 bit idk how to test but it should be the same logic, so I think it works
                BRA         $00000FFF
                BCS         $00000FFF
                BGE         $00000FFF
                BLT         $00000FFF
                BVC         $00000FFF
                
                *Not sure what the best way to test for different disp is...
                
				*tests for ORI below
				ORI.B 	#0, D0
				ORI.W 	#1000, (A0)
				ORI.L 	#10000000,-(A1)
				ORI.B 	#100, (A2)+
				ORI.W 	#1000, $ABCD.W
				ORI.L 	#10000000, $ABCDEFFF
				ORI.B 	#2, $0123.W
				
				
				*tests for OR below*
					*OR.x ea, Dn first
				OR.B 	#10,D7
				OR.B 	D0,D1
				OR.W 	(A0),D2
				OR.L 	-(A1),D3
				OR.B 	(A2)+,D4
				OR.W 	$FFFF.W,D5
				OR.L 	$FFFFFFFF,D6
					*now OR.x Dn, ea
				OR.B 	D0,(A3)
				OR.W 	D1,-(A4)
				OR.L 	D2,(A5)+
				OR.W 	D3, $FFFF.W
				OR.L 	D4, $FFFFFFFF
				OR.B 	D5,$0123.W
				
				
				
				*Tests for CMPI*
				CMPI.B 		#0,D0
				CMPI.W 		#1000,(A0)
				CMPI.L 		#10000,(A1)+
				CMPI.L 		#100000,-(A2)
				CMPI.L 		#1000000,$FFFF.W
				CMPI.B 		#2,$0123.W
				CMPI.L		#10000000,$FFFFFFFF
                
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
                *test for NOP below
                NOP
                
                *test for RTS
                RTS
                

* Put variables and constants here

STACKADDRESS    EQU         $7000    ;marks the location of the start of the stack

*various instruction's hex values (or partial hex values) are stored here
NOPCODE         EQU         $4E71       ;hex version of the NOP
RTSCODE         EQU         $4E75       ;Hex version of RTS
JSRSTARTBYTE    EQU         $4E         ;next two digits are 10+ EA Mode first 2 digits, final four are EA Mode final digit(1) and EA register (3)
NEGSTARTBYTE    EQU         $44         ;starting byte of NEG - next two bits are size, next 3 are EA mode, last 3 are EA reg
ALSRLSTARTNYBLE EQU         $E          ;starting nybble for ASL/ASR/LSL/LSR. next nybble determines reg/mem shift
BRASTARTBYTE    EQU         $60         ;starting byte for BRA
BCSSTARTBYTE    EQU         $65         ;starting byte for BCS
BGESTARTBYTE    EQU         $6C         ;starting byte for BGE
BLTSTARTBYTE    EQU         $6D         ;starting byte for BLT
BVCSTARTBYTE    EQU         $68         ;starting byte for BVC
CMPEORNYBBLE    EQU         $B          ;starting nybble for CMP and EOR.  Second nybble will be odd for EOR, even for CMP
CMPISTARTBYTE   EQU         $0C         ;starting byte for CMPI
ORSTARTNYBBLE   EQU         $8          ;starting nybble for OR
ORISTARTBYTE    EQU         $00         ;starting byte for ORI

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
BRAMESSAGE      DC.L        'BRA',0
BCSMESSAGE      DC.L        'BCS',0
BGEMESSAGE      DC.L        'BGE',0
BLTMESSAGE      DC.L        'BLT',0
BVCMESSAGE      DC.L        'BVC',0
CMPMESSAGE      DC.L        'CMP',0
CMPIMESSAGE     DC.L        'CMPI',0
EORMESSAGE      DC.L        'EOR',0
ORMESSAGE       DC.L        'OR',0
ORIMESSAGE      DC.L        'ORI',0


ADDRESSA        DC.L        'A',0           ;for printing ADDRESS (A) registers
INDIRECTADAB    DC.L        '(A',0          ;Beginning of the Indirect ADdress - used for start of increment as well
INDIRECTADDECB  DC.L        '-(A',0         ;Beginning of INDIRECT ADdress DECrement
INCREMENTEND    DC.L        ')+',0          ;END of INCREMENT address line

CLOSEPAREN      DC.L        ')',0           ;for closing Indirect Address normal and Decrement
DOLLARSIGN      DC.L        '$',0           ;for absolute address stuff (xxx).w/l
COMMASPACE      DC.L        ', ',0          ;for 2 argument instructions
POUNDSIGN       DC.L        '#',0           ;for printing immediate values

BYTEEND         DC.L        '.B  ',0          ;for instructions that are sized - this is a bite-sized one
WORDEND         DC.L        '.W  ',0          ;same, but word
LONGEND         DC.L        '.L  ',0          ;same, but long

DATAREG         DC.L        'D',0           ;D for data reg... this can probably be done better

CR              EQU         $0D             ;carriage return
NEWLINE         DC.L        '',CR           ;for making a newline
DOUBLESPACE     DC.L        '  ',0          ;needed to make a double space in some circumstances 

NEEDINPUT		DC.L 		'Press any key to disassemble more code from the file',CR
WHERETOSTART    DC.L        'Please enter the even address where you would like to start disassembling here.',CR
WHERETOSTARTPT  DC.L        'Please note addresses are 8 digits - anything less will be followed with 0s.',CR 
WHERETOSTARTPTO DC.L       'If the address is over 8 digits, only the first eight digits will be counted.',CR
WHERETOSTARTPTT DC.L        'Finally, non-valid digits will be replaced with 0 & only upper-case hex allowed. $',CR
NOTEVEN         DC.L        'Please enter an even address',CR


                END         START        ; last line of source


































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
