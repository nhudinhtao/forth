/*
	Generate random unique 32 bit number
*/

#ifndef RANDOM_UNIQUE_32_H
#define RANDOM_UNIQUE_32_H

#include <sys/types.h>   /* u_long */
#include <sys/time.h>    /* gettimeofday() */
#include <stdio.h>       /* printf() */
#include <time.h>        /* clock() */
#include <unistd.h>      /* get..() */
#include <sys/utsname.h> /* uname() */
#include "md5.h"

#include "../include/brg_types.h"

#ifdef __cplusplus
extern "C" 
{
#endif

#ifndef u_long
#define u_long unsigned long 
#endif

static u_long md_32(char *string, int length);
uint32_t random32(int type);

#ifdef __cplusplus
}  /* end extern "C" */
#endif

#endif