Red [Needs: 'View
	Title:   "Cave-In"
	Author:  "@planetsizecpu"
	File:    %Cave.red
	Purpose: {This is a arcade game sequel}
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
#include %bogo.red
#include %loadlevel.red
#include %makegame.red

; Game data & defaults object
GameData: context [
	Levels: ["L1" "L2" "L3" "L4" "L5" "L6" "L7" "L8" "L9" "L10" "L11" "L12" "L13" "L14" "L15" 
				"L16" "L17" "L18" "L19" "L20" "L21" "L22" "L23" "L24" "L25" "L26"] 
	GameRate: 0:00:00.003
	either system/platform = 'Windows [
		GameRate: 0:00:00.006 ;Win cant handle 3ms rate so it goes as fast as possible
	][
		GameRate: 0:00:00.065 ;For other OSs as GTK we must test this value as they handle right
	]
	CaveName: "cave"
	CaveFace: make face! [type: 'base] ;Define a null 'base to avoid compiler error
	CaveFaceHalfSizeX: 800 ;Half x cave size will be updated as we load the level cave image
	CaveFaceRollOffsetX: (0 - CaveFaceHalfSizeX)
	CaveFaceHalfSizeY: 600 ;Half y cave size will be updated as we load the level cave image
	CaveFaceRollOffsetY: (0 - CaveFaceHalfSizeY)
	PlayerFace: object [image: []] ;Must be defined to avoid error when compile to release mode
	Items: [] 
	Curlevel: "" 
	Stock: 0 
	Goldbags: 0 ;On wheelbarrow loaded goldbags
	Score: 0
	Gravity: 3 ;Scenarios with slopes are not suitable for higher values, here the boy gets locked
	Antigravity: 3
	DropGravity: 3
	Slide: false
	StepValue: 2
	Inertia: 0.5 ;This values seems to work well from slow cpu's to i5 faster machines
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
	LifterStopDelay: 100	;Standard value for older i5 and less performance machines
	TerrainColor: 187.145.0.0   ;This color stop gravity effect, it can be updated by config file parameter
	StairsColor1: 68.68.68.0
	StairsColor2: 127.127.127.0
	HandleColor: 195.195.195.0
	LifterCable: 128.64.64.0
	DemoMode: false
	ThiefGetup: [ThiefGetup-X1 ThiefGetup-X2] ;Thief getup sequence
	ThiefDead: [ThiefDead-X1 ThiefDead-X2 ThiefDead-X3 ThiefDead-X4] ;Thief dead sequence
	ThiefVanish: [ThiefVanish-X1 ThiefVanish-X2 ThiefVanish-X3 ThiefVanish-X4] ;Thief vanish sequence
	ThiefUnVanish: [ThiefVanish-X4 ThiefVanish-X3 ThiefVanish-X2 ThiefVanish-X1] ;Thief unvanish sequence
	AgentGetup: [AgentGetup-X1 AgentGetup-X2] ;Agent getup sequence
	AgentDead: [AgentDead-X1 AgentDead-X2 AgentDead-X3 AgentDead-X4] ;Agent dead sequence
	FAgentGetup: [FAgentGetup-X1 FAgentGetup-X2] ;Female agent getup sequence
	FAgentDead: [FAgentDead-X1 FAgentDead-X2 FAgentDead-X3 FAgentDead-X4] ;Female agent dead sequence
	PAgentGetup: [PAgentGetup-X1 PAgentGetup-X2] ;PhaGoblins agent getup sequence
	PAgentDead: [PAgentDead-X1 PAgentDead-X2 PAgentDead-X3 PAgentDead-X4] ;PhaGoblins agent dead sequence
	YAgentGetup: [YAgentGetup-X1 YAgentGetup-X2] ;Phantasm agent getup sequence
	YAgentDead: [YAgentDead-X1 YAgentDead-X2 YAgentDead-X3 YAgentDead-X4] ;Phantasm agent dead sequence
	SpiderDead: [SpiderDead-X1 SpiderDead-X2 SpiderDead-X3 SpiderDead-X4] ;Spider dead sequence
	DropDead: [DropDead-X1 DropDead-X2 DropDead-X3 DropDead-X4] ;Drop crash sequence 
]

; Local CPU performance index depending on system state
CpuData: context [
	CpuBogo: bogo
	CpuIdx: 0 ;Std value CPUs older than mid-range i5 to match the game settings
	either system/state/interpreted? [
		if CpuBogo < 0.120 [CpuIdx: 1]
		if CpuBogo < 0.100 [CpuIdx: 2]
		if CpuBogo < 0.080 [CpuIdx: 3]
		if CpuBogo < 0.060 [CpuIdx: 4]
		if CpuBogo < 0.040 [CpuIdx: 5]
		if CpuBogo < 0.020 [CpuIdx: 6]
		if CpuBogo < 0.009 [CpuIdx: 7]
	][
		if CpuBogo < 0.060 [CpuIdx: 1]
		if CpuBogo < 0.050 [CpuIdx: 2]
		if CpuBogo < 0.040 [CpuIdx: 3]
		if CpuBogo < 0.030 [CpuIdx: 4]
		if CpuBogo < 0.020 [CpuIdx: 5]
		if CpuBogo < 0.010 [CpuIdx: 6]
		if CpuBogo < 0.004 [CpuIdx: 7]
	]
]

; Set game screen layout
GameScr: layout [
	title "Cave-In"
	; size 800x750
	size 800x600
	origin 0x0
	space 0x0
	
	; Info field is also used for event management!
	at 10x610 info: base 780x30 orange blue font [name: "Arial" size: 14 style: 'bold] focus 
	rate GameData/GameRate on-time [
		info/rate: none 
		if CheckStatus [alert "END OF GAME" quit] 
		info/rate: GameData/GameRate
	]
]
GameControl: layout [
	below
	at 10x5  Glevel: text 110x21 yellow blue font [name: "Arial" size: 14 style: 'bold]
	at 150x5 Glives: text 100x21 yellow blue font [name: "Arial" size: 14 style: 'bold]
	at 290x5 Gstock: text 100x21 yellow blue font [name: "Arial" size: 14 style: 'bold]
	at 430x5 Ggbags: text 100x21 yellow blue font [name: "Arial" size: 14 style: 'bold]										
	at 570x5 Gscore: text 215x21 yellow blue font [name: "Arial" size: 14 style: 'bold]											
	at 10x35  Gdeasy: radio yellow blue "Easy"   on-change [CheckDifficulty]
	at 150x35  Gdnorm: radio yellow blue "Normal" on-change [CheckDifficulty]
	at 290x35  Gddiff: radio yellow blue "Difficult" on-change [CheckDifficulty]
	at 430x35  Gdexpe: radio yellow blue "Expert" on-change [CheckDifficulty]
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
	at 374x267 bg: text 10x15 black white
	at 650x450 button 100x50 white red center "P L A Y" on-click [bg/text: to-string CpuData/CpuIdx wait 2 unview]] [actors: context [on-up: func [face event][OpenBrowser face event]]
]

; Check CPU index on faster machines to trim waiting time for karts & elevators
if CpuData/CpuIdx > 0 [GameData/LifterStopDelay: 200 GameData/KartStopDelay: 200]
if CpuData/CpuIdx > 1 [GameData/LifterStopDelay: 220 GameData/KartStopDelay: 220]
if CpuData/CpuIdx > 2 [GameData/LifterStopDelay: 240 GameData/KartStopDelay: 240]
if CpuData/CpuIdx > 3 [GameData/LifterStopDelay: 260 GameData/KartStopDelay: 260]
if CpuData/CpuIdx > 4 [GameData/LifterStopDelay: 280 GameData/KartStopDelay: 280]
if CpuData/CpuIdx > 5 [GameData/LifterStopDelay: 300 GameData/KartStopDelay: 300]
if CpuData/CpuIdx > 6 [GameData/LifterStopDelay: 320 GameData/KartStopDelay: 320]
if CpuData/CpuIdx > 7 [GameData/LifterStopDelay: 340 GameData/KartStopDelay: 340]

; Level loading & start game play
either exists? %curlevel.txt [
	GameData/Curlevel: read %curlevel.txt
][
	GameData/Curlevel: first GameData/Levels
]
LoadDfltImages
LoadLevel GameData/Curlevel
MakeGame
view/no-wait GameControl
view/options GameScr [actors: context [on-key: func [face event][CheckKeyboard face event/key]]]