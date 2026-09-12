# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file PowerShell utility (`fasten-video.ps1`) that mutes and time-compresses a video to fit within a target duration (default 120s), writes the result to `%USERPROFILE%\Downloads\<name>-fast.mp4`, and deletes the source on success. Built for personal exercise-clip processing on Windows.

## Run

```powershell
.\fasten-video.ps1 "C:\path\to\input.mp4"           # default -MaxSeconds 120
.\fasten-video.ps1 "C:\path\to\input.mp4" -MaxSeconds 90
```

There is no build, lint, or test suite. Validate changes by running the script against a real `.mp4` and inspecting the output file.

## Required tools

`ffmpeg` and `ffprobe` must be either on `PATH` or located at `C:\ffmpeg\bin\`. `Resolve-Tool` (script:11) handles the lookup.

## Architecture / behavior notes

The script is a linear pipeline — keep it that way; do not introduce modules or helpers unless the script grows substantially.

- **Speed factor** is computed as `max(1.0, duration / MaxSeconds)` (script:31). Videos already shorter than `MaxSeconds` are passed through at 1.0x (no slowdown).
- **Filter** chain is `drawtext=...,setpts=PTS/<speed>` on the video stream, with `-an` to drop audio entirely. Do not switch to `atempo` / re-add audio without changing the spec — the README explicitly states "mute".
- **Timestamp overlay** burns the source file's `LastWriteTime` (recording time) as static top-right text via `drawtext` *before* `setpts`, so it stays fixed after fast-forward. Requires an ffmpeg build with libfreetype and `C:\Windows\Fonts\arial.ttf`. Colons in the stamp are escaped (`\:`) and the fontfile path colon is escaped (`C\:/...`) for the filtergraph parser.
- **Encoder settings** (`libx264 -preset fast -crf 23 -pix_fmt yuv420p -movflags +faststart`) are tuned for broad compatibility (Windows Photos, web). Changing these affects file size and playback compatibility.
- **Source deletion** (script:52) only runs after `ffmpeg` exits 0 *and* the output exists with non-zero size. Preserve this guard — losing the source on a bad encode is the worst-case failure.
- `$ErrorActionPreference = 'Stop'` is set globally; rely on thrown exceptions rather than manual `if ($LASTEXITCODE)` checks except around native `ffmpeg` invocations (PowerShell does not throw on native exit codes).
- Paths are passed to native tools via `--` end-of-options to handle filenames starting with `-`. Keep this when modifying invocations.

## Conventions

- PowerShell 5.1 compatible (no `??`, no ternary, no pipeline chain operators). The script uses `&` call operator + `$LASTEXITCODE` for native commands.
- Commit message style: conventional commits (`feat:`, `fix:`, etc.) — see prior commit `feat: mute and fast-forward exercise videos to under 2 minutes`.
