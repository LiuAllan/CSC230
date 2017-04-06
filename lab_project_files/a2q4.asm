;
; a2q4.asm
;
; Fix the button subroutine program so that it returns
; a different value for each button
;

;
; Definitions for PORTA and PORTL when using
; STS and LDS instructions (ie. memory mapped I/O)
;
.equ DDRB=0x24
.equ PORTB=0x25
.equ DDRL=0x10A
.equ PORTL=0x10B

;
; Definitions for using the Analog to Digital Conversion
.equ ADCSRA=0x7A
.equ ADMUX=0x7C
.equ ADCL=0x78
.equ ADCH=0x79


		; initialize the Analog to Digital conversion

		ldi r16, 0x87
		sts ADCSRA, r16
		ldi r16, 0x40
		sts ADMUX, r16

		; initialize PORTB and PORTL for ouput
		ldi	r16, 0xFF
		sts DDRB,r16
		sts DDRL,r16


		clr r0
		call display
lp:
		call check_button
		tst r24
		breq lp
		mov	r0, r24

		call display
		ldi r20, 0x40
		call delay
		ldi r20, 0
		mov r0, r20
		call display
		rjmp lp

;
; An improved version of the button test subroutine
;
; Returns in r24:
;	0 - no button pressed
;	1 - right button pressed
;	2 - up button pressed
;	4 - down button pressed
;	8 - left button pressed
;	16- select button pressed
;
; this function uses registers:
;	r24
;
; if you consider the word:
;	 value = (ADCH << 8) +  ADCL
; then:
;
; value > 0x3E8 - no button pressed
;
; Otherwise:
; value < 0x032 - right button pressed
; value < 0x0C3 - up button pressed
; value < 0x17C - down button pressed
; value < 0x22B - left button pressed
; value < 0x316 - select button pressed
; 
check_button:
		; start a2d
		lds	r16, ADCSRA	
		ori r16, 0x40
		sts	ADCSRA, r16

		; wait for it to complete
wait:		lds r16, ADCSRA
		andi r16, 0x40
		brne wait

		; read the value
		lds r16, ADCL
		lds r17, ADCH

		; put your new logic here:
		clr r24
		cpi r17, 0x0
		brne nextpart
		cpi r16, 0x32
		brmi make1
		cpi r16, 0xc3
		brmi make2
		cpi r16, 0xc3
		brpl make4


nextpart:
		cpi r17, 0x1
		brne part3
		cpi r16, 0x7c
		brpl make8
		rjmp make4



part3:
		cpi r17, 0x2
		brne part4
		cpi r16, 0x2b
		brpl make16
		rjmp make8


part4:
		cpi r17, 0x3
		brne make0
		cpi r16, 0x16
		brpl make0
		rjmp make0

make0:
		ldi r24, 0
		rjmp skip

make1:
		ldi r24, 1
		rjmp skip
make2:
		ldi r24, 2
		rjmp skip
make4:
		ldi r24, 4
		rjmp skip
make8:
		ldi r24, 8
		rjmp skip
make16:
		ldi r24, 16
		rjmp skip



skip:	ret

;
; delay
;
; set r20 before calling this function
; r20 = 0x40 is approximately 1 second delay
;
; this function uses registers:
;
;	r20
;	r21
;	r22
;
delay:	
del1:		nop
		ldi r21,0xFF
del2:		nop
		ldi r22, 0xFF
del3:		nop
		dec r22
		brne del3
		dec r21
		brne del2
		dec r20
		brne del1	
		ret

;
; display
; 
; display the value in r0 on the 6 bit LED strip
;
; registers used:
;	r0 - value to display
;
display:
		; copy your code from a2q2.asm here
	ldi r16, 0xFF
		sts DDRB, r16		; PORTB all output
		sts DDRL, r16		; PORTL all output

; Your code here
		ldi r30, 0x0F		; holds temp value 
		ldi r27, 0x00		; holds port ls values
		and r30, r0			; gets the signifigant digits for port l
		
		mov r26, r30		; holds the temp value
				
		andi r30, 0x01
		breq stepover1		
		ori r27, 0x80
stepover1:
		mov r30, r26
		andi r30, 0x02
		breq stepover2
		ori r27, 0x20		
stepover2:
		mov r30, r26
		andi r30, 0x04
		breq stepover3
		ori r27, 0x08
stepover3:
		mov r30, r26
		andi r30, 0x08
		breq stepover4
		ori r27, 0x02
stepover4:
		sts PORTL, r27
		
		

		ldi r29, 0xF0		; holds port bs values
		ldi r25, 0x00		
		and r29, r0
		ldi r27, 0x00
		mov r25, r29

		andi r29, 0x10
		breq stepover5
		ori r27, 0x08
stepover5:
		mov r29, r25
		andi r29, 0x20
		breq stepover6
		ori r27, 0x02
stepover6:
		sts PORTB, r27

		ret

