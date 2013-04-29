# File:		$Id$
# Author:	Kevin Carbone
#
# Description:	Project-board_printer.asm
#               This file handles the functions
#		that are responsible for printing the board.
#                               
#               
#
# Revisions:	$Log$

.data
	.globl	SIZE
	.globl	BOARD
.align 0
diagonal: .asciiz "\\" 
side: .asciiz "|"
nl: .asciiz "\n"
hash: .asciiz "#"
space: .asciiz " "

border: .asciiz	"---+"
intersect: .asciiz "+"

PRINT_INT = 	1
PRINT_STRING = 	4
READ_INT = 	5
EXIT = 		10
.text
.align 2


#Prints the board
print_board:
	addi	$sp,$sp,-4
	sw	$ra,0($sp)
	
	la	$t0,BOARD
	lw	$t1,SIZE
	move	$t7,$t0
	move	$t2,$t1 	#row counter
	move	$t6,$t1		#col counter
	jal	print_border
#	jal	print_nl
#	jal	print_wall
row_loop:
	beq	$t2,$zero,print_done
	jal	print_nl
	jal	print_wall
acc_loop:
	beq	$t6,$zero,mid_line_print

acc_clue_print:

	lw	$t3,0($t0)
	beq	$t3,$zero,acc_none
	jal	print_slash
	div	$t4,$t3,100
	li	$t5,99
	beq	$t4,$t5,block_across
	slti	$t5,$t4,10
	bne	$t5,$zero,acc_sd

	li	$v0,PRINT_INT
	move	$a0,$t4
	syscall
	j	acc_done
acc_none:
	jal	print_space
	jal	print_space
	jal	print_space
	j	acc_done

acc_sd:
	jal	print_hash
	li	$v0,PRINT_INT
	move	$a0,$t4
	syscall
	j	acc_done

block_across:
	jal	print_hash
	jal	print_hash

acc_done:
	jal	print_wall
	addi	$t6,$t6,-1
	addi	$t0,$t0,8
	j	acc_loop
	
mid_line_print:
	
	move	$t0,$t7
	lw	$t6,(SIZE)
	jal	print_nl
	jal	print_wall
mid_line_loop:

	lw	$t3,0($t0)
	beq	$t3,$zero,mid_p_val
	jal	print_hash
	jal	print_slash
	jal	print_hash
	j	mid_line_done

mid_p_val:
	jal	print_space
	li	$v0,PRINT_INT
	lw	$a0,4($t0)
	beq	$a0,$zero,mid_space
	syscall
	j	n_spce
mid_space:
	jal	print_space
n_spce:
	jal	print_space
	j	mid_line_done
	

mid_line_done:
	jal	print_wall
	addi	$t0,$t0,8
	addi	$t6,$t6,-1
	beq	$t6,$zero,dow_clue_print
	j	mid_line_loop
dow_clue_print:
	move	$t0,$t7
	lw	$t3,0($t0)
	lw	$t6,(SIZE)
	jal	print_nl
	jal	print_wall

dow_clue_loop:
	lw	$t3,0($t0)	
	beq	$t3,$zero,dow_none
	div	$t3,$t3,100
	mfhi	$t3
	li	$t5,99
	beq	$t3,$t5,dow_clue_block
	slti	$t5,$t3,10
	bne	$t5,$zero,dow_sd
	li	$v0,PRINT_INT
	move	$a0,$t3
	syscall
	jal	print_slash
	j	dow_clue_done

dow_sd:
	jal	print_hash
	li	$v0,PRINT_INT
	move	$a0,$t3
	syscall
	jal	print_slash
	j	dow_clue_done

dow_none:
	jal	print_space
	jal	print_space
	jal	print_space
	j	dow_clue_done

dow_clue_block:
	jal	print_hash
	jal	print_hash
	jal	print_slash

dow_clue_done:
	jal	print_wall
	addi	$t0,$t0,8
	addi	$t6,$t6,-1
	beq	$t6,$zero,row_done
	j	dow_clue_loop

row_done:
	addi	$t2,$t2,-1
	lw	$t6,(SIZE)
	mul	$t5,$t6,8
	add	$t7,$t7,$t5
	move	$t0,$t7
	jal	print_nl
	jal	print_border
#	jal	print_nl
#	jal	print_wall
	j	row_loop
	


print_done:
	jal	print_nl
	lw	$ra,($sp)
	addi	$sp,$sp,4
	jr	$ra



print_space:
	li	$v0,PRINT_STRING
	la	$a0,space
	syscall
	jr	$ra

print_slash:
	li	$v0,PRINT_STRING
	la	$a0,diagonal
	syscall
	jr	$ra

print_wall:
	li	$v0,PRINT_STRING
	la	$a0,side
	syscall
	jr	$ra

print_nl:
	li	$v0,PRINT_STRING
	la	$a0,nl
	syscall
	jr	$ra

print_hash:
	li	$v0,PRINT_STRING
	la	$a0,hash
	syscall
	jr	$ra

print_border:
	li	$v0,PRINT_STRING
	la	$a0,intersect
	syscall
	lw	$a1,SIZE
p_border_lp:
	la	$a0,border
	syscall
	addi	$a1,$a1,-1
	bne	$a1,$zero,p_border_lp
	jr	$ra


