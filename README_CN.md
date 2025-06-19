# 用于内核漏洞开发的 Android 磁盘镜像（支持 Binder）
[🌐 English Version](README.md) | [🌐 中文版本](README_CN.md)

## 目的

本项目提供了一个轻量级的 Android 磁盘镜像，专为内核漏洞开发而设计 —— 特别是支持 Binder。

为何要创建这个项目：

* **Cuttlefish 使用起来令人沮丧**
* **仅仅为了编译内核与获得一个可用的镜像就下载 400+ GB 的 AOSP 实在太夸张**
* **Syzkaller 的镜像非常精简且实用**，但缺少必要的 Binder context manager

Binder 是 Android 中一个功能强大且被广泛研究的内核攻击面。为了支持漏洞开发与实验，这个镜像包含一个可运行的 `hwservicemanager` 和 Binder 上下文支持 —— 而无需完整的 Android 环境开销。

⚠️ **目前仅支持 x86/x86\_64 架构。ARM 尚不支持。**

## 快速开始：生成镜像

如果你想自行构建磁盘镜像：

```bash
git clone https://github.com/TomAPU/droidimage.git
cd droidimage
./generate.sh <output_folder>
````

整个过程大约需要 **1 小时**。构建成功后，`disk.img` 文件将位于你指定的输出文件夹中。

你也可以从以下链接下载预构建好的镜像：
[Google Drive - 预构建镜像](https://drive.google.com/file/d/1a9d4rWA3IuHUUBee1wvvtsV6w4cghTAP/view?usp=sharing)

## 功能与限制

**可用功能：**

* SSH 访问（不需要密钥，只需 SSH）
* 可运行的 `hwservicemanager`
* 启用 Binder 内核接口

**不可用的功能：**

* `logd` 和 `adb`
* `setprop` / `getprop`
* Android 中使用的 SELinux 规则（但仍然有 SELinux）
* 大多数 Android 用户空间组件
* GPU 支持（注意：Cuttlefish 在这方面也存在问题）

此镜像专注于 **纯内核级研究**，不适用于用户级 Android 应用测试。

## 内核配置

请参考以下内核配置：
[Syzkaller 的 android-5.10.config](https://github.com/google/syzkaller/blob/master/dashboard/config/linux/android-5.10.config)

确保启用了以下选项以支持 Binder：

```bash
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDERFS=y
CONFIG_ANDROID_BINDER_DEVICES="binder0,binder1"
CONFIG_ANDROID_DEBUG_SYMBOLS=y
CONFIG_ANDROID_VENDOR_HOOKS=y
```

## 使用 QEMU 和内核启动镜像

在构建或下载好 `disk.img` 之后，您可以使用 QEMU 和自行准备的内核镜像（`bzImage`）来启动它。以下示例包括对 SSH、GDB 和 QEMU monitor 的访问 — **端口号可根据需要自定义**。

```bash
# 请将路径和端口替换为您自己的值
qemu-system-x86_64 \
 -m 2048 \
 -gdb tcp::[GDB_PORT] \
 -monitor tcp::[MONITOR_PORT],server,nowait \
 -smp 4 \
 -display none -serial stdio -no-reboot \
 -device virtio-rng-pci \
 -cpu host,migratable=on \
 -kernel /path/to/bzImage \
 -device virtio-scsi-pci,id=scsi \
 -device scsi-hd,bus=scsi.0,drive=d0 \
 -drive file=/path/to/disk.img,if=none,id=d0 \
 -append "nokaslr earlyprintk=serial root=/dev/sda1 console=ttyS0" \
 -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:[SSH_PORT]-:22 \
 -net nic,model=e1000 \
 -enable-kvm -nographic -snapshot
```

### 请替换以下内容：

* `/path/to/bzImage` — 您的 Linux 内核镜像路径
* `/path/to/disk.img` — 生成的 Android 磁盘镜像路径
* `[GDB_PORT]` — 可选的 GDB 调试端口
* `[MONITOR_PORT]` — QEMU monitor 的端口
* `[SSH_PORT]` — SSH 本地转发端口

注意：启动后您无法直接与虚拟机交互，**必须通过 SSH 连接使用**。

---

## 通过 SSH 访问虚拟机

在 QEMU 启动并且虚拟机启动完成后，您可以通过以下方式 SSH 登录：

```bash
ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o PubkeyAuthentication=no \
    root@127.0.0.1 -p [SSH_PORT]
```

不需要密码或密钥设置 — 您将直接以 root 身份登录。

## 工作原理

本项目基于 **Syzkaller 的 buildroot 脚本**，在其基础上增加了运行 `hwservicemanager` 和支持 Binder 测试所需的最小 AOSP 组件集。

主要改动如下：

* 完全移除了 Android 中使用的 SELinux 规则
* 将 `hwservicemanager` 中的访问控制检查修改为始终返回 `true`，以绕过 SELinux 问题

由于其以 Syzkaller 为基础，这个设置也可能适合用于内核模糊测试工作流程。

如需深入了解基于 Binder 的内核漏洞利用技术，可参考 [这份来自 OffensiveCon 2024 的精彩演讲](https://androidoffsec.withgoogle.com/slides/offensivecon_24_binder.pdf)（注：演讲内容探讨的是基于 LKL 的模糊测试，是一种完全不同的模糊方法）。

