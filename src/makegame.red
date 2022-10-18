Red [
	Title:   "Cave-In"
	Author:  "@planetsizecpu"
	File:    %MakeGame.red
	Purpose: {Create game functions after making objects}
]

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

		; Apply gravity to objects that can fall down
		GoGravity
		
		; Check for screen roll
		either GameData/PlayerFace/offset/x > GameData/CaveFaceHalfSizeX [
			GameData/CaveFace/offset/x: GameData/CaveFaceRollOffsetX
		][
			GameData/CaveFace/offset/x: 0 
		]
		either GameData/PlayerFace/offset/y > GameData/CaveFaceHalfSizeY [
			GameData/CaveFace/offset/y: GameData/CaveFaceRollOffsetY
		][
			GameData/CaveFace/offset/y: 0 
		]
		
		; Check for demo mode autoplay
		if GameData/DemoMode [PlayDemoMode]
		
		; Check for thief tools use timing
		if GameData/PlayerFace/extra/tool [
			GameData/PlayerFace/extra/getobject/extra/usedtool: add GameData/PlayerFace/extra/getobject/extra/usedtool GameData/GameRate
			; Wow! we are going across a lot of objects here, I would call it transobjecting
			if GameData/PlayerFace/extra/getobject/extra/usedtool > GameData/PlayerFace/extra/getobject/extra/timetool  [
				prin "END OF USE TOOL "
				print GameData/PlayerFace/extra/getobject/extra/name
				Message "Tool timeout"
				
				; Set tool invisible
				GameData/PlayerFace/extra/getobject/visible?: false
				GameData/PlayerFace/extra/getobject/offset: -50x-50	
				GameData/PlayerFace/extra/getobject/extra/gravity: false
				
				; Delete used tools from the tree-of-faces to shorten the process loop
				alter GameData/CaveFace/pane (GameData/PlayerFace/extra/getobject)
				
				; Thief to leave tool
				GameData/PlayerFace/extra/tool: false
				GameData/PlayerFace/extra/getobject: copy []
				either GameData/PlayerFace/extra/handle [
					GameData/PlayerFace/image: ThiefHandle
				][
					GameData/PlayerFace/image: GameData/PlayerFace/extra/image
				]
			]
		]
		
		; Check for level goals and progress
		if GameData/Goldbags >= GameData/Stock [
			print "***************************************************"
			prin  "ENDING LEVEL " print GameData/Curlevel
			print "***************************************************"
			print
			EraseLevel GameData/CaveFace
			alert "CONGRATS! LEVEL FINISHED"
			GameData/Levels: next find GameData/Levels GameData/Curlevel
			GameData/Curlevel: first GameData/Levels
			write %curlevel.txt GameData/Curlevel
			GameData/Stock: 0
			GameData/Goldbags: 0
			
			either none? GameData/Curlevel [
				print "***************************************************"		
				print " NO MORE LEVELS! " 
				print "***************************************************"		
				Message "Congratulations you win the game"
				view BadgeScr
				alert "CONGRATS! YOU WIN THE GAME"
				GameData/Curlevel: "L1"
				write %curlevel.txt GameData/Curlevel
				quit
			][
				print "***************************************************"		
				prin  "LOADING LEVEL " print GameData/Curlevel
				print "***************************************************"		
				Message "Loading new level"
				alert "Get ready for new level!"
				LoadLevel first GameData/Levels
				GameData/PlayerFace/extra/lives: add GameData/PlayerFace/extra/lives 1 ;One extra life for level ending
				Glives/text: copy "LIVES:  " 
				append Glives/text to-string GameData/PlayerFace/extra/lives
				Message "You awarded one extra life"
				GameData/Score: add GameData/Score 250
				Gscore/text: copy "SCORE: "
				append Gscore/text to-string GameData/Score							
			]
		]
				
		Return Ret
	]
	
	; Check keyboard for handling
	CheckKeyboard: function [f key][
		switch key [
			left [GoLeft GameData/PlayerFace]
			right [GoRight GameData/PlayerFace]
			up [GoUp GameData/PlayerFace]
			down [GoDown GameData/PlayerFace]
			#" " [GoAction GameData/PlayerFace]
			#"#" [GameData/Stock: 1 Gstock/text: copy "STOCK: "	append Gstock/text to-string GameData/Stock message "Oh my god!"] ;Cheat
			#"%" [AskLevel] ;Cheat
			#"@" [SetDemoMode] ;Cheat
		]	
	]
	
	; Messages to player on low bar
	Message: function [s [string!]][
		GameControl/offset/y: GameScr/offset/y - 95
		info/text: copy s 
	]
	
	; Set demo mode 
	SetDemoMode: function [][
		either GameData/DemoMode [
			GameData/DemoMode: false 
			GameData/PlayerFace/extra/lives: 3
			Glives/text: copy "LIVES:  " 
			append Glives/text to-string GameData/PlayerFace/extra/lives
			message "DEMO MODE OFF"
		][
			GameData/DemoMode: true 
			GameData/PlayerFace/extra/lives: 99 
			Glives/text: copy "LIVES:  " 
			append Glives/text to-string GameData/PlayerFace/extra/lives
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
	
	; Ask for new level cheat
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
	
	; Erase current level data
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
			; Check if object is visible 
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
	
	; Check if some object overlaps other object in the whole cave
	CheckOverlaps: function [f [object!]][
		Ret: none
		foreach-face GameData/CaveFace [
			if face <> f [
				if overlap? face f [Ret: face]
			]
		]
		return Ret
	]
	
	; Check if some loaded kart overlaps gold/pickax/elevator, we call here when action key pressed while on kart
	; so f argument should be a loaded kart only to work properly, this is due to the fact that previous func
	; not work while on kart as it detects the thief overlap on the same kart it goes before detecting other objects.
	; We also call here to detect battle spheres hit on the boy while on elevator because is the same behavior
	CheckKartOverlaps: function [f [object!]][
		Ret: none
		foreach-face GameData/CaveFace [
			if any [face/extra/type = "G" face/extra/type = "T" face/extra/type = "L"] [
				if overlap? face f [Ret: face]
			]
		]
		return Ret
	]

	; Check if it is terrain at left from some object
	CheckTerrainLT: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
		CheckPointU: (((FOffset/y + 3) * GameData/CaveFace/size/x) + FOffset/x ) - 2
		CheckPointC: (((FOffset/y + (to-integer (FSize/y / 2))) * GameData/CaveFace/size/x) + FOffset/x ) - 5		
		CheckPointD: (((FOffset/y + (FSize/y - 3 )) * GameData/CaveFace/size/x) + FOffset/x ) - 2
		TerrainU: GameData/CaveFace/image/(CheckPointU)
		TerrainC: GameData/CaveFace/image/(CheckPointC)		
		TerrainD: GameData/CaveFace/image/(CheckPointD)
		if any [TerrainU = GameData/TerrainColor TerrainC = GameData/TerrainColor TerrainD = GameData/TerrainColor] [Ret: true]
		return Ret
	]

	; Check if it is terrain at right from some object
	CheckTerrainRT: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
		CheckPointU: (((FOffset/y + 3) * GameData/CaveFace/size/x) + FOffset/x + Fsize/x ) + 2
		CheckPointC: (((FOffset/y + (to-integer (FSize/y / 2))) * GameData/CaveFace/size/x) + FOffset/x + Fsize/x ) + 5				
		CheckPointD: (((FOffset/y + (FSize/y - 3 )) * GameData/CaveFace/size/x) + FOffset/x + Fsize/x ) + 2		
		TerrainU: GameData/CaveFace/image/(CheckPointU)
		TerrainC: GameData/CaveFace/image/(CheckPointC)		
		TerrainD: GameData/CaveFace/image/(CheckPointD)
		if any [TerrainU = GameData/TerrainColor TerrainC = GameData/TerrainColor TerrainD = GameData/TerrainColor] [Ret: true]		
		return Ret
	]
	
	; Check if it is a climbing slope at left from some object
	CheckSlopeLT: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
		CheckPoint: (((FOffset/y + (FSize/y)) * GameData/CaveFace/size/x) + FOffset/x ) - 8
		Terrain: GameData/CaveFace/image/(CheckPoint)
		if any [Terrain = GameData/TerrainColor Terrain = GameData/StairsColor1 Terrain = GameData/StairsColor2] [Ret: true]
		return Ret
	]

	; Check if it is a climbing slope at right from some object
	CheckSlopeRT: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
		CheckPoint: (((FOffset/y + (FSize/y)) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x + 8
		Terrain: GameData/CaveFace/image/(CheckPoint)
		if any [Terrain = GameData/TerrainColor Terrain = GameData/StairsColor1 Terrain = GameData/StairsColor2] [Ret: true]
		return Ret
	]
	
	; Check if it is ceiling over some object
	CheckCeiling: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
		CheckPointL: (((FOffset/y - GameData/CeilingDist) * GameData/CaveFace/size/x) + FOffset/x )
		CheckPointR: (((FOffset/y - GameData/CeilingDist) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x		
		TerrainL: GameData/CaveFace/image/(CheckPointL)
		TerrainR: GameData/CaveFace/image/(CheckPointR)	
		if any [TerrainL = GameData/TerrainColor TerrainR = GameData/TerrainColor] [Ret: true]
		return Ret
	]	

	; Check if it is floor under some object
	CheckFloor: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
		CheckPointL: (((FOffset/y + FSize/y + 1) * GameData/CaveFace/size/x) + FOffset/x )
		CheckPointR: (((FOffset/y + FSize/y + 1) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x
		TerrainL: GameData/CaveFace/image/(CheckPointL)
		TerrainR: GameData/CaveFace/image/(CheckPointR)	
		if any [TerrainL = GameData/TerrainColor TerrainR = GameData/TerrainColor] [Ret: true]
		return Ret
	]

	; Check if it is stairs over some object
	CheckStairsUP: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
	
		; Compute points to check over the object using coordinates on cave image
		CheckPointOL: (((FOffset/y - 1) * GameData/CaveFace/size/x) + FOffset/x )
		CheckPointOR: (((FOffset/y - 1) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x
	
		; Get terrain color
		TerrainOL: GameData/CaveFace/image/(CheckPointOL)
		TerrainOR: GameData/CaveFace/image/(CheckPointOR)
	
		; Check stairs over the object 
		if ((TerrainOL = GameData/StairsColor1) or (TerrainOL = GameData/StairsColor2)) and
				((TerrainOR = GameData/StairsColor1) or (TerrainOR = GameData/StairsColor2)) [Ret: true]
	
		return Ret
	]
	
	; Check if it is stairs under some object
	CheckStairsDN: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
	
		; Compute points to check under the object using coordinates on cave image
		CheckPointUL: (((FOffset/y + FSize/y + 2) * GameData/CaveFace/size/x) + FOffset/x )
		CheckPointUR: (((FOffset/y + FSize/y + 2) * GameData/CaveFace/size/x) + FOffset/x ) + FSize/x
	
		; Get terrain color
		TerrainUL: GameData/CaveFace/image/(CheckPointUL)
		TerrainUR: GameData/CaveFace/image/(CheckPointUR)	

		; Check stairs under the object
		if ((TerrainUL = GameData/StairsColor1) or (TerrainUL = GameData/StairsColor2)) and
				((TerrainUR = GameData/StairsColor1) or (TerrainUR = GameData/StairsColor2)) [Ret: true]
	
		return Ret
	]
			
	; Check if it is handle over some object
	CheckHandle: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
		c: 0
		
		; Compute points to check over the object using coordinates on cave image
		while [c < 45] [
			CheckPointY: (((FOffset/y - c) * GameData/CaveFace/size/x) + FOffset/x + (to-integer (FSize/x / 2)))
			TerrainY: GameData/CaveFace/image/(CheckPointY)
			if (TerrainY = GameData/HandleColor) [Ret: true]		
			c: add c 1
		]
		return Ret
	]
	
	; Look to left of object coordinates for lifter
	LookForElevatorLT: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset

		; Loop to left from object
		CheckPointY: FOffset/y * GameData/CaveFace/size/x ;We check at object eye level
		CheckPointX: FOffset/x
		pxl: 0
		repeat pxl 12 [
			CheckPointX: subtract CheckPointX 1
			CheckPoint: (CheckPointY + CheckPointX )
			Terrain: GameData/CaveFace/image/(CheckPoint)
			if  Terrain = GameData/LifterCable [
				Ret: true
				break
			]
		]
		return Ret
	]

	; Look to right of object coordinates for lifter
	LookForElevatorRT: function [f [object!]][
		Ret: false
		FSize: f/size
		FOffset: f/offset
		
		; Loop to right from object
		CheckPointY: FOffset/y * GameData/CaveFace/size/x ;We check at object eye level
		CheckPointX: FOffset/x + FSize/x
		pxl: 0
		repeat pxl 12 [
			CheckPointX: add CheckPointX 1
			CheckPoint: (CheckPointY + CheckPointX )
			Terrain: GameData/CaveFace/image/(CheckPoint)
			if  Terrain = GameData/LifterCable [
				Ret: true
				break
			]
		]
		return Ret
	]

	;-------------------------------------------------------------------------
	; Movement & effects functions
	;-------------------------------------------------------------------------	
	
	; Getup effects for people
	GoGetup: function [f [object!]][
		if f/extra/type = "A" [
			(first f/extra/name) = #"a" [
				foreach img GameData/AgentGetup [f/image: get img]
				f/image: AgentGetup-X2		
			]
			if (first f/extra/name) = #"f" [
					foreach img GameData/FAgentGetup [f/image: get img]			
					f/image: FAgentGetup-X2		
			]
			if (first f/extra/name) = #"p" [
					foreach img GameData/PAgentGetup [f/image: get img]			
					f/image: PAgentGetup-X2					
			]
			if (first f/extra/name) = #"y" [
					foreach img GameData/YAgentGetup [f/image: get img]			
					f/image: YAgentGetup-X2					
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

	; Dead effects for people, return true if player has no more lives
	GoDead: function [f [object!]][
		Ret: false
		f/size: f/extra/size
		prin f/extra/name print " IS DEAD"
		
		; Check the lives of agents to stop births
		if f/extra/type = "A" [
			; Account score
			GameData/Score: add GameData/Score GameData/AgentKnockPoints
			Gscore/text: copy "SCORE: "
			append Gscore/text to-string GameData/Score				
			Message "An agent is dead"
			either f/extra/lives > 0 [f/extra/lives: subtract f/extra/lives 1][f/rate: none return true]
			;Show female/male/phantasm agents dead image cycle
			if (first f/extra/name) = #"a" [
				foreach img GameData/AgentDead [f/image: get img wait GameData/AgentDeadDelay]		
			]
			if (first f/extra/name) = #"f" [
				foreach img GameData/FAgentDead [f/image: get img wait GameData/AgentDeadDelay]		
			]
			if (first f/extra/name) = #"p" [
				foreach img GameData/PAgentDead [f/image: get img wait GameData/AgentDeadDelay]		
			]
			if (first f/extra/name) = #"y" [
				foreach img GameData/YAgentDead [f/image: get img wait GameData/AgentDeadDelay]		
			]			
		]

		; Check the lives of thief to stop game
		if f/extra/type = "J" [
			Message "You dead"
			either f/extra/lives > 0 [f/extra/lives: subtract f/extra/lives 1][return true]
			;Play dead sequence
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
			f/extra/getobject/visible?: true
			f/extra/getobject/extra/gravity: true
		]
		
		; Set defaults for object
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
		; Set object at his starting point & size
		f/offset: f/extra/offset
		f/size: f/extra/size
		f/image: f/extra/image
		
		Glives/text: copy "LIVES:  " 
		append Glives/text to-string GameData/PlayerFace/extra/lives
		
		return Ret
	]
	
	; Gravity effect for objects affected by, also added effects of inertia, passage & difficulty 
	GoGravity: function [][
		; Check if we come from passage travel to do effects
		if GameData/PlayerFace/extra/passage [
			GameData/PlayerFace/extra/passage: false
			foreach img GameData/ThiefUnVanish [GameData/PlayerFace/image: get img wait GameData/ThiefDeadDelay]
			GameData/PlayerFace/offset/x: GameData/PlayerFace/offset/x + 5
			GameData/PlayerFace/offset/y: GameData/PlayerFace/offset/y - 5
			GameData/PlayerFace/image: Thief-S4
		]
		foreach-face GameData/CaveFace [
			
			; If object has gravity apply them when no floor no stairs and no lifter under the object
			if all [face/visible? face/extra/gravity] [

				; Check for overlaps when falling
				OtherFace: CheckOverlaps face
				if not none? OtherFace [
				
					; Check for lifter surface for stop fall of persons
					if OtherFace/extra/type = "L" [
						if any [face/extra/type = "A" face/extra/type = "J" face/extra/type = "R"] [
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
								message "Thake this!!!"
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
					; Check for gold hit on band so we can't finish this level,					
					if OtherFace/extra/type = "B" [			
						if any [face/extra/type = "G" face/extra/type = "W"][
							print "ITEM LOST ON LAVA, WE CAN'T FINISH THIS LEVEL SO RESTART"
							alert "ITEM LOST ON LAVA (RESTART)"
							OldLevel: GameData/Curlevel
							info/rate: none
							EraseLevel GameData/CaveFace 
							GameData/Curlevel: OldLevel
							LoadLevel GameData/Curlevel
							info/rate: GameData/GameRate
						]
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
							GameData/Goldbags: add GameData/Goldbags 1
							
							prin "WHEELBARROW " prin OtherFace/extra/name 
							prin " NOW HAS " prin OtherFace/extra/goldbags
							print " GOLD BAGS"
							Ggbags/text: copy "CARRY: "
							append Ggbags/text to-string GameData/Goldbags
							
							GameData/Score: add GameData/Score face/extra/value
							Gscore/text: copy "SCORE: "
							append Gscore/text to-string GameData/Score	
				
							face/enabled?: false
							face/visible?: false
							face/extra/gravity: false
							face/offset: -25x-25
							; Delete carryed bag from the face tree to shorten the process loop
							;alter GameData/CaveFace/pane (face)
							either alter GameData/CaveFace/pane (face) [
								prin "ADDED OBJECT: " 
								print face/extra/facename
								][
								prin "DELETED OBJECT: " 
								print face/extra/facename
							]						
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
					
					; Check for gravity effects on falling objects
					if face/extra/type = "A" [
						if face/extra/altitude > GameData/FallingFaceAltitude [
							if (first face/extra/name) = #"a" [
								face/image: Agent-S4
							]
							if (first face/extra/name) = #"f" [
								face/image: FAgent-S4
							]
							if (first face/extra/name) = #"p" [						
								face/image: PAgent-S4
							]
							if (first face/extra/name) = #"y" [						
								face/image: YAgent-S4
							]

						]
						if face/extra/altitude > GameData/GetupAltitude [face/extra/getup: true] ; Agents can not die by fall or game is not playable
					]
					if face/extra/type = "J" [
						if face/extra/altitude > GameData/FallingFaceAltitude [if not face/extra/wbarrow [face/image: Thief-S4]]
						if face/extra/altitude > GameData/GetupAltitude and (not face/extra/wbarrow) [face/extra/getup: true]
						if face/extra/altitude > GameData/DeadAltitude [face/extra/altitude: 0 GoDead face]
					]					
					if face/extra/type = "R" [
							if face/extra/altitude > GameData/FallingFaceAltitude [if not face/extra/wbarrow [face/image: Girl-S4]]
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
	
	; Some object going left
	GoLeft: function [f [object!]][
		if f/extra/handle [exit]
		if f/extra/type = "J" [f/extra/direction: -1]
		if CheckTerrainLT f [exit]
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

	; Some object going right
	GoRight: function [f [object!]][
		if f/extra/handle [exit]
		if f/extra/type = "J" [f/extra/direction: 1]
		if CheckTerrainRT f [exit]
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

	; Some object going up
	GoUp: function [f [object!]][
		if f/extra/handle [exit]
		if CheckCeiling f [exit]	
		if all [(not CheckStairsUP f) (not CheckStairsDN f)] [exit]

		y: f/offset/y
		y: subtract y GameData/StepValue
		if f/extra/type = "A" [y: subtract y GameData/StepValue] ;Agents need extra speed on stairs because of homing checks
		f/offset/y: y

		GoWalkStairs f
	]

	; Some object going down
	GoDown: function [f [object!]][
		if f/extra/handle [exit]			
		if CheckFloor f [exit]	

		y: f/offset/y
		y: add y GameData/StepValue
		if f/extra/type = "A" [y: add y GameData/StepValue] ;Agents need extra speed on stairs because of homing checks
		f/offset/y: y

		GoWalkStairs f 
	]

	; Some object walking on stairs 
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
	
	; Some object walking on floor
	GoWalkFloor: function [f [object!] dir [integer!]][
		
		; Check if object has something loaded on hands 
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

		; Check if it is overlap on this object
		OtherFace: CheckOverlaps f 
	
		; BEFORE TAKING SOMETHING WE MUST LEAVE WHAT WE HAVE ON HANDS
		
		; Check if we leave gold
		if all [f/extra/gold (not CheckStairsDN f) (not CheckTerrainLT f) (not CheckTerrainRT f) (not CheckHandle f) (not f/extra/handle)] [
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

					; Account score
					GameData/Score: add GameData/Score f/extra/getobject/extra/value
					Gscore/text: copy "SCORE: "
					append Gscore/text to-string GameData/Score
					
					; Set gold away
					f/extra/getobject/enabled?: false
					f/extra/getobject/visible?: false
					f/extra/getobject/extra/gravity: false
					f/extra/getobject/offset: -25x-25
					; Delete carryed bag from the object tree to shorten the process loop
					;alter GameData/CaveFace/pane (f/extra/getobject
					either alter GameData/CaveFace/pane (f/extra/getobject) [
						prin "ADDED OBJECT: " 
						print f/extra/getobject/extra/facename
						][
						prin "DELETED OBJECT: " 
						print f/extra/getobject/extra/facename
						
					]
					
					; Set defaults
					f/extra/getobject: copy []
					f/extra/gold: false
					f/size: Thief-S4/size
					f/image: Thief-S4					
					exit
				][
					; Leave gold on lifter o kart
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
					prin "LEAVE GOLD IN MOTION " print OtherFace/extra/name
					Message "Leave gold in motion"
					OtherFace: none
				]
			]
		]			
		
		; Check if we leave tool
		if all [f/extra/tool (not CheckTerrainLT f) (not CheckTerrainRT f) (not CheckHandle f) (not f/extra/handle) (none? OtherFace)] [
			; Recover tool object data
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
		if all [f/extra/wbarrow (not CheckHandle f) (none? OtherFace)] [
			OtherFace: f/extra/getobject
			OtherFace/offset/x: f/offset/x + 5
			OtherFace/offset/y: f/offset/y + 10
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
		
		; Check if object has handle, and left them
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
			
			; Check if we take the (OtherFace) kart
			if not none? OtherFace [
				if OtherFace/extra/type = "K" [
					KartJumpIn OtherFace f
					f/visible?: false
					exit
				]
			]
		][
			; Check if object is under handle and grab them
			if (CheckHandle f) [ 
				if all [not f/extra/wbarrow not f/extra/onkart] [
					f/visible?: false
					f/extra/gravity: false
					f/extra/handle: true				
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
					f/offset/y: subtract f/offset/y 8
					f/visible?: true

					print "GRAB HANDLE"	
					Message "Ill grab this ceiling beam..."
				]
				
				; Check if we left the kart
				if not none? OtherFace [
					if OtherFace/extra/type = "K" [
						KartJumpOut OtherFace f
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
						f/offset/y: OtherFace/offset/y - 21
						f/visible?: true
						exit
					]
				]
			]
		]
		
		; NOW IF WE DON'T HAVE ANYTHING IN HANDS WE CAN TAKE SOMETING
		
		; Check overlap on other object and get it if we can
		if (not none? OtherFace) [
			if all [(not f/extra/handle) (not f/extra/tool) (not f/extra/gold) (not f/extra/wbarrow)] [
				;prin "*** OVERLAP OTHERFACE: " print OtherFace/extra/name
				switch OtherFace/extra/type [
					none [
						; We set this for security
					] 
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
						Message "Ah-ha! a pickax!!"
						f/extra/tool: true
						f/extra/getobject: OtherFace
						f/image: ThiefTool
						OtherFace/visible?: false
						OtherFace/offset: -50x-50
						OtherFace/extra/gravity: false
					]
					"W"	[if not f/extra/onkart [
							; It is malfunction if we get the barrow on kart, so it is forbidden
							prin "GOT WHEELBARROW " print OtherFace/extra/name
							Message "This is my kind of work!!!"
							f/extra/wbarrow: true
							f/extra/getobject: OtherFace
							f/size: ThiefWba/size
							either OtherFace/extra/goldbags > 0 [f/image: ThiefWGba][f/image: ThiefWba]
							OtherFace/visible?: false
							OtherFace/offset: -75x-75
							OtherFace/extra/gravity: false
						]
					]				
					"K" [if f/extra/onkart [	;The thief is on kart, check if overlaps gold/pickax
							KartOverlap: CheckKartOverlaps OtherFace
							if not none? KartOverlap [
								if KartOverlap/extra/type <> "L" [
									Message "Load stuff on kart "
									either KartOverlap/extra/type = "T" [f/extra/tool: true][f/extra/gold: true]
									f/extra/getobject: KartOverlap  
									KartOverlap/visible?: false
									KartOverlap/offset: -75x-75
									KartOverlap/extra/gravity: false
								]
							]
						]
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
		OtherFace: CheckOverlaps f			
		
		; Check for kart hit over some object 
		if not none? OtherFace [
			either f/extra/loaded [
				if OtherFace/extra/type = "A" [
					OtherFace/extra/dead: true
					print " AGENT DEAD BY KART"
					Message "Agent dead by kart"
					exit
				]		
			][
				if OtherFace/extra/type = "J" [
					OnElevator: false
					ElevatorOverlap: none
					ElevatorOverlap: CheckKartOverlaps OtherFace ;Check if also is an elevator so thief is on and safe
					if not none? ElevatorOverlap [
						if ElevatorOverlap/extra/type = "L" [OnElevator: true]
					]
					if all [not OtherFace/extra/handle not OnElevator] [
						prin OtherFace/extra/name
						print " DEAD BY KART"
						Message "You dead by kart"
						GoDead OtherFace
						exit
					]
				]
			]
		]
		
		; Check if kart is on stop delay
		either f/extra/stopdelay > 0 [
			f/extra/stopdelay: subtract f/extra/stopdelay 1
			exit
		][
			; No on stop delay, overlapping (boy) object (hidden) must follow the kart when moving
			if f/extra/loaded [
				f/extra/getobject/offset: f/offset	
			]
		]
		
		; We use direction on kart to allow easy displacement
		f/offset/x: add f/offset/x f/extra/direction
		if f/offset/x <= fst/x [f/extra/direction:  3 f/extra/stopdelay: GameData/KartStopDelay]
		if f/offset/x >= lst/x [f/extra/direction: -3 f/extra/stopdelay: GameData/KartStopDelay]
	]
	
	; Kart jump-in (from handle status) Here (OtherFace) is the thief
	KartJumpIn: function [f [object!] OtherFace [object!]][
		OtherFace/extra/handle: false	 ;Clear jumping object handle status
		OtherFace/extra/blockedLT: false ;Clear locks
		OtherFace/extra/blockedRT: false ;Clear locks 
		OtherFace/offset: f/offset  	 ;The jumping object follows kart hidden
		OtherFace/visible?: false		 ;Make jumping object not visible
		OtherFace/extra/gravity: false   ;Gravity does not affect on kart
		OtherFace/extra/wound: false	 ;Clear wound status as kart have medkit
		OtherFace/extra/onkart: true     ;Signal jumping object as loaded on kart
		f/extra/loaded: true 			 ;Signal kart as loaded
		f/extra/getobject: OtherFace	 ;Save thief object as loaded on kart
		f/extra/altitude: 0 			 ;Don't use altitude on kart
		either f/extra/direction > 0 [f/image: Kart-TR1][f/image: Kart-TL1]	;Set loaded kart image
		print "ON KART"
		message "... And into the wagon"
	]
	
	; Kart jump-out (to handle status on GoAction function)
	KartJumpOut: function [f [object!] OtherFace [object!]][
		f/extra/loaded: false			;Signal kart as unloaded
		f/extra/getobject: copy []		;Erase thief object from kart
		f/extra/altitude: 0 			;Don't use altitude on kart
		f/image: f/extra/image 			;Set unloaded kart image 
		OtherFace/visible?: true		;Make jumping object visible
		OtherFace/extra/handle: true    ;Signal jumping object as on handle
		OtherFace/extra/onkart: false	;Signal jumping object as not loaded on kart
		OtherFace/offset/y: subtract OtherFace/offset/y 16 ;Vertical adjust as we leave the kart
		print "LEAVE KART"
		message "Hoppla..."
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
			exit
		]

		; Check for altitude and force horizontal center jumping object on lifter to avoid walls 
		if not none? OtherFace [
			if any [OtherFace/extra/type = "J" OtherFace/extra/type = "A" OtherFace/extra/type = "R"] [
			
				; If have barrow, we are on kart, or we hang on handle, can't take lifter other case yes
				if all [not OtherFace/extra/wbarrow not OtherFace/extra/onkart not OtherFace/extra/handle] [
					OtherFace/offset/x: f/offset/x + f/extra/halfsizex  - 10 ; Centering jumping object is costly!
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
			]
		]
	]

	;-------------------------------------------------------------------------
	; Agents motion & homing functions
	;-------------------------------------------------------------------------
	AgentMotion: function [f [object!]][		

		; Check for this agent getup & dead
		if f/extra/getup [GoGetup f]
		if f/extra/dead [GoDead f exit]

		; Check for agent overlap  
		OtherFace: CheckOverlaps f 
		if not none? OtherFace [

			; Check if other object is agent and push them away if not on stairs (on lifter is unnecesary)
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
			
			; Check if agent is on lifter and guide in proper direction
			if OtherFace/extra/type = "L" [ 
				either (GameData/PlayerFace/offset/x < (f/offset/x - 2)) [
					either not GameData/PlayerFace/extra/tool [f/extra/direction: 9][f/extra/direction: 3]
				][
					either not GameData/PlayerFace/extra/tool [f/extra/direction: 3][f/extra/direction: 9]
				]
			]
			
			; Chekc if the girlfriend is with the thief
			if f/extra/type = "R" [
				if OtherFace/extra/type = "J" [
					f/image: GirlGetup-X3
					exit
				]
			]
			
			; Check if other object is thief
			if OtherFace/extra/type = "J" [
				; Check if thief has tool or is on kart and kill agent, otherwise kill thief
				either any [OtherFace/extra/tool OtherFace/extra/onkart] [
					; Set get-up status on the agent to disturb it
					print "PLAYER HAS TOOL or IS ON KART, NO FEAR."					
					f/extra/dead: true
					exit
				][
					OtherFace/extra/dead: true
					exit
				]
			]
		]

		; HOMING FUNCTION vary their behavior by the tool status! 
		; Negative direction means compute new direction (clock wise)
		; if there is a direction follow it while we can or find stairs or elevator 
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
				either LookForElevatorLT f [
					either none? OtherFace [
						f/extra/direction: -1 ;Don't wait for lifter if thief is on opposite direction
					][ 
						either all [OtherFace/extra/type = "L" not OtherFace/extra/loaded][
							GoLeft f
						][
							f/extra/direction: -1 ;Don't wait for lifter if thief is on opposite direction
						]
					]
				][
					GoLeft f
				]
			]
			if f/extra/direction = 3 [
				if any [f/extra/blockedRT CheckTerrainRT f] [f/extra/direction: -1]			
				either LookForElevatorRT f [  
					if none? OtherFace [  
						f/extra/direction: -1 ;Don't wait for lifter if thief is on opposite direction					
					][
						if all [OtherFace/extra/type = "L" not OtherFace/extra/loaded][
							GoRight f 
						][
							f/extra/direction: -1 ;Don't wait for lifter if thief is on opposite direction					
						]
					]
				][
					GoRight f
				]

			]		
			; If we find stairs or thief have pickax we must check for new direction
			if any [CheckStairsUP f CheckStairsDN f GameData/PlayerFace/extra/tool] [f/extra/direction: -1]
			exit
		]
				
		; Get best vertical direction first, as it need stairs to move it takes precedence
		if GameData/PlayerFace/offset/y < (f/offset/y - 2) [
			if any [CheckStairsUP f CheckStairsDN f] [
				either not CheckCeiling f [
					either not GameData/PlayerFace/extra/tool [f/extra/direction: 12][f/extra/direction: 6]
					exit ; For prevalence of vertical directions
				][
					f/extra/direction: -1
				]
			]
		]
		if (GameData/PlayerFace/offset/y > (f/offset/y + 2)) [
			if any [CheckStairsUP f CheckStairsDN f] [
				either not CheckFloor f [
					either not GameData/PlayerFace/extra/tool [f/extra/direction: 6][f/extra/direction: 12]
					exit ; For prevalence of vertical directions
				][
					f/extra/direction: -1				
				]
			]
		]

		; Agent is at the same vertical level, so we get best horizontal direction
		either GameData/PlayerFace/offset/x < f/offset/x [
			either not CheckTerrainLT f [
				either not GameData/PlayerFace/extra/tool [f/extra/direction: 9][f/extra/direction: 3]
			][
				f/extra/blockedLT: true  
				if (not CheckTerrainRT f) and (not CheckStairsUP f) [
					f/extra/direction: 3 ; We checked cannot go left and no on stairs
				]
			]
		][
			either not CheckTerrainRT f [
				either not GameData/PlayerFace/extra/tool [f/extra/direction: 3][f/extra/direction: 3]
			][
				f/extra/blockedRT: true
				if (not CheckTerrainLT f) and (not CheckStairsUP f) [
					f/extra/direction: 9 ; We checked cannot go right and no on stairs
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
			; Check if other object is agent and guide them away
			if OtherFace/extra/type = "A" [
					OtherFace/extra/getup: true
					f/extra/dead: true
					exit
			]
			; Check if other object is girl to kill the spider 			
			if OtherFace/extra/type = "R" [
					print "THE GIRL HAS FLY SWATTER, NO FEAR."
					f/extra/dead: true
					exit
			]
			; Check if other object is thief
			if OtherFace/extra/type = "J" [
				; Check if thief has tool or barrow or is on kart and kill thief if not
				either any [OtherFace/extra/tool /OtherFace/extra/wbarrow OtherFace/extra/onkart] [
					; Set get-up status on the spider to disturb it
					print "PLAYER HAS TOOL, NO FEAR."
					f/extra/dead: true
					exit
				][
					either OtherFace/extra/wound [
						OtherFace/extra/dead: true
						f/extra/dead: true
					][
						OtherFace/extra/wound: true
						OtherFace/extra/getup: true
						f/extra/dead: true
						
					]
					exit
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
		if f/extra/dead [GoDead f exit]

		; Check for drop overlap  
		OtherFace: CheckOverlaps f 
		if not none? OtherFace [
			; Check if other object is agent and guide them away
			if OtherFace/extra/type = "A" [
					OtherFace/extra/getup: true
					f/extra/dead: true
					exit
			]
			
			; Check if other object is thief
			if OtherFace/extra/type = "J" [
				either OtherFace/extra/wound [
					OtherFace/extra/dead: true
					f/extra/dead: true
				][
					OtherFace/extra/wound: true
					OtherFace/extra/getup: true
					f/extra/dead: true						
				]
				exit
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
						exit
			]
		]
		
		; Band displacement depending of axis: 1x0 -> Horizontal, Other -> Vertical
		either Axis = 1x0 [	
			f/offset/x: add f/offset/x f/extra/direction
			
			either f/extra/direction > 0 [ 
				if (f/offset/x) >= 0 [f/offset/x: f/extra/offset/x]
			][
				if (absolute f/offset/x) > (to-integer (f/image/size/x / 2)) [f/offset/x: f/extra/offset/x]
			]
		][
			f/offset/y: add f/offset/y f/extra/direction
			either f/extra/direction > 0 [ 
				if (f/offset/y) >= 0 [f/offset/y: f/extra/offset/y]
			][
				if (absolute f/offset/y) > (to-integer (f/image/size/y / 2)) [f/offset/y: f/extra/offset/y]
			]
		]
	]	
	
	;-------------------------------------------------------------------------
	; Passage motion 
	;-------------------------------------------------------------------------
	PassageMotion: function [f [object!] sp [object!]][
	
		; Do nothing if start passage is loaded 
		if sp/extra/loaded [exit]
		
		; Do nothing if object is not allowed to travel
		if all [f/extra/type <> "A" f/extra/type <> "J" f/extra/type <> "R"] [exit]
		
		; Init destination passage
		dp: copy []
		
		; Stop this pair passage timers & get destination passage face
		foreach-face GameData/CaveFace [
			if face/extra/type = "P" [
				; Pair grouping is on direction field
				if face/extra/direction = sp/extra/direction [
					face/rate: none
					if face <> sp [dp: face] ;Get destination passage 
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
		
		; Thief vanish transition effects idea thx to @greggirwin
		if f/extra/type = "J" [
			OldSize: f/size
			f/offset: sp/offset
			f/offset/x: f/offset/x - 5
			f/offset/y: f/offset/y - 25
			f/size: ThiefVanish-X1/size
			foreach img GameData/ThiefVanish [f/image: get img wait GameData/ThiefDeadDelay]
			f/extra/passage: true
			f/size: OldSize
			OldSize: 0x0
		]
		
		; Travel the passing object
		f/offset: dp/offset
		
		; Start passage pair timers
		sp/rate: sp/extra/rate
		dp/rate: dp/extra/rate

		exit
	]

	; Reset passage after timeout
	PassageReset: function [f [object!]][
		f/extra/loaded: false
		f/image: Passage-G
	]
	;-------------------------------------------------------------------------
	; Battle Spheres motion & effects functions 
	;-------------------------------------------------------------------------
	XPhereMotion: function [f [object!]][
		/local fst: first f/extra/stops
		/local lst: last  f/extra/stops
		/local stp: 0
		OtherFace: CheckOverlaps f			
		
		; Check for sphere hit over some object 
		if not none? OtherFace [
			if OtherFace/extra/type = "J" [
				OnElevator: false
				ElevatorOverlap: none
				ElevatorOverlap: CheckKartOverlaps OtherFace ;Check if also is an elevator so thief is on and safe
				if not none? ElevatorOverlap [
					if ElevatorOverlap/extra/type = "L" [OnElevator: true]
				]
				if not OnElevator [
					prin OtherFace/extra/name
					print " DEAD BY SPHERE"
					Message "You dead by sphere"
					GoDead OtherFace
					exit
				]
			]
		]
		
		; Check if sphere is on stop delay
		if f/extra/stopdelay > 0 [f/extra/stopdelay: subtract f/extra/stopdelay 1 exit]
		
		; We use direction on sphere to allow easy displacement
		f/offset/x: add f/offset/x f/extra/direction
		if f/offset/x <= fst/x [f/extra/direction:  3 f/extra/stopdelay: 20]
		if f/offset/x >= lst/x [f/extra/direction: -3 f/extra/stopdelay: 20]
	
		; We use random value to allow vertical sneak of spheres
		either f/extra/altitude < 60 [
			f/extra/altitude: add f/extra/altitude 1
		][
			f/extra/altitude: 0
			either f/extra/walking < 3 [f/extra/walking: add f/extra/walking 1][f/extra/walking: 0]
			f/offset/y: (fst/y - 15) + random 30
			if f/extra/walking = 0 [f/image: f/extra/images/1]
			if f/extra/walking = 1 [f/image: f/extra/images/2]
			if f/extra/walking = 2 [f/image: f/extra/images/3]
			if f/extra/walking = 3 [f/image: f/extra/images/4]
		]
	]
		
]