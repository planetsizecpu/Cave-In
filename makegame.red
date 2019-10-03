Red [
	Title:   "Cave-In"
	Author:  "@planetsizecpu"
	File:    "MakeGame.red"
]

;--------------------------------------------------------------------------------------------------
; Create game functions 
;--------------------------------------------------------------------------------------------------
MakeGame: does [

	;-------------------------------------------------------------------------
	; Main functions
	;-------------------------------------------------------------------------	
	
	; Checks for game status
	CheckStatus: function [][
		Ret: false
		
		; Check for thief dead & get-up
		if GameData/PlayerFace/extra/dead [if GoDead GameData/PlayerFace [ Message "No more lives" Ret: true ]]
		if GameData/PlayerFace/extra/getup [GoGetup GameData/PlayerFace]

		; Apply gravity to faces
		GoGravity
		
		; Check for screen roll
		either GameData/PlayerFace/offset/x > GameData/CaveFaceHalfSizeX [
			cave/offset/x: GameData/CaveFaceRollOffsetX
		][
			cave/offset/x: 0 
		]
		
		; Check for demo mode
		if GameData/DemoMode [PlayDemoMode]
		
		; Check for thief tools timing
		if GameData/PlayerFace/extra/tool [
			GameData/PlayerFace/extra/getobject/extra/usedtool: add GameData/PlayerFace/extra/getobject/extra/usedtool GameData/GameRate
			if GameData/PlayerFace/extra/getobject/extra/usedtool > GameData/PlayerFace/extra/getobject/extra/timetool  [
				prin "END OF USE TOOL "
				print GameData/PlayerFace/extra/getobject/extra/name
				Message "Tool timeout"
				; Set tool invisible
				GameData/PlayerFace/extra/getobject/visible?: false
				GameData/PlayerFace/extra/getobject/offset: -50x-50	
				GameData/PlayerFace/extra/getobject/extra/gravity: false
				; Thief to leave tool
				GameData/PlayerFace/extra/tool: false
				GameData/PlayerFace/extra/getobject: copy []
				GameData/PlayerFace/image: GameData/PlayerFace/extra/image
			]
		]
		
		; Check for level goals
		if GameData/Goldbags >= GameData/Stock [
			print "***************************************************"
			prin  "ENDING LEVEL " print GameData/Curlevel
			print "***************************************************"
			print
			EraseLevel GameData/CaveFace
			
			GameData/Levels: next find GameData/Levels GameData/Curlevel
			GameData/Curlevel: first GameData/Levels
			GameData/Stock: 0
			GameData/Goldbags: 0
			
			either none? GameData/Curlevel [
				print "***************************************************"		
				print " NO MORE LEVELS! " 
				print "***************************************************"		
				Message "Congratulations you win"
				alert "CONGRATULATIONS YOU WIN"
				quit
			][
				print "***************************************************"		
				prin  "LOADING LEVEL " print GameData/Curlevel
				print "***************************************************"			
				Message "Loading new level"
				LoadLevel first GameData/Levels
				john/lives: add john/lives 1 ;One extra life for level ending
				Glives/text: copy "LIVES:  " 
				append Glives/text to-string john/lives
				Message "You awarded one extra life"
			]
		]
		
		Return Ret
	]
	
	; Check keyboard for handling
	CheckKeyboard: function [face key][
		switch key [
			left [GoLeft GameData/PlayerFace]
			right [GoRight GameData/PlayerFace]
			up [GoUp GameData/PlayerFace]
			down [GoDown GameData/PlayerFace]
			#" " [GoAction GameData/PlayerFace]
			#"#" [GameData/Stock: 1 Gstock/text: copy "STOCK: "	append Gstock/text to-string GameData/Stock message "Oh my god!"] ;Cheat! 
			#"%" [AskLevel] ;Cheat!
			#"@" [SetDemoMode]
		]
	]
	
	; Message to player
	Message: function [s [string!]][
		info/text: copy s 
	]
	
	; Set demo mode 
	SetDemoMode: function [][
		either GameData/DemoMode [
			GameData/DemoMode: false 
			john/lives: 3
			Glives/text: copy "LIVES:  " 
			append Glives/text to-string john/lives
			message "DEMO MODE OFF"
		][
			GameData/DemoMode: true 
			john/lives: 99 
			Glives/text: copy "LIVES:  " 
			append Glives/text to-string john/lives
			message "DEMO MODE ON"
		]
	]
	
	; Play demo mode
	PlayDemoMode: has [][
		drn: 3 seq: third now/time
		if seq > 14 [drn: 9]
		if seq > 29 [drn: 3]
		if seq > 44 [drn: 9]
		switch drn [
			9  [GoLeft GameData/PlayerFace]
			3  [GoRight GameData/PlayerFace]
			12 [GoUp GameData/PlayerFace]
			6  [GoDown GameData/PlayerFace]
		]
	]
	
	; Ask for new level
	AskLevel: has [][
		info/rate: none
		EraseLevel GameData/CaveFace 
		GameData/Stock: 0 
		GameData/Goldbags: 0 
		OldLevel: GameData/Curlevel
		either not none? rd: request-dir [
			rs: split to-string rd "/"
			alter rs ""
			alter rs ""
			GameData/Curlevel: last rs
			LoadLevel GameData/Curlevel 
			info/rate: GameData/GameRate]
		[
			GameData/Curlevel: OldLevel
			LoadLevel GameData/Curlevel 
			info/rate: GameData/GameRate
		]
	]
	
	; Erase level data
	EraseLevel: function [f [object!]][
		foreach x GameData/Items [unset (to-word x)]
		GameData/Items: copy []
		foreach-face f [
			face/rate: none
		]
		f/pane: copy []
		unset 'f
	]
	
	; Set agents difficulty level rate 
	SetAgentsRate: function [r [time!]][
		foreach-face GameData/CaveFace [
			; Check if face is visible 
			if face/visible? [
				; If there is an agent or a spider, then apply difficulty level rate
				if any [face/extra/type = "A" face/extra/type = "S"] [
					face/rate: r
				]
			]
		]
	]
	
	;-------------------------------------------------------------------------
	; Miscellaneous checking functions
	;-------------------------------------------------------------------------	
	
	; Check if some face overlaps other face in the cave
	CheckOverlaps: function [f [object!]][
		Ret: none
		foreach-face GameData/CaveFace [
			if face <> f [
				if overlap? face f [Ret: face] ;Break would help here
			]
		]
		return Ret
	]

	; Check if it is terrain at left from some face
	CheckTerrainLT: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
		CheckPointU: (((FOffset/y + 3) * GameData/CaveFace/size/x) + FOffset/x ) - 2
		CheckPointC: (((FOffset/y + (FSize/y / 2)) * GameData/CaveFace/size/x) + FOffset/x ) - 5		
		CheckPointD: (((FOffset/y + (FSize/y - 3 )) * GameData/CaveFace/size/x) + FOffset/x ) - 2
		TerrainU: GameData/CaveFace/image/(CheckPointU)
		TerrainC: GameData/CaveFace/image/(CheckPointC)		
		TerrainD: GameData/CaveFace/image/(CheckPointD)
		if any [TerrainU = GameData/TerrainColor TerrainC = GameData/TerrainColor TerrainD = GameData/TerrainColor] [Ret: true]
		return Ret
	]

	; Check if it is terrain at right from some face
	CheckTerrainRT: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
		CheckPointU: (((FOffset/y + 3) * GameData/CaveFace/size/x) + FOffset/x + Fsize/x ) + 2
		CheckPointC: (((FOffset/y + (FSize/y / 2)) * GameData/CaveFace/size/x) + FOffset/x + Fsize/x ) + 5				
		CheckPointD: (((FOffset/y + (FSize/y - 3 )) * GameData/CaveFace/size/x) + FOffset/x + Fsize/x ) + 2		
		TerrainU: GameData/CaveFace/image/(CheckPointU)
		TerrainC: GameData/CaveFace/image/(CheckPointC)		
		TerrainD: GameData/CaveFace/image/(CheckPointD)
		if any [TerrainU = GameData/TerrainColor TerrainC = GameData/TerrainColor TerrainD = GameData/TerrainColor] [Ret: true]		
		return Ret
	]
	
	; Check if it is a climbing slope at left from some face
	CheckSlopeLT: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
		CheckPoint: (((FOffset/y + (FSize/y)) * GameData/CaveFace/size/x) + FOffset/x ) - 8
		Terrain: GameData/CaveFace/image/(CheckPoint)
		if any [Terrain = GameData/TerrainColor Terrain = GameData/StairsColor1 Terrain = GameData/StairsColor2] [Ret: true]
		return Ret
	]

	; Check if it is a climbing slope at right from some face
	CheckSlopeRT: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
		CheckPoint: (((FOffset/y + (FSize/y)) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x + 8
		Terrain: GameData/CaveFace/image/(CheckPoint)
		if any [Terrain = GameData/TerrainColor Terrain = GameData/StairsColor1 Terrain = GameData/StairsColor2] [Ret: true]
		return Ret
	]
	
	; Check if it is ceiling over some face
	CheckCeiling: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
		CheckPointL: (((FOffset/y - GameData/CeilingDist) * GameData/CaveFace/size/x) + FOffset/x )
		CheckPointR: (((FOffset/y - GameData/CeilingDist) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x		
		TerrainL: GameData/CaveFace/image/(CheckPointL)
		TerrainR: GameData/CaveFace/image/(CheckPointR)	
		if any [TerrainL = GameData/TerrainColor TerrainR = GameData/TerrainColor] [Ret: true]
		return Ret
	]	

	; Check if it is floor under some face
	CheckFloor: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
		CheckPointL: (((FOffset/y + FSize/y + 1) * GameData/CaveFace/size/x) + FOffset/x )
		CheckPointR: (((FOffset/y + FSize/y + 1) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x
		TerrainL: GameData/CaveFace/image/(CheckPointL)
		TerrainR: GameData/CaveFace/image/(CheckPointR)	
		if any [TerrainL = GameData/TerrainColor TerrainR = GameData/TerrainColor] [Ret: true]
		return Ret
	]

	; Check if it is stairs over some face
	CheckStairsUP: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
	
		; Compute points to check over the face using coordinates on cave image
		CheckPointOL: (((FOffset/y - 1) * GameData/CaveFace/size/x) + FOffset/x )
		CheckPointOR: (((FOffset/y - 1) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x
	
		; Get terrain color
		TerrainOL: GameData/CaveFace/image/(CheckPointOL)
		TerrainOR: GameData/CaveFace/image/(CheckPointOR)
		; prin TerrainOL prin " - " print TerrainOR
	
		; Check stairs over the face 
		if ((TerrainOL = GameData/StairsColor1) or (TerrainOL = GameData/StairsColor2)) and
				((TerrainOR = GameData/StairsColor1) or (TerrainOR = GameData/StairsColor2)) [Ret: true]
	
		return Ret
	]
	
	; Check if it is stairs under some face
	CheckStairsDN: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
	
		; Compute points to check under the face using coordinates on cave image
		CheckPointUL: (((FOffset/y + FSize/y + 2) * GameData/CaveFace/size/x) + FOffset/x )
		CheckPointUR: (((FOffset/y + FSize/y + 2) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x
	
		; Get terrain color
		TerrainUL: GameData/CaveFace/image/(CheckPointUL)
		TerrainUR: GameData/CaveFace/image/(CheckPointUR)	
		; prin TerrainUL prin " - " print TerrainUR

		; Check stairs under the face
		if ((TerrainUL = GameData/StairsColor1) or (TerrainUL = GameData/StairsColor2)) and
				((TerrainUR = GameData/StairsColor1) or (TerrainUR = GameData/StairsColor2)) [Ret: true]
	
		return Ret
	]
			
	; Check if it is handle over some face
	CheckHandle: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset
		c: 0
		
		; Compute points to check over the face using coordinates on cave image
		while [c < 45] [
			CheckPointY: (((FOffset/y - c) * GameData/CaveFace/size/x) + FOffset/x + (FSize/x / 2))
			TerrainY: GameData/CaveFace/image/(CheckPointY)
			if (TerrainY = GameData/HandleColor) [Ret: true]		
			c: add c 1
			
		]
		
		return Ret
	]
	
	
	; Look to left of face coordinates for stairs or lifter (function for further use)
	LookForStairLT: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset

		; Loop to left from face until external wall
		CheckPointY: (FOffset/y + FSize/y) * GameData/CaveFace/size/x
		CheckPointX: FOffset/x
		while [CheckPointX > 14][
			CheckPointX: subtract CheckPointX 1
			CheckPoint: (CheckPointY + CheckPointX )
			Terrain: GameData/CaveFace/image/(CheckPoint)
			if Terrain = GameData/TerrainColor [
				print "LEFT-LOOK FOUND TERRAIN"
				break
			] 
			if  any [Terrain = GameData/StairsColor1 Terrain = GameData/StairsColor2 Terrain = GameData/LifterCable] [
				print "LEFT-LOOK FOUND STAIR OR LIFTER"
				Ret: true
				break
			]
		]
		return Ret
	]

	; Look to right of face coordinates for stairs or lifter (function for further use)
	LookForStairRT: function [face [object!]][
		Ret: false
		FSize: face/size
		FOffset: face/offset

		; Loop to right from face until external wall
		CheckPointY: (FOffset/y + FSize/y) * GameData/CaveFace/size/x
		CheckPointX: FOffset/x
		while [CheckPointX < (GameData/CaveFace/size/x - 14)][
			CheckPointX: add CheckPointX 1
			CheckPoint: (CheckPointY + CheckPointX )
			Terrain: GameData/CaveFace/image/(CheckPoint)
			if Terrain = GameData/TerrainColor [
				print "RIGHT-LOOK FOUND TERRAIN"
				break
			] 
			if any [Terrain = GameData/StairsColor1 Terrain = GameData/StairsColor2 Terrain = GameData/LifterCable] [
				print "RIGHT-LOOK FOUND STAIR OR LIFTER"
				Ret: true
				break
			]
		]
		return Ret
	]


	;-------------------------------------------------------------------------
	; Movement & effects functions
	;-------------------------------------------------------------------------	
	
	; Getup effects 
	GoGetup: function [f [object!]][
		if f/extra/type = "A" [
			either ((first f/extra/name) = #"f") [
				foreach img GameData/FAgentGetup [f/image: get img]			
				f/image: FAgentGetup-X2		
			][
				foreach img GameData/AgentGetup [f/image: get img]
				f/image: AgentGetup-X2		
			]
			f/extra/getup: false
			f/extra/altitude: 0  ;Agents are strong, not to die on falls
		]
		if f/extra/type = "J" [
			foreach img GameData/ThiefGetup [f/image: get img]
			f/extra/getup: false
			f/image: ThiefGetup-X2
		]
	]

	; Dead effects, return true if no more lives
	GoDead: function [f [object!]][
		Ret: false
		f/size: f/extra/size
		prin f/extra/name print " IS DEAD"
		
		; Check the lives of agents to stop births
		if f/extra/type = "A" [
			Message "An agent is dead"
			either f/extra/lives > 0 [f/extra/lives: subtract f/extra/lives 1][f/rate: none return true]
			;Show female/male agents dead image cycle
			either ((first f/extra/name) = #"f") [
				foreach img GameData/FAgentDead [f/image: get img wait GameData/AgentDeadDelay]		
			][
				foreach img GameData/AgentDead [f/image: get img wait GameData/AgentDeadDelay]		
			]
		]

		; Check the lives of thief to stop game
		if f/extra/type = "J" [
			Message "You dead"
			either f/extra/lives > 0 [f/extra/lives: subtract f/extra/lives 1][return true]
			;If thief is dead on air wait for hit the ground
			while [(not CheckFloor f) and (not CheckOverlaps f)] [GoGravity wait 0.01]
			foreach img GameData/ThiefDead [f/image: get img wait GameData/ThiefDeadDelay]		
		]		
		
		; Check the lives of spiders to stop births
		if f/extra/type = "S" [
			Message "A spider is dead"
			either f/extra/lives > 0 [f/extra/lives: subtract f/extra/lives 1][f/rate: none return true]
			foreach img GameData/SpiderDead [f/image: get img wait GameData/SpiderDeadDelay]		
		]		
		
		; Check the lives of drops to stop births
		if f/extra/type = "D" [
			either f/extra/lives > 0 [f/extra/lives: subtract f/extra/lives 1][f/rate: none f/visible?: false return true]
			foreach img GameData/DropDead [f/image: get img]	;Drops can't have stop delay
		]				
		
		; If it is some object on hands leave them at place and make it visible
		if any [f/extra/gold f/extra/tool f/extra/wbarrow] [
			f/extra/getobject/offset: f/offset
			f/extra/getobject/extra/gravity: true
			f/extra/getobject/visible?: true
		]
		
		; Set defaults for face
		f/extra/walking: 0
		f/extra/altitude: 0
		f/extra/gravity: true
		f/extra/getup: false
		f/extra/dead: false
		f/extra/getup: false
		f/extra/wound: false
		f/extra/onkart: false
		f/extra/wbarrow: false
		f/extra/tool: false
		f/extra/gold: false
		f/extra/handle: false
		f/extra/loaded: false	
		f/extra/getobject: copy []
		either f/extra/lives > 0 [
			prin f/extra/name print " HAS ONE MORE LIVE"
		][
			f/extra/dead: true 
			prin f/extra/name print " HAS NO MORE LIVES"
			Ret: true
		]
		; Set face at his starting point
		f/offset: f/extra/offset
		f/image: f/extra/image
		
		Glives/text: copy "LIVES:  " 
		append Glives/text to-string GameData/PlayerFace/extra/lives
		
		return Ret
	]
	
	; Gravity, inertia, passage, & difficulty effects for objects affected by
	GoGravity: function [][
		foreach-face GameData/CaveFace [
			
			; If object has gravity apply them when no floor no stairs and no lifter under the face
			if all [face/visible? face/extra/gravity] [

				; Check for overlaps when falling
				OtherFace: CheckOverlaps face
				if not none? OtherFace [
				
					; Check for lifter surface for stop fall of persons
					if OtherFace/extra/type = "L" [
						if any [face/extra/type = "A" face/extra/type = "J"] [
							; If have barrow, then can't take lifter
							if not face/extra/wbarrow [
								; Counteract the gravity effect
								face/extra/altitude: 0 
								face/offset/y: subtract face/offset/y GameData/Antigravity
							]
						]
					]
					
					; Check for something hit on agent or spider to knock it out
					if any [OtherFace/extra/type = "A" OtherFace/extra/type = "S"] [
						if any [face/extra/type = "G" face/extra/type = "T" face/extra/type = "W" face/extra/type = "D"] [
							if face/extra/altitude > GameData/KnockAltitude [
								OtherFace/extra/dead: true
							]
						]
					]
					
					; Check for drop hit on thief to knock it out
					if OtherFace/extra/type = "J" [
						if face/extra/type = "D" [
							if face/extra/altitude > GameData/KnockAltitude [
								OtherFace/extra/dead: true
							]
						]					
					]
					
					; Check for passage travel
					if OtherFace/extra/type = "P" [
						PassageMotion face OtherFace
					]
					
					; Check for gold hit on barrow so we carry
					if OtherFace/extra/type = "W" [
						if face/extra/type = "G" [
							prin "CARRY GOLD " 
							prin face/extra/name 
							prin " ON " 
							print OtherFace/extra/name
							Message "Load gold"
					
							; We use direction to set loaded barrow image
							either OtherFace/extra/direction < 0 [OtherFace/image: Wbarrow-LG1][OtherFace/image: Wbarrow-RG1]				
							OtherFace/extra/goldbags: add OtherFace/extra/goldbags 1
							GameData/Goldbags: OtherFace/extra/goldbags
				
							prin "WHEELBARROW " prin OtherFace/extra/name 
							prin " NOW HAS " prin OtherFace/extra/goldbags
							print " GOLD BAGS"
							Ggbags/text: copy "CARRY: "
							append Ggbags/text to-string GameData/Goldbags
				
							face/enabled?: false
							face/visible?: false
							face/extra/gravity: false
							face/offset: -25x-25
						]
					]
				]	
				
				; If no floor and no stairs then face fall down
				either all [(not CheckFloor face) (not CheckStairsDN face)] [
					; Drops may have different gravity (lava)
					either face/extra/type = "D" [
						face/offset/y: add face/offset/y GameData/DropGravity
					][
						face/offset/y: add face/offset/y GameData/Gravity
					]
					face/extra/altitude: add face/extra/altitude 1
					face/extra/blockedLT: false
					face/extra/blockedRT: false
					
					; Check for gravity effects
					if face/extra/type = "A" [
						if face/extra/altitude > GameData/FallingFaceAltitude [
							either (first face/extra/name) = #"f" [
								face/image: FAgent-S4
							][						
								face/image: Agent-S4
							]
						]
						if face/extra/altitude > GameData/GetupAltitude [face/extra/getup: true] ; Agents can not die by fall or game is not playable
					]
					if face/extra/type = "J" [
						if face/extra/altitude > GameData/FallingFaceAltitude [face/image: Thief-S4]
						if face/extra/altitude > GameData/GetupAltitude [face/extra/getup: true]
						if face/extra/altitude > GameData/DeadAltitude [face/extra/dead: true]
					]					
				][
					; Zero altitude over terrain, if not persons may die on floor!
					face/extra/altitude: 0

					; Add inertia when apply
					if (GameData/Slide) [
						if (face/extra/type = "J") [
							if face/extra/lastdir < 0 [
								if (not CheckTerrainLT face) and (not CheckSlopeLT face) [
									face/offset/x: subtract face/offset/x to-integer face/extra/inertia
								]
							]
							if face/extra/lastdir > 0 [
								if (not CheckTerrainRT face) and (not CheckSlopeRT face) [
									face/offset/x: add face/offset/x to-integer face/extra/inertia
								]
							]
							if face/extra/inertia > 0 [face/extra/inertia: subtract face/extra/inertia GameData/AddInertia]
						]
					]
					
					; If it is a drop now on floor then kill it
					if face/extra/type = "D" [
						face/extra/dead: true
						GoDead face
					]
				]
			]
		]
	]
	
	; Some face going left
	GoLeft: function [f [object!]][
		if f/extra/handle [return 0]
		if f/extra/type = "J" [f/extra/direction: -1]
		if CheckTerrainLT f [return 0]
		if CheckSlopeLT f [f/offset/y: f/offset/y - 1]

		x: f/offset/x
		x: subtract x GameData/StepValue
		f/offset/x: x 		
		GoWalkFloor f 1

		; Accumulate inertia when apply
		if (GameData/Slide) [
			if (f/extra/type = "J") [
				if f/extra/lastdir > 0 [f/extra/inertia: 0.0]
				f/extra/lastdir: -1
				if f/extra/inertia < GameData/MaxInertia [f/extra/inertia: add f/extra/inertia GameData/Inertia]
			]			
		]		
	]

	; Some face going right
	GoRight: function [f [object!]][
		if f/extra/handle [return 0]
		if f/extra/type = "J" [f/extra/direction: 1]
		if CheckTerrainRT f [return 0]
		if CheckSlopeRT f [f/offset/y: f/offset/y - 1]

		x: f/offset/x
		x: add x GameData/StepValue
		f/offset/x: x		
		GoWalkFloor f 0
		
		; Accumulate inertia when apply
		if (GameData/Slide) [
			if (f/extra/type = "J") [
				if f/extra/lastdir < 0 [f/extra/inertia: 0.0]
				f/extra/lastdir: 1				
				if f/extra/inertia < GameData/MaxInertia [f/extra/inertia: add f/extra/inertia GameData/Inertia]
			]			
		]
	]

	; Some face going up
	GoUp: function [f [object!]][
		if f/extra/handle [return 0]
		if CheckCeiling f [return 0]	
		if all [(not CheckStairsUP f) (not CheckStairsDN f)] [return 0]

		y: f/offset/y
		y: subtract y GameData/StepValue
		if f/extra/type = "A" [y: subtract y GameData/StepValue] ;Agents need extra speed on stairs
		f/offset/y: y

		GoWalkStairs f
	]

	; Some face going down
	GoDown: function [f [object!]][
		if f/extra/handle [return 0]			
		if CheckFloor f [return 0]	

		y: f/offset/y
		y: add y GameData/StepValue
		if f/extra/type = "A" [y: add y GameData/StepValue] ;Agents need extra speed on stairs
		f/offset/y: y

		GoWalkStairs f 
	]

	; Some face walking on stairs
	GoWalkStairs: function [f [object!]][
		f/extra/blockedLT: false
		f/extra/blockedRT: false
		; Change image when moving
		f/extra/walking: add f/extra/walking 1
		if f/extra/walking > 4 [f/extra/walking: 1]
		switch f/extra/walking [
			1 [f/image: f/extra/images/7]
			2 [f/image: f/extra/images/8]
			3 [f/image: f/extra/images/9]
			4 [f/image: f/extra/images/8]
		]
	]
	
	; Some face walking on floor
	GoWalkFloor: function [f [object!] dir [integer!]][
		
		; Check if face has something loaded on hands 
		OnHands: " "
		if f/extra/gold [OnHands: "G"]
		if f/extra/tool [OnHands: "T"]
		if f/extra/wbarrow [OnHands: "W"]
		
		
		; Set proper image regarding direction
		f/extra/walking: add f/extra/walking 1
		if f/extra/walking > 4 [f/extra/walking: 1]
		switch OnHands [
			" " [switch f/extra/walking [
					; This code works for loaded thief & agents
					1 [either dir = 1 [f/image: f/extra/images/1][f/image: f/extra/images/2]]
					2 [either dir = 1 [f/image: f/extra/images/3][f/image: f/extra/images/4]]
					3 [either dir = 1 [f/image: f/extra/images/5][f/image: f/extra/images/6]]
					4 [either dir = 1 [f/image: f/extra/images/3][f/image: f/extra/images/4]]
				]			
			]
			"G" [switch f/extra/walking [
					1 [either dir = 1 [f/image: f/extra/images/11][f/image: f/extra/images/12]]
					2 [either dir = 1 [f/image: f/extra/images/13][f/image: f/extra/images/14]]
					3 [either dir = 1 [f/image: f/extra/images/15][f/image: f/extra/images/16]]
					4 [either dir = 1 [f/image: f/extra/images/13][f/image: f/extra/images/14]]
				]			
			]			
			"T" [switch f/extra/walking [
					1 [either dir = 1 [f/image: ThiefTool-L1][f/image: ThiefTool-R1]]
					2 [either dir = 1 [f/image: ThiefTool-L2][f/image: ThiefTool-R2]]
					3 [either dir = 1 [f/image: ThiefTool-L3][f/image: ThiefTool-R3]]
					4 [either dir = 1 [f/image: ThiefTool-L2][f/image: ThiefTool-R2]]
				]			
			]						
			"W" [either f/extra/getobject/extra/goldbags > 0[
					switch f/extra/walking [
						1 [either dir = 1 [f/image: ThiefWGba-L1][f/image: ThiefWGba-R1]]
						2 [either dir = 1 [f/image: ThiefWGba-L2][f/image: ThiefWGba-R2]]
						3 [either dir = 1 [f/image: ThiefWGba-L3][f/image: ThiefWGba-R3]]
						4 [either dir = 1 [f/image: ThiefWGba-L2][f/image: ThiefWGba-R2]]
					]
				][
					switch f/extra/walking [
						1 [either dir = 1 [f/image: ThiefWba-L1][f/image: ThiefWba-R1]]
						2 [either dir = 1 [f/image: ThiefWba-L2][f/image: ThiefWba-R2]]
						3 [either dir = 1 [f/image: ThiefWba-L3][f/image: ThiefWba-R3]]
						4 [either dir = 1 [f/image: ThiefWba-L2][f/image: ThiefWba-R2]]					
					]
				]			
			]									
		]
	]

	;-------------------------------------------------------------------------
	; Thief actions
	;-------------------------------------------------------------------------
	
	; Thief interaction some object
	GoAction: function [f [object!]][


		; Check if it is overlap
		OtherFace: CheckOverlaps f 
	
		; Check if we leave gold
		if all [f/extra/gold (not CheckStairsDN f) (not CheckTerrainLT f) (not CheckTerrainRT f) (not CheckHandle f)] [
			either (none? OtherFace) [
				OtherFace: f/extra/getobject		
				; We use direction to leave gold 
				either f/extra/direction < 0 [
					OtherFace/offset/x: f/offset/x + 22
					OtherFace/offset/y: f/offset/y
				][
					OtherFace/offset/x: f/offset/x - OtherFace/size/x
					OtherFace/offset/y: f/offset/y				
				]
				OtherFace/visible?: true
				OtherFace/extra/gravity: true
				f/extra/gold: false
				f/extra/getobject: copy []
				f/image: Thief-S4
				prin "LEAVE GOLD " print OtherFace/extra/name
				Message "Leave gold"
				OtherFace: none
				
			][
				; if we leave gold and there is a barrow we are carrying gold
				either OtherFace/extra/type = "W" [
					prin "CARRY GOLD " 
					prin f/extra/getobject/extra/name 
					prin " ON " 
					print OtherFace/extra/name
					Message "Load gold"
					
					; We use direction to set loaded barrow image
					either f/extra/direction < 0 [OtherFace/image: Wbarrow-LG1][OtherFace/image: Wbarrow-RG1]

					; Account gold
					OtherFace/extra/goldbags: add OtherFace/extra/goldbags 1
					GameData/Goldbags: add GameData/Goldbags 1
				
					prin "WHEELBARROW " prin OtherFace/extra/name 
					prin " NOW HAS " prin OtherFace/extra/goldbags
					print " GOLD BAGS"
					Ggbags/text: copy "CARRY: "
					append Ggbags/text to-string GameData/Goldbags
				
					f/extra/getobject/enabled?: false
					f/extra/getobject/visible?: false
					f/extra/getobject/extra/gravity: false
					f/extra/getobject/extra/offset: -25x-25
					f/extra/getobject: copy []
					f/extra/gold: false
					f/size: Thief-S4/size
					f/image: Thief-S4					
					return 0
				][
					; Leave gold on lifter
					OtherFace: f/extra/getobject		
					; We use direction to leave gold 
					either f/extra/direction < 0 [
						OtherFace/offset/x: f/offset/x + 22
						OtherFace/offset/y: f/offset/y
					][
						OtherFace/offset/x: f/offset/x - OtherFace/size/x
						OtherFace/offset/y: f/offset/y				
					]
					OtherFace/visible?: true
					OtherFace/extra/gravity: true
					f/extra/gold: false
					f/extra/getobject: copy []
					f/image: Thief-S4
					prin "LEAVE GOLD ON LIFTER " print OtherFace/extra/name
					Message "Leave gold"
					OtherFace: none
				]
			]
		]			
		
		; Check if we leave tool
		if all [f/extra/tool (not CheckStairsDN f) (not CheckTerrainLT f) (not CheckTerrainRT f) (not CheckHandle f) (none? OtherFace)] [
			OtherFace: f/extra/getobject
			; We use direction to leave tool
			either f/extra/direction < 0 [
				OtherFace/offset/x: f/offset/x - OtherFace/size/x
				OtherFace/offset/y: f/offset/y
			][
				OtherFace/offset/x: f/offset/x + 22
				OtherFace/offset/y: f/offset/y				
			]
			OtherFace/visible?: true
			OtherFace/extra/gravity: true
			f/extra/tool: false
			f/extra/getobject: copy []
			f/image: Thief-S4
			prin "LEAVE TOOL " print OtherFace/extra/name
			Message "Leave tool"
			OtherFace: none
		]
		
		; Check if we leave barrow
		if all [f/extra/wbarrow (none? OtherFace)] [
			OtherFace: f/extra/getobject
			OtherFace/offset/x: f/offset/x + 5
			OtherFace/offset/y: f/offset/y + (f/size/y - OtherFace/size/y) 
			OtherFace/visible?: true
			OtherFace/extra/gravity: true
			f/extra/wbarrow: false
			f/extra/getobject: copy []
			f/size: Thief-S4/size
			f/image: Thief-S4
			prin "LEAVE WHEELBARROW " print OtherFace/extra/name
			Message "Leave wheelbarrow"
			OtherFace: none
		]					
		
		
		; Check if face has handle, and left them
		either f/extra/handle [
			f/extra/handle: false
			f/extra/gravity: true
			f/extra/inertia: 0.0
			f/extra/altitude: 0
			f/offset/y: add f/offset/y 8
			f/size: f/extra/size
			f/image: f/extra/images/7		
			print "LEAVE HANDLE"
			Message "Leave handle"
			
			; Check if we take the kart
			if not none? OtherFace [
				if OtherFace/extra/type = "K" [
					KartJumpIn OtherFace f
					return 0
				]
			]
		][
			; Check if face is under handle and got them
			if (CheckHandle f) [ 
				if not f/extra/wbarrow [
					f/visible?: true
					f/extra/gravity: false
					f/extra/handle: true
					f/offset/y: subtract f/offset/y 8
						
					if f/extra/gold [
						f/size: ThiefHandleb/size
						f/image: ThiefHandleb
					]
					if f/extra/tool [
						f/size: ThiefHandlet/size
						f/image: ThiefHandlet
					]
					if (not f/extra/gold) and (not f/extra/tool) [
						f/size: ThiefHandle/size
						f/image: ThiefHandle
					]
					print "GOT HANDLE"	
					Message "Got handle"
				]
				
				; Check if we left the kart
				if not none? OtherFace [
					if OtherFace/extra/type = "K" [
						KartJumpOut OtherFace f
						return 0
					]
				]
			]
		]
		
		; Check overlap on other face and get it if main face don't have anything in hands
		if (not none? OtherFace) [
			;if (not f/extra/handle) and (not f/extra/tool) and (not f/extra/gold) and (not f/extra/wbarrow) [
			if all [(not f/extra/handle) (not f/extra/tool) (not f/extra/gold) (not f/extra/wbarrow)] [
				switch OtherFace/extra/type [
					none	[]
					"G"	[prin "GOT GOLD " print OtherFace/extra/name
						Message "Got gold"
						f/extra/gold: true
						f/extra/getobject: OtherFace
						f/image: ThiefBag
						OtherFace/visible?: false
						OtherFace/offset: -25x-25
						OtherFace/extra/gravity: false
					]					
					"T"	[prin "GOT TOOL " print OtherFace/extra/name
						Message "Got tool"
						f/extra/tool: true
						f/extra/getobject: OtherFace
						f/image: ThiefTool
						OtherFace/visible?: false
						OtherFace/offset: -50x-50
						OtherFace/extra/gravity: false
					]
					"W"	[prin "GOT WHEELBARROW " print OtherFace/extra/name
						Message "Got wheelbarrow"
						f/extra/wbarrow: true
						f/extra/getobject: OtherFace
						f/size: ThiefWba/size
						either OtherFace/extra/goldbags > 0 [f/image: ThiefWGba][f/image: ThiefWba]
						OtherFace/visible?: false
						OtherFace/offset: -75x-75
						OtherFace/extra/gravity: false
					]				
				]
			]
		]
	]
	
	;-------------------------------------------------------------------------
	; Karts motion & effects functions 
	;-------------------------------------------------------------------------
	KartMotion: function [f [object!]][
		/local fst: first f/extra/stops
		/local lst: last  f/extra/stops
		/local stp: 0
		
		; Check for kart overlap 
		OtherFace: CheckOverlaps f 
				
		; Check for run over thief face if not loaded
		if not f/extra/loaded [
			if not none? OtherFace [
				if OtherFace/extra/type = "J" [
					if not OtherFace/extra/handle [
						prin OtherFace/extra/name
						print " DEAD BY KART"
						Message "You dead by kart"
						GoDead OtherFace
						return 0
					]
				]
				if OtherFace/extra/type = "K" [
					OtherFace/extra/dead: true
					print " AGENT DEAD BY KART"
					Message "Agent dead by kart"
					return 0
				]
			]
		]
		
		; Check if kart is on stop delay
		either f/extra/stopdelay > 0 [
			f/extra/stopdelay: subtract f/extra/stopdelay 1
			return 0
		][
			; No on stop delay, overlapping face (hidden) must follow the kart when moving
			if f/extra/loaded [
				f/extra/getobject/offset: f/offset
			]
		]
		
		; We use direction on kart to allow easy displacement
		f/offset/x: add f/offset/x f/extra/direction
		if f/offset/x <= fst/x [f/extra/direction:  2]
		if f/offset/x >= lst/x [f/extra/direction: -2]

		; Check for kart stops and set next delay
		foreach stp f/extra/stops [if (stp/x = f/offset/x) or (stp/x = (f/offset/x - 1)) [
				f/extra/stopdelay: GameData/KartStopDelay
			]
		]
	]
	
	; Kart jump-in (from handle status)
	KartJumpIn: function [f [object!] OtherFace [object!]][
		OtherFace/extra/handle: false	 ;Clear jumping face handle status
		OtherFace/extra/blockedLT: false ;Clear locks
		OtherFace/extra/blockedRT: false ;Clear locks 
		OtherFace/offset: f/offset  	 ;The jumping face follows kart hidden
		OtherFace/visible?: false		 ;Make jumping face not visible
		OtherFace/extra/gravity: false   ;Gravity does not affect on kart
		OtherFace/extra/wound: false	 ;Clear wound status as kart have medkit
		OtherFace/extra/onkart: true     ;Signal jumping face as loaded on kart
		f/extra/loaded: true 			 ;Signal kart as loaded
		f/extra/getobject: OtherFace	 ;Save thief face as loaded on kart
		f/extra/altitude: 0 			 ;Don't use altitude on kart
		either f/extra/direction > 0 [f/image: Kart-TR1][f/image: Kart-TL1]	;Set loaded kart image
		print "ON KART"
	]
	
	; Kart jump-out (to handle status on GoAction function)
	KartJumpOut: function [f [object!] OtherFace [object!]][
		f/extra/loaded: false			;Signal kart as unloaded
		f/extra/getobject: copy []		;Erase thief face from kart
		f/extra/altitude: 0 			;Don't use altitude on kart
		f/image: f/extra/image 			;Set unloaded kart image 
		OtherFace/visible?: true		;Make jumping face visible
		OtherFace/extra/handle: true    ;Signal jumping face as on handle
		OtherFace/extra/onkart: false	;Signal jumping face as not loaded on kart
		OtherFace/offset/y: subtract OtherFace/offset/y 16 ;Vertical adjust as we leave the kart
		print "LEAVE KART"
	]

	;-------------------------------------------------------------------------
	; Lifters motion & effects functions
	;-------------------------------------------------------------------------
	LifterMotion: function [f [object!]][
		/local fst: first f/extra/stops
		/local lst: last  f/extra/stops
		/local stp: 0x0

		; Check for lifter overlap 
		OtherFace: CheckOverlaps f 
		
		; Check if lifter is on stop delay
		if f/extra/stopdelay > 0 [
			f/extra/stopdelay: subtract f/extra/stopdelay 1 
			return 0
		]

		; Check for altitude and force horizontal center other face to avoid walls 
		if not none? OtherFace [
			if any [OtherFace/extra/type = "J" OtherFace/extra/type = "A"] [
				; If have barrow, then can't take lifter
				if all [not OtherFace/extra/wbarrow not OtherFace/extra/onkart] [
					OtherFace/offset/x: f/offset/x + (f/size/x / 2) - 7
					OtherFace/offset/y: f/offset/y - 30
					if OtherFace/extra/altitude > GameData/DeadAltitude [GoDead OtherFace return 0]
				]
			]
		]
			
		; We use direction on lifter to allow easy displacement
		f/offset/y: add f/offset/y f/extra/direction
		if f/offset/y = fst/y [f/extra/direction:  1]
		if f/offset/y = lst/y [f/extra/direction: -1]
		
		; Check for lifter stops and set next delay
		foreach stp f/extra/stops [if stp/y = f/offset/y [
				f/extra/stopdelay: GameData/LifterStopDelay 
				if f/extra/timetool <> 0 [ f/extra/stopdelay: add f/extra/stopdelay to-integer f/extra/timetool]
			]
		]
	]

	;-------------------------------------------------------------------------
	; Agents motion & homing functions
	;-------------------------------------------------------------------------
	AgentMotion: function [f [object!]][		

		; Check for this agent getup & dead
		if f/extra/getup [GoGetup f]
		if f/extra/dead [GoDead f return 0]

		; Check for agent overlap  
		OtherFace: CheckOverlaps f 
		if not none? OtherFace [
			; Check if other face is agent and push them away if not on stairs (on lifter is unnecesary)
			if OtherFace/extra/type = "A" [
				if all [not CheckStairsDN f  not CheckStairsUP f] [
					; Push away first agent
					f/extra/blockedLT: false
					f/extra/blockedRT: false					
					f/offset/x: f/offset/x - f/size/x
					either any [CheckTerrainLT f CheckTerrainRT f] [
						f/offset: f/extra/offset ; Avoid agent buried on terrain by going home
					][
						f/extra/direction: 9 
						f/extra/blockedRT: true
						f/extra/blockedLT: false
					]
					; Push away second agent
					OtherFace/extra/blockedLT: false
					OtherFace/extra/blockedRT: false					
					OtherFace/offset/x: OtherFace/offset/x + OtherFace/size/x
					either any [CheckTerrainLT OtherFace CheckTerrainRT OtherFace] [
						OtherFace/offset: OtherFace/extra/offset ; Avoid agent buried on terrain by going home
					][					
						OtherFace/extra/direction: 3
						OtherFace/extra/blockedLT: true
						OtherFace/extra/blockedRT: false
					]
				]
			]
			if OtherFace/extra/type = "L" [ 
				either (GameData/PlayerFace/offset/x < (f/offset/x - 2)) [
					either not GameData/PlayerFace/extra/tool [f/extra/direction: 9][f/extra/direction: 3]
				][
					either not GameData/PlayerFace/extra/tool [f/extra/direction: 3][f/extra/direction: 9]
				]
			]
			
			; Check if other face is thief
			if OtherFace/extra/type = "J" [
				; Check if thief has tool or is on kart and kill thief if not
				either any [OtherFace/extra/tool OtherFace/extra/onkart] [
					; Set get-up status on the agent to disturb it
					print "JOHN HAS TOOL, NO FEAR."					
					f/extra/dead: true
					return 0
				][
					OtherFace/extra/dead: true
					return 0
				]
			]
		]

		; HOMING FUNCTION vary their behavior by the tool status! 
		; Negative direction means compute new direction (clock wise)
		; if there is a direction follow it while we can or find stairs
		if f/extra/direction > 0 [
			if f/extra/direction = 12 [
				GoUp f 
				if not CheckStairsUP f [f/extra/direction: -1]
			]	
			if f/extra/direction = 6 [
				GoDown f 
				if not CheckStairsDN f [f/extra/direction: -1]				
			]		
			if f/extra/direction = 9 [
				if any [f/extra/blockedLT CheckTerrainLT f] [f/extra/direction: -1]
				GoLeft f 
			]
			if f/extra/direction = 3 [
				if any [f/extra/blockedRT CheckTerrainRT f] [f/extra/direction: -1]			
				GoRight f
			]		
			; If we find stairs or thief have pickax we must check for new direction
			if any [CheckStairsUP f CheckStairsDN f GameData/PlayerFace/extra/tool] [f/extra/direction: -1]
			return 0
		]
				
		; Get best vertical direction first, as it need stairs to move it takes precedence
		if GameData/PlayerFace/offset/y < (f/offset/y - 2) [
			if any [CheckStairsUP f CheckStairsDN f] [
				either not CheckCeiling f [
					either not GameData/PlayerFace/extra/tool [f/extra/direction: 12][f/extra/direction: 6]
					return 0 ; For prevalence of vertical directions
				][
					f/extra/direction: -1
				]
			]
		]
		if (GameData/PlayerFace/offset/y > (f/offset/y + 2)) [
			if any [CheckStairsUP f CheckStairsDN f] [
				either not CheckFloor f [
					either not GameData/PlayerFace/extra/tool [f/extra/direction: 6][f/extra/direction: 12]
					return 0 ; For prevalence of vertical directions
				][
					f/extra/direction: -1				
				]
			]
		]

		; Agent is at the same /y level, so we get best horizontal direction
		either GameData/PlayerFace/offset/x < f/offset/x [
			either not CheckTerrainLT f [
				either not GameData/PlayerFace/extra/tool [f/extra/direction: 9][f/extra/direction: 3]
			][
				f/extra/blockedLT: true
				if (not CheckTerrainRT f) [
					f/extra/direction: 3
				]
			]
		][
			either not CheckTerrainRT f [
				either not GameData/PlayerFace/extra/tool [f/extra/direction: 3][f/extra/direction: 3]
			][
				f/extra/blockedRT: true
				if (not CheckTerrainLT f) [
					f/extra/direction: 9
				]
			]				
		]
	]
	
	;-------------------------------------------------------------------------
	; Spiders motion & homing functions
	;-------------------------------------------------------------------------
	SpiderMotion: function [f [object!]][		

		; Check for this spider getup & dead
		if f/extra/getup [GoGetup f]
		if f/extra/dead [GoDead f]

		; Check for spider overlap  
		OtherFace: CheckOverlaps f 
		if not none? OtherFace [
			; Check if other face is agent and guide them away
			if OtherFace/extra/type = "A" [
					OtherFace/extra/getup: true
					f/extra/dead: true
					return 0
			]
			
			; Check if other face is thief
			if OtherFace/extra/type = "J" [
				; Check if thief has tool or is on kart and kill thief if not
				either any [OtherFace/extra/tool OtherFace/extra/onkart] [
					; Set get-up status on the spider to disturb it
					print "JOHN HAS TOOL, NO FEAR."
					f/extra/dead: true
					return 0
				][
					either OtherFace/extra/wound [
						OtherFace/extra/dead: true
						f/extra/dead: true
					][
						OtherFace/extra/wound: true
						OtherFace/extra/getup: true
						f/extra/dead: true
						
					]
					return 0
				]
			]
		]
		
		; When spider must go LEFT
		if f/extra/altitude = 0 [
			if any [GameData/PlayerFace/offset/x < f/offset/x  f/extra/blockedRT] [
				either not CheckTerrainLT f [
					GoLeft f
					f/extra/blockedLT: false
				][	
					; Finally spider go right due to galery blocked				
					if CheckFloor f [f/extra/blockedLT: true]
					GoRight f
					f/extra/blockedRT: false				
				]
			]
		]
						
		; When spider must go RIGHT
		if f/extra/altitude = 0 [		
			if any [GameData/PlayerFace/offset/x > f/offset/x  f/extra/blockedLT] [
				either not CheckTerrainRT f [
					GoRight f
					f/extra/blockedRT: false
				][			
					; Finally spider go left due to galery blocked				
					if CheckFloor f [f/extra/blockedRT: true]				
					GoLeft f
					f/extra/blockedLT: false
				]
			]						
		]
	]
	
	;-------------------------------------------------------------------------
	; Water drop motion
	;-------------------------------------------------------------------------
	DropMotion: function [f [object!]][		

		; Check for this drop dead
		if f/extra/dead [GoDead f return 0]

		; Check for drop overlap  
		OtherFace: CheckOverlaps f 
		if not none? OtherFace [
			; Check if other face is agent and guide them away
			if OtherFace/extra/type = "A" [
					OtherFace/extra/getup: true
					f/extra/dead: true
					return 0
			]
			
			; Check if other face is thief
			if OtherFace/extra/type = "J" [
				either OtherFace/extra/wound [
					OtherFace/extra/dead: true
					f/extra/dead: true
				][
					OtherFace/extra/wound: true
					OtherFace/extra/getup: true
					f/extra/dead: true						
				]
				return 0
			]
		]
	]
	
	;-------------------------------------------------------------------------
	; Bands motion
	;-------------------------------------------------------------------------
	BandMotion: function [f [object!]][
		
		; Check for band overlap 
		OtherFace: CheckOverlaps f 
		Axis: first f/extra/stops ;First stop is rolling axis
		
		; Check for dead if touch the band
		if not none? OtherFace [
			if any [OtherFace/extra/type = "A" OtherFace/extra/type = "D" 
					OtherFace/extra/type = "J" OtherFace/extra/type = "S"] [
						prin OtherFace/extra/name
						print " DEAD BY BAND"
						GoDead OtherFace
						return 0
			]
		]
		
		; Band displacement depending of axis: 1x0 -> Horizontal, Other -> Vertical
		either Axis = 1x0 [	
			f/offset/x: add f/offset/x f/extra/direction
			
			either f/extra/direction > 0 [ 
				if (f/offset/x) >= 0 [f/offset/x: f/extra/offset/x]
			][
				if (absolute f/offset/x) > (f/image/size/x / 2) [f/offset/x: f/extra/offset/x]
			]
		][
			f/offset/y: add f/offset/y f/extra/direction
			either f/extra/direction > 0 [ 
				if (f/offset/y) >= 0 [f/offset/y: f/extra/offset/y]
			][
				if (absolute f/offset/y) > (f/image/size/y / 2) [f/offset/y: f/extra/offset/y]
			]
		]
	]	
	
	;-------------------------------------------------------------------------
	; Passage motion 
	;-------------------------------------------------------------------------
	PassageMotion: function [f [object!] sp [object!]][
	
		
		; Do nothing if start passage is loaded 
		if sp/extra/loaded [return 0]
		
		; Do nothing if face is not allowed to travel
		if all [f/extra/type <> "A" f/extra/type <> "J"] [return 0]
		
		; Init destination passage
		dp: copy []
		
		; Stop this pair passage timers & get destination passage face
		foreach-face GameData/CaveFace [
			if face/extra/type = "P" [
				; Pair grouping is on direction field
				if face/extra/direction = sp/extra/direction [
					face/rate: none
					if face <> sp [dp: face]
				]
			]
		]
		
		; Set passage pair indicators
		sp/image: Passage-R
		sp/extra/loaded: true
		dp/image: Passage-R
		dp/extra/loaded: true
			
		prin f/extra/name
		prin " IS ON PASSAGE "
		prin sp/extra/name
		prin " SO WE TRAVEL TO "
		print dp/extra/name
		
		; Travel the face
		f/offset: dp/offset
		
		; Start passage pair timers
		sp/rate: sp/extra/rate
		dp/rate: dp/extra/rate
		
		return 0
	]

	; Reset passage after timeout
	PassageReset: function [f [object!]][
		f/extra/loaded: false
		f/image: Passage-G
	]
		
]