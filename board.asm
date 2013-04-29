# File:		$Id$
# Author:	Kevin Carbone
#
# Description:	Project-board.asm
#               This file handles reading in the board
#		and handling bad input.
#                               
#               
#
# Revisions:	$Log$
	.data
	
illegal_size:  .asciiz "\nInvalid board size, Cross Sums terminating\n"
illegal_input: .asciiz "\nIllegal input value, Cross Sums terminating\n"
	.globl SIZE
	.globl	BOARD
.text
PRINT_INT = 	1
PRINT_STRING = 	4
READ_INT = 	5
EXIT = 		10

#Output the size is illegal and exit the program
pr_illegal_size:
	li	$v0,PRINT_STRING
	la	$a0,illegal_size
	syscall
	li	$v0,EXIT
	syscall

#Output the input is illegal and exit the program
pr_illegal_input:
	li	$v0,PRINT_STRING
	la	$a0,illegal_input
	syscall
	li	$v0,EXIT
	syscall

#Reads the board in from STDIN
read_board:
	addi	$sp,$sp,-4
	sw	$ra,0($sp)
	li	$v0,READ_INT
	syscall
	sw	$v0,SIZE
	move	$t0,$v0
	slti	$t1,$t0,13
	sgt	$t2,$t0,1
	and	$t0,$t1,$t2
	beq	$t0,$zero,pr_illegal_size
	
	mul	$t0,$v0,$v0

	move	$t5,$v0

	move	$t1,$zero
	la	$t7,BOARD
read_loop:
	beq	$t1,$t0,done_read_loop

	li	$v0,READ_INT
	syscall
	
	move	$t2,$v0
	move	$a0,$t2
	jal 	handle_input

	sw	$t2,0($t7)
	sw	$zero,4($t7)

	

	addi	$t1,$t1,1
	addi	$t7,$t7,8
	j	read_loop
done_read_loop:
	lw	$ra,($sp)
	addi	$sp,$sp,4
	jr	$ra

#Error Checks input
handle_input:
	beq	$a0,$zero,hi_ret
	move	$t6,$a0
	move	$t4,$zero
	div	$t4,$t6,100
	slti	$t3,$t4,46
	sgt	$t6,$t6,0
	seq	$t4,$t4,99
	or	$t3,$t3,$t4
	and	$t3,$t3,$t6
	beq	$t3,$zero,pr_illegal_input

	move	$t6,$a0
	move	$t4,$zero
	rem	$t4,$t6,100
	slti	$t3,$t4,46
	sgt	$t6,$t6,0
	seq	$t4,$t4,99
	or	$t3,$t3,$t4
	and	$t3,$t3,$t6
	beq	$t3,$zero,pr_illegal_input

hi_ret:	
	jr $ra



