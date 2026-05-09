# fasten-video

Mute + tua nhanh video tập thể dục thô về `<= 120s`, đẩy output vô `Downloads`, xóa file gốc.

## Yêu cầu

- Windows + PowerShell
- `ffmpeg` + `ffprobe` (PATH hoặc `C:\ffmpeg\bin\`)

## Dùng

```powershell
.\fasten-video.ps1 "C:\Users\tan\OneDrive\Pictures\Camera Roll\WIN_20260509.mp4"
```

Output: `%USERPROFILE%\Downloads\<name>-fast.mp4`. File gốc bị xóa khi encode thành công.

Đổi target duration (mặc định 120s):

```powershell
.\fasten-video.ps1 "video.mp4" -MaxSeconds 90
```
