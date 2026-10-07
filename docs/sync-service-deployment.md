# Windows 局域网同步服务部署示例

本说明适用于受信任的家庭或开发网络，让同一局域网内的手机端和桌面端连接 Windows 上的同步服务。公网部署请使用 [Linux 与 HTTPS 部署指南](server-sync-service-deployment.md)。本文中的命令供维护人员执行，不代表服务已经部署。

## 准备与地址

需要 Node.js 24 或更高版本。在仓库根目录打开 PowerShell；当前服务只使用 Node.js 内置模块，无需安装生产依赖。

```powershell
node --version
Set-Location server
```

本指南用 `192.168.1.100` 表示 Windows 主机的局域网 IPv4 地址，**它仅是示例，所有出现的位置都要替换为实际地址**。可通过以下命令查看以太网或 Wi-Fi 的地址，选择与客户端处于同一局域网的网卡：

```powershell
Get-NetIPAddress -AddressFamily IPv4
```

DHCP 分配的地址可能变化。地址变更后更新客户端同步设置；也可在路由器中配置地址保留。

环境参数、默认数据路径与接口限制见 [服务端 README](../server/README.md)。相对配置路径以 `server` 目录为基准。

## 启动服务

在上一步的 PowerShell 窗口执行，将占位令牌替换为长随机字符串。所有客户端必须使用同一令牌。

```powershell
$env:HOST = '0.0.0.0'
$env:PORT = '8787'
$env:SYNC_AUTH_TOKEN = '替换为自己的长随机令牌'
$env:SYNC_DATA_FILE = './data/sync-store.json'
$env:UPDATE_MANIFEST_FILE = './data/update-manifest.json'
$env:RELEASE_DIRECTORY = './data/releases'
npm start
```

看到 `Diary sync server listening on http://0.0.0.0:8787` 表示服务已开始监听。关闭窗口会停止服务，环境变量也只在此窗口生效。令牌不要写入 Git、截图或聊天记录。

服务不会自动加载 `.env`。如果使用环境文件，在 `server` 目录参考 `.env.example` 创建 `.env`，然后改用 `node --env-file=.env src/server.mjs` 启动，并保护该文件。不要同时保留与 `.env` 冲突的同名环境变量。

## 局域网访问与防火墙

先在 Windows 主机验证健康接口：

```powershell
Invoke-RestMethod 'http://127.0.0.1:8787/health'
```

响应中 `data.status` 应为 `ok`。客户端与主机连接同一局域网后，在客户端浏览器打开 `http://192.168.1.100:8787/health`，其中 IP 替换为主机实际地址。

若本机正常而客户端无法连接，检查 Windows 网络类型和现有防火墙规则。确实需要新增入站规则时，维护人员可在管理员 PowerShell 中执行以下示例；规则仅适用于专用网络和本地子网：

```powershell
New-NetFirewallRule `
  -DisplayName '此刻同步服务 (局域网 TCP 8787)' `
  -Direction Inbound `
  -Action Allow `
  -Protocol TCP `
  -LocalPort 8787 `
  -RemoteAddress LocalSubnet `
  -Profile Private
```

不要将路由器端口映射到此 HTTP 服务，也不要为此开启公用网络入站权限。需要外网访问时，使用 HTTPS 反向代理或可信 VPN。

## 连接客户端

在手机端进入 **我的** → **数据** → **同步**，或打开桌面端同步设置：

1. 服务器地址填入 `http://192.168.1.100:8787`，将 IP 替换为实际地址。
2. 访问令牌填入服务端配置的同一令牌并保存。
3. 使用一条用于验证的含附件日记检查另一设备能否收到文字和附件。

留空服务器地址会保持纯本地模式。

## 更新、备份与恢复

服务端持久化数据与 App 内的 **备份与恢复** 是两条独立路径。使用默认路径时，更新源码或迁移前按以下步骤处理；若修改过路径，备份实际配置指向的位置。

1. 按 `Ctrl+C` 停止服务，避免复制正在写入的同步数据。
2. 将 `server/data/sync-store.json` 和整个 `server/data/assets` 目录一起复制到安全位置；使用 `.env` 时一并保管配置文件。
3. 需要保留更新分发内容时，备份 `server/data/update-manifest.json` 和 `server/data/releases`。
4. 保留当前 `server/src`、`server/package.json` 和源码版本信息，再更新源码。不要以清空目录或镜像覆盖方式替换整个 `server`，保留 `.env` 和 `data`。
5. 在仓库根目录执行 `npm --prefix server test` 验证更新，再按上面的方式启动并检查健康接口与跨端同步。

更新失败时停止服务，恢复之前的源码版本后重新启动。源码回滚保留现有数据；只有需要恢复数据时，才在停机状态下成套恢复 `sync-store.json` 和 `assets`。恢复旧备份会影响备份之后的新记录，恢复前应保留当前数据副本并确认恢复范围。备份包含私人日记和访问配置，应限制访问并另存一份到主机以外。

手机端和桌面端仍应定期通过 App 的 **备份与恢复** 导出设备侧备份。

## 常见排查

| 现象 | 检查方式 |
| --- | --- |
| 本机无法访问 `/health` | 确认启动窗口尚未关闭、Node.js 启动无错误，且端口 `8787` 未被其他程序占用。 |
| 客户端无法访问 `/health` | 确认实际局域网 IP、同一网络与专用网络防火墙规则；不要使用回环或虚拟网卡地址。 |
| 客户端返回 `401` | 核对客户端访问令牌与 `SYNC_AUTH_TOKEN`，不要在输出中打印令牌。 |
| 主机重启后地址失效 | 重新查询局域网 IP，并更新客户端地址。 |
| 有文字但附件缺失 | 检查实际 `assets` 目录是否保留、运行用户是否可读写，以及客户端附件同步状态。 |

同步格式见 [跨端数据格式与同步协议](sync-contract.md)。
