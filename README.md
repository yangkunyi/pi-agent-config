# pi-agent-config

yky 的 pi / grok 可移植配置。多机共享:一台改,其余 `git pull` + 对应 install。

**skills 只有一棵树**:`~/.agents/skills/`(共享 Agent Skills 根)。pi 直接读它,`~/.grok/skills` 软链到它,其它 agent 的目录由 cc-switch 以 symlink 指过去。决策见 `docs/adr/0001`。

## 内容

**全局 skills(源 + 快照)** — `skills/`,19 个:

- `grilling` / `tdd` / `wayfinder` / `code-review` / `domain-modeling` … 在这里编辑,然后拷进 `~/.agents/skills/`
- 七个 beads 相关成员(`setup-matt-pocock-skills`、`drain`、`to-tickets`、`implement`、`to-spec`、`triage`、`ask-matt`)的**源在 `beads-matt-dag/skills/`**,不在这里
- lark / archon-cli 那 29 个由各自的 CLI 安装器放进共享根,本仓不保存

**grok** → `~/.grok/`(`./install-grok.sh`):

- `grok/agents/` — 自定义 agent 定义(软链)
- `grok/AGENTS.md` — 全局 agent 指引(软链)
- `grok/skills` — 不再单独一棵;`install-grok.sh` 把 `~/.grok/skills` 指到 `~/.agents/skills`
- `grok/config.toml` — 模板(`max_depth`、bundled skill ignore 等);**故意不软链**,各机本地实体文件

**pi 侧不再由本仓管理**(2026-09-14,ADR-0003):`~/.pi/agent/` 下的 `agents/`、`AGENTS.md`、`settings.json`、`optimizer.json`、`models.json` 都是本地文件,`models.json` 归 cc-switch。原先的 `install.sh` 已删除 —— 它会重建 `~/.pi/agent/skills` 这条软链,把共享根遮蔽掉。

**不含**: `auth.json`(各机本地登录)、sessions、missions、run-history、downloads、bin、node_modules、hooks(本机绝对路径)。

## 用法(每台机器一次)

```bash
git clone git@github.com:yangkunyi/pi-agent-config.git ~/pi-agent-config
~/pi-agent-config/install-grok.sh   # grok: agents/ + AGENTS.md + skills 软链
```

pi 与其它 agent 的 skills 由 cc-switch 管:存储位置 `unified`(=`~/.agents/skills`),同步方式 `symlink`,整棵树随 WebDAV 走。

## 更新

改完 push;其他机器:

```bash
cd ~/pi-agent-config && git pull && ./install-grok.sh
```

改全局 skill:`skills/<name>/` 里改 → 拷进 `~/.agents/skills/<name>/`。改 grok 指引:改 `grok/AGENTS.md`(软链,改完即生效)。
