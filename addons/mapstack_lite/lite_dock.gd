@tool
extends VBoxContainer
## The dock: what MapStack is, one button to install (or turn on) MapStack Free, and links to the trailer and Pro.
## Uses the editor's own theme, so it looks right in every editor theme with no overrides.

const Installer := preload("res://addons/mapstack_lite/free_installer.gd")
const Text := preload("res://addons/mapstack_lite/lite_text.gd")
const LINKS_PATH := "res://addons/mapstack_lite/links.json"
const DOWNLOAD_PATH := "user://mapstack_free_download.zip"
const PLUGIN := "mapstack"

var _links: Dictionary
var _state: Label
var _main: Button
var _confirm: ConfirmationDialog
var _http: HTTPRequest

func _ready() -> void:
	_links = _read_links()
	_build()
	_refresh()

func _read_links() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(LINKS_PATH))
	return parsed if parsed is Dictionary else {}

func _zip() -> Dictionary:
	var zip = _links.get("free_zip", {})
	return zip if zip is Dictionary else {}

func _can_download() -> bool:
	return str(_zip().get("url", "")) != "" and str(_zip().get("sha256", "")) != ""

func _build() -> void:
	var title := Label.new()
	title.text = Text.TITLE
	title.theme_type_variation = &"HeaderMedium"
	add_child(title)
	add_child(_wrapped(Text.PITCH))
	_state = _wrapped("")
	add_child(_state)
	_main = Button.new()
	_main.pressed.connect(_on_main)
	add_child(_main)
	add_child(_link_button(Text.TRAILER, "trailer"))
	add_child(_link_button(Text.PRO, "pro_page"))
	_confirm = ConfirmationDialog.new()
	_confirm.title = Text.CONFIRM_TITLE
	_confirm.dialog_autowrap = true
	_confirm.confirmed.connect(_download)
	add_child(_confirm)
	_http = HTTPRequest.new()
	_http.download_file = DOWNLOAD_PATH
	_http.request_completed.connect(_on_downloaded)
	add_child(_http)

func _wrapped(words: String) -> Label:
	var label := Label.new()
	label.text = words
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _link_button(words: String, key: String) -> LinkButton:
	var button := LinkButton.new()
	button.text = words
	button.uri = str(_links.get(key, ""))
	return button

func _refresh(message: String = "") -> void:
	_main.disabled = false
	if Installer.is_installed():
		var on := EditorInterface.is_plugin_enabled(PLUGIN)
		_state.text = Text.STATE_READY if on else Text.STATE_OFF
		_main.text = Text.TURN_ON
		_main.visible = not on
	else:
		_state.text = Text.STATE_MISSING
		_main.text = Text.INSTALL if _can_download() else Text.GET_FREE
		_main.visible = true
	if message != "":
		_state.text = message

func _on_main() -> void:
	if Installer.is_installed():
		EditorInterface.set_plugin_enabled(PLUGIN, true)
		_refresh()
	elif _can_download():
		_confirm.dialog_text = str(_links.get("license_summary", "")) + Text.CONFIRM_TAIL
		_confirm.popup_centered()
	else:
		OS.shell_open(str(_links.get("free_page", "")))
		_state.text = Text.STATE_BROWSER

func _download() -> void:
	_main.disabled = true
	_state.text = Text.STATE_DOWNLOADING
	var error := _http.request(str(_zip().get("url", "")))
	if error != OK:
		_refresh(Text.FAIL_DOWNLOAD % error_string(error))

func _on_downloaded(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_refresh(Text.FAIL_DOWNLOAD % ("HTTP %d" % code if result == HTTPRequest.RESULT_SUCCESS else "error %d" % result))
		return
	_state.text = Text.STATE_CHECKING
	if Installer.sha256_of(DOWNLOAD_PATH) != str(_zip().get("sha256", "")).to_lower():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DOWNLOAD_PATH))
		_refresh(Text.FAIL_CHECK % str(_zip().get("version", "")))
		return
	_state.text = Text.STATE_INSTALLING
	var problem := Installer.install(DOWNLOAD_PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DOWNLOAD_PATH))
	if problem != "":
		_refresh(problem)
		return
	var files := EditorInterface.get_resource_filesystem()
	files.filesystem_changed.connect(_turn_on_after_scan, CONNECT_ONE_SHOT)
	files.scan()

func _turn_on_after_scan() -> void:
	EditorInterface.set_plugin_enabled(PLUGIN, true)
	_refresh()
