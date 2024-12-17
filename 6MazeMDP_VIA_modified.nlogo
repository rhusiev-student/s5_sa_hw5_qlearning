globals[
  total-reward
  actions
  delta
  success-ratio
  try-number
  success-number
  epoch
  walkable-patches
]
breed[walkers walker]

patches-own [
  reward
  value
  temp
  policy
  u
  active?

  teleport-target-patch
  class
]

walkers-own [
  current-reward
  current-action

]


to setup
 clear-all
 reset-ticks


  set actions ["up" "left" "down" "right"]
  ask patches with [abs pxcor < max-pxcor and abs pycor < max-pycor] [
    set pcolor white
    set plabel "-1"
    set plabel-color black
    set reward -1
    set value 0
    set class "path"
  ]

  ask patch (min-pxcor + 1) (max-pycor - 1) [
    set pcolor red
    set plabel "IN"
    set class "start"
    sprout-walkers 1 [
      set color magenta
      set shape "person"
      set size 0.7
    ]
  ]

  ask patch (max-pxcor - 1) (min-pycor + 1) [
    set pcolor green
    set plabel "OUT +100"
    set reward 100
    set value 100
    set class "finish"
  ]

  ask patch (min-pxcor + 1) (max-pycor - 2) [
    set pcolor grey
    set plabel "STOP +2"
    set reward 2
    set value 2
    set class "stop"
  ]

  ask n-of volcano-number patches with [pcolor = white] [
    sprout 1 [
      set shape "fire"
      set size 0.7
    ]
    set pcolor pink
    set plabel-color black
    set plabel "-50"
    set reward -50
    set value -50
    set class "volcano"
  ]

  ask n-of stone-number patches with [pcolor = white] [
    set pcolor black
    set class "rock"
  ]

  ask n-of teleports-number patches with [pcolor = white][
    set pcolor violet
    set class "teleport"
    set teleport-target-patch nobody

    sprout 1 [
      set shape "pentagon"
      set size 0.7
      set color white
    ]
  ]

  ask patches with [class = "teleport"][
    if teleport-target-patch = nobody[
    let my-target one-of patches with [class = "teleport" and teleport-target-patch = nobody]
    set teleport-target-patch my-target
    let me self
    ask my-target[
      set teleport-target-patch me
    ]
    ]
  ]

  ask n-of wind-number patches with [pcolor = white][
    set class "wind"
    set pcolor gray
    sprout 1 [
      set shape "arrow"
      set size 0.7
      set heading 90
      set color blue
    ]
  ]

  ask n-of barrels-number patches with [pcolor = white][
    set class "barrel"
    set pcolor lime
    sprout 1 [
      set shape "box"
      set size 0.7
    ]
  ]

  ask n-of frozen-number patches with [pcolor = white and count neighbors with [pcolor = white] = 8][
    set class "ice-center"
    set pcolor blue
    set reward 0
    ask neighbors [
      set pcolor blue
      set reward 0
    ]

    sprout 1 [
      set shape "target"
      set size 0.7
    ]
  ]

  set walkable-patches patches with [class = "path" or class = "wind" or pcolor = blue or class = "teleport"]
  draw-lines


end

to set-value-zero
  ask walkable-patches[
    set value 0
  ]
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

  ask walkable-patches [
    ifelse count neighbors4 with [pcolor = green] > 0 [
      set policy towards one-of neighbors4 with [pcolor = green]
      show policy
    ][
      set policy towards one-of neighbors4 with [class = "path"]
    ]

  ]
end


to show-values

  if show-policy? [
    ask walkable-patches [
      set plabel policy
    ]
  ]

  if show-reward? [
    ask walkable-patches [
      set plabel reward
    ]
  ]

  if show-value? [
    ask walkable-patches [
      set plabel precision value 2
    ]
  ]

end

to value-iteration
  set delta 10000

   while [delta > epsilon * (1 - gamma) / gamma][

    set delta 0

    let s -1000
    let best-action 0
    let v 0
    ask walkable-patches [
      set temp value
    ]

    ask walkable-patches [
      set s -1000
      foreach actions [
        a ->
        set v 0
        set v get-value-from-action a
        ;set v reward + gamma * v
        if v > s [
          set policy a
          set s v
        ]

      ]
      set temp s
    ]


   ask walkable-patches [
      if abs (temp - value) > delta [
        set delta abs (temp - value)
   ]

   set value temp
  ]

  show-values
  output-print delta
    tick
  ]

end


to value-iteration-step

  let s -1000
  let best-action 0
  let v 0
  ask patches with [pcolor = white] [
    set temp value
  ]

  ask patches with [pcolor = white] [
    output-print word "Calculating value for patch" self
   set s -1000
    foreach actions [
      a ->
      set v 0
      output-print word "for action " a
      set v main-prob * (get-value-from-action a)
      ; remove a from actions
      ; rest-actions
      let rest-actions remove-item (position a actions) actions
      foreach rest-actions [
        b ->
        set v v + ((1 - main-prob) / 3 ) * (get-value-from-action b)
      ]



      output-print word "value is " v
      set v reward + gamma * v
      if v > s [
        set policy a
        set s v
      ]


    ]

    output-print s
    set temp s
  ]

  ask patches with [pcolor = white] [
    set value temp
  ]

  show-values
end

to find-best-policy
  let f false

  ask patches with [pcolor = green][
     if count neighbors4 with [pcolor = red] > 0 [
      set f true
    ]
  ]

  if f [
    ask patches [set active? false]
  ]


  ask patches with [pcolor = blue][
    if count neighbors4 with [pcolor = red] = 0 [
      ask max-one-of neighbors4 with [class = "path"][value] [
        set pcolor red
        set active? true
      ]
    ]
  ]

  ask patches with [active? = true][
    set active? false
    let temp-value [value] of max-one-of neighbors4 with [class = "path"] [value]
     ask max-one-of neighbors4 with [class = "path"][value] [
      if value >= temp-value [
        set pcolor red
        set active? true
      ]
     ]


  ]

end

to launch-test

  let max-epoch number-iterations
  set epoch 0
  let success false
  ask patches with [class = "finish"][
    set value 10000
  ]

  while [epoch < number-iterations][
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

    while [success != true] [
      ask walkers [
        let temp-value [value] of max-one-of neighbors4 [value]

        ifelse random-float 1 < main-prob [
          set heading towards one-of neighbors4 with [value = temp-value]
        ][

          set heading towards one-of neighbors4 with [pcolor != black]
        ]

        let volcano-probability (count neighbors4 with [class = "volcano"]) * prob-fall

        if random-float 1 < volcano-probability [
          set heading towards one-of neighbors4 with [class = "volcano"]
          set success true ;restart
          set try-number try-number + 1
          set total-reward total-reward + current-reward
        ]

        ;ice
        if [pcolor] of patch-ahead 1 = blue and [pcolor] of patch-here = blue[
          let slip-probability (1 - volcano-probability - steady-ice-probability)
          show "Slip probability:"
          show slip-probability

          if random-float (1 - volcano-probability) < slip-probability [
            show "Slipping on ice"

            let slip-patch nobody
            ask patch-here[
              let center-patch one-of patches in-radius (sqrt 2) with [class = "ice-center"]
              let ice-patches other patches with [pcolor = blue and distance center-patch = sqrt 2]
              set slip-patch one-of ice-patches
            ]

            setxy [pxcor] of slip-patch [pycor] of slip-patch
          ]
        ]

        fd 1

        ;teleports
        if [class] of patch-here = "teleport"[
          show "Teleporting"
          let teleport-endpoint [teleport-target-patch] of patch-here
          setxy ([pxcor] of teleport-endpoint + 1) ([pycor] of teleport-endpoint)
        ]

        ;wind
        if [class] of patch-here = "wind"[
          if random-float (1 - volcano-probability) < wind-glide-probability[
            show "Gliding on wind"
            setxy ([pxcor] of patch-here + 1) [pycor] of patch-here
          ]
        ]

        wait(0.2)
        set current-reward current-reward + reward

      if [pcolor] of patch-here = green [
          set total-reward total-reward + current-reward
          set epoch epoch + 1
          set success-number success-number + 1
          set try-number try-number + 1
          set success true]
      ]
      tick
    ]
  ]

end

to-report compute-patch-value [current-patch target-patch volcano-probability] ;processes the added obstacles
  ;teleports
  if [class] of current-patch = "teleport"[
    let spawn-point patch ([pxcor] of teleport-target-patch + 1) ([pycor] of teleport-target-patch )
    let target-value (1 - volcano-probability) * ([value] of spawn-point + gamma * ([reward] of spawn-point + teleportation-cost))
    report target-value
  ]

  ;wind areas
  if [class] of current-patch = "wind"[
    let normal-value (1 - volcano-probability - wind-glide-probability) * ([value] of target-patch + gamma * [reward] of target-patch)

    let target-value 0
    let push-destination-patch patch (pxcor + 1)(pycor)
    set target-value wind-glide-probability * ([value] of push-destination-patch + gamma * [reward] of push-destination-patch)
    report target-value + normal-value
  ]

  ;ice areas
  if [pcolor] of current-patch = blue and [pcolor] of target-patch = blue[
    let normal-value steady-ice-probability * ([value] of target-patch + gamma * [reward] of target-patch)

    let center-patch one-of patches in-radius (sqrt 2) with [class = "ice-center"]
    let ice-patches patches with [pcolor = blue and distance center-patch = sqrt 2]

    let value-sum 0

    ask ice-patches[
      set value-sum value-sum + (value + gamma * reward)
    ]

    let slippery-value (1 - steady-ice-probability - volcano-probability) / 4 * (value-sum)

    report normal-value + slippery-value
  ]

  ;simple step
  report (1 - volcano-probability) * ([value] of target-patch + gamma * [reward] of target-patch)

end

to-report get-value-from-action [action]

  let volcano-value-component 0
  let volcano-probability 0

  if count neighbors4 with [class = "volcano"] > 0 [
    set volcano-probability (count neighbors4 with [pcolor = pink]) * prob-fall
    set volcano-value-component volcano-probability * (-50) * gamma
  ]

  let me self
  let num-distant-barrels count patches with [class = "barrel" and (distance me) <= barrel-radius and (distance me) > 1 ]
  let num-close-barrels count patches with [class = "barrel" and (distance me) <= 1]
  let poison-effect (num-close-barrels * (-100) * 0.25 + num-distant-barrels * (-100) * 0.1) * gamma

  if ((action = "left") and (check-constraints (pxcor - 1) pycor) = true)
  [
    let target-patch patch (pxcor - 1) pycor

    report (compute-patch-value self target-patch volcano-probability ) + volcano-value-component + poison-effect ;no need to include the probability of getting poisoned in the formula as getting poisoned does not get the agent into a different state
  ]

  if ((action = "right") and (check-constraints (pxcor + 1) pycor))
  [
    let target-patch patch (pxcor + 1) pycor

    report (compute-patch-value self target-patch volcano-probability ) + volcano-value-component + poison-effect ;no need to include the probability of getting poisoned in the formula as getting poisoned does not get the agent into a different state
  ]

  if ((action = "up") and (check-constraints pxcor  (pycor + 1)))
  [
    let target-patch patch pxcor (pycor + 1)

    report (compute-patch-value self target-patch volcano-probability ) + volcano-value-component + poison-effect ;no need to include the probability of getting poisoned in the formula as getting poisoned does not get the agent into a different state
  ]

  if ((action = "down") and (check-constraints pxcor  (pycor - 1)))
  [
    let target-patch patch pxcor (pycor - 1)

    report (compute-patch-value self target-patch volcano-probability ) + volcano-value-component + poison-effect ;no need to include the probability of getting poisoned in the formula as getting poisoned does not get the agent into a different state
  ]

  report (1 - volcano-probability) * (value * gamma * reward) + volcano-value-component + poison-effect ;no need to include the probability of getting poisoned in the formula as getting poisoned does not get the agent into a different state

end

to clear-values

end

to Q-learning


end
@#$#@#$#@
GRAPHICS-WINDOW
329
2
1121
795
-1
-1
37.33333333333334
1
10
1
1
1
0
0
0
1
-10
10
-10
10
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
0.0
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
10
10.0
1
1
NIL
HORIZONTAL

BUTTON
1690
615
1753
648
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
1691
695
1756
728
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
1758
653
1839
686
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
1614
655
1685
688
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

MONITOR
1598
274
1701
319
Avrage reward
total-reward / try-number
2
1
11

MONITOR
1526
217
1635
262
current-reward
[current-reward] of one-of walkers
17
1
11

SLIDER
1413
540
1585
573
gamma
gamma
0
1
0.53
0.01
1
NIL
HORIZONTAL

SWITCH
1582
363
1716
396
show-value?
show-value?
0
1
-1000

BUTTON
1625
507
1746
540
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
1581
404
1720
437
show-policy?
show-policy?
1
1
-1000

BUTTON
1626
555
1775
588
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

SWITCH
1583
444
1727
477
show-reward?
show-reward?
1
1
-1000

BUTTON
1255
25
1411
58
NIL
value-iteration-step
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
1452
16
1786
202
13

SLIDER
55
546
227
579
prob-fall
prob-fall
0
1
0.05
0.01
1
NIL
HORIZONTAL

BUTTON
1255
151
1388
184
NIL
find-best-policy
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
1418
589
1590
622
epsilon
epsilon
0
0.5
0.08
0.01
1
NIL
HORIZONTAL

BUTTON
1255
65
1378
98
NIL
value-iteration
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
1254
265
1357
298
NIL
launch-test
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
1252
191
1401
251
number-iterations
10.0
1
0
Number

PLOT
1244
313
1444
463
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot delta"

BUTTON
1763
511
1887
544
NIL
set-value-zero
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
1485
275
1591
320
success ratio %
success-number / try-number * 100
2
1
11

BUTTON
1253
493
1353
526
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

MONITOR
1503
356
1560
401
NIL
epoch
17
1
11

SLIDER
1413
497
1585
530
main-prob
main-prob
0
1
0.9
0.01
1
NIL
HORIZONTAL

BUTTON
1790
568
1898
601
NIL
clear-values\n
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
183
228
216
teleports-number
teleports-number
0
16
0.0
2
1
NIL
HORIZONTAL

SLIDER
56
232
228
265
wind-number
wind-number
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
57
276
229
309
barrels-number
barrels-number
0
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
56
327
228
360
frozen-number
frozen-number
0
7
0.0
1
1
NIL
HORIZONTAL

SLIDER
56
399
248
432
teleportation-cost
teleportation-cost
-100
-1
-1.0
1
1
NIL
HORIZONTAL

SLIDER
56
453
268
486
wind-glide-probability
wind-glide-probability
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
54
502
269
535
steady-ice-probability
steady-ice-probability
0
1
0.88
0.01
1
NIL
HORIZONTAL

SLIDER
56
595
228
628
barrel-radius
barrel-radius
2
5
4.0
1
1
NIL
HORIZONTAL

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
