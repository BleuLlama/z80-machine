/* MC6850 emulation
 *
 *  2016-06-08 Scott Lawrence 
 */

/* ********************************************************************** */
/*
 *      Ports and bit masks for MC6580 emulation
 */

#ifndef __MC6850_H__

#define kMC6850PortControl      (0x80)
        #define kPWC_Div1       0x01
        #define kPWC_Div2       0x02
                /* 0 0  / 1
                   0 1  / 16
                   1 0  / 64
                   1 1  reset
                */
        #define kPWC_Word1      0x04
        #define kPWC_Word2      0x08
        #define kPWC_Word3      0x10
                /* 0 0 0        7 E 2
                   0 0 1        7 O 2
                   0 1 0        7 E 1
                   0 1 1        7 O 1
                   1 0 0        8 n 2
                   1 0 1        8 n 1
                   1 1 0        8 E 1
                   1 1 1        8 O 1
                */
        #define kPWC_Tx1        0x20
        #define kPWC_Tx2        0x40
                /* 0 0  -RTS low, tx interrupt disabled
                   0 1  -RTS low, tx interrupt enabled
                   1 0  -RTS high, tx interrupt disabled
                   1 1  -RTS low, tx break on data, interrupt disabled
                */
        #define kPWC_RxIrqEn    0x80

#define kMC6850PortStatus       (0x80)
        #define kPRS_RxDataReady        0x01 /* rx data is ready to be read */
        #define kPRS_TXDataEmpty        0x02 /* tx data is ready for new contents */
        #define kPRS_DCD        0x04 /* data carrier detect */
        #define kPRS_CTS        0x08 /* clear to send */
        #define kPRS_FrameErr   0x10 /* improper framing */
        #define kPRS_Overrun    0x20 /* characters lost */
        #define kPRS_ParityErr  0x40 /* parity was wrong */
        #define kPRS_IrqReq     0x80 /* irq status */

#endif
