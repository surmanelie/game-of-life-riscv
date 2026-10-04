.section ".word"
   /* Game state memory locations */
  .equ CURR_STATE, 0x90001000       /* Current state of the game */
  .equ GSA_ID, 0x90001004           /* ID of the GSA holding the current state */
  .equ PAUSE, 0x90001008            /* Is the game paused or running */
  .equ SPEED, 0x9000100C            /* Current speed of the game */
  .equ CURR_STEP,  0x90001010       /* Current step of the game */
  .equ SEED, 0x90001014             /* Which seed was used to start the game */
  .equ GSA0, 0x90001018             /* Game State Array 0 starting address */
  .equ GSA1, 0x90001058             /* Game State Array 1 starting address */
  .equ CUSTOM_VAR_START, 0x90001200 /* Start of free range of addresses for custom vars */
  .equ CUSTOM_VAR_END, 0x90001300   /* End of free range of addresses for custom vars */
  .equ RANDOM, 0x40000000           /* Random number generator address */
  .equ LEDS, 0x50000000             /* LEDs address */
  .equ SEVEN_SEGS, 0x60000000       /* 7-segment display addresses */
  .equ BUTTONS, 0x70000004          /* Buttons address */

  /* States */
  .equ INIT, 0
  .equ RAND, 1
  .equ RUN, 2

  /* Colors (0bBGR) */
  .equ RED, 0x100
  .equ BLUE, 0x400

  /* Buttons */
  .equ JT, 0x10
  .equ JB, 0x8
  .equ JL, 0x4
  .equ JR, 0x2
  .equ JC, 0x1
  .equ BUTTON_2, 0x80
  .equ BUTTON_1, 0x20
  .equ BUTTON_0, 0x40

  /* LED selection */
  .equ ALL, 0xF

  /* Constants */
  .equ N_SEEDS, 4           /* Number of available seeds */
  .equ N_GSA_LINES, 10       /* Number of GSA lines */
  .equ N_GSA_COLUMNS, 12    /* Number of GSA columns */
  .equ MAX_SPEED, 10        /* Maximum speed */
  .equ MIN_SPEED, 1         /* Minimum speed */
  .equ PAUSED, 0x00         /* Game paused value */
  .equ RUNNING, 0x01        /* Game running value */

.section ".text.init"
  .globl main

main:
  li sp, CUSTOM_VAR_END /* Set stack pointer, grows downwards */ 
game_start:
  jal ra, reset_game
  jal ra, get_input
  mv s0, a0
game_loop:
  mv a0, s0
  jal ra, select_action
  mv a0, s0
  jal ra, update_state
  jal ra, update_gsa
  jal ra, clear_leds
  jal ra, mask
  jal ra, draw_gsa
  jal ra, wait
  jal ra, decrement_step
  bnez a0, game_start
  jal ra, get_input
  mv s0, a0
  j game_loop

/* BEGIN:auxiliary */
/* Place all auxiliary procedures and additional constants 
   that may be used by other procedures in this section */

/* END:auxiliary */

/* BEGIN:clear_leds */
clear_leds:
  li t0, LEDS
  li t1, 0x7FF
  sw t1, 0(t0)
  ret
/* END:clear_leds */

/* BEGIN:set_pixel */
set_pixel:
  slli t0, a1, 4
  or t0, t0, a0
  li t1, RED
  or t0, t0, t1
  li t1, 0x10000
  or t0, t0, t1
  li t2, LEDS
  sw t0, 0(t2)
  ret
/* END:set_pixel */

/* BEGIN:wait */
wait:
  li t0, 0x400
  li t1, SPEED
  lw t1, 0(t1)
  bgez t1, wait_check
  li t1, MIN_SPEED
wait_check:
  bnez t1, wait_loop
  li t1, MIN_SPEED
wait_loop:
  sub t0, t0, t1
  bgez t0, wait_loop
  ret
/* END:wait */

/* BEGIN:set_gsa */
set_gsa:
  li t0, GSA_ID
  lw t0, 0(t0)
  slli t0, t0, 6
  slli t1, a1, 2
  add t0, t0, t1
  li t1, GSA0
  add t0, t0, t1
  sw a0, 0(t0)
  ret
/* END:set_gsa */

/* BEGIN:get_gsa */
get_gsa:
  li t0, GSA_ID
  lw t0, 0(t0)
  slli t0, t0, 6
  slli t1, a0, 2
  add t0, t0, t1
  li t1, GSA0
  add t0, t0, t1
  lw a0, 0(t0)
  ret
/* END:get_gsa */

/* BEGIN:draw_gsa */
draw_gsa:
  li t0, GSA_ID
  lw t0, 0(t0)
  slli t0, t0, 6
  li t1, GSA0
  add t0, t0, t1
  li t1, 0
  li t2, N_GSA_LINES
  li t3, LEDS
draw_gsa_loop:
  lw t4, 0(t0)
  slli t4, t4, 16
  li t5, RED
  or t4, t4, t5
  slli t5, t1, 4
  or t4, t4, t5
  li t5, ALL
  or t4, t4, t5
  sw t4, 0(t3)
  addi t0, t0, 4
  addi t1, t1, 1
  blt t1, t2, draw_gsa_loop
  ret
/* END:draw_gsa */

/* BEGIN:random_gsa */
random_gsa:
  li t0, GSA_ID
  lw t0, 0(t0)
  slli t0, t0, 6
  li t1, GSA0
  add t0, t0, t1
  li t1, 0
  li t2, RANDOM
random_gsa_line:
  li t3, 0
  li t4, 0
random_gsa_cell:
  lw t5, 0(t2)
  andi t5, t5, 1
  sll t5, t5, t4
  or t3, t3, t5
  addi t4, t4, 1
  li t5, N_GSA_COLUMNS
  blt t4, t5, random_gsa_cell
  sw t3, 0(t0)
  addi t0, t0, 4
  addi t1, t1, 1
  li t5, N_GSA_LINES
  blt t1, t5, random_gsa_line
  ret
/* END:random_gsa */

/* BEGIN:change_speed */
change_speed:
  li t0, SPEED
  lw t1, 0(t0)
  bnez a0, change_speed_dec
  li t2, MAX_SPEED
  bge t1, t2, change_speed_end
  addi t1, t1, 1
  j change_speed_end
change_speed_dec:
  li t2, MIN_SPEED
  bge t2, t1, change_speed_end
  addi t1, t1, -1
change_speed_end:
  sw t1, 0(t0)
  ret
/* END:change_speed */

/* BEGIN:pause_game */
pause_game:
  li t0, PAUSE
  lw t1, 0(t0)
  xori t1, t1, 1
  sw t1, 0(t0)
  ret
/* END:pause_game */

/* BEGIN:change_steps */
change_steps:
  li t0, CURR_STEP
  lw t1, 0(t0)
  add t1, t1, a0
  slli a1, a1, 4
  add t1, t1, a1
  slli a2, a2, 8
  add t1, t1, a2
  sw t1, 0(t0)
  ret
/* END:change_steps */

/* BEGIN:set_seed */
set_seed:
  la t0, SEEDS
  slli a0, a0, 2
  add t0, t0, a0
  lw t0, 0(t0)
  li t1, GSA_ID
  lw t1, 0(t1)
  slli t1, t1, 6
  li t2, GSA0
  add t1, t1, t2
  li t2, 0
  li t3, N_GSA_LINES
set_seed_loop:
  lw t4, 0(t0)
  sw t4, 0(t1)
  addi t0, t0, 4
  addi t1, t1, 4
  addi t2, t2, 1
  blt t2, t3, set_seed_loop
  ret
/* END:set_seed */

/* BEGIN:increment_seed */
increment_seed:
  addi sp, sp, -4
  sw ra, 0(sp)
  li t0, SEED
  lw t1, 0(t0)
  li t2, N_SEEDS
  bge t1, t2, increment_seed_random
  addi t1, t1, 1
  sw t1, 0(t0)
  bge t1, t2, increment_seed_random
  mv a0, t1
  jal ra, set_seed
  j increment_seed_end
increment_seed_random:
  jal ra, random_gsa
increment_seed_end:
  lw ra, 0(sp)
  addi sp, sp, 4
  ret
/* END:increment_seed */

/* BEGIN:update_state */
update_state:
  addi sp, sp, -4
  sw ra, 0(sp)
  li t0, CURR_STATE
  lw t1, 0(t0)
  li t2, RUN
  beq t1, t2, update_state_run
  andi t3, a0, JR
  bnez t3, update_state_to_run
  li t2, RAND
  beq t1, t2, update_state_end
  andi t3, a0, JC
  beqz t3, update_state_end
  li t3, SEED
  lw t3, 0(t3)
  li t4, N_SEEDS
  blt t3, t4, update_state_end
  sw t2, 0(t0)
  j update_state_end
update_state_to_run:
  li t2, RUN
  sw t2, 0(t0)
  li t0, PAUSE
  li t2, RUNNING
  sw t2, 0(t0)
  j update_state_end
update_state_run:
  andi t3, a0, JB
  beqz t3, update_state_end
  jal ra, reset_game
update_state_end:
  lw ra, 0(sp)
  addi sp, sp, 4
  ret
/* END:update_state */

/* BEGIN:select_action */
select_action:
  addi sp, sp, -8
  sw ra, 0(sp)
  sw s0, 4(sp)
  mv s0, a0
  li t0, CURR_STATE
  lw t0, 0(t0)
  li t1, RUN
  beq t0, t1, select_action_run
  andi t2, s0, JC
  beqz t2, select_action_steps
  jal ra, increment_seed
select_action_steps:
  andi a0, s0, BUTTON_0
  srli a0, a0, 6
  andi a1, s0, BUTTON_1
  srli a1, a1, 5
  andi a2, s0, BUTTON_2
  srli a2, a2, 7
  or t2, a0, a1
  or t2, t2, a2
  beqz t2, select_action_end
  jal ra, change_steps
  j select_action_end
select_action_run:
  andi t2, s0, JC
  beqz t2, select_action_jr
  jal ra, pause_game
select_action_jr:
  andi t2, s0, JR
  beqz t2, select_action_jl
  li a0, 0
  jal ra, change_speed
select_action_jl:
  andi t2, s0, JL
  beqz t2, select_action_jt
  li a0, 1
  jal ra, change_speed
select_action_jt:
  andi t2, s0, JT
  beqz t2, select_action_end
  jal ra, random_gsa
select_action_end:
  lw s0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 8
  ret
/* END:select_action */

/* BEGIN:cell_fate */
cell_fate:
  li t0, 3
  beq a0, t0, cell_fate_alive
  beqz a1, cell_fate_dead
  li t0, 2
  beq a0, t0, cell_fate_alive
cell_fate_dead:
  li a0, 0
  ret
cell_fate_alive:
  li a0, 1
  ret
/* END:cell_fate */

/* BEGIN:find_neighbours */
find_neighbours:
  li t0, GSA_ID
  lw t0, 0(t0)
  slli t0, t0, 6
  li t1, GSA0
  add t0, t0, t1
  li t6, 0
  li t5, -1
find_neighbours_y:
  add t1, a1, t5
  bgez t1, find_neighbours_y_pos
  addi t1, t1, N_GSA_LINES
find_neighbours_y_pos:
  li t2, N_GSA_LINES
  blt t1, t2, find_neighbours_y_ok
  addi t1, t1, -N_GSA_LINES
find_neighbours_y_ok:
  slli t1, t1, 2
  add t1, t1, t0
  lw t2, 0(t1)
  li t3, -1
find_neighbours_x:
  or t4, t3, t5
  beqz t4, find_neighbours_next
  add t4, a0, t3
  bgez t4, find_neighbours_x_pos
  addi t4, t4, N_GSA_COLUMNS
find_neighbours_x_pos:
  li a2, N_GSA_COLUMNS
  blt t4, a2, find_neighbours_x_ok
  addi t4, t4, -N_GSA_COLUMNS
find_neighbours_x_ok:
  li a2, 1
  sll a2, a2, t4
  and a2, a2, t2
  beqz a2, find_neighbours_next
  addi t6, t6, 1
find_neighbours_next:
  addi t3, t3, 1
  li a2, 2
  blt t3, a2, find_neighbours_x
  addi t5, t5, 1
  blt t5, a2, find_neighbours_y
  slli t1, a1, 2
  add t1, t1, t0
  lw t2, 0(t1)
  li a2, 1
  sll a2, a2, a0
  and a2, a2, t2
  li a1, 0
  beqz a2, find_neighbours_end
  li a1, 1
find_neighbours_end:
  mv a0, t6
  ret
/* END:find_neighbours */

/* BEGIN:update_gsa */
update_gsa:
  li t0, PAUSE
  lw t0, 0(t0)
  bnez t0, update_gsa_start
  ret
update_gsa_start:
  addi sp, sp, -16
  sw ra, 0(sp)
  sw s0, 4(sp)
  sw s1, 8(sp)
  sw s2, 12(sp)
  li s0, 0
update_gsa_line:
  li s1, 0
  li s2, 0
update_gsa_cell:
  mv a0, s1
  mv a1, s0
  jal ra, find_neighbours
  jal ra, cell_fate
  sll a0, a0, s1
  or s2, s2, a0
  addi s1, s1, 1
  li t0, N_GSA_COLUMNS
  blt s1, t0, update_gsa_cell
  li t0, GSA_ID
  lw t0, 0(t0)
  xori t0, t0, 1
  slli t0, t0, 6
  slli t1, s0, 2
  add t0, t0, t1
  li t1, GSA0
  add t0, t0, t1
  sw s2, 0(t0)
  addi s0, s0, 1
  li t0, N_GSA_LINES
  blt s0, t0, update_gsa_line
  li t0, GSA_ID
  lw t1, 0(t0)
  xori t1, t1, 1
  sw t1, 0(t0)
  lw s2, 12(sp)
  lw s1, 8(sp)
  lw s0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 16
  ret
/* END:update_gsa */

/* BEGIN:get_input */
get_input:
  li t0, BUTTONS
  lw a0, 0(t0)
  sw zero, 0(t0)
  ret
/* END:get_input */

/* BEGIN:decrement_step */
decrement_step:
  li t0, CURR_STEP
  lw t1, 0(t0)
  li t2, CURR_STATE
  lw t2, 0(t2)
  li t3, RUN
  bne t2, t3, decrement_step_display
  li t2, PAUSE
  lw t2, 0(t2)
  beqz t2, decrement_step_display
  addi t1, t1, -1
  sw t1, 0(t0)
  bnez t1, decrement_step_display
  li a0, 1
  ret
decrement_step_display:
  la t0, font_data
  li t2, 0
  li t3, 0
decrement_step_digit:
  andi t4, t1, 0xF
  slli t4, t4, 2
  add t4, t4, t0
  lw t4, 0(t4)
  sll t4, t4, t3
  or t2, t2, t4
  srli t1, t1, 4
  addi t3, t3, 8
  li t4, 32
  blt t3, t4, decrement_step_digit
  li t0, SEVEN_SEGS
  sw t2, 0(t0)
  li a0, 0
  ret
/* END:decrement_step */

/* BEGIN:reset_game */
reset_game:
  addi sp, sp, -4
  sw ra, 0(sp)
  li t0, CURR_STATE
  li t1, INIT
  sw t1, 0(t0)
  li t0, GSA_ID
  sw zero, 0(t0)
  li t0, PAUSE
  li t1, PAUSED
  sw t1, 0(t0)
  li t0, SPEED
  li t1, MIN_SPEED
  sw t1, 0(t0)
  li t0, CURR_STEP
  li t1, 1
  sw t1, 0(t0)
  li t0, SEED
  sw zero, 0(t0)
  li a0, 0
  jal ra, set_seed
  jal ra, decrement_step
  jal ra, clear_leds
  jal ra, mask
  jal ra, draw_gsa
  lw ra, 0(sp)
  addi sp, sp, 4
  ret
/* END:reset_game */

/* BEGIN:mask */
mask:
  li t0, SEED
  lw t0, 0(t0)
  slli t0, t0, 2
  la t1, MASKS
  add t1, t1, t0
  lw t1, 0(t1)
  li t0, GSA_ID
  lw t0, 0(t0)
  slli t0, t0, 6
  li t2, GSA0
  add t0, t0, t2
  li t2, 0
  li t3, LEDS
mask_loop:
  lw t4, 0(t1)
  lw t5, 0(t0)
  and t5, t5, t4
  sw t5, 0(t0)
  not t4, t4
  li t5, 0xFFF
  and t4, t4, t5
  slli t4, t4, 16
  li t5, BLUE
  or t4, t4, t5
  slli t5, t2, 4
  or t4, t4, t5
  li t5, ALL
  or t4, t4, t5
  sw t4, 0(t3)
  addi t0, t0, 4
  addi t1, t1, 4
  addi t2, t2, 1
  li t5, N_GSA_LINES
  blt t2, t5, mask_loop
  ret
/* END:mask */

/* 7-segment display */
font_data:
  .word 0x3F
  .word 0x06
  .word 0x5B
  .word 0x4F
  .word 0x66
  .word 0x6D
  .word 0x7D
  .word 0x07
  .word 0x7F
  .word 0x6F
  .word 0x77
  .word 0x7C
  .word 0x39
  .word 0x5E
  .word 0x79
  .word 0x71

  seed0:
	.word 0xC00
	.word 0xC00
	.word 0x000
	.word 0x060
	.word 0x0A0
	.word 0x0C6
	.word 0x006
	.word 0x000
  .word 0x000
  .word 0x000

seed1:
	.word 0x000
	.word 0x000
	.word 0x05C
	.word 0x040
	.word 0x240
	.word 0x200
	.word 0x20E
	.word 0x000
  .word 0x000
  .word 0x000

seed2:
	.word 0x000
	.word 0x010
	.word 0x020
	.word 0x038
	.word 0x000
	.word 0x000
	.word 0x000
	.word 0x000
  .word 0x000
  .word 0x000

seed3:
	.word 0x000
	.word 0x000
	.word 0x090
	.word 0x008
	.word 0x088
	.word 0x078
	.word 0x000
	.word 0x000
  .word 0x000
  .word 0x000


# Predefined seeds
SEEDS:
  .word seed0
  .word seed1
  .word seed2
  .word seed3

mask0:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
  .word 0xFFF
  .word 0xFFF

mask1:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF
  .word 0x1FF
  .word 0x1FF

mask2:
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
  .word 0x7FF
  .word 0x7FF

mask3:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000
  .word 0x000
  .word 0x000

mask4:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000
  .word 0x000
  .word 0x000

MASKS:
  .word mask0
  .word mask1
  .word mask2
  .word mask3
  .word mask4
