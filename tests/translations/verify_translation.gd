extends SceneTree


func fail(message: String) -> void:
    printerr("ASM TRANSLATION FAIL: " + message)
    quit(1)


func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        fail("Expected CSV and compiled translation paths")
        return
    var csv := FileAccess.open(args[0], FileAccess.READ)
    var translation := ResourceLoader.load(args[1]) as Translation
    if csv == null or translation == null:
        fail("Cannot load CSV or compiled translation")
        return
    if csv.get_csv_line() != PackedStringArray(["key", "en"]) or translation.locale != "en":
        fail("Unexpected CSV header or translation locale")
        return
    var seen: Dictionary = {}
    var mismatches := 0
    while csv.get_position() < csv.get_length():
        var row := csv.get_csv_line()
        if row.size() != 2 or row[0].is_empty() or seen.has(row[0]):
            fail("Malformed or duplicate CSV key")
            return
        if str(translation.get_message(row[0])) != row[1]:
            printerr("CSV/compiled text mismatch: " + JSON.stringify({"key": row[0], "csv": row[1], "compiled": str(translation.get_message(row[0]))}))
            mismatches += 1
        seen[row[0]] = true
    csv.close()
    if mismatches > 0:
        fail("%d CSV/compiled message mismatches" % mismatches)
        return
    if seen.size() != 15:
        fail("Unexpected original test20 translation key count: %d" % seen.size())
        return
    print("ASM TRANSLATION: %d messages verified, 0 failures" % seen.size())
    quit(0)
