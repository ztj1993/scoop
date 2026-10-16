# Scoop 使用指南

## 常用命令
```
# 更新应用(不更新 scoop)
scoop install chrome --no-update-scoop

# 更新指定应用
scoop update extras/chrome
```

## 配置命令
```
# 将自动更新的检测间隔设置得非常大，解决每次都更新 scoop 问题
scoop config last_update 2099-01-01 00:00:00

# 设置代理
# https://github.com/ScoopInstaller/Scoop/wiki/Using-Scoop-behind-a-proxy
scoop config proxy proxy.example.org:8080
```