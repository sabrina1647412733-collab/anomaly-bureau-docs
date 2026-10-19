@echo off
setlocal
echo ============================================
echo   备份 Godot 主工程  -^>  anomaly-bureau-game
echo ============================================
cd /d "%~dp0岚桥站0017-Godot"
if errorlevel 1 (
  echo [错误] 找不到工程目录 岚桥站0017-Godot
  pause
  exit /b 1
)

git add -A
git diff --cached --quiet
if %errorlevel%==0 (
  echo 没有新改动，直接检查远端同步...
  git push
  goto done
)

echo 本次改动：
git -c core.quotepath=false status --short
echo.
set "MSG="
set /p "MSG=提交说明（直接回车 = 自动用时间）: "
if "%MSG%"=="" set "MSG=自动备份 %date% %time%"
git commit -m "%MSG%"
if errorlevel 1 goto fail
git push
if errorlevel 1 goto fail
goto done

:fail
echo.
echo [失败] 把上面的红字发给我。常见原因：代理没开（需 127.0.0.1:7897）或需要重新登录 GitHub。
pause
exit /b 1

:done
echo.
echo 完成。按任意键关闭。
pause >nul
