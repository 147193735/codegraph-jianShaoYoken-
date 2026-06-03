@echo off
chcp 65001 >nul 2>&1
title CodeGraph 快速工具 v2.0
color 0B
setlocal enabledelayedexpansion
@echo off

:: ============================================
:: CodeGraph 路径智能检测
:: ============================================
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: 优先使用全局安装的 codegraph
where codegraph 2>nul >nul
if not errorlevel 1 (
    set "CODEGRAPH=codegraph"
    goto :detect_done
)

:: 查找 node 路径
set "NODE_CMD=node"
where node 2>nul >nul
if errorlevel 1 (
    if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_CMD=%ProgramFiles%\nodejs\node.exe"
)

:: ============================================
:: 检查本地构建 + 依赖完整性
:: ============================================
set "LOCAL_DIR="
if exist "%SCRIPT_DIR%\dist\bin\codegraph.js" set "LOCAL_DIR=%SCRIPT_DIR%"
if exist "%SCRIPT_DIR%\..\dist\bin\codegraph.js" set "LOCAL_DIR=%SCRIPT_DIR%\.."

if defined LOCAL_DIR (
    :: 检查依赖是否存在
    if exist "!LOCAL_DIR!\node_modules\commander" (
        set "CODEGRAPH="%NODE_CMD%" "!LOCAL_DIR!\dist\bin\codegraph.js""
        goto :detect_done
    )
    :: 依赖缺失，自动安装
    echo(检测到编译产物但依赖缺失，正在自动安装...
    echo.
    pushd "!LOCAL_DIR!"
    call npm ci --no-audit --no-fund 2>&1
    popd
    if not errorlevel 1 (
        set "CODEGRAPH="%NODE_CMD%" "!LOCAL_DIR!\dist\bin\codegraph.js""
        echo(依赖安装完成!
        echo.
        goto :detect_done
    )
    echo.
)

:: ============================================
:: 自动编译：如果检测到是 codegraph 仓库但未编译，自动执行构建
:: ============================================
echo(检测到 codegraph 源码但未编译，正在自动构建...
echo.

:: 尝试在脚本所在目录构建
if exist "%SCRIPT_DIR%\package.json" (
    pushd "%SCRIPT_DIR%"
    goto :do_build
)
:: 尝试在上级目录构建
if exist "%SCRIPT_DIR%\..\package.json" (
    pushd "%SCRIPT_DIR%\.."
    goto :do_build
)
goto :build_failed

:do_build
echo(--- 安装依赖 ---
call npm ci --no-audit --no-fund 2>&1
if errorlevel 1 (
    popd
    goto :build_failed
)
echo.
echo(--- 构建 codegraph ---
call npm run build 2>&1
if errorlevel 1 (
    popd
    goto :build_failed
)
popd

:: 构建完成后重新检测
set "LOCAL_DIR="
if exist "%SCRIPT_DIR%\dist\bin\codegraph.js" set "LOCAL_DIR=%SCRIPT_DIR%"
if exist "%SCRIPT_DIR%\..\dist\bin\codegraph.js" set "LOCAL_DIR=%SCRIPT_DIR%\.."
if defined LOCAL_DIR (
    set "CODEGRAPH="%NODE_CMD%" "!LOCAL_DIR!\dist\bin\codegraph.js""
    echo(构建成功!
    echo.
    goto :detect_done
)

:build_failed
echo.
echo([错误] codegraph 未找到或编译失败！
echo(请手动执行: cd /d "%SCRIPT_DIR%" ^&^& npm ci ^&^& npm run build
echo(或全局安装: npm i -g @colbymchenry/codegraph
pause
exit /b 1

:detect_done

:: ============================================
:: 拖放支持：拖入文件夹后自动切换到目标目录
:: ============================================
if not "%~1"=="" (
    set "TARGET=%~1"
    :: 如果拖入的是快捷方式(.lnk)，自动解析目标路径
    if /i "%~x1"==".lnk" (
        for /f "delims=" %%t in ('powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%~f1'); Write-Output $s.TargetPath" 2^>nul') do set "TARGET=%%t"
        if "!TARGET!"=="%~f1" (
            echo [错误] 无法解析快捷方式!
            pause
            exit /b 1
        )
    )
    pushd "!TARGET!" 2>nul
    if errorlevel 1 (
        echo [错误] 无法进入目录: !TARGET!
        pause
        exit /b 1
    )
    cls
    echo ================================================
    echo      CodeGraph 快速工具 v2.0
    echo      语义代码知识图谱 --- 命令行助手
    echo ================================================
    echo.
    echo  拖入目标: !TARGET!
    echo  已切换到: %CD%
    echo.
    echo  按任意键进入主菜单...
    pause >nul
)

:menu
:: 检测 VS Code MCP 配置状态
set "MCP_ICON="
set "MCP_CFG=%APPDATA%\Code\User\mcp.json"
if exist "%MCP_CFG%" (
    findstr /i "codegraph" "%MCP_CFG%" >nul 2>&1 && set "MCP_ICON=[MCP:ON]"
)

cls
echo ================================================
echo(     CodeGraph 快速工具 v2.0
echo(     语义代码知识图谱 --- 命令行助手
echo ================================================
echo.
echo( 当前目录: %CD%    %MCP_ICON%
echo.
echo( ---查看分析---     ---搜索追踪----------
set "M1= [1]项目状态        [3]搜索符号   [4]查找调用者"
set "M2= [2]文件结构        [5]查被调者   [6]影响分析"
set "M3=                    [7]查找受影响测试"
echo(!M1!
echo(!M2!
echo(!M3!
echo.
echo( ---索引维护---     ---服务与配置--------
echo( [8]初始化项目      [11]MCP服务   [12]配置MCP
echo( [9]重新索引        [13]卸载配置   [14]帮助
echo( [10]增量同步
echo.
echo( -----------------------------------------------
echo(  [0]退出
echo.
set /p choice="请输入选项 (0-14): "

if "%choice%"=="1" goto status
if "%choice%"=="2" goto files
if "%choice%"=="3" goto query
if "%choice%"=="4" goto callers
if "%choice%"=="5" goto callees
if "%choice%"=="6" goto impact
if "%choice%"=="7" goto affected
if "%choice%"=="8" goto init
if "%choice%"=="9" goto index
if "%choice%"=="10" goto sync
if "%choice%"=="11" goto serve
if "%choice%"=="12" goto vscode_mcp
if "%choice%"=="13" goto uninstall
if "%choice%"=="14" goto help
if "%choice%"=="0" exit /b
goto menu

:status
cls
echo ================================================
echo(             项目状态检查
echo ================================================
echo.
%CODEGRAPH% status
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:files
cls
echo ================================================
echo(             项目文件结构
echo ================================================
echo.
echo(格式选项: tree(树形) flat(列表) grouped(按语言)
set /p fmt="请输入格式 (默认 tree): "
if "%fmt%"=="" set fmt=tree
echo.
echo(筛选目录(可选，直接回车跳过):
set /p filter="请输入目录路径: "
echo.
if "%filter%"=="" (
    %CODEGRAPH% files --format %fmt%
) else (
    %CODEGRAPH% files --format %fmt% --filter "%filter%"
)
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:query
cls
echo ================================================
echo(             搜索代码符号
echo ================================================
echo.
set /p symbol="请输入要搜索的符号名称: "
if "%symbol%"=="" goto query
echo.
echo(正在搜索 "%symbol%"...
echo.
%CODEGRAPH% query "%symbol%"
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:callers
cls
echo ================================================
echo(             查找调用者
echo ================================================
echo.
set /p symbol="请输入符号名称: "
if "%symbol%"=="" goto callers
echo.
echo(正在查找 "%symbol%" 的调用者...
echo.
%CODEGRAPH% callers "%symbol%"
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:callees
cls
echo ================================================
echo(             查找被调用者
echo ================================================
echo.
set /p symbol="请输入符号名称: "
if "%symbol%"=="" goto callees
echo.
echo(正在查找 "%symbol%" 调用了什么...
echo.
%CODEGRAPH% callees "%symbol%"
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:impact
cls
echo ================================================
echo(             分析变更影响
echo ================================================
echo.
set /p symbol="请输入要分析的符号名称: "
if "%symbol%"=="" goto impact
set /p depth="请输入分析深度 (默认 2): "
if "%depth%"=="" set depth=2
echo.
echo(正在分析 "%symbol%" 的影响范围 (深度=%depth%)...
echo.
%CODEGRAPH% impact "%symbol%" --depth %depth%
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:affected
cls
echo ================================================
echo(         查找受影响的测试文件
echo ================================================
echo.
echo(输入源文件路径(空格分隔多个文件，或直接回车使用 git diff)
echo(示例: src/utils.ts src/api.ts
echo.
set /p files="请输入文件路径: "
echo.
if "%files%"=="" (
    echo 正在使用 git diff 检测变更文件...
    echo.
    %CODEGRAPH% affected --stdin
) else (
    echo 正在查找受影响的测试文件...
    echo.
    %CODEGRAPH% affected %files%
)
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:init
cls
echo ================================================
echo(             初始化 CodeGraph
echo ================================================
echo.
echo(正在初始化项目并构建索引...
echo.
%CODEGRAPH% init -i
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:index
cls
echo ================================================
echo(             重新索引项目
echo ================================================
echo.
echo(警告: 将清除现有索引并重新构建!
set /p confirm="确认重新索引? (y/n): "
if /i "%confirm%"=="y" (
    echo.
    echo 正在执行完整重新索引...
    echo.
    %CODEGRAPH% index --force
) else (
    echo 已取消。
)
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:sync
cls
echo ================================================
echo(             增量同步索引
echo ================================================
echo.
echo(正在同步最新的文件变更...
echo.
%CODEGRAPH% sync
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:serve
cls
echo ================================================
echo(          启动 MCP 服务
echo ================================================
echo.
echo(正在启动 MCP 服务...
echo(按 Ctrl+C 停止服务
echo.
%CODEGRAPH% serve --mcp
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:vscode_mcp
cls
echo ================================================
echo(        配置 VS Code MCP 服务器
echo ================================================
echo.
set "MCP_DIR=%APPDATA%\Code\User"

if not exist "%MCP_DIR%" (
    echo [错误] 未找到 VS Code 配置目录!
    echo 请确保已安装 VS Code 并至少运行过一次。
    echo.
    pause
    goto menu
)

:: 检查是否已配置
set "MCP_ALREADY="
if exist "%MCP_DIR%\mcp.json" (
    findstr /i "codegraph" "%MCP_DIR%\mcp.json" >nul 2>&1 && set "MCP_ALREADY=1"
)

if defined MCP_ALREADY (
    echo 检测到 VS Code MCP 已配置!
    echo   - 文件: %MCP_DIR%\mcp.json
    echo.
    set /p overwrite="是否重新配置? (y/n): "
)
if defined MCP_ALREADY (
    if /i "!overwrite!"=="n" goto :vscode_skip
    if /i "!overwrite!"=="" goto :vscode_skip
    echo.
)

if exist "%MCP_DIR%\mcp.json" (
    copy "%MCP_DIR%\mcp.json" "%MCP_DIR%\mcp.json.bak" >nul
    echo 已备份现有配置为 mcp.json.bak
    echo.
)

echo(正在写入 MCP 配置...
echo.

:: 构建 MCP JSON 配置
> "%MCP_DIR%\mcp.json" (
    echo {
    echo     "servers": {
    echo         "codegraph": {
    echo             "type": "stdio",
    echo             "command": "node",
    echo             "args": [
    echo                 "%SCRIPT_DIR:\=\\%\\dist\\bin\\codegraph.js",
    echo                 "serve",
    echo                 "--mcp"
    echo             ]
    echo         }
    echo     }
    echo }
)

echo(配置完成!
echo(文件位置: %MCP_DIR%\mcp.json
echo.
echo(请重启 VS Code 使配置生效。
echo(重启后在 Copilot Chat 中问: "用 codegraph 查一下项目状态"
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:vscode_skip
echo(已取消。
echo.
pause
goto menu

:uninstall
cls
echo ================================================
echo(             卸载 CodeGraph
echo ================================================
echo.
echo(警告: 这将从所有已配置的代理中移除 CodeGraph!
echo.
set /p confirm="确认卸载? (y/n): "
if /i "%confirm%"=="y" (
    %CODEGRAPH% uninstall
    echo.
    echo 卸载完成。
) else (
    echo 已取消。
)
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu

:help
cls
echo ================================================
echo(             帮助信息
echo ================================================
echo.
echo(CodeGraph 是一个本地优先的语义代码知识图谱工具。
echo(它为 AI 编码助手(Claude Code、Cursor、Codex 等)
echo(提供代码结构查询能力，比传统的 grep/搜索快 70%%。
echo.
echo(主要功能:
echo(  * 代码符号索引 --- 函数、类、方法、变量等
echo(  * 调用关系追踪 --- 调用者/被调用者分析
echo(  * 影响范围分析 --- 修改前评估影响
echo(  * 全文本搜索 --- 基于 FTS5 的快速搜索
echo(  * 自动同步 --- 文件变更后自动更新索引
echo(  * 20+ 语言支持 --- TS/JS/Python/Go/Rust/Java 等
echo(  * 框架感知路由 --- Django/Flask/Express/Spring 等
echo.
echo(拖放用法: 将项目文件夹拖到此 .bat 文件上即可直接操作
echo.
echo(更多信息: https://colbymchenry.github.io/codegraph/
echo.
echo ------------------------------------------------
echo(按任意键返回主菜单...
pause >nul
goto menu
