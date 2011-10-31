// Copyright (c) 2011, Mikael Bohman, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include <xs1.h>
#include <print.h>
#include "lms.h"

#define CLOCKDIV 50
port p_TXD = PORT_UART_TXD;
clock clk = XS1_CLKBLK_1;

int main() {
#define ELEMENTS 256
#define REDUCTION 1
#define POLYNOMIAL 0xEDB88320
#define LEN ELEMENTS*48*REDUCTION

	int errorvec[1 + LEN / REDUCTION];
	int state[2][ELEMENTS];
	int hreal[ELEMENTS];
	int hest[ELEMENTS];
	int hi = 0;
	int x_des, x_ref, error, noise;
	unsigned usign1, usign2, seed1, seed2, lo = 0;
	unsigned POW[2] = { 0, 0 };
	int mu = 0x8000000;
	timer t;
t	:>usign1;
	t:>seed1;
	if(mu<0) {
		printstr("mu must be positive");
		return 0;
	}
	// init port logic
	configure_out_port_no_ready(p_TXD, clk, 1);
	set_clock_div(clk, CLOCKDIV);
	start_clock(clk);
	crc32(usign1, seed1, POLYNOMIAL);

	for (int i = 0; i < ELEMENTS; i++) {
		state[0][i] = 0;
		state[1][i] = 0;
		hest[i]=0;
		crc32(usign1, seed1, POLYNOMIAL);
		hreal[i]= (((int)usign1)>>2);
		{	hi,lo}=macs(hreal[i],hreal[i],0,0);
		POW[0] += hi/ELEMENTS;
	}
	t:>usign1;
	printstr("Error power in estimate is: ");
	t:>seed1;
	printuint(POW[0]);
	t:>usign2;
	printstr("\nSending hreal over UART");
	txByte(p_TXD,hreal,ELEMENTS);
	printstr("\nLMS filtering...");
	t:>seed2;
	crc32(usign1, seed1, POLYNOMIAL);// Create random numbers from random seed
	crc32(usign2, seed2, POLYNOMIAL);// Create random numbers from random seed

	for (int j = 0; j<LEN; j++) {
		crc32(usign1, seed1, POLYNOMIAL);
		x_ref=((int) usign1)>>8;
		crc32(usign2, seed2, POLYNOMIAL);
		noise=((int) usign2)>>16;
		x_des=fir(x_ref, hreal, state[0], ELEMENTS);
		errorvec[j/REDUCTION]=lms(x_ref, x_des+noise, mu, hest, state[1], ELEMENTS);
	}
	errorvec[LEN/REDUCTION]=mu;
	printstr("\nError power after ");
	printint(LEN);
	printstr(" samples is: ");
	for (int i = 0; i < ELEMENTS; i++) {
		error=hreal[i]-hest[i];
		{	hi,lo}=macs(error,error,0,0);
		POW[1] += hi/ELEMENTS;
	}
	printint(POW[1]);
	printstr("\nReduction is: ");
	if(POW[1]>0)
	printint(POW[0]/POW[1]);
	else
	printstr("inf, e.g. beyond the used precision");
	printstrln(" times");
	printstrln("Sending hest over UART");
	txByte(p_TXD,hest,ELEMENTS);
	printstrln("Sending error over UART");
	txByte(p_TXD,errorvec,1+LEN/REDUCTION);

	return 0;
}
