;*********************************************************************************************************
;                                               uC/OS-II
;                                         The Real-Time Kernel
;
;                          (c) Copyright 1992-2003, Jean J. Labrosse, Weston, FL
;                                          All Rights Reserved
;
;                                               ARM920T Port
;                                            ADS v1.2 Compiler
;                                             Samsung S3C2440A
;
; File    : os_cpu_a.s
; Des	  : S3C2440�� uC/OS-II Port 
; by      : ???
; History : 
; 2005.02.13: KInG(kimingoo@hotmail.com): 
;			  1. uC/OS-II 2/E �������� �ǻ��ڵ带 �ּ����� �ް� ������� �� ��ġ ��.
;			  2. ���ǿ� Ȯ���� ���� C�ҽ��� �ۼ��Ǵ� �κе� �ǻ��ڵ忡 ���� ����� �ڵ�� �ۼ���.
;			  Note: ARM�� ��Ʈ�� ������ �ǻ��ڵ� �״�� �ۼ� �� �� ������ ����!!
; 2005.07.30: KInG(kimingoo@hotmail.com): OSCtxSw(), OSIntCtxSw() Ÿ��Ʋ �ּ� ����
;*********************************************************************************************************

SRCPND   	EQU  0x4a000000    ; Source pending
INTPND   	EQU  0x4a000010    ; Interrupt request status

;*********************************************************************************************************
;                                    EXPORT and EXTERNAL REFERENCES
;*********************************************************************************************************
	IMPORT  OSRunning
	IMPORT  OSTCBCur
	IMPORT  OSTCBHighRdy
	IMPORT  OSPrioCur
	IMPORT  OSPrioHighRdy
	IMPORT  OSIntNesting
	IMPORT  OSIntCtxSwFlag
			
	IMPORT  OSIntEnter
	IMPORT  OSIntExit
	IMPORT  OSTaskSwHook
	IMPORT  OSTimeTick

	EXPORT  OSStartHighRdy
	EXPORT  OSCtxSw
	EXPORT  OSTickISR	
	EXPORT  OSIntCtxSw
	EXPORT  OS_IntCtxSw

	EXPORT  OSCPUSaveSR
	EXPORT  OSCPURestoreSR


	AREA UCOS_ARM, CODE, READONLY
	
;*********************************************************************************************************
;                                          START MULTITASKING
;                                       void OSStartHighRdy(void)
;
; The stack frame is assumed to look as follows:
;
;							    Entry Point(Task Name)				(High memory)
;                               LR(R14)
;                               R12
;                               R11
;                               R10
;                               R9
;                               R8
;                               R7
;                               R6
;                               R5
;                               R4
;                               R3
;                               R2
;                               R1
;                               R0 : argument
;                               CPSR
; OSTCBHighRdy->OSTCBStkPtr --> SPSR								(Low memory)
;
; Note : OSStartHighRdy() MUST:
;           a) Call OSTaskSwHook() then,
;           b) Set OSRunning to TRUE,
;           c) Switch to the highest priority task.
;*********************************************************************************************************
OSStartHighRdy  
	;----------------------------------------------------------------------------------	
	; ����� ���� �Լ� OSTaskSwHook() �� ȣ���Ѵ�;
	; OSRunning = TRUE;
	;----------------------------------------------------------------------------------	
	BL		OSTaskSwHook
	LDR		R0, =OSRunning          ; Indicate that multitasking has started
	MOV		R1, #1
	STRB 	R1, [R0]

	;----------------------------------------------------------------------------------		
	; ����� �½�ũ�� ���� �����͸� ���´�:
	; 		Stack pointer = OSTCBHighRdy->OSTCBStkPtr;
	;----------------------------------------------------------------------------------	
	LDR 	R0, =OSTCBHighRdy
	LDR 	R0, [R0]         
	LDR 	SP, [R0]         

	;----------------------------------------------------------------------------------		
	; �� �½�ũ�� �������κ��� ��� �������͸� �����Ѵ�;
	;----------------------------------------------------------------------------------	
	LDMFD 	SP!, {R0}  
	MSR 	SPSR_cxsf, R0
	LDMFD 	SP!, {R0}  
	MSR 	CPSR_cxsf, R0
	LDMFD 	SP!, {R0-R12, LR, PC}


;*********************************************************************************************************
;                                PERFORM A CONTEXT SWITCH (From task level)
;                                           void OSCtxSw(void)
;
; Note(s): 	   1) Upon entry: 
;              	  OSTCBCur      points to the OS_TCB of the task to suspend
;              	  OSTCBHighRdy  points to the OS_TCB of the task to resume
;
;          	   2) The stack frame of the task to suspend looks as follows:
;
;				  									LR(R14)					(High memory)
;           					                    R12
; 			                      			        R11
;           		                			    R10
;                   		           			 	R9
;                           		    			R8
;                               					R7
;                               					R6
;                               					R5
;                               					R4
;                               					R3
;                               					R2
;                               					R1
;                               					R0
;                               					CPSR
; 						OSTCBCur->OSTCBStkPtr ----> SPSR					(Low memory)
;
;
;          	   3) The stack frame of the task to resume looks as follows:
;
;			  		  								LR(R14)					(High memory)
;			           			                    R12
;           		            			        R11
;                   		        			    R10
;                           		   			 	R9
;                               					R8
;                               					R7
;			                               			R6
;           		                    			R5
;                   		            			R4
;                           		    			R3
;                               					R2
;                               					R1
;			                               			R0
;           		                    			CPSR
; 					OSTCBHighRdy->OSTCBStkPtr ---->	SPSR					(Low memory)
;*********************************************************************************************************
OSCtxSw
	;----------------------------------------------------------------------------------	
	; ���μ��� �������� ����;
	;----------------------------------------------------------------------------------		
	STMFD	SP!, {LR}
	STMFD	SP!, {R0-R12, LR}
	MRS		R0,  CPSR
	STMFD	SP!, {R0}	
	MRS		R0,  SPSR
	STMFD	SP!, {R0}	

	;----------------------------------------------------------------------------------	
	; ���� �½�ũ�� ���� �����͸� ���� �½�ũ�� �½�ũ ��Ʈ�� ��Ͽ� ����:
	; 		OSTCBCur->OSTCBStkPtr = ���� ������;
	;----------------------------------------------------------------------------------		
	LDR		R0, =OSTCBCur
	LDR		R0, [R0]
	STR		SP, [R0]
	
	;----------------------------------------------------------------------------------		
	; OSTaskSwHook();
	;----------------------------------------------------------------------------------	
	BL 		OSTaskSwHook

	;----------------------------------------------------------------------------------			
	; OSTCBCur = OSTCBHighRdy;
	;----------------------------------------------------------------------------------		
	LDR		R0, =OSTCBHighRdy
	LDR		R1, =OSTCBCur
	LDR		R0, [R0]
	STR		R0, [R1]
	
	;----------------------------------------------------------------------------------		
	; OSPrioCur = OSPrioHighRdy;
	;----------------------------------------------------------------------------------		
	LDR		R0, =OSPrioHighRdy
	LDR		R1, =OSPrioCur
	LDRB	R0, [R0]
	STRB	R0, [R1]
	
	;----------------------------------------------------------------------------------		
	; ������� �½�ũ�� ���� ������ ����:
	; 		���� ������ = OSTCBHighRdy->OSTCBStkPtr;
	;----------------------------------------------------------------------------------		
	LDR		R0, =OSTCBHighRdy
	LDR		R0, [R0]
	LDR		R0, [R0]
	MOV		SP, R0

	;----------------------------------------------------------------------------------	
	; ������� �½�ũ�� �������κ��� ���μ��� �������� ����;
	;----------------------------------------------------------------------------------	
	LDMFD 	SP!, {R0}		
	MSR 	SPSR_cxsf, R0
	LDMFD 	SP!, {R0}		
	MSR		CPSR_cxsf, R0
	LDMFD 	SP!, {R0-R12, LR, PC}	

	
;*********************************************************************************************************
;                                            TICK HANDLER
;
; Description:  
;     This handles all the Timer4(INT_TIMER4) interrupt which is used to generate the uC/OS-II tick.
;*********************************************************************************************************
OSTickISR
	;----------------------------------------------------------------------------------	
	; ���μ��� �������� ����
	;----------------------------------------------------------------------------------	
	STMFD   SP!, {R0-R3, R12, LR}
        
	;----------------------------------------------------------------------------------	
	; OSIntEnter() ȣ�� �Ǵ� OSIntNesting ���� 1 ����;
	;----------------------------------------------------------------------------------		
	BL      OSIntEnter

	;----------------------------------------------------------------------------------	
	; Ÿ�̸� ���ͷ�Ʈ �߻���ġ Ŭ����;
	;----------------------------------------------------------------------------------	
	MOV 	R1, #1
	MOV		R1, R1, LSL #14		; Timer4 Source Pending Reg.
	LDR 	R0, =SRCPND
	STR 	R1, [R0]

	LDR		R0, =INTPND
	LDR		R1, [R0]
	STR		R1, [R0]		

	;----------------------------------------------------------------------------------		
	; OSTimeTick();
	;----------------------------------------------------------------------------------	
	BL		OSTimeTick
	
	;----------------------------------------------------------------------------------	
	; OSIntExit();
	;----------------------------------------------------------------------------------	
	BL      OSIntExit

	;----------------------------------------------------------------------------------	
	; if(OSIntCtxSwFlag == TRUE) _IntCtxSw();
	;----------------------------------------------------------------------------------	
	LDR     R0, =OSIntCtxSwFlag    	; See if we need to do a context switch
	LDR     R1, [R0]
	CMP     R1, #1
	BEQ     OS_IntCtxSw           	; Yes, Switch to Higher Priority Task

	;----------------------------------------------------------------------------------	
	; ���μ��� �������� ����;
	;----------------------------------------------------------------------------------	
	LDMFD   SP!, {R0-R3, R12, LR}   ; No, Restore registers of interrupted task''s stack
        
	;----------------------------------------------------------------------------------	
	; ���ͷ�Ʈ ���� ��� ����;
	;----------------------------------------------------------------------------------		
	SUBS    PC, LR, #4         		; Return from IRQ		
	
	
;*********************************************************************************************************
;                                PERFORM A CONTEXT SWITCH (From an ISR)
;                                        void OSIntCtxSw(void)
;
; Description: 1) This code performs a context switch if a higher priority task has been made ready-to-run
;               	during an ISR.
;
;          	   2) The stack frame of the task to suspend looks as follows:
;
;				  									LR(R14)					(High memory)
;           					                    R12
; 			                      			        R11
;           		                			    R10
;                   		           			 	R9
;                           		    			R8
;                               					R7
;                               					R6
;                               					R5
;                               					R4
;                               					R3
;                               					R2
;                               					R1
;                               					R0
;                               					CPSR
; 						OSTCBCur->OSTCBStkPtr ----> SPSR					(Low memory)
;
;
;          	   3) The stack frame of the task to resume looks as follows:
;
;			  		  								LR(R14)					(High memory)
;			           			                    R12
;           		            			        R11
;                   		        			    R10
;                           		   			 	R9
;                               					R8
;                               					R7
;			                               			R6
;           		                    			R5
;                   		            			R4
;                           		    			R3
;                               					R2
;                               					R1
;			                               			R0
;           		                    			CPSR
; 					OSTCBHighRdy->OSTCBStkPtr ---->	SPSR					(Low memory)
;*********************************************************************************************************
OSIntCtxSw
	LDR 	R0, =OSIntCtxSwFlag		;OSIntCtxSwFlag = TRUE
	MOV 	R1, #1
	STR 	R1, [R0]
	MOV 	PC, LR

OS_IntCtxSw
	LDR     R0, =OSIntCtxSwFlag  	; OSIntCtxSwFlag = FALSE
	MOV     R1, #0
	STR     R1, [R0]

	LDMFD   SP!, {R0-R3, R12, LR}	; Clean up IRQ stack
	STMFD   SP!, {R0-R3}			; We will use R0-R3 as temporary registers
	MOV     R1, SP
	ADD     SP, SP, #16
	SUB     R2, LR, #4

	MRS     R3, SPSR				; Disable interrupts for when we go back to SVC mode
	ORR     R0, R3, #0xC0
	MSR     SPSR_c, R0

	LDR     R0, =.+8				; Switch back to SVC mode (Code below, current location + 2 instructions)
	MOVS    PC, R0					; Restore PC and CPSR

	; SAVE OLD TASK''S CONTEXT ONTO OLD TASK''S STACK
	STMFD   SP!, {R2}				; Push task''s PC 
	STMFD   SP!, {R4-R12, LR}		; Push task''s LR,R12-R4
	MOV     R4,  R1					; Move R0-R3 from IRQ stack to SVC stack
	MOV     R5,  R3
	LDMFD   R4!, {R0-R3}			; Load R0-R3 from IRQ stack
	STMFD   SP!, {R0-R3}			; Push R0-R3
	STMFD   SP!, {R5}				; Push task''s CPSR
	MRS     R4,  SPSR
	STMFD   SP!, {R4}				; Push task''s SPSR


	;----------------------------------------------------------------------------------	
	; ���� �½�ũ�� ���� �����͸� ���� �½�ũ�� �½�ũ ��Ʈ�� ��Ͽ� ����:
	; 		OSTCBCur->OSTCBStkPtr = ���� ������;
	;----------------------------------------------------------------------------------		
	LDR		R0, =OSTCBCur
	LDR		R0, [R0]
	STR		SP, [R0]
	
	;----------------------------------------------------------------------------------		
	; ����� ���� �Լ� OSTaskSwHook()�� ȣ���Ѵ�;
	;----------------------------------------------------------------------------------	
	BL 		OSTaskSwHook

	;----------------------------------------------------------------------------------			
	; OSTCBCur = OSTCBHighRdy;
	;----------------------------------------------------------------------------------		
	LDR		R0, =OSTCBHighRdy
	LDR		R1, =OSTCBCur
	LDR		R0, [R0]
	STR		R0, [R1]
	
	;----------------------------------------------------------------------------------		
	; OSPrioCur = OSPrioHighRdy;
	;----------------------------------------------------------------------------------		
	LDR		R0, =OSPrioHighRdy
	LDR		R1, =OSPrioCur
	LDRB	R0, [R0]
	STRB	R0, [R1]
	
	;----------------------------------------------------------------------------------		
	; ������� �½�ũ�� ���� ������ ����:
	; 		���� ������ = OSTCBHighRdy->OSTCBStkPtr;
	;----------------------------------------------------------------------------------		
	LDR		R0, =OSTCBHighRdy
	LDR		R0, [R0]
	LDR		R0, [R0]
	MOV		SP, R0

	;----------------------------------------------------------------------------------	
	; ������� �½�ũ�� �������κ��� ���μ��� �������� ����
	;----------------------------------------------------------------------------------	
	LDMFD 	SP!, {R0}
	MSR 	SPSR_cxsf, R0
	LDMFD 	SP!, {R0}
	MSR		CPSR_cxsf, R0
	LDMFD 	SP!, {R0-R12, LR, PC}	


;*********************************************************************************************************
;                                   CRITICAL SECTION METHOD 3 FUNCTIONS
;
; Description: Disable/Enable interrupts by preserving the state of interrupts.  Generally speaking you
;              would store the state of the interrupt disable flag in the local variable 'cpu_sr' and then
;              disable interrupts.  'cpu_sr' is allocated in all of uC/OS-II''s functions that need to 
;              disable interrupts.  You would restore the interrupt disable state by copying back 'cpu_sr'
;              into the CPU''s status register.
;
; Prototypes : OS_CPU_SR  OSCPUSaveSR(void);
;              void       OSCPURestoreSR(OS_CPU_SR cpu_sr);
;
;
; Note(s)    : 1) These functions are used in general like this:
;
;                 void Task (void *p_arg)
;                 {
;                 #if OS_CRITICAL_METHOD == 3          /* Allocate storage for CPU status register */
;                     OS_CPU_SR  cpu_sr;
;                 #endif
;
;                          :
;                          :
;                     OS_ENTER_CRITICAL();             /* cpu_sr = OSCPUSaveSR();                */
;                          :
;                          :
;                     OS_EXIT_CRITICAL();              /* OSCPURestoreSR(cpu_sr);                */
;                          :
;                          :
;                 }
;
;              2) OSCPUSaveSR() is implemented as recommended by Atmel''s application note:
;
;                    "Disabling Interrupts at Processor Level"
;*********************************************************************************************************
OSCPUSaveSR
	MRS     R0, CPSR				; Set IRQ and FIQ bits in CPSR to disable all interrupts
	ORR     R1, R0, #0xC0
	MSR     CPSR_c, R1
	MRS     R1, CPSR				; Confirm that CPSR contains the proper interrupt disable flags
	AND     R1, R1, #0xC0
	CMP     R1, #0xC0
	BNE     OSCPUSaveSR				; Not properly disabled (try again)
	MOV     PC, LR					; Disabled, return the original CPSR contents in R0

OSCPURestoreSR
	MSR     CPSR_c, R0
	MOV     PC, LR
	        
	END
