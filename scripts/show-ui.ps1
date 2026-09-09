param(
    [Parameter(Mandatory = $true)]
    [string]$Screen,
    [string]$McpVscode,
    [string]$McpCursor,
    [string]$McpCodex
)

$line = "----------------------------------------------"

function Write-Panel {
    param(
        [string]$Title,
        [string[]]$Lines = @()
    )

    Write-Host $line
    Write-Host "  $Title"
    Write-Host $line
    foreach ($item in $Lines) {
        Write-Host $item
    }
}

function Write-ReturnToMain {
    Write-Host ""
    Write-Host $line
    Write-Host "按任意键返回主菜单..."
}

function Write-ReturnToMcpMenu {
    Write-Host ""
    Write-Host $line
    Write-Host "按任意键返回 MCP 配置菜单..."
}

function Convert-McpStatus([string]$Status) {
    switch ($Status) {
        "ON" { return "已配置" }
        "LOCAL" { return "当前项目" }
        "GLOBAL" { return "全局" }
        default { return "未配置" }
    }
}

switch ($Screen) {
    "set-title" {
        try {
            $Host.UI.RawUI.WindowTitle = "CodeGraph 快速工具 v2.3"
        } catch {
            # Some hosts do not expose a writable console title.
        }
    }
    "node-missing" {
        Write-Panel "[错误] 未检测到 Node.js" @(
            "",
            "CodeGraph 需要支持 SQLite FTS5 的 Node.js 运行时。",
            "请先从 https://nodejs.org 安装 Node.js 24 LTS。",
            "",
            "安装完成后请重新运行本工具。",
            "",
            "按任意键退出..."
        )
    }
    "local-check" {
        Write-Host ""
        Write-Host "[*] 检测到本地开发版本，正在检查构建文件..."
    }
    "node-fts5-missing" {
        Write-Panel "[错误] 当前 Node.js 不支持 SQLite FTS5" @(
            "",
            "CodeGraph 依赖 FTS5 建立符号搜索索引。",
            "请安装 Node.js 24 LTS 后重新运行本工具。",
            "下载地址：https://nodejs.org",
            "",
            "按任意键退出..."
        )
    }
    "node-runtime-download" {
        Write-Panel "正在准备隔离 Node.js 运行时" @(
            "",
            "当前 Node.js 不支持 SQLite FTS5。",
            "将下载 Node.js 24 LTS 到本工具的 .codegraph-runtime 目录。",
            "不会替换系统 Node.js，也不会修改项目依赖。",
            ""
        )
    }
    "node-runtime-failed" {
        Write-Panel "[错误] 隔离 Node.js 运行时准备失败" @(
            "",
            "请检查网络后重新运行本工具。",
            "详细原因请查看上方输出。",
            "",
            "按任意键退出..."
        )
    }
    "dependencies-install" {
        Write-Host "[*] 正在安装项目依赖..."
        Write-Host ""
    }
    "dependencies-failed" {
        Write-Host ""
        Write-Host "[警告] 项目依赖安装失败，部分功能可能不可用。"
    }
    "build-start" {
        Write-Host "[*] 正在编译 TypeScript 构建文件..."
        Write-Host ""
    }
    "build-failed" {
        Write-Host ""
        Write-Host "[警告] 本地构建失败，将尝试使用全局 CodeGraph 命令。"
    }
    "build-complete" {
        Write-Host "[完成] 本地构建完成。"
    }
    "shortcut-failed" {
        Write-Panel "[错误] 无法解析快捷方式的目标目录" @(
            "",
            "按任意键退出..."
        )
    }
    "enter-directory-failed" {
        Write-Panel "[错误] 无法进入指定目录" @(
            "",
            "请确认拖入的是有效项目文件夹。",
            "",
            "按任意键退出..."
        )
    }
    "main-prompt" {
        Write-Host ""
        Write-Host "请输入功能编号 (0-14)："
    }
    "status" {
        Write-Panel "项目状态"
        Write-Host ""
    }
    "files" {
        Write-Panel "项目文件"
        Write-Host ""
        Write-Host "显示格式：tree（树形）、flat（平铺）、grouped（分组）。"
        Write-Host "请输入显示格式，直接回车默认使用 tree："
    }
    "files-filter" {
        Write-Host ""
        Write-Host "可按目录筛选文件，直接回车则不筛选。"
        Write-Host "请输入目录路径："
    }
    "search-symbol" {
        Write-Panel "搜索符号"
        Write-Host ""
        Write-Host "请输入符号名称："
    }
    "search-running" {
        Write-Host ""
        Write-Host "正在搜索符号..."
        Write-Host ""
    }
    "find-callers" {
        Write-Panel "查找调用者"
        Write-Host ""
        Write-Host "请输入符号名称："
    }
    "find-callers-running" {
        Write-Host ""
        Write-Host "正在查找调用者..."
        Write-Host ""
    }
    "find-callees" {
        Write-Panel "查找被调者"
        Write-Host ""
        Write-Host "请输入符号名称："
    }
    "find-callees-running" {
        Write-Host ""
        Write-Host "正在查找被调者..."
        Write-Host ""
    }
    "impact" {
        Write-Panel "影响分析"
        Write-Host ""
        Write-Host "请输入符号名称："
    }
    "impact-depth" {
        Write-Host ""
        Write-Host "请输入分析深度，直接回车默认使用 2："
    }
    "impact-running" {
        Write-Host ""
        Write-Host "正在分析影响范围..."
        Write-Host ""
    }
    "affected" {
        Write-Panel "查找受影响测试"
        Write-Host ""
        Write-Host "请输入源文件路径，多个路径以空格分隔。"
        Write-Host "直接回车将对比最近一次 Git 提交。"
        Write-Host "示例：src/utils.ts src/api.ts"
        Write-Host ""
        Write-Host "请输入文件路径："
    }
    "affected-git" {
        Write-Host "正在通过 Git 差异检测变更文件..."
        Write-Host ""
    }
    "affected-files" {
        Write-Host "正在查找受影响的测试文件..."
        Write-Host ""
    }
    "initialize" {
        Write-Panel "初始化 CodeGraph"
        Write-Host ""
        Write-Host "正在初始化项目并构建索引..."
        Write-Host ""
    }
    "reindex" {
        Write-Panel "重新建立项目索引"
        Write-Host ""
        Write-Host "[警告] 此操作会删除现有索引并重新构建。"
        Write-Host "输入 y 确认重新建立索引，其他输入将取消："
    }
    "reindex-running" {
        Write-Host ""
        Write-Host "正在完整重建索引..."
        Write-Host ""
    }
    "cancelled" {
        Write-Host "已取消。"
    }
    "sync" {
        Write-Panel "增量同步"
        Write-Host ""
        Write-Host "正在同步最近的文件变更..."
        Write-Host ""
    }
    "serve" {
        Write-Panel "启动 MCP 服务"
        Write-Host ""
        Write-Host "正在启动 MCP 服务。"
        Write-Host "按 Ctrl+C 可停止服务。"
        Write-Host ""
    }
    "mcp-menu" {
        $vscodePath = Join-Path $env:APPDATA "Code\User\mcp.json"
        $cursorProjectPath = Join-Path (Get-Location) ".cursor\mcp.json"
        $cursorGlobalPath = Join-Path $env:USERPROFILE ".cursor\mcp.json"
        $codexPath = Join-Path $env:USERPROFILE ".codex\config.toml"
        Write-Panel "配置 MCP（VS Code / Cursor / Codex）" @(
            "",
            "VS Code、Cursor 与 Codex 使用不同的配置文件：",
            "  VS Code  $vscodePath",
            "  Cursor   项目配置 $cursorProjectPath",
            "           全局配置 $cursorGlobalPath",
            "  Codex    全局配置 $codexPath",
            "",
            "当前状态：VS Code=$(Convert-McpStatus $McpVscode)  Cursor=$(Convert-McpStatus $McpCursor)  Codex=$(Convert-McpStatus $McpCodex)",
            "",
            "[1] 配置 VS Code Copilot MCP（全局）",
            "[2] 配置 Cursor MCP（当前项目）",
            "[3] 配置 Cursor MCP（全局）",
            "[4] 同时配置 VS Code 与 Cursor（当前项目）",
            "[5] 注册 Codex MCP（全局）",
            "[6] 配置全局 MCP（Claude / Cursor / Codex / VS Code Copilot）",
            "[0] 返回主菜单",
            "",
            "请输入功能编号 (0-6)："
        )
    }
    "mcp-vscode-success" {
        Write-Host ""
        Write-Host "[完成] 已写入 VS Code MCP 配置。"
        Write-Host "请重启 VS Code 以加载配置。"
        Write-ReturnToMcpMenu
    }
    "mcp-cursor-project-success" {
        Write-Host ""
        Write-Host "[完成] 已写入当前项目的 Cursor MCP 配置。"
        Write-Host "请重启 Cursor 以加载配置。"
        Write-ReturnToMcpMenu
    }
    "mcp-cursor-global-success" {
        Write-Host ""
        Write-Host "[完成] 已写入全局 Cursor MCP 配置。"
        Write-Host "请重启 Cursor 以加载配置。"
        Write-ReturnToMcpMenu
    }
    "mcp-both-success" {
        Write-Host ""
        Write-Host "[完成] 已为当前项目配置 VS Code 与 Cursor MCP。"
        Write-Host "请重启 VS Code 和 Cursor 以加载配置。"
        Write-ReturnToMcpMenu
    }
    "mcp-codex" {
        Write-Panel "注册 Codex MCP（全局）" @(
            "",
            "这会为所有 Codex 项目注册 CodeGraph：",
            "  $(Join-Path $env:USERPROFILE '.codex\config.toml')",
            "",
            "正在注册...",
            ""
        )
    }
    "mcp-codex-failed" {
        Write-Host ""
        Write-Host "[错误] Codex MCP 注册失败，请检查上方输出。"
        Write-ReturnToMcpMenu
    }
    "mcp-codex-success" {
        Write-Host ""
        Write-Host "[完成] Codex MCP 已注册。"
        Write-Host "请重启 Codex 或新建会话以加载 codegraph_explore 工具。"
        Write-ReturnToMcpMenu
    }
    "mcp-global" {
        Write-Panel "配置全局 MCP" @(
            "",
            "目标：Claude Code、Cursor、Codex CLI、VS Code Copilot",
            "范围：全局，对所有项目生效。",
            "Claude 还会获得 CodeGraph 权限与使用说明。",
            ""
        )
    }
    "mcp-global-failed" {
        Write-Host ""
        Write-Host "[错误] 全局 MCP 配置失败，请检查上方输出。"
        Write-ReturnToMcpMenu
    }
    "mcp-global-success" {
        Write-Host ""
        Write-Host "[完成] 全局 MCP 配置完成。"
        Write-Host "请重启相关工具以加载配置。"
        Write-ReturnToMcpMenu
    }
    "uninstall" {
        Write-Panel "卸载 CodeGraph" @(
            "",
            "[警告] 此操作会从所有已配置的智能工具中移除 CodeGraph。",
            "输入 y 确认卸载，其他输入将取消："
        )
    }
    "uninstall-complete" {
        Write-Host ""
        Write-Host "卸载完成。"
    }
    "help" {
        Write-Panel "帮助" @(
            "",
            "CodeGraph 是本地优先的语义代码图谱工具。",
            "它为 AI 编程助手提供基于代码结构的查询能力，",
            "相较传统 grep 文本搜索，能更快定位符号和调用关系。",
            "",
            "主要能力：",
            "  * 为函数、类、方法和变量建立符号索引",
            "  * 追踪调用者和被调者",
            "  * 分析代码变更影响范围",
            "  * FTS5 全文搜索",
            "  * 自动同步文件变更",
            "  * 支持二十多种语言",
            "  * 识别常见框架路由",
            "",
            "可将项目文件夹直接拖到此 .bat 文件上，以该项目为工作目录。",
            "",
            "更多信息：https://colbymchenry.github.io/codegraph/"
        )
    }
    "return-main" {
        Write-ReturnToMain
    }
    "goodbye" {
        Write-Host ""
        Write-Host "感谢使用 CodeGraph。"
        Write-Host "按任意键退出..."
    }
    "global-install-start" {
        Write-Host ""
        Write-Host "[*] 未检测到 CodeGraph 命令，正在进行全局安装..."
        Write-Host "[*] npm i -g @colbymchenry/codegraph"
        Write-Host ""
    }
    "global-install-failed" {
        Write-Panel "[错误] 全局安装失败" @(
            "",
            "请检查网络后重试，或手动执行：",
            "  npm i -g @colbymchenry/codegraph",
            "",
            "按任意键退出..."
        )
    }
    "global-install-complete" {
        Write-Host ""
        Write-Host "[完成] CodeGraph 全局安装完成。"
        Write-Host ""
    }
    default {
        Write-Host "[错误] 未知界面：$Screen"
    }
}
