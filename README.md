# dsh-purge-community v1.6.60 · 离线备份仓库

> 这是一个**纯备份仓库**，不是插件的官方仓库，也不接受 issue / PR。
> 目的只有一个：万一上游（GitHub 上的 `dsh-purge` 项目）某天下架或被删除，
> 你还能从这里把插件原样装回去。

- 备份对象：`dsh-purge-community` **v1.6.60**
- 目标宿主：DeepSeekRuntime（DSH）`0.2.1-rc.1`
- 备份日期：2026-10-29
- 原始来源：`https://github.com/kingcharleslzy-ai/dsh-purge/releases`
- 原版作者：小杨 / YuJunZhiXue；本版本维护：kingcharleslzy-ai
- 许可证：MIT（见插件包内 `LICENSE`）

---

## 一、仓库里有什么

| 路径 | 说明 |
|---|---|
| `release/dsh-purge-community-1.6.60.tgz` | **官方原始安装包**（1.7 MB），pnpm / DSH 可直接识别 |
| `release/dsh-purge-community-1.6.60-full-backup.zip` | 完整备份包（3.6 MB）：官方包 + 已安装副本 + 配置 + 运行状态 + 恢复脚本 |
| `restore/一键恢复.ps1` | Windows 一键恢复脚本（自动改路径、补 bundles） |
| `restore/恢复说明.md` | 详细恢复步骤与排错 |
| `SHA256SUMS.txt` | 全部文件的 SHA256 校验值 |

---

## 二、怎么恢复（Windows）

1. 完全退出 DSH（任务管理器确认没有 `DeepSeekRuntime.exe`）；
2. 下载 `release/dsh-purge-community-1.6.60-full-backup.zip` 并解压；
3. 右键 `一键恢复.ps1` → 用 PowerShell 运行；
4. 重开 DSH，让它执行一次 `purge_status`，能看到 **80 patch** 的状态即成功。

手动方式（脚本跑不通时）：

```powershell
$pkg = "$env:USERPROFILE\.dsh\dsh-purge-community\pkgs\f742c17f8f0bcd95501b7a4123c2283ebe2f135fe44ad1339fb928e0eeabc6c1"
New-Item -ItemType Directory -Force -Path $pkg | Out-Null
Copy-Item ".\dsh-purge-community-1.6.60.tgz" $pkg -Force

$dst = "$env:USERPROFILE\.dsh\profiles\desktop\node_modules\dsh-purge-community"
Copy-Item ".\dsh-purge-community" (Split-Path $dst) -Recurse -Force
```

再确认 `%USERPROFILE%\.dsh\profiles\desktop\package.json` 里：

```json
"dependencies": { "dsh-purge-community": "file:C:/Users/<用户名>/.dsh/dsh-purge-community/pkgs/f742c17f.../dsh-purge-community-1.6.60.tgz" },
"dsh": { "profile": { "bundles": ["@deepseek-ai/dsh-base", "@deepseek-ai/dsh-web-app", "dsh-purge-community"] } }
```

---

## 三、校验

```
tgz : F742C17F8F0BCD95501B7A4123C2283EBE2F135FE44AD1339FB928E0EEABC6C1
zip : 08D4451B521638163B89D705FCA58560EAB1DEDEEC6686178D02E5F4810EA757
```

tgz 的哈希正好等于插件缓存目录名（`f742c17f…`），哈希对上就说明是原包、未被替换。

---

## 四、说明

- 本仓库仅为个人存档，方便断网/断源时重装；**不提供任何授权、激活或绕过服务**。
- 插件版权归原作者所有，此处按 MIT 许可证原样保存，未做任何修改。
- 如果上游恢复，请优先使用上游的最新版本；本仓库只保证 1.6.60 这一个版本可用。
