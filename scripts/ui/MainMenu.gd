extends Control
## MainMenu.gd — 主菜单脚本
## 输入世界描述 → 生成世界蓝图 → 进入游戏世界

@onready var _world_input: LineEdit = $CenterPanel/InputContainer/WorldInput
@onready var _generate_button: Button = $CenterPanel/InputContainer/GenerateButton
@onready var _continue_button: Button = $CenterPanel/ContinueButton
@onready var _exit_button: Button = $CenterPanel/ExitButton
@onready var _status_label: Label = $CenterPanel/StatusLabel

const AIClientClass = preload("res://scripts/ai/AIClient.gd")
const ValidatorClass = preload("res://scripts/world/WorldBlueprintValidator.gd")

var _ai_client = null
var _is_generating: bool = false


func _ready() -> void:
	# 初始化 AI Client
	_ai_client = AIClientClass.new()
	
	# 连接信号
	if _generate_button:
		_generate_button.pressed.connect(_on_generate_pressed)
	if _continue_button:
		_continue_button.pressed.connect(_on_continue_pressed)
	if _exit_button:
		_exit_button.pressed.connect(_on_exit_pressed)
	if _world_input:
		_world_input.text_submitted.connect(_on_text_submitted)
	
	# 设置状态
	_set_status("")


func _on_text_submitted(text: String) -> void:
	_on_generate_pressed()


func _on_generate_pressed() -> void:
	if _is_generating:
		return
	
	var world_description = ""
	if _world_input:
		world_description = _world_input.text.strip_edges()
	
	if world_description == "":
		_set_status("请输入世界描述。")
		return
	
	_is_generating = true
	_set_status("正在生成世界...请等待片刻...")
	
	if _generate_button:
		_generate_button.disabled = true
	
	# 调用 AI 生成世界蓝图
	await _generate_world(world_description)


func _on_continue_pressed() -> void:
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.has_save():
		_set_status("没有找到可继续的存档。")
		return
	var result = save_manager.load_game()
	if not result.get("ok", false):
		_set_status("读取存档失败。")
		return
	_set_status("游戏已读取，正在进入世界...")
	await get_tree().create_timer(0.5).timeout
	_enter_game_world()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _generate_world(description: String) -> void:
	# 步骤 1: 调用 AI
	var blueprint = await _ai_client.generate_world_blueprint(description)
	
	if blueprint.is_empty():
		_set_status("生成失败，请重试。")
		_is_generating = false
		if _generate_button:
			_generate_button.disabled = false
		return
	
	# 步骤 2: 校验世界蓝图
	var validator = ValidatorClass.new()
	var validation_result = validator.validate(blueprint)
	
	if validation_result.errors.size() > 0:
		# 使用修复后的蓝图
		blueprint = validation_result.fixed_blueprint
		GameLog.add_warning("世界蓝图需修复: %d 处" % validation_result.errors.size())
		for err in validation_result.errors:
			GameLog.add_warning("  " + err)
	
	# 步骤 3: 检查是否使用了 Mock
	if ConfigManager.get_ai_provider() == "mock" or validation_result.errors.size() > 0:
		_set_status("云端 AI 暂不可用，已使用本地默认世界生成。")
	else:
		_set_status("世界生成成功！正在进入世界...\n" + blueprint.get("world_name", "未知世界"))
	
	# 步骤 4: 保存到 WorldState
	WorldState.set_world_blueprint(blueprint)
	
	# 步骤 5: 延迟切换到 GameWorld
	await get_tree().create_timer(1.5).timeout
	_enter_game_world()


func _enter_game_world() -> void:
	# 切换到 GameWorld 场景
	var scene_path = "res://scenes/GameWorld.tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		_set_status("错误: 找不到 GameWorld.tscn 场景文件！")
		_is_generating = false
		if _generate_button:
			_generate_button.disabled = false


func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text
