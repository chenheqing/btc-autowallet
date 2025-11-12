# GitHub 仓库连接指南

## 步骤 1: 安装 Git

如果您的系统上还没有安装 Git，请先安装：

### Windows 安装方法：
1. 访问 https://git-scm.com/download/win
2. 下载并安装 Git for Windows
3. 安装完成后，重启终端/PowerShell

### 验证安装：
```bash
git --version
```

## 步骤 2: 配置 Git（首次使用）

```bash
git config --global user.name "您的用户名"
git config --global user.email "您的邮箱@example.com"
```

## 步骤 3: 初始化本地仓库

在项目目录中执行：

```bash
# 初始化 Git 仓库
git init

# 添加文件到暂存区
git add .

# 创建首次提交
git commit -m "Initial commit"
```

## 步骤 4: 连接到 GitHub 仓库

### 方法 A: 连接到已存在的 GitHub 仓库

```bash
# 添加远程仓库（将 YOUR_USERNAME 和 YOUR_REPO 替换为实际值）
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# 或者使用 SSH（需要先配置 SSH 密钥）
git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO.git

# 推送代码
git branch -M main
git push -u origin main
```

### 方法 B: 创建新的 GitHub 仓库

1. 访问 https://github.com/new
2. 创建新仓库（不要初始化 README、.gitignore 或 license）
3. 按照方法 A 的步骤连接

## 步骤 5: 推送代码

```bash
git push -u origin main
```

## 常见问题

### 如果遇到认证问题：
- 使用 Personal Access Token 代替密码
- 生成 Token: GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
- 使用 Token 作为密码进行推送

### 使用 SSH 密钥（推荐）：
```bash
# 生成 SSH 密钥
ssh-keygen -t ed25519 -C "您的邮箱@example.com"

# 复制公钥内容
cat ~/.ssh/id_ed25519.pub

# 将公钥添加到 GitHub: Settings → SSH and GPG keys → New SSH key
```


