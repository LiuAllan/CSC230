#define LCD_LIBONLY
.include "m2560def.inc"
;.include "lcd.asm"
	
.cseg	


.org 0x0000
		jmp setup

.org 0x0028
		jmp timer1_isr

setup:

	call timer_init

	ldi r16, 0x87
	sts ADCSRA, r16
	ldi r16, 0x40
	sts ADMUX, r16
	ldi r16, 0x20
	sts spd, r16
	;initialize the lcd
	call lcd_init 

	;clear the lcd
	call lcd_clr

	;copy the strings from program to data memory

	call get_strs
	
	;set l1ptr and l2ptr to point at the start of the display strings
	call setpointer1
	call setpointer2
	
	call cpytoline1
	call cpytoline2

	ldi	r16, 0xFF
	sts DDRB,r16
	sts DDRL,r16
	clr r16
	sts count1, r16
	sts count2, r16
	sts len1, r16
	sts len2, r16
	sts flag, r16
	sts button, r16
	ldi r16, 4
	sts spddisp, r16
	ldi r16, 0x20
	sts spd, r16
	call getlens1
	call getlens2



;do forever:
main:

	lds r16, button
	cpi r16, 0
	breq nobutton

	call respbutton

	nobutton:

	push ZH
	push ZL
	ldi ZH, high(flag)
	ldi ZL, low(flag)
	ld r17, Z
	pop ZL
	pop ZH
	cpi r17, 2
	breq main


;clear the lcd

call lcd_clr


;display line1 and line2
call display_strings


;move the pointers forward (wrap around when appropriate)
call updatepointer1
call updatepointer2


;copy from the pointers in msg1 and msg2 to line1 and line2

call cpytoline1
call cpytoline2




;delay

lds r20, spd

call delay

call display

clr r16
;sts button, r16

jmp main









;################## Timer Interupt Functions ########


timer_init:
		push r16
		; reset timer counter to 0
		ldi r16, 0x00
		sts TCNT1H, r16 	; must WRITE high byte first 
		sts TCNT1L, r16		; low byte
		; timer mode
		
		sts TCCR1A, r16
		; prescale 
		; Our clock is 16 MHz, which is 16,000,000 per second
		;
		; scale values are the last 3 bits of TCCR1B:
		;
		; 000 - timer disabled
		; 001 - clock (no scaling)
		; 010 - clock / 8
		; 011 - clock / 64
		; 100 - clock / 256
		; 101 - clock / 1024
		; 110 - external pin Tx falling edge
		; 111 - external pin Tx rising edge

		ldi r16, 0b0000010	; clock / 256
		sts TCCR1B, r16

		; Write your code here: enable timer interrupts
		
		ldi r16, 0x01
		sts TIMSK1, r16
		sei
		pop r16
		
		ret



timer1_isr:
		push r16
		push r17
		push r18
		lds r16, SREG
		push r16
		push r24
		push XH
		push XL
		push YH
		push YL
		push ZH
		push ZL
		push r19
		
		;Write your code here: reverse the bits which control the bottom two LEDs, hint PORTB
		
		;; here we'll check if button is pressed
		; Returns in r24:
	;	0 - no button pressed
	;	1 - right button pressed

	;	2 - up button pressed
	;	4 - down button pressed

	;	8 - left button pressed
	;	16- select button pressed
		ldi r16, 1
		sts button, r16

		; timer interrupt flag is automatically
		; cleared when this ISR is executed
		; per page 168 ATmega datasheet
	
		pop r19
		pop ZL
		pop ZH
		pop YL
		pop YH
		pop XL
		pop XH
		pop r24
		pop r16
		sts SREG, r16
		pop r18
		pop r17
		pop r16
	reti


swaps:

	push r16
	
	ldi r16, high(msg2)   			;dest
	push r16
	ldi r16, low(msg2)
	push r16
	ldi r16, high(msg1_p << 1) 			;source
	push r16
	ldi r16, low(msg1_p << 1)				
	push r16
	
	call str_init
	pop r16
	pop r16
	pop r16
	pop r16
	
	ldi r16, high(msg1)  		 ;dest
	push r16
	ldi r16, low(msg1)
	push r16
	ldi r16, high(msg2_p << 1) 		;source
	push r16
	ldi r16, low(msg2_p << 1)				
	push r16
	
	call str_init
	pop r16
	pop r16
	pop r16
	pop r16

	call getlens1
	call getlens2
	call setpointer1
	call setpointer2
	clr r16


sts side, r16

pop r16
ret	


swap1:

	push r16
	
	ldi r16, high(msg1)   			;dest
	push r16
	ldi r16, low(msg1)
	push r16
	ldi r16, high(msg1_p << 1) 			;source
	push r16
	ldi r16, low(msg1_p << 1)				
	push r16
	
	call str_init
	pop r16
	pop r16
	pop r16
	pop r16
	
	ldi r16, high(msg2)  		 ;dest
	push r16
	ldi r16, low(msg2)
	push r16
	ldi r16, high(msg2_p << 1) 		;source
	push r16
	ldi r16, low(msg2_p << 1)				
	push r16
	
	call str_init
	pop r16
	pop r16
	pop r16
	pop r16

	call getlens1
	call getlens2
	call setpointer1
	call setpointer2
	ldi r16, 1
	sts side, r16

	pop r16


ret

respbutton:
		push XH
		push XL
		push YH
		push YL
		push ZH
		push ZL
		push r16
		push r19
		call check_button
		ldi ZH, high(spd)
		ldi ZL, low(spd)
		ldi XH, high(tempr)
		ldi XL, low(tempr)
		ldi YH, high(flag)
		ldi YL, low(flag)
		ld r16, X
		cpi r16, 0
		breq ahead
		cpi r16, 1
		breq set1
		cpi r16, 2
		breq set2
		cpi r16, 4
		breq set2
		cpi r16, 8
		breq set8
		cpi r16, 16
		breq set16
		jmp ahead


; speeds up when right button pushed
set1:
		st Y, r16
		ld r19, Z
		dec r19
		cpi r19, 0x4
		breq ahead
		st Z, r19
		lds r16, spddisp
		inc r16
		sts spddisp, r16
		
		jmp ahead

; up button stops scroll or down button pushed to resume
set2:
		st Y, r16
		jmp ahead

; left button, slow down
set8:
		st Y, r16
		ld r19, Z
		inc r19
		cpi r19, 0x35
		breq ahead
		st Z, r19
		lds r16, spddisp
		dec r16
		sts spddisp, r16
		jmp ahead

; select change message
set16:
		st Y, r16
		lds r16, side
		cpi r16, 1
		breq top
		call swap1
		jmp ahead


top:	call swaps
		

ahead:


	pop r19
	pop r16
	pop ZL
	pop ZH
	pop YL
	pop YH
	pop XL
	pop XH

ret


check_button:
		push r16
		push r17
		push r24
		push XH
		push XL
		
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
		cpi r17, 3			;  if > 0x3E8, no button pressed 
		brne bsk1		    ;  
		cpi r16, 0xE8		; 
		brsh bsk_done		; 
bsk1:	tst r17				; if ADCH is 0, might be right or up  
		brne bsk2			; 
		cpi r16, 0x32		; < 0x32 is right
		brsh bsk3
		ldi r24, 0x01		; right button
		rjmp bsk_done
bsk3:	cpi r16, 0xC3		
		brsh bsk4	
		ldi r24, 0x02		; up			
		rjmp bsk_done
bsk4:	ldi r24, 0x04		; down (can happen in two tests)
		rjmp bsk_done
bsk2:	cpi r17, 0x01		; could be up,down, left or select
		brne bsk5
		cpi r16, 0x7c		; 
		brsh bsk7
		ldi r24, 0x04		; other possiblity for down
		rjmp bsk_done
bsk7:	ldi r24, 0x08		; left
		rjmp bsk_done
bsk5:	cpi r17, 0x02
		brne bsk6
		cpi r16, 0x2b
		brsh bsk6
		ldi r24, 0x08
		rjmp bsk_done
bsk6:	ldi r24, 0x10
bsk_done:
		
		ldi XH, high(tempr)
		ldi XL, low(tempr)
		st X, r24
		pop XL
		pop XH
		pop r24
		pop r17
		pop r16
		ret




display:
		
		push r30
		push r27
		push r26
		push r25
		push r16

; Your code here
		ldi r30, 0x0F		; holds temp value 
		ldi r27, 0x00
		lds r16, spddisp
		mov r0, r16					; holds port ls values
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

		pop r16
		pop r25
		pop r26
		pop r27
		pop r30
		ret
















;################## Part 1 Functions  ###############


; display the lines on the lcd
display_strings:

	; This subroutine sets the position the next
	; character will be output on the lcd
	;
	; The first parameter pushed on the stack is the Y position
	; 
	; The second parameter pushed on the stack is the X position
	; 
	; This call moves the cursor to the top left (ie. 0,0)

	push r16

	call lcd_clr

	ldi r16, 0x00
	push r16
	ldi r16, 0x00
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	; Now display msg1 on the first line
	ldi r16, high(line1)
	push r16
	ldi r16, low(line1)
	push r16
	call lcd_puts
	pop r16
	pop r16

	; Now move the cursor to the second line (ie. 0,1)
	ldi r16, 0x01
	push r16
	ldi r16, 0x00
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	; Now display msg1 on the second line
	ldi r16, high(line2)
	push r16
	ldi r16, low(line2)
	push r16
	call lcd_puts
	pop r16
	pop r16

	pop r16
	ret


;set/reset pointer1
setpointer1:
	push YH
	push YL
	push r16
	push r17

	ldi YH, high(l1ptr)
	ldi YL, low(l1ptr)

	ldi r16, high(msg1)
	ldi r17, low(msg1)
	
	st Y+, r17
	st Y, r16

	pop r17
	pop r16
	pop YL
	pop YH
	
ret

;set/reset pointer2
setpointer2:
	push YH
	push YL
	push r16
	push r17

	ldi YH, high(l2ptr)
	ldi YL, low(l2ptr)

	ldi r16, high(msg2)
	ldi r17, low(msg2)
	
	st Y+, r17
	st Y, r16

	pop r17
	pop r16
	pop YL
	pop YH
	
ret



;gets strings into data memory
get_strs:
	push r16
	
	ldi r16, high(msg1)   			;dest
	push r16
	ldi r16, low(msg1)
	push r16
	ldi r16, high(msg1_p << 1) 			;source
	push r16
	ldi r16, low(msg1_p << 1)				
	push r16
	
	call str_init
	pop r16
	pop r16
	pop r16
	pop r16
	
	ldi r16, high(msg2)  		 ;dest
	push r16
	ldi r16, low(msg2)
	push r16
	ldi r16, high(msg2_p << 1) 		;source
	push r16
	ldi r16, low(msg2_p << 1)				
	push r16
	
	call str_init
	pop r16
	pop r16
	pop r16
	pop r16

	pop r16

	ret


;copies msg1 into line1
cpytoline1:
		push XH
		push XL
		push ZH
		push ZL
		push YH
		push YL
		push r16
		push r17
	
		clr r17
		
		ldi XH, high(l1ptr)
		ldi XL, low(l1ptr)

		ldi ZH, high(line1)
		ldi ZL, low(line1)
		
		ld YL, X+
		ld YH, X

getchar:
		ld r16, Y+
		cpi r16, 0 
		breq resY
		st Z+, r16
		inc r17
		cpi r17, 16
		breq nullchar
		jmp getchar

resY: 	
		ldi YH, high(msg1)
		ldi YL, low(msg1)
		jmp getchar
		
nullchar:
		clr r17
		st Z, r17

		pop r17
		pop r16
		pop YL
		pop YH
		pop ZL
		pop ZH
		pop XL
		pop XH
		
		ret 


;copies msg1 into line1
cpytoline2:
		push XH
		push XL
		push ZH
		push ZL
		push YH
		push YL
		push r16
		push r17
	
		clr r17
		
		ldi XH, high(l2ptr)
		ldi XL, low(l2ptr)

		ldi ZH, high(line2)
		ldi ZL, low(line2)
		
		ld YL, X+
		ld YH, X

getchar1:
		ld r16, Y+
		cpi r16, 0 
		breq resY1
		st Z+, r16
		inc r17
		cpi r17, 16
		breq nullchar1
		jmp getchar1


resY1: 	
		ldi YH, high(msg2)
		ldi YL, low(msg2)
		jmp getchar1
		
nullchar1:
		clr r17
		st Z, r17

		pop r17
		pop r16
		pop YL
		pop YH
		pop ZL
		pop ZH
		pop XL
		pop XH
		
		ret 


; gets the strings lengths
getlens1:
	
	push YH
	push YL
	push r16
	push r18
	clr r18
	ldi YH, high(msg1)
	ldi YL, low(msg1)
	
bak:
	ld r16, Y+
	cpi r16, 0
	breq ender
	inc r18
	jmp bak

ender:
	
	sts len1, r18
	pop r18
	pop r16
	pop YL
	pop YH
ret

; gets the strings lengths
getlens2:
	
	push YH
	push YL
	push r16
	push r18
	clr r18
	ldi YH, high(msg2)
	ldi YL, low(msg2)
	
bak1:
	ld r16, Y+
	cpi r16, 0
	breq ender1
	inc r18
	jmp bak1

ender1:
	
	sts len2,r18
	pop r18
	pop r16
	pop YL
	pop YH
ret

updatepointer1:
	push XH
	push XL
	push r16
	push r17
	push r18
	
	lds r18, len1 	

	lds r17, count1
	inc r17
	cp r17, r18
	breq respointer

	ldi XH,high(l1ptr)
	ldi XL, low(l1ptr)

	ld r16, X
	inc r16
	st X, r16
	
	sts count1, r17
	jmp fin


respointer:
	call setpointer1
	clr r17
	sts count1, r17

fin:
	pop r18
	pop r17
	pop r16
	pop XL
	pop XH

	ret


updatepointer2:
	push XH
	push XL
	push r16
	push r17
	push r18
	
	lds r18, len2 	

	lds r17, count2
	inc r17
	cp r17, r18
	breq respointer1

	ldi XH,high(l2ptr)
	ldi XL, low(l2ptr)

	ld r16, X
	inc r16
	st X, r16
	
	sts count2, r17
	jmp fin1


respointer1:
	call setpointer2
	clr r17
	sts count2, r17

fin1:
	pop r18
	pop r17
	pop r16
	pop XL
	pop XH

	ret
	
;delay function
delay:	
		push r21
		push r22
		
del1_2:	
		nop
		ldi r21,0xFF
del2_2:	nop
		ldi r22, 0xFF
del3_2:	nop
		dec r22
		brne del3_2
		dec r21
		brne del2_2
		dec r20
		brne del1_2

		pop r22
		pop r21
		ret



;###################### End of functions #################

; sample strings 
; These are in program memory 
msg1_p: .db "Why did the cat eat potatoes? ", 0
msg2_p: .db "Because it 'cat' find anything better. ", 0

.include "lcd.asm"

.dseg 
;


; The program copies the strings from program memory 
; into data memory. 
; l1ptr and l2ptr index into these strings 
; 

msg1: .byte 200 
msg2: .byte 200 
; These strings contain the 16 characters to be displayed on the LCD
; Each time through the loop, the pointers l1ptr and l2ptr are incremented
; and then 16 characters are copied into these memory locations
line1: .byte 17 
line2: .byte 17 

; These keep track of where in the string each line currently is
l1ptr: .byte 2 
l2ptr: .byte 2

flag: .byte 1
tempr: .byte 1
spd: .byte 1
count1: .byte 1
count2: .byte 1
len1: .byte 1
len2: .byte 1
button: .byte 1
side: .byte 1
spddisp: .byte 1
