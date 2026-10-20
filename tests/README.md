# Compatibility and package verification

## Test23 local demand hotfix

Run `tools/Test-Demand.ps1 -GodotExecutable <console-executable>`. Its isolated project loads the actual SmartWindowData and allocation scripts with small WindowBase/ResourceContainer fixtures; it never loads the game or a save. Checks cover modern Process and legacy get_goal demand, goal/rate conversion, live required/goal changes, multiple materials, unrelated buffers, paused/zero-input states, true uncapped consumers and manager chains. The 25-target reproduction uses 24 finite consumers and one uncapped seller and verifies all three allocation modes, surplus, shortage, zero supply and conservation.

Test23 passes 138 demand checks on Godot 4.7.2 and 4.6.1. Running the same fixtures against pre-fix test22 reproduces 43 behavioral failures, including modern consumers being misclassified and finite demand reading zero. The 158 unlock checks and all 15 translated messages still pass. Tests do not launch the editor or change its settings; only a project-local cache for the two fixture classes is seeded.

Live validation must check the existing managers without replacing nodes or switching saved Mode/Base choices. CPU processing nodes should report finite demand; a real Processing Seller can still contribute one valid uncapped target. The GPU miner/seller chain remains legitimately uncapped. Scheduled game monitoring stays paused.

## Build test23 from committed source

Run the isolated demand/unlock/translation suites above, commit the intended source changes, then build from the clean working tree:

```powershell
.\tools\New-Release.ps1 -ReleaseLabel 0.1.0-test23 -OutputDirectory 'C:\path\new-empty-output-folder'
```

The optional output directory lets a reviewed publication bundle be rebuilt without overwriting an installed/tested local artifact. The packager still requires a clean Git tree, refuses existing output files, includes the source commit in its notes, and verifies all 20 runtime files. Omit `-OutputDirectory` to retain the existing `release/` default used by CI. GitHub publication remains a separate explicit action unless `-Publish` is requested.

## Test22 local unlock hotfix

Run `tools/Test-Unlocks.ps1 -GodotExecutable <console-executable>` for isolated CPU/GPU node and guide requirement regression checks. It tests both legacy string/perk requirements and modern array/research requirements without loading the game or its saves. Test22 packages contain 20 runtime files; `Test-Package.ps1` checks every byte against source, metadata, and the unchanged translation. The optional original-test20 reconciliation is restricted to historical test21 because test22 intentionally changes registration.

The test22 fix is limited to unlock registration. Live verification must confirm the Smart Thread Manager appears in Add Node > CPU after a normal save/restart, while the existing map is unchanged. No mod publication, automatic node replacement, save editing, or monitoring resumption is part of this hotfix.

## Historical test21 checks

Run from the repository root with the official Godot 4.6.1 console/editor executable. Tests use an isolated project under ignored `release/` and do not load Upload Labs or saves.

```powershell
# Read-only verification of the checked-in compiled translation:
.\tools\Test-Translations.ps1 -GodotExecutable 'C:\path\Godot_v4.6.1-stable_win64_console.exe'

# Rebuild in isolation, verify, then replace the candidate's compiled translation:
.\tools\Test-Translations.ps1 -GodotExecutable 'C:\path\Godot_v4.6.1-stable_win64_console.exe' -Rebuild

# Commit source before building; this does not publish:
.\tools\New-Release.ps1 -ReleaseLabel 0.1.0-test21

# Verify archive bytes and the narrowly allowed differences from the original:
.\tools\Test-Package.ps1 -Archive '.\release\guardipee14-AdaptiveSmartManager-v0.1.0-test21.zip' -OriginalArchive 'C:\path\original-test20.zip'
```

The translation test checks the English locale, CSV structure, duplicate keys and all 15 message values. The compiler uses Godot's [OptimizedTranslation.generate](https://docs.godotengine.org/en/4.6/classes/class_optimizedtranslation.html) and [ResourceSaver.save](https://docs.godotengine.org/en/4.6/classes/class_resourcesaver.html), with an independent reload/verification process afterward. The test21 compiled translation digest is `997f9b755bdfade7e23a8d47ee45520f2cd1ac4fe0a3e3adad49898a13a17b61`.

The package check verifies all 19 ZIP entries against source, rejects duplicates/unexpected/missing files, checks test21 metadata and the verified translation digest. The optional baseline must be the original archive with SHA-256 `b3b8aad369e28ce19874dee6bceec0e07d84de9c3914ac05ed708f7fe66c7dfc`, not GitHub's same-named download. Baseline comparisons allow only README changes, rebuilt translation, manifest description/website metadata, explicit build constant/startup wording and line-ending/trailing-whitespace normalization. Allocation logic, scenes and CSV text must match.

The packager retains a uniquely named staging folder and refuses replacing existing ZIP/checksum/notes files. Archive byte hashes may differ across builds because source timestamps/line endings differ; per-file contents and the original-gameplay comparison are the source reproducibility gate. Existing public tags/assets must not be overwritten.

## Remaining game smoke test

With the candidate installed and AAC test7 unchanged, load the existing save and confirm test21 startup, successful resource preflight, both managers and normal translated labels/Mode/Base controls. Let AAC sample for at least 30 seconds and verify raw demand mirrors and graph integrity. Do not change allocation settings or repeat the previous disconnect/Accept/Undo tests unless a new symptom warrants it. Close normally so the resulting log can be checked. This gate remains pending until that exact candidate is tested; no publication is implied by the build commands above.
