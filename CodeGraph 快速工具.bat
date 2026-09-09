@echo off
goto :cg_main

:ui
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\scripts\show-ui.ps1" -Screen "%~1" -McpVscode "%~2" -McpCursor "%~3" -McpCodex "%~4"
exit /b 0

:run_codegraph
if defined CG_LOCAL_SCRIPT goto :run_local_codegraph
codegraph %*
exit /b %ERRORLEVEL%

:run_local_codegraph
"%NODE_CMD%" "%CG_LOCAL_SCRIPT%" %*
exit /b %ERRORLEVEL%

:cg_main
chcp 65001 >nul 2>&1
title CodeGraph
color 0B
setlocal enabledelayedexpansion

rem ============================================
rem CodeGraph detection and setup
rem ============================================
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
call :ui set-title

rem Step 1: detect a compatible Node.js runtime or prepare an isolated one.
set "NODE_CMD="
where node 2>nul >nul
if not errorlevel 1 set "NODE_CMD=node"
if not defined NODE_CMD if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_CMD=%ProgramFiles%\nodejs\node.exe"

call :ensure_node_fts5
if errorlevel 1 exit /b 1

rem Step 2: require the global CLI only when no local build is available.
if not exist "%SCRIPT_DIR%\dist\bin\codegraph.js" call :ensure_global_codegraph
if errorlevel 1 exit /b 1

rem Step 3: prepare a local development checkout
rem Ensure dependencies and dist are available when package.json is present.
if exist "%SCRIPT_DIR%\package.json" (
    call :ui local-check

    rem Install dependencies when TypeScript is missing.
    if not exist "%SCRIPT_DIR%\node_modules\typescript" (
        call :ui dependencies-install
        cd /d "%SCRIPT_DIR%"
        call npm install
        if errorlevel 1 (
            call :ui dependencies-failed
        )
        echo.
    )

    rem Build the local CLI when its entry point is missing.
    if not exist "%SCRIPT_DIR%\dist\bin\codegraph.js" (
        call :ui build-start
        cd /d "%SCRIPT_DIR%"
        call npm run build
        if errorlevel 1 (
            call :ui build-failed
        ) else (
            call :ui build-complete
        )
        echo.
    )
)

rem Step 4: prefer the local build and pin MCP entries to it.
rem Fall back to the global codegraph command only when no local build exists.
set "CG_LOCAL_SCRIPT="
set "CG_MCP_CMD=codegraph"
set "CG_MCP_SCRIPT="
if exist "%SCRIPT_DIR%\dist\bin\codegraph.js" (
    set "CG_LOCAL_SCRIPT=%SCRIPT_DIR%\dist\bin\codegraph.js"
    set "CG_MCP_CMD=%NODE_CMD%"
    set "CG_MCP_SCRIPT=%SCRIPT_DIR%\dist\bin\codegraph.js"
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
            call :ui shortcut-failed
            pause >nul
            exit /b 1
        )
    )
    pushd "!TARGET!" 2>nul
    if errorlevel 1 (
        call :ui enter-directory-failed
        pause >nul
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
call :ui main-prompt
set "choice="
set /p "choice="

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
call :ui status
call :run_codegraph status
call :ui return-main
pause >nul
goto menu

:files
cls
call :ui files
set "fmt="
set /p "fmt="
if "!fmt!"=="" set fmt=tree
call :ui files-filter
set "filter="
set /p "filter="
echo.
if "!filter!"=="" (
    call :run_codegraph files --format %fmt%
) else (
    call :run_codegraph files --format %fmt% --filter "%filter%"
)
call :ui return-main
pause >nul
goto menu

:query
cls
call :ui search-symbol
set "symbol="
set /p "symbol="
if "!symbol!"=="" goto query
call :ui search-running
call :run_codegraph query "%symbol%"
call :ui return-main
pause >nul
goto menu

:callers
cls
call :ui find-callers
set "symbol="
set /p "symbol="
if "!symbol!"=="" goto callers
call :ui find-callers-running
call :run_codegraph callers "%symbol%"
call :ui return-main
pause >nul
goto menu

:callees
cls
call :ui find-callees
set "symbol="
set /p "symbol="
if "!symbol!"=="" goto callees
call :ui find-callees-running
call :run_codegraph callees "%symbol%"
call :ui return-main
pause >nul
goto menu

:impact
cls
call :ui impact
set "symbol="
set /p "symbol="
if "!symbol!"=="" goto impact
call :ui impact-depth
set "depth="
set /p "depth="
if "!depth!"=="" set depth=2
call :ui impact-running
call :run_codegraph impact "%symbol%" --depth %depth%
call :ui return-main
pause >nul
goto menu

:affected
cls
call :ui affected
set "files="
set /p files=
echo.
if not "!files!"=="" goto :affected_files
call :ui affected-git
if defined CG_LOCAL_SCRIPT (
    git diff --name-only HEAD~1 2>nul | "%NODE_CMD%" "%CG_LOCAL_SCRIPT%" affected --stdin
) else (
    git diff --name-only HEAD~1 2>nul | codegraph affected --stdin
)
goto :affected_done

:affected_files
call :ui affected-files
call :run_codegraph affected %files%

:affected_done
call :ui return-main
pause >nul
goto menu

:init
cls
call :ui initialize
call :run_codegraph init -i
call :ui return-main
pause >nul
goto menu

:index
cls
call :ui reindex
set "confirm="
set /p "confirm="
if /i "!confirm!"=="y" (
    call :ui reindex-running
    call :run_codegraph index --force
) else (
    call :ui cancelled
)
call :ui return-main
pause >nul
goto menu

:sync
cls
call :ui sync
call :run_codegraph sync
call :ui return-main
pause >nul
goto menu

:serve
cls
call :ui serve
call :run_codegraph serve --mcp
call :ui return-main
pause >nul
goto menu

:mcp_menu
cls
call :ui mcp-menu "%MCP_VSCODE%" "%MCP_CURSOR%" "%MCP_CODEX%"
set "mcp_choice="
set /p "mcp_choice="
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
call :ui mcp-vscode-success
pause >nul
goto mcp_menu

:mcp_config_cursor_local
call :mcp_write_cursor_local
call :ui mcp-cursor-project-success
pause >nul
goto mcp_menu

:mcp_config_cursor_global
call :mcp_write_cursor_global
call :ui mcp-cursor-global-success
pause >nul
goto mcp_menu

:mcp_config_both
call :mcp_write_vscode
call :mcp_write_cursor_local
call :ui mcp-both-success
pause >nul
goto mcp_menu

:mcp_config_codex
cls
call :ui mcp-codex
call :run_codegraph install --target=codex --location=global --yes
if errorlevel 1 (
    call :ui mcp-codex-failed
) else (
    call :ui mcp-codex-success
)
pause >nul
goto mcp_menu

:mcp_config_other
@echo off
cls
call :ui mcp-global
call :run_codegraph install --target=claude,cursor,codex,copilot-vscode --location=global --yes
if errorlevel 1 (
    call :ui mcp-global-failed
) else (
    call :ui mcp-global-success
)
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
call :ui uninstall
set "confirm="
set /p "confirm="
if /i "!confirm!"=="y" (
    call :run_codegraph uninstall
    call :ui uninstall-complete
) else (
    call :ui cancelled
)
call :ui return-main
pause >nul
goto menu

:help
cls
call :ui help
call :ui return-main
pause >nul
goto menu

rem ============================================
rem Safe exit and fall-through guard
rem ============================================
:safe_exit
call :ui goodbye
pause >nul
exit /b

rem Return to the menu if execution reaches this point.
goto menu

:ensure_global_codegraph
where codegraph 2>nul >nul
if not errorlevel 1 exit /b 0
call :ui global-install-start
call npm i -g @colbymchenry/codegraph
if errorlevel 1 (
    call :ui global-install-failed
    pause >nul
    exit /b 1
)
call :ui global-install-complete
exit /b 0

:ensure_node_fts5
if defined NODE_CMD (
    "%NODE_CMD%" "%SCRIPT_DIR%\scripts\check-node-fts5.js" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

call :ui node-runtime-download
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\scripts\ensure-node-runtime.ps1" -RuntimeRoot "%SCRIPT_DIR%\.codegraph-runtime"
if errorlevel 1 (
    call :ui node-runtime-failed
    pause >nul
    exit /b 1
)

if not exist "%SCRIPT_DIR%\.codegraph-runtime\node-path.txt" (
    call :ui node-runtime-failed
    pause >nul
    exit /b 1
)

set "NODE_CMD="
set /p NODE_CMD=<"%SCRIPT_DIR%\.codegraph-runtime\node-path.txt"
if not defined NODE_CMD (
    call :ui node-runtime-failed
    pause >nul
    exit /b 1
)

"%NODE_CMD%" "%SCRIPT_DIR%\scripts\check-node-fts5.js" >nul 2>&1
if errorlevel 1 (
    call :ui node-runtime-failed
    pause >nul
    exit /b 1
)

for %%i in ("%NODE_CMD%") do set "CG_NODE_DIR=%%~dpi"
set "PATH=!CG_NODE_DIR!;%PATH%"
exit /b 0
