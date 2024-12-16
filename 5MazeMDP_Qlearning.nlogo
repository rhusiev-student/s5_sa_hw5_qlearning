globals[
  total-reward
  actions
  delta
  success-ratio
  try-number
  success-number
  epoch
]

breed[walkers walker]

patches-own [
  reward
  value
  temp
  policy
  u
  active?
  Qlist
]

walkers-own [
  current-reward
  current-action
  Qsa
  Hlist
]


to setup
 clear-all


  ask patches with [abs pxcor < max-pxcor and abs pycor < max-pycor] [
    set pcolor white
    set plabel "-1"
    set plabel-color black
    set reward -1
  ]

  ask patch (min-pxcor + 1) (max-pycor - 1) [
    set pcolor blue
    set plabel "IN"
    sprout-walkers 1 [
      set color magenta
      set shape "person"
      set size 0.7
    ]
    set reward -1
  ]

  ask patch (max-pxcor - 1) (min-pycor + 1) [
    set pcolor green
    set plabel "OUT +100"
    set reward 100
  ]

;  ask one-of patches with [pcolor = white] [
;    set pcolor grey
;    set plabel "STOP +2"
;    set reward 2
;  ]

  ask n-of stone-number patches with [pcolor = white] [
    set pcolor black
  ]

  ask n-of volcano-number patches with [pcolor = white] [
    sprout 1 [
      set shape "fire"
      set size 0.7
    ]
    set plabel-color black
    set plabel "-50"
    set reward -50
  ]


  set total-reward []

  draw-lines

  reset-ticks

end

to draw-lines

  ask patches with [pcolor != black] [

    sprout 1 [
      set heading (- 45)
      fd 1 / sqrt 2
      rt 135
      set pen-size 1
      set color black
      pen-down
      fd 1
      rt 90
      fd 1
      rt 90
      fd 1
      rt 90
      fd 1

      die
      ]
    ]
end


to up

  ask walkers [
    set current-action "up"
    perform-action
  ]

end

to down

  ask walkers [
    set current-action "down"
    perform-action
  ]

end

to to-left

  ask walkers [
    set current-action "left"
    perform-action
  ]

end

to to-right

  ask walkers [
    set current-action "right"
    perform-action
  ]

end

to perform-action

  if ((current-action = "left") and (check-constraints (pxcor - 1) pycor) = true)
  [
      setxy pxcor - 1 pycor
   ]
  if ((current-action = "right") and (check-constraints (pxcor + 1) pycor))
  [
      setxy pxcor + 1 pycor
   ]
  if ((current-action = "up") and (check-constraints pxcor  (pycor + 1)))
  [
      setxy pxcor pycor + 1
   ]

  if ((current-action = "down") and (check-constraints pxcor  (pycor - 1)))
  [
      setxy pxcor pycor - 1
   ]

  calculate-reward

end


to-report check-constraints [x y]
  let f false

  if (x <= max-pxcor - 1) and (x >= min-pxcor + 1) and (y <= max-pycor - 1) and (y >= min-pycor + 1)
  [
    set f true
  ]
  let p patch x y
  if (p != nobody) [
    if ([pcolor] of patch x y = black)
  [
    set f false
  ]
  ]
  report f
end

to calculate-reward
  set current-reward current-reward + [reward] of patch-here


end

to set-random-policy
  ask patches with [pcolor = white or pcolor = blue] [
    ifelse count neighbors4 with [pcolor = green] > 0[
      set policy towards one-of neighbors4 with [pcolor = green]
    ][
      ; add grey to policy
      let naybors neighbors4 with [pcolor = white and pxcor > [pxcor] of myself or pycor < [pycor] of myself]
      if any? naybors with [pcolor = white][

      set policy towards one-of naybors with [pcolor = white]
      ]


    ]
  ]

end

to show-policy
  ask patches [
    set plabel policy
  ]

end

to perform-policy
  set total-reward []

  let max-epoch number-iterations
  set epoch 0
  let success false


  while [epoch < number-iterations or success = false][
    ; create new walker
    set success false
    ask walkers [die]

    ask patch (min-pxcor + 1) (max-pycor - 1) [
      sprout-walkers 1 [
        set color magenta
        set shape "person"
        set size 0.7
        set current-reward 0
      ]
    ]

    ;until green patch
    ; perform policy
    let max-steps 100
    let steps 0
    while [success != true and steps < max-steps][

      ask walkers [
        set steps steps + 1
        set heading [policy] of patch-here
        set current-reward current-reward + [reward] of patch-here
        ifelse [pcolor] of patch-ahead 1 != black [
          fd 1
        ] [
          set current-reward current-reward + [reward] of patch-here
        ]
        wait(wait-value)
        if [pcolor] of patch-here = green [
          set current-reward current-reward + [reward] of patch-here
          set success true]
      ]
    ]


    ; calculate total reward
    ; show total reward histogram
    ask walkers[
    set total-reward fput current-reward total-reward
    ]

    set epoch epoch + 1
    tick
  ]
end

to show-values

  if show-value? [
    ask patches with [pcolor = white] [
      set plabel value
    ]
  ]

  if show-policy? [
    ask patches with [pcolor = white] [
      set plabel policy
    ]
  ]

  if show-reward? [
    ask patches with [pcolor = white] [
      set plabel reward
    ]
  ]

end

; to do
; fix grey zone
; and blue zone Qlist
; create best policy perform


to Q-learning

  ; create structure

  ask patches with [pcolor != black] [
    set Qlist [0 0 0 0]
  ]


  ; launch learning process

  let max-epoch number-iterations
  set epoch 0
  let success false

  while [epoch < number-iterations][
    set success false

    ask walkers [die]

    ask patch (min-pxcor + 1) (max-pycor - 1) [

      sprout-walkers 1 [
      set color cyan
      set shape "person"
      set size 0.7
      set current-reward 0
      set Hlist [90 180 270 0]
    ]
  ]

    while [not success] [
    ask walkers[
      wait(wait-value)
    set Qsa 0
    let Qnew 1
    let Qmax 0
    let dirp 0


    let rand random 100
      ifelse rand <= exploration-%
        [
        let dir one-of Hlist
        set dirp position dir Hlist
        set Qmax max Qlist
        set Qnew item dirp Qlist
        ]
    [
      while [Qnew != Qmax]
      [
      let dir one-of Hlist
      set dirp position dir Hlist
      set Qmax max Qlist
      set Qnew item dirp Qlist
      ]
    ]

      set heading item dirp Hlist
      ifelse [pcolor] of patch-ahead 1 = white [
        let r [reward] of patch-ahead 1
        let QQnew max [Qlist] of patch-ahead 1
        set Qnew Qnew + step-size * (r + gamma * QQnew - Qnew)
        set Qnew precision Qnew 2
        set Qlist replace-item dirp Qlist Qnew
          ask patch-ahead 1 [
            set pcolor 8
            wait (wait-value)
            set pcolor white

          ]
        fd 1
        wait(wait-value)
      ][
          ifelse [pcolor] of patch-ahead 1 != black [
            let r [reward] of patch-ahead 1
            let QQnew max [Qlist] of patch-ahead 1
            set Qnew Qnew + step-size * (r + gamma * QQnew - Qnew)
            set Qnew precision Qnew 2
            set Qlist replace-item dirp Qlist Qnew
            fd 1
            set success true
            wait(wait-value)
            ask walkers [die]

          ][
            let r -50
            let QQnew max [Qlist] of patch-here
            set Qnew Qnew + step-size * (r + gamma * QQnew - Qnew)
            set Qnew precision Qnew 2
            set Qlist replace-item dirp Qlist Qnew
            wait(wait-value)
          ]

      ]

    ]
      ask patches with [pcolor = white][
        set plabel map [a -> precision a 1] Qlist
      ]


  ]
    ask walkers [die]
    set epoch epoch + 1
  ]

  ask patches with [pcolor != black] [
    let Qlist-reduced (list)
    if pycor + 1 >= -3 [
      set Qlist-reduced fput item 3 Qlist Qlist-reduced
    ]
    if pxcor - 1 >= -3 [
      set Qlist-reduced fput item 2 Qlist Qlist-reduced
    ]
    if pycor - 1 >= -3 [
      set Qlist-reduced fput item 1 Qlist Qlist-reduced
    ]
    if pxcor + 1 >= -3 [
      set Qlist-reduced fput item 0 Qlist Qlist-reduced
    ]
    ifelse empty? Qlist-reduced [
      set policy 180
    ] [
      let maxQ max Qlist-reduced
      let pos position maxQ Qlist
      let next-patch one-of neighbors4
      
      if pos = 0 [
        set next-patch 90
      ]
      if pos = 1 [
        set next-patch 180
      ]
      if pos = 2 [
        set next-patch 270
      ]
      if pos = 3 [
        set next-patch 0
      ]
      set policy next-patch
    ]
  ]
end

; create simulate button
; to explore this policy
@#$#@#$#@
GRAPHICS-WINDOW
249
10
883
645
-1
-1
89.43
1
10
1
1
1
0
0
0
1
-3
3
-3
3
0
0
1
ticks
30.0

BUTTON
60
37
126
70
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
55
82
227
115
volcano-number
volcano-number
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
60
130
232
163
stone-number
stone-number
0
5
1.0
1
1
NIL
HORIZONTAL

BUTTON
602
656
665
689
NIL
up
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
603
736
668
769
NIL
down
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
670
694
751
727
NIL
to-right
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
526
696
597
729
NIL
to-left
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

SLIDER
62
196
234
229
number-iterations
number-iterations
0
100
10.0
1
1
NIL
HORIZONTAL

BUTTON
76
254
225
287
NIL
set-random-policy
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
79
304
187
337
NIL
show-policy
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
80
355
206
388
NIL
perform-policy
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1160
14
1250
59
NIL
total-reward
17
1
11

MONITOR
1158
67
1342
112
NIL
[current-reward] of walkers
17
1
11

PLOT
1163
132
1567
393
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"reward" 1.0 0 -16777216 true "" "if length total-reward > 0 [plot mean total-reward]"
"max-reward" 1.0 0 -2674135 true "" "if length total-reward > 0 [plot max total-reward]"

BUTTON
66
433
176
466
NIL
show-values
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
70
486
204
519
show-value?
show-value?
1
1
-1000

SWITCH
73
539
212
572
show-policy?
show-policy?
0
1
-1000

SWITCH
76
587
220
620
show-reward?
show-reward?
1
1
-1000

SLIDER
78
639
250
672
wait-value
wait-value
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
80
687
252
720
exploration-%
exploration-%
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
88
731
260
764
step-size
step-size
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
277
692
449
725
gamma
gamma
0
1
0.87
0.01
1
NIL
HORIZONTAL

BUTTON
1163
427
1263
460
NIL
Q-learning
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
