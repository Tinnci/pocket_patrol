# PocketPatrol

一个基于 Flutter 的应用，将旧手机变身为远程监控摄像头，可通过 Tailscale 网络远程访问，适合家庭环境下的安全监控和旧设备再利用。

本项目最初基于 Flutter 团队的 Material 3 Demo，展示了 M3 组件、排版、色彩系统和海拔（Elevation）等特性。支持明/暗模式、色彩种子、以及 Material 2/3 的切换对比。

> **应用场景**：利用闲置手机作为家庭监控摄像头，通过 Tailscale 实现远程安全访问，是旧手机再利用的极佳方式。

## 主要功能

- **实时监控**：通过手机摄像头实时查看画面，支持录像、截图等操作。
- **远程连接**：集成 Tailscale 网络，支持远程安全访问。
- **录像管理**：浏览、回放、下载和删除历史录像。
- **多样设置**：支持摄像头参数、运动检测、通知推送、网络配置等自定义。

## 主要界面

1. **实时画面**：显示当前摄像头画面，支持录像、截图、状态指示等。
2. **录像管理**：浏览和管理历史录像，支持回放、下载、删除。
3. **设置**：配置摄像头、运动检测、通知、网络等参数。

## Original Demo Features (Still available for reference)

# Material 3 Demo

This sample Flutter app showcases Material 3 features in the Flutter Material library. These features include updated components, typography, color system and elevation support. The app supports light and dark themes, different color palettes, as well as the ability to switch between Material 2 and Material 3. For more information about Material 3, the guidance is now live at https://m3.material.io/.

This app also includes new M3 components such as IconButtons, Chips, TextFields, Switches, Checkboxes, Radio buttons and ProgressIndicators. 

# Preview

<img width="400" alt="Screen Shot 2022-08-12 at 12 00 28 PM" src="https://user-images.githubusercontent.com/36861262/184426137-47b550e1-5c6e-4bb7-b647-b1741f96d42b.png"><img width="400" alt="Screen Shot 2022-08-12 at 12 00 38 PM" src="https://user-images.githubusercontent.com/36861262/184426154-063a39e8-24bd-40be-90cd-984bf81c0fdf.png">


# Features
## Icon Buttons on the Top App Bar
<img src="https://user-images.githubusercontent.com/36861262/166506048-125caeb3-5d5c-4489-9029-1cb74202dd37.png" width="25"/>  Users can switch between a light or dark theme with this button.

<img src="https://user-images.githubusercontent.com/36861262/166508002-90fce980-d228-4312-a95f-a1919bb79ccc.png" width="25" />  Users can switch between Material 2 and Material 3 for the displayed components with this button.

<img src="https://user-images.githubusercontent.com/36861262/166511137-85dea8df-0017-4649-b913-14d4b7a17c2f.png" width="25" /> This button will bring up a pop-up menu that allows the user to change the base color used for the light and dark themes. This uses a new color seed feature to generate entire color schemes from a single color.

## Component Screen
The default screen displays all the updated components in Material 3: AppBar, common Buttons, Floating Action Button(FAB), Chips, Card, Checkbox, Dialog, NavigationBar, NavigationRail, ProgressIndicators, Radio buttons, TextFields and Switch.

### Adaptive Layout
Based on the fact that NavigationRail is not recommended on a small screen, the app changes its layout based on the screen width. If it's played on iOS or Android devices which have a narrow screen, a Navigation Bar will show at the bottom and will be used to navigate. But if it's played as a desktop or a web app, a Navigation Rail will show on the left side and at the same time, a Navigation Bar will show as an example but will not have any functionality.

Users can see both layouts on one device by running a desktop app and adjusting the screen width.

## Color Screen
With Material 3, we have added support for generating a full color scheme from a single seed color. The Color Screen shows users all of the colors in light and dark color palettes that are generated from the currently selected color.

## Typography Screen
The Typography Screen displays the text styles used in for the default TextTheme.

## Elevation Screen
The Elevation screen shows different ways of elevation with a new supported feature "surfaceTintColor" in the Material library.
