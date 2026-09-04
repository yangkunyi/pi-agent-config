# pi-agent-config

yky 的 pi / grok 可移植配置。多机共享:一台改,其余 `git pull` + 对应 install。

pi 和 grok 的 skills / agents / 全局指引分开放: spawn API 不一样,不能共用一棵树。

## 内容

pi → `~/.pi/agent/`(`./install.sh`):

- `skills/` — 自定义 skills
- `agents/` — 自定义 subagent 定义
- `AGENTS.md` — 全局 agent 指引
- `settings.json` — pi 设置
- `optimizer.json` — optimizer 配置
- `models.json` — 模型 provider baseUrl
- `npm/package.json` + `package-lock.json` — 扩展依赖(各机 `npm install`)

grok → `~/.grok/`(`./install-grok.sh`):

- `grok/skills/` — 自定义 skills
- `grok/agents/` — 自定义 agent 定义
- `grok/AGENTS.md` — 全局 agent 指引
- `grok/config.toml` — grok 设置(`max_depth`、bundled skill ignore 等)

**不含**: `auth.json`(各机本地登录)、sessions、missions、run-history、downloads、bin、node_modules、hooks(本机绝对路径)。

## 用法(每台机器一次)

```bash
git clone git@github.com:yangkunyi/pi-agent-config.git ~/pi-agent-config
~/pi-agent-config/install.sh       # pi
~/pi-agent-config/install-grok.sh  # grok
```

然后本机跑一次 `pi` / `grok` 登录,生成自己的 `auth.json`。

## 更新

改完 push;其他机器:

```bash
cd ~/pi-agent-config && git pull
./install.sh       # 只更新 pi
./install-grok.sh  # 只更新 grok
```

改 grok skill: 直接改 `grok/skills/<name>/`(`~/.grok/skills` 是软链,同一份)。
