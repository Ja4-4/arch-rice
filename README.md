# دليل تثبيت Arch Linux (دوال بوت مع Windows) + رايس كامل

جهاز: **MSI — i7 — RTX 3050** · بدون فلاش USB · Arch كنظام ثانوي كامل جنب Windows.

---

## ⚠️ قبل أي شي
- **خذ نسخة احتياطية (Backup)** لملفاتك المهمة. تقسيم القرص دايماً فيه احتمال خطأ.
- جهازك **UEFI** → اتبع مسار الفلاش (أسهل وأضمن).
- **عطّل Secure Boot** من BIOS (مفتاح الدخول للـ BIOS في أجهزة MSI غالباً `Delete` أو `F2`).

---

## الترتيب الكامل (نظرة سريعة)

| المرحلة | وين | تسوي وش |
|--------|------|---------|
| 0 | Windows | Backup |
| 1 | Windows | تقليص القرص + عمل فلاش بوت (Rufus) |
| 2 | BIOS/Live | بوت من الفلاش (F11) + `archinstall` |
| 3 | Arch | تنزيل السكربتات داخل الأرش |
| 4 | Arch | تشغيل السكربتات بالترتيب |
| 5 | Arch | الصور + تبديل الثيمات |

---

## المرحلة 1 — على Windows

1. **قلّص القرص**: `Disk Management` ← يمين على C: ← `Shrink Volume` ← قلّص **100 GB** على الأقل → اتركها `unallocated` (لا تسوي عليها partition).
2. **حمّل الـ ISO**: من https://archlinux.org/download/ (الحجم ~1.3 جيجا).
3. **اعمل فلاش بوت بـ Rufus**: حمّل Rufus من https://rufus.ie ← افتحه:
   - `Device` → اختر الفلاش (8 أو 16 جيجا — **بينمسح كله**)
   - `SELECT` → اختر ملف الـ ISO
   - `Partition scheme` → **GPT** ، `Target system` → **UEFI**
   - `START` → لو سألك اختر وضع **DD Image** → انتظر لين يخلص.
4. **عطّل Secure Boot** من BIOS، ثم ريستارت واضغط **F11** (قائمة البوت في MSI) ← اختر الفلاش (الخيار اللي يبدأ بـ `UEFI:`).

> بديل: **Ventoy** (ventoy.net) — تركّبه مرة على الفلاش وتنسخ أي ISO عليه بالسحب والإفلات. مثالي للفلاش 16 جيجا لو تبي ملتي-بوت.

---

## المرحلة 2 — تثبيت الأرش الأساسي

داخل بيئة الأرش الحية اكتب:

```bash
archinstall
```

الإعدادات:
- **Disk configuration** → اختر المساحة الفاضية (unallocated) → `Best-effort default`
- **Bootloader** → `grub`  (يكتشف Windows للدوال بوت)
- **Profile** → `Minimal`  (لا تختار ديسكتوب، السكربت يركّبه)
- **Network** → `NetworkManager`  ← مهم عشان النت يشتغل بعد الريبوت
- حدد **username + password + root password**
- `Install` → انتظر → `reboot`

---

## المرحلة 3 — تنزيل السكربتات داخل الأرش

بعد ما يشتغل الأرش وتسجّل دخول (نت شغّال)، أسهل طريقة:
- افتح المتصفح، سجّل دخول claude.ai، افتح نفس المحادثة، ونزّل الملفات الـ 6.

أو انسخها من قرص Windows (نفس الهارد — يظهر لك بمدير الملفات).

الملفات:
```
arch-setup.sh   nvidia-hybrid.sh   forensics.sh   rice-install.sh   add-image.sh
```

حطها بمجلد واحد وأعطها صلاحية تنفيذ:
```bash
chmod +x *.sh
```

---

## المرحلة 4 — تشغيل السكربتات بالترتيب

```bash
./arch-setup.sh      # 1) النظام + أدوات الأمن والبرمجة + KDE (احتياطي)
./nvidia-hybrid.sh   # 2) درايفر Intel + RTX 3050 ، ثم:
sudo reboot
./forensics.sh       # 3) أدوات التحقيق الرقمي
./rice-install.sh    # 4) Hyprland + مبدّل الثيمات الأربعة
```

بعد `rice-install.sh`: سجّل خروج ← عند شاشة الدخول اختر جلسة **Hyprland**.

> ملاحظة: `terminal-rice.sh` القديم **ملغى** — `rice-install.sh` بديله وأشمل.

---

## المرحلة 5 — الصور وتبديل الأجواء

**الصور** (آيرون مان، ديكستر، مستر روبوت، سايبربانك) — تجيبها بنفسك وتحطها:
```bash
./add-image.sh dexter  ~/Downloads/dexter.jpg   wall
./add-image.sh jarvis  ~/Downloads/ironman.png  logo
```
الثيمات: `jarvis` · `cyberpunk` · `mrrobot` · `dexter`

**تبديل الجو**:
```bash
theme cyberpunk      # أو jarvis / mrrobot / dexter
```
أو زر **`Super+T`** داخل Hyprland.

---

## مفاتيح Hyprland

| الزر | الوظيفة |
|------|---------|
| `Super+Return` | تيرمنال |
| `Super+Space` | مشغّل التطبيقات |
| `Super+T` | تبديل الثيم |
| `Super+Q` | إغلاق النافذة |
| `Super+E` | مدير الملفات |
| `Super+L` | قفل الشاشة |
| `Super+1..5` | الأسطح الافتراضية |
| `Super+Shift+S` | سكرين شوت منطقة |
| `Alt+Shift` | عربي/إنجليزي |

**تشغيل الكرت القوي لتطبيق معيّن**: `prime-run <app>` (مثال: `prime-run steam`).

---

## (اختياري) تحميل Claude Code — وكيل AI بالتيرمنال

```bash
curl -fsSL https://claude.ai/install.sh | bash
```
يحتاج اشتراك Pro/Max أو API. مثالي لمشروع جارفيس حقك.

---

## حل مشاكل سريعة
- **الدخول لـ Hyprland يطلع مشوّش** → اختر جلسة `Plasma (X11)` مؤقتاً.
- **سطر بالإعدادات يطلع خطأ** (تغيّر صيغة Hyprland بين النسخ) → احذف السطر وكمّل، الباقي يشتغل.
- **Windows ما يظهر بقائمة GRUB** → `sudo os-prober && sudo grub-mkconfig -o /boot/grub/grub.cfg`.
