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