;
; a2q3.asm
;
; Write a main program that increments a counter when the buttons are pressed
;
; Use the subroutine you wrote in a2q2.asm to solve this problem.
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

; Your code here
; make sure your code is an infinite loop

		ldi r31, 0x00
		mov r0, r31

start:
		
		call check_button

		cpi r24, 0x00
		breq disp
		inc r0
		ldi r20, 0x30
		call delay

disp:	call display
		mov r19, r0
		cpi r19, 0x40
		brne start
		ldi r19, 0x00
		mov r0, r19

		jmp start



done:		jmp done		; if you get here, you're doing it wrong

;
; the function tests to see if the button
; UP or SELECT has been pressed
;
; on return, r24 is set to be: 0 if not pressed, 1 if pressed
;
; this function uses registers:
;	r16
;	r17
;	r24
;
; This function could be made much better.  Notice that the a2d
; returns a 2 byte value (actually 12 bits).
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
; This function 'cheats' because I observed
; that ADCH is 0 when the right or up button is
; pressed, and non-zero otherwise.
; 
check_button:
		; start a2d
		lds	r16, ADCSRA	
		ori r16, 0x40
		sts	ADCSRA, r16

		; wait for it to complete
wait:	lds r16, ADCSRA
		andi r16, 0x40
		brne wait

		; read the value
		lds r16, ADCL
		lds r17, ADCH

		clr r24
		cpi r17, 0
		brne skip		
		ldi r24,1
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
; copy your display subroutine from a2q2.asm here
 
; display the value in r0 on the 6 bit LED strip
;
; registers used:
;	r0 - value to display
;	r17 - value to write to PORTL
;	r18 - value to write to PORTB
;
;   r16 - scratch
display:

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


