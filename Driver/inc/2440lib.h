/*
*********************************************************************************************************
*                                   	  
*											  S3C2440 Library
*
*                          			     (c) Copyright 2005, king
*                                           All Rights Reserved
*
* File    : 2440lib.h
* Des	  : S3C2440용 기타 라이브러리
* By      : KInG(kimingoo@hotmail.com)
* History : 2005.07.30 -> draft
*********************************************************************************************************
*/

#ifndef __2440LIB_H__
#define __2440LIB_H__


// Fin=16.9344MHz, FCLK = 400MHz(399651840Hz)
// FCLK : HCLK : PCLK = 1 : 3 : 6
#define FCLK	(399651840)
#define HCLK	(FCLK / 3)
#define PCLK 	(FCLK / 6)


void InitSystem(void);
void Led_Display(int data);

void ISR_Uart1RxD(void);


#endif /*__2440LIB_H__*/
