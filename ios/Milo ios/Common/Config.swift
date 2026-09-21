import Foundation

// MARK: - 环境配置
/// Debug/Release 环境区分
#if DEBUG
let isDebug = true
#else
let isDebug = false
#endif

// MARK: - 版本信息
let appVersion = APIConfig.appVersion
let appBuildNumber = APIConfig.appBuild
