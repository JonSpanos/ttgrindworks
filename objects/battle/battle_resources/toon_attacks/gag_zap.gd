extends ToonAttack
class_name GagZap

const FALLBACK_THROW_SFX := preload('res://audio/sfx/battle/gags/throw/AA_pie_throw_only.ogg')

@export var model: PackedScene
@export var scale: float = 1.0
@export var splat_color: Color = Color.WHITE
@export var splat_sfx: AudioStream
@export var present_sfx: AudioStream
@export var throw_sfx: AudioStream
@export var miss_sfx: AudioStream

func action():
	var target = targets[0]
	if not target.drenched: # If target not drenched
		return
	
	user = Util.get_player()
	var cog: Cog = targets[0]
	user.face_position(cog.global_position)
	var throwable = model.instantiate()
	user.toon.right_hand_bone.add_child(throwable)
	throwable.scale *= scale
	user.set_animation('pie_throw')
	manager.s_focus_char.emit(user)
	if present_sfx:
		AudioManager.play_sound(present_sfx)

	if action_name == "Birthday Cake":
		throwable.get_node("AnimationPlayer").play("candles")

	await manager.sleep(2.545)
	if not throw_sfx:
		AudioManager.play_sound(FALLBACK_THROW_SFX)
	else:
		AudioManager.play_sound(throw_sfx)
	await manager.sleep(0.1)
	throwable.top_level = true
	var throw_tween = manager.create_tween()
	throw_tween.tween_property(throwable, 'global_position', cog.head_node.global_position, 0.25)
	
	# Roll for accuracy
	var hit: bool = manager.roll_for_accuracy(self) or cog.lured
	
	if hit:
		await throw_tween.finished
		throw_tween.kill()
		user.face_position(manager.battle_node.global_position)
		manager.s_focus_char.emit(cog)
		throwable.queue_free()
		print(targets)
		for _cog in targets:
			if not _cog.drenched:
				break
			manager.s_focus_char.emit(_cog)
			var immune := get_immunity(_cog)
			
			if not immune:
				var throw_damage: int = manager.affect_target(_cog, 'hp', damage, false)
			else:
				manager.battle_text(_cog, "IMMUNE")
		
			var splat = load("res://objects/battle/effects/splat/splat.tscn").instantiate()
			splat.modulate = splat_color
			_cog.head_node.add_child(splat)
			if splat_sfx:
				AudioManager.play_sound(splat_sfx)
			
			if not immune:
				if not _cog.lured:
					_cog.set_animation('pie-small')
				else:
					manager.knockback_cog(_cog)
				
		
			await manager.barrier(_cog.animator.animation_finished, 4.0)
			
		await manager.check_pulses(targets)
	else:
		manager.s_focus_char.emit(cog)
		cog.set_animation('sidestep-left')
		if miss_sfx:
			AudioManager.play_sound(miss_sfx)
		await throw_tween.finished
		throw_tween.kill()
		throwable.queue_free()
		manager.battle_text(cog, "MISSED")
		await cog.animator.animation_finished

func get_stats() -> String:
	var string := "Damage: " + get_true_damage() + "\n"\
	+ "Affects: "
	match target_type:
		ActionTarget.SELF:
			string += "Self"
		ActionTarget.ENEMIES:
			string += "All Cogs"
		ActionTarget.ENEMY and ActionTarget.ZAP:
			string += "One Cog"
		ActionTarget.ENEMY_SPLASH:
			string += "Three Cogs"

	
	string += "\nPool Damage: " + str(int(get_true_damage()) * .9).pad_decimals(0)

	return string
