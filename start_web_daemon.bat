@echo off
chcp 65001 >nul
rem ================================================================
rem  Lease Contract Web - guarded start  (crash restart + health probe)
rem  2026-09-11 rewrite v2: interpreter selection delegated to
rem  backend\pick_python.bat (full dependency check; uv / Hermes /
rem  WorkBuddy isolated environments are skipped automatically).
rem  Usage: double click, or drop a shortcut into shell:startup.
rem  Stop : close this window, then run stop_web.bat
rem  NOTE: keep every rem line ASCII (see 诊断启动.bat for the reason).
rem ================================================================
cd /d "%~dp0"
call "%~dp0backend\pick_python.bat"
if not defined PY_RUN (
  echo 未找到具备完整依赖的 Python 环境，请先双击 诊断启动.bat 查看原因。
  pause
  exit /b 1
)

echo 守护启动，使用解释器: %PY_RUN%
%PY_RUN% "%~dp0backend\run_service_guard.py"
pause
