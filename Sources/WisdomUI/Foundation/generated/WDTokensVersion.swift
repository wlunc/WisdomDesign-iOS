// 本文件由 wisdomdesign/tools/token-build/build.js 生成，请勿手改。
// 修改请编辑 wisdomdesign/tokens/wisdom.tokens.json 后重新生成。
// tokens v1.0.0 · sha256:e552bb87e270


/// 令牌变更集自证（G7 / U14）：banner（生成物第 3 行）与 dist/tokens.manifest.json 同值。
/// `sha256` = 令牌源文件（tokens/wisdom.tokens.json）字节的 SHA-256；`sha12` = 其前 12 位。
/// iOS SPEC §1.5.4 写的 `WDTokensVersion.hash` 即本文件的 `sha12`（同一值的文档别名）。
public enum WDTokensVersion {
    public static let version: String = "1.0.0"
    public static let sha256: String = "e552bb87e27055c82073d7b28546608bf9eb7b7ec6ebb84d2cddafcbbd1e9f3b"
    public static let sha12: String = "e552bb87e270"
    /// 已生成的 scheme 清单（M0-1 schemes 维度）。
    public static let schemes: [String] = ["light", "dark"]
    /// 默认 scheme（schemes.<name>.isDefault == true）。
    public static let defaultScheme: String = "light"
    /// U12 语义色槽位数（生成器 --check 断言 == 32）。
    public static let colorSlotCount: Int = 32
}
