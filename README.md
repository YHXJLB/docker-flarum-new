<p align="center">
  <img height="128" src="https://flarum.org/img/logo.svg" alt="Flarum 2.0">
</p>

<p align="center">
  <a href="https://github.com/YHXJLB/docker-flarum-new/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/YHXJLB/docker-flarum-new/build.yml?branch=master&label=build&logo=github&style=flat-square" alt="Build Status"></a>
  <a href="https://github.com/YHXJLB/docker-flarum-new/pkgs/container/docker-flarum-new"><img src="https://img.shields.io/badge/registry-ghcr.io-blue?style=flat-square&logo=github" alt="GHCR"></a>
  <a href="https://flarum.org/"><img src="https://img.shields.io/badge/flarum-2.0.0--rc.8-green?style=flat-square" alt="Flarum"></a>
</p>

## 关于

基于 [crazy-max/docker-flarum](https://github.com/crazy-max/docker-flarum)（MIT）适配的
**Flarum 2.0** Docker 镜像。沿用其镜像格式（Alpine + s6-overlay + nginx + php-fpm），
但安装方式改为直接使用 Flarum 官方发布的 **完整包归档**（
[flarum/installation-packages](https://github.com/flarum/installation-packages) 的
`v2.0.0-rc.8` 完整包），以确定性地复现固定版本，而非构建时跑 composer。

> Flarum 2.0 目前处于 RC 阶段，API 已稳定，但正式稳定版发布前请先备份数据再上线。

## 特性

* 非 root 用户运行
* 多平台镜像（amd64 / arm64，由 GitHub Actions 构建）
* [s6-overlay](https://github.com/just-containers/s6-overlay/) 作为进程管理器
* nginx + php84-fpm
* 通过「sidecar」容器运行 Flarum 定时任务
* 扩展通过 `/data/extensions/list` 持久化，容器重启自动重装
* 通过 GitHub Actions 构建并推送至 GHCR

## 镜像

| registry | 镜像 |
| --- | --- |
| GitHub Container Registry | `ghcr.io/yhxjlb/docker-flarum-new` |

可用标签：`2.0`、`latest`、`master`、以及语义化版本标签。

## 环境变量

### 通用

* `TZ`：容器时区（默认 `UTC`）
* `PUID` / `PGID`：Flarum 运行用户/组 id（默认 `1000`）
* `MEMORY_LIMIT`：PHP 内存限制（默认 `256M`）
* `UPLOAD_MAX_SIZE`：上传大小上限（默认 `16M`）
* `NGINX_WORKER_PROCESSES`：nginx worker 进程数（默认 `auto`）
* `CLEAR_ENV`：FPM worker 是否清理环境（默认 `yes`）
* `OPCACHE_MEM_SIZE`：OpCache 内存（默认 `128`）
* `LISTEN_IPV6`：nginx 是否监听 IPv6（默认 `true`）
* `REAL_IP_FROM` / `REAL_IP_HEADER` / `LOG_IP_VAR`：反代真实 IP 相关

### Flarum

* `FLARUM_DEBUG`：调试模式（默认 `false`）
* `FLARUM_BASE_URL`：站点地址 **必填**
* `FLARUM_FORUM_TITLE`：论坛标题（仅首次安装使用）
* `FLARUM_API_PATH`：api 路径（默认 `api`）
* `FLARUM_ADMIN_PATH`：admin 路径（默认 `admin`）
* `FLARUM_POWEREDBY_HEADER`：X-Powered-By 头（默认 `true`）
* `FLARUM_REFERRER_POLICY`：Referrer 策略（默认 `same-origin`）
* `FLARUM_COOKIE_SAMESITE`：Cookie SameSite（默认 `lax`）
* `FLARUM_ANNOUNCEMENTS_DISABLED`：关闭后台公告（默认 `false`）

### Sidecar 定时任务

* `SIDECAR_CRON`：设为 `1` 启用 sidecar 模式（默认 `0`）
* `CRON_SCHEDULE`：定时任务周期（默认 `* * * * *`）

### 数据库

* `DB_HOST`：数据库主机 **必填**
* `DB_PORT`：端口（默认 `3306`）
* `DB_NAME`：库名（默认 `flarum`）
* `DB_USER`：用户（默认 `flarum`）
* `DB_PASSWORD`：密码
* `DB_PREFIX`：表前缀（默认 `flarum_`）
* `DB_NOPREFIX`：强制无前缀（默认 `false`）
* `DB_TIMEOUT`：等待数据库就绪的秒数（默认 `60`）

> `DB_USER_FILE` / `DB_PASSWORD_FILE` 可用文件内容填充（Docker secrets）。

> 注意：镜像内置的数据库连通性检测使用 `mariadb` 客户端，默认面向
> MySQL/MariaDB。若改用 PostgreSQL/SQLite，需自行调整 `rootfs/etc/cont-init.d/03-config.sh`
> 中的检测逻辑，并相应安装 `php84-pdo_pgsql` / `php84-pdo_sqlite`。

## 卷

* `/data`：包含 assets、extensions、storage

> 卷需归属 `PUID:PGID` 指定的用户/组，否则容器可能启动失败。

## 端口

* `8000`：HTTP

## 使用

### Docker Compose（推荐）

参考仓库内的 [docker-compose.yml](docker-compose.yml) 与 [.env.example](.env.example)：

```bash
cp .env.example .env
# 编辑 .env，设置 FLARUM_BASE_URL 与数据库凭据
docker compose up -d
docker compose logs -f
```

数据库默认随 compose 一起起一个 MariaDB 11.8。首次启动会创建管理员账号
`flarum` / `flarum`，请尽快在后台修改。

### 命令行

```bash
docker run -d -p 8000:8000 --name flarum \
  -v $(pwd)/data:/data \
  -e "DB_HOST=db" \
  -e "FLARUM_BASE_URL=http://127.0.0.1:8000" \
  ghcr.io/yhxjlb/docker-flarum-new:2.0
```

## 构建（GitHub Actions）

本仓库通过 GitHub Actions（`.github/workflows/build.yml`）在 push / tag 时自动
`docker buildx build` 多平台镜像并推送至 GHCR。本地也可用
[docker-bake.hcl](docker-bake.hcl) 构建：

```bash
docker buildx bake
```

## 管理扩展

镜像不持久化 `/opt/flarum/composer.json`、`composer.lock`、`vendor` 之外的扩展；
额外的直接 Composer 依赖记录在 `/data/extensions/list`，容器启动时自动重装。

```bash
docker compose exec flarum extension require fof/upload
docker compose exec flarum extension list
docker compose exec flarum extension remove fof/upload
```

## 升级

Flarum 升级建议通过后台或 `php flarum` 命令完成；镜像更新则重新拉取：

```bash
docker compose pull
docker compose up -d
```

## 许可

MIT。基于 crazy-max/docker-flarum，参见 [LICENSE](LICENSE)。
