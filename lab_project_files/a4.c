/*
 * a4.c
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "main.h"
#include "lcd_drv.h"



// These are included by the LCD driver code, so 
// we don't need to include them here.
// #include <avr/io.h>
// #include <util/delay.h>


void strntoline(char *msg, char* pointer, char* dest){
	char* tmp = pointer;
	int i = 0;
	while (i < 16){
		if(*tmp == 0){
			tmp = msg;
		}
		dest[i] = *tmp;
		i++;
		tmp++;
	}
	return;
}

void displayValue ( int val )
{
	unsigned char toL = 0x00;
	unsigned char toB = 0x00;

	// We only have six LEDs, so only six bits of precision
	// mask off the rest
	// 0b0011 1111
	// 0x3F
	val = val & 0x3F;

	// This should be a loop but... 
	if (val & 0x01)
		toL |= 0x80;
	if (val & 0x02)
		toL |= 0x20;
	if (val & 0x04)
		toL |= 0x08;
	if (val & 0x08)
		toL |= 0x02;
	if (val & 0x10)
		toB |= 0x08;
	if (val & 0x20)
		toB |= 0x02;
	
	PORTB = toB;
	PORTL = toL;	
	return;
}


int button_pressed(int current){

	// start conversion
	ADCSRA |= 0x40;

	// bit 6 in ADCSRA is 1 while conversion is in progress
	// 0b0100 0000
	// 0x40
	while (ADCSRA & 0x40)
		;
	unsigned int val = ADCL;
	unsigned int val2 = ADCH;

	val += (val2 << 8);


	
	if (val > 1000 )
	{
		if(current == 2) return current;		
		return 0;
	}
			 
    if (val < 50) 
	  return 1;
    else if (val < 195)
	  return 2;
    else if (val < 380)  
	  return 4;
    else if (val < 555)  
	  return 8;
    else 
	  return 16;
	   

}



void init_buttons(){
/* set PORTL and PORTB for output*/
	DDRL = 0xFF;
	DDRB = 0xFF;


	/* enable A2D: */

	/* ADCSRA:
	 * bit 7 - ADC enable
	 * bit 6 - ADC start conversion
	 * bit 5 - ADC auto trigger enable
	 * bit 4 - ADC interrupt flag
	 * bit 3 - ADC interrupt enable
	 * bit 2 |
	 * bit 1 |- ADC prescalar select bits
	 * bit 0 |
	 * 
	 * we want:
	 * 0b1000 0111
	 * which is:
	 * 0x87
	 */
	ADCSRA = 0x87;

	/* ADMUX - ADC Multiplexer Selection Register
	 *
	 * Select ADC0
     */
	ADMUX = 0x40;
	return;

}



int main( void )
{
	
	init_buttons();

	lcd_init();
	char* msg2 = "I saw a frog on a log, even through all the fog. ";
	char* msg1 = "My cat goes moo, so we brought him to the zoo. ";
	char line1[17];
	char line2[17]; 

	char* point1 = msg1;
	char* point2 = msg2;
	int speed = 1000;
	int flag = 0;
	int flag2 = 1;
	int spdtemp = 500;


	line1[16] = 0;
	line2[16] = 0;
	
	strntoline(msg1, point1, line1);
	strntoline(msg2, point2, line2);
	

	lcd_xy( 0, 0 );
	/* lcd_puts takes a pointer to a null terminated
	 * string and displays it at the current cursor position.
	 *
	 * In this call, I'm using a constant string
	 */
	lcd_puts(line1);

	lcd_xy( 0, 1 );

	/* This function will delay for the number of milliseconds */
//	_delay_ms(500);

	/*
	 * Here using a buffer.  Note that this isn't the normal
	 * way to initialize a C-string, but I wanted to illustrate
	 * how they are created.
	 */

 	lcd_puts(line2);


	for (;;)
	{	
	_delay_ms(speed);
		if(flag == 2){
			 flag = button_pressed(flag);
			continue;
		}
	
		point1++;
		point2++;
		if(*point1 == 0) point1 = msg1;
		if(*point2 == 0) point2 = msg2;

		strntoline(msg1, point1, line1);
		lcd_xy( 0, 0 );
		lcd_puts(line1);

		strntoline(msg2, point2, line2);
		lcd_xy( 0, 1 );
		lcd_puts(line2);
			
		flag = button_pressed(flag);
		displayValue(flag);
		if(flag == 0) continue;
		if(flag == 2){ 
			spdtemp = speed;
			continue;
		}
		if(flag == 4 ) speed = spdtemp;
		if(flag == 8){
			if(speed < 2000){
				speed += 100;
			}
		}
		if(flag == 1){
			if (speed > 200){
				speed -= 100;
			}
		}
		if (flag == 16) {
			if (flag2 == 1 ){
				point2 = msg1;
				point1 = msg2;
				flag2 = 2;
			}else{
				point1 = msg1;
				point2 = msg2;
				flag2 = 1;
			}	
		}
	
	}
	}
