/*Xingeng Wang, xiw031, 11144515
Yuchen Lin  , yul761, 11138672*/
#include "common.h"
#include <stdio.h>
#include <standards.h>
#include <os.h>



volatile int THREAD,DEADLINE,SIZE;


PROCESS child(int SIZE)
{ 
  initTime();
  ResetETimer(0);
  int et;
  int i;
  for(i=0; i<= SIZE ;i=i+1)
  {
     Square(i);
  }
  et=GetETimer(0);
  printf("child pid %d called square() %d times in %d ms\n",MyPid(), counter[MyPid()],et);
}



PROCESS parent(int THREAD)
{
  int i;
  PID Childthread[THREAD];
  for(i=0; i< THREAD ;i=i+1)
  {
    Childthread[i]=Create( (void(*)()) child, 10000000, "child", (void *) SIZE, NORM, USR );
  }

}




void mainp(int argc, char* argv[])
{
   
  THREAD= atoi(argv[1]);
  DEADLINE= atoi(argv[2]);
  SIZE= atoi(argv[3]);

  Create( (void(*)()) parent, 16000, "parent", (void *) THREAD, NORM, USR );
}
