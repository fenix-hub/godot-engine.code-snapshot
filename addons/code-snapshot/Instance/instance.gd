tool
class_name CodeSnapshotInstance
extends Control

onready var viewport_container : ViewportContainer = $VSplitContainer/ViewportContainer
onready var viewport : Viewport = viewport_container.get_child(0)
onready var snapshot_container : ColorRect = viewport.get_node("Background")
onready var settings_container : VBoxContainer = $VSplitContainer/Settings

onready var script_container : PanelContainer = snapshot_container.get_node("ScriptContainer")
onready var script_edit : TextEdit = script_container.get_node("VBox/ScriptEdit")
onready var template_menu : PopupMenu = settings_container.get_node("Template/TemplateMenu").get_popup()
onready var colors_list : VBoxContainer = settings_container.get_node("Colors/ColorsList")
onready var properties_list : VBoxContainer = settings_container.get_node("Properties/PropertiesList")
onready var from : LineEdit = settings_container.get_node("Properties/PropertiesList/from_line_to_line/from")
onready var to : LineEdit = settings_container.get_node("Properties/PropertiesList/from_line_to_line/to")
onready var script_name : LineEdit = settings_container.get_node("ScriptName/LineEdit")
onready var save : FileDialog = $Save

var script_editor : ScriptEditor
var editor_settings : EditorSettings

var template_dir : String = "res://addons/code-snapshot/godot-syntax-themes/"
var templates : PoolStringArray
var template_file : String = "Darcula"

var keywords : Array = ["self", "if", "else", "elif", "or", "and", "yield","func", "onready", "export", "var", "tool", "extends", "void", "null", "true", "false", "class_name", "print", "return", "pass", "match", "in", "define", "const"]
var types : PoolStringArray = ["bool","int","float","String","Vector2","Vector3","Array","Dictionary","Color", "PoolStringArray","PoolIntArray","PoolRealArray"]
var from_line_to : Array = [-1, -1]
var lines_count_as_min_size : bool = true
var exporting_extension : String 
var path_to_save : String

func set_editor_settings(settings : EditorSettings):
    editor_settings = settings

func set_script_editor(editor : ScriptEditor):
    script_editor = editor
    script_editor.connect("editor_script_changed", self, "_on_script_changed")
    _on_script_changed(script_editor.get_current_script())

func hide_nodes():
    colors_list.hide()
    properties_list.hide()

func _ready() -> void:
    yield(get_tree(),"idle_frame")
#	viewport.set_process_input(true)
    script_edit.set_text("")
    template_menu.connect("index_pressed", self, "_on_index_pressed")
    script_name.connect("text_changed", self, "_on_text_changed")
    hide_nodes()
    load_templates()
    if script_editor != null : _on_script_changed(script_editor.get_current_script())

func load_templates():
    templates = []
    template_menu.clear()
    var dir = Directory.new()
    if dir.open(template_dir) == OK:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir() and file_name.get_extension() == "tet":
                templates.append(file_name.get_basename())
                template_menu.add_item(file_name.get_basename())
            file_name = dir.get_next()
    else:
            print("An error occurred when trying to access the path.")
    _on_index_pressed(0)

func _on_index_pressed(index : int):
    apply_template(templates[index])
    $VSplitContainer/Settings/Template/TemplateMenu.set_text("> "+templates[index])

func apply_template(template : String):
    script_edit.clear_colors()
    var config = ConfigFile.new()
    var err = config.load(template_dir+"%s.tet"%template)
    if err == OK: # If not, something went wrong with the file loading
        set_script_box_color(config.get_value("color_theme", "background_color"))
        for setting in config.get_section_keys("color_theme"):
            if setting == "gdscript/function_definition_color" : 
                add_function_definition_color(config.get_value("color_theme",setting))
                set_node_color("function_definition_color", config, "gdscript/")
            if setting == "keyword_color": add_keywords_color(config.get_value("color_theme",setting))
            if setting == "comment_color": add_comment_color(config.get_value("color_theme", setting))
            if setting == "string_color" : add_string_color(config.get_value("color_theme", setting))
            if setting == "engine_type_color" : add_engine_type_color(config.get_value("color_theme",setting))
            if setting == "gdscript/node_path_color" : add_node_path_color(config.get_value("color_theme",setting))
            if setting == "text_color" : set_text_color(config.get_value("color_theme",setting))
            script_edit.set("custom_colors/"+setting, config.get_value("color_theme",setting))
            set_node_color(setting, config)

func set_node_color(setting : String, config : ConfigFile, category : String = ""):
    if colors_list.get_node_or_null("%s/Color"%setting) != null : colors_list.get_node_or_null("%s/Color"%setting).color = config.get_value("color_theme",category+setting)

func add_node_path_color(color : Color):
    script_edit.add_color_region("$","", color, false)

func add_engine_type_color(color : Color):
    for type in types: 
        script_edit.add_keyword_color(type, color)
    for type in ClassDB.get_class_list():
        script_edit.add_keyword_color(type, color)

func add_function_definition_color(color : Color):
    script_edit.add_color_region("func ","", color)

func set_script_edit_size(size : Vector2):
    script_container.rect_size = size

func set_background_color(color : Color):
    snapshot_container.color = color

# Script Box Color
func set_script_box_color(color : Color):
    script_container.get("custom_styles/panel").set("bg_color", color)
    set_script_background_color(color)

func get_script_box_color() -> String:
    return "#"+script_container.get("custom_styles/panel").get("bg_color").to_html(false)
# ................

func set_member_variable_color(color : Color):
    script_edit.set("custom_colors/member_variable_color", color)

func set_function_color(color : Color):
    script_edit.set("custom_colors/function_color", color)

# Script Background color .....
func set_script_background_color(color : Color):
    script_edit.set("custom_colors/background_color", color)

func get_script_background_color() -> String:
    return "#"+script_edit.get("custom_colors/background_color").to_html(false)
# ..............

func set_number_color(color : Color):
    script_edit.set("custom_colors/number_color", color)

# Text Color .....
func set_text_color(color : Color):
    script_edit.set("custom_colors/font_color", color)

func get_text_color() -> String:
    return "#"+script_edit.get("custom_colors/font_color").to_html(false)
# ................

func add_keywords_color(color : Color):
    for keyword in keywords:
        script_edit.add_keyword_color(keyword,color)

func add_comment_color(color : Color):
    script_edit.add_color_region("#","",color,true)

func add_string_color(color : Color):
    script_edit.add_color_region('"','"',color,false)

func set_from_line_to(from : int, to : int):
    from_line_to = [from, to]

func _on_text_changed(text : String) -> void:
    script_container.get_node("VBox/TopBar/ScriptName").set_text(text)
    

func set_script_name(_name : String) -> void:
    script_name.set_text(_name)
    script_container.get_node("VBox/TopBar/ScriptName").set_text(_name)

var current_script : Script

func _on_script_changed(script : Script):
    if script == null or script_edit == null: return
    current_script = script
    var code : String = script.get_source_code()
    var code_array : Array = code.c_unescape().split("\n")
    code = PoolStringArray(code_array.slice(from_line_to[0]-1 if from_line_to[0] != -1 and from_line_to[0] < code_array.size()-1 else 0, from_line_to[1]-1 if from_line_to[1] != -1 and from_line_to[1] < code_array.size()-1 else code_array.size()-1)).join("\n")
    script_edit.set_text(code)
    set_script_name(script.resource_path.get_file())
    change_frame_min_size()

func change_frame_min_size():
    if lines_count_as_min_size:
        script_edit.rect_min_size.y = script_edit.get_line_count() * (editor_settings.get_setting("interface/editor/code_font_size") + 6) if script_edit.get_line_count() <= 35 else 132
        viewport_container.rect_min_size.y = script_edit.rect_min_size.y + 168
    else:
        script_edit.rect_min_size.y = 0
        viewport_container.rect_min_size.y = 300

func _on_ColorsBtn_toggled(button_pressed : bool):
    colors_list.visible = button_pressed
    if button_pressed: $VSplitContainer/Settings/Colors/ColorsBtn.set_text("v Colors")
    else: $VSplitContainer/Settings/Colors/ColorsBtn.set_text("> Colors")

func _on_PropertiesBtn_toggled(button_pressed : bool):
    properties_list.visible = button_pressed
    if button_pressed: $VSplitContainer/Settings/Properties/PropertiesBtn.set_text("v Properties")
    else: $VSplitContainer/Settings/Properties/PropertiesBtn.set_text("> Properties")




func _on_export_confirmed(path : String):
    path_to_save = path

func _on_Save_hide():
    match exporting_extension:
        "png":
            var image : Image = viewport.get_texture().get_data()
            image.flip_y()
            image.save_png(path_to_save)
        "html":
            var file : File = File.new()
            file.open(path_to_save, File.WRITE)
            var content : String = '<!DOCTYPE html>\n'
            content+='<pre>\n<code class="gdscript-codeblock">\n'
            content+=script_edit.text+"\n"
            content+='</code>\n</pre>'
            file.store_line(content)
            file.close()


func _on_autowrap_value_toggled(button_pressed):
    script_edit.wrap_enabled = button_pressed
    script_edit.update()


func _on_draw_tabs_value_toggled(button_pressed):
    script_edit.draw_tabs = button_pressed

func _on_from_text_changed(new_text):
    if new_text.is_valid_integer():
        if int(new_text) == 0:
            new_text = str(-1)
            from.set_text(new_text)
        from_line_to[0] = int(new_text)
        _on_script_changed(current_script)



func _on_to_text_changed(new_text):
    if new_text.is_valid_integer():
        if int(new_text) == 0:
            new_text = str(-1)
            to.set_text(new_text)
        from_line_to[1] = int(new_text)
        _on_script_changed(current_script)


func _on_Reload_pressed():
    _on_script_changed(current_script)


func _on_minimap_draw_value_toggled(button_pressed):
    script_edit.minimap_draw = button_pressed


func _on_ViewportContainer_item_rect_changed():
    snapshot_container.rect_size = viewport_container.rect_size

func _on_minsie_value_toggled(button_pressed):
    lines_count_as_min_size = button_pressed
    change_frame_min_size()


func _on_show_line_numbers_toggled(button_pressed):
    snapshot_container.get_node("ScriptContainer/VBox/ScriptEdit").show_line_numbers = button_pressed
    pass # Replace with function body.

func _on_ExportPNG_pressed():
    exporting_extension = "png"
    save.filters = ["*.png ; Portable Network Graphics"]
    save.current_file = "snapshot.png"
    save.popup()


func _on_ExportHTML_pressed():
    exporting_extension = "html"
    save.filters = ["*.html ; HyperText Markup Language"]
    save.current_file = "snapshot.html"
    save.popup()


