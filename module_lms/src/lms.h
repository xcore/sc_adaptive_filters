// Copyright (c) 2011, Mikael Bohman, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#ifndef LMS_H_
#define LMS_H_


extern int fir(int xn, int coeffs[], int state[], int ELEMENTS);
int lms(int x_ref, int x_des, int mu,int coeffs[], int state[],int ELEMENTS);
void txByte(port p_TXD,int data[], unsigned size);

#endif /* LMS_H_ */
