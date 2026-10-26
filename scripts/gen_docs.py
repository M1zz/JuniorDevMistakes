#!/usr/bin/env python3
"""docs/<언어>/{index,privacy,support}.html 생성기.
문구: scripts/docs_i18n/<언어>.json (ko.json 이 원문). 사용: python3 scripts/gen_docs.py
"""
import json, os, re, html
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = 'https://m1zz.github.io/JuniorDevMistakes'
LANGS = [('ko','한국어'),('en','English'),('en-GB','English (UK)'),('zh-Hans','简体中文'),('zh-Hant','繁體中文'),
 ('ja','日本語'),('ru','Русский'),('es','Español'),('de','Deutsch'),('fr','Français'),('it','Italiano'),
 ('pt-BR','Português (Brasil)'),('th','ไทย'),('vi','Tiếng Việt'),('cs','Čeština'),('da','Dansk'),('el','Ελληνικά'),
 ('fi','Suomi'),('id','Bahasa Indonesia'),('nb','Norsk bokmål'),('nl','Nederlands'),('pl','Polski'),('sv','Svenska'),('tr','Türkçe')]
src = open(os.path.join(ROOT,'docs/index.html'),encoding='utf-8').read()
INDEX_CSS = re.search(r'<style>(.*?)</style>',src,re.S).group(1)
priv = open(os.path.join(ROOT,'docs/privacy.html'),encoding='utf-8').read()
DOC_CSS = re.search(r'<style>(.*?)</style>',priv,re.S).group(1)
EXTRA_CSS = """
    .langs { font-size: .8rem; color: rgba(240,238,252,.45); line-height: 2; }
    .langs a { color: rgba(240,238,252,.6); text-decoration: none; margin-right: 10px; white-space: nowrap; }
    .langs a:hover, .langs a.cur { color: #f0eefc; }
    .langs a.cur { font-weight: 700; }
    .doc-langs { max-width: 720px; margin: 64px auto 0; padding-top: 24px; border-top: 1px solid rgba(255,255,255,.08); }
    .foot-links a { margin-right: 14px; }
    .faq dt { font-weight: 700; margin: 24px 0 6px; color: #f0eefc; }
    .faq dd { color: rgba(240,238,252,.75); margin: 0; }
"""
E_ = html.escape
def t(d,k): return E_(d[k])
def alt_links(page):
    o = ''.join(f'  <link rel="alternate" hreflang="{c}" href="{BASE}/{c}/{page}" />\n' for c,_ in LANGS)
    return o + f'  <link rel="alternate" hreflang="x-default" href="{BASE}/en/{page}" />\n'
def lang_bar(lang,page):
    return '<div class="langs">' + ' '.join(
        f'<a href="../{c}/{page}" hreflang="{c}" lang="{c}"' + (' class="cur" aria-current="true"' if c==lang else '') + f'>{E_(n)}</a>'
        for c,n in LANGS) + '</div>'
APPLE_ICON = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>'
def btn(d,extra=''):
    return f'''<a href="#" class="btn-store">
    {APPLE_ICON.replace('<svg ','<svg '+extra,1) if extra else APPLE_ICON}
    <div>
      <span class="btn-store-sub">{t(d,'dl_on')}</span>
      <span class="btn-store-main">App Store</span>
    </div>
  </a>'''
def head(lang,title,desc,page,css):
    d = f'  <meta name="description" content="{E_(desc)}" />\n  <meta property="og:title" content="{E_(title)}" />\n  <meta property="og:description" content="{E_(desc)}" />\n  <meta property="og:type" content="website" />\n' if desc else ''
    return f'''<!DOCTYPE html>
<html lang="{lang}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{E_(title)}</title>
{d}{alt_links(page)}  <style>{css}</style>
</head>
'''
def logo(lang,d):
    return '실수<span>100</span>' if lang=='ko' else E_(d['brand'])
def index(lang,d):
    cats = ['⌨️','🐛','🌿','🏗️','🛡️','🧠','💬','🖥️','🔒','⚡']
    chips = '\n'.join(f'    <div class="cat-chip"><span>{cats[i]}</span> {t(d,"c%d"%(i+1))}</div>' for i in range(10))
    icons = [('rgba(63,56,132,.25)','✓'),('rgba(242,179,51,.2)','📓'),('rgba(56,199,140,.2)','📊'),('rgba(77,140,235,.2)','☁️'),('rgba(240,107,107,.2)','🔖'),('rgba(128,89,184,.2)','💻')]
    feats = '\n'.join(f'''    <div class="feature-card">
      <div class="feature-icon" style="background:{icons[i][0]}">{icons[i][1]}</div>
      <h3>{t(d,"f%d_t"%(i+1))}</h3>
      <p>{t(d,"f%d_p"%(i+1))}</p>
    </div>''' for i in range(6))
    li = lambda p,n: '\n'.join(f'        <li>{t(d,p+str(i))}</li>' for i in range(1,n+1))
    title = d['i_title']
    return head(lang,title,d['i_desc'],'index.html',INDEX_CSS+EXTRA_CSS) + f'''<body>

<nav>
  <div class="nav-logo">{logo(lang,d)}</div>
  <span><a href="support.html" class="nav-link">{t(d,'nav_support')}</a> &nbsp; <a href="privacy.html" class="nav-link">{t(d,'nav_privacy')}</a></span>
</nav>

<section class="hero">
  <div class="hero-badge">{t(d,'badge')}</div>
  <div class="app-icon">⌨️</div>
  <h1>{t(d,'h1_a')}<br><em>{t(d,'h1_em')}</em>{t(d,'h1_b')}</h1>
  <p class="hero-sub">
    {t(d,'hero_sub1')}<br>
    {t(d,'hero_sub2')}
  </p>
  {btn(d)}
</section>

<section>
  <p class="section-label">{t(d,'f_label')}</p>
  <h2>{t(d,'f_h2')}</h2>
  <p class="section-desc">{t(d,'f_desc')}</p>

  <div class="features-grid">
{feats}
  </div>
</section>

<section class="categories-section">
  <p class="section-label">{t(d,'c_label')}</p>
  <h2>{t(d,'c_h2')}</h2>
  <p class="section-desc">{t(d,'c_desc')}</p>

  <div class="categories-grid">
{chips}
  </div>
</section>

<section>
  <p class="section-label">{t(d,'pr_label')}</p>
  <h2>{t(d,'pr_h2')}</h2>
  <p class="section-desc">{t(d,'pr_desc')}</p>

  <div class="pricing-grid">
    <div class="price-card">
      <p class="price-plan">{t(d,'free_plan')}</p>
      <p class="price-amount">{t(d,'free_amount')}</p>
      <p class="price-period">{t(d,'free_period')}</p>
      <ul class="price-features">
{li('free_li',5)}
      </ul>
    </div>
    <div class="price-card featured">
      <div class="price-badge">BEST</div>
      <p class="price-plan">{t(d,'pro_m_plan')}</p>
      <p class="price-amount">{t(d,'pro_m_amount')}</p>
      <p class="price-period">{t(d,'pro_m_period')}</p>
      <ul class="price-features">
{li('pro_li',5)}
      </ul>
    </div>
    <div class="price-card">
      <p class="price-plan">{t(d,'pro_l_plan')}</p>
      <p class="price-amount">{t(d,'pro_l_amount')}</p>
      <p class="price-period">{t(d,'pro_l_period')}</p>
      <ul class="price-features">
{li('pro_li',5)}
      </ul>
    </div>
  </div>
</section>

<section class="sync-section" style="background:var(--surface); border-top:1px solid var(--border); border-bottom:1px solid var(--border);">
  <p class="section-label">{t(d,'s_label')}</p>
  <h2>{t(d,'s_h2')}</h2>
  <p class="section-desc">{t(d,'s_desc')}</p>
  <div class="devices">
    <div class="device-chip">📱 iPhone</div>
    <div class="device-chip">📲 iPad</div>
    <div class="device-chip">💻 Mac</div>
    <div class="device-chip">☁️ {t(d,'s_chip')}</div>
  </div>
</section>

<section class="cta-section">
  <h2>{t(d,'cta_h2')}</h2>
  <p>{t(d,'cta_p1')}<br>{t(d,'cta_p2')}</p>
  {btn(d,'style="width:22px;height:22px" ')}
</section>

<footer>
  <div>
    <p>© 2026 {t(d,'brand')}. All rights reserved.</p>
    <div style="margin-top:12px">{lang_bar(lang,'index.html')}</div>
  </div>
  <span class="foot-links"><a href="support.html">{t(d,'nav_support')}</a><a href="privacy.html">{t(d,'nav_privacy')}</a></span>
</footer>

</body>
</html>
'''
def doc_page(lang,d,page,title,body):
    return head(lang,title,'',page,DOC_CSS+EXTRA_CSS) + f'''<body>
<nav>
  <div class="nav-logo">{logo(lang,d)}</div>
  <a href="index.html">{t(d,'back_home')}</a>
</nav>

<div class="container">
{body}
</div>
<div class="doc-langs">{lang_bar(lang,page)}</div>
</body>
</html>
'''
def privacy(lang,d):
    ap = f'<a href="https://www.apple.com/legal/privacy/{"ko/" if lang=="ko" else ""}" target="_blank" rel="noopener">apple.com/legal/privacy</a>'
    li = lambda p,n: '\n'.join(f'    <li>{t(d,p+str(i))}</li>' for i in range(1,n+1))
    icloud = E_(d['p_icloud']).replace('{apple_link}',ap)
    body = f'''  <h1>{t(d,'p_title')}</h1>
  <p class="updated">{t(d,'p_updated')}</p>

  <p>{t(d,'p_intro')}</p>

  <h2>{t(d,'p_h1')}</h2>
  <p>{t(d,'p_collect_lead')}</p>
  <ul>
{li('p_collect_li',4)}
  </ul>
  <p>{t(d,'p_collect_sync')}</p>

  <h2>{t(d,'p_h2')}</h2>
  <ul>
{li('p_not_li',4)}
  </ul>

  <h2>{t(d,'p_h3')}</h2>
  <p>{t(d,'p_third')}</p>

  <h2>{t(d,'p_h4')}</h2>
  <p>{icloud}</p>

  <h2>{t(d,'p_h5')}</h2>
  <p>{t(d,'p_iap')}</p>

  <h2>{t(d,'p_h6')}</h2>
  <p>{t(d,'p_delete')}</p>

  <h2>{t(d,'p_h7')}</h2>
  <p>{t(d,'p_child')}</p>

  <h2>{t(d,'p_h8')}</h2>
  <p>{t(d,'p_change')}</p>

  <h2>{t(d,'p_h9')}</h2>
  <p>{t(d,'p_contact')}</p>'''
    return doc_page(lang,d,'privacy.html',f"{d['p_title']} — {d['brand']}",body)
def support(lang,d):
    faq = '\n'.join(f'    <dt>{t(d,"q%d"%i)}</dt>\n    <dd>{t(d,"a%d"%i)}</dd>' for i in range(1,6))
    body = f'''  <h1>{t(d,'su_title')}</h1>
  <p class="updated">{t(d,'brand')}</p>

  <p>{t(d,'su_intro')}</p>

  <h2>{t(d,'su_h_contact')}</h2>
  <p>{t(d,'su_contact')}</p>

  <h2>{t(d,'su_h_faq')}</h2>
  <dl class="faq">
{faq}
  </dl>

  <h2>{t(d,'su_h_docs')}</h2>
  <ul>
    <li><a href="privacy.html">{t(d,'p_title')}</a></li>
    <li><a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/" target="_blank" rel="noopener">{t(d,'su_eula')}</a></li>
  </ul>'''
    return doc_page(lang,d,'support.html',f"{d['su_title']} — {d['brand']}",body)
def main():
    for lang,_ in LANGS:
        p = os.path.join(ROOT,'scripts/docs_i18n',lang+'.json')
        if not os.path.exists(p): continue
        d = json.load(open(p,encoding='utf-8'))
        out = os.path.join(ROOT,'docs',lang); os.makedirs(out,exist_ok=True)
        for name,fn in (('index.html',index),('privacy.html',privacy),('support.html',support)):
            open(os.path.join(out,name),'w',encoding='utf-8').write(fn(lang,d))
        print('generated',lang)
if __name__=='__main__': main()
