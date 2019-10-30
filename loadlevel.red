Red [
	Title:   "Cave-In"
	Author:  "@planetsizecpu"
	File:    "LoadLevel.red"
]

;--------------------------------------------------------------------------------------------------
; Load level data
;--------------------------------------------------------------------------------------------------
LoadLevel: func [lv][

	; Level selection & loading
	Ldata: to-file "DATA"
	Level: to-file lv
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
			dead: false
			loaded: false
			wound: false
			blockedLT: false
			blockedRT: false
			image: copy []
			images: copy []			
			either ItemType = "C" [
				image: load (Level/(lin/11))
			][
				image: load (Ldata/(lin/11))
				foreach p lin [if c > 10 [append images load (Ldata/(p))] c: add c 1]
			]
			face: object! []
			getobject: [] 
		]
	]
	unset 'c

	; Locate all items on screen	
	foreach x GameData/Items [

		; Read item object
		ItemObj: get to-word x
		w: to-word ItemObj/facename
		
		; Make new face for item object depending on its type and attach to cave panel
		switch/default ItemObj/type [
			"A" [set (w) make face! [type: 'base size: ItemObj/size offset: ItemObj/offset image: copy ItemObj/image extra: ItemObj
									 rate: ItemObj/rate actors: context [on-time: func [f e][AgentMotion f]]
									 ItemObj/lives: 32
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
					GameData/CaveFaceHalfSizeX: GameData/CaveFace/size/x / 2
					GameData/CaveFaceRollOffsetX: 0 - GameData/CaveFaceHalfSizeX
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
		] [prin "UNKNOWN OBJECT ON CONFIG FILE " print x alert "UNKNOWN OBJECT ON CONFIG FILE" quit]
		
		; Set object's face, now object/face points to face and face/extra points to object, to easy data I/O 
		ItemObj/face: (get w)

	]
	unset 'x unset 'w
	
	; Show game info
	Glevel/text: copy "LEVEL: " 
	append Glevel/text GameData/Curlevel	
	info/text: copy "Press (SPACE) as button, go for heavy gold!"
	Glives/text: copy "LIVES:  " 
	append Glives/text to-string john/lives
	Gstock/text: copy "STOCK: "
	append Gstock/text to-string GameData/Stock
	Ggbags/text: copy "CARRY: " 
	append Ggbags/text to-string GameData/Goldbags
	Gdeasy/data: false
	Gdnorm/data: true
	Gddiff/data: false
	Gdexpe/data: false
]

;-------------------------------------------------------------------------
; Load default images for handling
;-------------------------------------------------------------------------
LoadDfltImages: func [][
	Ldata: to-file "DATA"

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
	
	Kart-TL1: load to-file (Ldata/Kart-tl1.png)
	Kart-TR1: load to-file (Ldata/Kart-tr1.png)
	
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
