Red [Title:   "Bogo"
	Author:  "@planetsizecpu"
	File:    %bogo.red
	Purpose: {Calculate cpu performance time for the most basic 100k calculations}
] 

bogo: function[][
	iterations: 100000
	current: 0
	value: 0.0
	retvalue: float!
	; Precomp values are:     0.13-0.14 on i5 4550/3.0Ghz
	
	; Timing for additions
	at1: now/time/precise repeat current iterations [value: add current 2] at2: now/time/precise at3: at2 - at1
	value: 0 current: 0
	
	; Timing for subtractions
	bt1: now/time/precise repeat current iterations [value: subtract current 2] bt2: now/time/precise bt3: bt2 - bt1
	value: 0 current: 0
	
	; Timing for multiplications
	ct1: now/time/precise repeat current iterations [value: multiply current 2] ct2: now/time/precise ct3: ct2 - ct1
	value: 0 current: 0
	
	; Timing for divisions
	dt1: now/time/precise repeat current iterations [value: divide current 2] dt2: now/time/precise dt3: dt2 - dt1
	value: 0 current: 0
	
	; Add values for total
	retvalue: to-float at3 + bt3 + ct3 + dt3
	return retvalue
]