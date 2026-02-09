# Android DHCPv6 客户端模块

## 简介

这是一个 KernelSU / Magisk 模块，专为 Android 设备设计，用于启用完整的 **Stateful DHCPv6（有状态 DHCPv6）** 客户端功能。
Android 原生系统通常仅支持 SLAAC（无状态自动配置），这导致在许多现代企业网络、校园网（如清华大学校园网）或某些特定 ISP 环境下无法正确获取 IPv6 地址。
本模块通过移植标准的 `wide-dhcpv6` 客户端，并集成智能化的启停脚本，完美解决了这一痛点。

## 核心功能

- **有状态 DHCPv6 支持**：完整支持 IA_NA（获取非临时 IPv6 地址）和 IA_PD（前缀代理）模式。
- **全自动智能化管理**：
  - **自动随连**：监测 WiFi 连接状态，连接成功后立即启动客户端获取 IP。
  - **自动释放**：监测 WiFi 断开，断开后自动停止进程，释放资源。
  - **极速响应**：针对 WiFi 快速切换（Flap）场景进行了特殊优化，秒级响应，告别卡顿。
- **后台稳定运行**：采用独特的 Pipe Keep-alive 技术，即使在最新的 Android 版本上也能稳定后台运行，无需修改系统镜像或重新编译内核。
- **持久化 DUID**：自动生成并妥善保存 DUID 文件，确保设备重启或重连后，DHCP 服务器分配相同的 IP 地址（需服务端支持）。
- **高度可配置**：内置标准的 `dhcp6c.conf` 配置文件，高级用户可根据网络需求自由定制请求参数。

## 安装指南

1. **环境要求**：
   - 已获取 Root 权限（KernelSU 或 Magisk）。
   - Android 内核开启了 IPv6 支持（绝大多数现代设备默认开启）。
   - 建议安装 Busybox 模块以获得最佳脚本兼容性。
2. **刷入步骤**：
   - 下载本模块的 ZIP 包。
   - 打开 Magisk Manager 或 KernelSU 应用。
   - 选择“模块” -> “从本地安装”，选择 ZIP 包刷入。
   - 重启手机生效。

## 使用说明

模块安装并重启后即自动生效。

- **连接 WiFi**：模块会自动尝试通过 DHCPv6 获取 IPv6 地址。
- **断开 WiFi**：模块会自动停止后台进程。

您可以通过以下命令查看获得的 IPv6 地址：

```bash
ip -6 addr show wlan0
```

## 故障排查

如果无法获取 IPv6 地址，请按照以下步骤排查：

1. **检查日志**：查看模块运行日志，定位错误原因。

   ```bash
   cat /data/adb/dhcpv6/run/dhcpv6.log
   ```

2. **手动测试**：在终端（如 Termux）中获取 Root 权限后手动运行启动脚本，观察输出。

   ```bash
   su
   sh /data/adb/modules/dhcpv6/scripts/start.sh
   ```

3. **配置文件**：检查 `/data/adb/modules/dhcpv6/dhcp6c.conf` 是否符合当前网络环境要求。

## 开发者

- **作者**：horrzs
- **基于**：[wide-dhcpv6 开源项目](https://github.com/Mygod/wide-dhcpv6)、[DHCPv6-Client-Android](https://github.com/Mygod/DHCPv6-Client-Android)


## Star History

<a href="https://www.star-history.com/#horrzs/DHCPv6Client-Magisk&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=horrzs/DHCPv6Client-Magisk&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=horrzs/DHCPv6Client-Magisk&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=horrzs/DHCPv6Client-Magisk&type=date&legend=top-left" />
 </picture>
</a>
