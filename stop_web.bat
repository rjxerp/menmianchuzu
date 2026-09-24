@echo off
rem ============================================================
rem  租赁合同管理系统 Web 版 - 停止服务脚本
rem  关闭 8000 端口上运行的 uvicorn 服务进程
rem ============================================================
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":8000" ^| findstr "LISTENING"') do (
  echo 正在停止服务进程 PID=%%P ...
  taskkill /F /PID %%P >nul 2>nul
)
ping -n 2 127.0.0.1 >nul
netstat -ano | findstr ":8000" | findstr "LISTENING" >nul 2>nul
if errorlevel 1 (
  echo 服务已停止
) else (
  echo 停止失败，请手动检查 8000 端口占用
)
pause
