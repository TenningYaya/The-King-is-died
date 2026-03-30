# audio_manager.gd
extends Node

# 预加载你的老祖 BGM 资源
var bgm_resource = preload("res://audio/Ancestor’s Sight.mp3")
var player: AudioStreamPlayer
@onready var _master_bus_index = AudioServer.get_bus_index("Master")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 动态创建一个播放器并添加到全局节点下
	player = AudioStreamPlayer.new()
	add_child(player)
	
	# 设置音乐资源
	player.stream = bgm_resource
	# 开启循环（如果你之前没在导入设置里开，这里可以用代码补一下）
	if player.stream is AudioStreamMP3:
		player.stream.loop = true
		
	# 设置音量（建议稍微低一点，比如 -12）
	player.volume_db = -12.0
	
	# 自动播放
	player.play()
	
	if GamedataManager.is_loading_save:
		var data = GamedataManager.get_data_for_node(self.name)
		if not data.is_empty():
			var saved_db = data.get("master_volume_db", 0.0)
			AudioServer.set_bus_volume_db(_master_bus_index, saved_db)
			# 同步到内存，防止 UI 没更新
			GamedataManager.master_volume_db = saved_db
			print("[MusicManager] 音量已恢复: %.1f dB" % saved_db)

# 以后你想在特定剧情停掉音乐，可以调用这个
func stop_music():
	player.stop()

# 以后想换战斗音乐，可以调用这个
func play_music(new_stream: AudioStream):
	if player.stream == new_stream: return
	player.stream = new_stream
	player.play()

func get_save_data() -> Dictionary:
	return {
		"master_volume_db": AudioServer.get_bus_volume_db(_master_bus_index)
	}
