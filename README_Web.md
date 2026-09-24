# 租赁合同管理系统 Web 版

**综合贸易 · 门面租赁管理系统** —— 由桌面版（PyQt5 + SQLite V2.2.6）完整迁移的浏览器 Web 应用。

| 项目 | 内容 |
|------|------|
| 版本 | v2.3.2-web（2026-09-17，版本单一源 backend/version.py） |
| 适用单位 | 邵阳市综合贸易总公司（商业房产/门面租赁） |
| 运行环境 | Windows 10/11 + Python 3.10+（已装 FastAPI/uvicorn/openpyxl/reportlab） |
| 访问方式 | 浏览器打开 `http://127.0.0.1:8000` |

---

## 1. 快速启动

方式一（推荐）：双击 **`start_web.bat`**。脚本会自动：
1. 探测可用的 Python（优先系统 Python，自动跳过 Hermes 等专用 venv）
2. 检查 Web 依赖（fastapi/uvicorn/openpyxl/reportlab/PyJWT/python-multipart），缺失则自动 `pip install -r requirements.txt`
3. 启动后端服务并打开浏览器

方式二（手动）：

```bat
cd /d "项目解压后的文件夹路径"（例如 D:\租赁合同管理系统_Web_20260902-0119）
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --app-dir backend
```

然后浏览器访问：<http://127.0.0.1:8000>

> 默认管理员账号 `admin`（初始密码以当前数据库中原有账号为准；新建数据库时初始密码为 `admin`）。

## 2. 技术架构

```
浏览器（Chrome/Firefox/Safari/Edge）
        │  REST API（JSON + JWT 认证）
        ▼
FastAPI 后端（backend/main.py）
   ├── 复用原桌面版数据层：db_utils.py（连接池、金额分↔元转换、建库/备份/优化）
   ├── 复用原业务服务：dashboard_services.py / operation_logger.py / config_utils.py / logger_module.py
   ├── 业务服务层：services.py（合同/租金/基础资料/报表/笔记/系统设置）
   └── 认证：auth.py（PBKDF2 密码兼容 + JWT）
        │
        ▼
SQLite 数据库（与原桌面版完全兼容：金额以「分」整数存储）
```

### 关键设计

- **数据兼容**：直接读取原正式库 `Data/ZHMY_Contract_SQLite_2026.db`（config.json 中 `database_path` 指定），
  金额转换层（元↔分）自动生效，历史数据零迁移。
- **认证安全**：JWT 登录令牌（12 小时有效期）；密码使用 PBKDF2-HMAC-SHA256 哈希（与原桌面版一致，
  兼容存量 MD5/明文格式并在登录成功时自动升级）；系统设置类接口强制管理员权限。
- **前端**：原生 HTML/CSS/JS 单页应用，无构建步骤；Chart.js 4.4.3 本地化（离线可用）；
  响应式布局适配桌面/平板/手机。
- **导出**：Excel（openpyxl，蓝色表头 + 边框 + 自适应列宽）、PDF（reportlab）。

## 3. 功能模块（与原桌面版一一对应）

| 模块 | 功能 |
|------|------|
| 仪表盘 | 经营统计卡片、近 12 个月应收/实收租金趋势图、合同到期/租金到期明细 |
| 合同管理 | 搜索筛选、添加/编辑/删除（收款后禁删）、收款明细、续签、Excel 导出/批量导入 |
| 租金管理 | 收款登记、已结清/未结清筛选、编辑/删除、Excel 导出 |
| 报表统计 | 合同统计/租金收入/收款状态三种报表 + 图表 + Excel/PDF 导出 |
| 基础资料 | 房屋、承租人、出租人、水电费标准四个子模块 + Excel 导出 |
| 系统设置（仅管理员） | 备份/恢复/初始化/数据库优化、用户管理、提醒设置、自动备份设置、软件信息、日志查看 |
| 笔记 | 多笔记增删改 |
| 关于 | 软件信息 |

## 4. 配置文件

`config.json`（项目根目录）：

| 配置项 | 含义 | 默认值 |
|--------|------|--------|
| `database_path` | 正式数据库完整路径 | 原桌面版正式库路径 |
| `secret_key` | JWT 签名密钥（首次启动自动生成 96 位随机值，勿泄露/删除） | 自动生成 |
| `logging.log_dir` | 运行日志目录 | `logs` |
| `operation_logging` | 操作日志配置 | - |

> 切换数据库请用管理员在「系统设置 → 数据维护」中操作（备份、选择/创建数据库），
> 程序会自动维护配置文件。**备份必须使用系统内「备份数据」功能**（sqlite3.backup 一致性备份，含 WAL 未落盘数据）。

### 安全配置（JWT 密钥）

JWT 签名密钥加载优先级：
1. **环境变量 `LEASE_WEB_SECRET`**（推荐用于多实例/容器部署，32+ 位随机字符串）
2. **`config.json` 的 `secret_key` 字段**（首次启动自动生成并持久化，重启后 token 失效需重新登录）

未配置时启动即报错（fail-fast），**不再使用任何硬编码默认密钥**。
修改密钥后所有已签发 token 立即失效，用户需重新登录。

## 5. 测试

```bat
cd backend
python run_tests.py          :: 一键跑全部 5 个套件
python test_web_api.py       :: 只跑 API 回归
```

| 套件 | 内容 | 断言数 |
|------|------|--------|
| `test_web_api.py` | 登录/权限/合同/租金 CRUD（含金额分存储校验）/报表/导出/备份恢复/笔记 | 74 |
| `test_schema_regression.py` | 新建库 schema 冒烟 + 幂等补列 | 2 |
| `test_fix_regression.py` | 历史修复回归 | 37 |
| `test_money_regression.py` | 金额 元/分 换算回归 | 29 |
| `test_pdf_security.py` | PDF 导出安全（R-01 / CVE-2023-33733 防护）+ reportlab 版本护栏 | 13 |

使用 `Data/Test_Contract_SQLite.db` 副本 + 金额迁移标记做隔离回归，**不污染正式库**。

## 6. 常见问题

| 问题 | 处理 |
|------|------|
| 启动提示找不到 uvicorn | `pip install fastapi uvicorn openpyxl reportlab pyjwt` |
| 端口被占用 | 修改 start_web.bat 中 `--port 8000` 或关闭占用程序 |
| 登录提示密码错误 | 以原数据库账号为准；忘记密码见桌面版手册 4.3（需用程序生成 PBKDF2 哈希） |
| 金额显示异常（×100） | 确认数据库 `schema_meta.amount_cents_migrated=1`（原正式库已迁移），重启服务 |
| 系统设置进不去 | 需管理员账号登录 |

## 7. 与原桌面版差异说明

- 图表由 matplotlib 改为 Chart.js（浏览器端渲染）。
- Excel 导入导出由 pandas 改为 openpyxl 纯实现（列模板与原版一致）。
- 自动备份原为桌面版 QTimer 定时器，Web 版保存设置后需配合系统计划任务或保持服务运行（由管理员手动触发备份亦可）。
- 屏幕超时锁屏为桌面版特性，Web 版以 JWT 过期时间代替。

## 8. 2026-09-11 安全与稳定性优化实施记录

依据《项目优化体检报告_20260911_1205.md》按 P0→P1→P2 顺序全部实施：

**P0 schema 修复**
- `db_utils.py` 建表模板补齐 11 个历史缺列；新增 `ensure_schema_columns()` 幂等补列（60s 缓存），三条取连接路径自动修复旧库；`create_empty_database` 写入金额迁移标记。
- 新增 `test_schema_regression.py`（新建库冒烟 + 幂等补列，2 用例）。

**P1 安全加固**
- P1-1 JWT 回查 users 表 + 密码版本签名（`pwd` claim）：删账号/改密后旧 token 立即失效。
- P1-2 `/api/auth/usernames` 加鉴权；登录页用户名改为自由输入（防账号枚举）。
- P1-3 `/api/system/db-name` 只返回文件名，不泄露绝对路径。
- P1-4 异常详情不再回传前端（仪表盘 4 处 + 附件保存 + auth 4 处），细节进服务日志。
- P1-5 三个 Excel 导入接口加 50MB 上限。
- P1-6 租金编辑加载失败显式 toast 并中止，不再静默退化为空白表单。
- P1-7 前端 `Store` 安全封装 localStorage 全部 19 处调用（防隐私模式白屏）。
- P1-8 金额列写入遇 dict 参数快速失败（防元当分写入 100 倍错账）。
- P1-10 `close_connection` 检测 `in_transaction` 漏 commit 打 WARNING。

**P1 备份与测试**
- 备份保留策略：每目录只留最新 30 份 `*_backup_*.db`。
- 异地备份：配置 `app_settings.offsite_backup_dir` 或环境变量 `LEASE_OFFSITE_BACKUP_DIR` 后自动拷贝（失败仅告警）。
- 新增统一测试入口 `backend/run_tests.py`（4 套用例一键跑，支持按名过滤）。

**P2 工程化**
- 新增公开接口 `GET /api/health`（库连通性 + 连接池占用），供守护脚本探活。
- `.gitignore` 补 `config.json`（含 JWT 密钥严禁入库）；**密钥已轮换**（所有用户需重新登录）。
- `config.json` 清理死键（`app_settings.auto_backup`、`theme`、`rent_filter_state`——真实开关在数据库/前端 localStorage）。
- 新增 `requirements.lock`（实测环境锁定版本）。
- 新增守护脚本 `start_web_daemon.bat`（崩溃自动重启 + 60 秒 health 探活），可放入 `shell:startup` 实现开机自启。

**测试结论**（当时）：`run_tests.py` 4/4 套件全部通过（74 API + 37 fix + 29 money + 2 schema）。

---

## 10. PDF 导出安全修复（R-01 / CVE-2023-33733，2026-09-11）

**背景**：交付检验发现 `reportlab==3.6.12` 存在 **CVE-2023-33733**（`rl_safe_eval` 代码注入 → 服务器 RCE）。
而 `excel_utils.build_pdf()` 会把**数据库中的用户数据**（承租方/备注/Excel 导入单元格等）直接送入
reportlab 的 `Paragraph()`，标记解析路径真实可达 → **属可利用的高危缺陷**。

**双重修复**
1. **依赖升级**：`reportlab` 3.6.12 → **5.0.1**（`requirements.txt` 安全下限提为 `>=3.6.13`，`requirements.lock` 锁定 5.0.1）。
2. **代码加固**：新增 `excel_utils._pdf_text()`，对送入 `Paragraph` 的表头与单元格文本统一做
   **XML 转义**（`& < >` → 实体），从根源阻断标记解析；渲染后可见内容**完全不变**。
   即使将来依赖被降级，此层仍能防护。

**验证（4 层）**
| 验证 | 结果 |
|------|------|
| `test_pdf_security.py` 单元回归 | **13/13 通过**（含"对照组直接送入会被解析"证明风险真实、"加固后渲染文本==原文"证明已阻断） |
| PDF 内容回归（升级前后） | 三类报表**文本完全一致**（行数/页数/文本长度/摘要全同） |
| 线上导出 | 三类报表 `HTTP 200`，均为合法 PDF |
| 端到端取证（隔离库注入标记形态数据 → 走完整 HTTP 链路导出） | 标记**原样出现在 PDF 中**、**未被解析**、可见文字保留 ✅ |

**日常回归**：`cd backend && python run_tests.py`（现为 **5/5 套件 155 断言**）。
若版本护栏报错，说明 reportlab 被降级到不安全版本，须立即恢复 `>=3.6.13`。

## 9. 启动与数据库连接（2026-09-11 修正）

**问题**：双击 `start_web.bat` 后服务起不来，表现为"无法自动连接数据库"。

**根因**：启动脚本按 `python → python3 → python3.11` 取 PATH 里第一个能跑的解释器，而本机 `python` 指向
WorkBuddy 托管环境（`.workbuddy\binaries\...\python3.13`），该环境**不含项目任何依赖**，服务无法启动。

**已修正**：

| 环节 | 现在的行为 |
|------|-----------|
| 解释器探测 | 统一收敛到 `backend\pick_python.bat`：候选为 `.venv` → 记忆文件 → Store 版 3.1x → `py -3.10~3.13` → PATH → `C:\Python3*` `D:\Python3*`；**每个候选都必须能导入全部 7 项依赖**，自动跳过 uv / Hermes / WorkBuddy / `.local\bin` 等隔离环境 |
| 解释器记忆 | 成功后写入 `backend/.python_exe.txt`，后续启动固定复用；换环境删掉该文件即自动重选 |
| 依赖校验 | 4 个包 → 7 个包（补 `jwt` / `openpyxl` / `reportlab`），缺失则用**腾讯镜像**安装 `requirements.lock`（回退 `requirements.txt`）；仍不行就用其创建项目 `.venv` |
| 端口占用 | 已有服务在跑则直接打开浏览器，不再误报"启动失败"（端口预检已提前到第一步） |
| 启动日志 | `logs/launcher.log`（选用的解释器、就绪/失败、失败时附服务日志末尾） |
| 数据库初始化 | `main.py` 启动钩子改为 **解析→自愈→绑定→实连校验**：配置缺路径回退扫描 `Data/`，库文件缺失自动新建空库，连不上/缺表则日志报错并把 `/api/health` 置为 `degraded` |
| 健康检查 | `GET /api/health` 返回 `db_configured` / `db_tables_ok` / `detail`，可直观判断库是否连上 |
| 守护脚本 | 重写为 `backend/run_service_guard.py`（精确管控 PID，避免误杀其他 python 进程），其解释器探测逻辑与 `pick_python.bat` 保持一致 |

### 9.1 启动脚本二次修正（2026-09-11 傍晚）

**问题**：双击 `start_web.bat` 弹出乱码错误框，内容是"解释器 ... 缺少依赖且自动安装失败"。

**根因**（两个独立缺陷叠加）：

1. **解释器被误选**：记忆文件里记的 Store 版 `python3.11.exe` 已从本机移除，脚本回退到 PATH 扫描，
   选中 `C:\Users\Administrator\.local\bin\python3.11.exe` —— 那是 **uv 托管**的解释器（指向
   `%APPDATA%\uv\python\cpython-3.11.15`），既没有任何项目依赖，又是 PEP 668 `externally-managed`，
   `pip install -r requirements.txt` 被直接拒绝，于是必然失败。
   旧逻辑的判定标准是"能 `import sys`"，没有校验业务依赖，这是关键漏洞。
2. **弹框乱码**：`start_web.bat` 实际保存为 **ANSI(GBK)**，脚本里却执行了 `chcp 65001`（UTF-8），
   cmd 于是按 UTF-8 解析 GBK 字节，传给 PowerShell 的中文全变成乱码。

**已修正**：

- 新增 **`backend\pick_python.bat`** 作为唯一选择器（`start_web.bat` / `诊断启动.bat` / `start_web_daemon.bat` 共用）：
  以「全量依赖可导入」为唯一判定标准；全部不合格时才自动装依赖，并使用腾讯镜像
  （本机直连 pypi.org 不稳定）；最后兜底创建项目 `.venv`。
- 端口预检提前到脚本第一步：服务已在运行则**只打开浏览器**，不再弹错。
- **文件编码约定**（改这些脚本时务必遵守，否则中文必乱）：

| 文件 | 编码 | 是否 `chcp 65001` | 说明 |
|------|------|------------------|------|
| `backend\pick_python.bat` | 纯 ASCII | 否 | 会被不同代码页的父脚本 `call`，**绝不能出现中文** |
| `start_web.bat` / `stop_web.bat` | ANSI(GBK) | 否 | 弹框中文依赖 CP936；加了 chcp 65001 就乱码 |
| `诊断启动.bat` / `start_web_daemon.bat` | UTF-8 | **是**，且放在第 2 行 | 本机 `PYTHONUTF8=1`/`PYTHONIOENCODING=utf-8`，Python 输出 UTF-8，必须切码页；这两个文件的 `rem` 注释也要保持纯 ASCII，否则会在切码页前被解析成杂散命令 |

**验证结果**（2026-09-11 18:30）：`诊断启动.bat` 全绿；`start_web.bat` 启动成功，
`/api/health` 返回 `status=ok / database=ok / db_tables_ok=true`；登录链路浏览器端到端
`check_login_e2e.js` 返回 `PASS:true`；`backend` 下 5 套回归共 155 断言全部通过。

**排查入口**：

- 双击 **`诊断启动.bat`** —— 列出所有候选解释器及依赖状态，并跑完整启动链路自检
- 或命令行：`python backend/check_startup.py`（输出解释器/依赖/配置/数据库/关键表/连接池/结论）
- 查看日志：`logs\launcher.log`、`logs\web_service.log`、`logs\service_guard.log`

**关键日志判读**：

```
启动数据库连接：OK —— ...\Data\ZHMY_Contract_SQLite_2026.db（来源: config.json/database_path）
```
出现上面这行即表示数据库已自动连接成功。若出现 `FAIL` / `WARN`，按提示处理：
配置未配路径 → 回退扫描；库文件不存在 → 自动新建空库（admin/admin）；
关键表缺失 → 「系统设置 → 初始化数据」；解释器选错 → 删 `backend\.python_exe.txt` 后重开。

