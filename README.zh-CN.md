# 日摄

[English](README.md) | 简体中文

**看见它，也知道它的日语。**

日摄（Hibi Lens）是一款 iPhone 日语词汇应用。拍下身边的东西，或者从相册里选一张照片，应用会识别物品，并把结果做成一张可以保存和复习的日语词卡。

识别在设备本地完成。照片和词卡也留在设备里，不需要注册账号。

<a href="https://apps.apple.com/us/app/%E6%97%A5%E6%91%84/id6792243095?l=zh-Hans-CN">
  <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/zh-cn?size=250x83" alt="在 App Store 下载" height="40">
</a>

<p align="center">
  <img src="BrandAssets/Screenshots/home.png" alt="日摄首页" width="220">
  <img src="BrandAssets/Screenshots/learning-gallery.png" alt="日摄学习词卡画廊" width="220">
</p>

## 目前包括什么

- 使用 SigLIP 文本索引进行本地物品识别
- 显示日语词、假名、罗马字、发音和英文含义
- 保存词卡，并区分学习中和已掌握状态
- 支持相机拍摄和从相册导入
- 支持浅色与深色外观
- 提供英文和简体中文界面

## 关于这个仓库

这个仓库包含日摄 1.0 iOS 客户端、本地识别资源，以及用于准备词表和 SigLIP 资源的工具。

你可以通过 Issues 报告问题、询问安装方法或提供产品反馈。soft launch 期间暂不接受代码贡献，Pull Requests 已关闭。当前政策见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 环境要求

- macOS，Xcode 26.5 或更高版本
- iOS 26 模拟器或设备
- Python 3，用于运行模型准备脚本
- 大约 200 MB 可用空间，用来下载和解压 Core ML 模型

## 准备识别模型

Core ML 图像编码模型约为 176 MB，因此它作为 GitHub Release 附件单独发布，不进入普通 Git 历史。

在仓库根目录运行：

```bash
python3 scripts/prepare_siglip_model.py
```

脚本会下载固定版本的压缩包，核对文件大小和 SHA-256，然后安装到：

```text
HibiLens/Models/SigLIP/siglip_base_patch16_224_image.mlpackage
```

模型来自 `google/siglip-base-patch16-224`，固定 revision 为
`7fd15f0689c79d79e38b1c2e2e2370a7bf2761ed`，采用 Apache 2.0 许可。

如果下载失败或校验值不符，脚本会停止，不会安装该压缩包。

## 构建

模型准备完成后，打开工程：

```bash
open HibiLens.xcodeproj
```

在 Xcode 中选择 `HibiLens` scheme 和一个 iOS 模拟器，然后构建或运行。

要在 Xcode 中运行测试，请选择 `Product > Test`，并确认已经选中 iOS 模拟器。

也可以在命令行执行不需要签名的构建：

```bash
xcodebuild -project HibiLens.xcodeproj \
  -scheme HibiLens \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

如果要重新分发 fork，请改用自己的产品名称、Bundle ID 和图形资源。这个工程使用的是中性占位 App Icon。

## 识别过程

日摄使用 Core ML 版 SigLIP 图像编码器和随应用提供的文本嵌入索引。应用把照片的图像向量与物品词表进行比较，再用匹配到的条目生成日语词卡。识别和词卡存储都在设备本地完成。

文件位置和生成工具见 [docs/recognition-pipeline.md](docs/recognition-pipeline.md)。

## 隐私

日摄本地客户端不需要账号。拍摄的图片、保存的词卡和学习进度存储在设备上。只有在你主动使用相机或相册功能时，应用才会请求相应权限。

已发布的政策见 [日摄隐私政策](https://kiethrios.github.io/PrivacyPolicy/HibiLensPrivacyPolicy_zh-Hans.html)。

## 许可与品牌

这个仓库中的原创代码和工具采用 [MIT License](LICENSE)。

MIT 不覆盖仓库中的所有内容：

- 日摄名称、官方 logo、官方 App Icon 和指定产品截图受 [BRAND_ASSETS.md](BRAND_ASSETS.md) 约束。
- 源自 JMdict 的词汇材料采用 CC BY-SA 4.0。
- 词表流程使用的 Open Images 源材料采用 CC BY 4.0。
- SigLIP 及其衍生模型资源采用 Apache 2.0。

署名信息和本地许可副本见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 反馈与安全问题

可通过 GitHub Issues 报告能够复现的问题、询问安装方法或提供产品反馈。请不要在公开 Issue 中披露安全问题，按照 [SECURITY.md](SECURITY.md) 的说明提交私密漏洞报告。
