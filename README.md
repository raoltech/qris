# TabuQR

**Aplikasi QRIS multifungsi** — parse, edit merchant, generate QR pembayaran dengan timeout, webhook, scan kamera, dan simpan QRIS. Dibangun dengan Flutter.

## Fitur

| Fitur | Keterangan |
|-------|-----------|
| **Parse QRIS** | Lihat struktur TLV lengkap, validasi CRC, info merchant & transaksi |
| **Generate QR** | Buat QR pembayaran dinamis dengan nominal & timeout (kadaluwarsa) |
| **Scan Kamera** | Scan QRIS langsung dari kamera HP |
| **Ubah Merchant** | Edit nama & kota merchant, QRIS otomatis diperbarui |
| **Webhook** | Konfigurasi callback URL & secret key untuk notifikasi |
| **Simpan QRIS** | Bookmark QRIS favorit untuk akses cepat |
| **Salin & Simpan** | Copy string QRIS atau simpan QR sebagai JPG |

## Unduh

👉 **[Download APK terbaru](https://github.com/raoltech/qris/releases/latest)** (Android)

Atau build sendiri:
```bash
# clone
git clone https://github.com/raoltech/qris.git
cd qris/mobile

# build
flutter pub get
flutter build apk --release
```

## Cara Pakai

1. Buka aplikasi → **QRIS Tools**
2. Tempel string QRIS atau scan QR code
3. Lihat detail TLV lengkap
4. Pilih aksi:
   - **Generate QR** → masukkan nominal + timeout → QR siap dibayar
   - **Ubah Merchant** → ganti nama & kota
   - **Webhook** → atur callback URL
   - **Simpan** → bookmark untuk akses cepat

## Tech Stack

- **Flutter** 3.24 — framework UI
- **@raoltech/qris** — library QRIS modular (Node.js port ke Dart)
- **mobile_scanner** — scan QR kamera

## Library QRIS

Package `@raoltech/qris` tersedia di [npm](https://www.npmjs.com/package/@raoltech/qris) dan repositori ini di `src/`. Lihat [`test.mjs`](test.mjs) untuk contoh penggunaan.

```
npm install @raoltech/qris
```
