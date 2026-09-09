@echo off
chcp 65001 >nul 2>&1
title CodeGraph Quick Tool v2.3
color 0B
setlocal enabledelayedexpansion

rem ============================================
rem CodeGraph detection and setup
rem ============================================
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

rem Step 1: detect Node.js
set "NODE_CMD=node"
where node 2>nul >nul
if errorlevel 1 (
    if exist "%ProgramFiles%\nodejs\node.exe" (
        set "NODE_CMD=%ProgramFiles%\nodejs\node.exe"
    ) else (
        echo [ERROR] Node.js was not found.
        echo.
        echo CodeGraph requires Node.js version 20 through 24.
        echo Install Node.js 20 or 22 LTS from https://nodejs.org first.
        echo.
        pause
        exit /b 1
    )
)

rem Step 2: require the global CLI only when no local build is available.
if not exist "%SCRIPT_DIR%\dist\bin\codegraph.js" call :ensure_global_codegraph
if errorlevel 1 exit /b 1
set "CODEGRAPH=codegraph"

rem Step 3: prepare a local development checkout
rem Ensure dependencies and dist are available when package.json is present.
if exist "%SCRIPT_DIR%\package.json" (
    echo.
    echo [*] Local development checkout detected. Checking build files...

    rem Install dependencies when TypeScript is missing.
    if not exist "%SCRIPT_DIR%\node_modules\typescript" (
        echo [*] npm install -- installing project dependencies...
        echo.
        cd /d "%SCRIPT_DIR%"
        call npm install
        if errorlevel 1 (
            echo.
            echo [WARN] npm install failed. Some features may be unavailable.
        )
        echo.
    )

    rem Build the local CLI when its entry point is missing.
    if not exist "%SCRIPT_DIR%\dist\bin\codegraph.js" (
        echo [*] npm run build -- compiling TypeScript into dist...
        echo.
        cd /d "%SCRIPT_DIR%"
        call npm run build
        if errorlevel 1 (
            echo.
            echo [WARN] npm run build failed. The global command will be used.
        ) else (
            echo [OK] Local build completed.
        )
        echo.
    )
)

rem Step 4: prefer the local build and pin MCP entries to it.
rem Fall back to the global codegraph command only when no local build exists.
set "CG_MCP_CMD=codegraph"
set "CG_MCP_SCRIPT="
set "CODEGRAPH_MCP_COMMAND="
set "CODEGRAPH_MCP_SCRIPT="
if exist "%SCRIPT_DIR%\dist\bin\codegraph.js" (
    set "CODEGRAPH=node "%SCRIPT_DIR%\dist\bin\codegraph.js""
    set "CG_MCP_CMD=node"
    set "CG_MCP_SCRIPT=%SCRIPT_DIR%\dist\bin\codegraph.js"
    set "CODEGRAPH_MCP_COMMAND=node"
    set "CODEGRAPH_MCP_SCRIPT=%SCRIPT_DIR%\dist\bin\codegraph.js"
)

:detect_done

rem ============================================
rem Drag-and-drop target directory support
rem ============================================
if not "%~1"=="" (
    set "TARGET=%~1"
    rem Resolve a dropped shortcut before changing directories.
    if /i "%~x1"==".lnk" (
        for /f "delims=" %%t in ('powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%~f1'); Write-Output $s.TargetPath" 2^>nul') do set "TARGET=%%t"
        if "!TARGET!"=="%~f1" (
            echo [ERROR] Unable to resolve the shortcut target.
            pause
            exit /b 1
        )
    )
    pushd "!TARGET!" 2>nul
    if errorlevel 1 (
        echo [ERROR] Unable to enter directory: !TARGET!
        pause
        exit /b 1
    )
)

:menu
:: Detect VS Code, Cursor, and Codex MCP configuration independently.
set "MCP_VSCODE=OFF"
set "MCP_CURSOR=OFF"
set "MCP_CODEX=OFF"
set "MCP_VSCODE_CFG=%APPDATA%\Code\User\mcp.json"
set "MCP_CURSOR_LOCAL_CFG=%CD%\.cursor\mcp.json"
set "MCP_CURSOR_GLOBAL_CFG=%USERPROFILE%\.cursor\mcp.json"
set "MCP_CODEX_CFG=%USERPROFILE%\.codex\config.toml"
if exist "%MCP_VSCODE_CFG%" (
    findstr /i "codegraph" "%MCP_VSCODE_CFG%" >nul 2>&1 && set "MCP_VSCODE=ON"
)
if exist "%MCP_CURSOR_LOCAL_CFG%" (
    findstr /i "codegraph" "%MCP_CURSOR_LOCAL_CFG%" >nul 2>&1 && set "MCP_CURSOR=LOCAL"
) else if exist "%MCP_CURSOR_GLOBAL_CFG%" (
    findstr /i "codegraph" "%MCP_CURSOR_GLOBAL_CFG%" >nul 2>&1 && set "MCP_CURSOR=GLOBAL"
)
if exist "%MCP_CODEX_CFG%" (
    findstr /i "mcp_servers.codegraph" "%MCP_CODEX_CFG%" >nul 2>&1 && set "MCP_CODEX=ON"
)

cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\scripts\show-menu.ps1" -CurrentDir "%CD%" -McpVscode "%MCP_VSCODE%" -McpCursor "%MCP_CURSOR%" -McpCodex "%MCP_CODEX%"
echo.
set /p "choice=Choose an option (0-14): "

if "!choice!"=="1" goto status
if "!choice!"=="2" goto files
if "!choice!"=="3" goto query
if "!choice!"=="4" goto callers
if "!choice!"=="5" goto callees
if "!choice!"=="6" goto impact
if "!choice!"=="7" goto affected
if "!choice!"=="8" goto init
if "!choice!"=="9" goto index
if "!choice!"=="10" goto sync
if "!choice!"=="11" goto serve
if "!choice!"=="12" goto mcp_menu
if "!choice!"=="13" goto uninstall
if "!choice!"=="14" goto help
if "!choice!"=="0" goto safe_exit
goto menu

:status
cls
echo ----------------------------------------------
echo              Project Status
echo ----------------------------------------------
echo.
call %CODEGRAPH% status
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:files
cls
echo ----------------------------------------------
echo              Project Files
echo ----------------------------------------------
echo.
echo Formats: tree, flat, grouped
set /p "fmt=Choose format (default tree): "
if "!fmt!"=="" set fmt=tree
echo.
echo Optional directory filter. Leave blank to skip.
set /p "filter=Directory path: "
echo.
if "!filter!"=="" (
    call %CODEGRAPH% files --format %fmt%
) else (
    call %CODEGRAPH% files --format %fmt% --filter "%filter%"
)
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:query
cls
echo ----------------------------------------------
echo              Search Symbol
echo ----------------------------------------------
echo.
set /p "symbol=Symbol name: "
if "!symbol!"=="" goto query
echo.
echo Searching "%symbol%"...
echo.
call %CODEGRAPH% query "%symbol%"
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:callers
cls
echo ----------------------------------------------
echo              Find Callers
echo ----------------------------------------------
echo.
set /p "symbol=Symbol name: "
if "!symbol!"=="" goto callers
echo.
echo Finding callers of "%symbol%"...
echo.
call %CODEGRAPH% callers "%symbol%"
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:callees
cls
echo ----------------------------------------------
echo              Find Callees
echo ----------------------------------------------
echo.
set /p "symbol=Symbol name: "
if "!symbol!"=="" goto callees
echo.
echo Finding callees of "%symbol%"...
echo.
call %CODEGRAPH% callees "%symbol%"
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:impact
cls
echo ----------------------------------------------
echo              Analyze Impact
echo ----------------------------------------------
echo.
set /p "symbol=Symbol name: "
if "!symbol!"=="" goto impact
set /p "depth=Analysis depth (default 2): "
if "!depth!"=="" set depth=2
echo.
echo Analyzing impact for "%symbol%" (depth=%depth%)...
echo.
call %CODEGRAPH% impact "%symbol%" --depth %depth%
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:affected
cls
echo ----------------------------------------------
echo           Find Affected Tests
echo ----------------------------------------------
echo.
echo Source file paths separated by spaces.
echo Leave blank to compare the latest Git commit.
echo Example: src/utils.ts src/api.ts
echo.
set /p files="File paths: "
echo.
if not "!files!"=="" goto :affected_files
echo Detecting changed files with git diff...
echo.
git diff --name-only HEAD~1 2>nul | %CODEGRAPH% affected --stdin
goto :affected_done

:affected_files
echo Finding affected test files...
echo.
call %CODEGRAPH% affected %files%

:affected_done
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:init
cls
echo ----------------------------------------------
echo              Initialize CodeGraph
echo ----------------------------------------------
echo.
echo Initializing the project and building its index...
echo.
call %CODEGRAPH% init -i
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:index
cls
echo ----------------------------------------------
echo              Reindex Project
echo ----------------------------------------------
echo.
echo Warning: this removes the existing index and rebuilds it.
set /p "confirm=Reindex project? (y/n): "
if /i "!confirm!"=="y" (
    echo.
    echo Running full reindex...
    echo.
    call %CODEGRAPH% index --force
) else (
    echo Cancelled.
)
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:sync
cls
echo ----------------------------------------------
echo              Incremental Sync
echo ----------------------------------------------
echo.
echo Syncing recent file changes...
echo.
call %CODEGRAPH% sync
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:serve
cls
echo ----------------------------------------------
echo             Start MCP Server
echo ----------------------------------------------
echo.
echo Starting MCP server...
echo Press Ctrl+C to stop the server.
echo.
call %CODEGRAPH% serve --mcp
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:mcp_menu
cls
echo ----------------------------------------------
echo      Configure MCP (VS Code / Cursor / Codex)
echo ----------------------------------------------
echo.
echo  VS Code, Cursor, and Codex use separate configuration files:
echo    VS Code   %%APPDATA%%\Code\User\mcp.json
echo    Cursor    local .cursor\mcp.json or global %%USERPROFILE%%\.cursor\mcp.json
echo    Codex     %%USERPROFILE%%\.codex\config.toml (global)
echo.
echo  Status: VS Code=%MCP_VSCODE%  Cursor=%MCP_CURSOR%  Codex=%MCP_CODEX%
echo.
echo  [1] Configure VS Code Copilot MCP (global)
echo  [2] Configure Cursor MCP (local project)
echo  [3] Configure Cursor MCP (global)
echo  [4] Configure VS Code plus Cursor (local project)
echo  [5] Register Codex MCP (global)
echo  [6] Configure global MCP (Claude / Cursor / Codex / VS Code Copilot)
echo  [0] Return to main menu
echo.
set /p "mcp_choice=Choose an option (0-6): "
if "!mcp_choice!"=="1" goto mcp_config_vscode
if "!mcp_choice!"=="2" goto mcp_config_cursor_local
if "!mcp_choice!"=="3" goto mcp_config_cursor_global
if "!mcp_choice!"=="4" goto mcp_config_both
if "!mcp_choice!"=="5" goto mcp_config_codex
if "!mcp_choice!"=="6" goto mcp_config_other
if "!mcp_choice!"=="0" goto menu
goto mcp_menu

:mcp_config_vscode
call :mcp_write_vscode
echo.
echo [OK] VS Code MCP written: %MCP_VSCODE_CFG%
echo      Restart VS Code to load the configuration.
echo.
echo ----------------------------------------------
echo Press any key to return...
pause >nul
goto mcp_menu

:mcp_config_cursor_local
call :mcp_write_cursor_local
echo.
echo [OK] Cursor MCP written: %MCP_CURSOR_LOCAL_CFG%
echo      Restart Cursor to load the configuration.
echo.
echo ----------------------------------------------
echo Press any key to return...
pause >nul
goto mcp_menu

:mcp_config_cursor_global
call :mcp_write_cursor_global
echo.
echo [OK] Cursor MCP written: %MCP_CURSOR_GLOBAL_CFG%
echo      Restart Cursor to load the configuration.
echo.
echo ----------------------------------------------
echo Press any key to return...
pause >nul
goto mcp_menu

:mcp_config_both
call :mcp_write_vscode
call :mcp_write_cursor_local
echo.
echo [OK] VS Code and Cursor were configured for this project.
echo      Restart VS Code and Cursor to load the configuration.
echo.
echo ----------------------------------------------
echo Press any key to return...
pause >nul
goto mcp_menu

:mcp_config_codex
cls
echo ----------------------------------------------
echo          Register Codex MCP (Global)
echo ----------------------------------------------
echo.
echo This registers CodeGraph for every Codex project:
echo   %%USERPROFILE%%\.codex\config.toml
echo.
echo Registering...
echo.
call %CODEGRAPH% install --target=codex --location=global --yes
if errorlevel 1 (
    echo.
    echo [ERROR] Codex MCP registration failed. Review the output above.
) else (
    echo.
    echo [OK] Codex MCP is registered.
    echo      Restart Codex or start a new session to load codegraph_explore.
)
echo.
echo ----------------------------------------------
echo Press any key to return...
pause >nul
goto mcp_menu

:mcp_config_other
@echo off
cls
echo ----------------------------------------------
echo            Configure Global MCP
echo ----------------------------------------------
echo.
echo Targets: Claude Code, Cursor, Codex CLI, VS Code Copilot
echo Scope: global, all projects
echo Claude also receives CodeGraph permissions and an instructions block.
echo.
call %CODEGRAPH% install --target=claude,cursor,codex,copilot-vscode --location=global --yes
if errorlevel 1 (
    echo.
    echo [ERROR] Global MCP configuration failed. Review the output above.
) else (
    echo.
    echo [OK] Global MCP configuration completed. Restart the affected tools.
)
echo.
echo ----------------------------------------------
echo Press any key to return...
pause >nul
goto mcp_menu

rem ============================================
rem MCP configuration writer
rem ============================================
:mcp_write_vscode
set "MCP_WRITE_CFG=%MCP_VSCODE_CFG%"
set "MCP_WRITE_KEY=servers"
set "MCP_WRITE_PATH_ARG="
call :mcp_write_json
exit /b 0

:mcp_write_cursor_local
if not exist "%CD%\.cursor" mkdir "%CD%\.cursor"
set "MCP_WRITE_CFG=%CD%\.cursor\mcp.json"
set "MCP_WRITE_KEY=mcpServers"
set "MCP_WRITE_PATH_ARG=%CD%"
call :mcp_write_json
exit /b 0

:mcp_write_cursor_global
if not exist "%USERPROFILE%\.cursor" mkdir "%USERPROFILE%\.cursor"
set "MCP_WRITE_CFG=%USERPROFILE%\.cursor\mcp.json"
set "MCP_WRITE_KEY=mcpServers"
set "MCP_WRITE_PATH_ARG=${workspaceFolder}"
call :mcp_write_json
exit /b 0

:mcp_write_json
set "MCP_ENV_CFG=%MCP_WRITE_CFG%"
set "MCP_ENV_KEY=%MCP_WRITE_KEY%"
set "MCP_ENV_PATH_ARG=%MCP_WRITE_PATH_ARG%"
set "MCP_ENV_CMD=%CG_MCP_CMD%"
set "MCP_ENV_SCRIPT=%CG_MCP_SCRIPT%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$cfgPath=$env:MCP_ENV_CFG; $topKey=$env:MCP_ENV_KEY; $pathArg=$env:MCP_ENV_PATH_ARG;" ^
  "$cmd=$env:MCP_ENV_CMD; $script=$env:MCP_ENV_SCRIPT; if(-not $cmd){$cmd='codegraph'};" ^
  "$dir=Split-Path $cfgPath -Parent; if(-not(Test-Path $dir)){New-Item -ItemType Directory -Path $dir -Force|Out-Null};" ^
  "$obj=$null; if((Test-Path $cfgPath)-and((Get-Item $cfgPath).Length -gt 0)){try{$obj=Get-Content $cfgPath -Raw -Encoding UTF8|ConvertFrom-Json}catch{$obj=$null}};" ^
  "if(-not $obj){$obj=New-Object PSObject};" ^
  "if(-not $obj.PSObject.Properties[$topKey]){$obj|Add-Member -NotePropertyName $topKey -NotePropertyValue (New-Object PSObject) -Force};" ^
  "$args=@('serve','--mcp'); if($pathArg){$args+=@('--path',$pathArg)};" ^
  "if($script){$entry=@{type='stdio';command=$cmd;args=@($script)+$args}} else {$entry=@{type='stdio';command=$cmd;args=$args}};" ^
  "$obj.$topKey|Add-Member -NotePropertyName codegraph -NotePropertyValue (New-Object PSObject -Property $entry) -Force;" ^
  "$obj|ConvertTo-Json -Depth 10|Set-Content $cfgPath -Encoding UTF8"
exit /b 0

:uninstall
cls
echo ----------------------------------------------
echo              Uninstall CodeGraph
echo ----------------------------------------------
echo.
echo Warning: this removes CodeGraph from every configured agent.
echo.
set /p "confirm=Uninstall? (y/n): "
if /i "!confirm!"=="y" (
    call %CODEGRAPH% uninstall
    echo.
    echo Uninstall completed.
) else (
    echo Cancelled.
)
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

:help
cls
echo ----------------------------------------------
echo              Help
echo ----------------------------------------------
echo.
echo CodeGraph is a local-first semantic code graph tool.
echo It gives AI coding agents structural code-query capabilities.
echo It can be much faster than traditional grep-based exploration.
echo.
echo Features:
echo   * Symbol indexing for functions, classes, methods, and variables
echo   * Caller and callee tracing
echo   * Change impact analysis
echo   * FTS5 full-text search
echo   * Automatic sync after file changes
echo   * Support for more than 20 languages
echo   * Framework-aware routing
echo.
echo Drag and drop a project folder onto this .bat file to work in that folder.
echo.
echo More information: https://colbymchenry.github.io/codegraph/
echo.
echo ----------------------------------------------
echo Press any key to return to the main menu...
pause >nul
goto menu

rem ============================================
rem Safe exit and fall-through guard
rem ============================================
:safe_exit
echo.
echo Thank you for using CodeGraph.
pause >nul
exit /b

rem Return to the menu if execution reaches this point.
goto menu

:ensure_global_codegraph
where codegraph 2>nul >nul
if not errorlevel 1 exit /b 0
echo.
echo [*] CodeGraph CLI was not found. Installing globally...
echo [*] npm i -g @colbymchenry/codegraph
echo.
call npm i -g @colbymchenry/codegraph
if errorlevel 1 (
    echo.
    echo [ERROR] Global installation failed. Check your network or run:
    echo   npm i -g @colbymchenry/codegraph
    echo.
    pause
    exit /b 1
)
echo.
echo [OK] CodeGraph installation completed.
echo.
exit /b 0
