# assembly-pong

## description
This is a simple pong game written in 8086 assembly. <br>
I started this project as a way to learn assembly, in preparation for an upcoming unit at university.

## how to run
  What is needed to run the game:
  - DOSBox
  - 8086 assembler (masm)

  to run the game:
   - clone the repository
   - open DOSBox <br> 
   - mount the directory where the game is located <br>
   - commands to run the game
     - run the game by typing `masm /a pong.asm`, enter through the prompts or ';' to skip prompts
     - type `link pong`, enter through the prompts or ';' to skip prompts 
     - finally `pong` to run the game

## game screenshots

#### main menu
![image](https://github.com/jamesrdoran/assembly-pong/assets/139739768/55c4d7c5-eac6-4df5-b36e-358e4c1677ee)

#### game play
![image](https://github.com/jamesrdoran/assembly-pong/assets/139739768/c702a402-fe15-4bc9-a6de-393b428aea01)

#### game over
![image](https://github.com/jamesrdoran/assembly-pong/assets/139739768/be9094b4-d18e-4b1f-8767-67cbdffca3bc)

## how to play

### start a game
`s or S` - start a single player game <br>
`m or M` - start a multiplayer game <br>
`e or E` - exit the game

### movement
left paddle: <br>
  `w or W` - up <br>
  `s or S` - down <br>

right paddle: <br>
  `o or O` - up <br>
  `l or L` - down <br>

### restart or exit the game
`r or R` - restart the game <br>
`e or E` - exit the game

## credits

All credit goes to programmingdimension for creating the YouTube tutorial <br>
https://github.com/programmingdimension/8086-Assembly-Pong
