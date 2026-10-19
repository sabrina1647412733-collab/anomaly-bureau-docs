@echo off
setlocal
title 岚桥站 0017 · 录制（Godot 内部录制，不会黑屏）

set SCRIPTDIR=%~dp0
set GODOT=C:\Users\Sabrina\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe
set PROJ=
for /d %%D in ("%SCRIPTDIR%*Godot*") do set PROJ=%%D
if "%PROJ%"=="" echo [错误] 没找到 Godot 项目目录 & pause & exit /b 1
if not exist "%GODOT%" echo [错误] 没找到 Godot 程序 & pause & exit /b 1

set OUTDIR=%SCRIPTDIR%_record
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set STAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set STAMP=%STAMP: =0%
set AVI=%OUTDIR%\rec_%STAMP%.avi
set MP4=%OUTDIR%\rec_%STAMP%.mp4

echo ============================================================
echo   岚桥站 0017  ·  录制模式（用 Godot 自己写帧，绝不黑屏）
echo ------------------------------------------------------------
echo   * 游戏会照常打开，能正常走位、对话、按键
echo   * 画面 1600x900，锁定 30 帧；因为逐帧渲染，速度可能比平时快一点点
echo   * 录到你不想要为止，然后直接关掉游戏窗口（Alt+F4）
echo   * 关窗后会自动转成 mp4 并打开文件夹
echo   * 注意：这个模式录不到游戏声音
echo ============================================================
echo.
"%GODOT%" --path "%PROJ%" --write-movie "%AVI%" --fixed-fps 30
echo.
echo 录制结束：%AVI%
echo 正在转 mp4 ...

set FFBIN=
if exist "%SCRIPTDIR%_tools\ffmpeg.exe" set FFBIN="%SCRIPTDIR%_tools\ffmpeg.exe"
if not defined FFBIN (where ffmpeg >nul 2>nul && set FFBIN=ffmpeg)
if not defined FFBIN goto :noff

%FFBIN% -y -hide_banner -loglevel error -i "%AVI%" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -movflags +faststart "%MP4%"
if not exist "%MP4%" goto :failed
del /q "%AVI%"
echo.
echo ============================================================
echo   完成：%MP4%
echo   （原始 avi 已删除，省空间）
echo ============================================================
start "" explorer "%OUTDIR%"
echo.
pause
exit /b 0

:noff
echo [提示] 没找到 ffmpeg，只能留下 avi 文件。
echo   想自动转 mp4：把 ffmpeg.exe 放到 %SCRIPTDIR%_tools\ 目录下再运行本脚本。
echo   文件：%AVI%
start "" explorer "%OUTDIR%"
pause
exit /b 0

:failed
echo [错误] 转换失败，原始文件还在：%AVI%
pause
exit /b 1
