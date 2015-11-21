#include "2440lcd.h"
#include "2440addr.h"


FB_ADDR fb = (FB_ADDR)LCDFRAMEBUFFER;


//=========================================================================
// Function    : TL_Init()
// Description : TFT-LCD �ʱ�ȭ
// Param       : width          - LCD width
//               height         - LCD hight
//               virtual_width  - virtual screen width
//               virtual_height - Virtual screen height
//=========================================================================
void TL_Init(int width, int height, int virtual_width, int virtual_height)
{
    // Disable Pull-up register : OUTPUT.. SO, DISABLE..
	rGPCUP		= 0x0000FFFF; 			
	// Initialize VD[7:0], VM(VDEN), VFRAME(VSYNC), VLINE(HSYNC), VCLK, LEND      
	rGPCCON		= 0xAAAA02AA;	
	// Disable Pull-up register		
	rGPDUP		= 0x0000FFFF;		
	// Initialize VD[23:8]	
	rGPDCON		= 0xAAAAAAAA;			
    
    // CLKVAL 1, PNRMODE TFT_LCD, BPPMODE 16bpp, ENVID off
	rLCDCON1 	= (1<<8)   | (3<<5) | (12<<1) | (0<<0);	
	// FRM565 5:6:5, Half-Word swap(Little enian)	
    rLCDCON5	= (1<<11)  |1 << 9 | 1 << 8 | (1<<0);					
	
	// VBPD  33, LINEVAL 479,     VFPD    10,    VSPW  2
	rLCDCON2 	= (32<<24) | ((height-1)<<14) | (9<<6)  | (1<<0);	
	// HBPD  40, HOZVAL  639,     HFPD    24
	rLCDCON3	= (39<<19) | ((width-1) <<8)  | (23<<0);			
	// HSPW  96
	rLCDCON4	= (95<<0);											

	rLCDSADDR1	= ((unsigned)fb >> 1);
    rLCDSADDR2	= LOW21((unsigned)fb>>1) + (width+0) * (height);
	rLCDSADDR3	= (0<<11) | (width);

	rLCDCON1	|= (1<<0); // ENVID ON
	
	TL_FillFrame(WHITE);
}		


//=========================================================================
// Function    : TL_PutPixel()
// Description : Pixel�ϳ��� Frame buffer�� ��´�.
// Param       : x     - x��ǥ
//               y     - y��ǥ
//               color - ����
//=========================================================================
void TL_PutPixel( int x, int y, int color )
{
    if( ( x >= 0 && x < 640 ) && ( y >= 0 && y < 480 ) )
        fb[y][x] = (int)color;
}


//=========================================================================
// Function    : TL_FillFrame()
// Description : Buffer ��ü�� �Ѱ��� �������� ä���.
// Param       : color - ����
//               on    - ä�� ��� ( Frame or Memory )
//=========================================================================
void TL_FillFrame(int color)
{
	int x, y;

	for(y=0; y<480; y++) 
	{
	    for(x=0; x<640; x++) 
	    {
			fb[y][x] = color;
        }
    }
}


//=========================================================================
// Function    : TFT_DrawLine()
// Description : �������� �� ������ �׸���.
// Param       : xs - x start ��ġ
//				 xe - x end   ��ġ
//				 yy - y ��ġ
//			     color - ����
//=========================================================================
void TFT_DrawLine(int xs, int xe, int yy, int color)
{
	int i;
	
 	for(i=xs;i<=xe;i++)	
 	 	TL_PutPixel(i, yy, color);
}
