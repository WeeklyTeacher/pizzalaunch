# Local behavioral checks

Run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Test-Behavior.ps1
```

The runner first compiles every actual `src/**/*.luau` file, then executes each
`tests/*.spec.luau` in a separate Lune process. A spec is a self-running Luau script
using assertions and concise PASS messages; an error fails the aggregate. Use
`-Filter RecordPersistence.spec.luau` for one focused spec.

`scripts/Get-TestRuntime.ps1` downloads the official Windows x64 Lune 0.10.5
release only into ignored `.qa-artifacts/tools/lune-0.10.5`. It verifies the pinned
release archive SHA-256 and checks the executable against that archive every run.
It does not install tools globally or alter PATH. Release provenance:
https://github.com/lune-org/lune/releases/tag/v0.10.5

Pure modules use ordinary relative `require`. `support/LoadModule.luau` loads the
unchanged actual source with Roblox datatypes and explicitly injected service,
clock, task, or remote doubles. These tests demonstrate logic at those boundaries;
they do not demonstrate Roblox physics, replication, real DataStores, Studio
rendering, camera feel, touch gestures, or controller focus.

`RecoveryOverlay.spec.luau` reads the frozen Transfer fixture without writing it.
It verifies full current Rojo source coverage, unknown-script rejection, missing
module recovery, exact source verification, binary round-trip preservation of an
unmapped geometry fixture, and output containment/overwrite guards. Its small
overwrite fixtures remain ignored in `.qa-artifacts`.

Normal source builds use `rojo build default.project.json -o .qa-artifacts/<new-name>.rbxl`.
Optional recovery generation uses:

```powershell
$runtime = & scripts/Get-TestRuntime.ps1
& $runtime run scripts/Create-RecoveryArtifact.luau
```

This writes a uniquely named ignored artifact from the canonical read-only input.
The complete module mapping comes from `rojo sourcemap`; no fixed module list is
maintained. Existing mapped scripts keep their instances and non-source properties,
new required modules are added, and unknown embedded scripts cause failure. Both
the original canonical hash and the in-memory Workspace serialization are checked
before/after. The historical tracked merged recovery artifact is never updated.
A source-only Rojo build contains mapped objects and cannot prove preservation of
unknown objects in an existing Studio place. Recovery fixture checks also cannot
prove preservation of geometry that is absent from that fixture.
