extends SceneTree
## Run: godot --headless --path <a project holding addons/mapstack_lite and this folder> -s tests/test_free_installer.gd

const Installer := preload("res://addons/mapstack_lite/free_installer.gd")

var failures := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", what)

func make_zip(path: String, entries: Dictionary) -> void:
	var packer := ZIPPacker.new()
	packer.open(path)
	for name in entries:
		packer.start_file(name)
		packer.write_file(str(entries[name]).to_utf8_buffer())
		packer.close_file()
	packer.close()

func _init() -> void:
	check(Installer.entry_is_safe("addons/mapstack/plugin.cfg"), "plain file is safe")
	check(not Installer.entry_is_safe("addons/mapstack/../project.godot"), "climbing out is refused")
	check(not Installer.entry_is_safe("addons/other/x.gd"), "other addons are refused")
	check(not Installer.entry_is_safe("project.godot"), "project files are refused")
	check(not Installer.entry_is_safe("addons/mapstack/"), "folders are skipped")
	check(not Installer.entry_is_safe("addons/mapstack/a\\..\\b"), "backslashes are refused")

	var root := "user://lite_test"
	DirAccess.make_dir_recursive_absolute(root)
	var good := root + "/good.zip"
	make_zip(good, {"addons/mapstack/plugin.cfg": "[plugin]", "addons/mapstack/core/a.gd": "x", "project.godot": "evil"})
	check(Installer.install(good, root + "/out") == "", "good zip installs")
	check(FileAccess.file_exists(root + "/out/addons/mapstack/core/a.gd"), "nested file written")
	check(not FileAccess.file_exists(root + "/out/project.godot"), "outside file not written")
	var empty := root + "/empty.zip"
	make_zip(empty, {"README.md": "hi"})
	check(Installer.install(empty, root + "/out2") != "", "zip without MapStack is refused")
	check(Installer.install(root + "/missing.zip", root + "/out3") != "", "missing zip is refused")
	check(Installer.sha256_of(good).length() == 64, "sha256 is hex")
	check(Installer.sha256_of(root + "/missing.zip") == "", "missing file hashes to empty")
	print("free_installer: ", "PASS" if failures == 0 else "%d FAILED" % failures)
	quit(1 if failures else 0)
