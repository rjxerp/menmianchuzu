@echo off
rem ================================================================
rem  租赁合同管理系统 Web 版 —— 一键启动（静默版）
rem  双击本文件：后台启动服务并自动打开浏览器，全程无命令行窗口。
rem  停止服务：双击 stop_web.bat      启动诊断：双击 诊断启动.bat
rem
rem  2026-09-11 第 2 次修正：
rem   1. 解释器选择改由 backend\pick_python.bat 统一负责，判定标准是
rem      「必须能导入全部依赖」。此前只判定 import sys，导致选中
rem      uv 托管的 python3.11（无依赖且 PEP668 拒绝安装）并弹出报错框。
rem   2. 端口预检提前到最前：服务已在运行则只打开浏览器，不再报错。
rem   3. 自动安装依赖改用腾讯镜像（本机直连 pypi.org 不稳定）。
rem   4. 本文件必须保存为 ANSI(GBK) 且不要添加 chcp 65001，
rem      否则弹框中文会乱码（本次故障现象之一）。
rem ================================================================
if /i not "%1"=="--hidden" (
  wscript //nologo "%~dp0start_web_hidden.vbs" "%~f0"
  exit /b 0
)
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "LAUNCHLOG=%~dp0logs\launcher.log"
if not exist "%~dp0logs" mkdir "%~dp0logs"

rem ---------------- ① 端口预检：已在运行就直接开浏览器 ----------------
netstat -ano | findstr ":8000" | findstr "LISTENING" >nul 2>nul
if not errorlevel 1 (
  curl -s -o nul http://127.0.0.1:8000/api/health >nul 2>nul
  if not errorlevel 1 (
    echo [%date% %time%] service already running - open browser >> "%LAUNCHLOG%"
    start "" http://127.0.0.1:8000
    exit /b 0
  )
  echo [%date% %time%] port 8000 occupied by other process >> "%LAUNCHLOG%"
  call :SHOWMSG "端口 8000 已被其他程序占用，无法启动服务。请先关闭占用该端口的程序，或重启电脑后再试。"
  exit /b 1
)

rem ---------------- ② 选择解释器（必须依赖完整） ----------------
call "%~dp0backend\pick_python.bat"
if not defined PY_RUN (
  echo [%date% %time%] no interpreter with full dependencies >> "%LAUNCHLOG%"
  call :SHOWMSG "没有找到可用的 Python 环境。请先安装 Python 3.10 及以上版本并执行 pip install -r requirements.txt，或双击 诊断启动.bat 查看详细原因。"
  exit /b 1
)
echo [%date% %time%] interpreter: %PY_RUN% >> "%LAUNCHLOG%"

rem ---------------- ③ 静默启动服务 ----------------
wscript //nologo "%~dp0run_hidden.vbs" %PY_RUN% -m uvicorn main:app --host 127.0.0.1 --port 8000 --app-dir backend
if errorlevel 1 (
  echo [%date% %time%] wscript launch failed - fallback to hidden cmd >> "%LAUNCHLOG%"
  start "lease-web" /min cmd /c "!PY_RUN! -m uvicorn main:app --host 127.0.0.1 --port 8000 --app-dir backend"
)

rem ---------------- ④ 等待服务就绪并打开浏览器 ----------------
for /l %%i in (1,1,60) do (
  curl -s -o nul http://127.0.0.1:8000/api/health >nul 2>nul
  if not errorlevel 1 (
    echo [%date% %time%] service ready - health OK >> "%LAUNCHLOG%"
    goto READY
  )
  ping -n 2 127.0.0.1 >nul
)
goto FAILED

:READY
start "" http://127.0.0.1:8000
exit /b 0

:FAILED
echo [%date% %time%] service NOT ready within 60s >> "%LAUNCHLOG%"
if exist "%~dp0logs\web_service.log" (
  echo -------- tail of web_service.log -------- >> "%LAUNCHLOG%"
  powershell -NoProfile -Command "Get-Content -Tail 30 -Encoding UTF8 '%~dp0logs\web_service.log'" >> "%LAUNCHLOG%" 2>nul
)
call :SHOWMSG "服务启动失败。请稍后重试；若反复失败，双击 诊断启动.bat 查看原因。日志文件：logs 目录下的 launcher.log 与 web_service.log。"
exit /b 1

:SHOWMSG
powershell -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('%~1','租赁合同管理系统')"
exit /b 0
