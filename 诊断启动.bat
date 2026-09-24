@echo off
chcp 65001 >nul
rem ================================================================
rem  Lease Contract Web - startup diagnostic  (2026-09-11 rewrite)
rem  Why UTF-8 + chcp 65001: this machine has PYTHONUTF8=1 /
rem  PYTHONIOENCODING=utf-8 globally, so Python children print UTF-8;
rem  the console must switch to 65001 or their output is mojibake.
rem  NOTE: keep every rem line ASCII. Non-ASCII comment lines are read
rem  before the code page switch and make cmd split them into stray
rem  commands ("... is not recognized as an internal command").
rem  Chinese text is only allowed inside echo lines (executed after chcp).
rem  backend\pick_python.bat is pure ASCII, so mixing is safe.
rem ================================================================
cd /d "%~dp0"

echo ================================================================
echo  ① 可用解释器探测（判定标准：能导入全部依赖）
echo ================================================================
call "%~dp0backend\pick_python.bat" verbose
if not defined PY_RUN (
  echo.
  echo  未找到具备完整依赖的 Python 环境。解决办法：
  echo     1. 安装 Python 3.10 及以上版本；
  echo     2. 执行 python -m pip install -r requirements.txt
  echo.
  pause
  exit /b 1
)
echo.
echo  使用解释器: %PY_RUN%
echo.
echo ================================================================
echo  ② 启动链路自检（配置解析 / 数据库连接 / 连接池 / 关键表）
echo ================================================================
set "LEASE_CONFIG_PATH=%~dp0config.json"
%PY_RUN% "%~dp0backend\check_startup.py"

echo.
echo ================================================================
echo  ③ 8000 端口监听状态
echo ================================================================
netstat -ano | findstr ":8000" | findstr "LISTENING"
if errorlevel 1 (
  echo      当前无监听，服务未运行
) else (
  echo      服务正在运行
)

echo.
pause
