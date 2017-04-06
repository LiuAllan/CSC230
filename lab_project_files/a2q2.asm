;
; a2q2.asm
;
;
; Turn the code you wrote in a2q1.asm into a subroutine
; and then use that subroutine with the delay subroutine
; to have the LEDs count up in binary.
;
;
; These definitions allow you to communicate with
; PORTB and PORTL using the LDS and STS instructions
;
.equ DDRB=0x24
.equ PORTB=0x25
.equ DDRL=0x10A
.equ PORTL=0x10B


; Your code here
; Be sure that your code is an infite loop
		ldi r31, 0x00
		mov r0, r31

start:
		
		call display
		inc r0
		ldi r20, 0x30
		call delay
		mov r16, r0
		cpi r16, 0x40
		brne start
		ldi r16, 0x00
		mov r0, r16

	
		jmp start


done:		jmp done	; if you get here, you're doing it wrong

;
; display
; 
; display the value in r0 on the 6 bit LED strip
;
; registers used:
;	r0 - value to display
;



display:
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
;
; delay
;
; set r20 before calling this function
; r20 = 0x40 is approximately 1 second delay
;
; registers used:
;	r20
;	r21
;	r22
;
delay:	
del1:	nop
		ldi r21,0xFF
del2:	nop
		ldi r22, 0xFF
del3:	nop
		dec r22
		brne del3
		dec r21
		brne del2
		dec r20
		brne del1	
		ret
