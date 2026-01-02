#import "@template/template:0.1.0": *
#show: doc => document("Godot Note", "B13902066 蔡孟憬", doc)
#show: codly-init.with()

#text(size: 16pt)[1/1]

- 如果角色需要使用重力，標準方法是使用`CharacterBody2D`，利用重力累加在`y`方向速度上來模擬受重力的運動。
```gdscript
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity() * delta
```
- `CharacterBody`中的`is_on_floor()`是偵測角色下方有沒有被碰撞箱阻擋。根據官方文件中對此方法的說明︰
#note()[Returns true if the body collided with the floor on the last call of `move_and_slide()`. Otherwise, returns false. The `up_direction` and `floor_max_angle` are used to determine whether a surface is "floor" or not.]
如果更改`up_direction`（預設向上）或`floor_max_angle`（預設$pi/4$）的值，可以自訂「地板」的判斷條件。
- `move_and_slide()`在這種物理運動中一定要加，角色才會真的移動並和其他實體交互作用。\
#note(title: "Input Handling")[
	#grid(
		columns: (auto, auto),
		[右圖是Godot引擎傳遞InputEvent的順序。在第三個框框Input Event真正傳入節點時，所有有覆寫`_input()`的節點都會收到這個事件。接下來才會輪到GUI、Shortcut、Unhandled Input等等。通常在一般的遊戲操作輸入中不建議使用`_input()`，因為可能會造成玩家在GUI打字，結果被當成Input Event吃掉的現象。實務上通常使用`_unhandled_input()`。	
		
		在每一個階段，Viewport會把事件廣播給有覆寫相對應virtual function的節點（且符合一些條件），直到事件被標記為handled為止。（雖然說是廣播，但實際還是有傳遞順序。）],[
			#figure(
				image("Screenshot from 2026-01-01 19-14-47.png", width: 50%)
			)
		]
	)
]

#pagebreak()

#text(size: 16pt)[1/2]

#block(
	width: auto,
	height: 2em,
	stroke: 1pt,
	inset: 0.5em,
	text(size: 14pt)[#align(center)[實作1︰點擊角色縮放]]
)

使用`_input_event()`實作︰

```gdscript
func _ready():
	# 確保角色可被physics picking
	input_pickable = true
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			scale.x *= 2
			scale.y *= 2
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			scale.x *= 0.5
			scale.y *= 0.5
		
		# 限制縮放倍率在0.25~4之間
		scale = scale.clamp(Vector2.ONE * 0.25, Vector2.ONE * 4)
```
- 為什麼使用`_input_event()`而不是`_unhandled_input()`？

「點中角色」這個行為實際上就是一個Physics Picking Event，它會要求命中某個`CollisionObject`才接收輸入。根據Godot的官方文件︰

#block(
  fill: luma(230),
  inset: 8pt,
  radius: 4pt,
  [If no one wanted the event so far, and Object Picking is turned on, the event is used for object picking. For the root viewport, this can also be enabled in Project Settings. In the case of a 2D scene, conceptually the same happens with `CollisionObject2D._input_event()`.],
)

Physics Picking是在事件未被前面階段消耗時才進行。如果是用`_unhandled_input()`處理，就算游標沒有點到角色，也會進行縮放，因此需要做額外的命中判斷。

- Scaling的原理

Godot中的scale是受節點父子關係影響的。當更改了一個節點的scale，那麼它的子節點們在世界中的大小都會隨之變化。簡而言之，
$ "global transform = local transform"times"parent transform" $
因此，當縮放施加在`CharacterBody2D`上，它的子節點（這裡是`Sprite2D`和`CollisionShape2D`）也會跟著被縮放。
