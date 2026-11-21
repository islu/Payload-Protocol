# The itch.io Page

This file has the text and the settings of the itch.io page. Copy each part into the page editor. Update this file when the game changes.

## Upload Settings

| Field | Value |
| --- | --- |
| Kind of project | HTML |
| Upload | `build/payload-protocol-web-v<version>.zip` (`task zip:web`). `index.html` is at the top of the zip. |
| This file will be played in the browser | On |
| Viewport dimensions | 1280 × 720. The game scales the screen of 1920 × 1080 down. The descriptions tell the player to use fullscreen. |
| Mobile friendly | Off. The game needs a mouse. |
| Automatically start on page load | Off |
| Fullscreen button | On |
| SharedArrayBuffer support | Off. The web export has no thread support (`variant/thread_support=false`). |
| Release status | Released. The version stays 1.0.0 until Game Off ends. |
| Pricing | No payments, or Donate |
| Genre | Puzzle |
| Tags | puzzle, strategy, roguelite, space, pixel-art, godot, sci-fi, singleplayer, short, inventory-management |
| Made with | Godot |
| Accessibility | Interactive tutorial |
| Community | Comments |
| AI disclosure | The owner decides. The code and the text were written with the help of Claude. The art is from FreePixel. Scripts draw the icon and the images of `docs/itch/`. |
| Languages | English, Chinese (Traditional) |
| Inputs | Mouse, Keyboard |
| Average session | About half an hour |

## Images

| Image | Size | File |
| --- | --- | --- |
| Cover image | 630 × 500 | `docs/itch/cover.png` |
| Header image | 960 × 200, transparent | `docs/itch/header.png`. Set the title of the page to hidden. |
| Background image | 512 × 512 tile | `docs/itch/background.png`. Set it to repeat. |
| Social media image | 1200 × 630 | `docs/itch/social.png` |
| Favicon | 512 × 512 | `project/icon.png` |
| Wide cover | 1260 × 540 (21:9) | `docs/itch/wide_cover.png` |
| Logo | Transparent, horizontal | `docs/itch/logo.png`. It has a dark outline, so it is legible on white and on black. |
| Screenshots | 1920 × 1080. Upload them in this order. | `docs/screenshots/2_station.png`, `3_warp.png`, `4_report.png`, `5_event.png`, `6_run_end.png`, `1_title.png` |
| Icon of the page | 512 × 512 | `project/icon.png` |

`task art` draws each image of `docs/itch/` with `tools/art/make_cover.py`. The cover shows a FreePixel cargo ship whose hold explodes, with cells of 1x1 cargo that fly out. It shows no screenshot. The social media image and the wide cover use `2_station.png` and `3_warp.png`: after you replace a screenshot, run `task art` again. `2_station.png` is `shots/05a_station_hold.png`, and `3_warp.png` is the frame of the hits in the first shift (`shots/07_warp_04.png`). Take new screenshots with `task shots`. Copy the best ones into `docs/screenshots/`.

## Theme

The colors are the colors of the game (`project/scenes/common/palette.gd`).

| Field | Color | Palette |
| --- | --- | --- |
| Background | `#0B1020` | `BACKGROUND` |
| Background 2 | `#131A30` | `PANEL` |
| Text | `#D8E4FF` | `TEXT` |
| Link | `#5FD3FF` | `ACCENT` |
| Button | `#FFBA46` | `TITLE_AMBER` |
| Border | `#2A3A66` | `PANEL_LINE` |

Do not use `GOOD` (green) or `BAD` (red) on the page. In the game, they show a success and a loss.

## Short Description

Pack the hold. Survive the warp. A puzzle game about cargo that slides, breaks, and explodes.

## Description (English)

**Pack the hold. Survive the warp.**

You fly cargo between space stations. At each station, take contracts and pack the freight into your hold. Then launch: the ship warps, and every piece of cargo slides across the hold.

Crystals shatter. Fuel drums explode. Coolant leaks onto the electronics. The route above the hold shows each shift before you launch, so every disaster is one you could have seen coming.

**How to play**

- Take contracts. The hold is never big enough for all of them.
- Drag the freight into the grid. Right click or R rotates it.
- Launch. All cargo slides to a wall or to cargo that stopped. Heavy cargo hits hard.
- Intact freight pays at the arrival. Scrap stays in your hold.
- Pay the loan at the end of each leg. Three legs make a run.

**Features**

- A run of 20 to 30 minutes, with a short tutorial at the start.
- Freight that reacts: Fragile, Volatile, Fluid, Electronic, and Perishable.
- Clamps, Shock Sponges, Coolers, Shields, and a stasis bay to protect your cargo.
- VIP clients, long hauls, and the Black Market.
- Low Gravity, Heat Zones, meteors, and hull breaches.
- English and Traditional Chinese.

**Controls**: mouse to drag, right click or R to rotate, Ctrl+Z to undo, Space to speed up the warp, Esc to pause.

**Tip**: play in fullscreen for the best view. Click the fullscreen button at the bottom right of the game.

**Credits**: cargo and speaker art by FreePixel. Effects by pixelfx (Patch and Hugo Duprez, MIT). Sounds by Kenney (CC0). Music "Vintage Menu" by iamoneabe (CC0). Font jf open huninn by justfont (SIL OFL 1.1). Made with Godot 4.7.

## Description (繁體中文)

**裝好貨艙，撐過跳躍。**

你在太空站之間運送貨物。每到一站，接下合約，把貨物排進貨艙。然後出發：船一跳躍，每件貨物都會在艙裡滑動。

水晶會碎，燃料桶會爆炸，冷卻液會漏到電子貨物上。貨艙上方的航線會先列出每一段位移，所以每一場災難，你其實都看得到它要來。

**玩法**

- 接下合約。貨艙永遠裝不下全部。
- 把貨物拖進格子。按右鍵或 R 旋轉。
- 出發。所有貨物會滑到牆邊，或停在已經停下的貨物前。重的貨物撞得最兇。
- 完好的貨物在抵達時付款。廢鐵會留在你的貨艙裡。
- 每一期結束時要還款。三期就是一局。

**特色**

- 一局約 20 到 30 分鐘，開頭有簡短的教學。
- 會起反應的貨物：易碎、爆裂物、流體、電子、生鮮。
- 卡榫、緩衝海綿、冷藏機、護盾和靜滯艙，用來保護貨物。
- VIP 客戶、長程合約和黑市。
- 低重力、熱區、隕石和船殼破裂。
- 支援英文和繁體中文。

**操作**：滑鼠拖曳貨物，右鍵或 R 旋轉，Ctrl+Z 復原，Space 加速跳躍，Esc 暫停。

**提示**：建議全螢幕遊玩，畫面最清楚。請按遊戲右下角的全螢幕按鈕。

**感謝**：貨物與角色美術來自 FreePixel。特效來自 pixelfx（Patch 與 Hugo Duprez，MIT）。音效來自 Kenney（CC0）。音樂〈Vintage Menu〉作者 iamoneabe（CC0）。字型為 justfont 的 jf open 粉圓（SIL OFL 1.1）。使用 Godot 4.7 製作。
