#ifndef __2440UART_H__
#define __2440UART_H__


#define uprintf		Uart_Printf

void Uart_Init	(int pclk, int baud);
void Uart_Printf(const char *fmt, ...);


#endif /*__2440UART_H__*/