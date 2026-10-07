# Linux 同步服务与 HTTPS 部署示例

本指南使用 `/opt/diary`、服务账号 `deploy`、域名 `sync.example.com` 和 PM2 应用名 `diary-sync` 作为示例，按实际环境替换。它适用于已经具备 Node.js 24 或更高版本、PM2、SSH 和 HTTPS 反向代理的 Linux 运行环境，采用上传源码的方式发布，不要求服务器目录是 Git 工作副本。本文中的命令供维护人员执行，不代表已修改任何服务器。

公网客户端连接 `https://sync.example.com`；Node.js 仅监听 `127.0.0.1:8787`，由同机反向代理转发。不要默认向公网开放 `8787` 或其他 HTTP 同步端口。

## 运行目录与配置

由管理员按既有权限管理方式准备 `/opt/diary`，确保服务账号能够读写该目录及数据目录。所有 PM2 命令由同一服务账号执行。

| 内容 | 示例位置 |
| --- | --- |
| 源码与包信息 | `/opt/diary/src`、`/opt/diary/package.json` |
| 环境文件 | `/opt/diary/.env` |
| 日记与变更日志 | `/opt/diary/data/sync-store.json` |
| 同步附件 | `/opt/diary/data/assets` |
| 更新清单与安装包 | `/opt/diary/data/update-manifest.json`、`/opt/diary/data/releases` |

在本地仓库根目录上传服务源码，不上传本地 `.env` 或 `data`：

```powershell
scp -r server/src server/package.json deploy@sync.example.com:/opt/diary/
```

以下命令在服务器的服务账号会话中执行：

```bash
cd /opt/diary
node --version
pm2 --version
install -d -m 700 data
```

当前服务只使用 Node.js 内置模块，无需安装生产依赖。环境参数的完整说明见 [服务端 README](../server/README.md)。

创建 `/opt/diary/.env`，将占位令牌替换为长随机字符串，客户端使用相同令牌：

```dotenv
HOST=127.0.0.1
PORT=8787
SYNC_AUTH_TOKEN=替换为自己的长随机令牌
SYNC_DATA_FILE=./data/sync-store.json
UPDATE_MANIFEST_FILE=./data/update-manifest.json
RELEASE_DIRECTORY=./data/releases
```

```bash
chmod 600 /opt/diary/.env
```

令牌只保存在受保护的配置文件和自己的客户端中，不写入 Git、公开文档、终端录屏或聊天记录。相对路径以 `/opt/diary` 为基准；如果改变 `SYNC_DATA_FILE`，附件目录也会随之位于该文件所在目录的 `assets` 子目录。

## PM2 启动与本地维护

在 `/opt/diary` 中首次创建进程：

```bash
pm2 start "$(command -v node)" \
  --name diary-sync \
  --cwd /opt/diary \
  --interpreter none \
  -- --env-file=.env src/server.mjs
pm2 save
curl --fail --silent --show-error http://127.0.0.1:8787/health
```

PM2 启动的实际命令是 `node --env-file=.env src/server.mjs`，每次重启都会重新读取 `.env`。同名进程环境变量优先于 `.env`，应避免保留冲突配置。系统开机启动按已有 PM2 运维方式配置；服务使用单个进程，不要让多个实例写入同一份 JSON 数据文件。

健康响应中 `data.status` 应为 `ok`。维护时可使用：

```bash
pm2 describe diary-sync
pm2 logs diary-sync --lines 100
```

只操作本服务的 PM2 应用。若实际名称不同，统一替换本指南中的 `diary-sync`。

## HTTPS 公开接入

先为实际域名配置 DNS、有效 TLS 证书和现有反向代理。公网入口使用 HTTPS 的 `443` 端口；云安全组和主机防火墙不需要公开 Node.js 的 `8787` 端口。SSH 仍遵循既有管理访问限制。

下面是 Nginx 转发示例，应合并到现有配置中，并替换域名和证书路径。使用其他反向代理时保留相同的 HTTPS 入口与本地上游设置。

```nginx
server {
    listen 443 ssl;
    server_name sync.example.com;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    client_max_body_size 128m;

    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

`128m` 用于允许服务支持的附件大小，JSON 同步请求仍由应用限制为 2 MiB。代理需要转发 `/health`、`/api/` 和 `/downloads/`，并保留客户端的 `Authorization` 请求头。由维护人员按既有流程检查代理配置并加载，本文不包含自动修改防火墙或重载其他服务的命令。

从客户端侧验证：

```powershell
curl.exe --fail --silent --show-error https://sync.example.com/health
```

客户端服务器地址填 `https://sync.example.com`，访问令牌与服务端一致。健康检查、更新检查与下载安装包接口公开；同步数据和附件接口在配置令牌后要求 Bearer 鉴权。不要把私人文件放入公开的 `data/releases` 目录。

## 保留数据的源码更新

更新前在本地仓库根目录验证服务测试，并记录待发布的源码版本：

```powershell
npm --prefix server test
```

每次更新建立独立发布目录。以下示例中的 `YYYYMMDD-HHMMSS` 在所有步骤中替换为同一个实际时间戳。

在本地上传完整的 `src` 和 `package.json` 到暂存目录：

```powershell
$syncHost = 'deploy@sync.example.com'
$deployRoot = '/opt/diary/.deploy-YYYYMMDD-HHMMSS'
ssh $syncHost "install -d -m 700 '$deployRoot' '$deployRoot/staging' '$deployRoot/backup'"
scp -r server/src server/package.json "$($syncHost):$deployRoot/staging/"
```

在服务器检查暂存源码，备份当前源码，再停止进程获得一致的数据备份。以下操作只替换 `src` 和 `package.json`，保留现有 `.env` 和 `data`：

```bash
set -eu
cd /opt/diary
deploy_root=/opt/diary/.deploy-YYYYMMDD-HHMMSS
test -f "$deploy_root/staging/package.json"
test -f "$deploy_root/staging/src/server.mjs"
for file in "$deploy_root"/staging/src/*.mjs; do
  node --check "$file"
done
cp -a src package.json "$deploy_root/backup/"
pm2 stop diary-sync
cp -a .env data "$deploy_root/backup/"
mv src "$deploy_root/previous-src"
mv "$deploy_root/staging/src" src
mv "$deploy_root/staging/package.json" package.json
pm2 restart diary-sync --update-env
curl --fail --silent --show-error http://127.0.0.1:8787/health
```

这些命令应作为一次发布执行，不能复用已使用过的发布目录。若备份或替换步骤失败，先确认目录状态，恢复完整源码后再启动；不要直接重复整段命令。若未来引入生产依赖或数据迁移，需要将对应安装、兼容检查和恢复步骤纳入该版本发布流程。

本地健康检查通过后再验证 HTTPS 健康接口，并用测试日记确认跨端文字与附件同步。更新清单在请求时读取，单独更新 `data/update-manifest.json` 无需重启服务；清单中的下载地址也应使用实际 HTTPS 地址。

## 备份与回滚

完整持久化备份至少包含 `sync-store.json` 和整个 `assets` 目录；需要保留更新分发时，加上 `update-manifest.json` 和 `releases`。配置文件也应独立保管。自定义数据路径时备份实际路径，不要只复制默认 `data`。

复制数据前停止 `diary-sync`，复制完成后再启动，以免 JSON 与附件来自不一致的写入状态。上面的发布备份已经在停机后复制默认数据目录；维护人员还应将备份传到服务器外的安全位置，并限制访问或加密保存。App 内导出的设备侧备份仍需单独保留。

如果新源码启动或验证失败，在服务器回滚本次源码：

```bash
set -eu
cd /opt/diary
deploy_root=/opt/diary/.deploy-YYYYMMDD-HHMMSS
test -f "$deploy_root/backup/src/server.mjs"
test -f "$deploy_root/backup/package.json"
pm2 stop diary-sync
mv src "$deploy_root/failed-src"
cp -a "$deploy_root/backup/src" src
cp -p "$deploy_root/backup/package.json" package.json
pm2 restart diary-sync --update-env
curl --fail --silent --show-error http://127.0.0.1:8787/health
```

源码回滚保留当前 `.env` 和 `data`，不会自动覆盖发布后收到的新日记。确实需要恢复数据时，先停机，再成套恢复 JSON 与附件目录，并确认会影响备份之后的新记录。发布目录在验证稳定后按保留策略人工清理，避免误删数据或唯一备份。

## 常见排查

| 现象 | 排查方式 |
| --- | --- |
| 进程反复重启或本地健康失败 | 检查 `pm2 logs diary-sync --lines 100`、Node.js 版本、源码语法、`.env` 格式和数据目录权限。 |
| 本地健康正常、HTTPS 失败 | 检查域名、TLS 证书、反向代理上游和 HTTPS 入口规则；不要通过公开 `8787` 绕过问题。 |
| 客户端返回 `401` | 核对令牌与代理是否转发 `Authorization`，不要在日志或命令输出中打印令牌。 |
| 附件返回 `413` | 检查代理请求体上限；服务支持的单附件上限为 128 MiB。 |
| 有文字但没有附件 | 检查实际 `assets` 目录、运行用户权限、代理配置和客户端附件同步状态。 |
| 更新检查成功、同步失败 | 更新接口公开，仍需单独检查同步令牌和同步接口返回。 |

接口和格式见 [跨端数据格式与同步协议](sync-contract.md)。受信任局域网中的 Windows 部署见 [Windows 局域网部署示例](sync-service-deployment.md)。
