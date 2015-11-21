/*
*********************************************************************************************************
*                                                uC/OS-II
*                                          The Real-Time Kernel
*                                   	  
*											  S3C2440 Library
*
*                          			     (c) Copyright 2005, king
*                                           All Rights Reserved
*
* File    : 2440lib.c
* Des	  : S3C2440용 기타 라이브러리
* By      : KInG(kimingoo@hotmail.com)
* History : 2005.07.30 -> draft
*********************************************************************************************************
*/

#include "includes.h"


static void InitUart1RxDIsr(void);
static void StartClockTick(void);


void InitSystem(void)
{   
	Uart_Init(PCLK, 115200);
	TL_Init(LCD_XSIZE, LCD_YSIZE, SCR_XSIZE, SCR_YSIZE);

	TL_FillFrame(WHITE);	
	InitUart1RxDIsr();
	
	StartClockTick();
}


void Led_Display(int data)
{
	// Active is low.(LED On)
	// GPF7   GPF6  GPF5   GPF4
	// nLED_8 nLED4 nLED_2 nLED_1
    rGPFDAT &= ~(0xf<<4);
    rGPFDAT  = (~data & 0xf) << 4;         
}


static void InitUart1RxDIsr(void)
{	
	pISR_UART1 	= (unsigned)ISR_Uart1RxD;
	rINTSUBMSK  &= ~BIT_SUB_RXD1;
	rINTMSK		&= ~BIT_UART1;	
}


// ClockTick 발생 함수 Timer4를 사용함
static void StartClockTick(void)
{
	INT32U ticf;				// Timer input clock Freauency
	
	rTCFG0 &= ~(0xff<<8);		// Prescaler1[15: 8]=0x00  (prescaler value=0)
	rTCFG1 &= ~(0xf<<16);		//       MUX4[19:16]=0000b (divider   value=2)

	// Timer input clock Freauency = PCLK / (prescaler value+1) / divider value
	ticf = PCLK / (0+1) / 2;		
	
	rTCNTB4 = ticf / OS_TICKS_PER_SEC;
	
	rTCON |=  (1<<22) | (1<<21);
	rTCON &= ~(1<<21);
	
	rTCON |=  (1<<20);			// Start for Timer4

	// Timer4 인터럽트 벡터 설치 & 인터럽트 마스킹 해제
	pISR_TIMER4  = (unsigned)OSTickISR;		
	rINTMSK     &= ~(BIT_TIMER4);
}

