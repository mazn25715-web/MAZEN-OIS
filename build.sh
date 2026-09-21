#!/usr/bin/env bash
set -euo pipefail

# تنظيف أي عمليات بناء سابقة
rm -rf build
mkdir build && cd build

# تهيئة إعدادات live-build لدبيان تريكسي وتوجيه المرايا رسمياً
lb clean --purge || true
lb config \
    --distribution trixie \
    --archive-areas "main contrib non-free non-free-firmware" \
    --mirror-bootstrap "http://deb.debian.org/debian/" \
    --mirror-binary "http://deb.debian.org/debian/" \
    --debian-installer live \
    --bootappend-live "boot=live components locales=ar_EG.UTF-8,en_US.UTF-8 keyboard-layouts=ara,us" \
    --iso-application "Mazen OS" \
    --iso-volume "MAZEN_OS" \
    --iso-publisher "Mazen OS Project"

# إنشاء هيكل المجلدات المطلوبة لتفادي مشاكل النسخ
mkdir -p config/package-lists \
         config/includes.chroot/usr/local/bin \
         config/includes.chroot/usr/share/backgrounds/mazen-os \
         config/includes.chroot/usr/share/pixmaps \
         config/includes.chroot/usr/share/applications \
         config/includes.chroot/etc/lightdm \
         config/hooks/live

# نسخ الملفات والأصول مع التحقق من وجودها
[ -f ../config/package-lists/mazen.list.chroot ] && cp ../config/package-lists/mazen.list.chroot config/package-lists/ || true
[ -d ../config/includes.chroot/usr/local/bin ] && cp -r ../config/includes.chroot/usr/local/bin/* config/includes.chroot/usr/local/bin/ || true
[ -f ../config/includes.chroot/usr/share/applications/mazen-app-store.desktop ] && cp ../config/includes.chroot/usr/share/applications/mazen-app-store.desktop config/includes.chroot/usr/share/applications/ || true
[ -f ../config/includes.chroot/etc/lightdm/lightdm.conf ] && cp ../config/includes.chroot/etc/lightdm/lightdm.conf config/includes.chroot/etc/lightdm/ || true
[ -f ../assets/mazen-wallpaper.svg ] && cp ../assets/mazen-wallpaper.svg config/includes.chroot/usr/share/backgrounds/mazen-os/ || true
[ -f ../assets/mazen-logo.svg ] && cp ../assets/mazen-logo.svg config/includes.chroot/usr/share/pixmaps/mazen-logo.svg || true

# منح صلاحيات التنفيذ
[ -d config/includes.chroot/usr/local/bin ] && chmod +x config/includes.chroot/usr/local/bin/* || true

# بدء البناء الفعلي وتصدير السجلات
lb build 2>&1 | tee ../build.log

# إعادة تسمية ملف الـ ISO الناتج بالشكل المطلوب تماماً
if [ -f live-image-amd64.hybrid.iso ]; then
    mv live-image-amd64.hybrid.iso ../Mazen-OS.iso
    echo "Created ../Mazen-OS.iso successfully!"
else
    echo "Error: ISO file not found!"
    exit 1
fi
