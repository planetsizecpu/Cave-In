Red [Needs: 'View
	Title:   "Lander"
	Author:  "@planetsizecpu"
	File:    "lander.red"
] 


recycle/off
system/view/auto-sync?:  yes

; Game data & defaults object
GameData: context [
	GameRate: 0:00:00.004 
	Gravity: 1
	Antigravity: 1
	HorizontalStep: 1
	DeadAltitude: 60
	TerrainColor: 178.178.178.0
	Curlevel: 1
	WindowHcenter: 400
	WindowHlimitL: 1
	WindowHlimitR: 778
	
	; Make moon object
	MoonImg: load %moon.png
	Moon: make face! [type: 'panel size: MoonImg/size offset: 0x0 pane: copy [] draw: copy [] 
					  image: copy MoonImg extra: [] focus: true]
	MoonFace: Moon
	MoonFaceHalfSizeX: (MoonFace/size/x / 2) * -1
				  
	; Make lander object
	Lander: object [
		name: "Lander"
		facename: "LanderFace" 
		face: copy []
		size: to-pair 22x34 
		offset: to-pair 400x10 
		direction: 6
		rate: 0:0:00.1
		firing: 0
		lastdir: 0
		inertia: 0.0
		altitude: 0
		lives: 4
		gravity: true
		display: true
		dead: false
		image: load %ship.png
		images: copy []  
		append images load %fship1.png
		append images load %fship2.png
		append images load %fship3.png
		face: object! []
	]
	
	Base: object [
	name: "Base"
		facename: "BaseFace" 
		face: copy []
		size: to-pair 60x10
		offset: to-pair 231x473 
		direction: 6
		rate: 0:0:00.1
		firing: 0
		lastdir: 0
		inertia: 0.0
		altitude: 0
		lives: 4
		gravity: false
		display: true
		dead: false
		image: load %base.png
		images: copy []  
		face: object! []
	]
]

; Check game status
CheckStatus: function [][
	Ret: false
		
	; Check for player dead
	if GameData/Lander/dead [Message "No more lives" Ret: true ]


	return Ret
]

; Gravity affect for lander
LanderManagement: function [f [object!]] [
	OtherFace: CheckOverlaps f
	if none? OtherFace [
		GameData/Lander/face/image: Gamedata/Lander/image
		GameData/Lander/face/offset/y: add GameData/Lander/face/offset/y GameData/Gravity
	]
]

; Check keyboard for handling
CheckKeyboard: function [face key][
	switch key [
		left [GoLeft GameData/Moon]
		right [GoRight GameData/Moon]
		#" " [GoAction GameData/Lander/face]
	]
]

; Action effect for ship
GoAction: function [f [object!]][
	if f/offset/y < 1 [return 0]
	either f/extra/firing < 3 [f/extra/firing: add f/extra/firing 1][f/extra/firing: 1]
	switch f/extra/firing [
		1 [f/image: Gamedata/Lander/images/1]
		2 [f/image: Gamedata/Lander/images/2]
		3 [f/image: Gamedata/Lander/images/3]		
	]
	f/offset/y: subtract f/offset/y GameData/Antigravity
]

; Ship going left direction 
GoLeft: function [f [object!]][

	; if ship is at the window center move the scenary else move the ship
	either GameData/Lander/face/offset/x = GameData/WindowHcenter [
		either f/offset/x <= 0 [
			f/offset/x: f/offset/x + GameData/HorizontalStep
			info/text: copy to-string f/offset/x
		][
			GameData/Lander/face/offset/x: GameData/Lander/face/offset/x - GameData/HorizontalStep
		]
	][
		if GameData/Lander/face/offset/x > GameData/WindowHlimitL [
			GameData/Lander/face/offset/x: GameData/Lander/face/offset/x - GameData/HorizontalStep
		]
	]
]

; Ship going ight direction
GoRight: function [f [object!]][

	; if ship is at the window center move the scenary else move the ship
	either GameData/Lander/face/offset/x = GameData/WindowHcenter [	
		either f/offset/x >= GameData/MoonFaceHalfSizeX [
			f/offset/x: f/offset/x - GameData/HorizontalStep
			info/text: copy to-string f/offset/x
		][
			GameData/Lander/face/offset/x: GameData/Lander/face/offset/x + GameData/HorizontalStep
		]
	][
		if GameData/Lander/face/offset/x < GameData/WindowHlimitR [
			GameData/Lander/face/offset/x: GameData/Lander/face/offset/x + GameData/HorizontalStep
		]
	]
]

; Check if some face overlaps other face in the cave
CheckOverlaps: function [f [object!]][
	Ret: none
	foreach-face GameData/MoonFace [
		if face <> f [
			if overlap? face f [Ret: face] ;Break would help here
		]
	]
	return Ret
]

; Game screen layout
GameScr: layout [
	title "Moon Lander"
	size 800x750
	origin 0x0
	space 0x0
	
	; Info field is also used for event management!
	at 10x610 info: base 780x30 blue orange font [name: "Arial" size: 14 style: 'bold] focus 
	rate GameData/GameRate on-time [
		info/rate: none 
		if CheckStatus [alert "END OF GAME" quit] 
		info/rate: GameData/GameRate
	]
	below
]

; Moon setup
append GameScr/pane GameData/Moon

; Ship face definition
LanderFace: make face! [type: 'base size: GameData/Lander/size offset: GameData/Lander/offset image: copy GameData/Lander/image extra: GameData/Lander
						rate: GameData/Lander/rate actors: context [on-time: func [f e][LanderManagement f]]]
GameData/Lander/face: LanderFace
LanderFace/extra: GameData/Lander
append GameScr/pane LanderFace

; Base face definition
BaseFace: make face! [type: 'base size: GameData/Base/size offset: GameData/Base/offset image: copy GameData/Base/image extra: GameData/Base]
GameData/Base/face: BaseFace
BaseFace/extra: GameData/Base
append GameData/Moon/pane BaseFace



	
; Start game
view/options GameScr [actors: context [on-key: func [face event][CheckKeyboard face event/key]]]



