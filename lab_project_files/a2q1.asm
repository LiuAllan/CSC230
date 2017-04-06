;
; a2q1.asm
;
; Write a program that displays the binary value in r16
; on the LEDs.
;
; See the assignment PDF for details on the pin numbers and ports.
;
;
;
; These definitions allow you to communicate with
; PORTB and PORTL using the LDS and STS instructions
;
.equ DDRB=0x24
.equ PORTB=0x25
.equ DDRL=0x10A
.equ PORTL=0x10B



		ldi r16, 0xFF
		sts DDRB, r16		; PORTB all output
		sts DDRL, r16		; PORTL all output
		ldi r16, 0x17		; display the value
		mov r0, r16			; in r0 on the LEDs

; Your code here
		ldi r22, 0x0F		; holds temp value 
		ldi r27, 0x00		; holds port ls values
		and r22, r0			; gets the signifigant digits for port l
		
		mov r26, r22		; holds the temp value
				
		andi r22, 0x01
		breq stepover1		
		ori r27, 0x80
stepover1:
		mov r22, r26
		andi r22, 0x02
		breq stepover2
		ori r27, 0x20		
stepover2:
		mov r22, r26
		andi r22, 0x04
		breq stepover3
		ori r27, 0x08
stepover3:
		mov r22, r26
		andi r22, 0x08
		breq stepover4
		ori r27, 0x02
stepover4:
		sts PORTL, r27
		
		

		ldi r23, 0xF0		; holds port bs values
		ldi r25, 0x00		
		and r23, r0
		ldi r27, 0x00
		mov r25, r23

		andi r23, 0x10
		breq stepover5
		ori r27, 0x08
stepover5:
		mov r23, r25
		andi r23, 0x20
		breq stepover6
		ori r27, 0x02
stepover6:
		sts PORTB, r27
		

		

;
; Don't change anything below here
;
done:	jmp done
