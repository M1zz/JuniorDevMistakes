#!/usr/bin/env python3
"""App Store marketing screenshots: raw simulator captures → headline + device, rendered by headless Chrome.

Usage: python3 scripts/compose_screenshots.py [lang ...]        (all languages when none given)

  in   docs/screenshots/raw/{iphone,ipad}/<lang>/<scene>.png      (scripts/capture_screenshots.sh)
  out  docs/screenshots/marketing/<lang>/NN-<scene>.png           iPhone 1242x2688
       docs/screenshots/marketing/<lang>/NN-<scene>-ipad.png      iPad   2064x2752

Colours follow the app (AppTheme in ContentView.swift): deep indigo gradient, warm coral/peach accent.
In COPY, `\n` is the only allowed line break and `{word}` is drawn in the accent colour.
A headline that would need more lines than written, or overflow, stops the run - shorten the copy.
"""
import concurrent.futures, html, pathlib, re, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "marketing"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

SIZE = {"iphone": (1242, 2688), "ipad": (2064, 2752)}

# Store order. Each entry: (scene, headline, subtitle).
COPY = {
    "ko": [
        ("home", "같은 실수를\n{두 번} 하지 않게", "주니어 개발자가 자주 하는 실수 100가지"),
        ("detail", "상황부터 해법까지\n{한 장}에", "벌어지는 일, 하는 법, 성장 포인트를 한 번에"),
        ("list", "겪어 본 실수는\n{체크}하기", "10개 분야, 분야마다 10가지 실수"),
        ("retro", "질문에 답하며\n{회고}하기", "내 답이 회고 일지에 차곡차곡 쌓여요"),
        ("progress", "나의 성장을\n{한눈에}", "경험한 실수, 회고, 북마크를 숫자로"),
    ],
    "en": [
        ("home", "Never make the same\nmistake {twice}", "100 common junior developer mistakes"),
        ("detail", "The fix,\n{on one page}", "What goes wrong, what to do, and what you learn"),
        ("list", "{Check off} the ones\nyou've made", "10 categories with 10 mistakes each"),
        ("retro", "Reflect with\n{real questions}", "Your answers build a personal retro journal"),
        ("progress", "See your growth\n{at a glance}", "Mistakes covered, retros written, bookmarks saved"),
    ],
    "en-GB": [
        ("home", "Never make the same\nmistake {twice}", "100 common junior developer mistakes"),
        ("detail", "The fix,\n{on one page}", "What goes wrong, what to do, and what you learn"),
        ("list", "{Tick off} the ones\nyou've made", "10 categories with 10 mistakes each"),
        ("retro", "Reflect with\n{real questions}", "Your answers build a personal retro journal"),
        ("progress", "See your growth\n{at a glance}", "Mistakes covered, retros written, bookmarks saved"),
    ],
    "zh-Hans": [
        ("home", "同一个坑\n不踩{第二次}", "初级开发者最常踩的 100 个坑"),
        ("detail", "场景、做法、收获\n{一页}讲清", "会发生什么、该怎么做、能学到什么"),
        ("list", "踩过的坑\n{打个勾}", "10 大类，每类 10 个坑"),
        ("retro", "回答问题\n写{复盘}", "你的回答会汇成自己的复盘日志"),
        ("progress", "成长进度\n{一目了然}", "踩过的坑、复盘和收藏都有数"),
    ],
    "zh-Hant": [
        ("home", "同樣的雷\n不踩{第二次}", "新手工程師最常踩的 100 個雷"),
        ("detail", "情境、做法、收穫\n{一頁}看懂", "會發生什麼、該怎麼做、能學到什麼"),
        ("list", "踩過的雷\n{打個勾}", "10 大類，每類 10 個雷"),
        ("retro", "回答問題\n寫{回顧}", "你的回答會累積成自己的回顧日誌"),
        ("progress", "成長進度\n{一目了然}", "踩過的雷、回顧與書籤一次看"),
    ],
    "ja": [
        ("home", "同じ失敗を\n{二度と}しない", "新人エンジニアがやりがちなミス100"),
        ("detail", "状況・対策・学びを\n{1ページ}で", "何が起きて、どうすればよく、何が身につくか"),
        ("list", "やらかしたことは\n{チェック}", "10カテゴリ×10個のミス"),
        ("retro", "質問に答えて\n{ふりかえり}", "答えはそのまま自分のふりかえり日誌に"),
        ("progress", "成長が\n{ひと目で}わかる", "経験したミス、ふりかえり、ブックマークを数字で"),
    ],
    "ru": [
        ("home", "Не повторяйте\nошибку {дважды}", "100 типичных ошибок начинающих разработчиков"),
        ("detail", "Ситуация, решение\nи {урок}", "Что происходит, что делать и чему это учит"),
        ("list", "{Отмечайте}\nсвои ошибки", "10 разделов по 10 ошибок"),
        ("retro", "Подводите итоги\n{по вопросам}", "Ответы собираются в ваш дневник ретроспектив"),
        ("progress", "Ваш рост —\n{наглядно}", "Пройденные ошибки, записи и закладки в цифрах"),
    ],
    "es": [
        ("home", "No repitas el mismo\nerror {dos veces}", "Los 100 errores más comunes de un dev junior"),
        ("detail", "Qué pasa y qué hacer,\n{en una página}", "La situación, la solución y lo que aprendes"),
        ("list", "{Marca} los errores\nque ya cometiste", "10 categorías con 10 errores cada una"),
        ("retro", "Reflexiona con\n{buenas preguntas}", "Tus respuestas forman tu diario de reflexión"),
        ("progress", "Tu progreso,\n{de un vistazo}", "Errores vividos, reflexiones y marcadores"),
    ],
    "de": [
        ("home", "Denselben Fehler\n{nie zweimal}", "100 typische Fehler von Junior-Devs"),
        ("detail", "Problem und Lösung\n{auf einer Seite}", "Was passiert, was hilft und was du daraus lernst"),
        ("list", "{Abhaken}, was du\nschon erlebt hast", "10 Kategorien mit je 10 Fehlern"),
        ("retro", "Reflektieren mit\n{guten Fragen}", "Deine Antworten landen in deinem Rückblick-Journal"),
        ("progress", "Dein Fortschritt\n{auf einen Blick}", "Erlebte Fehler, Rückblicke und Lesezeichen"),
    ],
    "fr": [
        ("home", "Ne refaites jamais\nla même {erreur}", "Les 100 erreurs les plus courantes des devs juniors"),
        ("detail", "Le problème et la solution,\n{sur une page}", "Ce qui arrive, quoi faire et ce que vous en tirez"),
        ("list", "{Cochez} les erreurs\ndéjà vécues", "10 catégories de 10 erreurs"),
        ("retro", "Faites le point\n{avec les bonnes questions}", "Vos réponses forment votre journal de rétro"),
        ("progress", "Votre progression\n{en un coup d'œil}", "Erreurs vécues, rétros et favoris en chiffres"),
    ],
    "it": [
        ("home", "Mai più lo stesso\nerrore {due volte}", "I 100 errori più comuni degli sviluppatori junior"),
        ("detail", "Problema e soluzione\n{in una pagina}", "Cosa succede, cosa fare e cosa impari"),
        ("list", "{Spunta} gli errori\ngià commessi", "10 categorie da 10 errori ciascuna"),
        ("retro", "Rifletti con\n{le domande giuste}", "Le tue risposte diventano un diario personale"),
        ("progress", "I tuoi progressi\n{a colpo d'occhio}", "Errori vissuti, riflessioni e segnalibri"),
    ],
    "pt-BR": [
        ("home", "Nunca repita o mesmo\nerro {duas vezes}", "Os 100 erros mais comuns de devs júnior"),
        ("detail", "Problema e solução\n{numa página só}", "O que acontece, o que fazer e o que você aprende"),
        ("list", "{Marque} os erros\nque você já cometeu", "10 categorias com 10 erros cada"),
        ("retro", "Reflita com\n{as perguntas certas}", "Suas respostas viram seu diário de retrospectiva"),
        ("progress", "Seu progresso\n{num relance}", "Erros vividos, retrospectivas e favoritos"),
    ],
    "th": [
        ("home", "พลาดเรื่องเดิม\n{ไม่มีอีกแล้ว}", "100 ข้อผิดพลาดที่จูเนียร์เดฟเจอบ่อย"),
        ("detail", "ปัญหาและทางแก้\n{ครบในหน้าเดียว}", "เกิดอะไรขึ้น ควรทำอย่างไร และได้เรียนรู้อะไร"),
        ("list", "เคยพลาดข้อไหน\n{ติ๊กไว้เลย}", "10 หมวด หมวดละ 10 ข้อ"),
        ("retro", "ตอบคำถาม\nเพื่อ{ทบทวนตัวเอง}", "คำตอบของคุณกลายเป็นสมุดทบทวนส่วนตัว"),
        ("progress", "เห็นพัฒนาการ\n{ได้ในพริบตา}", "ข้อที่เคยพลาด การทบทวน และบุ๊กมาร์ก"),
    ],
    "vi": [
        ("home", "Đừng mắc cùng một lỗi\n{hai lần}", "100 sai lầm phổ biến của junior dev"),
        ("detail", "Vấn đề và cách xử lý\n{trong một trang}", "Chuyện gì xảy ra, nên làm gì, học được gì"),
        ("list", "{Đánh dấu} những lỗi\nbạn từng mắc", "10 nhóm, mỗi nhóm 10 sai lầm"),
        ("retro", "Nhìn lại bản thân\nqua {từng câu hỏi}", "Câu trả lời thành nhật ký nhìn lại của riêng bạn"),
        ("progress", "Tiến bộ của bạn\n{trong nháy mắt}", "Lỗi đã trải qua, bài nhìn lại và dấu trang"),
    ],
    "cs": [
        ("home", "Stejnou chybu\n{nikdy dvakrát}", "100 nejčastějších chyb juniorních vývojářů"),
        ("detail", "Problém a řešení\n{na jedné stránce}", "Co se stane, co dělat a co si z toho vzít"),
        ("list", "{Odškrtněte} chyby,\nkteré už znáte", "10 kategorií po 10 chybách"),
        ("retro", "Reflexe\n{s dobrými otázkami}", "Vaše odpovědi tvoří osobní deník reflexe"),
        ("progress", "Váš pokrok\n{na první pohled}", "Zažité chyby, reflexe a záložky v číslech"),
    ],
    "da": [
        ("home", "Lav aldrig samme\nfejl {to gange}", "De 100 mest almindelige fejl for juniorudviklere"),
        ("detail", "Problem og løsning\n{på én side}", "Hvad der sker, hvad du gør, og hvad du lærer"),
        ("list", "{Sæt flueben} ved\nde fejl, du har begået", "10 kategorier med 10 fejl i hver"),
        ("retro", "Reflektér med\n{de rigtige spørgsmål}", "Dine svar bliver til din egen refleksionsdagbog"),
        ("progress", "Dine fremskridt\n{samlet ét sted}", "Oplevede fejl, refleksioner og bogmærker"),
    ],
    "el": [
        ("home", "Μην κάνετε το ίδιο\nλάθος {δύο φορές}", "Τα 100 πιο συχνά λάθη των junior developers"),
        ("detail", "Πρόβλημα και λύση\n{σε μία σελίδα}", "Τι συμβαίνει, τι να κάνετε και τι μαθαίνετε"),
        ("list", "{Τσεκάρετε} τα λάθη\nπου έχετε κάνει", "10 κατηγορίες με 10 λάθη η καθεμία"),
        ("retro", "Αναστοχαστείτε με\n{τις σωστές ερωτήσεις}", "Οι απαντήσεις σας γίνονται ημερολόγιο ανασκόπησης"),
        ("progress", "Η πρόοδός σας\n{με μια ματιά}", "Λάθη, ανασκοπήσεις και σελιδοδείκτες σε αριθμούς"),
    ],
    "fi": [
        ("home", "Samaa virhettä\n{ei kahdesti}", "100 juniorikehittäjän yleisintä virhettä"),
        ("detail", "Ongelma ja ratkaisu\n{yhdellä sivulla}", "Mitä tapahtuu, mitä tehdä ja mitä opit"),
        ("list", "{Merkitse} virheet,\njotka olet tehnyt", "10 kategoriaa, kussakin 10 virhettä"),
        ("retro", "Pohdi\n{oikeilla kysymyksillä}", "Vastauksistasi syntyy oma pohdintapäiväkirja"),
        ("progress", "Edistymisesi\n{yhdellä silmäyksellä}", "Koetut virheet, pohdinnat ja kirjanmerkit"),
    ],
    "id": [
        ("home", "Jangan ulangi\nkesalahan {yang sama}", "100 kesalahan paling umum junior developer"),
        ("detail", "Masalah dan solusi\n{dalam satu halaman}", "Apa yang terjadi, harus bagaimana, dan pelajarannya"),
        ("list", "{Centang} kesalahan\nyang pernah kamu buat", "10 kategori, masing-masing 10 kesalahan"),
        ("retro", "Refleksi lewat\n{pertanyaan yang tepat}", "Jawabanmu jadi jurnal refleksi pribadi"),
        ("progress", "Lihat progresmu\n{sekilas}", "Kesalahan yang dialami, refleksi, dan bookmark"),
    ],
    "nb": [
        ("home", "Gjør aldri samme\nfeil {to ganger}", "De 100 vanligste feilene juniorutviklere gjør"),
        ("detail", "Problem og løsning\n{på én side}", "Hva som skjer, hva du gjør, og hva du lærer"),
        ("list", "{Kryss av} feilene\ndu har gjort", "10 kategorier med 10 feil i hver"),
        ("retro", "Reflekter med\n{de riktige spørsmålene}", "Svarene dine blir din egen refleksjonsdagbok"),
        ("progress", "Fremgangen din\n{samlet på ett sted}", "Opplevde feil, refleksjoner og bokmerker"),
    ],
    "nl": [
        ("home", "Maak nooit twee keer\n{dezelfde fout}", "De 100 meest gemaakte fouten van junior developers"),
        ("detail", "Probleem en oplossing\n{op één pagina}", "Wat er gebeurt, wat je doet en wat je leert"),
        ("list", "{Vink af} welke fouten\nje al maakte", "10 categorieën met elk 10 fouten"),
        ("retro", "Terugblikken met\n{de juiste vragen}", "Je antwoorden vormen je eigen terugblikdagboek"),
        ("progress", "Je voortgang\n{in één oogopslag}", "Gemaakte fouten, terugblikken en bladwijzers"),
    ],
    "pl": [
        ("home", "Nie popełniaj tego\nsamego błędu {dwa razy}", "100 najczęstszych błędów początkujących programistów"),
        ("detail", "Problem i rozwiązanie\n{na jednej stronie}", "Co się dzieje, co zrobić i czego się nauczysz"),
        ("list", "{Odhaczaj} błędy,\nktóre masz za sobą", "10 kategorii po 10 błędów"),
        ("retro", "Retrospektywa\n{z dobrymi pytaniami}", "Twoje odpowiedzi tworzą osobisty dziennik"),
        ("progress", "Twoje postępy\n{w jednym miejscu}", "Przeżyte błędy, retrospektywy i zakładki"),
    ],
    "sv": [
        ("home", "Gör aldrig samma\nmisstag {två gånger}", "De 100 vanligaste misstagen juniorutvecklare gör"),
        ("detail", "Problem och lösning\n{på en sida}", "Vad som händer, vad du gör och vad du lär dig"),
        ("list", "{Bocka av} misstagen\ndu redan gjort", "10 kategorier med 10 misstag i varje"),
        ("retro", "Reflektera med\n{rätt frågor}", "Dina svar blir din egen reflektionsdagbok"),
        ("progress", "Dina framsteg\n{på ett ställe}", "Upplevda misstag, reflektioner och bokmärken"),
    ],
    "tr": [
        ("home", "Aynı hatayı\n{iki kez} yapma", "Junior geliştiricilerin en sık yaptığı 100 hata"),
        ("detail", "Sorun ve çözüm\n{tek sayfada}", "Ne olur, ne yapmalı ve ne öğrenirsin"),
        ("list", "Yaptığın hataları\n{işaretle}", "Her biri 10 hatadan oluşan 10 kategori"),
        ("retro", "Doğru sorularla\n{geriye bak}", "Cevapların kişisel geri bakış günlüğüne dönüşür"),
        ("progress", "Gelişimini\n{tek bakışta} gör", "Yaşadığın hatalar, geri bakışlar ve yer imleri"),
    ],
}

# Shared with make_creative_assets.py so the header and search result look like the same app.
BASE_CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:%(W)dpx; height:%(H)dpx; overflow:hidden; }
body { position:relative;
  background: radial-gradient(ellipse at 85%% 0%%, rgba(255,158,122,.28), transparent 55%%),
              linear-gradient(160deg, #403985 0%%, #5a479e 55%%, #8059b8 100%%);
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", "Hiragino Sans", "PingFang SC", "Thonburi", sans-serif; }
.headline { font-weight:800; color:#ffffff; letter-spacing:-0.025em; line-height:1.14; }
.headline b { color:#ffb08f; font-weight:800; }
.eyebrow { font-weight:700; color:#ffb08f; letter-spacing:-0.005em; line-height:1.15; }
.sub { font-weight:500; color:#d9d3f2; letter-spacing:-0.01em; line-height:1.3; text-wrap:balance; }
:lang(ja) .headline, :lang(zh) .headline, :lang(th) .headline, :lang(th) .sub, :lang(th) .eyebrow { letter-spacing:0; }
:lang(th) .headline { line-height:1.32; }
:lang(ko) .headline, :lang(ko) .sub, :lang(ko) .eyebrow { word-break:keep-all; }
.device { position:absolute; background:#0d0b1c; border:solid #2b2650; box-shadow:0 50px 140px rgba(18,10,50,.55); }
.device img { width:100%%; display:block; }
"""

# Shrinks `.fit` text until it fits its box and keeps the line count written in the copy.
FIT_JS = """
<script>
function lines(el) {
  return Math.round(el.getBoundingClientRect().height / parseFloat(getComputedStyle(el).lineHeight));
}
function fit(box, el, max, min, want) {
  let size = max;
  el.style.fontSize = size + 'px';
  const bad = () => box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 || lines(el) > want;
  while (size > min && bad()) { size -= 2; el.style.fontSize = size + 'px'; }
  if (bad()) document.body.dataset.overflow = (document.body.dataset.overflow || '') + el.className + ' ';
}
document.fonts.ready.then(() => {
  for (const el of document.querySelectorAll('[data-max]')) {
    const want = +el.dataset.lines || el.querySelectorAll('br').length + 1;
    fit(el.closest('.box'), el, +el.dataset.max, +el.dataset.min, want);
  }
  document.body.dataset.done = '1';
});
</script>
"""


def rich(text):
    """'a {b}\\nc' → 'a <b>b</b><br>c'."""
    text = html.escape(text, quote=False).replace("\n", "<br>")
    return re.sub(r"\{(.*?)\}", r"<b>\1</b>", text)


def plain(text):
    return text.replace("{", "").replace("}", "")


def device(kind, img, left, top, width, rotate=0):
    """Phone or tablet frame around a raw capture; radii scale with the frame width."""
    bezel = width * (0.028 if kind == "iphone" else 0.022)
    screen_r = width * (0.135 if kind == "iphone" else 0.04)
    return (f'<div class="device" style="left:{left}px;top:{top}px;width:{width}px;padding:{bezel:.0f}px;'
            f'border-width:{bezel * 0.25:.0f}px;border-radius:{screen_r + bezel:.0f}px;transform:rotate({rotate}deg)">'
            f'<img src="{img}" style="border-radius:{screen_r:.0f}px"></div>')


def slide_html(lang, kind, index, scene, headline, sub):
    W, H = SIZE[kind]
    img = (RAW / kind / lang / f"{scene}.png").as_uri()
    margin = round(W * 0.075)
    top = round(H * (0.065 if kind == "iphone" else 0.05))
    box_h = round(H * 0.18)
    head_max = round(W * (0.098 if kind == "iphone" else 0.066))
    sub_size = round(W * (0.04 if kind == "iphone" else 0.027))
    dev_w = round(W * (0.8 if kind == "iphone" else 0.78))
    dev_top = top + box_h + round(H * 0.03)
    rotate = (0, -3, 0, 3, 0)[index % 5]
    return f"""
<div class="box" style="position:absolute;left:{margin}px;top:{top}px;width:{W - 2 * margin}px;height:{box_h}px;
     display:flex;flex-direction:column;align-items:center;justify-content:flex-start;text-align:center;overflow:hidden">
  <div class="headline" data-max="{head_max}" data-min="{round(head_max * 0.6)}">{rich(headline)}</div>
  <div class="sub" data-max="{sub_size}" data-min="{round(sub_size * 0.75)}" data-lines="2"
       style="margin-top:{round(sub_size * 0.7)}px">{html.escape(sub)}</div>
</div>
{device(kind, img, (W - dev_w) // 2, dev_top, dev_w, rotate)}"""


def render(page_body, W, H, lang, out_png):
    """Render with headless Chrome after the fit script has run; stop when copy does not fit."""
    page = (f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>'
            f'{BASE_CSS % {"W": W, "H": H}}</style></head><body>{page_body}{FIT_JS}</body></html>')
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(page)
        url = pathlib.Path(f.name).as_uri()
    flags = ["--headless=new", f"--window-size={W},{H}", "--force-device-scale-factor=1", "--disable-gpu",
             "--hide-scrollbars", "--virtual-time-budget=4000", "--allow-file-access-from-files"]
    flags.append(f"--user-data-dir={tempfile.mkdtemp(prefix='silsu100-chrome-')}")
    try:
        dom = subprocess.run([CHROME, *flags, "--dump-dom", url], capture_output=True, text=True, timeout=90).stdout
        if 'data-done="1"' not in dom:
            raise SystemExit(f"fit script did not finish: {out_png}")
        if "data-overflow" in dom:
            raise SystemExit(f"copy does not fit: {out_png} - shorten it")
        out_png.parent.mkdir(parents=True, exist_ok=True)
        for _ in range(3):
            r = subprocess.run([CHROME, *flags, f"--screenshot={out_png}", url], capture_output=True, timeout=90)
            if r.returncode == 0 and out_png.exists():
                break
        else:
            raise SystemExit(f"Chrome did not render {out_png}")
    finally:
        pathlib.Path(f.name).unlink(missing_ok=True)
    # Chrome screenshots are RGB already; strip any alpha to be safe (App Store rejects it).
    subprocess.run(["sips", "-s", "format", "png", "-s", "hasAlpha", "no", str(out_png)], capture_output=True)
    print(out_png.relative_to(ROOT))


def jobs(langs):
    for lang in langs:
        for kind in SIZE:
            for index, (scene, headline, sub) in enumerate(COPY[lang]):
                suffix = "" if kind == "iphone" else "-ipad"
                out = OUT / lang / f"{index + 1:02d}-{scene}{suffix}.png"
                yield slide_html(lang, kind, index, scene, headline, sub), *SIZE[kind], lang, out


if __name__ == "__main__":
    langs = sys.argv[1:] or list(COPY)
    unknown = [l for l in langs if l not in COPY]
    if unknown:
        raise SystemExit(f"unknown language: {unknown}")
    with concurrent.futures.ThreadPoolExecutor(4) as pool:
        for future in [pool.submit(render, *job) for job in jobs(langs)]:
            future.result()
