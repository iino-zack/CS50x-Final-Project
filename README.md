# Monkey And Hunter
#### Video Demo: https://youtu.be/ci4v8mvby4Q
#### Description:
As the project name suggests, the monkey and hunter is a hypothetical scenario often used to illustrate the effect of gravity on projectile motion. It can be presented as exercise problem or as a demonstration. Yet my project elevates the scenario even further by incorporating drag force, setting random velocities to the monkey and randomising physical variables and leaving it for the player to solve in order to shoot at the monkey and get the highest score!

#### Some cool features!?
- The game scales accordingly depending on the game's window size! So no matter how big or small your monitor is, Gameplay will always be the same across multiple platforms!
- Physics simulation is not bound to FPS. So high FPS and low FPS doesn't really give you an competitive advantage compared to some games.

#### Folder (root)

**`main.lua`:**
- `main.lua` is the ENTIRETY of the game.
- It handles everything from visuals all the way to physics, from loading the game to updating the game.
- Prepare yourselves when you dive into the spaghetti code... D:


**`conf.lua`:**
- `conf.lua` is the configuration file used the LÖVE game engine .
- It defines the minimum width, mimimum height, title and icon of the game.
- Feel free to configure this to your liking!

#### Folder (assets)
The assets used in the game, I used paint.net for those who were wondering!

**`background 1.png`:**
- Pretty basic background with clouds and a blue blue sky!

**`background 2.png`:**
- Another basic background, this time during noon and with a tree and a rivine!

**`background 3.png`:**
- *cricket noises* Shhhhh! Dont make any sudden moves! wait.... does the night help you in hunting monkeys?

**`cannon.png`:**
- The cannon used in hunting season, Boy has she grown ever since the scratch days!

**`cannonball.png`:**
- BFF of ```cannon.png```. Together, they are an unstoppable duo!

**`dead monke.png`:**
- Ouch. May it rest in peace...

**`icon.png`:**
- Icon used in the game!

**`monke.png`:**
- Aha! Got you in my sights! Take aim... steady.. Fire!

**`wheel.png`:**
- I think ```wheel.png``` needs a wheelchair...

#### Folder (modules)

**`buttons.lua`:**
- `buttons.lua` was responsible for creating the main menu buttons!
- It takes in a ```text``` string input and a ```func``` function, Creating a new button and returns a table with the provided parameters.
- This was used in ```main.lua```'s main menu where it handles everything from playing the game, showing help info, changing difficulty and exiting the game!
