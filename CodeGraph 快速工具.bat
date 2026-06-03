@echo off
chcp 65001 >nul 2>&1
title CodeGraph 快速工具
color 0B

:: ============================================
:: CodeGraph 路径配置（按你的实际情况修改）
:: ============================================
:: 使用 Node.js 22（CodeGraph 要求 Node.js 20+）
set NODE22=C:\Program Files\nodejs\node.exe
::
:: 方式A：使用本地构建（无需安装）
set CODEGRAPH="%NODE22%" D:\LAYADOMO\codegraph\dist\bin\codegraph.js
::
:: 方式B：如果 codegraph 已全局安装，用下面这行取代上面那行
:: set CODEGRAPH=codegraph
:: ============================================

:menu
cls
echo ================================================
echo      CodeGraph 快速工具 v1.0
echo      语义代码知识图谱 --- 命令行助手
echo ================================================
echo.
echo 当前项目: %CD%
echo.
echo 请选择操作:
echo.
echo   [1] 查看项目状态  (%%CODEGRAPH%% status)
echo   [2] 初始化项目    (%%CODEGRAPH%% init -i)
echo   [3] 重新索引      (%%CODEGRAPH%% index --force)
echo   [4] 增量同步      (%%CODEGRAPH%% sync)
echo   [5] 搜索符号      (%%CODEGRAPH%% query)
echo   [6] 分析影响      (%%CODEGRAPH%% impact)
echo   [7] 启动 MCP 服务 (%%CODEGRAPH%% serve --mcp)
echo   [8] 卸载配置      (%%CODEGRAPH%% uninstall)
echo   [9] 查看帮助      (%%CODEGRAPH%% --help)
echo.
echo   [0] 退出
echo.
set /p choice="请输入选项 (0-9): "

if "%choice%"=="1" goto status
if "%choice%"=="2" goto init
if "%choice%"=="3" goto index
if "%choice%"=="4" goto sync
if "%choice%"=="5" goto query
if "%choice%"=="6" goto impact
if "%choice%"=="7" goto serve
if "%choice%"=="8" goto uninstall
if "%choice%"=="9" goto help
if "%choice%"=="0" exit /b
goto menu

:status
cls
echo ================================================
echo              项目状态检查
echo ================================================
echo.
%CODEGRAPH% status
echo.
echo ------------------------------------------------
echo 按任意键返回主菜单...
pause >nul
goto menu

:init
cls
echo ================================================
echo              初始化 CodeGraph
echo ================================================
echo.
echo 正在初始化项目并构建索引...
echo.
%CODEGRAPH% init -i
echo.
echo ------------------------------------------------
echo 按任意键返回主菜单...
pause >nul
goto menu

:index
cls
echo ================================================
echo              重新索引项目
echo ================================================
echo.
echo 正在执行完整重新索引...
echo.
%CODEGRAPH% index --force
echo.
echo ------------------------------------------------
echo 按任意键返回主菜单...
pause >nul
goto menu

:sync
cls
echo ================================================
echo              增量同步索引
echo ================================================
echo.
echo 正在同步最新的文件变更...
echo.
%CODEGRAPH% sync
echo.
echo ------------------------------------------------
echo 按任意键返回主菜单...
pause >nul
goto menu

:query
cls
echo ================================================
echo              搜索代码符号
echo ================================================
echo.
set /p symbol="请输入要搜索的符号名称: "
if "%symbol%"=="" goto query
echo.
echo 正在搜索 "%symbol%"...
echo.
%CODEGRAPH% query "%symbol%"
echo.
echo ------------------------------------------------
echo 按任意键返回主菜单...
pause >nul
goto menu

:impact
cls
echo ================================================
echo              分析变更影响
echo ================================================
echo.
set /p symbol="请输入要分析的符号名称: "
if "%symbol%"=="" goto impact
set /p depth="请输入分析深度 (默认 2): "
if "%depth%"=="" set depth=2
echo.
echo 正在分析 "%symbol%" 的影响范围 (深度=%depth%)...
echo.
%CODEGRAPH% impact "%symbol%" --depth %depth%
echo.
echo ------------------------------------------------
echo 按任意键返回主菜单...
pause >nul
goto menu

:serve
cls
echo ================================================
echo           启动 MCP 服务
echo ================================================
echo.
echo 正在启动 MCP 服务...
echo 按 Ctrl+C 停止服务
echo.
%CODEGRAPH% serve --mcp
echo.
echo ------------------------------------------------
echo 按任意键返回主菜单...
pause >nul
goto menu

:uninstall
cls
echo ================================================
echo              卸载 CodeGraph
echo ================================================
echo.
echo 警告: 这将从所有已配置的代理中移除 CodeGraph！
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
echo 按任意键返回主菜单...
pause >nul
goto menu

:help
cls
echo ================================================
echo              帮助信息
echo ================================================
echo.
echo CodeGraph 是一个本地优先的语义代码知识图谱工具。
echo 它为 AI 编码助手（Claude Code、Cursor、Codex 等）
echo 提供代码结构查询能力，比传统的 grep/搜索快 70%。
echo.
echo 主要功能:
echo   * 代码符号索引 --- 函数、类、方法、变量等
echo   * 调用关系追踪 --- 调用者/被调用者分析
echo   * 影响范围分析 --- 修改前评估影响
echo   * 全文本搜索 --- 基于 FTS5 的快速搜索
echo   * 自动同步 --- 文件变更后自动更新索引
echo   * 20+ 语言支持 --- TS/JS/Python/Go/Rust/Java 等
echo   * 框架感知路由 --- Django/Flask/Express/Spring 等
echo.
echo 更多信息: https://colbymchenry.github.io/codegraph/
echo.
echo ------------------------------------------------
echo 按任意键返回主菜单...
pause >nul
goto menu
