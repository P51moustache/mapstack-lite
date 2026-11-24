@tool
extends RefCounted
## Unpacks a MapStack zip into the project. Pure apart from the file writes, so tests call it directly.
## Only entries under addons/mapstack/ are written; anything else in the zip, or any path that climbs out of
## that folder, is refused, so a damaged or altered zip cannot touch the rest of the project.

const ADDON_PREFIX := "addons/mapstack/"
const PLUGIN_CFG := "res://addons/mapstack/plugin.cfg"

## True when `entry` is a file MapStack Lite may write: inside addons/mapstack/, no "..", no absolute path.
static func entry_is_safe(entry: String) -> bool:
	if not entry.begins_with(ADDON_PREFIX) or entry.ends_with("/"):
		return false
	if entry.begins_with("/") or entry.contains("\\") or entry.contains(":"):
		return false
	for part in entry.split("/"):
		if part == ".." or part == ".":
			return false
	return true

## Lower-case hex SHA-256 of the file at `path` ("" when it cannot be read).
static func sha256_of(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	const CHUNK := 1 << 20  # 1 MiB keeps memory flat for a zip of a few hundred MB.
	while not file.eof_reached():
		hashing.update(file.get_buffer(CHUNK))
	return hashing.finish().hex_encode()

static func is_installed() -> bool:
	return FileAccess.file_exists(PLUGIN_CFG)

## Writes the zip's addons/mapstack/ files under `root` (res:// in the editor). Returns "" or what went wrong.
static func install(zip_path: String, root: String = "res://") -> String:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return "The download is not a zip MapStack Lite can open."
	var entries: Array[String] = []
	for entry in reader.get_files():
		if entry_is_safe(entry):
			entries.append(entry)
	if not entries.has(ADDON_PREFIX + "plugin.cfg"):
		reader.close()
		return "The download does not contain MapStack (no addons/mapstack/plugin.cfg)."
	for entry in entries:
		var target := root.path_join(entry)
		DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		var out := FileAccess.open(target, FileAccess.WRITE)
		if out == null:
			reader.close()
			return "Could not write %s." % target
		out.store_buffer(reader.read_file(entry))
		out.close()
	reader.close()
	return ""
