/*
This is a C++ implementation of what will be translated into a 68K
assembly disassembler - that is, it will take in binary code and 
convert it to 68K assembly instructions.
*/

/*
REQUIRED INSTRUCTIONS TO DISSASSEMBLE
	
    MOVE, MOVEA, MOVEM						
    *ADD, *ADDA							
    SUB, SUBQ							
    MULS, DIVS							
    LEA									
    OR, ORI								
    NEG									
    EOR									
    LSR, LSL							
    ASR, ASL							
    ROL, ROR							
    *BCLR								
    CMP, CMPI							
    *Bcc (BCS, BGE, BLT, BVC)			
    *BRA, JSR, RTS		


*Bcc (BCS, BGE, BLT, BVC)
JSR,
LEA
LSL
LSR,
MULS,
NEG
OR,
ORI
ROL,
ROR
RTS
SUB,
SUBQ	

	
EFFECTIVE ADDRESSING MODES

	
    Data Register Direct:        Dn
    Address Register Direct:     An
    Address Register Indirect:  (An)
    Address Register Indirect with Post incrementing: (A0)+
    Address Register Indirect with Pre decrementing:  -(SP)
    Immediate Data: #
    Absolute Long Address: (xxx).L
    Absolute Word Address: (xxx).W

	
If the instruction recieved is not required, output DATA.

Displacement is worth extra points.
*/

/*
REFERENCES

T* True 0000 
F* False 0001
HI High 0010
LS Low or Same 0011
CC(HI) Carry Clear 0100 
CS(LO) Carry Set 0101
NE Not Equal 0110 
EQ Equal 0111 
VC Overflow Clear 1000
VS Overflow Set 1001
PL Plus 1010
MI Minus 1011 
GE Greater or Equal 1100 
LT Less Than 1101
GT Greater Than 1110  Z
LE Less or Equal 1111


Rounding Mode (RND Field)		 Encoding 		Rounding Precision (PREC Field)
To Nearest (RN) 					0 0			Extend (X)
To Zero (RZ) 						0 1 		Single (S)
To Minus Infinity (RM)				1 0 		Double (D)
To Plus Infinity (RP) 				1 1 		Undefined

FPCC Encodings 
Data Type 							N 		Z 		I 		NAN
+ Normalized or Denormalized 		0		0		0		0
– Normalized or Denormalized 		1		0		0		0
+ 0 								0 		1 		0 		0
– 0 								1 		1 		0 		0
+ Infinity 							0		0		1		0
– Infinity 							1		0		1		0
+ NAN 								0 		0		0 		1
– NAN 								1 		0 		0 		1


Mnemonic 			Definition 					Equation 		Predicate 		BSUN Bit Set
											IEEE Nonaware Tests
EQ 					Equal 							Z 			000001 				No
NE 					Not Equal 						Z 			001110				No 
GT 					Greater Than				NAN V Z V N		010010 				Yes 
NGT					Not Greater Than 			NAN V Z V N 	011101 				Yes
GE 					Greater Than or Equal 		Z V (NAN V N) 	010011 				Yes 
NGE					Not Greater Than or Equal 	NAN V (N Λ Z) 	011100 	Yes
LT 					Less Than 					N Λ (NAN V Z) 	010100 Yes
NLT					Not Less Than 				NAN V (Z V N) 011011 Yes
LE 					Less Than or Equal 			Z V (N Λ NAN) 010101 Yes
NLE					Not Less Than or Equal 		NAN V (N V Z) 011010 Yes
GL 					Greater or Less Than 		NAN V Z 010110 Yes
NGL					Not Greater or Less Than 	NAN V Z 011001 Yes
GLE					Greater, Less or Equal 		NAN 010111 Yes
NGLE 				Not Greater, Less or Equal 	NAN 011000 Yes
											IEEE Aware Tests
EQ Equal Z 000001 No
NE Not Equal Z 001110 No
OGT Ordered Greater Than NAN V Z V N 000010 No
ULE Unordered or Less or Equal NAN V Z V N 001101 No
OGE Ordered Greater Than or Equal Z V (NAN V N) 000011 No 
ULT Unordered or Less Than NAN V (N Λ Z) 001100 No
OLT Ordered Less Than N Λ (NAN V Z) 000100 No
UGE Unordered or Greater or Equal NAN V Z V N 001011 No
OLE Ordered Less Than or Equal Z V (N Λ NAN) 000101 No
UGT Unordered or Greater Than NAN V (N V Z) 001010 No
OGL Ordered Greater or Less Than NAN V Z 000110 No
UEQ Unordered or Equal NAN V Z 001001 No
OR Ordered NAN 000111 No
UN Unordered NAN 001000 No
											Miscellaneous Tests
F False False 000000 No
T True True 001111 No
SF Signaling False False 010000 Yes
ST Signaling True True 011111 Yes
SEQ Signaling Equal Z 010001 Yes
SNE Signaling Not Equal Z 011110 Yes




										EFFECTIVE ADDRESSING MODES AND CATEGORIES (pg. 60)
											* indicates required, ** indicates optional at end
											nothing means don't bother with

Addressing Modes				Syntax			Mode Field		Reg. Field 		Data 	Memory 	Control	 Alterable
Register Direct
 *Data							Dn				000				reg no.			X			-		-		X
 *Address						An 				001				reg. no. 		—			-		-		X

Register Indirect
 *Address						(An)			010				reg. no.		X			X		X		X
 *Address with Postincrement	(An)+			011				reg. no.		X			X		-		X
 *Address with Predecrement		-(An)			100				reg. no.		X			X		-		X
 **Address with Displacement	(d16, An)		101				reg. no.		X			X		X		X
 
Address Register Indirect with Index
 **8-Bit Displacement			(d8,An,Xn)		110				reg. no.		X			X		X		X
 **Base Displacement 			(bd,An,Xn)		110				reg. no.		X			X		X		X
 
Memory Indirect
 Postindexed					([bd,An],Xn,od)	110				reg. no.		X			X		X		X
 Preindexed						([bd,An,Xn],od)	110				reg. no.        X			X		X		X
 
Program Counter Indirect
 with Displacement 				(d16,PC) 		111 			010 			X 			X 		X 		—
 
Program Counter Indirect with Index
 8-Bit Displacement				(d8,PC,Xn)	111				011				X			X		X		-
 Base Displacement 				(bd,PC,Xn)		111				011				X			X		X		-
 
Program Counter Memory Indirect
 Postindexed					([bd,PC],Xn,od)	111				011				X			X		X		X
 Preindexed 					([bd,PC,Xn],od)	111				011       		X			X		X		X
 
Absolute Data Addressing
 *Short							(xxx).W			111				000				X			X		X		-
 *Long 							(xxx).L			111				000             X			X		X		-

*Immediate						#<xxx> 			111 			100 			X 			X 		— 		—*





									INTEGER OPERATIONS

									ADD
15 14 13 12 		11 10 9 		8 7 6 		5 4 3		2 1 0 
1  1  0  1 			REGISTER 		OPMODE		EA MODE 	EA REGISTER

			OPMODE
	BYTE	Word	Long	Operation
	000		001		010		<ea> + Dn -> Dn
	100		101		110		Dn + <ea> -> <ea>
	
	EA			Mode	Register
	Dn			000		reg. number:Dn			if location is source operand
	An*			001		reg. number:An			if location is source operand
	(An) 		010		reg. number: An
	(An)+ 		011		reg. number: An
	-(An) 		100		reg. number: An
	(d16,An)	101		reg. number: An  <-- address with displacement
	(d8,An,xn)	110		reg. number: An	 <-- 8 bit displacement
	(xxx).W		111		000
	(xxx).L		111		001
	#<data>		111		100						if location is source operand
	
	

									ADDA
15 14 13 12 		11 10 9 		8 7 6 		5 4 3		2 1 0 
1  1  0  1 			REGISTER 		OPMODE		EA MODE 	EA REGISTER

			OPMODE
	Word	Long
	011		111
	
	EA			Mode	Register
	Dn			000		reg. number:Dn			
	An*			001		reg. number:An			
	(An) 		010		reg. number: An
	(An)+ 		011		reg. number: An
	-(An) 		100		reg. number: An
	(d16,An)	101		reg. number: An  <-- address with displacement
	(d8,An,xn)	110		reg. number: An	 <-- 8 bit displacement
	(xxx).W		111		000
	(xxx).L		111		001
	#<data>		111		100		

	
	
	
	
									ASL, ASR pg. 125
                                    Register Shifts
15 14 13 12 11 10 9             8       7 6         5       4 3     2 1 0 
1  1  1  0  COUNT? REGISTER     dr      SIZE        i/r     0 0     REGISTER 

    Count/Register ﬁeld—Speciﬁes shift count or register that contains the shift count:
        If i/r = 0, this ﬁeld contains the shift count.  The values 1 – 7 represent counts
            of 1 – 7; a value of zero represents a count of eight.
        If i/r = 1, this ﬁeld speciﬁes the data register that contains the shift count (modulo 64)
    dr ﬁeld—Speciﬁes the direction of the shift.
        0 — Shift right
        1 — Shift left 
    Size ﬁeld—Speciﬁes the size of the operation.
        00 — Byte operation 
        01 — Word operation 
        10 — Long operation
    i/r ﬁeld 
        If i/r = 0, speciﬁes immediate shift count. 
        If i/r = 1, speciﬁes register shift count. 
    Register ﬁeld—Speciﬁes a data register to be shifted. 
 
									Memory Shifts
15 14 13 12 11 10 9 	8 	7 6		5 4 3 		2 1 0 
1  1  1  0  0  0  0 	dr 	1 1     EA Mode     EA register
    
    dr ﬁeld—Speciﬁes the direction of the shift.
        0 — Shift right
        1 — Shift left 
        
    EA			Mode	Register			
	(An) 		010		reg. number: An
	(An)+ 		011		reg. number: An
	-(An) 		100		reg. number: An
	(d16,An)	101		reg. number: An  <-- address with displacement
	(d8,An,xn)	110		reg. number: An	 <-- 8 bit displacement
	(xxx).W		111		000
	(xxx).L		111		001
    


									Bcc pg. 130
15 14 13 12 		11 10 9 8 		7 6 5 4 3 2 1 0
0  1  1  0 			CONDITION 		8-BIT DISPLACEMENT
	16-BIT DISPLACEMENT IF 8-BIT DISPLACEMENT = $00
	32-BIT DISPLACEMENT IF 8-BIT DISPLACEMENT = $FF 
	
	Condition ﬁeld—The binary code for one of the conditions listed in the table. 
	8-Bit Displacement ﬁeld—Twos complement integer specifying the number of bytes
		between the branch instruction and the next instruction to be executed if the condition is met. 
	16-Bit Displacement ﬁeld—Used for the displacement when the 8-bit displacement ﬁeld contains $00. 
	32-Bit Displacement ﬁeld—Used for the displacement when the 8-bit displacement ﬁeld contains $FF.
	A branch to the immediately following instruction automatically uses the 16-bit displacement format
		because the 8-bit displacement ﬁeld contains $00 (zero offset). 

		

									BCLR pg. 134
15 14 13 12 11 10 9 8 7 6 	5 4 3 		2 1 0 
0  0  0  0  1  0  0 0 1 0	EA MODE		EA REGISTER
0  0  0  0  0  0  0 0 <----- BIT NUMBER ----->

	EA			Mode	Register
	Dn*			000		reg. number:Dn					
	(An) 		010		reg. number: An
	(An)+ 		011		reg. number: An
	-(An) 		100		reg. number: An
	(d16,An)	101		reg. number: An  <-- address with displacement
	(d8,An,xn)	110		reg. number: An	 <-- 8 bit displacement
	(xxx).W		111		000
	(xxx).L		111		001
	
	
	
									BRA pg. 159
15 14 13 12 11 10 9 8 	7 6 5 4 3 2 1 0
0  1  1  0  0  0  0 0 	8-BIT DISPLACEMENT
	16-BIT DISPLACEMENT IF 8-BIT DISPLACEMENT = $00
	32-BIT DISPLACEMENT IF 8-BIT DISPLACEMENT = $FF

	8-Bit Displacement ﬁeld—Twos complement integer specifying the number of bytes
		between the branch instruction and the next instruction to be executed if the condition is met. 
	16-Bit Displacement ﬁeld—Used for the displacement when the 8-bit displacement ﬁeld contains $00. 
	32-Bit Displacement ﬁeld—Used for the displacement when the 8-bit displacement ﬁeld contains $FF.
	A branch to the immediately following instruction automatically uses the 16-bit displacement format
		because the 8-bit displacement ﬁeld contains $00 (zero offset). 
		

		
                                   CMP pg. 179
15 14 13 12     11 10 9     8 7 6       5 4 3       2 1 0 
1  0  1  1      REGISTER    OPMODE      EA MODE     EA REGISTER

    Register ﬁeld—Speciﬁes the destination data register. 
    Opmode ﬁeld 
        Byte    Word    Long    Operation
        000     001     010     Dn – < ea > 
    
    EA			Mode	Register
	Dn			000		reg. number:Dn			
	An*			001		reg. number:An			
	(An) 		010		reg. number: An
	(An)+ 		011		reg. number: An
	-(An) 		100		reg. number: An
	(d16,An)	101		reg. number: An  <-- address with displacement
	(d8,An,xn)	110		reg. number: An	 <-- 8 bit displacement
	(xxx).W		111		000
	(xxx).L		111		001
	#<data>		111		100		
    
    
    
    
                                CMPI pg. 183
                            CMPI # < data > , < ea >
15 14 13 12 11 10 9 8       7 6     5 4 3       2 1 0 
0  0  0  0  1  1  0 0       SIZE    EA MODE     EA REGISTER
<- 16-BIT WORD DATA ->      <--- 8-BIT BYTE DATA --->
<------------------ 32-BIT LONG DATA --------------->

    Size ﬁeld—Speciﬁes the size of the operation. 
        00 — Byte operation 
        01 — Word operation 
        10 — Long operation 

    EA			Mode	Register
	Dn			000		reg. number:Dn					
	(An) 		010		reg. number: An
	(An)+ 		011		reg. number: An
	-(An) 		100		reg. number: An
	(d16,An)	101		reg. number: An  <-- address with displacement
	(d8,An,xn)	110		reg. number: An	 <-- 8 bit displacement
	(xxx).W		111		000
	(xxx).L		111		001
    
    
    


                               DIVS pg.196                          <------ check things before this for condition codes, pg number, isntruction fields stuff, etc
                    DIVS.W < ea > ,Dn32/16 → 16r – 16q 
                    WORD OPERATION
15 14 13 12     11 10 9     8 7 6   5 4 3       2 1 0 
1  0  0  0      REGISTER    1 1 1   EA MODE     EA REGISTER

    Register ﬁeld—Speciﬁes any of the eight data registers. 
        This ﬁeld always speciﬁes the destination operand. 
    Effective Address ﬁeld—Speciﬁes the source operand
    
    EA			Mode	Register
	Dn			000		reg. number:Dn					
	(An) 		010		reg. number: An
	(An)+ 		011		reg. number: An
	-(An) 		100		reg. number: An
	(d16,An)	101		reg. number: An  <-- address with displacement
	(d8,An,xn)	110		reg. number: An	 <-- 8 bit displacement
	(xxx).W		111		000
	(xxx).L		111		001
	#<data>		111		100	
    
    CONDITION CODES
    X N Z V C
    — * * * 0 
    
    Overﬂow occurs if the quotient is larger than a 16-bit signed integer. 

                    LONG OPERATION  <-- 68020+ only?

                    
                    
                    
                    
                    
                            EOR pg. 204
                            EOR Dn, < ea >
                    WORD
15 14 13 12 11 10 9     8 7 6       5 4 3       2 1 0 
1  0  1  1  REGISTER    OPMODE      EA MODE     EA REGISTER

    Register ﬁeld—Speciﬁes any of the eight data registers. 
    Opmode ﬁeld
        Byte    Word    Long    Operation 
        100     101     110     < ea > ⊕ Dn → < ea > 
        
    EA			Mode	Register
	Dn			000		reg. number:Dn					
	(An)+ 		011		reg. number: An
	-(An) 		100		reg. number: An
	(d16,An)	101		reg. number: An  <-- address with displacement
	(d8,An,xn)	110		reg. number: An	 <-- 8 bit displacement
	(xxx).W		111		000
	(xxx).L		111		001
    
    CONDITION CODES
        X N Z V C
        — * * 0 0
        X — Not affected. 
        N — Set if the most signiﬁcant bit of the result is set; cleared otherwise.
        Z — Set if the result is zero; cleared otherwise. 
        V — Always cleared. 
        C — Always cleared
        
        
        
        
        
        
 
                                JSR pg. 213
                                JSR < ea >
                                
*/