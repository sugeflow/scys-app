# iPhone 更新约定

- 用户要求更新 App 时保留登录状态和本地数据，默认必须覆盖安装。
- 保持 Bundle ID `me.suge.scys` 和现有签名团队不变。
- 构建完成后，使用 `xcrun devicectl device install app --device <device-id> <signed-app-path>` 安装已签名的 `.app`。
- 不使用默认的 `flutter install`：当前 Flutter 版本默认先卸载旧 App，会清除 WebView 登录数据。
- 覆盖安装失败时不得自动卸载、清除 App 数据或更换 Bundle ID；说明具体失败原因，再由用户决定是否允许删除重装。
- 用户偏好直接完成必要的构建和安装，不要反复进行额外检查或长时间模拟器诊断。
