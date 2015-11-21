/*
*********************************************************************************************************
*                                                uC/OS-II
*                                          The Real-Time Kernel
*
*    									uC/OS-II 切嚼侩 抗力 家胶
*
*                          			     (c) Copyright 2005, KInG
*                                           All Rights Reserved
*
* File    : Main.c
* Des	  : 绢敲府纳捞记 皋牢 风凭
* By      : KInG(kimingoo@hotmail.com)
* History : 2005.07.30 -> draft
*********************************************************************************************************
*/

#include "includes.h"


#define 	TASK_START_PRIO			10			// Start 
#define 	TASK_DRAW1_PRIO			11			// Draw1
#define 	TASK_DRAW2_PRIO			12			// Draw2
#define 	TASK_DRAW3_PRIO			13			// Draw3 
#define 	TASK_DRAW4_PRIO			14			// Draw4 

#define		TASK_START_STK_SIZE		1024		
#define		TASK_DRAW1_STK_SIZE		1024		
#define		TASK_DRAW2_STK_SIZE		1024		
#define		TASK_DRAW3_STK_SIZE		1024		
#define		TASK_DRAW4_STK_SIZE		1024		

OS_STK TaskStartStk[TASK_START_STK_SIZE];		              
OS_STK TaskDraw1Stk[TASK_DRAW1_STK_SIZE];    	
OS_STK TaskDraw2Stk[TASK_DRAW2_STK_SIZE];    	
OS_STK TaskDraw3Stk[TASK_DRAW3_STK_SIZE];    	    
OS_STK TaskDraw4Stk[TASK_DRAW4_STK_SIZE];    	

void TaskStart	(void* pdata);	
void TaskDraw1 	(void* pdata);	
void TaskDraw2 	(void* pdata);	
void TaskDraw3 	(void* pdata);	
void TaskDraw4 	(void* pdata);	

void delay		(void);			



OS_EVENT 	*pSem1, *pSem2, *pSem3, *pSem4;		
					


//串口接收中断服务函数，当串口接收到数据时，进入此中断服务函数，
void isrUart1RxD(void)
{
	char key;
	
	rSUBSRCPND	= BIT_SUB_RXD1;          //清除中断位，以允许下一次中断
	rSRCPND		= BIT_UART1;
	rINTPND		= BIT_UART1;
	
	key = rURXH1;                        //从接受寄存器读取接收到的字符
	
	switch(key)
    {
        case '1':	OSSemPost(pSem1);	break;	
        case '2':	OSSemPost(pSem2);	break;
        case '3':	OSSemPost(pSem3);  	break;
        case '4':	OSSemPost(pSem4);	break;
    }
    
    uprintf("%c\n", key);
}


void Main(void)
{
    OSInit(); 
    OSTaskCreate(TaskStart, (void *)0, &TaskStartStk[TASK_START_STK_SIZE-1], TASK_START_PRIO);
    OSStart();  
}



void TaskStart(void* pdata)
{
	InitSystem();	


	pSem1  = OSSemCreate(0);
	pSem2  = OSSemCreate(0);
	pSem3  = OSSemCreate(0);
	pSem4  = OSSemCreate(0);
	


	OSTaskCreate(TaskDraw1, (void *)0, &TaskDraw1Stk[TASK_DRAW1_STK_SIZE-1], TASK_DRAW1_PRIO);
	OSTaskCreate(TaskDraw2, (void *)0, &TaskDraw2Stk[TASK_DRAW2_STK_SIZE-1], TASK_DRAW2_PRIO);
	OSTaskCreate(TaskDraw3, (void *)0, &TaskDraw3Stk[TASK_DRAW3_STK_SIZE-1], TASK_DRAW3_PRIO);
	OSTaskCreate(TaskDraw4, (void *)0, &TaskDraw4Stk[TASK_DRAW4_STK_SIZE-1], TASK_DRAW4_PRIO);

	OSTaskDel(OS_PRIO_SELF);	
}



void TaskDraw1(void* pdata)
{
	INT8U 		err;
	void * 		pd;
	INT32U 		i, j;
	INT32U 		x1, x2, y1, y2, color;

	pd = pdata;	

	x1=0,x2=320, y1=0, y2=240;


	while(1)
	{
		OSSemPend(pSem1, 0, &err);
		color = RED;	

		for(i=0; i<2; i++)
		{
			for(j=y1; j<y2; j++)
			{
				TFT_DrawLine(x1, x2-1, j, color);
				delay();			
			}
			
			color = WHITE;
		}
	}
}

void TaskDraw2(void* pdata)
{
	INT8U 		err;
	void * 		pd;
	INT32U 		i, j;
	INT32U 		x1, x2, y1, y2, color;

	pd = pdata;	

	x1=320,x2=640, y1=0, y2=240;
	

	while(1)
	{
		OSSemPend(pSem2, 0, &err);	
		
		color = YELLOW;

		for(i=0; i<2; i++)
		{
			for(j=y1; j<y2; j++)
			{
				TFT_DrawLine(x1, x2-1, j, color);
				delay();			
			}
			
			color = WHITE;
		}
	}
}

void TaskDraw3(void* pdata)
{
	INT8U 		err;
	void * 		pd;
	INT32U 		i, j;
	INT32U 		x1, x2, y1, y2, color;

	pd = pdata;	

 	x1=0, 	x2=320, y1=240, y2=480; 
	
	while(1)
	{
		OSSemPend(pSem3, 0, &err);	
		
		color = GREEN;

		for(i=0; i<2; i++)
		{
			for(j=y1; j<y2; j++)
			{
				TFT_DrawLine(x1, x2-1, j, color);
				delay();			
			}
			
			color = WHITE;
		}
	}
}

void TaskDraw4(void* pdata)
{
	INT8U 		err;
	void * 		pd;
	INT32U 		i, j;
	INT32U 		x1, x2, y1, y2, color;

	pd = pdata;	

 	x1=320, x2=640, y1=240, y2=480; 
	
	while(1)
	{
		OSSemPend(pSem3, 0, &err);	
		
		color = VIOLET;

		for(i=0; i<2; i++)
		{
			for(j=y1; j<y2; j++)
			{
				TFT_DrawLine(x1, x2-1, j, color);
				delay();			
			}
			
			color = WHITE;
		}
	}
	

}

void delay(void)
{
	int i;

	for(i=0; i<0x5ffff; i++)
		;
}















