# 在开发机部署局域网同步服务

本说明用于把同步服务运行在当前 Windows 开发机上，让同一局域网内的手机端连接。它适合受信任的家庭或开发网络；不要把这个 HTTP 服务直接暴露到公网。

## 当前环境与路径

| 项目 | 当前值 |
| --- | --- |
| 开发机局域网 IP | `192.168.1.6`（以太网，`/24`） |
| 服务根目录 | `D:\devcode\main\diary\diary\server` |
| 服务端口 | `8787` |
| 手机端服务器地址 | `http://192.168.1.6:8787` |
| 同步数据 | `D:\devcode\main\diary\diary\server\data\sync-store.json` |
| 已同步附件 | `D:\devcode\main\diary\diary\server\data\assets` |
| 更新清单 | `D:\devcode\main\diary\diary\server\data\update-manifest.json` |
| 可下载安装包 | `D:\devcode\main\diary\diary\server\data\releases` |

`192.168.1.6` 是当前 DHCP 分配的地址，网络切换或路由器重新分配地址后可能会变化。不要把它写死进代码；变更后只需在手机的同步设置中更新地址。

## 首次准备

需要 Node.js 24 或更高版本。当前开发机的 Node.js 版本是 24.18.0。

```powershell
Set-Location 'D:\devcode\main\diary\diary\server'
npm install
```

不要将真实令牌写入 Git。`server/.env.example` 只用于提示变量名称，当前服务不会自动读取 `.env` 文件，因此启动时要由 PowerShell 环境变量提供配置。

## 启动服务

在一个专用 PowerShell 窗口中执行。请为 `SYNC_AUTH_TOKEN` 生成并填入一段只在自己的设备间使用的长随机字符串。

```powershell
Set-Location 'D:\devcode\main\diary\diary\server'
$env:HOST = '0.0.0.0'
$env:PORT = '8787'
$env:SYNC_AUTH_TOKEN = '请替换为自己的长随机令牌'
$env:SYNC_DATA_FILE = './data/sync-store.json'
$env:UPDATE_MANIFEST_FILE = './data/update-manifest.json'
npm start
```

看到下面的输出即表示服务已启动：

```text
Diary sync server listening on http://0.0.0.0:8787
```

这些变量只在当前 PowerShell 窗口生效。关闭窗口会停止服务；下一次启动时需要重新设置。不要将令牌写入截图、聊天记录或受版本控制的文件。

## Windows 防火墙

若本机健康检查正常、手机却无法连接，通常是防火墙未允许入站连接。管理员 PowerShell 可执行以下命令一次：

```powershell
New-NetFirewallRule `
  -DisplayName '此刻同步服务 (TCP 8787)' `
  -Direction Inbound `
  -Action Allow `
  -Protocol TCP `
  -LocalPort 8787 `
  -Profile Private
```

这条规则只应在“专用”网络配置文件下使用。无需对公用网络或公网开放端口。

## 验证服务

服务启动后，先在开发机运行：

```powershell
Invoke-RestMethod 'http://127.0.0.1:8787/health'
```

预期会返回 `status` 为 `ok`。然后让手机和开发机连接同一个 Wi-Fi 或局域网，在手机浏览器打开：

```text
http://192.168.1.6:8787/health
```

能看到健康检查结果后，打开手机 App：

1. 进入 **我的** → **数据** → **同步**。
2. 在“服务器地址”填入 `http://192.168.1.6:8787`。
3. 在“访问令牌”填入启动服务时使用的同一令牌，保存连接。
4. 返回首页后触发同步，或在“我的”页观察同步状态。

留空服务器地址会保持纯本地模式，不会上传任何日记。

## 备份与恢复

同步服务的数据与 App 内的 **备份与恢复** 是两条独立路径。迁移或维护服务器前：

1. 停止同步服务，避免复制到正在写入的文件。
2. 复制 `server\data\sync-store.json` 和整个 `server\data\assets` 目录到安全位置。
3. 需要保存可下载安装包或更新元数据时，一并复制 `server\data\releases` 与 `server\data\update-manifest.json`。

手机端日记仍应定期使用 **我的** → **数据** → **备份与恢复** 导出 JSON；它是设备侧的独立可恢复备份。

## 常见排查

| 现象 | 检查方式 |
| --- | --- |
| 本机无法访问 `/health` | 确认启动 PowerShell 尚未关闭，且端口 `8787` 未被其他程序占用。 |
| 手机无法访问 `/health` | 确认两台设备在同一局域网，使用的是 `192.168.1.6` 而不是 WSL、VMware 或 Clash 的虚拟网卡地址，并检查专用网络防火墙规则。 |
| App 显示同步失败 | 检查服务器地址是否带有 `http://`、端口是否为 `8787`，以及手机端令牌是否与 `SYNC_AUTH_TOKEN` 完全一致。 |
| 重启后地址失效 | 在开发机执行 `Get-NetIPAddress -AddressFamily IPv4` 找到以太网或 Wi-Fi 的局域网地址，然后在 App 中更新服务器地址。 |
| 需要外网同步 | 不要直接端口映射当前 HTTP 服务。应先增加 HTTPS、身份验证与网络隔离，或通过可信 VPN 访问私有网络。 |

服务接口与跨端同步格式见 [同步协议](sync-contract.md)。
