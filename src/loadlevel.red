Red [
	Title:   "Cave-In"
	Author:  "@planetsizecpu"
	File:    %LoadLevel.red
	Purpose: {Load game and level data and create objects}
]

;--------------------------------------------------------------------------------------------------
; Load level data
;--------------------------------------------------------------------------------------------------
LoadLevel: func [lv][

	; Level selection & loading
	Ldata: to-file "data"
	Level: to-file lv
	GameData/Curlevel: to-string lv
	LastPassage: copy " "

	; Read level config file
	LevelData: copy []
	foreach x read/lines to-file (Level/items.txt) [
		f: to-string first x
		if (f <> "#") and (f <> "&") [append LevelData x]
		if f = "&" [ 
			w: second split x " " 
			v: third split x " " 
			if tuple? GameData/(to-word w) [
				GameData/(to-word w): to-tuple v	
			]
			if logic? GameData/(to-word w) [
				GameData/(to-word w): to-logic v	
			]
			if integer? GameData/(to-word w) [
				GameData/(to-word w): to-integer v	
			]			
		]
	]
	unset 'f unset 'w unset 'v

	; To store level objects 
	GameData/Items: copy []
	GameData/Stock: 0
	GameData/Goldbags: 0

	; Create level item objects & item list
	; ItemType|ObjectName|FaceName|FaceSize|FaceOffset|Rate|Stops|TimeOfTool|Direction|Gravity|ImageFiles
	foreach x LevelData [ lin: split x "|" 
		
		; Create items list
		append GameData/Items lin/2
		
		; Type of item is the first character of the first field on the line
		ItemType: to-string first lin/1
		
		; Override cavern face name and set a fixed one for secure use on scripts
		fn: lin/3
		if ItemType = "C" [fn: GameData/CaveName]
		
		; Counter for parsing images
		c: 1 
		
		; Create new item object
		set (to-word lin/2) object [
			type: ItemType 
			name: lin/2 
			facename: fn 
			face: copy []
			size: to-pair lin/4 
			halfsizex: to-integer (size/x / 2)
			halfsizey: to-integer (size/y / 2)
			offset: to-pair lin/5  
			rate: to-time lin/6 
			stops: copy []
			foreach p (split lin/7 ",") [append stops to-pair p]
			stopdelay: 0
			direction: to-integer lin/9 
			walking: 0
			lastdir: -1
			inertia: 0.0
			altitude: 0
			goldbags: 0
			lives: 0
			value: 0 if [ItemType = "G"][Value: 100 ; Nominal value
							if (first name) = #"f" [Value: 200] ; Fat-goldbags
							if (first name) = #"h" [Value: 300] ; Heavy-goldbags
						]
			gravity: false if lin/10 = "1" [gravity: true]
			timetool: to-time lin/8
			usedtool: 0:0:0.0
			display: true
			getup: false
			onkart: false
			wbarrow: false
			tool: false
			gold: false
			handle: false
			passage: false
			dead: false
			loaded: false
			wound: false
			blockedLT: false
			blockedRT: false
			getobject: [] 
			image: copy []
			images: copy []			
			either ItemType = "C" [
				image: load (Level/(lin/11))
			][
				image: load (Ldata/(lin/11))
				foreach p lin [if c > 10 [append images load (Ldata/(p))] c: add c 1]
			]
		]
	]
	unset 'c

	; Locate all items on screen	
	foreach x GameData/Items [

		; Read item object
		ItemObj: get to-word x
		w: to-word ItemObj/facename
		
		; Check CPU index on faster machines to trim rate for karts & elevators
		inc: to-time 0:0:0.0003
		if any [ItemObj/type = "L" ItemObj/type = "K"] [
			if CpuData/CpuIdx > 0 [ItemObj/rate: add ItemObj/rate inc]
			if CpuData/CpuIdx > 1 [ItemObj/rate: add ItemObj/rate inc]
			if CpuData/CpuIdx > 2 [ItemObj/rate: add ItemObj/rate inc]
			if CpuData/CpuIdx > 3 [ItemObj/rate: add ItemObj/rate inc]
			if CpuData/CpuIdx > 4 [ItemObj/rate: add ItemObj/rate inc]
			if CpuData/CpuIdx > 5 [ItemObj/rate: add ItemObj/rate inc]
			if CpuData/CpuIdx > 6 [ItemObj/rate: add ItemObj/rate inc]
			if CpuData/CpuIdx > 7 [ItemObj/rate: add ItemObj/rate inc]
		]
		unset 'inc
		
		; Make new face for item object depending on its type and attach to cave panel
		switch/default ItemObj/type [
			"A" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
									 rate: ItemObj/rate actors: context [on-time: func [f e][AgentMotion f]]
									 ItemObj/lives: 64
									]
					append cave/pane (get w)
				]
			"B" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
						             rate: ItemObj/rate actors: context [on-time: func [f e][BandMotion f]]
									]
					append cave/pane (get w)
				]				
			"C" [set (w) make face! [type: 'panel size: ItemObj/size offset: ItemObj/offset pane: copy [] draw: copy [] 
									 image: copy ItemObj/image extra: ItemObj focus: true
									]
					append GameScr/pane get (w)
					GameData/CaveFace: get (w)
					GameData/CaveFaceHalfSizeX: to-integer (GameData/CaveFace/size/x / 2)
					GameData/CaveFaceRollOffsetX: 0 - GameData/CaveFaceHalfSizeX
					either GameData/CaveFace/size/y > 600 [
						GameData/CaveFaceHalfSizeY: to-integer (GameData/CaveFace/size/y / 2)
						GameData/CaveFaceRollOffsetY: 0 - GameData/CaveFaceHalfSizeY
					][
						GameData/CaveFaceHalfSizeY: to-integer (GameData/CaveFace/size/y)
						GameData/CaveFaceRollOffsetY: 0
					]
				]
			"D" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
									 rate: ItemObj/rate actors: context [on-time: func [f e][DropMotion f]]
									 ItemObj/lives: 255
									]
					append cave/pane (get w)													
				]			
			"G" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj]
					append cave/pane (get w)
					GameData/Stock: add GameData/Stock 1
				]
			"J" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj]
					append cave/pane (get w)
					ItemObj/lives: 3
					GameData/PlayerFace: (get w)
				]
			"K" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
						             rate: ItemObj/rate actors: context [on-time: func [f e][KartMotion f]]
									]
					append cave/pane (get w)
				]
			"L" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
						             rate: ItemObj/rate actors: context [on-time: func [f e][LifterMotion f]]
								    ]
					append cave/pane (get w)
				]
			"P" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
									 rate: ItemObj/rate actors: context [on-time: func [f e][PassageReset f]]
									]
					append cave/pane (get w)													
				]		
			"R" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
									 rate: ItemObj/rate actors: context [on-time: func [f e][AgentMotion f]]
									 ItemObj/lives: 64
									]
					append cave/pane (get w)
				]				
			"S" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
									 rate: ItemObj/rate actors: context [on-time: func [f e][SpiderMotion f]]
									 ItemObj/lives: 255
									]
					append cave/pane (get w)													
				]
			"T" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj]
					append cave/pane (get w)
				]	
			"W" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj]
					append cave/pane (get w)
				]				
			"X" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
						             rate: ItemObj/rate actors: context [on-time: func [f e][XphereMotion f]]
									]
					append cave/pane (get w)
				]
		] [prin "UNKNOWN OBJECT ON CONFIG FILE " print x alert "UNKNOWN OBJECT ON CONFIG FILE" quit]
		
		; Set object's face, now object/face points to face and face/extra points to object, to easy data I/O 
		ItemObj/face: (get w)

	]
	unset 'x unset 'w unset 'LevelData
	
	; Show game info
	info/text: copy "Press (SPACE) as button, go for heavy gold!"
	Glevel/text: copy "LEVEL: " 
	append Glevel/text GameData/Curlevel	
	Glives/text: copy "LIVES:  " 
	append Glives/text to-string john/lives
	Gstock/text: copy "STOCK: "
	append Gstock/text to-string GameData/Stock
	Ggbags/text: copy "CARRY: " 
	append Ggbags/text to-string GameData/Goldbags
	Gscore/text: copy "SCORE: "
	append Gscore/text to-string GameData/Score
	Gdeasy/data: false
	Gdnorm/data: true
	Gddiff/data: false
	Gdexpe/data: false
]

;-------------------------------------------------------------------------
; Load default images for handling
;-------------------------------------------------------------------------
LoadDfltImages: func [][
	Ldata: to-file "data"

	Thief-R1: load to-file (Ldata/thief-r1.png)
	Thief-R2: load to-file (Ldata/thief-r2.png)
	Thief-R3: load to-file (Ldata/thief-r3.png)
	Thief-L1: load to-file (Ldata/thief-l1.png)
	Thief-L2: load to-file (Ldata/thief-l2.png)
	Thief-L3: load to-file (Ldata/thief-l3.png)
	Thief-S1: load to-file (Ldata/thief-s1.png)
	Thief-S2: load to-file (Ldata/thief-s2.png)
	Thief-S3: load to-file (Ldata/thief-s3.png)
	Thief-S4: load to-file (Ldata/thief-s4.png)
	
	ThiefWba: load to-file (Ldata/thief-w.png)
	ThiefWba-L1: load to-file (Ldata/thief-wl1.png)
	ThiefWba-L2: load to-file (Ldata/thief-wl2.png)
	ThiefWba-L3: load to-file (Ldata/thief-wl3.png)	
	ThiefWba-R1: load to-file (Ldata/thief-wr1.png)
	ThiefWba-R2: load to-file (Ldata/thief-wr2.png)
	ThiefWba-R3: load to-file (Ldata/thief-wr3.png)		
	
	ThiefWGba: load to-file (Ldata/thief-wg.png)
	ThiefWGba-L1: load to-file (Ldata/thief-wlg1.png)
	ThiefWGba-L2: load to-file (Ldata/thief-wlg2.png)
	ThiefWGba-L3: load to-file (Ldata/thief-wlg3.png)	
	ThiefWGba-R1: load to-file (Ldata/thief-wrg1.png)
	ThiefWGba-R2: load to-file (Ldata/thief-wrg2.png)
	ThiefWGba-R3: load to-file (Ldata/thief-wrg3.png)		
	
	ThiefTool: load to-file (Ldata/thief-t.png)
	ThiefTool-L1: load to-file (Ldata/thief-tl1.png)
	ThiefTool-L2: load to-file (Ldata/thief-tl2.png)
	ThiefTool-L3: load to-file (Ldata/thief-tl3.png)	
	ThiefTool-R1: load to-file (Ldata/thief-tr1.png)
	ThiefTool-R2: load to-file (Ldata/thief-tr2.png)
	ThiefTool-R3: load to-file (Ldata/thief-tr3.png)	

	ThiefBag: load to-file (Ldata/thief-b.png)
	ThiefBag-L1: load to-file (Ldata/thief-bl1.png)
	ThiefBag-L2: load to-file (Ldata/thief-bl2.png)
	ThiefBag-L3: load to-file (Ldata/thief-bl3.png)	
	ThiefBag-R1: load to-file (Ldata/thief-br1.png)
	ThiefBag-R2: load to-file (Ldata/thief-br2.png)
	ThiefBag-R3: load to-file (Ldata/thief-br3.png)		
	
	ThiefGetup-X1: load to-file (Ldata/thiefs-x1.png)
	ThiefGetup-X2: load to-file (Ldata/thiefs-x2.png)
	ThiefDead-X1: load to-file (Ldata/thiefd-x1.png)
	ThiefDead-X2: load to-file (Ldata/thiefd-x2.png)
	ThiefDead-X3: load to-file (Ldata/thiefd-x3.png)
	ThiefDead-X4: load to-file (Ldata/thiefd-x4.png)
	
	ThiefHandle: load to-file (Ldata/thiefh1.png)
	ThiefHandleb: load to-file (Ldata/thiefh1-b.png)
	ThiefHandlet: load to-file (Ldata/thiefh1-t.png)	

	ThiefVanish-X1: load to-file (Ldata/thiefvanish-x1.png)
	ThiefVanish-X2: load to-file (Ldata/thiefvanish-x2.png)
	ThiefVanish-X3: load to-file (Ldata/thiefvanish-x3.png)
	ThiefVanish-X4: load to-file (Ldata/thiefvanish-x4.png)
	
	Agent-S1: load to-file (Ldata/agent-s1.png)
	Agent-S2: load to-file (Ldata/agent-s2.png)
	Agent-S3: load to-file (Ldata/agent-s3.png)
	Agent-S4: load to-file (Ldata/agent-s4.png)	

	AgentGetup-X1: load to-file (Ldata/agents-x1.png)
	AgentGetup-X2: load to-file (Ldata/agents-x2.png)
	AgentDead-X1: load to-file (Ldata/agentd-x1.png)
	AgentDead-X2: load to-file (Ldata/agentd-x2.png)
	AgentDead-X3: load to-file (Ldata/agentd-x3.png)
	AgentDead-X4: load to-file (Ldata/agentd-x4.png)

	FAgent-S1: load to-file (Ldata/fagent-s1.png)
	FAgent-S2: load to-file (Ldata/fagent-s2.png)
	FAgent-S3: load to-file (Ldata/fagent-s3.png)
	FAgent-S4: load to-file (Ldata/fagent-s4.png)		

	FAgentGetup-X1: load to-file (Ldata/fagents-x1.png)
	FAgentGetup-X2: load to-file (Ldata/fagents-x2.png)
	FAgentDead-X1: load to-file (Ldata/fagentd-x1.png)
	FAgentDead-X2: load to-file (Ldata/fagentd-x2.png)
	FAgentDead-X3: load to-file (Ldata/fagentd-x3.png)
	FAgentDead-X4: load to-file (Ldata/fagentd-x4.png)
	
	PAgent-S1: load to-file (Ldata/phant-s1.png)
	PAgent-S2: load to-file (Ldata/phant-s2.png)
	PAgent-S3: load to-file (Ldata/phant-s3.png)
	PAgent-S4: load to-file (Ldata/phant-s4.png)		

	PAgentGetup-X1: load to-file (Ldata/phants-x1.png)
	PAgentGetup-X2: load to-file (Ldata/phants-x2.png)
	PAgentDead-X1: load to-file (Ldata/phantd-x1.png)
	PAgentDead-X2: load to-file (Ldata/phantd-x2.png)
	PAgentDead-X3: load to-file (Ldata/phantd-x3.png)
	PAgentDead-X4: load to-file (Ldata/phantd-x4.png)

	YAgent-S1: load to-file (Ldata/tallman-s1.png)
	YAgent-S2: load to-file (Ldata/tallman-s2.png)
	YAgent-S3: load to-file (Ldata/tallman-s3.png)
	YAgent-S4: load to-file (Ldata/tallman-s4.png)
	
	YAgentGetup-X1: load to-file (Ldata/tallmans-x1.png)
	YAgentGetup-X2: load to-file (Ldata/tallmans-x2.png)
	YAgentDead-X1: load to-file (Ldata/tallmand-x1.png)
	YAgentDead-X2: load to-file (Ldata/tallmand-x2.png)
	YAgentDead-X3: load to-file (Ldata/tallmand-x3.png)
	YAgentDead-X4: load to-file (Ldata/tallmand-x4.png)
	
	Girl-S1: load to-file (Ldata/rose-s1.png)
	Girl-S2: load to-file (Ldata/rose-s2.png)
	Girl-S3: load to-file (Ldata/rose-s3.png)
	Girl-S4: load to-file (Ldata/rose-s4.png)	
	
	GirlGetup-X1: load to-file (Ldata/rose-x1.png)
	GirlGetup-X2: load to-file (Ldata/rose-x2.png)		
	GirlGetup-X3: load to-file (Ldata/rose-x3.png)
	
	Kart-TL1: load to-file (Ldata/kart-tl1.png)
	Kart-TR1: load to-file (Ldata/kart-tr1.png)
	
	Wbarrow-RG1: load to-file (Ldata/barrow-rg1.png)
	Wbarrow-LG1: load to-file (Ldata/barrow-lg1.png)
	
	SpiderDead-X1: load to-file (Ldata/spiderd-x1.png)
	SpiderDead-X2: load to-file (Ldata/spiderd-x2.png)
	SpiderDead-X3: load to-file (Ldata/spiderd-x3.png)
	SpiderDead-X4: load to-file (Ldata/spiderd-x4.png)
	
	DropDead-X1: load to-file (Ldata/dropd-x1.png)
	DropDead-X2: load to-file (Ldata/dropd-x2.png)
	DropDead-X3: load to-file (Ldata/dropd-x3.png)
	DropDead-X4: load to-file (Ldata/dropd-x4.png)
	
	Passage-G: load to-file (Ldata/passage-G.png)
	Passage-R: load to-file (Ldata/passage-R.png)
]
