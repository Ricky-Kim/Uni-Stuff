.data
	character: .quad 0x0000000000000000
	amount:	.quad 0x0000000000000000
	position: .quad 0x0000000000000000
    bgcolor: .quad 0x0000000000000000
    fgcolor: .quad 0x0000000000000000
	effect:	 .quad 0x0000000000000000

.include "final.s"
.text
	formatstr: .asciz "%c"
	output: .asciz "\033[38;5;%ld;48;5;%ldm%c"		# without special effect
	soutput: .asciz "\033[%ldm%c"							# with effect
	# soutput: .asciz "\033[4m%c\033[0m"
	coutput: .asciz "\033[0m"

#  to reset
.global main

# ************************************************************
# Subroutine: decode                                         *
# Description: decodes message as defined in Assignment 3    *
#   - 2 byte unknown                                         *
#   - 4 byte index                                           *
#   - 1 byte amount                                          *
#   - 1 byte character                                       *
# Parameters:                                                *
#   first: the address of the message to read                *
#   return: no return value                                  *
# ************************************************************
decode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer
	movq 	%rdi, %r12		# move MESSAGE address to r12

	# your code goes here
decode_start:
	# movq $0, %rcx
	movq (%rdi), %rcx
	movb %cl, character		# move char to memory
	shr $8, %rcx			# bit shift to point to the amount
	movb %cl, amount		# get the amount
	shr $8, %rcx			# bit shift to get next memory block index
	movl %ecx, position		# get next memory block index
    shr $32, %rcx           # bit shift to the foreground color bit
    movb %cl, fgcolor       # get the foreground color bit
    shr $8, %rcx            # bit shift to the background color bit
    movb %cl, bgcolor       # get the background color bit

ploop:						# printing loop

	cmpq $0, amount			# check how many times need to be printed
	je next				# jump to 'next' section to get next memory block position
	movq bgcolor, %rdx		# move background color for compare??????
	cmpq %rdx, fgcolor		# compare foreground and background color
	je addeffect			# if colors are equal, jump to add special effects
	jmp noeffect			# jump to no effect printing section

addeffect:
	cmpq 	$0,   fgcolor		# reset to normal
	je	eff_reset
	cmpq 	$37,  fgcolor	# blink off
	je eff_blink_off
	cmpq 	$42,  fgcolor	# bold
	je eff_bold
	cmpq 	$66,  fgcolor	# faint
	je eff_faint
	cmpq	$105, fgcolor	# conceal
	je eff_conceal
	cmpq	$153, fgcolor	# reveal
	je eff_reveal
	cmpq	$182, fgcolor	# blink
	je eff_blink
	# jmp eff_underline		# undifined effect !!!!!!!!???????


eff_reset:
	movq 	$0,   effect 		# reset 0
	jmp	add_eff_end
eff_blink_off:
	movq 	$25,  effect		# blink off 25
	jmp add_eff_end
eff_bold:
	movq	$1,   effect		# bold 1
	jmp add_eff_end
eff_faint:
	movq	$2,   effect		# faint 2
	jmp add_eff_end
eff_conceal:
	movq	$8,   effect		# conceal $8
	jmp add_eff_end
eff_reveal:
	movq	$28,  effect		# reveal $28
	jmp add_eff_end
eff_blink:
	movq	$5,   effect		# blink 5
	jmp add_eff_end


add_eff_end:
	movq character, %rdx
	movq effect, %rsi		# effect
	movq $soutput, %rdi		# format string for special effect
	jmp callprint			# jump to skip no effect printing section

noeffect:
	movq character, %rcx	# character to print
	movq bgcolor, %rdx		# pass background color
	movq fgcolor, %rsi		# pass foreground color
    movq $output, %rdi	    # pass the format string
callprint:
	movq $0, %rax			# no vector registers. (for printf)
    call printf
	decq amount				# decrease the amount
	jmp ploop				# jump to printing loop
next:
	cmpq $0, position		# check if is is the last position
	je end

	# movq $0, %rcx
	movq position, %rcx
	leaq (%r12, %rcx, 8), %rdi	# get next address

	jmp decode_start



end:
	# epilogue
	popq 	%r12			# restore old r12
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location
	ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi	# first parameter: address of the message
	call	decode			# call decode


	movq $0, %rax			# no vector registers. (for printf)
	movq $coutput, %rdi		# cancel any special effect at the end
    call printf

	popq	%rbp			# restore base pointer location
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program
