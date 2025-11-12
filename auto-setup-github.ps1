# 自动连接 Git 远程仓库脚本
Param(
    [string]$RemoteProvider = "GitHub"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section($index, $title) {
    Write-Host ("[{0}] {1}" -f $index, $title) -ForegroundColor Yellow
}

function Ensure-GitInstalled {
    Write-Section 1 "检测 Git 安装状态"
    try {
        $version = git --version
        Write-Host "✓ Git 已安装: $version" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Git 未安装，请先安装后重试: https://git-scm.com/download/win" -ForegroundColor Red
        exit 1
    }
}

function Ensure-GitConfig {
    Write-Section 2 "检测 Git 全局配置"
    $name = git config --global user.name 2>$null
    $email = git config --global user.email 2>$null
    if (-not $name) {
        $name = Read-Host "请输入 Git 用户名 (user.name)"
        git config --global user.name $name
    }
    if (-not $email) {
        $email = Read-Host "请输入 Git 邮箱 (user.email)"
        git config --global user.email $email
    }
    Write-Host "✓ 当前配置: $name `<$email`>" -ForegroundColor Green
}

function Ensure-Repository {
    Write-Section 3 "初始化/检查本地仓库"
    if (-not (Test-Path .git)) {
        git init | Out-Null
        Write-Host "✓ 已初始化 Git 仓库" -ForegroundColor Green
    }
    else {
        Write-Host "✓ .git 目录已存在" -ForegroundColor Green
    }
}

function Ensure-Commit {
    Write-Section 4 "确认存在提交"
    git add .
    $status = git status --porcelain
    if ($status) {
        $message = Read-Host "输入提交信息(默认: Initial commit)"
        if (-not $message) { $message = "Initial commit" }
        git commit -m $message | Out-Null
        Write-Host "✓ 已创建提交" -ForegroundColor Green
    }
    else {
        $existing = git log --oneline 2>$null
        if ($existing) {
            Write-Host "✓ 仓库已有提交" -ForegroundColor Green
        }
        else {
            Write-Host "⚠ 没有待提交的文件，请确认项目文件" -ForegroundColor Yellow
        }
    }
}

function Ensure-MainBranch {
    Write-Section 5 "设置 main 分支"
    git branch -M main 2>$null
    Write-Host "✓ 当前分支: main" -ForegroundColor Green
}

function Configure-Remote {
    Write-Section 6 "配置远程仓库"
    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl) {
        Write-Host "检测到已有远程 origin: $remoteUrl" -ForegroundColor Cyan
        $replace = Read-Host "是否替换远程地址? (y/n)"
        if ($replace -notin @('y','Y')) {
            return $remoteUrl
        }
        git remote remove origin
    }

    Write-Host "请输入远程仓库信息:" -ForegroundColor White
    $host = if ($RemoteProvider -ieq 'GitLab') { 'gitlab.com' } else { 'github.com' }
    $username = Read-Host "用户名"
    $repo = Read-Host "仓库名称"
    $mode = Read-Host "选择连接方式: 1=HTTPS  2=SSH (默认 HTTPS)"
    if ($mode -eq '2') {
        $remoteUrl = "git@${host}:${username}/${repo}.git"
    }
    else {
        $remoteUrl = "https://$host/$username/$repo.git"
    }
    git remote add origin $remoteUrl
    Write-Host "✓ 已添加远程 origin: $remoteUrl" -ForegroundColor Green
    return $remoteUrl
}

function Push-Remote($remoteUrl) {
    if (-not $remoteUrl) { return }
    $push = Read-Host "是否现在推送到远程? (y/n)"
    if ($push -notin @('y','Y')) { return }
    try {
        git push -u origin main
        Write-Host "✓ 推送成功" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ 推送失败，错误信息如下:" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Ensure-GitInstalled
Ensure-GitConfig
Ensure-Repository
Ensure-Commit
Ensure-MainBranch
$remoteUrl = Configure-Remote
Push-Remote -remoteUrl $remoteUrl

Write-Host "=== 完成 ===" -ForegroundColor Green
Write-Host "若使用 HTTPS 请准备 Personal Access Token；若使用 SSH 请确保已配置密钥。" -ForegroundColor Cyan
