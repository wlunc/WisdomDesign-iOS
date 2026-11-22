# iOS Provider 校验与 CI 集成（登记豁免）

## 运行

```bash
cd <workspace>   # 必须与 ../wisdomdesign 同级
python3 iOS/ai/skill-provider/validate_provider.py
# exit 0 时打印 recomputed status 与 33 cards
```

依赖：Python 3 标准库；需要同级 `wisdomdesign/` 提供 M0 provider schema、baseline 与 catalog。
校验内容：provider/capabilities/api-card 三个 schema（含 additionalProperties）、index 与磁盘卡片一致、
卡片/证据引用可解析、status 由证据重算并与 `provider.json` 一致、snapshot stale 声明与当前 API 哈希一致、
组件覆盖声明（10/37）与 catalog 一致。

## 为什么未接入 wisdomdesign CI

- `wisdomdesign` 的 GitHub Actions 只 checkout 自己仓，**无法访问同级 iOS 仓**（iOS 是独立仓；本轮工作区是本地多仓布局）。
- iOS Provider 的原生构建/模拟器验证由 iOS 仓自有门禁负责；本校验属于平台侧契约门禁，不是跨仓结构检查。
- 因此按任务允许的“明确登记豁免”处理：本文件 + `verification.json#/ciIntegration`（status=exempt-registered）登记。

## 平台责任与后续接线

- 责任：iOS Provider 所有者在**每次修改 provider 源、API 卡、capabilities 或 verification 之后**运行上述命令，并在提交/评审中附退出码。
- 打包/发布前：流水线负责人应在打包前运行该命令（或读取 `verification.json#/statusComputation` 的 derivedEffective），不得只复制 `provider.json` 的静态字段。
- 若未来 iOS 仓接入自己的 CI：在 iOS 仓 CI 增加 `python3 ai/skill-provider/validate_provider.py` 步骤即可；若 wisdomdesign CI 引入多仓 checkout，也可在该 checkout 下运行同命令。
- 2026-11-22 本轮已运行：exit 0（33 cards, status=experimental）。
