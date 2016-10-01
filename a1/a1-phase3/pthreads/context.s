
/*
 * int
 * savecontext(f, savearea, sp)
 * void (*f)();
 * void *savearea;
 * void *sp;
 *
 * If F == 0, save enough of the current state in SAVEAREA so that
 * control can later be returned to the caller of the function calling
 * savecontext().  Savecontext() behaves like setjmp(3) in that 0 is
 * returned when the context is saved but a non-zero value is returned
 * when returnto() resumes execution of the saved context.
 *
 * If F != 0, switch to the stack pointed to by SP and call F.  There is
 * no return from F.
 *
 * void
 * returnto(savearea)
 * void *savearea;
 *
 * Restore the state previously stored in SAVEAREA and continue execution
 * based on that saved state.  This resumes a suspended thread, making
 * it look like a call to savecontext() with F == 0 is now returning.
 *
 * bjb/mwg Dec/89 and Jul/90
 */
/********************************************


note: unless the predecrement addressing mode is used, the register mask can
be interpreted as follows:

------------------------------------------------------------------------------
Mask:  MostSigBit  15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0  LeastSigBit
Register:          a7 a6 a5 a4 a3 a2 a1 a0 d7 d6 d5 d4 d3 d2 d1 d0
------------------------------------------------------------------------------

 if the predecrement addressing mode is used, the mask becomes:
------------------------------------------------------------------------------
Mask:  MostSigBit  15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0  LeastSigBit
Register:          d0 d1 d2 d3 d4 d5 d6 d7 a0 a1 a2 a3 a4 a5 a6 a7

*********************************************/

#if defined(i386) || defined(i686)
#ifdef Darwin
.globl _saveProcContext
.align 4
_saveProcContext:
#else
.globl saveProcContext
.align 4
saveProcContext:
#endif

        mov %ebx, %eax    /* save current index register in accumulator */
        mov 4(%esp), %ebx /* first parameter used as ptr into save area */
        mov %eax, 32(%ebx) /* store current index register into save area */
        mov (%esp), %eax  /* take value at top of stack and put into */
        mov %eax, (%ebx)  /* save area:	 this is return address */
        mov %edi, 4(%ebx) /* store other registers in save area */
        mov %esi, 8(%ebx)
        mov %edx, 16(%ebx)
        mov %ecx, 20(%ebx)
        mov %ebp, 24(%ebx)
        mov %esp, 28(%ebx)
#ifdef Darwin
	mov 32(%ebx), %eax
	mov %eax, %ebx
#else
        mov %eax, %ebx    /* restore the value of the bx register */
#endif
        mov $11, %eax     /* special code to return non-zero value */
        ret		  /* to the caller of saveProcContext */

#ifdef Darwin
.globl _startNewProc
.align 4
_startNewProc:
#else
.globl startNewProc
.align 4
startNewProc:
#endif

        mov 4(%esp),%eax  /* first parameter is the entry point to the fn */
        mov 8(%esp),%esp  /* second parameter is the stack pointer for fn */
        jmp %eax	  /* just do a jmp there */

#ifdef Darwin
.globl _returnToProc
.align 4
_returnToProc:
#else
.globl returnToProc
.align 4
returnToProc:
#endif
        mov 4(%esp), %ebx /* first parameter is pointer to the save area */
        mov 4(%ebx), %edi /* restore all the registers */
        mov 8(%ebx), %esi
        mov 16(%ebx), %edx
        mov 20(%ebx), %ecx
        mov 24(%ebx), %ebp
        mov 28(%ebx), %esp /* the last thing we restore is the stack */
        mov (%ebx), %eax   /* now we are in the context of the new proc */
        mov %eax,(%esp)    /* put the return address into the stack */
        mov 32(%ebx), %eax /* retrieve the original bx register */
        mov %eax, %ebx 
        mov $0, %eax	/* set return value to 0 */
        ret		/* actually perform the return */

#endif /* i386 */


	
#ifdef x86_64
.globl saveProcContext
.align 4
saveProcContext:

        mov %rbx, %rax    /* save current index register in accumulator */
        mov %rdi, %rbx /* first parameter used as ptr into save area */
        mov %rax, 64(%rbx) /* store current index register into save area */
        mov (%rsp), %rax  /* take value at top of stack and put into */
        mov %rax, (%rbx)  /* save area:	 this is return address */
        mov %rdi, 8(%rbx) /* store other registers in save area */
        mov %rsi, 16(%rbx)
        mov %rdx, 32(%rbx)
        mov %rcx, 40(%rbx)
        mov %rbp, 48(%rbx)
        mov %rsp, 56(%rbx)
        mov %rax, %rbx    /* restore the value of the bx register */
        mov $11, %rax     /* special code to return non-zero value */
        ret		  /* to the caller of saveProcContext */

.globl startNewProc
.align 4
startNewProc:
        mov %rdi ,%rax  /* first parameter is the entry point to the fn */
        mov %rsi, %rsp  /* second parameter is the stack pointer for fn */
        jmp %rax	  /* just do a jmp there */


.globl returnToProc
.align 4
returnToProc:
        mov %rdi, %rbx /* first parameter is pointer to the save area */
        mov 8(%rbx), %rdi /* restore all the registers */
        mov 16(%rbx), %rsi
        mov 24(%rbx), %rdx
        mov 40(%rbx), %rcx
        mov 48(%rbx), %rbp
        mov 56(%rbx), %rsp /* the last thing we restore is the stack */
        mov (%rbx), %rax   /* now we are in the context of the new proc */
        mov %rax,(%rsp)    /* put the return address into the stack */
        mov 64(%rbx), %rax /* retrieve the original bx register */
        mov %rax, %rbx 
        mov $0, %rax	/* set return value to 0 */
        ret		/* actually perform the return */

#endif /* x86_64 */


#ifdef sun3
.text
.globl _saveProcContext

_saveProcContext:
	movl	sp@(0x4), a0		/* get save area (1st param) */
        movl    sp@, a0@                /* save ret address, it gets trashed*/
	moveml	#0xfefe, a0@(4)		/* save regs to save area    */
					/* this includes a6 (frame pointer) */
					/* and a7 (stack pointer)    */
        moveq   #17, d0
	rts


.text
.globl _startNewProc

_startNewProc:
        movl    sp@(0x4), a0            /* get function addr from stack   */
        movl    sp@(0x8), sp            /* set stack pointer to new stack */
        jmp     a0@


.text
.globl _returnToProc

_returnToProc:
	movl	sp@(0x4), a0		/* get save area (only param) */
	moveml	a0@(4), #0xfefe    	/* this restores the regs     */
        movl    a0@, sp@
        moveq   #0, d0
        rts

#endif /* sun3 */




#if defined(sun4) || defined(solaris)
#ifdef sun4
#include    <sun4/asm_linkage.h>
#include    <sun4/trap.h>
#endif  

#ifdef solaris
#define _ASM
#include <sys/trap.h> 
#include <sys/stack.h>

#endif 
topstack =  0
globals  = 12

.text
#ifdef sun4
.global _saveProcContext
_saveProcContext:
#else
.global saveProcContext
saveProcContext:
#endif
    st  %g1, [%o0 + globals +  0]        ! Save all globals just in case
    st  %g2, [%o0 + globals +  4]
    st  %g3, [%o0 + globals +  8]
    st  %g4, [%o0 + globals + 12]
    st  %g5, [%o0 + globals + 16]
    st  %g6, [%o0 + globals + 20]
    st  %g7, [%o0 + globals + 24]
    mov %y, %g1
    st  %g1, [%o0 + globals + 28]

    st  %sp, [%o0 + topstack + 0]
    st  %o7, [%o0 + topstack + 4]

    jmp  %o7 + 0x8
    add %g0, 17, %o0

.text
#ifdef sun4
.global _startNewProc
_startNewProc:
#else
.global startNewProc
startNewProc:
#endif
    ta  ST_FLUSH_WINDOWS                ! Flush all other active windows

    add  %o1, STACK_ALIGN - 1, %o1      ! SPARC requires stricter alignment
    and  %o1, ~(STACK_ALIGN - 1), %o1   ! than malloc gives so force alignment
    sub  %o1, SA(MINFRAME), %fp
    sub  %fp, SA(MINFRAME), %sp

    jmpl %o0, %g0
    nop

.text
#ifdef sun4

.globl _returnToProc

_returnToProc:
#else
.globl returnToProc
returnToProc:
#endif
    ta  ST_FLUSH_WINDOWS                ! Flush all other active windows

    ld  [%o0 + globals + 28], %g1       ! Restore global regs
    mov %g1, %y
    ld  [%o0 + globals +  0], %g1
    ld  [%o0 + globals +  4], %g2
    ld  [%o0 + globals +  8], %g3
    ld  [%o0 + globals + 12], %g4
    ld  [%o0 + globals + 16], %g5
    ld  [%o0 + globals + 20], %g6
    ld  [%o0 + globals + 24], %g7

    ld  [%o0 + topstack + 0], %fp
    sub %fp, SA(MINFRAME), %sp
    ld  [%o0 + topstack + 4], %o7

    clr  %o0
    retl
    restore %o0, 0x0, %o0

#endif /* sun4 */

#ifdef hp700

	.CODE
	.SUBSPA $CODE$
	.EXPORT saveProcContext,ENTRY
	.PROC
	.CALLINFO
saveProcContext .ENTER
	STWM    %rp, 4(%arg0)         /* store return address */
	STWM    3, 4(%arg0)           /* store general purpose registers */
	STWM    4, 4(%arg0)
	STWM    5, 4(%arg0)
	STWM    6, 4(%arg0)
	STWM    7, 4(%arg0)
	STWM    8, 4(%arg0)
	STWM    9, 4(%arg0)
	STWM    10, 4(%arg0)
	STWM    11, 4(%arg0)
	STWM    12, 4(%arg0)
	STWM    13, 4(%arg0)
	STWM    14, 4(%arg0)
	STWM    15, 4(%arg0)
	STWM    16, 4(%arg0)
	STWM    17, 4(%arg0)
	STWM    18, 4(%arg0)
	STWM    19, 4(%arg0)
	STWM    20, 4(%arg0)
	STWM    21, 4(%arg0)
	STWM    22, 4(%arg0)
	STWM    %sl, 4(%arg0)       /* store static link (necessray?) */
	STWM    %sp, 4(%arg0)       /* store stack pointer            */

	LDIL	17,%ret0            /* return the perfect number      */
	.LEAVE
	.PROCEND


	.EXPORT startNewProc,ENTRY
	.PROC
	.CALLINFO
startNewProc  .ENTER
	LDIL    0, 3         /* clear register 3                   */
	LDH     0(%arg0), 3  /* dereference value supplied as addr */
	BV	0(3)         /* branch to that location    
			      * - note: this is peculiar to cc on hpux. gcc on
			      * this architecture (and others I've seen) pass
			      * the address directly rather than a reference to
			      * where it is located!
			      */
	COPY	%arg1,%sp    /* set stack pointer to new stack */
	.LEAVE 
	.PROCEND


	.EXPORT returnToProc,ENTRY
	.PROC
	.CALLINFO
returnToProc .ENTER
	LDWM    4(%arg0), %rp         /* load return address */
	LDWM    4(%arg0), 3           /* load general purpose registers */
	LDWM    4(%arg0), 4
	LDWM    4(%arg0), 5
	LDWM    4(%arg0), 6
	LDWM    4(%arg0), 7
	LDWM    4(%arg0), 8
	LDWM    4(%arg0), 9
	LDWM    4(%arg0), 10
	LDWM    4(%arg0), 11
	LDWM    4(%arg0), 12
	LDWM    4(%arg0), 13
	LDWM    4(%arg0), 14
	LDWM    4(%arg0), 15
	LDWM    4(%arg0), 16
	LDWM    4(%arg0), 17
	LDWM    4(%arg0), 18
	LDWM    4(%arg0), 19
	LDWM    4(%arg0), 20
	LDWM    4(%arg0), 21
	LDWM    4(%arg0), 22
	LDWM    4(%arg0), %sl       /* load static link (necessray?) */
	LDWM    4(%arg0), %sp       /* load stack pointer            */
	LDIL	0, %ret0            /* return zero */
	.LEAVE
	.PROCEND
        .END
#endif /* hp700 */


#ifdef mips
/* mips stuff has yet to be tested */

.text
.globl saveProcContext
.ent saveProcContext

saveProcContext:
        sw      $16,  0($4)             /* save regs to save area */
        sw      $17,  4($4)
        sw      $18,  8($4)
        sw      $19, 12($4)
        sw      $20, 16($4)
        sw      $21, 20($4)
        sw      $22, 24($4)
        sw      $23, 28($4)
        sw      $fp, 32($4)
        sw      $sp, 36($4)
        sw      $31, 40($4)
        /* Don't know if gp needs to be saved... */

        li      $2, 17
        j       $31
.end saveProcContext

.text
.globl startNewProc
.ent startNewProc
startNewProc:
        addu    $sp, $0, $5             /* set stack pointer to new stack */
        j       $4
.end startNewProc


.text
.globl returnToProc
.ent returnToProc

returnToProc:
        lw      $16,  0($4)
        lw      $17,  4($4)
        lw      $18,  8($4)
        lw      $19, 12($4)
        lw      $20, 16($4)
        lw      $21, 20($4)
        lw      $22, 24($4)
        lw      $23, 28($4)
        lw      $fp, 32($4)
        lw      $sp, 36($4)

        lw      $31, 40($4)
        li      $2, 0
        j       $31
.end returnToProc

#endif /* mips */
