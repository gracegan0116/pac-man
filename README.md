# pac-man

**_The Design_**

The game was designed using one main FSM to generate the control signals for the main game logic which signals one other smaller FSM to control the movement of pac-man. A large multiplexer was used to select the bit to be drawn by the VGA adapter.


A. Main FSM

There are eight states in the Main FSM to handle the main logic of the game. In the INIT state, it waits for the player to generate the start signal(SW[0]) to signal the start of the game. When the start signal is produced by the player, it switches to the next state, PRINT_BG. 

In PRINT_BG state, it prints the maze background of the game. Once it finishes drawing the maze, it makes the done_bg signal go high, which signals to switch to the next state, PRINT_EXIT. Similar to the PRINT_BG state, in PRINT_EXIT state, it prints the exit of the maze and makes the done_exit signal go high once it finishes drawing the exit. However, instead of switching to another PRINT state, it switches to CHECK state. 

In CHECK state, it checks for whether a game-win or a game-over condition occurs. If either the touch_maze signal (output by check_maze module) or the timeout signal (output by the counter module) is high, it jumps immediately to GAME_OVER state. Otherwise, if the is_win signal goes high(output by check_maze module), it jumps to GAME_WIN state.  However, if neither the game-win condition nor the game-over condition is satisfied, it goes to PRINT_PACMAN state, as game continues.
In PRINT_PACMAN state, it sends a signal (go_pacman) to the Animate_Pacman FSM to generate the movement of the pac-man in the direction indicated by the player. A done_pacman signal is produced by the animate_pacman FSM to indicate switching to the next state, WAIT.

In the WAIT state, we generate a one second delay before looping back to DRAW_BG state, so that the sprites on the VGA is sensible to the human eye. The loop continues until one of GAME_WIN or GAME_OVER state is reached.

In GAME_WIN and GAME_OVER states,  which are triggered by the is_win  signal and touch_maze and timeout signals respectively continues to loop in their respective states until the player inputs a reset signal if they wishes to replay the game.

B. Animate_Pacman FSM 

The animate_pacman FSM gets triggered when the reg go_pacman from top module becomes true(1). There are three states in the Animate_Pacman FSM.
Since we cannot allow animation of the pac-man at all times during the game, thus,  the first       state of the Animate_Pacman FSM is the WAIT state. In the Wait state, it waits for the go_pacman signal from the top module to become true(1), once this condition is met, it will go to the next state.

The second state of the Animate_Pacman FSM is the SHIFT state. In the SHIFT state, it checks for the desired movement of the pac-man, if right input is true(1), then it increases the pac-man’s x-position, if left input is true(1) then it decreases the pac-man’s x-position, if up is true(1) then it decreases the pac-man’s y-position and if down is true then it increases the pac-man’s y-position.  After this process, it will jump to the third state.
The third state is the PRINT state. In this state, the pac-man is printed by setting the writeEn signal to be true which triggers the draw_pacman module to draw the pacman at the new position, and sends a signal back to the done_print wire when the pac-man has been drawn. When the done_print wire is true(1), it will go back to the WAIT state.

C.   Check_Maze Module 

The Check_Maze module’s has two main functions. The first function is to check for the overlap between the pac-man sprite and the maze border. The second function is to check if the pac-man arrived at the final destination. 

This module checks for the overlap between the pac-man and the maze by reading the ROM that was created for the maze mif at four different address  that corresponds to the four corners of the pac-man sprite, if any of the four locations has a white pixel then the output isWhite will be true(1). It then perform similar process for checking whether the pac-man arrived at the final destion but this time, it will read the ROM that was created for the exit mif and sets the output isWin true(1) if any of the four locations has a white pixel. 

D.   Vga_Mux Module 

Since only one pixel can be drawn at a time by the vga_adapter module, thus, we need to use a multiplexer that selects the desired image to be drawn on the VGA. This module is used in the Main FSM, it takes in inputs (x-location, y-location and colour) for drawing the pac-man, background, gameover, gamewin, exit and a select signal (MuxSelect). This Mux then outputs a single x-location, y-location and a colour according to the MuxSelect that can be used by the vga_adapter.
