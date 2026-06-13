#!/bin/bash
# run_dev.sh – Script khởi động dev cho LuxeBag Flutter (Git Bash / MINGW64)
# Sử dụng: ./run_dev.sh
# Hoặc với thiết bị cụ thể: ./run_dev.sh emulator-5554

ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
DEVICE_ID="${1:-}"

# ── 1. Kiểm tra adb ──────────────────────────────────────────────────────────
if [ ! -f "$ADB" ]; then
  echo "⚠️  Không tìm thấy adb tại: $ADB"
else
  # ── 2. adb reverse để tunnel port 8888 ─────────────────────────────────────
  echo "🔗 Thiết lập adb reverse tcp:8888..."

  if [ -n "$DEVICE_ID" ]; then
    "$ADB" -s "$DEVICE_ID" reverse tcp:8888 tcp:8888
  else
    "$ADB" reverse tcp:8888 tcp:8888
  fi

  if [ $? -eq 0 ]; then
    echo "✅ adb reverse thành công"
  else
    echo "⚠️  adb reverse thất bại – đảm bảo emulator đang chạy"
  fi
fi

# ── 3. flutter run ────────────────────────────────────────────────────────────
echo ""
echo "🚀 Khởi động Flutter app..."

if [ -n "$DEVICE_ID" ]; then
  flutter run -d "$DEVICE_ID"
else
  flutter run
fi
