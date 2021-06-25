extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    yield(VisualServer, "frame_post_draw")
    var image : Image = .get_texture().get_data()
    image.flip_y()
    image.save_png("res://path_to_save.png")
