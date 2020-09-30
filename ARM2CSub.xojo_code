#tag Class
Protected Class ARM2CSub
Inherits Application
	#tag Event
		Sub Open()
		  init
		  
		End Sub
	#tag EndEvent


	#tag Note, Name = Branch Instructions
		00-23, Offset
		24, L, 0=ordinary branch, 1=branch with link
		25-27, 101
		28-31, COND, conditional code
		
	#tag EndNote

	#tag Note, Name = Conditional Codes
		COND codes
		0000 EQ
		0001 NE
		0010 CS
		0011 CC
		0100 MI
		0101 PL
		0110 VS
		0111 VC
		1000 HI
		1001 LS
		1010 GE
		1011 LT
		1100 GT
		1101 LE
		1110 AL
		1111 NV
		
		
	#tag EndNote

	#tag Note, Name = Data Processing Instructions
		00-11, Operand2, register (possibly shifted) or immediate constant 
		  when register shifted
		  00-03 register
		  04-06 shift operation
		    000 LSL#, ASL#
		    001 LSL R, ASL R
		    010 LSR#
		    011 LSR R
		    100 ASR
		    101 ASR R
		    110 ROR, RRX (without #)
		    111 ROR R
		  07-11 shift #
		12-15, Rd,  number of destination register
		16-19, Rn, number of register used as operand 1
		20, S, 0=modify status flag on execution
		21-24, Opcode, instruction code
		25, I, 0=operand 2 is register, 1=operand 2 is constant
		26-27, 00
		28-31, COND, conditional code
		
		Opcodes
		0000 AND
		0001 EOR
		0010 SUB
		0011 RSB
		0100 ADD
		0101 ADC
		0110 SBC
		0111 RSC
		1000 TST
		1001 TEQ
		1010 CMP
		1011 CMN
		1100 ORR
		1101 MOV
		1110 BIC
		1111 MVN
		
		 
		
		
		
	#tag EndNote

	#tag Note, Name = Multiple Register Transfer
		00-15, register list
		16-19, Rn, number of register used as operand 1
		20, L, 0=STR, 1=LDR
		21, W, 1=perform writeback
		22, S, 1=load status register
		23, U, 1=offset added to base address, 0=offset substracted from base address
		24, P, 0=pre-index, 1=post-index
		25-27, 100
		28-31, COND, conditional code
		
		
		 
		
		
		
	#tag EndNote

	#tag Note, Name = Multiply Instructions
		00-03, Rm, number of register
		04-07, 1001
		08-11, Rs, number of register
		12-15, Rd,  number of destination register
		16-19, Rn, number of register used as operand 1
		20, S, 0=modify status flag on execution
		21, A, 0=multiply only, 1=multiply and accumulate 
		22-27, 000000
		28-31, COND, conditional code
		
	#tag EndNote

	#tag Note, Name = Single Register Transfer
		00-11, Offset
		12-15, Rd,  number of destination register
		16-19, Rn, number of register used as operand 1
		20, L, 0=STR, 1=LDR
		21, W, 1=perform writeback
		22, B, 1=byte addressing, 0=word addressing
		23, U, 1=offset added to base address, 0=offset substracted from base address
		24, P, 0=pre-index, 1=post-index
		25, I, 0=operand 2 is register, 1=operand 2 is constant
		26-27, 01
		28-31, COND, conditional code
		
		
		 
		
		
		
	#tag EndNote

	#tag Note, Name = SWI Instruction
		00-23, Comment/Data field
		24-27, 1111
		28-31, COND, conditional code
		
		
	#tag EndNote


	#tag Constant, Name = kEditClear, Type = String, Dynamic = False, Default = \"&Delete", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"&Delete"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"&Delete"
	#tag EndConstant

	#tag Constant, Name = kFileQuit, Type = String, Dynamic = False, Default = \"&Quit", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"E&xit"
	#tag EndConstant

	#tag Constant, Name = kFileQuitShortcut, Type = String, Dynamic = False, Default = \"", Scope = Public
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"Cmd+Q"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"Ctrl+Q"
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
