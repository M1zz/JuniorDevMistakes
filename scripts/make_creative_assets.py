#!/usr/bin/env python3
"""App Store product page header + search result images: HTML → headless Chrome.

Usage: python3 scripts/make_creative_assets.py [lang ...]       (all languages when none given)

  docs/screenshots/creative/<lang>/header.png   3840x1646  top of the product page
  docs/screenshots/creative/<lang>/search.png   3840x2560  search results

Device screens are the iPhone raw captures from scripts/capture_screenshots.sh.
Background, colours, fonts and the fit script come from compose_screenshots.py so all store images match.
The search image tells the same story as screenshot 1 (its headline and subtitle are reused).

Text stays inside Apple's safe areas (measured from the official PSD templates); outside it may be cropped.
No prices, discounts, URLs, awards or other platform names (Apple guideline).
"""
import html, pathlib, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import compose_screenshots as compose  # noqa: E402

RAW = compose.RAW / "iphone"
OUT = compose.ROOT / "docs" / "screenshots" / "creative"

# (width, height, safe area left, top, right, bottom)
SPEC = {
    "header": (3840, 1646, (1097, 493, 2743, 1154)),
    "search": (3840, 2560, (836, 765, 3004, 1795)),
}

# Header: one promise. Eyebrow is the app's short name in that store (APPSTORE.md).
HEADER = {
    "ko":      ("실수 100", "남이 겪은 실수로 배우고\n{더 빨리} 성장하세요"),
    "en":      ("100 Dev Mistakes", "Learn from their mistakes.\n{Grow faster.}"),
    "en-GB":   ("100 Dev Mistakes", "Learn from their mistakes.\n{Grow faster.}"),
    "zh-Hans": ("踩坑100", "别人踩过的坑\n帮你{成长更快}"),
    "zh-Hant": ("踩雷100", "別人踩過的雷\n讓你{成長更快}"),
    "ja":      ("やらかし100", "先輩たちの失敗から学んで\n{もっと速く}成長しよう"),
    "ru":      ("100 ошибок джуна", "Учитесь на чужих ошибках.\n{Растите быстрее.}"),
    "es":      ("100 Errores Dev", "Aprende de los errores ajenos.\n{Crece más rápido.}"),
    "de":      ("100 Dev-Fehler", "Aus fremden Fehlern lernen.\n{Schneller wachsen.}"),
    "fr":      ("100 Erreurs Dev", "Apprenez des erreurs des autres.\n{Progressez plus vite.}"),
    "it":      ("100 Errori Dev", "Impara dagli errori degli altri.\n{Cresci più in fretta.}"),
    "pt-BR":   ("100 Erros de Dev Júnior", "Aprenda com os erros dos outros.\n{Evolua mais rápido.}"),
    "th":      ("100 ข้อพลาด", "เรียนรู้จากความผิดพลาดของคนอื่น\n{โตได้เร็วกว่า}"),
    "vi":      ("100 Sai Lầm Junior Dev", "Học từ sai lầm của người khác,\n{tiến bộ nhanh hơn}"),
    "cs":      ("100 chyb", "Učte se z cizích chyb.\n{Rosťte rychleji.}"),
    "da":      ("100 Fejl", "Lær af andres fejl.\n{Voks hurtigere.}"),
    "el":      ("100 Λάθη", "Μάθετε από τα λάθη των άλλων.\n{Εξελιχθείτε πιο γρήγορα.}"),
    "fi":      ("100 virhettä", "Opi muiden virheistä.\n{Kehity nopeammin.}"),
    "id":      ("100 Kesalahan Junior Dev", "Belajar dari kesalahan orang lain.\n{Berkembang lebih cepat.}"),
    "nb":      ("100 feil", "Lær av andres feil.\n{Voks raskere.}"),
    "nl":      ("100 Fouten", "Leer van andermans fouten.\n{Groei sneller.}"),
    "pl":      ("100 błędów juniora", "Ucz się na cudzych błędach.\n{Rozwijaj się szybciej.}"),
    "sv":      ("100 Misstag", "Lär dig av andras misstag.\n{Väx snabbare.}"),
    "tr":      ("100 Hata", "Başkalarının hatalarından öğren.\n{Daha hızlı geliş.}"),
}

# Search result eyebrow: what people in that country type into the search field.
EYEBROW = {
    "ko": "주니어 개발자 성장", "en": "Junior developer tips", "en-GB": "Junior developer tips",
    "zh-Hans": "程序员成长", "zh-Hant": "工程師成長", "ja": "新人エンジニア",
    "ru": "Советы разработчику", "es": "Programador junior", "de": "Junior-Entwickler",
    "fr": "Développeur débutant", "it": "Sviluppatore junior", "pt-BR": "Programador júnior",
    "th": "โปรแกรมเมอร์มือใหม่", "vi": "Lập trình viên mới", "cs": "Junior programátor",
    "da": "Juniorudvikler", "el": "Προγραμματισμός", "fi": "Ohjelmointi aloittelijalle",
    "id": "Belajar coding", "nb": "Juniorutvikler", "nl": "Junior developer",
    "pl": "Początkujący programista", "sv": "Juniorutvecklare", "tr": "Junior yazılımcı",
}


def header_html(lang):
    W, H, (l, t, r, b) = SPEC["header"]
    eyebrow, headline = HEADER[lang]
    left = (RAW / lang / "detail.png").as_uri()
    right = (RAW / lang / "home.png").as_uri()
    return f"""
{compose.device("iphone", left, 250, 260, 700, -7)}
{compose.device("iphone", right, 2890, 260, 700, 7)}
<div class="box" style="position:absolute;left:{l}px;top:{t}px;width:{r - l}px;height:{b - t}px;
     display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;overflow:hidden">
  <div class="eyebrow" style="font-size:72px">{html.escape(eyebrow)}</div>
  <div class="headline" data-max="150" data-min="84" style="margin-top:24px">{compose.rich(headline)}</div>
</div>"""


def search_html(lang):
    W, H, (l, t, r, b) = SPEC["search"]
    scene, headline, sub = compose.COPY[lang][0]
    col = int((r - l) * 0.6)
    ph_w = 1000
    ph_left = l + col + 140
    img = (RAW / lang / f"{scene}.png").as_uri()
    return f"""
{compose.device("iphone", img, ph_left, t - 330, ph_w, 4)}
<div class="box" style="position:absolute;left:{l}px;top:{t}px;width:{col}px;height:{b - t}px;
     display:flex;flex-direction:column;justify-content:center;overflow:hidden">
  <div class="eyebrow" style="font-size:88px">{html.escape(EYEBROW[lang])}</div>
  <div class="headline" data-max="200" data-min="110" style="margin-top:32px">{compose.rich(headline)}</div>
  <div class="sub" data-max="76" data-min="56" data-lines="2" style="margin-top:44px">{html.escape(sub)}</div>
</div>"""


if __name__ == "__main__":
    langs = sys.argv[1:] or list(HEADER)
    unknown = [l for l in langs if l not in HEADER]
    if unknown:
        raise SystemExit(f"unknown language: {unknown}")
    for lang in langs:
        for kind, build in (("header", header_html), ("search", search_html)):
            W, H, _ = SPEC[kind]
            compose.render(build(lang), W, H, lang, OUT / lang / f"{kind}.png")
