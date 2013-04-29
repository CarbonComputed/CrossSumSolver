# File:		$Id$
# Author:	Kevin Carbone
#
# Description:	Project-cross_sums.asm
#               This file handles the
#		main logic of the program.
#                               
#               
#
# Revisions:	$Log$

	.data
	.align 0

banner: .asciiz	"\n******************\n**  CROSS SUMS  **\n******************\n"
init_board_str: .asciiz "\nInitial Puzzle\n\n"
fin_board_str:	.asciiz	"\nFinal Puzzle\n\n"
imp_puz:  .asciiz "\nImpossible Puzzle\n"

        .align  2               # instructions must be on word boundaries
#	.text                   # this is program code
	

	.globl  main            # main is a global label
	.globl  print_board
	.globl	SIZE
	.globl	read_board
	.globl	nl

#Holds the size of the board.
SIZE:
	.word 0

#Pointer to the current node being processed.
NODE:
	.word BOARD

#Holds the number of the current node being processed.
NODE_CTR:
	.word	0

#Pointer to the board data structure.
#Structure: Value - 4 bytes
#	    Guess - 4 bytes
#	    Total - 8 bytes
BOARD:
	.space 1200

#Pointer to the first empty node, useful for 
#checking impossible puzzles.
FIRST:
	.word 0


# CONSTANTS
#
# syscall codes
PRINT_INT = 	1
PRINT_STRING = 	4
READ_INT = 	5
EXIT = 		10
	.text

#The main function
main:
	addi 	$sp,$sp,-4
	sw	$ra,0($sp)

	li	$v0,PRINT_STRING
	la	$a0,banner
	syscall
	
	jal	read_board
	
	li	$v0,PRINT_STRING
	la	$a0,init_board_str
	syscall
	jal	print_board
	move	$t0,$zero		#zero out registers, just in case.
	move	$t1,$zero
	move	$t2,$zero
	move	$t3,$zero
	move	$t4,$zero
	move	$t5,$zero
	move	$t6,$zero
	move	$t7,$zero
	jal	get_empty
	lw	$t0,NODE_CTR
	sw	$t0,FIRST
	jal	solve_board
	lw	$ra,0($sp)
	addi	$sp,$sp,4
	jr	$ra


#Board Solving function.
#I used backtracking to check for solutions.
solve_board:
	addi	$sp,$sp,-8
	sw	$ra,0($sp)
	sw	$s1,4($sp)
	move	$s3,$sp
w_loop:
	jal	is_goal
	beq	$v0,$zero,not_goal
	li	$v0,PRINT_STRING
	la	$a0,fin_board_str
	syscall
	jal	print_board
	la	$v0,PRINT_STRING
	la	$a0,nl
	syscall
	li	$v0,EXIT
	syscall
not_goal:
	jal	make_move	
	j	w_loop
	lw	$s1,4($sp)
	lw	$ra,0($sp)
	addi	$sp,$sp,8
	jr	$ra


#Makes a guess in the next empty square
# or goes back to a previous one if necessary.
make_move:
	addi	$sp,$sp,-4
	sw	$ra,($sp)
inc_loop:
	lw	$t0,NODE
	lw	$t2,4($t0)
	li	$t7,9
	beq	$t2,$t7,call_undo
	addi	$t2,$t2,1
	sw	$t2,4($t0)
	sw	$t0,NODE
	jal	is_valid
	beq	$v0,$zero,inc_loop
	j	done_mm
call_undo:
	
	jal	undo_move
	j	inc_loop

done_mm:
	jal	get_empty
	lw	$ra,($sp)
	addi	$sp,$sp,4
	jr	$ra

undo_move:			#Undos the current square and goes to the previous empty one.
	addi	$sp,$sp,-36
	sw	$ra,($sp)
	sw	$t7,4($sp)
	sw	$t6,8($sp)
	sw	$t5,12($sp)
	sw	$t4,16($sp)
	sw	$t3,20($sp)
	sw	$t2,24($sp)
	sw	$t1,28($sp)
	sw	$t0,32($sp)

	lw	$t0,NODE
	lw	$t2,4($t0)
	move	$t2,$zero
	sw	$t2,4($t0)
	sw	$t0,NODE
	jal	get_prev_empty


	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra
impossible:
	li	$v0,PRINT_STRING
	la	$a0,imp_puz
	syscall
	li	$v0,EXIT
	syscall

#Checks to see if there are no more empty squares.
#If none are empty, we have a winner.
is_goal:
	addi	$sp,$sp,-4
	sw	$ra,($sp)
	jal	is_none_empty
	move	$s7,$v0
	move	$v0,$s7
	lw	$ra,($sp)
	addi	$sp,$sp,4
	jr	$ra

is_none_empty:
	la	$t0,BOARD
	lw	$t1,SIZE
	mul	$t1,$t1,$t1
is_none_empty_loop:
	beq	$t1,$zero,none_empty
	lw	$t3,($t0)
	lw	$t4,4($t0)
	beq	$t3,$t4,is_empty
	addi	$t1,$t1,-1
	addi	$t0,$t0,8
	j	is_none_empty_loop
is_empty:
	move	$v0,$zero
	jr	$ra
none_empty:
	li	$v0,1
	jr	$ra

#Checks the validity of the board state.
is_valid:
	addi	$sp,$sp,-4
	sw	$ra,($sp)
	jal	check_across
	move	$s7,$v0
	jal	check_down
	and	$s7,$s7,$v0
	jal	check_acc_dup
	and	$s7,$s7,$v0
	jal	check_dow_dup
	and	$s7,$s7,$v0
	move	$v0,$s7
	lw	$ra,($sp)
	addi	$sp,$sp,4
	jr	$ra


get_empty:		#Stores the address of the next empty square in NODE
	addi	$sp,$sp,-36
	sw	$ra,($sp)
	sw	$t7,4($sp)
	sw	$t6,8($sp)
	sw	$t5,12($sp)
	sw	$t4,16($sp)
	sw	$t3,20($sp)
	sw	$t2,24($sp)
	sw	$t1,28($sp)
	sw	$t0,32($sp)
	la	$t0,BOARD
	lw	$t1,($t0)
	lw	$t3,4($t0)
	move	$t2,$zero
get_empty_loop:
	beq	$t1,$t3,get_empty_done
	addi	$t0,$t0,8
	addi	$t2,$t2,1
	lw	$t1,($t0)
	lw	$t3,4($t0)
	j	get_empty_loop
get_empty_done:
	sw	$t0,NODE
	sw	$t2,NODE_CTR
	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra

get_prev_empty:		    #Stores the address of the previous empty square in NODE
	addi	$sp,$sp,-36 #If it cant go back anymore, the puzzle is impossible.
	sw	$ra,($sp)
	sw	$t7,4($sp)
	sw	$t6,8($sp)
	sw	$t5,12($sp)
	sw	$t4,16($sp)
	sw	$t3,20($sp)
	sw	$t2,24($sp)
	sw	$t1,28($sp)
	sw	$t0,32($sp)
	lw	$t0,NODE
	addi	$t0,$t0,-8
	lw	$t1,($t0)
	lw	$t2,NODE_CTR
	addi	$t2,$t2,-1
	lw	$s4,FIRST
	addi	$s4,$s4,-1
	beq	$s4,$t2,impossible
get_prev_empty_loop:
	beq	$t1,$zero,get_prev_empty_done
	addi	$t0,$t0,-8
	addi	$t2,$t2,-1
	lw	$t1,($t0)
	j	get_prev_empty_loop
get_prev_empty_done:
	sw	$t0,NODE
	sw	$t2,NODE_CTR
	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra



#Checks the validity of the across run.
check_across:
	addi	$sp,$sp,-36
	sw	$ra,($sp)
	sw	$t7,4($sp)
	sw	$t6,8($sp)
	sw	$t5,12($sp)
	sw	$t4,16($sp)
	sw	$t3,20($sp)
	sw	$t2,24($sp)
	sw	$t1,28($sp)
	sw	$t0,32($sp)

	lw	$t0,NODE
	lw	$t1,NODE_CTR
	lw	$t2,SIZE
	move	$t5,$zero
check_a_loop:
	lw	$t3,($t0)
	lw	$t4,4($t0)
	add	$t5,$t5,$t4
	move	$a0,$t1
	lw	$a0,-8($t0)
	jal	is_block_clue
	move	$t4,$v0
	bne	$t4,$zero,done_a_loop
	addi	$t0,$t0,-8

	j	check_a_loop
done_a_loop:
	move	$t1,$t0
	jal	is_last_acc
	move	$a0,$v0
	li	$v0,PRINT_INT
	move	$v0,$a0
	move	$t0,$t1
	move	$t4,$v0
	lw	$t7,-8($t0)
	div	$t7,$t7,100
	move	$a0,$t7
	li	$v0,PRINT_INT
	move	$a0,$t5
	li	$v0,PRINT_INT
	bne	$t4,$zero,ch_a_eq
	slt	$t5,$t5,$t7
	bne	$t5,$zero,a_loop_ret_one
	move	$v0,$zero
	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra	
ch_a_eq:
	beq	$t5,$t7,a_loop_ret_one
	move	$v0,$zero	
	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra
a_loop_ret_one:
	li	$v0,1
	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra


#Checks if the square is the last one in an across run.
is_last_acc:
	addi	$sp,$sp,-20
	sw	$t7,0($sp)
	sw	$t6,4($sp)
	sw	$t5,8($sp)
	sw	$t4,12($sp)
	sw	$ra,16($sp)

	lw	$t5,NODE
	lw	$t4,($t5)
	lw	$t5,8($t5)
	lw	$t6,NODE_CTR
	sne	$t0,$t5,$zero
	move	$v0,$zero
	move	$a0,$t6
	jal	is_right_wall
	move	$s5,$v0
	move	$v0,$s5
	or	$v0,$t0,$v0
	lw	$t7,0($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	lw	$ra,16($sp)
	addi	$sp,$sp,20
	jr	$ra

#Checks validity of a downward run.
check_down:
	addi	$sp,$sp,-36
	sw	$ra,($sp)
	sw	$t7,4($sp)
	sw	$t6,8($sp)
	sw	$t5,12($sp)
	sw	$t4,16($sp)
	sw	$t3,20($sp)
	sw	$t2,24($sp)
	sw	$t1,28($sp)
	sw	$t0,32($sp)

	lw	$t0,NODE
	lw	$t1,NODE_CTR

	move	$t5,$zero
check_d_loop:
	lw	$t3,($t0)
	lw	$t4,4($t0)
	add	$t5,$t5,$t4
	move	$a0,$t1
	#jal	is_up_wall
	#move	$t4,$v0
	lw	$t2,SIZE
	mul	$t2,$t2,8
	
	move	$a0,$t0
	sub	$a0,$a0,$t2
	lw	$a0,0($a0)
	jal	is_block_clue
	move	$t4,$v0
	bne	$t4,$zero,done_d_loop
	sub	$t0,$t0,$t2
	j	check_d_loop
done_d_loop:
	jal	is_last_down
	move	$t4,$v0
	lw	$t2,SIZE
	mul	$t2,$t2,8
	move	$t6,$t2
	move	$t7,$t0
	sub	$t7,$t7,$t6
	lw	$t7,0($t7)
	rem	$t7,$t7,100
	bne	$t4,$zero,ch_d_eq
	slt	$t5,$t5,$t7
	bne	$t5,$zero,d_loop_ret_one
	move	$v0,$zero
	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra	
ch_d_eq:
	beq	$t5,$t7,d_loop_ret_one
	move	$v0,$zero	
	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra
d_loop_ret_one:
	li	$v0,1
	lw	$ra,($sp)
	lw	$t7,4($sp)
	lw	$t6,8($sp)
	lw	$t5,12($sp)
	lw	$t4,16($sp)
	lw	$t3,20($sp)
	lw	$t2,24($sp)
	lw	$t1,28($sp)
	lw	$t0,32($sp)
	addi	$sp,$sp,36
	jr	$ra


#Check if square is last one in down run
is_last_down:
	addi	$sp,$sp,-20
	sw	$t7,0($sp)
	sw	$t6,4($sp)
	sw	$t5,8($sp)
	sw	$t4,12($sp)
	sw	$ra,16($sp)

	lw	$t7,NODE
	lw	$t5,SIZE
	mul	$t5,$t5,8
	add	$t7,$t7,$t5
	lw	$t7,0($t7)
	lw	$t6,NODE_CTR
	sne	$t7,$t7,$zero
	move	$v0,$zero
	move	$a0,$t6
	jal	is_down_wall
	or	$v0,$t7,$v0
	lw	$t7,0($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	lw	$ra,16($sp)
	addi	$sp,$sp,20
	jr	$ra

#Takes value as parameter
#Checks if value is a clue square
is_block_clue:
	bne	$a0,$zero,bl_clue_ret_one
	move	$v0,$zero
	jr	$ra
bl_clue_ret_one:
	li	$v0,1
	jr	$ra


#Check if square is against left wall.
is_left_wall:
	addi	$sp,$sp,-16
	sw	$t7,($sp)
	sw	$t6,4($sp)
	sw	$t5,8($sp)
	sw	$t4,12($sp)
	


	beq	$a0,$zero,lw_return_one
	lw	$t2,SIZE
	div	$v0,$a0,$t2
	mfhi	$v0
	beq	$v0,$zero,lw_return_one
	move	$v0,$zero
	lw	$t7,($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	addi	$sp,$sp,16
	jr	$ra
lw_return_one:
	li	$v0,1

	lw	$t7,($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	addi	$sp,$sp,16

	jr	$ra

#Check if square is against right wall.
is_right_wall:
	#move	$sp,$s3
#	sub	$a0,$sp,$s3
#	li	$v0,PRINT_INT
#	syscall
	
	addi	$sp,$sp,-16
	sw	$t7,0($sp)
	sw	$t6,0($sp)
	sw	$t5,4($sp)
	sw	$t4,8($sp)
	sw	$ra,12($sp)

	lw	$t7,NODE_CTR
	lw	$t2,SIZE
	div	$t6,$t7,$t2
	mfhi	$t6
	li	$v0,PRINT_INT
	move	$a0,$t6
#	syscall
	
	move	$t7,$zero
	lw	$t7,SIZE
	#break
	addi	$t7,$t7,-1
#	break
	li	$v0,PRINT_INT
	move	$a0,$t7
#	syscall
	beq	$t6,$t7,rw_return_one
	move	$v0,$zero
	lw	$t7,0($sp)
	lw	$t6,0($sp)
	lw	$t5,4($sp)
	lw	$t4,8($sp)
	lw	$ra,12($sp)
	addi	$sp,$sp,16
	jr	$ra
rw_return_one:
	lw	$t7,0($sp)
	lw	$t6,0($sp)
	lw	$t5,4($sp)
	lw	$t4,8($sp)
	lw	$ra,12($sp)
	addi	$sp,$sp,16
	li	$v0,1
	jr	$ra

#Check if square is against up wall.
is_up_wall:
	addi	$sp,$sp,-16
	sw	$t7,($sp)
	sw	$t6,4($sp)
	sw	$t5,8($sp)
	sw	$t4,12($sp)


	lw	$t7,SIZE
	move	$t6,$a0
	slt	$v0,$t6,$t2
	bne	$v0,$zero,uw_return_one
	move	$v0,$zero
	lw	$t7,($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	addi	$sp,$sp,16
	jr	$ra
uw_return_one:
	li	$v0,1
	lw	$t7,($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	addi	$sp,$sp,16
	jr	$ra

#Check if square is against down wall.
is_down_wall:	
	addi	$sp,$sp,-16
	sw	$t7,($sp)
	sw	$t6,4($sp)
	sw	$t5,8($sp)
	sw	$t4,12($sp)


	move	$t6,$a0
	lw	$t7,SIZE
	mul	$t5,$t7,$t7
	sub	$t5,$t5,$t7
	slt	$v0,$t6,$t5
	beq	$v0,$zero,dw_return_one
	move	$v0,$zero
	lw	$t7,($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	addi	$sp,$sp,16

	jr	$ra
dw_return_one:
	li	$v0,1
	lw	$t7,($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	addi	$sp,$sp,16

	jr	$ra




#Checks across run for duplicates
check_acc_dup:
	addi	$sp,$sp,-20
	sw	$t7,0($sp)
	sw	$t6,4($sp)
	sw	$t5,8($sp)
	sw	$t4,12($sp)
	sw	$ra,16($sp)	
	lw	$t7,NODE
	lw	$t4,NODE
acc_dup_o_loop:
	lw	$t6,($t7)
	move	$t4,$t7
	addi	$t4,$t4,-8
	move	$a0,$t6
	jal	is_block_clue
	lw	$t6,4($t7)
	bne	$v0,$zero,acc_dup_r_one
acc_dup_i_loop:
	lw	$t5,($t4)
	move	$a0,$t5
	jal	is_block_clue
	bne	$v0,$zero,acc_dup_di
	lw	$t5,4($t4)
	beq	$t5,$t6,acc_dup_r_zero
	addi	$t4,$t4,-8
	j	acc_dup_i_loop

acc_dup_di:
	addi	$t7,$t7,-8
	j	acc_dup_o_loop
acc_dup_r_zero:
	lw	$t7,0($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	lw	$ra,16($sp)
	addi	$sp,$sp,20
	move	$v0,$zero
	jr	$ra
acc_dup_r_one:
	lw	$t7,0($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	lw	$ra,16($sp)
	addi	$sp,$sp,20
	li	$v0,1
	jr	$ra

#Checks down run for duplicates
check_dow_dup:
	addi	$sp,$sp,-20
	sw	$t7,0($sp)
	sw	$t6,4($sp)
	sw	$t5,8($sp)
	sw	$t4,12($sp)
	sw	$ra,16($sp)	
	lw	$t7,NODE
	lw	$t3,SIZE
	mul	$t3,$t3,-8
dow_dup_o_loop:
	lw	$t6,($t7)
	move	$t4,$t7
	add	$t4,$t4,$t3
	move	$a0,$t6
	jal	is_block_clue
	lw	$t6,4($t7)
	bne	$v0,$zero,dow_dup_r_one
dow_dup_i_loop:
	lw	$t5,($t4)
	move	$a0,$t5
	jal	is_block_clue
	bne	$v0,$zero,dow_dup_di
	lw	$t5,4($t4)
	beq	$t5,$t6,dow_dup_r_zero
	add	$t4,$t4,$t3
	j	dow_dup_i_loop

dow_dup_di:
	add	$t7,$t7,$t3
	j	dow_dup_o_loop
dow_dup_r_zero:
	lw	$t7,0($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	lw	$ra,16($sp)
	addi	$sp,$sp,20
	move	$v0,$zero
	jr	$ra
dow_dup_r_one:
	lw	$t7,0($sp)
	lw	$t6,4($sp)
	lw	$t5,8($sp)
	lw	$t4,12($sp)
	lw	$ra,16($sp)
	addi	$sp,$sp,20
	li	$v0,1
	jr	$ra



