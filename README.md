![release gif](https://github.com/user-attachments/assets/71592007-b9d1-43e0-ac41-d55bec9040b0)

Hello! Welcome to QRawl: Tiny Mass Disco, a 16x9 rhythm dungeon crawler. This game was created as part of the the Tiny Mass Games project, a loose collective of game devs focused on creating polished short-form games in two-month dev cycles. This game came out of our tenth season, and I decided to open-source the code after completing it. The official web version of the game can be found at https://joshuagalecki.itch.io/qrawl-tiny-mass-disco.

There are two important things to understand in terms of designing a rhythm dungeon crawler. The first is the rhythm part of it. For the basics of the Conductor class and creating a rhythm game, I'll refer you to fizzd's legendary tutorial on A Dance of Ice and Fire, archived at https://web.archive.org/web/20190317082117/http://ludumdare.com/compo/2014/09/09/an-ld48-rhythm-game-part-2/. Honestly, I've done three rhythm games and prototypes now and I dredge that up every time. Classic. 

The second important thing to understand is the dungeon crawler part of the game. Many rhythm games don't have to deal with this side, as something like Guitar Hero only rates input instead of really reacting to it. Lots of cues have been taken from Crypt of the Necrodancer, since they invented the genre combination.

The player's input can be in eight different states:

- None: The player has not put in any input yet, but they still could.
- Early: The player hit a direction, but it was too long before the beat to count as good input. This is a failure input.
- Okay: The player hit a direction, but it was a decent bit before or after the beat hits. Barely good enough to count as a good input.
- Good: The player hit a direction and it was acceptably within a window of time around the beat.
- Great: The player hit a direction and it was very close to the beat.
- Late: The plaer hit a direction, but it was too long after the beat to count as a good input. This is a failure input.
- Failed: The player hit a direction, but the requested direction was illegal. (For instance, trying to go into a wall when you can't dig.) This is a failure input.
- Missed: A beat closed out without any input from the player. This is a failure input.

Here's a chart showing the timings. It may seem obvious, but it's worth mentioning that a player can hit valid input on either side of the beat.

![Input Rating Explanation](https://github.com/user-attachments/assets/de90ebd7-f345-4d3d-ae29-fbb4bd117ccc)

When we are 25% of the way to the next beat, the Conductor sends out a beat close out signal. This lets us wrap up any logic related to that particular beat. For instance, if the player hasn't moved by that point, they aren't given a chance to. Technically, they missed their chance after the OK envelope closed. The point of the close out signal is to signify that the beat is closed and the game logic should move on. Mistimed input immediately after the close out signal now counts as an Early input for the next beat instead of a Late input for the previous one.

(A small aside: why not have a close out signal right after the OK envelope expires? That gives us a chance to mark the input as Late for the old beat. You can have a Great / Good / OK input for 0.06 / 0.12 / 0.18 beats after the beat hit, and then Late input until we're at 0.25 beats. It wouldn't be very sporting for a player to have an input at 0.2 beats, miss the OK on one beat and get marked off as Early for the next beat.)

So, now to my favorite part of the code - time travel! As fizzd says, we want everything in the game to respond to the beat, right? But, we also want the monsters to wait until after the player has provided input. If a player is being chased by a ghost and the ghost is going to attack on the beat, how do you accept a late-but-valid input from the player? (Let's say they hit an input 0.05 beats after the beat hit, well within our envelope.) Making the monsters wait until after player input (or after the beat closes out) looks awful, as they won't be sync'ed up to the music at all.

Time travel is the solution, of course. I keep the entire game state in a single object. In one specific case - when the beat hits but player input is still None - I keep a copy of the old game state (previous_game_state) and update the current state (game_state). If the player doesn't do anything and ends up with a Missed input, then the current game state just keeps being the current game state. If the player does hit a late-but-valid input, then we pass in previous_game_state to the player_controller's update function. If we leave the update function with a valid move from the player, then we'll set previous_game_state to be the current game state and then run all of the "beat hit" updates (that were run on the "old" current game state when the beat hit). 

Time travel is always confusing, so gaze upon this graphic.

![Time travel explanation](https://github.com/user-attachments/assets/9ed19717-345f-4e9f-b7bb-e67745a90d4c)

1) This is the previous beat, call it beat 40. The slime is about to move forward into the player's square. If the player is still there, the slime will stay where it is and attack the player. The current game state is in yellow.
2) Beat 41 hits. No input has been received by the player. Save the current game state as previous_game_state (in pink). Resolve the current game state (in yellow), where the slime attacks the player and the player loses health.
3) Just a bit after beat 41, the player puts in an input. This resolves against previous_game_state (in pink). It's a valid input, so previous_game_state (with the player's updates) becomes the current state. The slime moves forward without attacking the player, since the player is no longer on the same square.

That's the tricky part about dungeon crawling to the beat! Hopefully you've found this guide helpful, either for playing around with this codebase or perhaps implementing your own rhythm dungeon crawler logic.



As a final aside, I cheat the game's 16 x 9 pixel restriction twice. Once for credits for legibility / time's sake, and once after dungeon is beaten. Winning the game reveals that the whole dungeon is a giant QR code. I have a future game idea to make another QR dungeon crawler (the "Qrawl" of the game's title) that can take a picture of any random QR code and make it into a dungeon. I love the idea of taking ads and other intrusions into our daily lives and turning them into our own playgrounds.

This project is licensed under the terms of the MIT license
