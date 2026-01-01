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
- `move_and_slide()`在這種物理運動中一定要加，角色才會真的移動並和其他實體交互作用。
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