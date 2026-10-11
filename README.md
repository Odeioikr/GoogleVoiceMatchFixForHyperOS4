# Google Assistant/Gemini 语音唤醒修复 

KernelSU/systemless 模块，修复RedmiK90ProMax（POCO F8 Ultra）HyperOS 上 Hey Google 语音唤醒不支持的问题，同时支持息屏唤醒。

## 实现方法

- 将设备现有 Google App 以 systemless 方式挂载为系统特权应用，补齐热词相关权限。
- 引入同机型海外 ROM 的原始热词注册 APK 和共享 JAR，使 Google 使用 Qualcomm DSP 硬件热词检测。
- 在重启完成后自动允许并保存 Google“锁屏显示”权限，解除 HyperOS 对锁屏启动 Gemini 的拦截。

## 配套设置

- 电源键与小白条入口：[Gemini For HyperOS4（LSPosed 模块）](https://github.com/fulu2778/Gemini-For-HyperOS4)，提供长按电源键打开 Gemini、长按小白条打开圈定即搜。

## 实机测试

- 机型：Redmi K90 Pro Max（myron）
- 系统：HyperOS `4.0.0.33.XPMCNXM` / Android 17(由 酷安@江南烟雨断桥殇 提供的官改ROM)
- Google App：`17.62.10.ve.arm64`（versionCode `301813730`）
- 模块：`v1.1-candidate`（versionCode `2`）

息屏、亮屏锁屏及解锁后无需手动预激活的语音唤醒均通过。其他机型与版本未经验证。
