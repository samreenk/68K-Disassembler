/*
This is a C++ implementation of what will be translated into a 68K
assembly disassembler - that is, it will take in binary code and 
convert it to 68K assembly instructions.
*/

/*
REQUIRED INSTRUCTIONS TO DISSASSEMBLE
	
    MOVE, MOVEA, MOVEM
    ADD, ADDA
    SUB, SUBQ
    MULS, DIVS
    LEA
    OR, ORI
    NEG
    EOR
    LSR, LSL
    ASR, ASL
    ROL, ROR
    BCLR
    CMP, CMPI
    Bcc (BCS, BGE, BLT, BVC)
    BRA, JSR, RTS

	
EFFECTIVE ADDRESSING MODES

	
    Data Register Direct:          Dn
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






									INTEGER OPERATIONS

									ADD
15 14 13 12 		11 10 9 		8 7 6 		5 4 3		2 1 0 
1  1  0  1 			REGISTER 		OPMODE		EA MODE 	EA REGISTER



*/