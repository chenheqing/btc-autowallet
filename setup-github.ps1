# GitHub 仓库连接脚本
# 使用方法: .\setup-github.ps1 -GitHubUsername "您的用户名" -RepoName "仓库名"

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    
    [Parameter(Mandatory=$false)]
    [string]$UseSSH = "false"
)

Write-Host "=== GitHub 仓库连接脚本 ===" -ForegroundColor Green

# 检查 Git 是否安装
try {
    $gitVersion = git --version
    Write-Host "✓ Git 已安装: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ 错误: Git 未安装！" -ForegroundColor Red
    Write-Host "请先安装 Git: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# 检查是否已初始化 Git 仓库
if (Test-Path .git) {
    Write-Host "✓ Git 仓库已初始化" -ForegroundColor Green
} else {
    Write-Host "正在初始化 Git 仓库..." -ForegroundColor Yellow
    git init
    Write-Host "✓ Git 仓库初始化完成" -ForegroundColor Green
}

# 检查是否已配置用户信息
$userName = git config --global user.name
$userEmail = git config --global user.email

if (-not $userName -or -not $userEmail) {
    Write-Host "警告: 未配置 Git 用户信息" -ForegroundColor Yellow
    Write-Host "请运行以下命令配置:" -ForegroundColor Yellow
    Write-Host "  git config --global user.name `"您的用户名`"" -ForegroundColor Cyan
    Write-Host "  git config --global user.email `"您的邮箱@example.com`"" -ForegroundColor Cyan
    $continue = Read-Host "是否继续? (y/n)"
    if ($continue -ne "y") {
        exit 0
    }
}

# 添加文件
Write-Host "正在添加文件到暂存区..." -ForegroundColor Yellow
git add .

# 检查是否有更改需要提交
$status = git status --porcelain
if ($status) {
    Write-Host "正在创建首次提交..." -ForegroundColor Yellow
    git commit -m "Initial commit"
    Write-Host "✓ 提交完成" -ForegroundColor Green
} else {
    Write-Host "没有需要提交的更改" -ForegroundColor Yellow
}

# 设置远程仓库
$remoteUrl = if ($UseSSH -eq "true") {
    "git@github.com:${GitHubUsername}/${RepoName}.git"
} else {
    "https://github.com/${GitHubUsername}/${RepoName}.git"
}

# 检查是否已存在远程仓库
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
    Write-Host "远程仓库已存在: $existingRemote" -ForegroundColor Yellow
    $update = Read-Host "是否更新为新的仓库地址? (y/n)"
    if ($update -eq "y") {
        git remote set-url origin $remoteUrl
        Write-Host "✓ 远程仓库地址已更新" -ForegroundColor Green
    }
} else {
    git remote add origin $remoteUrl
    Write-Host "✓ 远程仓库已添加: $remoteUrl" -ForegroundColor Green
}

# 设置主分支
Write-Host "正在设置主分支..." -ForegroundColor Yellow
git branch -M main 2>$null

# 提示推送
Write-Host ""
Write-Host "=== 下一步 ===" -ForegroundColor Green
Write-Host "1. 确保 GitHub 仓库 '$RepoName' 已创建" -ForegroundColor Yellow
Write-Host "2. 运行以下命令推送代码:" -ForegroundColor Yellow
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "如果遇到认证问题，请使用 Personal Access Token 或配置 SSH 密钥" -ForegroundColor Yellow


