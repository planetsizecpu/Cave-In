# Cave-In
Cave-In: [Bagman®](https://www.youtube.com/watch?v=HcVstQnHhSA) Arcade game sequel: **still alpha as [Red](https://www.red-lang.org/p/download.html) lang itself**

![Test Image 0](/scenes/bagman.jpg)

There was this arcade machine game from the early 80's where I spent a lot of coins. As I'm learning Red language, I thought it would be a good training to design a similar game, just to learn while play, because I wanted to play again this game. Red lang allowed me to create the game from scratch, I never imagined it would be so easy & fun to make games (have I mentioned that wanted to play again?), I enjoyed a lot as it has been a long time since I did it this way (since my COBOL epoch at 80's to be honest). 

As it was a lot of work to do for only a person, design everything and put it all to run together was a challenge, I could hardly have done it with another language that was not **human oriented** 😃. Yes, [Red](https://www.red-lang.org/p/download.html) really makes everything a bit easier, I'm sure you would like to [try](https://www.red-lang.org/p/download.html) it if you are, like me, tired of fighting against the tense syntax and semantics of traditional languages. [Red](https://www.red-lang.org/p/download.html) is a data format first, so you write relative expressions and decide what is code and what is data, because everything is data in [Red](https://www.red-lang.org/p/download.html), and so the expressions evaluation runs fluent accordingly. 

In this game I explore the idea of writing the object names out of the source code, in the config files, together with the other object parameters, I had this idea when thinking on how to allow multiple game levels and take profit of these files to reduce the LOC number (~2300), so the objects are created when loading the level config file using the names they have. The code makes intensive use (maybe abuse 😆) of path access to data **across multiple objects** (what I myself refer to as **transobjecting** 😄), this feature, native on Red, avoids using a lot of code functions or so called 'methods' on other langs to manage objects. That is, truly, fighting against software complexity.

I know this game does not have the quality of the true arcade game, but the goal is not to market it, but to learn, to play and share the code to others, so they can also enjoy and learn in his way. In addition there are some known functional concerns on behavior, as for example elevators & kart excessive speed on Linux and different computer speeds (what is itself a challenge), and for sure will discover more flawns, so the development continues, but slowly. 

Official sound support is not available at this time, (you're already aware that Red is alpha stage) so no sound is provided by now. I remember the sound effects & melody the arcade machine had, [Turkey in the Straw](https://www.youtube.com/watch?v=Vr8QnkTwT_w) (ice cream truck song melody), some day music & sound will be available in Red and we could enjoy much more.

**********************************************************************************************************
REQUIREMENTS: None on Windows & MacOs, just click on the executable file. For Linux GTK Must be installed and running.

**To run the game you need to copy the desired executable file from the right folder for your O.S. in the main game folder.**
**********************************************************************************************************

**The game also runs on interpreter!**, you need the [Red](https://www.red-lang.org/p/download.html) toolchain in your path, just download/unpack the files & folders and click on cave.red file (sources must be at the main game folder in this case). This way you'll see a lot of messages in the gui console that help on debug, because I use the gui console for development and testing.

You can also cross-compile your exe going to the `src` folder with `[PATH to Red]red -r -t [target OS] cave.red`.


Meet us at the [Red forums](https://gitter.im/red/red) and ask whatever you want to ask, here is the Red dev team ready for answer, and of course me too. Have fun! 😉 

Red language is an open source project made by Full Stack/Redlake Technologies @ www.red-lang.org 

Bagman game was a registered trade mark by Stern-Seeburg, all my acknowledgments for this great game!

**********************************************************************************************************
INSTRUCTIONS FOR CREATING NEW LEVELS: Read file  zLevelsDesign.txt   please
**********************************************************************************************************
![Test Image 1](/scenes/LevelA.gif)


