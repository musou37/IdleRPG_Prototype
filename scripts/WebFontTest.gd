extends Node
var frames := 0
func _process(_delta: float) -> void:
	frames += 1
	if frames == 2:
		var tc := load("res://assets/fonts/NotoSansTC-Bold.otf") as FontFile
		var em := load("res://assets/fonts/NotoEmoji.ttf") as FontFile
		tc.allow_system_fallback = false
		em.allow_system_fallback = false
		tc.fallbacks = [em]
	if frames == 5:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://web_font_preview.png")
		get_tree().quit()
