# MarkViewer — Comprehensive Test Document

**English + Farsi · Lists · Tables · Code · GNOME**

This file is a **large, deliberate stress test** for MarkViewer. Open it with:

```bash
make run FILE=test-showcase.md
# or
./build/markviewer test-showcase.md
make debug FILE=test-showcase.md   # GTK Inspector
```

---

## Why MarkViewer Matters

MarkViewer is a **native GTK 4 markdown reader** for the Linux desktop. It does not embed Chromium, Electron, or a WebView. Every heading, paragraph, list, table, and code block is a real GTK widget.

That matters because:

1. **Performance** — no browser engine startup; small memory footprint; instant open for local `.md` files.
2. **Desktop integration** — follows GNOME / Libadwaita light and dark themes, system fonts, and window chrome.
3. **RTL correctness** — Persian and Arabic documents get proper direction, alignment, and mixed-script inline code.
4. **Privacy** — offline, local files only; no JavaScript runtime parsing your notes in a hidden engine.
5. **Hackability** — Vala + GTK source you can read, patch, and ship as a single binary.

If you maintain documentation in Markdown on Linux — project READMEs, Obsidian exports, class notes, API docs — MarkViewer is the **fast path from file path to readable window**.

---

## چرا MarkViewer مهم است؟

**مارک‌ویور** یک نمایشگر بومی مارک‌داون برای میزکار لینوکس است. برخلاف ابزارهای مبتنی بر مرورگر، همه‌چیز با **ویجت‌های GTK 4** رسم می‌شود.

دلایل اهمیت:

- **سرعت بالا** — بدون بارگذاری موتور وب؛ باز شدن فوری فایل‌های محلی.
- **یکپارچگی با GNOME** — تم روشن/تاریک، فونت سیستم، و ظاهر Libadwaita.
- **پشتیبانی RTL** — متن فارسی راست‌چین، کد انگلیسی چپ‌چین داخل پاراگراف.
- **حریم خصوصی** — فایل روی دیسک شما می‌ماند؛ بدون اجرای JavaScript.
- **قابل توسعه** — کد Vala شفاف برای دیباگ layout، فاصله‌ها، و جداول.

این سند عمداً **بزرگ و پرحجم** است تا بتوانید فاصله بین بلوک‌ها، لیست‌ها، جدول‌ها، و بلوک کد را در یک فایل واحد آزمایش کنید.

---

# GNOME and the Linux Desktop

## What is GNOME?

**GNOME** is a free and open-source desktop environment for Unix-like systems. It provides:

- A composited shell (Mutter)
- Core applications (Files, Terminal, Settings)
- **GTK** — the widget toolkit MarkViewer builds on
- **Libadwaita** — modern GNOME design patterns (header bars, clamped content, adaptive layout)

GNOME prioritizes **simplicity, accessibility, and consistent HIG** (Human Interface Guidelines). Applications that use GTK + Libadwaita feel at home on Fedora, Ubuntu (with extensions), Arch, and other distributions shipping GNOME.

## چرا GNOME برای MarkViewer مهم است؟

| موضوع | توضیح فارسی | English note |
|-------|-------------|--------------|
| تم سیستم | برنامه با تم روشن/تاریک میزکار هماهنگ می‌شود | Automatic light/dark via Libadwaita |
| فونت | پشته فونت فارسی در CSS تعریف شده | Vazirmatn, Shabnam, Noto Arabic stack |
| جهت متن | RTL برای پاراگراف فارسی | `set_direction(RTL)` on widgets |
| کد | بلوک کد همیشه LTR و مونواسپیس | Code blocks ignore RTL body direction |
| Inspector | `make debug` برای دیباگ layout | GTK Inspector ≈ DevTools for widgets |

## Why native beats embedded WebView (for reading)

> **English:** A WebView bundles HTML, CSS, JS, and a full layout engine. For *editing* rich apps that can be right. For *reading* a single markdown file on a fast machine, native widgets win on startup time, RAM, and predictable RTL behavior.
>
> **فارسی:** موتور وب برای خواندن یک فایل `.md` سنگین است. ویجت بومی همان نتیجه را با کنترل دقیق‌تر روی فاصله، جدول، و لیست می‌دهد.

---

## Headings (all six levels)

# Heading 1 — MarkViewer Test
## Heading 2 — GNOME Integration
### Heading 3 — Lists Below
#### Heading 4 — Tables Below
##### Heading 5 — Mixed Scripts
###### Heading 6 — End of Heading Block

### سرتیترهای فارسی

# سطح ۱ — آزمایش جامع
## سطح ۲ — لیست و جدول
### سطح ۳ — متن ترکیبی فارسی و English

---

## Paragraphs — English

MarkViewer parses **GitHub Flavored Markdown** through [cmark-gfm](https://github.com/github/cmark-gfm). Extensions enabled in this project include **tables**, **task lists**, **strikethrough**, **autolinks**, and **tag filter**.

Try inline code like `Gtk.Label`, `Adw.Clamp`, and `Cmark.parser_new()` inside an English sentence. Links work too: [GNOME GitLab](https://gitlab.gnome.org/GNOME) and autolink <https://gtk.org>.

~~Strikethrough~~ should render on this line.

---

## پاراگراف‌ها — فارسی

مارک‌ویور فایل‌های `.md` محلی را با **ویجت‌های GTK 4** نمایش می‌دهد — بدون موتور وب و بدون اجرای JavaScript روی محتوای شما.

برای باز کردن این سند آزمایشی از ترمینال استفاده کنید: `make run FILE=test-showcase.md`. برای دیباگ layout از `make debug` و GTK Inspector بهره ببرید.

متن فارسی باید **راست‌چین** باشد، در حالی که `inline code` و بلوک‌های کد همچنان **چپ‌چین** و مونواسپیس بمانند.

**پررنگ** و *مورب* و ***هر دو*** در یک جملهٔ فارسی با لینک به [cmark-gfm](https://github.com/github/cmark-gfm).

---

## Unordered lists (English)

- First item: native GTK rendering
- Second item: no WebView
- Third item with **bold** and `inline code`
  - Nested level A
  - Nested level B
    - Deep nested C
- Fourth item after nested block

---

## لیست گلوله‌ای — فارسی

- آیتم اول: راست‌چین با نقطهٔ گلوله
- آیتم دوم: فاصلهٔ کم بین نقطه و متن
- آیتم سوم با **پررنگ** و `کد_خطی`
  - زیرلیست سطح ۱
  - زیرلیست با متن طولانی‌تر که باید wrap شود و همچنان با گلوله هم‌تراز بماند
    - سطح عمیق‌تر
- آیتم پایانی لیست

---

## Ordered lists (English)

1. Clone the repository
2. Run `make build`
3. Open this file with `make run FILE=test-showcase.md`
4. Nested ordered sub-steps:
   1. Check list marker width
   2. Check paragraph alignment
   3. Verify code block LTR
5. Final ordered item

---

## لیست شماره‌دار — فارسی (ارقام لاتین)

1. نصب وابستگی‌ها روی آرچ
2. اجرای `meson setup build`
3. کامپایل با `ninja -C build`
4. زیرمرحله‌ها:
   1. بررسی RTL
   2. بررسی جدول
   3. بررسی بلوک کد
5. پایان لیست

---

## لیست شماره‌دار — ارقام فارسی/عربی (preprocessor)

۱. این آیتم با رقم فارسی ۱ شروع می‌شود
۲. آیتم دوم برای تست نرمال‌سازی preprocessor
۳. آیتم سوم با متن **مهم**
۴. زیرلیست:
   ۱. زیرآیتم الف
   ۲. زیرآیتم ب
۵. پایان

---

## Task lists (GFM)

- [x] Build MarkViewer with Meson
- [x] Load `assets/markviewer.css`
- [x] RTL paragraphs align right
- [ ] Perfect every edge case on first try
- [ ] Ship to Flathub (future)
- [x] Nested tasks:
  - [x] Tables render cell text
  - [ ] Table column auto-width polish
  - [x] Code blocks selectable

### تسک‌لیست فارسی

- [x] نمایش صحیح متن راست‌چین
- [x] جدول با ستون فارسی و انگلیسی
- [ ] بهینه‌سازی فاصلهٔ بین بلوک‌ها
- [x] `make debug` برای GTK Inspector

---

## Mixed list — English marker, Farsi content

1. Install `gtk4` and `libadwaita`
2. فونت فارسی باید خوانا باشد
3. Run `./build/markviewer test-showcase.md`
4. جدول و کد را در همین فایل ببین
5. Done

---

## Blockquotes

> English blockquote: MarkViewer is optimized for **reading**, not editing. One file, one window, native widgets.
>
> Second paragraph inside the same quote.

> **فارسی:** این یک blockquote راست‌چین است. باید حاشیه در سمت راست دیده شود، نه چپ.
>
> پاراگراف دوم داخل نقل‌قول با `کد` و **تاکید**.

---

## Code blocks

### English — directory tree (LTR, monospace)

```
project/
├── src/
│   ├── main.vala
│   ├── window.vala
│   └── markdown_renderer.vala
├── assets/
│   └── markviewer.css
├── docs/
│   └── overview.md
└── test-showcase.md    ← you are here
```

### فارسی + tree — mixed (must stay LTR inside block)

```
notes/
├── projects/
│   ├── markviewer/   ← مارک‌ویور
│   ├── docs/         ← مستندات
│   └── drafts/       ← پیش‌نویس
├── archive/
│   └── 2026/
└── README.md
```

### Short shell session

```bash
cd markviewer
make build
make run FILE=test-showcase.md
GTK_DEBUG=inspector ./build/markviewer test-showcase.md
```

---

## Tables — simple (English)

| Component | Role |
|-----------|------|
| cmark-gfm | Parse GFM AST |
| Vala | Application language |
| GTK 4 | Widget rendering |
| Libadwaita | GNOME shell patterns |

---

## Tables — alignment (GFM)

| Left | Center | Right |
|:-----|:------:|------:|
| L1 | C1 | 100 |
| Longer left cell text | C2 | 2500 |
| `code` | **bold** | 3.14 |

---

## Tables — Persian headers and mixed content

| بخش | توضیح | وضعیت |
|-----|-------|-------|
| `markdown_renderer` | تبدیل AST به ویجت GTK | پایدار |
| `markdown_preprocessor` | نرمال‌سازی ارقام و ریاضی | پایدار |
| `math_widget` | نمایش منبع LaTeX (بدون موتور وب) | پایدار |
| `font_config` | بارگذاری فونت Shabnam | پایدار |

---

## Tables — wide (horizontal scroll test)

| Module | File | Lines (approx) | Notes |
|--------|------|----------------|-------|
| Window | `src/window.vala` | 120 | Adw.Clamp, stylesheet |
| Renderer | `src/markdown_renderer.vala` | 560+ | AST → widgets, RTL |
| Preprocessor | `src/markdown_preprocessor.vala` | 80 | Persian digits, blockquotes |
| Tree dumper | `src/tree_dumper.vala` | 200 | YAML AST export |
| Styles | `assets/markviewer.css` | 175 | GTK-safe CSS only |

---

## Tables — links and inline markup inside cells

| Feature | Example | Works? |
|---------|---------|--------|
| Link | [README](README.md) | yes |
| Autolink | <https://gitlab.gnome.org> | yes |
| Bold | **important** | yes |
| Code | `hexpand = true` | yes |
| Strikethrough | ~~old~~ | in paragraphs |
| Farsi | **پشتیبانی فارسی** | yes |

---

## Tables — numeric and punctuation

| Year | Project | LOC | License |
|------|---------|-----|---------|
| 2024 | GTK 4 apps surge | — | LGPL |
| 2025 | Libadwaita 1.5+ | — | LGPL |
| 2026 | MarkViewer test doc | 500+ | check repo |

---

## Long English section (spacing stress test)

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

Second paragraph immediately after — gap between paragraphs should feel tight, like a good markdown reader, not like a slideshow with huge margins.

Third paragraph with a list inline reference: see unordered lists above. And a table reference: see Persian headers table.

---

## بخش بلند فارسی (فشار به فاصله و RTL)

لورم ایپسوم متن ساختگی است که برای پر کردن فضا در این سند آزمایشی استفاده شده است. هدف این است که چند پاراگراف پشت‌سرهم راست‌چین نمایش داده شوند و فاصلهٔ بین آن‌ها طبیعی باشد.

پاراگراف دوم: اگر فاصله‌ها هنوز زیاد است، کلاس‌های `md-block` و `.md-list-item` در CSS و renderer را در GTK Inspector بررسی کن.

پاراگراف سوم با لینک: [مستندات پروژه](docs/README.md) و کد `make debug FILE=test-showcase.md`.

---

## Nested structures combined

1. Ordered outer
   - Unordered inner with `code`
   - Inner item two
2. Outer with quote:
   > Quote inside list item — English
3. Outer with table:

| Col A | Col B |
|-------|-------|
| 1 | 2 |

4. Outer with code:

```
nested code line 1
nested code line 2
```

5. Final outer item — **فارسی** و English mixed

---

## Mathematics (LaTeX source)

MarkViewer recognizes **GitHub-style math delimiters** and shows the LaTeX source in monospace. Formulas are not typeset.

### Inline math

- Einstein: $E = mc^2$
- Pythagoras: $a^2 + b^2 = c^2$
- Persian context: معادلهٔ خطی $y = mx + b$ در صفحهٔ مختصات
- Greek letters: $\alpha + \beta = \gamma$
- Subscripts and superscripts: $x_i^2 + x_{i+1}^2$

### Block math (display mode)

$$
\int_0^1 x^2 \, dx = \frac{1}{3}
$$

$$
\left( \sum_{k=1}^{n} a_k b_k \right)^2 \leq
\left( \sum_{k=1}^{n} a_k^2 \right)
\left( \sum_{k=1}^{n} b_k^2 \right)
$$

Matrix example:

$$
\begin{bmatrix}
1 & 2 & 3 \\
4 & 5 & 6 \\
7 & 8 & 9
\end{bmatrix}
$$

Alternate block delimiters:

\[
\nabla \times \vec{\mathbf{B}} -\, \frac{1}{c}\, \frac{\partial\vec{\mathbf{E}}}{\partial t} = \frac{4\pi}{c}\vec{\mathbf{j}}
\]

### Math in tables

| Formula | Name | فارسی |
|---------|------|-------|
| $A = \pi r^2$ | Circle area | مساحت دایره |
| $e^{i\pi} + 1 = 0$ | Euler identity | اتحاد اویلر |
| $\displaystyle \sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}$ | Basel problem | مسئلهٔ بازل |

### Math in lists

1. Quadratic formula: $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$
2. Block inside list item:

   $$
   \lim_{n \to \infty} \left(1 + \frac{1}{n}\right)^n = e
   $$

3. فارسی: مساحت سطح کره $A = 4\pi r^2$

### Math must not break in code

Inline code keeps literal dollars: `$E=mc^2$` should appear as raw text, not rendered math.

```
# Raw LaTeX in fenced code — not rendered
$$ \int_0^1 f(x)\,dx $$
```

---

## Horizontal rules

Content above rule one.

---

Content between rules.

***

Content below rule two.

---

## Links collection

- [MarkViewer README](README.md)
- [cmark-gfm](https://github.com/github/cmark-gfm)
- [Libadwaita](https://gitlab.gnome.org/GNOME/libadwaita)
- [GTK 4 docs](https://docs.gtk.org/gtk4/)
- Autolink: <https://wiki.gnome.org>

---

## Closing — English

You have reached the end of this showcase. If headings, lists, tables, code blocks, blockquotes, and mixed Farsi/English paragraphs all look correct, MarkViewer is doing its job as a **native GNOME markdown reader**.

Report layout bugs with `make debug`, inspect widget classes (`md-list-item`, `md-table-cell`, `md-code-wrap`), and iterate on `assets/markviewer.css` plus `src/markdown_renderer.vala`.

---

## پایان — فارسی

به انتهای سند آزمایشی رسیدید. اگر لیست‌ها فشرده‌اند، گلوله با خط هم‌تراز است، جدول‌ها پر شده‌اند، و بلوک کد چپ‌چین مانده است، مارک‌ویور برای مطالعهٔ روزانهٔ یادداشت‌های مارک‌داون روی لینوکس آماده است.

**موفق باشید — happy testing on GNOME.**