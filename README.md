# pi-agent-config

yky 的 pi agent 可移植配置。多机共享:一台改,其余 `git pull` + `install.sh`。

## 内容

- `skills/` — 全部自定义 skills
- `agents/` — 自定义 subagent 定义
- `AGENTS.md` — 全局 agent 指引
- `settings.json` — pi 设置
- `optimizer.json` — optimizer 配置
- `models.json` — 模型 provider baseUrl
- `npm/package.json` + `package-lock.json` — 扩展依赖(各机 `npm install`)

**不含**: `auth.json`(各机本地登录)、sessions、missions、run-history、node_modules、bin。

## 用法(每台机器一次)

```bash
git clone git@github.com:yangkunyi/pi-agent-config.git ~/pi-agent-config
~/pi-agent-config/install.sh
```

然后本机跑一次 `pi` 登录,生成自己的 `auth.json`。

## 更新

改完 push;其他机器:

```bash
cd ~/pi-agent-config && git pull && ./install.sh
```
