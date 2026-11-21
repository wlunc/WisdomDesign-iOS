import Foundation

// 成员四色的**分配规则**（设计 14 §1.3；A-11）。令牌值本身在
// `Foundation/generated/WDTokens.swift`（`WDMemberTone.fill` / `.ink`，已随外观自适应），
// 本文件只放「哪个成员用哪一档」这一条纯函数规则。

extension WDMemberTone {
  /// 按**成员 ID** 分配档位：`toneIndex = FNV1a32(memberID) mod 4`（设计 14 §1.3）。
  ///
  /// 五条设计要求逐条落在这里：
  /// 1. 输入是**成员 ID**（稳定标识），不是显示名 —— 改名不换色；
  /// 2. 纯函数、无状态、无随机 —— 冷启动 / 换机 / 换页面都同色；
  /// 3. 按 UTF-8 逐字节 —— 两端同算法才能同色（Android 侧同名函数对本表五个 fixture 对拍）；
  /// 4. `mod 4` 直接出档，不再二次映射；
  /// 5. **允许撞色** —— 四人同档是预期行为（`u_1001` 与 `u_1005` 都落在 `tone-4`），
  ///    身份靠名字与位置区分，不靠保证四色唯一。
  ///
  /// 取模基数是 `allCases.count`（当前 4），映射用显式 switch 而不是数组下标：
  /// 少一层「`allCases` 顺序」的隐含依赖，两端对拍时读起来也更直接。
  public static func assign(memberID: String) -> WDMemberTone {
    let index = Int(fnv1a32(memberID) % UInt32(allCases.count))
    switch index {
    case 0: return .tone1
    case 1: return .tone2
    case 2: return .tone3
    default: return .tone4
    }
  }

  /// FNV-1a 32 位哈希：初值 `0x811C9DC5`、乘子 `0x01000193`、按 UTF-8 逐字节、32 位回绕。
  ///
  /// `&` 系列运算符是**回绕**语义（不是溢出错误），与设计给的「32-bit wrap」一一对应；
  /// 两个常量是 FNV-1a **算法参数**（偏移基 + 质数），不是可主题化的设计令牌，
  /// 因此不受 R7「数值必须可追溯到令牌」的约束（本文件在 `Foundation/Tokens/`，属 R7 白名单）。
  /// 单测 fixture 见 `Tests/WisdomUITests/Components/WDAvatarTests.swift`（设计 §1.3 五条）。
  static func fnv1a32(_ value: String) -> UInt32 {
    var hash: UInt32 = 0x811C_9DC5
    for byte in value.utf8 {
      hash = (hash ^ UInt32(byte)) &* 0x0100_0193
    }
    return hash
  }
}
