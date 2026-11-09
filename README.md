# Auto Manager — Control Europe

GUI Roblox untuk game **Control Europe**: spawn army otomatis ke grup, auto capture,
auto delete army lemah, dan auto upgrade kota. Dipecah menjadi modul kecil
(semua file < 500 baris) supaya mudah di-debug, termasuk oleh AI.

## Instalasi

**Cara A — Rojo (disarankan untuk GitHub)**
```bash
rojo build -o AutoManager.rbxl     # atau: rojo serve, lalu connect dari Studio
```

**Cara B — Manual di Studio**
1. Buat `LocalScript` bernama `AutoManager` di `StarterPlayer > StarterPlayerScripts`,
   isi dengan `src/AutoManager/init.client.lua`.
2. Di dalam LocalScript itu buat 3 `Folder`: `Core`, `Services`, `UI`.
3. Buat `ModuleScript` di tiap folder dengan nama sama seperti file di `src/AutoManager/<folder>/`
   (tanpa `.lua`) lalu salin isinya.

## Jalankan via executor (loadstring)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/rendays666/control-Europe/main/loader.lua"))()
```

`loader.lua` mengunduh tiap modul dari GitHub, mengompilasinya dengan `loadstring`, lalu
menjalankan `Boot.lua` — jalur yang sama dengan versi Studio (`init.client.lua`).

- Menjalankan ulang aman: GUI lama dihapus otomatis.
- Mau pakai branch/fork lain: set `getgenv().AutoManagerBase = "https://raw.githubusercontent.com/<user>/<repo>/<branch>/src/AutoManager/"` sebelum menjalankan loader.
- GitHub raw di-cache ±5 menit, jadi perubahan terbaru bisa tertunda sebentar.
- Syarat executor: `game:HttpGet` (atau `request`), `loadstring`, dan `require` untuk modul game.

## Struktur

```
loader.lua                 Entry point executor (loadstring)
src/AutoManager/
├─ init.client.lua        Entry point Studio (menyiapkan `load`)
├─ Boot.lua               Merakit semua modul (dipakai Studio & executor)
├─ Core/
│  ├─ Config.lua          Warna, default, interval, nama remote (EDIT DI SINI)
│  ├─ Context.lua         Objek `ctx` yang dibagikan ke semua modul + ctx.every()
│  ├─ Janitor.lua         Pembersih koneksi/instance/thread
│  ├─ Logger.lua          Log terpusat (level info/ok/warn/error)
│  └─ Remote.lua          Pembungkus Network:Bind(evt):FireServer(...)
├─ Services/              Logic game (tanpa UI)
│  ├─ World.lua           Baca negara, tile, grup, soldier
│  ├─ Spawner.lua         Spawn army + masukkan ke grup
│  ├─ AutoCapture.lua
│  ├─ AutoDelete.lua
│  └─ AutoUpgrade.lua
└─ UI/                    Tampilan
   ├─ Widgets.lua         Helper tombol/input/label/scroll
   ├─ MainWindow.lua      Window, drag, minimize, tab, hotkey
   ├─ LogPanel.lua        Panel log global
   ├─ ArmyPage.lua
   └─ UpgradePage.lua
```

## Cara kerja `ctx`

Semua modul menerima satu objek `ctx` (lihat `Core/Context.lua`):

| Field | Isi |
|---|---|
| `ctx.Config` | Konstanta |
| `ctx.state` | Setting yang diubah user di GUI |
| `ctx.runtime` | Status untuk ditampilkan UI (negara, status upgrade) |
| `ctx.log(msg, level)` | Tulis log |
| `ctx.remote.fire(key, ...)` | Kirim RemoteEvent (key dari `Config.Remotes`) |
| `ctx.world` | Akses data game (`Services/World.lua`) |
| `ctx.every(interval, fn, name)` | Loop aman (error tidak mematikan loop) |
| `ctx.destroy()` | Matikan semua & hapus GUI |

## Tips debugging (termasuk untuk AI)

- Kasih ke AI **hanya file yang relevan** + `Core/Context.lua`, bukan seluruh proyek.
- Bug tampilan → `UI/`. Bug logic → `Services/`. Game berubah (nama folder/remote) →
  `Services/World.lua` dan `Core/Config.lua`.
- Semua error loop muncul di panel Log (merah) dan Output Roblox.

## Kontrol

- `RightShift` — tampil/sembunyikan GUI (ubah di `Config.ToggleKey`)
- Tombol `—` minimize, `✕` tutup (semua loop ikut berhenti)
