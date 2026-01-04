#import "@template/template:0.1.0": *
#show link: set text(fill: blue)
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

#link("https://github.com/cmj0415/Godot-practice/commit/b7dd308f1b7d0f13be7a34ef968b6a6032686f47#diff-e0c9754ebacfcbb51ab5610ccae23d909248a6c9496c6335712218781bd27a00")[完整程式]

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

#pagebreak()

#block(
	width: auto,
	height: 2em,
	stroke: 1pt,
	inset: 0.5em,
	text(size: 14pt)[#align(center)[實作2︰按住左鍵拖曳角色]]
)

#link("https://github.com/cmj0415/Godot-practice/commit/f67004e57aded737e4073d69d5ba6d41ab03668d")[完整程式]

這裡我們會稍微改變一下前面判斷縮放的方法。因為拖曳時同樣是先按下了左鍵，因此會導致拖曳時角色跟著放大。我們使用`pressed_on_me`和`dragging`兩個變數記錄角色「是否被點」和「是否在拖曳狀態中」。如果角色「有被點」且「不是在拖曳狀態中」才進行縮放。

- 拖曳的判斷
我們使用拖曳的長度是否超過某個閾值來判斷是否在拖曳狀態中（程式中使用`moved_distance`來記錄）。因為`_input_event()`只處理游標「命中」當下的事件，因此在後續的拖曳過程中，應交給`_unhandled_input()`來處理這段時間內的事件。大致邏輯架構如下（只寫出拖曳所需邏輯，其他請見完整程式碼）︰

```gdscript
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton：
		if event.pressed:
			pressed_on_me = true
			dragging = false
			moved_distance = 0.0
			drag_offset_global = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		else:
			# 處理放開時的行為，如判斷是否要進行縮放
				
func _unhandled_input(event):	
	if not pressed_on_me:
		return		
	if event is InputEventMouseMotion:
		moved_distance += event.relative.length()		
		if not dragging and moved_distance >= drag_threshold:
			dragging = true
		if dragging:
			global_position = get_global_mouse_position() + drag_offset_global
			get_viewport().set_input_as_handled()
```
如果需要拖曳時不受重力影響，在`_physics_process()`內加上`if dragging: return`即可。
- 角色位置的計算
`InputEventMouseMotion`中的`relative`屬性代表游標相對於上一幀的偏移量。程式第6行計算的是「點擊當下」，角色位置相對於游標位置的偏移量。因此，當拖曳中每一幀要更新角色位置時，即是用當下的游標位置加上偏移量。
#note()[
	只有在滑鼠「按下」和「放開」時事件的類型是`InputEventMouseButton`，拖曳中都是`InputEventMouseMotion`。按下時`event.pressed`為`true`，放開時為`false`。
]

#text(size: 16pt)[1/4]
#block(
	width: auto,
	height: 2em,
	stroke: 1pt,
	inset: 0.5em,
	text(size: 14pt)[#align(center)[實作3︰雙擊切換角色型態]]
)
在我們的程式中，單擊是有功能的。因此，如果玩家要使用雙擊，我們不能讓單擊的功能在玩家點第一下時就執行。雖然Godot有`event.double_click`來判斷是否是雙擊事件，但卻沒有無法在玩家點擊第一下時預測到這到底是單擊事件還是雙擊事件。舉例來說，以下的程式碼會造成錯誤的執行結果︰
```gdscript
if event.double_click:
	_on_double_click()
else:
	_on_single_click()
```
這會造成雙擊的第一下也執行`_on_single_click()`。

- 雙擊的判斷條件
我們將雙擊定義為︰
+ 兩次點擊的時間間隔不超過`double_click_time`
+ 兩次點擊的距離間隔不超過`double_click_dist`
- 區分單擊與雙擊
由於不能在點擊第一下時就執行`_on_single_click()`，因此需要有一個計時器來「延遲執行」。我們需要用一些變數記錄資訊︰
+ `waiting_for_second`記錄是否正在等待可能的第二次點擊
+ `last_click_time`記錄上一次點擊的時間
+ `last_click_pos`記錄上一次點擊的位置

大致邏輯如下（只寫出區分單擊與雙擊的邏輯，其他請見完整程式碼）︰
```gdscript
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return	

		# 放開時才做！
		if not event.pressed: 
			var now := Time.get_ticks_msec()
			if waiting_for_second:
				if now - last_click_time <= double_click_time \
					and event.position.distance_to(last_click_pos) <= double_click_dist:
					waiting_for_second = false
					_on_double_click()
					get_viewport().set_input_as_handled()
					return
				else:
					last_click_time = now
					last_click_pos = event.position
					waiting_for_second = true
			else:
				last_click_time = now
				last_click_pos = event.position
				waiting_for_second = true
			get_viewport().set_input_as_handled()
		
func _process(delta):
	if not waiting_for_second:
		return
	var now := Time.get_ticks_msec()
	if now - last_click_time > double_click_time:
		_on_single_click()
		waiting_for_second = false
```
這裡我們使用會被逐幀呼叫的`_process`當作計時器，當一個點擊還在等待第二次點擊，但時間已經超過雙擊的限制，那麼就執行`_on_single_click()`。