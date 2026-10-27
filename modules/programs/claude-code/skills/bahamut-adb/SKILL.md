---
name: bahamut-adb
description: Connect adb from this devbox (hichi-devbox) to the Android Studio emulator running on bahamut (Windows), then install/restart/debug the Loom app (dev.chst.orochi.loom). Use when the user asks to connect to adb, the emulator, bahamut, install an APK, check logcat, or test a Loom build on Android.
---

# adb to the bahamut emulator

## Topology

- **devbox** (this machine, NixOS): `hichi-devbox`, Tailscale IP `100.87.92.85`, LAN `192.168.0.132`. Only TCP 22 is open in the firewall. No adb installed globally — use `nix shell nixpkgs#android-tools -c adb ...`.
- **bahamut** (Windows, Tailscale `100.88.16.109`): runs Android Studio + emulator `emulator-5554` (adb port **5555** = console port + 1). No SSH server, so Claude cannot reach it directly. The user runs commands there.
- Windows adb: `C:\Users\Lionswrath\AppData\Local\Android\Sdk\platform-tools\adb.exe` (from WSL: `/mnt/c/Users/Lionswrath/AppData/Local/Android/Sdk/platform-tools/adb.exe`).
- **APK share** on the devbox: container `loom-apk-share` serves `~/.local/share/orochi-loom/apks/*.apk` at `http://100.87.92.85:8765/`.

## Do NOT

- Don't open firewall ports on bahamut (a TCP 5037 rule was deliberately removed). Don't suggest WSL `networkingMode=mirrored` — bahamut's Windows version doesn't support it.
- Don't kill other users' / unknown sshd sessions holding ports; pick another port instead.

## Connect (SSH reverse tunnel, outbound from bahamut)

1. Ask the user to run in **Windows PowerShell on bahamut** (NOT WSL — WSL's 127.0.0.1 is not Windows' localhost):
   ```powershell
   ssh -N -R 5556:127.0.0.1:5555 lionswrath@100.87.92.85
   ```
   It asks for the devbox password, then appears to hang — that's correct; window must stay open.
   If `emulator-XXXX` differs, the right-hand port is XXXX+1 (user can check with `adb.exe devices`).
2. The emulator accepts only ONE adb connection. Ask the user to free it (WSL, in platform-tools dir): `./adb.exe kill-server`. Android Studio may grab it back; closing Studio's Device Manager/Logcat (or Studio) helps. The emulator keeps running.
3. Verify and connect from the devbox:
   ```bash
   ss -ltn | grep 5556          # tunnel listening?
   nix shell nixpkgs#android-tools -c sh -c 'adb connect 127.0.0.1:5556; sleep 3; adb devices -l'
   ```
4. If `unauthorized`: user taps **Allow** (+ "Always allow") on the emulator's USB-debugging prompt. Re-run `adb devices -l`; expect `device`.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Connection refused` on 127.0.0.1:5556 | Tunnel not up. `ss -ltn \| grep 5556` empty → ssh not running / password not entered / OpenSSH client missing (`Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0`). |
| `remote port forwarding failed` in user's ssh | Port taken on devbox (`ss -ltnp \| grep <port>`); use another port, e.g. 5557. |
| `offline`, raw handshake gets no bytes back | ssh run from WSL instead of PowerShell, or Windows adb server still holds the emulator → `adb.exe kill-server`. |
| `unauthorized` | Accept the prompt on the emulator. |

Raw handshake probe (no reply = far end not reaching emulator):
```bash
printf 'CNXN\x00\x00\x00\x01\x00\x10\x00\x00\x07\x00\x00\x00\x32\x02\x00\x00\xbc\xb1\xa7\xb1host::\x00' | timeout 5 nc 127.0.0.1 5556 | od -c | head
```

## Common tasks (devbox, after connecting)

Use `A="nix shell nixpkgs#android-tools -c adb -s 127.0.0.1:5556"` style invocations:
```bash
ls -t ~/.local/share/orochi-loom/apks | head            # newest builds
adb -s 127.0.0.1:5556 install -r ~/.local/share/orochi-loom/apks/<name>.apk
adb -s 127.0.0.1:5556 shell am force-stop dev.chst.orochi.loom
adb -s 127.0.0.1:5556 shell am start -n dev.chst.orochi.loom/.MainActivity
adb -s 127.0.0.1:5556 logcat -d -s flutter | tail -100  # Flutter logs (use -d; don't stream forever)
adb -s 127.0.0.1:5556 exec-out screencap -p > <scratchpad>/screen.png   # then Read it
adb -s 127.0.0.1:5556 shell dumpsys package dev.chst.orochi.loom | grep -E 'versionName|lastUpdateTime'
```
"Activity not started, intent delivered to top-most instance" = app already open; force-stop first.

## Disconnect

`adb disconnect 127.0.0.1:5556` on the devbox, then the user closes the PowerShell ssh window. Android Studio reconnects on its own.

## Fallback: user installs on bahamut without the tunnel

`~/loom.sh <apk-name>` in bahamut's WSL (downloads from the share, `adb.exe install -r`, restarts the app). Without args it lists APKs.
