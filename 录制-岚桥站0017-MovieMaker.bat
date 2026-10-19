@echo off
setlocal
rem ===== 岚桥站 0017 · Godot 录制（Movie Maker 模式）=====
rem 功能路径全部为 ASCII，靠 %~dp0 自动定位项目，避免中文路径编码问题
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
echo ============================================================
echo   岚桥站 0017 · Godot 录制模式
echo   画面 1600x900，锁定 30 帧，逐帧渲染不掉帧
echo   录完请直接关掉游戏窗口（Alt+F4），文件才会写完
echo   原始文件：%AVI%
echo ============================================================
echo.
"%GODOT%" --path "%PROJ%" --write-movie "%AVI%" --fixed-fps 30
echo.
echo 录制结束，原始文件：%AVI%
where ffmpeg >nul 2>nul
if %errorlevel%==0 goto :conv
echo 没找到 ffmpeg，装一个就能自动转 mp4：winget install Gyan.FFmpeg
goto :done
:conv
set MP4=%AVI:.avi=.mp4%
echo 正在用 ffmpeg 转成 mp4 ...
ffmpeg -y -i "%AVI%" -c:v libx264 -crf 18 -pix_fmt yuv420p "%MP4%"
echo 已生成：%MP4%
:done
echo.
pause
