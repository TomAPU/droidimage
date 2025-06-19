# Android Disk Image for Kernel Exploit Development with Binder Support
[🌐 English Version](README.md) | [🌐 中文版本](README_CN.md)

## Purpose

This project provides a lightweight Android disk image tailored for kernel exploit development—specifically with Binder support.

Why this exists:

* **Cuttlefish is frustrating to use**
* **Downloading 400+ GB of AOSP just to get a working image is overkill**
* **Syzkaller’s image is minimal and useful**, but lacks the necessary Binder context manager

Binder is a powerful and widely studied kernel attack surface in Android. To support exploit development and experimentation, this image includes a functional `hwservicemanager` and Binder context support—without the overhead of a full Android environment.

⚠️ **Currently supports only x86/x86\_64. ARM is not supported (yet).**

## Quick Start: Image Generation

To build the disk image yourself:

```bash
git clone https://github.com/TomAPU/droidimage.git
cd droidimage
./generate.sh <output_folder>
```

This will take approximately **1 hour** to complete. Upon success, a `disk.img` file will be located in your specified output folder.

Alternatively, you can download a prebuilt image from:
[Google Drive - Prebuilt Image](https://drive.google.com/file/d/1a9d4rWA3IuHUUBee1wvvtsV6w4cghTAP/view?usp=sharing)

## Features & Limitations

**What works:**

* SSH access (No keys needed, just SSH)
* Functional `hwservicemanager`
* Binder kernel interface enabled

**What doesn't:**

* `logd` and `adb`
* `setprop` / `getprop`
* SELinux rules used in Android  (But can still has SELinux)
* Most Android userspace things
* GPU support (Note: Cuttlefish also struggles here)

This image is focused **purely on kernel-level research**, not user-level Android app testing.

## Kernel Configuration

Use this kernel configuration as a reference:
[android-5.10.config from Syzkaller](https://github.com/google/syzkaller/blob/master/dashboard/config/linux/android-5.10.config)

Ensure the following options are enabled for Binder:

```bash
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDERFS=y
CONFIG_ANDROID_BINDER_DEVICES="binder0,binder1"
CONFIG_ANDROID_DEBUG_SYMBOLS=y
CONFIG_ANDROID_VENDOR_HOOKS=y
```

## Running the Image with QEMU + Kernel

Once you have built or downloaded the `disk.img`, you can boot it using QEMU and your own kernel image (`bzImage`). The example below includes SSH, GDB, and monitor access — **you may customize the port numbers as needed**.

```bash
# Replace paths and ports with your own values
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

### Replace:

* `/path/to/bzImage` — your Linux kernel image
* `/path/to/disk.img` — the generated Android disk image
* `[GDB_PORT]` — port for optional GDB debugging
* `[MONITOR_PORT]` — port for QEMU monitor
* `[SSH_PORT]` — local forwarded port for SSH access

Note that after booting, you can not directly interact with the VM, you *have* to use SSH.


## Accessing the VM via SSH

After QEMU starts and the VM boots up, you can SSH into it using:

```bash
ssh -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o PubkeyAuthentication=no \
    root@127.0.0.1 -p [SSH_PORT]
```

No password or key setup is needed — you’ll get direct root access.

## How It Works

This project is based on **Syzkaller’s buildroot scripts**, enhanced with a minimal set of AOSP components necessary to run `hwservicemanager` and support Binder-based testing.

Notable modifications:

* SELinux rules used in Android are stripped out entirely
* Access control checks in `hwservicemanager` are patched to always return `true` to get rid of SElinux issue.

Due to the Syzkaller base, this setup is also likely suitable for kernel fuzzing workflows.

For deeper insights on Binder-based kernel exploitation, consider reviewing [this excellent presentation](https://androidoffsec.withgoogle.com/slides/offensivecon_24_binder.pdf) from OffensiveCon 2024 (note: it explores an LKL-based fuzzing, a completely dfferent approach for fuuzzing).

