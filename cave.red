Red [Needs: 'View
	Title:   "Cave-In"
	Author:  "@planetsizecpu"
	File:    "Cave.red"
] 

; Credit to @rebolek for help on "make face" syntax & browser behavior
; Credit to @toomasv for "play" music dialect porting (not implemented yet) & browser behavior
; Credit to @gltewald for help on png files transparency
; Credit to @endo64 for help on difficulty level
; Credit to @greggirwin for help on L11 Sphinx teleporter door
; Thanks to @dander & others for moral support on early stages 
; Thanks to @TheRedTeam for making this fantastic human-oriented language 
recycle/off
system/view/auto-sync?:  yes

; Load librarys
#include %loadlevel.red
#include %makegame.red
	
; Game data & defaults object
GameData: context [
	Levels: ["L1" "L2" "L3" "L4" "L5" "L6" "L7" "L8" "L9" "L10" "L11" "L12" "L13"] 
	GameRate: 0:00:00.003 
	CaveName: "cave"
	CaveFace: make face! [type: 'base] ;Define a null 'base to avoid compiler error
	CaveFaceHalfSizeX: 800 ;Half x cave size will be updated as we load the level cave image
	CaveFaceRollOffsetX: (0 - CaveFaceHalfSizeX)
	PlayerFace: object [image: []] ;Must be defined to avoid error when compile to release mode
	Items: [] 
	Curlevel: "" 
	Stock: 0 
	Goldbags: 0
	Score: 0
	Gravity: 3
	Antigravity: 3
	DropGravity: 3
	Slide: false
	StepValue: 2
	Inertia: 0.5
	MaxInertia: 2.0
	AddInertia: 0.02
	CeilingDist: 18
	ThiefDeadDelay: 0.1
	SpiderDeadDelay: 0.01
	AgentDeadDelay: 0.03
	AgentRate: 0:00:00.05
	AgentKnockPoints: 25  ;We don't want to promote guards killing behaviors
	KnockAltitude: 10	
	FallingFaceAltitude: 15
	GetupAltitude: 40
	DeadAltitude: 60
	KartStopDelay: 100
	LifterStopDelay: 100
	TerrainColor: 187.145.0.0   ;This color stop gravity effect
	StairsColor1: 68.68.68.0
	StairsColor2: 127.127.127.0
	HandleColor: 195.195.195.0
	LifterCable: 128.64.64.0
	DemoMode: false
	ThiefGetup: [ThiefGetup-X1 ThiefGetup-X2] ;Thief getup sequence
	ThiefDead: [ThiefDead-X1 ThiefDead-X2 ThiefDead-X3 ThiefDead-X4] ;Thief dead sequence
	AgentGetup: [AgentGetup-X1 AgentGetup-X2] ;Agent getup sequence
	AgentDead: [AgentDead-X1 AgentDead-X2 AgentDead-X3 AgentDead-X4] ;Agent dead sequence
	FAgentGetup: [FAgentGetup-X1 FAgentGetup-X2] ;Female agent getup sequence
	FAgentDead: [FAgentDead-X1 FAgentDead-X2 FAgentDead-X3 FAgentDead-X4] ;Female agent dead sequence
	SpiderDead: [SpiderDead-X1 SpiderDead-X2 SpiderDead-X3 SpiderDead-X4] ;Spider dead sequence
	DropDead: [DropDead-X1 DropDead-X2 DropDead-X3 DropDead-X4] ;Drop crash sequence 
]

; Set game screen layout
GameScr: layout [
	title "Cave-In"
	size 800x750
	origin 0x0
	space 0x0
	
	; Info field is also used for event management!
	at 10x610 info: base 780x30 orange blue font [name: "Arial" size: 14 style: 'bold] focus 
	rate GameData/GameRate on-time [
		info/rate: none 
		if CheckStatus [alert "END OF GAME" quit] 
		info/rate: GameData/GameRate
	]
	below
	at 10x655  Glevel: text 110x21 yellow blue font [name: "Arial" size: 14 style: 'bold]
	at 150x655 Glives: text 100x21 yellow blue font [name: "Arial" size: 14 style: 'bold]
	at 290x655 Gstock: text 100x21 yellow blue font [name: "Arial" size: 14 style: 'bold]
	at 430x655 Ggbags: text 100x21 yellow blue font [name: "Arial" size: 14 style: 'bold]										
	at 570x655 Gscore: text 215x21 yellow blue font [name: "Arial" size: 14 style: 'bold]											
	at 10x685  Gdeasy: radio yellow blue "Easy"   on-change [CheckDifficulty]
	at 150x685  Gdnorm: radio yellow blue "Normal" on-change [CheckDifficulty]
	at 290x685  Gddiff: radio yellow blue "Difficult" on-change [CheckDifficulty]
	at 430x685  Gdexpe: radio yellow blue "Expert" on-change [CheckDifficulty]
]

; Open browser to red-lang HQ
OpenBrowser: function [face event][
	if event/type = 'up [
		if (event/offset > 600x525) and (event/offset < 800x570) [
			print "Thanks for visiting us!"
			browse http://www.red-lang.org
		]
	]
]

; Check for agents difficulty rate 
CheckDifficulty: function [][
	if Gdeasy/data [GameData/AgentRate: 0:00:00.07 SetAgentsRate GameData/AgentRate]
	if Gdnorm/data [GameData/AgentRate: 0:00:00.05 SetAgentsRate GameData/AgentRate]
	if Gddiff/data [GameData/AgentRate: 0:00:00.04 SetAgentsRate GameData/AgentRate]
	if Gdexpe/data [GameData/AgentRate: 0:00:00.03 SetAgentsRate GameData/AgentRate]
]

; View splash screen
view/options [size 800x600 	
	  at 1x1 Splash: image 800x600 %DATA/cave-in.jpg 
	  at 650x450 button 100x50 red brick center "P L A Y" on-click [unview]] [actors: context [on-up: func [face event][OpenBrowser face event]]]

; Level loading & start game play
GameData/Curlevel: first GameData/Levels
LoadDfltImages
LoadLevel GameData/Curlevel
MakeGame
view/options GameScr [actors: context [on-key: func [face event][CheckKeyboard face event/key]]]