#include "includes.h"


static void Uart_SendByte	(int data);
static void Uart_SendString	(char *pt);


void Uart_Init(int pclk, int baud)
{
    //*** PORT H GROUP
    //Ports  :  GPH10    GPH9  GPH8 GPH7  GPH6  GPH5 GPH4 GPH3 GPH2 GPH1  GPH0 
    //Signal : CLKOUT1 CLKOUT0 UCLK nCTS1 nRTS1 RXD1 TXD1 RXD0 TXD0 nRTS0 nCTS0
    //Binary :   10   ,  10     10 , 11    11  , 10   10 , 10   10 , 10    10
    rGPHCON = 0x2afaaa;
    rGPHUP  = 0x7ff;    // The pull up function is disabled GPH[10:0]
    
    rUFCON1 = 0x0;	//UART channel 1 FIFO control register, FIFO disable
    rUMCON1 = 0x0;	//UART chaneel 1 MODEM control register, AFC disable
    rULCON1 = 0x3;  //Line control register : Normal,No parity,1 stop,8 bits
	
	//    [10]       [9]     [8]        [7]        [6]      [5]         [4]           [3:2]        [1:0]
	// Clock Sel,  Tx Int,  Rx Int, Rx Time Out, Rx err, Loop-back, Send break,  Transmit Mode, Receive Mode
	//     0          1       0   ,      0          1        0           0    ,        01          01
	//   PCLK       Level    Pulse    Disable    Generate  Normal      Normal        Interrupt or Polling
    rUCON1	 = 0x245;   // Control register
    rUBRDIV1 =( (int)(pclk/16./baud+0.5) -1 );   //Baud rate divisior register 0

	while(!(rUTRSTAT1 & 0x4))	//Wait until tx shifter is empty.
		;
}


void Uart_Printf(const char *fmt, ...)
{
    va_list	ap;
    char 	string[256];

    va_start(ap, fmt);
    vsprintf(string, fmt, ap);
    va_end(ap);
    
	Uart_SendString(string);
}


static void Uart_SendByte(int data)
{
	if(data=='\n')
	{
		while(!(rUTRSTAT1 & 0x2))
			;

		rUTXH1 = '\r';
	}
	
	while(!(rUTRSTAT1 & 0x2))	//Wait until THR is empty.
		;   

	rUTXH1 = data;
}  


static void Uart_SendString(char *pt)
{
    while(*pt)
        Uart_SendByte(*pt++);
}
