#ifndef __2440LCD_H__
#define __2440LCD_H__


#define LCDFRAMEBUFFER 	0x33800000 //_NONCACHE_STARTADDRESS 

// 16bit 5-6-5
#define	RGB(R,G,B)      (((R)<<11)|((G)<<5)|(B))

#define	BLACK	        RGB( 0, 0, 0)
#define	RED		        RGB(31, 0, 0)
#define	GREEN	        RGB( 0,50, 0)
#define	BLUE	        RGB( 0, 0,31)
#define	VIOLET	        RGB(31, 0,31)
#define	GRAY	        RGB(10,10,10)
#define YELLOW			RGB(31,63, 0)
#define	WHITE	        RGB(31,63,31)

#define LCD_XSIZE 	    (640)
#define LCD_YSIZE   	(480)
#define SCR_XSIZE 	    (LCD_XSIZE*1)   //for virtual screen  
#define SCR_YSIZE	    (LCD_YSIZE*1)

//=========================================================================
// MACRO       : LOW21()
// Description : 하위 21비트만 남기고 나머지는 클리어한다.
// Param       : n - 대상 숫자
//=========================================================================
#define LOW21(n) 		((n) & 0x1fffff)	

//=========================================================================
// Variables
// Frame buffer and Memory buffer
//=========================================================================
typedef unsigned short (*FB_ADDR)[LCD_XSIZE];


void TL_Init		(int width, int height, int virtual_width, int virtual_height);
void TL_PutPixel	(int x, int y, int color);
void TL_FillFrame	(int color);
void TFT_DrawLine	(int xs, int xe, int yy, int color);


#endif /*__2440LCD_H__*/