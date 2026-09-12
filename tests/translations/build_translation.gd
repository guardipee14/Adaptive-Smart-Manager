extends SceneTree


func _initialize() -> void:
    var csv := FileAccess.open("res://AdaptiveSmartManager.csv", FileAccess.READ)
    if csv == null or csv.get_csv_line() != PackedStringArray(["key", "en"]):
        printerr("ASM TRANSLATION BUILD FAIL: missing CSV or invalid header")
        quit(1)
        return
    var source := Translation.new()
    source.locale = "en"
    var seen: Dictionary = {}
    while csv.get_position() < csv.get_length():
        var row := csv.get_csv_line()
        if row.size() != 2 or row[0].is_empty() or seen.has(row[0]):
            printerr("ASM TRANSLATION BUILD FAIL: malformed or duplicate key")
            quit(1)
            return
        source.add_message(row[0], row[1])
        seen[row[0]] = true
    csv.close()
    var compiled := OptimizedTranslation.new()
    compiled.generate(source)
    var result := ResourceSaver.save(compiled, "res://AdaptiveSmartManager.en.translation")
    if result != OK:
        printerr("ASM TRANSLATION BUILD FAIL: save returned %d" % result)
        quit(1)
        return
    print("ASM TRANSLATION BUILD: %d messages compiled" % seen.size())
    quit(0)
