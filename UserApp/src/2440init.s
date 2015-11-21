;***********************************************************************
;
;					      S3C2440A 스타트업코드
;
;
; NAME: 2440init.s
;
; DESC: C start up codes
;       Configure memory, ISR ,stacks
;		Initialize C-variables
;
; HISTORY:
; 2002.02.25: kwtark: ver 0.0
; 2002.03.20: purnnamu: Add some functions for testing STOP,Sleep mode
; 2003.03.14: DonGo: Modified for 2440.
; 2005.07.30: KInG(kimingoo@hotmail.com): 강의용으로 편집
;***********************************************************************

; Start address of stacks & ISR vector
_ISR_STARTADDRESS_	EQU 0x33ffff00
_STACK_BASEADDRESS_	EQU 0x33ff8000

; The location of stacks
FIQStack	EQU		(_STACK_BASEADDRESS_-0x0)		; 0x33ff8000 ~
IRQStack	EQU		(_STACK_BASEADDRESS_-0x1000)	; 0x33ff7000 ~
AbortStack	EQU		(_STACK_BASEADDRESS_-0x2000)	; 0x33ff6000 ~
UndefStack	EQU		(_STACK_BASEADDRESS_-0x2400)	; 0x33ff5c00 ~
SVCStack	EQU		(_STACK_BASEADDRESS_-0x2800)	; 0x33ff5800 ~
UserStack	EQU		(_STACK_BASEADDRESS_-0x3800)	; 0x33ff4800 ~

; SFR Memory address
WTCON 		EQU  	0x53000000						; Watch-dog timer mode
INTSUBMSK	EQU  	0x4a00001c						; Interrupt sub mask
INTOFFSET	EQU  	0x4a000014						; Interrupt request source offset
INTMSK   	EQU  	0x4a000008						; Interrupt mask control
CLKDIVN 	EQU  	0x4c000014						; Clock divider control
MPLLCON 	EQU  	0x4c000004						; MPLL Control
LOCKTIME	EQU  	0x4c000000						; PLL lock time counter
BWSCON  	EQU  	0x48000000						; Bus width & wait status

; Pre-defined constants
USERMODE    EQU 	0x10
FIQMODE     EQU 	0x11
IRQMODE     EQU 	0x12
SVCMODE     EQU 	0x13
ABORTMODE   EQU 	0x17
UNDEFMODE   EQU 	0x1b
MODEMASK    EQU 	0x1f
NOINT       EQU 	0xc0

	IMPORT	|Image$$RO$$Limit|  	
	IMPORT  |Image$$RW$$Base|   	
	IMPORT  |Image$$ZI$$Base|   	
	IMPORT  |Image$$ZI$$Limit|  	
	
	IMPORT  Main    				

;===================================================		
	AREA    Init, CODE, READONLY
	ENTRY

	;-----------------------------------------------
	;	Exception vector initialization
	;-----------------------------------------------
	B		ResetHandler
	B		HandlerUndef			
	B		HandlerSWI				
	B		HandlerPabort			
	B		HandlerDabort			
	B		.						
	B		HandlerIRQ	
	B		HandlerFIQ				

HandlerFIQ
	SUB		SP,  SP, #4				
	STMFD	SP!, {R0}				
	LDR     R0,  =HandleFIQ			
	LDR     R0,  [R0]	 			
	STR     R0,  [SP,#4]      		
	LDMFD   SP!, {R0,PC}     		


ResetHandler
	BL		DisWDT			; Disable watchdog timer
	BL		DisINT			; Disable interrupts
	BL		InitClock		; Clock initialization
	BL		InitMemCtr		; Memory bank initialization
	BL		InitStacks		; Stack initialization
	BL		SetupIRQ		; Setup IRQ exception handler
	BL		InitVar			; Initialization RW/ZI data area
	BL		Main			; Jump to Main
	B		.
	
	
HandlerUndef
	SUB		SP,  SP, #4
	STMFD	SP!, {R0}
	LDR     R0,  =HandleUndef
	LDR     R0,  [R0]         
	STR     R0,  [SP, #4]      
	LDMFD   SP!, {R0, PC}  
	
	
HandlerSWI
	SUB		SP,  SP, #4
	STMFD	SP!, {R0}
	LDR     R0,  =HandleSWI
	LDR     R0,  [R0]         
	STR     R0,  [SP, #4]      
	LDMFD   SP!, {R0, PC}  
	
		
HandlerPabort
	SUB		SP,  SP, #4
	STMFD	SP!, {R0}
	LDR     R0,  =HandlePabort
	LDR     R0,  [R0]         
	STR     R0,  [SP, #4]      
	LDMFD   SP!, {R0, PC}  
	

HandlerDabort
	SUB		SP,  SP, #4
	STMFD	SP!, {R0}
	LDR     R0,  =HandleDabort
	LDR     R0,  [R0]         
	STR     R0,  [SP, #4]      
	LDMFD   SP!, {R0, PC}
	
				
HandlerIRQ
	SUB		SP,  SP, #4
	STMFD	SP!, {R0}
	LDR     R0,  =HandleIRQ
	LDR     R0,  [R0]         
	STR     R0,  [SP, #4]      
	LDMFD   SP!, {R0, PC}  
	

;===================================================
IsrIRQ  
	SUB		SP,  SP, #4       
	STMFD	SP!, {R8-R9}
	LDR		R9,  =INTOFFSET	
	LDR		R9,  [R9]
	LDR		R8,  =HandleEINT0
	ADD		R8,  R8, R9, lsl #2
	LDR		R8,  [R8]
	STR		R8,  [SP, #8]
	LDMFD	SP!, {R8-R9, PC}
	
	
;===================================================
DisWDT
	; watch dog disable
	LDR		R0, =WTCON
	LDR		R1, =0x0
	STR		R1, [R0]
	
		
;===================================================
DisINT	
	; all interrupt disable
	LDR		R0, =INTMSK
	LDR		R1, =0xffffffff
	STR		R1, [R0]

	; all sub interrupt disable
	LDR		R0, =INTSUBMSK
	LDR		R1, =0x7fff
	STR		R1, [R0]
	
	
;===================================================
InitClock	
	; To reduce PLL lock time, adjust the LOCKTIME reg.
	LDR		R0, =LOCKTIME
	LDR		R1, =0xffffff
	STR		R1, [R0]

	; Fclk : Hclk : Pclk = 1 : 3 : 6
	LDR		R0, =CLKDIVN
	LDR		R1, =7
	STR		R1, [R0]

	; Configure MPLL (Fin=16.9344MHz, Fclk = 399651840)
	LDR		R0, =MPLLCON
	LDR		R1, =((110<<12)+(3<<4)+(1<<0))
	STR		R1, [R0]
	
		
;===================================================
InitMemCtr
    LDR		R0, =SMRDATA
	LDR		R1, =BWSCON				
	ADD		R2, R0, #52		; End address of SMRDATA			
0       
	LDR		R3, [R0], #4    
	STR		R3, [R1], #4    
	CMP		R2, R0		
	BNE		%B0
	MOV		PC, LR
	
	
;===================================================
InitStacks
	MRS		R0, CPSR
	BIC		R0, R0, #MODEMASK
	ORR		R1, R0, #UNDEFMODE|NOINT
	MSR		CPSR_cxsf, R1		
	LDR		SP, =UndefStack		

	ORR		R1, R0, #ABORTMODE|NOINT
	MSR		CPSR_cxsf, R1		
	LDR		SP, =AbortStack		

	ORR		R1, R0, #IRQMODE|NOINT
	MSR		CPSR_cxsf, R1		
	LDR		SP, =IRQStack		

	ORR		R1, R0, #FIQMODE|NOINT
	MSR		CPSR_cxsf, R1		
	LDR		SP, =FIQStack		

	BIC		R0, R0, #MODEMASK|NOINT
	ORR		R1, R0, #SVCMODE
	MSR		CPSR_cxsf, R1		
	LDR		SP, =SVCStack		

	; User mode has not be initialized.

	MOV		PC, LR


;===================================================
SetupIRQ
	LDR		R0, =HandleIRQ
	LDR		R1, =IsrIRQ
	STR		R1, [R0]
	
	
;===================================================
InitVar
	LDR		R0, =|Image$$RO$$Limit| 	 
	LDR		R1, =|Image$$RW$$Base|		 
	LDR		R3, =|Image$$ZI$$Base|		
			
	CMP		R0, R1				 
	BEQ		%F1
0		
	CMP		R1, R3			; init RW Section						
	LDRCC	R2, [R0], #4
	STRCC	R2, [R1], #4
	BCC		%B0
1		
	LDR		R1, =|Image$$ZI$$Limit| 	 
	MOV		R2, #0
2		
	CMP		R3, R1			; init ZI Section					
	STRCC	R2, [R3], #4
	BCC		%B2	
	
	MOV		PC, LR


;===================================================	
SMRDATA DATA
	DCD		0x22121110
	DCD     0x00000700
	DCD     0x00000700
	DCD     0x00000700
	DCD     0x00000700
	DCD     0x00000700
	DCD     0x00000700
	DCD     0x00018005
	DCD     0x00018005
	DCD     0x009604f5
	DCD     0x00000032
	DCD     0x00000030
	DCD     0x00000030
	
	
;===================================================
	AREA RamData, DATA, READWRITE
	^   _ISR_STARTADDRESS_		
HandleReset 	#   4
HandleUndef 	#   4
HandleSWI		#   4
HandlePabort    #   4
HandleDabort    #   4
HandleReserved  #   4
HandleIRQ		#   4
HandleFIQ		#   4

HandleEINT0		#   4
HandleEINT1		#   4
HandleEINT2		#   4
HandleEINT3		#   4
HandleEINT4_7	#   4
HandleEINT8_23	#   4
HandleCAM		#   4		
HandleBATFLT	#   4
HandleTICK		#   4
HandleWDT_AC97	#   4
HandleTIMER0 	#   4
HandleTIMER1 	#   4
HandleTIMER2 	#   4
HandleTIMER3 	#   4
HandleTIMER4 	#   4
HandleUART2  	#   4
HandleLCD 		#   4
HandleDMA0		#   4
HandleDMA1		#   4
HandleDMA2		#   4
HandleDMA3		#   4
HandleMMC		#   4
HandleSPI0		#   4
HandleUART1		#   4
HandleNFCON		#   4		
HandleUSBD		#   4
HandleUSBH		#   4
HandleIIC		#   4
HandleUART0 	#   4
HandleSPI1 		#   4
HandleRTC 		#   4
HandleADC 		#   4

	END