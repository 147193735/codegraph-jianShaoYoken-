param(
    [string]$CurrentDir,
    [string]$McpVscode,
    [string]$McpCursor,
    [string]$McpCodex
)

$top = "----------------------------------------------"

function Convert-McpStatus([string]$Status) {
    switch ($Status) {
        "ON" { return "已配置" }
        "LOCAL" { return "当前项目" }
        "GLOBAL" { return "全局" }
        default { return "未配置" }
    }
}

$vscodeStatus = Convert-McpStatus $McpVscode
$cursorStatus = Convert-McpStatus $McpCursor
$codexStatus = Convert-McpStatus $McpCodex
Write-Host $top
Write-Host "     CodeGraph 快速工具 v2.3"
Write-Host "     语义代码知识图谱 --- 命令行助手"
Write-Host $top
Write-Host ""
Write-Host " 当前目录: $CurrentDir"
Write-Host " MCP 状态: VS Code=$vscodeStatus  Cursor=$cursorStatus  Codex=$codexStatus"
Write-Host $top
Write-Host ""
Write-Host " [查看分析]"
Write-Host " [1] 项目状态"
Write-Host " [2] 文件结构"
Write-Host ""
Write-Host " [搜索追踪]"
Write-Host " [3] 搜索符号       [5] 查被调者"
Write-Host " [4] 查找调用者     [6] 影响分析"
Write-Host " [7] 查找受影响测试"
Write-Host ""
Write-Host " [索引维护]          [服务与配置]"
Write-Host " [8] 初始化项目     [11] MCP 服务"
Write-Host " [9] 重新索引       [12] 配置 MCP (IDE / Codex)"
Write-Host " [10] 增量同步      [13] 卸载配置"
Write-Host "                    [14] 帮助"
Write-Host ""
Write-Host $top
Write-Host "  [0] 退出"
Write-Host $top
