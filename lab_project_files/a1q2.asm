;
; CSc 230 Assignment 1 
; Question 2
;

; This program should calculate:
; R0 = R16 + R17
; if the sum of R16 and R17 is > 255 (ie. there was overflow)
; then R1 = 1, otherwise R1 = 0
;

;--*1 Do not change anything between here and the line starting with *--
.cseg
	ldi	r16, 0xF0
	ldi r17, 0x31
;*--1 Do not change anything above this line to the --*

;***
; Your code goes here:
;
	ldi r20, 0x00
	ldi r21, 0x01
	add r16,r17
	brcs true
	mov r1, r20
	jmp near

true: mov r1,r21
	jmp near

near: mov r0, r16




;****
;--*2 Do not change anything between here and the line starting with *--
done:	jmp done
;*--2 Do not change anything above this line to the --*


