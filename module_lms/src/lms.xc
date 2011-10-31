// Copyright (c) 2011, Mikael Bohman, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xclib.h>
#include <xs1.h>

void txByte(port p_TXD,int data[], unsigned size) {
	char byte;
	int int32[1];
	#pragma unsafe arrays
    	for (unsigned i = 0; i < size; i++) {
    	int32[0]=byterev(data[i]);
#pragma loop unroll
    	for(unsigned j=0;j<4;j++){
    	p_TXD	<: 0; //start bit
		byte=(int32,char[])[j];
#pragma loop unroll
		for(int k=0;k<8;k++)
			p_TXD <: >> byte;
		p_TXD<: 1; //stop bit
	}
}}


#pragma unsafe arrays
int lms(int x_ref, int x_des, int mu,int coeffs[], int state[],int ELEMENTS) {
#define shift 4;
	unsigned ynl,pnl,muel;
	int ynh,pnh, error,mue;
    ynl = (1<<23);
    ynh = 0;
	for (int j = ELEMENTS - 1 ; j != 0 ; j--) {
				state[j] = state[j - 1];
				{ynh, ynl}=macs(coeffs[j], state[j], ynh, ynl);
			}
			state[0] = x_ref<<7;
			{ynh, ynl}=macs(coeffs[0], x_ref<<7, ynh, ynl);
			{pnh, pnl}=macs(state[0], state[0]/ELEMENTS, pnh, pnl);

			ynh = ynh << 1 | ynl >> 31;

			error = x_des-ynh;
			{mue,muel}=macs(mu,error,0,0);
			for(int j = ELEMENTS-1 ; j!=0 ; j--)
				{coeffs[j],void}=macs((state[j]),mue,coeffs[j],0x80000000);
			{coeffs[0],void}=macs((state[0]),mue,coeffs[0],0x80000000);
			return error;
}
