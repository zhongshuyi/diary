# 将同步服务部署到服务器

本手册用于维护已部署在公网服务器上的“此刻”同步服务。它采用**直接上传源码**的方式更新服务器，不要求服务器目录是 Git 工作副本。

适用对象：拥有服务器 SSH `root` 免密登录权限、需要部署或升级同步服务的维护人员。

> 同步接口承载日记与附件。请只把同步令牌保存在服务器 `.env` 和自己的客户端中，绝不要写入 Git、文档、终端录屏或聊天记录。

## 1. 当前生产环境

| 项目 | 当前值 |
| --- | --- |
| 服务器公网 IP | `8.129.229.252` |
| 同步服务公网地址 | `http://8.129.229.252:59002` |
| SSH 用户 | `root` |
| 服务根目录 | `/opt/diary` |
| 服务端源码目录 | `/opt/diary/src` |
| 环境文件 | `/opt/diary/.env` |
| Node.js | `/www/server/nodejs/v24.20.0/bin/node`（`/usr/bin/node` 当前指向此版本） |
| PM2 | `/www/server/nodejs/v24.20.0/lib/node_modules/pm2/bin/pm2` |
| PM2 应用名 | `diary` |
| 监听地址与端口 | `0.0.0.0:59002` |
| 同步数据 | `/opt/diary/data/sync-store.json` |
| 附件文件 | `/opt/diary/data/assets` |
| 更新清单 | `/opt/diary/data/update-manifest.json` |
| 安装包目录 | `/opt/diary/data/releases` |

除非明确需要迁移数据，更新源码时不得覆盖 `.env`、`data/sync-store.json` 或 `data/assets`。

## 2. 接口与访问控制

| 用途 | 地址 | 是否需要同步令牌 |
| --- | --- | --- |
| 健康检查 | `GET /health` | 否 |
| 检查桌面端/手机端更新 | `GET /api/v1/update?platform=desktop` 或 `mobile` | 否 |
| 下载安装包 | `GET /downloads/<文件名>` | 否 |
| 同步数据 | `POST /api/v1/sync`、`POST /api/v2/sync` | 是 |
| 读取、上传附件 | `GET`、`HEAD`、`PUT /api/v2/assets/<sha256>` | 是 |

更新地址可以公开使用；同步地址也使用同一个服务根地址，但客户端只有带上 `.env` 中 `SYNC_AUTH_TOKEN` 对应的 Bearer 令牌才能读写日记和附件。

## 3. 首次部署

### 3.1 准备服务器目录和运行环境

服务器需要 Node.js 24 或更高版本，并确保云安全组和服务器防火墙都允许 TCP `59002` 入站。

将服务端目录上传到 `/opt/diary` 后，在服务器执行：

```bash
cd /opt/diary
/www/server/nodejs/v24.20.0/bin/node --version
```

当前服务只使用 Node.js 内置模块，没有生产依赖。若以后的 `package.json` 新增了依赖，再在此目录执行对应包管理器的安装命令。

### 3.2 创建环境文件

创建 `/opt/diary/.env`，文件内容如下。将占位令牌替换为仅自己持有的强随机字符串。

```dotenv
HOST=0.0.0.0
PORT=59002
SYNC_AUTH_TOKEN=替换为长随机令牌
SYNC_DATA_FILE=./data/sync-store.json
UPDATE_MANIFEST_FILE=./data/update-manifest.json
```

限制环境文件权限：

```bash
chmod 600 /opt/diary/.env
```

### 3.3 用 PM2 启动

首次创建 PM2 进程时执行：

```bash
PM2=/www/server/nodejs/v24.20.0/lib/node_modules/pm2/bin/pm2
"$PM2" start /www/server/nodejs/v24.20.0/bin/node \
  --name diary \
  --cwd /opt/diary \
  -- --env-file=.env src/server.mjs
"$PM2" save
```

服务的实际启动命令为：

```text
node --env-file=.env src/server.mjs
```

这使 Node.js 在每次进程启动时加载 `/opt/diary/.env`。不要依赖临时 Shell 环境变量来保存令牌。

## 4. 日常更新：直接上传源码

以下步骤在开发机仓库根目录 `D:\devcode\main\diary\diary` 中执行。先确认本地服务端测试通过：

```powershell
Set-Location 'D:\devcode\main\diary\diary'
npm --prefix server test
```

假设本次改动涉及 `protocol-v2.mjs` 和 `store.mjs`。其他改动也应按同样方式上传到服务器的临时目录，再替换目标文件；不要把整个目录直接覆盖到 `/opt/diary`。

### 4.1 在服务器创建可回滚的发布目录

在以下命令中，把时间戳替换为本次部署的实际值：

```bash
ssh root@8.129.229.252 '
  deploy_root=/opt/diary/.deploy-YYYYMMDD-HHMMSS
  install -d -m 700 "$deploy_root/backup" "$deploy_root/staging"
  cp --preserve=mode,timestamps /opt/diary/src/protocol-v2.mjs "$deploy_root/backup/protocol-v2.mjs"
  cp --preserve=mode,timestamps /opt/diary/src/store.mjs "$deploy_root/backup/store.mjs"
'
```

### 4.2 上传、校验并替换文件

```powershell
$deployRoot = '/opt/diary/.deploy-YYYYMMDD-HHMMSS'
scp -p server/src/protocol-v2.mjs server/src/store.mjs "root@8.129.229.252:$deployRoot/staging/"
```

在服务器检查语法并替换：

```bash
ssh root@8.129.229.252 '
  deploy_root=/opt/diary/.deploy-YYYYMMDD-HHMMSS
  /usr/bin/node --check "$deploy_root/staging/protocol-v2.mjs"
  /usr/bin/node --check "$deploy_root/staging/store.mjs"
  chmod 644 "$deploy_root/staging/protocol-v2.mjs" "$deploy_root/staging/store.mjs"
  mv "$deploy_root/staging/protocol-v2.mjs" /opt/diary/src/protocol-v2.mjs
  mv "$deploy_root/staging/store.mjs" /opt/diary/src/store.mjs
'
```

`mv` 在同一文件系统中完成替换；原文件已在 `backup` 目录中保留，可用于回滚。

若本次改动了 `package.json` 或新增了服务端文件，也要先上传相应文件，再在 `/opt/diary` 中执行依赖安装或配置调整。不要上传本地的 `.env` 与 `data` 目录。

### 4.3 重启服务

```bash
ssh root@8.129.229.252 '
  PM2=/www/server/nodejs/v24.20.0/lib/node_modules/pm2/bin/pm2
  "$PM2" restart diary
  "$PM2" ls
'
```

如果修改了 `.env`，使用以下命令确保 PM2 重启后采用新的环境：

```bash
"$PM2" restart diary --update-env
```

不要操作服务器中另一个名为 `customer` 的已停止 PM2 进程；同步服务对应的应用名是 `diary`。

## 5. 部署后验证

先在服务器上验证进程、端口和健康接口：

```bash
ssh root@8.129.229.252 '
  PM2=/www/server/nodejs/v24.20.0/lib/node_modules/pm2/bin/pm2
  "$PM2" ls
  curl --fail --silent --show-error http://127.0.0.1:59002/health
  ss -ltnp | grep ":59002"
'
```

预期健康检查响应包含：

```json
{"data":{"status":"ok","service":"diary-sync","protocolVersion":1}}
```

再从开发机验证公网连通性：

```powershell
curl.exe --fail --silent --show-error http://8.129.229.252:59002/health
```

最后用已配置同一同步地址和令牌的手机或桌面端新建一条含附件的日记，确认另一设备能收到文字与图片。

## 6. 查看日志与常见故障

```bash
PM2=/www/server/nodejs/v24.20.0/lib/node_modules/pm2/bin/pm2
"$PM2" logs diary --lines 100
"$PM2" describe diary
```

| 现象 | 排查方式 |
| --- | --- |
| PM2 显示 `stopped` 或反复重启 | 查看 `"$PM2" logs diary --lines 100`，并检查 `/opt/diary/.env` 格式、Node.js 版本与源码语法。 |
| 服务器本机健康检查正常，公网失败 | 检查云安全组和操作系统防火墙是否放行 TCP `59002`，并确认 `.env` 中为 `HOST=0.0.0.0`。 |
| 客户端返回 `401` | 同步地址正确但令牌不一致。核对客户端令牌与服务器 `SYNC_AUTH_TOKEN`，不要在任何输出中打印令牌。 |
| 有文字但没有图片 | 检查 `/opt/diary/data/assets` 是否存在、运行用户是否可读写，以及客户端是否已更新到支持附件上传/下载的版本。 |
| 更新检查正常但同步失败 | 这是预期的权限边界：更新接口公开，同步接口必须携带 Bearer 令牌。 |

## 7. 备份与回滚

### 7.1 备份持久化数据

在维护前复制以下内容到服务器外的安全位置：

```text
/opt/diary/data/sync-store.json
/opt/diary/data/assets/
/opt/diary/data/update-manifest.json
/opt/diary/data/releases/
```

不要只备份 `sync-store.json`；附件实际保存在 `assets` 目录。

### 7.2 回滚一次源码更新

若重启或验证失败，用本次部署目录中的备份覆盖目标文件，然后重启 `diary`：

```bash
ssh root@8.129.229.252 '
  deploy_root=/opt/diary/.deploy-YYYYMMDD-HHMMSS
  cp "$deploy_root/backup/protocol-v2.mjs" /opt/diary/src/protocol-v2.mjs
  cp "$deploy_root/backup/store.mjs" /opt/diary/src/store.mjs
  PM2=/www/server/nodejs/v24.20.0/lib/node_modules/pm2/bin/pm2
  "$PM2" restart diary
'
```

回滚后再次执行第 5 节的健康检查。发布临时目录可在确认稳定后再人工清理；保留最近数次部署的备份会更安全。

同步协议和接口细节参见 [跨端数据格式与同步协议](sync-contract.md)。开发机局域网调试参见 [开发机同步服务部署](sync-service-deployment.md)。
