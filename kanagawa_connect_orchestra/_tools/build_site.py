"""かながわコネクトオーケストラ サイト生成スクリプト

全ページ共通のヘッダー・フッター・head（SEO/OGP）と各ページ本文をここで一元管理し、
HTML と sitemap.xml を出力します。

使い方（kanagawa_connect_orchestra フォルダで実行）:
    python _tools/build_site.py

※ このスクリプトを実行すると HTML は上書きされます。
   HTML を直接編集した場合は、同じ内容をこのスクリプトにも反映してください。
"""
import json
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent  # kanagawa_connect_orchestra/
BASE = "https://kanagawa-connect-orchestra.web.app"
SITE = "かながわコネクトオーケストラ"
CONCEPT = "すべてのひとのためのオーケストラ"
PHILOSOPHY = "音楽を通して、ともに成長する"
FORM = "https://docs.google.com/forms/d/e/1FAIpQLSeNVFDq4rLClPT58n83vJLcjM70ODNXvUeHCRUNjm0TzqEUAA/viewform?usp=sharing&amp;ouid=104860576931330456926"
INSTAGRAM = "https://www.instagram.com/for.all.people_orch.kanagawa/"
INSTAGRAM_ID = "@for.all.people_orch.kanagawa"
MAIL = "kanagawaorchestra2026renraku@gmail.com"
PDF = "docs/recruitment-guidelines.pdf"
LASTMOD = "2026-10-04"

NAV = [
    ("index.html", "ホーム"),
    ("about.html", "私たちについて"),
    ("recruit.html", "団員募集"),
    ("concert.html", "第1回演奏会"),
    ("activity.html", "活動について"),
    ("contact.html", "お問い合わせ"),
]

NEW_TAB = '<span class="visually-hidden">（新しいタブで開きます）</span>'
ICON_EXT = '<svg class="icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M14 4h6v6M20 4l-9 9M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"/></svg>'
ICON_DL = '<svg class="icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>'
ICON_IG = '<svg class="icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4.2"/><circle cx="17.3" cy="6.7" r="0.6"/></svg>'
ICON_MAIL = '<svg class="icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3.5 6.5 12 13l8.5-6.5"/></svg>'


def href(page, root=""):
    if page == "index.html":
        return root + "./" if not root else root
    return root + page


# ---------------------------------------------------------------- parts

def btn_form(variant="primary", label="参加希望フォームへ"):
    return (f'<a class="btn btn--{variant}" href="{FORM}" target="_blank" rel="noopener noreferrer">'
            f'{label}{ICON_EXT}<span class="visually-hidden">（Googleフォーム・新しいタブで開きます）</span></a>')


def btn(page_href, label, variant="outline"):
    return f'<a class="btn btn--{variant}" href="{page_href}">{label}</a>'


def btn_pdf(variant="outline"):
    return f'<a class="btn btn--{variant}" href="{PDF}" download>{ICON_DL}募集要項（PDF）をダウンロード</a>'


def title(en, id_, ja):
    return f'''        <div class="section-title">
          <span class="section-title__en" aria-hidden="true">{en}</span>
          <h2 id="{id_}">{ja}</h2>
        </div>'''


def pending(text):
    return f'<span class="status status--tbd">{text}</span>'


def planned(text="予定"):
    return f'<span class="badge badge--planned">{text}</span>'


def row(dt, dd):
    return f'          <div class="info-list__row"><dt>{dt}</dt><dd>{dd}</dd></div>'


def card(h, body, extra=""):
    return f'''          <div class="card{extra}">
            <h3 class="card__title">{h}</h3>
            {body}
          </div>'''


def details(summary, body):
    return f'''          <details>
            <summary>{summary}</summary>
            <div class="accordion__body">{body}</div>
          </details>'''


def section(cls, id_, inner, narrow=True):
    container = "container container--narrow" if narrow else "container"
    return f'''    <section class="section{(' ' + cls) if cls else ''}" aria-labelledby="{id_}">
      <div class="{container}">
{inner}
      </div>
    </section>
'''


STAGES = '''        <ul class="stages">
          <li>「ちょっと興味がある」</li>
          <li>「まだ参加は決めていない」</li>
          <li>「詳しい話を聞いてみたい」</li>
        </ul>'''


def cta_band(heading="一緒に、オーケストラをつくりませんか。", text=None):
    text = text or "「ちょっと興味がある」「詳しい話を聞いてみたい」という段階でも、<br>参加希望フォームから気軽にご連絡ください。"
    return f'''    <section class="section section--navy cta-band" aria-labelledby="cta-title">
      <div class="container container--narrow">
{title("Join us", "cta-title", heading)}
        <p>{text}</p>
        <div class="btn-group btn-group--center">
          {btn_form("gold")}
          {btn("recruit.html", "団員募集の詳細を見る", "outline-light")}
        </div>
      </div>
    </section>
'''


def page_header(en, ja, lead=None):
    lead_html = f'\n        <p class="page-header__lead">{lead}</p>' if lead else ""
    return f'''    <div class="page-header">
      <div class="container">
        <span class="page-header__en" aria-hidden="true">{en}</span>
        <h1 class="page-header__title">{ja}</h1>{lead_html}
      </div>
    </div>
    <nav class="breadcrumb container" aria-label="パンくずリスト">
      <ol>
        <li><a href="./">ホーム</a></li>
        <li><span aria-current="page">{ja}</span></li>
      </ol>
    </nav>
'''


# ---------------------------------------------------------------- layout

def header(current, root=""):
    items = []
    for page, ja in NAV:
        cur = ' aria-current="page"' if page == current else ""
        items.append(f'          <li><a href="{href(page, root)}"{cur}>{ja}</a></li>')
    items = "\n".join(items)
    return f'''  <a class="skip-link" href="#main">本文へスキップ</a>
  <header class="site-header">
    <div class="container site-header__inner">
      <a class="site-logo" href="{href("index.html", root)}">
        <img class="site-logo__mark" src="{root}images/logo-160.png" width="40" height="40" alt="">
        <span>{SITE}</span>
      </a>
      <button class="nav-toggle" type="button" aria-expanded="false" aria-controls="global-nav">
        <span class="visually-hidden" data-nav-label>メニューを開く</span>
        <span class="nav-toggle__bar" aria-hidden="true"></span>
        <span class="nav-toggle__bar" aria-hidden="true"></span>
        <span class="nav-toggle__bar" aria-hidden="true"></span>
      </button>
      <nav class="global-nav" id="global-nav" aria-label="メインメニュー">
        <ul class="global-nav__list">
{items}
        </ul>
      </nav>
    </div>
  </header>
'''


def footer(root=""):
    items = "\n".join(f'          <li><a href="{href(p, root)}">{ja}</a></li>' for p, ja in NAV)
    return f'''  <footer class="site-footer">
    <div class="container">
      <div class="site-footer__top">
        <div class="site-footer__brand-block">
          <a class="site-footer__brand" href="{href("index.html", root)}">
            <img src="{root}images/logo-160.png" width="44" height="44" alt="">
            <span>{SITE}</span>
          </a>
          <p class="site-footer__concept">{CONCEPT}</p>
          <p class="site-footer__desc">学生を中心に活動する、年齢・経験を問わないオーケストラです。</p>
        </div>
        <nav class="footer-nav" aria-label="フッターメニュー">
          <ul>
{items}
          </ul>
        </nav>
      </div>
      <div class="site-footer__links">
        <a class="site-footer__join" href="{href("recruit.html", root)}">団員募集中｜詳しくはこちら</a>
        <a class="site-footer__sns" href="{INSTAGRAM}" target="_blank" rel="noopener noreferrer">{ICON_IG}<span>Instagram</span>{NEW_TAB}</a>
      </div>
      <p class="site-footer__copy"><small>&copy; <span data-year>2026</span> {SITE}</small></p>
    </div>
  </footer>
'''


def doc(filename, page_title, desc, body, jsonld, root="", noindex=False):
    full_title = f"{SITE}｜{CONCEPT}" if filename == "index.html" else f"{page_title}｜{SITE}"
    url = f"{BASE}/" if filename == "index.html" else f"{BASE}/{filename}"
    robots = '\n  <meta name="robots" content="noindex">' if noindex else ""
    canonical = "" if noindex else f'\n  <link rel="canonical" href="{url}">'
    ld = ""
    if jsonld:
        ld = '\n  <script type="application/ld+json">\n' + json.dumps(jsonld, ensure_ascii=False, indent=2) + "\n  </script>"
    return f'''<!DOCTYPE html>
<html lang="ja" class="no-js">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{full_title}</title>
  <meta name="description" content="{desc}">{canonical}{robots}
  <meta name="theme-color" content="#1c2a48">

  <!-- OGP / SNS -->
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="{SITE}">
  <meta property="og:title" content="{full_title}">
  <meta property="og:description" content="{desc}">
  <meta property="og:url" content="{url}">
  <meta property="og:image" content="{BASE}/images/ogp.png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="{SITE}｜{CONCEPT}">
  <meta property="og:locale" content="ja_JP">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{full_title}">
  <meta name="twitter:description" content="{desc}">
  <meta name="twitter:image" content="{BASE}/images/ogp.png">

  <!-- Favicon -->
  <link rel="icon" href="{root}favicon/favicon.ico" sizes="48x48">
  <link rel="icon" href="{root}favicon/icon-192.png" type="image/png" sizes="192x192">
  <link rel="apple-touch-icon" href="{root}favicon/apple-touch-icon.png">
  <link rel="manifest" href="{root}favicon/site.webmanifest">

  <!-- Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@500&amp;family=Noto+Sans+JP:wght@400;700&amp;family=Noto+Serif+JP:wght@500;600&amp;display=swap">

  <link rel="stylesheet" href="{root}css/style.css">
  <script src="{root}js/main.js" defer></script>{ld}
</head>
<body>
{header(filename, root)}
  <main id="main" tabindex="-1">
{body}  </main>

{footer(root)}</body>
</html>
'''


def breadcrumb_ld(name, filename):
    return {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "ホーム", "item": f"{BASE}/"},
            {"@type": "ListItem", "position": 2, "name": name, "item": f"{BASE}/{filename}"},
        ],
    }


ORG_LD = [
    {
        "@context": "https://schema.org",
        "@type": "MusicGroup",
        "@id": f"{BASE}/#organization",
        "name": SITE,
        "alternateName": "Kanagawa Connect Orchestra",
        "slogan": CONCEPT,
        "description": "学生を中心に活動する、年齢・経験を問わないオーケストラ。神奈川県を中心に活動予定。",
        "url": f"{BASE}/",
        "logo": f"{BASE}/images/logo.png",
        "image": f"{BASE}/images/ogp.png",
        "genre": "Classical",
        "areaServed": {"@type": "AdministrativeArea", "name": "神奈川県"},
        "email": MAIL,
        "sameAs": [INSTAGRAM],
    },
    {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "@id": f"{BASE}/#website",
        "name": SITE,
        "url": f"{BASE}/",
        "inLanguage": "ja",
        "publisher": {"@id": f"{BASE}/#organization"},
    },
]

# ================================================================ HOME
INSTR_SHORT = "弦楽器・木管楽器・金管楽器・打楽器"

index_body = f'''    <section class="hero" aria-labelledby="hero-title">
      <svg class="hero__lines" viewBox="0 0 1200 120" preserveAspectRatio="none" aria-hidden="true" focusable="false">
        <path d="M0 40 C200 10 400 70 600 40 S1000 10 1200 40"/>
        <path d="M0 60 C200 30 400 90 600 60 S1000 30 1200 60"/>
        <path d="M0 80 C200 50 400 110 600 80 S1000 50 1200 80"/>
      </svg>
      <div class="container hero__inner">
        <img class="hero__logo" src="images/logo.png" width="96" height="96" alt="">
        <p class="hero__name">{SITE}</p>
        <h1 class="hero__title" id="hero-title"><span>すべてのひとの</span><span>ための</span><span>オーケストラ</span></h1>
        <p class="hero__lead">{PHILOSOPHY}</p>
        <p class="hero__desc">学生を中心に活動する、年齢・経験を問わないオーケストラです。<br class="u-pc">神奈川県を中心に、2026年12月頃から活動を始める予定です。</p>
        <p class="hero__status"><span class="badge badge--gold">団員募集中</span><span>{INSTR_SHORT}</span></p>
        <div class="btn-group btn-group--center">
          {btn("recruit.html", "団員募集を見る", "primary")}
          {btn_form("outline")}
        </div>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="about-title">
      <div class="container container--narrow reveal">
{title("About", "about-title", "私たちについて")}
        <p class="lead">私たちは、音楽を通して<br>人と人がつながる場所をつくります。</p>
        <ul class="concept-lines">
          <li>人と人がつながり、</li>
          <li>音と音がつながり、</li>
          <li>みんなの音楽になる。</li>
        </ul>
        <p class="text-center">学校や年齢、経験の垣根を越えて集まり、<br class="u-pc">一人ひとりの音を大切にしながら、みんなでオーケストラをつくっていきます。</p>
        <div class="section-more">
          {btn("about.html", "私たちについて詳しく")}
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="both-title">
      <div class="container reveal">
{title("For everyone", "both-title", "初心者も、経験者も。")}
        <p class="lead">それぞれの経験を持ち寄って、<br>一緒に音楽をつくる。</p>
        <div class="grid-2">
          <div class="card card--audience">
            <p class="card__eyebrow">はじめての方へ</p>
            <h3 class="card__title">初めてでも、参加できます</h3>
            <p>オーケストラの経験がなくても大丈夫です。それぞれの経験や技術に合わせて、できることから一緒に取り組みます。失敗を恐れずに挑戦できる環境を目指しています。</p>
          </div>
          <div class="card card--audience">
            <p class="card__eyebrow">経験者の方へ</p>
            <h3 class="card__title">本気で、音楽をつくれます</h3>
            <p>第1回演奏会では、ドヴォルザークの交響曲第7番に挑戦します。指揮者や一部の人だけでなく、一人ひとりが「この曲で何を表現したいか」を考えながら、質の高い音楽を目指します。</p>
          </div>
        </div>
      </div>
    </section>

    <section class="section section--navy concert-feature" aria-labelledby="concert-title">
      <div class="container container--narrow reveal">
{title("The 1st Concert", "concert-title", "第1回演奏会")}
        <p class="concert-feature__lead">学生が中心となって、<br>ドヴォルザークの交響曲第7番に挑戦します。</p>
        <div class="concert-feature__program">
          <p class="concert-feature__tag">Main Program</p>
          <p class="concert-feature__composer" lang="cs">Antonín Dvořák</p>
          <p class="concert-feature__work" lang="en">Symphony No. 7</p>
          <p class="concert-feature__ja">ドヴォルザーク：交響曲第7番 ニ短調 作品70</p>
        </div>
        <p>メインプログラムとして予定しています。そのほか、オープニング・メイン前の作品・アンコールを予定しており、曲目は決定次第お知らせします。</p>
        <p class="small muted">開催日・会場は決定次第お知らせします。</p>
        <div class="section-more">
          {btn("concert.html", "第1回演奏会について", "outline-light")}
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="values-title">
      <div class="container reveal">
{title("Values", "values-title", "大切にしていること")}
        <ul class="values">
          <li class="value-card"><span class="value-card__num" aria-hidden="true">01</span><div><h3 class="value-card__title">経験を持ち寄る</h3><p class="value-card__text">初めての方も、経験を積んできた方も。互いに学び合い、一緒に成長します。</p></div></li>
          <li class="value-card"><span class="value-card__num" aria-hidden="true">02</span><div><h3 class="value-card__title">年齢・経験・所属を問わない</h3><p class="value-card__text">学校や団体の垣根を越えて、音楽をつくりたい気持ちでつながります。</p></div></li>
          <li class="value-card"><span class="value-card__num" aria-hidden="true">03</span><div><h3 class="value-card__title">失敗しても挑戦できる</h3><p class="value-card__text">うまくいかないことも成長の一部。安心して挑戦できる場所を目指します。</p></div></li>
          <li class="value-card"><span class="value-card__num" aria-hidden="true">04</span><div><h3 class="value-card__title">お互いを尊重する</h3><p class="value-card__text">年上だから、経験が長いから偉い、という考え方はしません。誰でも対等に意見を言えるオーケストラに。</p></div></li>
          <li class="value-card"><span class="value-card__num" aria-hidden="true">05</span><div><h3 class="value-card__title">みんなで音楽をつくる</h3><p class="value-card__text">誰か一人のものではなく、ここに集うみんなの音楽を。</p></div></li>
        </ul>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="recruit-title">
      <div class="container container--narrow reveal">
{title("Recruitment", "recruit-title", "団員募集")}
        <p class="lead">これから一緒に、<br>オーケストラをつくる仲間を募集しています。</p>
        <ul class="chips" aria-label="募集の特徴">
          <li>学生中心</li><li>年齢不問</li><li>所属不問</li><li>初心者歓迎</li><li>経験者歓迎</li>
        </ul>
        <p class="text-center">募集楽器：{INSTR_SHORT}<br><span class="small muted">その他の楽器の方もご相談ください。</span></p>
        <p class="text-center">参加希望フォームは、こんな段階でも送信できます。</p>
{STAGES}
        <div class="section-more">
          {btn("recruit.html", "団員募集の詳細を見る", "primary")}
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="activity-title">
      <div class="container container--narrow reveal">
{title("Activity", "activity-title", "活動について")}
        <dl class="info-list">
{row("活動地域", "神奈川県を中心に活動予定（神奈川県外からの参加も歓迎）")}
{row("活動開始", "2026年12月頃から合奏開始予定")}
{row("練習", "通常は月1〜2回程度、1回約3時間を想定<br>" + pending("具体的な日程・会場は今後決定予定です"))}
        </dl>
        <div class="section-more">
          {btn("activity.html", "活動について詳しく")}
        </div>
      </div>
    </section>

{cta_band()}'''

# ================================================================ ABOUT
WHY_INNER = title("Why we start", "why-title", "なぜ、このオーケストラをつくるのか") + '''
        <p>初心者だから。年齢が若いから。経験が少ないから。所属が違うから。<br class="u-pc">そんな理由で、自分の音楽を諦めてほしくありません。</p>
        <p>そして、経験を積んできた人にも、学校や団体の枠を越えて「普段とは違う仲間と演奏したい」という気持ちに応えられる場所でありたいと考えています。</p>
        <p>かながわコネクトオーケストラは、学生を中心に活動する、年齢・経験を問わないオーケストラです。<strong>年齢や経験に関係なく、音楽を通して人と人がつながる場所をつくりたい。</strong>その思いから、このオーケストラを立ち上げます。</p>'''

about_body = page_header("About", "私たちについて", "年齢や経験に関係なく、<br>音楽を通して人と人がつながる場所を。") + section("", "why-title", WHY_INNER) + f'''
    <section class="section section--tinted" aria-labelledby="concept-title">
      <div class="container container--narrow">
{title("Concept", "concept-title", CONCEPT)}
        <ul class="concept-lines">
          <li>人と人がつながり、</li>
          <li>音と音がつながり、</li>
          <li>みんなの音楽になる。</li>
        </ul>
        <p class="text-center">学校、学年、年齢、経験、所属している団体などに関係なく、<br class="u-pc">「オーケストラをやってみたい」「もっと音楽を楽しみたい」<br class="u-pc">「普段とは違う仲間と演奏したい」という気持ちを持つ人が、<br class="u-pc">一緒に音楽をつくれる場所を目指します。</p>
      </div>
    </section>

    <section class="section section--navy" aria-labelledby="philosophy-title">
      <div class="container container--narrow text-center">
{title("Philosophy", "philosophy-title", "理念")}
        <p class="lead">{PHILOSOPHY}</p>
        <p>経験者が初心者に教えるだけでなく、初心者から経験者が学ぶこともあります。<br class="u-pc">年齢や経験だけで意見の価値が決まるのではなく、<br class="u-pc">一人ひとりの音や考えを大切にしながら、みんなでオーケストラをつくっていきます。</p>
      </div>
    </section>

    <section class="section" aria-labelledby="bridge-title">
      <div class="container">
{title("Together", "bridge-title", "教える人と、教わる人に分けない")}
        <p class="text-center">「初心者だから参加できない」でも、「経験者だから初心者とは一緒にできない」でもなく。<br class="u-pc">それぞれの経験を持つ人が、一緒に成長する場所でありたいと考えています。</p>
        <div class="grid-2 u-mt-lg">
{card("初心者でも参加できる", "<p>「オーケストラをやったことがないから……」という理由だけで参加を諦める必要はありません。もちろん経験者も大歓迎です。それぞれの経験や技術に合わせて、できることから一緒に取り組みます。</p>")}
{card("挑戦できる", "<p>失敗を恐れて挑戦できなくなるような場所にはしたくありません。「やってみたい」と思ったことに挑戦し、うまくいかなかったらみんなで考えて改善する、そんな環境を目指します。</p>")}
{card("年齢や経験だけで上下関係を作らない", "<p>年上だから、経験年数が長いから偉い、という考え方ではなく、互いを尊重します。演奏や運営に必要な役割・責任を持ちつつ、誰でも対等に意見を言えるオーケストラを目指します。</p>")}
{card("みんなで音楽をつくる", "<p>指揮者や一部の人だけが音楽を決めるのではなく、演奏する一人ひとりが「この曲で何を表現したいか」「どうしたらもっと良くなるか」を考えながら、一緒に音楽をつくっていきます。</p>")}
        </div>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="ambition-title">
      <div class="container container--narrow">
{title("Our ambition", "ambition-title", "誰でも参加できて、本気で音楽をつくる")}
        <p>私たちは、初心者を受け入れることと、質の高い音楽を目指すことは両立できると考えています。</p>
        <p>第1回演奏会では、ドヴォルザークの交響曲第7番をメインプログラムとして予定しています。この作品に挑戦すること自体が、私たちの音楽的な目標のひとつです。</p>
        <div class="section-more">
          {btn("concert.html", "第1回演奏会について")}
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="org-title">
      <div class="container container--narrow">
{title("Profile", "org-title", "団体概要")}
        <dl class="info-list">
{row("団体名", SITE)}
{row("コンセプト", CONCEPT)}
{row("理念", PHILOSOPHY)}
{row("団体の特徴", "学生を中心に活動する、年齢・経験・所属を問わないオーケストラ")}
{row("活動地域", "神奈川県を中心に活動予定")}
{row("活動開始", "2026年12月頃から合奏開始予定")}
        </dl>
      </div>
    </section>

{cta_band()}'''

# ================================================================ RECRUIT
INSTR = [("弦楽器", ["ヴァイオリン", "ヴィオラ", "チェロ", "コントラバス"]),
         ("木管楽器", ["フルート", "オーボエ", "クラリネット", "ファゴット"]),
         ("金管楽器", ["ホルン", "トランペット", "トロンボーン", "ユーフォニアム", "チューバ"]),
         ("打楽器", ["パーカッション"])]
instr_html = "\n".join(
    f'''          <div class="instrument-card">
            <h3 class="instrument-card__title">{g}</h3>
            <ul>{"".join("<li>" + i + "</li>" for i in items)}</ul>
          </div>''' for g, items in INSTR)

STEPS = [("参加希望フォームに回答", "「興味がある」「話を聞いてみたい」の段階で、気軽にご回答ください。"),
         ("活動のご案内", "今後の活動内容や練習予定など、決定した情報を順次お知らせします。"),
         ("参加相談", "担当楽器・経験・日程などを確認し、必要に応じてご相談します。"),
         ("正式な参加", "活動条件や安全面を確認し、正式団員として活動を開始します。")]
steps_html = "\n".join(f'          <li><span class="steps__title">{a}</span><span class="steps__text">{b}</span></li>' for a, b in STEPS)

RULES = [
    ("基本的な姿勢", "<p>互いを尊重し、年齢・性別・経験・技術・所属による不当な扱いや、頭ごなしの否定をしません。困っている人を助け合い、建設的に意見を交わします。「上手な人が偉い」ではなく、全員で音楽をつくります。</p>"),
    ("練習への参加", "<p>可能な限り練習に参加し、欠席・遅刻・早退は早めに連絡してください。自分のパートを練習し、合奏を妨げない行動を基本とします。学校・仕事・体調などによるやむを得ない欠席を責めることはありません。</p>"),
    ("演奏会への参加・人数調整", "<p>編成・参加状況・曲の難易度などを考慮して出演者を決定します。初心者という理由だけで一律に除外することはありません。希望者が多い楽器は、曲ごとの担当変更や交代制など、納得感のある方法で公平に調整します。</p>"),
    ("初心者への配慮・意見交換", "<p>「初心者だから来ない方がいい」などの否定的な言動は固く禁止します。意見の違いがある場合も、人格否定や威圧的な態度、SNSでの攻撃は厳禁とし、建設的な対話を徹底します。</p>"),
    ("禁止事項", """<ul class="dash-list">
                <li><strong>他人を傷つける行為：</strong>暴力・脅迫・差別的言動、侮辱・人格否定・執拗な嫌がらせ、いじめ・仲間外れ</li>
                <li><strong>ハラスメント行為：</strong>セクシュアルハラスメント、パワーハラスメント、年齢・経験・立場を利用した威圧</li>
                <li><strong>プライバシー侵害：</strong>本名・連絡先・学校名・写真の無断公開、団体内の個人的なやり取りの無断転載</li>
                <li><strong>活動妨害行為：</strong>意図的な合奏練習の妨害、他の団員の演奏妨害・安全を損なう行為</li>
              </ul>"""),
    ("SNSの利用", "<p>顔写真や個人を特定できる情報は、本人の同意なく公開しません。トラブルをSNS上で一方的に公開せず、運営へご相談ください。</p>"),
    ("未成年の方の安全管理", "<p>保護者確認の徹底、金銭・会場・時間の適切な管理、成人との私的な交流における安全配慮を行います。</p>"),
    ("団費・会計", "<p>事前に用途・金額を明示し、不透明な請求は行いません。適切な帳簿記録を保ちます。</p>"),
    ("違反への対応", "<p>事態を把握したうえで注意・話し合いを行い、重大な違反の場合は参加停止・退団などの措置を講じます。</p>"),
    ("退団について", "<p>学業・仕事・家庭の事情などによる退団で不利益が生じることは一切ありません。再参加も歓迎します。</p>"),
    ("規約の変更", "<p>必要に応じて、団員に十分説明したうえで決定します。</p>"),
]
rules_html = "\n".join(details(h, b) for h, b in RULES)

FEE_TEXT = "会場費・練習会場費・楽譜・演奏会運営費などを踏まえて、活動内容に無理のない形で決定します。正式決定後、参加前に明確にお知らせします。"

FAQ = [
    ("オーケストラの経験がなくても参加できますか？", "<p>はい、参加できます。「オーケストラをやったことがないから」という理由だけで参加を諦める必要はありません。それぞれの経験や技術に合わせて、できることから一緒に取り組みます。</p>"),
    ("経験者にとっても、やりがいのある活動になりますか？", "<p>第1回演奏会では、ドヴォルザークの交響曲第7番をメインプログラムとして予定しています。一人ひとりが音楽づくりに関わり、質の高い演奏を目指すオーケストラです。</p>"),
    ("学生でなくても参加できますか？", "<p>はい。学生を中心に活動するオーケストラですが、学生以外の方の参加も歓迎しています。小学生から社会人まで、幅広い年代の参加を想定しています。</p>"),
    ("神奈川県外に住んでいますが、参加できますか？", "<p>はい、神奈川県外からの参加も歓迎します。活動は神奈川県を中心に予定しています。</p>"),
    ("参加費はかかりますか？", f"<p>金額は現在検討中で、今後決定予定です。{FEE_TEXT}</p>"),
    ("募集楽器にない楽器でも参加できますか？", "<p>その他の楽器についても、参加を希望される場合はご相談ください。</p>"),
    ("フォームを送ったら、必ず入団しなければいけませんか？", "<p>いいえ。フォームの回答は正式な入団手続きではありません。活動のご案内や参加相談を経て、正式な参加となります。「まだ参加を決めていない」段階での回答も歓迎です。</p>"),
]
faq_html = "\n".join(details(q, a) for q, a in FAQ)

recruit_body = page_header("Recruitment", "団員募集", "これから一緒に、<br>オーケストラをつくりませんか？") + f'''
    <section class="section" aria-labelledby="welcome-title">
      <div class="container container--narrow">
{title("Welcome", "welcome-title", "完成した団体に加わるのではなく、<br>一緒につくるオーケストラです")}
        <p>かながわコネクトオーケストラは、2026年12月頃の活動開始に向けて準備を進めている、立ち上げ段階のオーケストラです。</p>
        <p>どんな音楽をつくり、どんな雰囲気の団体にしていくのか。それを、これから集まるみなさんと一緒に創り上げていきたいと考えています。</p>
        <ul class="chips" aria-label="募集の特徴">
          <li>学生中心</li><li>年齢不問</li><li>所属不問</li><li>初心者歓迎</li><li>経験者歓迎</li><li>オーケストラ未経験OK</li>
        </ul>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="form-title">
      <div class="container container--narrow">
{title("Feel free", "form-title", "参加を決めていなくても、<br>フォームを送れます")}
        <p class="text-center">参加希望フォームは、こんな段階でも送信できます。</p>
{STAGES}
        <p class="text-center small muted">フォームの回答は正式な入団手続きではありません。<br>送信後に、活動のご案内や参加相談を行います。</p>
        <div class="btn-group btn-group--center">
          {btn_form("primary")}
          {btn_pdf()}
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="audience-title">
      <div class="container">
{title("For everyone", "audience-title", "初心者も、経験者も。")}
        <div class="grid-2">
          <div class="card card--audience">
            <p class="card__eyebrow">はじめての方へ</p>
            <h3 class="card__title">初めてでも、安心して</h3>
            <p>オーケストラ経験がなくても参加できます。吹奏楽の経験がある方、久しぶりに楽器を演奏したい方も歓迎です。それぞれの経験や技術に合わせて、できることから一緒に取り組みます。</p>
          </div>
          <div class="card card--audience">
            <p class="card__eyebrow">経験者の方へ</p>
            <h3 class="card__title">本気で、音楽をつくる</h3>
            <p>第1回演奏会のメインプログラムは、ドヴォルザークの交響曲第7番を予定しています。一人ひとりが「この曲で何を表現したいか」を考え、質の高い音楽を目指します。</p>
          </div>
        </div>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="outline-title">
      <div class="container container--narrow">
{title("Outline", "outline-title", "募集概要")}
        <dl class="info-list">
{row("募集対象", "学生を中心に、年齢・経験・所属を問わず募集しています。")}
{row("年代", "小学生／中学生／高校生／大学生・専門学校生／社会人など、幅広い年代の参加を想定しています（学生を中心に活動していますが、学生以外の方も歓迎です）。")}
{row("経験", "オーケストラ経験者、吹奏楽経験者、弦楽器経験者、初心者、久しぶりに楽器を演奏したい方など。")}
{row("活動地域", "神奈川県を中心に活動予定（特に神奈川県東部を中心に、オーケストラ活動に適した会場を選定）。神奈川県外からの参加も歓迎します。")}
{row("活動開始", "2026年12月頃からの合奏開始を予定しています（団員募集や会場準備の状況により変更の場合があります）。")}
{row("練習頻度", "通常は月1〜2回程度を想定しています。演奏会前は月2〜4回程度に増える予定です。")}
{row("練習時間", "1回あたり約3時間を想定しています。演奏会前はセクション練習なども柔軟に行います。")}
{row("練習日・会場", pending("今後決定予定です。決定次第お知らせします"))}
{row("参加費", pending("金額は現在検討中です") + '<br><span class="small">' + FEE_TEXT + '</span>')}
        </dl>
        <p class="note">※ 実際の演奏会への参加については、楽器編成・人数・練習状況などを踏まえて調整する場合があります。</p>
      </div>
    </section>

    <section class="section" aria-labelledby="instrument-title">
      <div class="container">
{title("Instruments", "instrument-title", "募集楽器")}
        <p class="text-center">現在、以下の楽器を中心に募集しています。<br>その他の楽器についても、参加を希望される場合はご相談ください。</p>
        <div class="instrument-grid">
{instr_html}
        </div>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="mind-title">
      <div class="container container--narrow">
{title("Our promise", "mind-title", "参加するうえで大切にしてほしいこと")}
        <p class="lead">「技術の高さ」ではなく<br>「一緒につくろうとすること」を大切にします。</p>
        <div class="card">
          <ul class="check-list">
            <li>練習にできる限り参加すること</li>
            <li>自分のパートを練習してくること</li>
            <li>他のメンバーの音や意見を尊重すること</li>
            <li>困ったときに相談すること</li>
            <li>より良い音楽をつくるために協力すること</li>
            <li>他の人が安心して活動できる環境を大切にすること</li>
          </ul>
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="flow-title">
      <div class="container container--narrow">
{title("How to join", "flow-title", "参加までの流れ")}
        <ol class="steps">
{steps_html}
        </ol>
        <div class="section-more">
          {btn_form("primary")}
        </div>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="safety-title">
      <div class="container">
{title("Safety &amp; privacy", "safety-title", "安心して参加いただくために")}
        <div class="grid-2">
{card("未成年の方へ", "<p>小・中・高校生の参加も歓迎です。安心して活動できる環境づくりのため、正式な活動参加にあたっては、必要に応じて保護者の方への確認や同意をお願いします。未成年の運営メンバーだけに判断を委ねず、成人の協力を得て、安全面・金銭面を適切に管理します。</p>")}
{card("個人情報の取り扱い", "<p>参加希望フォームでいただいた情報は、団体の活動に関するご連絡や参加確認などの目的で使用します。本人の同意なく第三者へ提供したり、SNSなどで公開したりすることはありません。必要以上の情報は集めない方針です。</p>")}
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="rules-title">
      <div class="container container--narrow">
{title("Rules", "rules-title", "参加ルール・基本方針")}
        <p>すべてのメンバーが安心して音楽活動を行える環境づくりのため、活動開始にあたって以下の基本方針を定めます。正式な団員規約・安全管理に関する規程などは、活動開始までに必要に応じて整備します。</p>
        <div class="accordion">
{rules_html}
        </div>
        <div class="section-more">
          {btn_pdf()}
        </div>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="faq-title">
      <div class="container container--narrow">
{title("FAQ", "faq-title", "よくある質問")}
        <div class="accordion">
{faq_html}
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="message-title">
      <div class="container container--narrow text-center">
        <h2 id="message-title" class="lead">誰かが「ここにいていい」と思える<br>オーケストラであること。</h2>
        <p>初心者だから。年齢が若いから。経験が少ないから。所属が違うから。<br class="u-pc">そんな理由で、自分の音楽を諦めてほしくありません。</p>
        <p>完成された団体に参加するのではなく、<br class="u-pc">どんな音楽をつくり、どんな雰囲気にするのかを、<br class="u-pc">これから集まるみなさんと一緒に創り上げていきたいと考えています。</p>
      </div>
    </section>

{cta_band()}'''

# ================================================================ CONCERT
concert_body = page_header("Concert", "第1回演奏会", "学生が中心となって、<br>ドヴォルザークの交響曲第7番に挑戦します。") + f'''
    <section class="section section--navy concert-feature" aria-labelledby="main-program-title">
      <div class="container container--narrow">
        <h2 class="visually-hidden" id="main-program-title">メインプログラム</h2>
        <div class="concert-feature__program">
          <p class="concert-feature__tag">Main Program</p>
          <p class="concert-feature__composer" lang="cs">Antonín Dvořák</p>
          <p class="concert-feature__work" lang="en">Symphony No. 7</p>
          <p class="concert-feature__ja">ドヴォルザーク：交響曲第7番 ニ短調 作品70</p>
        </div>
        <p>第1回演奏会では、ドヴォルザークの交響曲第7番を<br class="u-pc">メインプログラムとして予定しています。</p>
      </div>
    </section>

    <section class="section" aria-labelledby="status-title">
      <div class="container container--narrow">
{title("Status", "status-title", "現在の決定状況")}
        <p class="text-center">演奏会の情報は、決まったものから順にお知らせします。</p>
        <dl class="info-list">
{row("メインプログラム", "ドヴォルザーク：交響曲第7番 " + planned())}
{row("その他の曲目", pending("曲目は現在調整中です"))}
{row("開催日", pending("決定次第お知らせします"))}
{row("会場", pending("決定次第お知らせします"))}
{row("チケット", pending("決定次第お知らせします"))}
{row("出演者の参加費", pending("今後決定予定です") + '<br><span class="small">演奏会の開催条件などを踏まえて決定し、参加前に明確にお知らせします。</span>')}
{row("出演", SITE)}
        </dl>
        <p class="note">※ 演奏会の日程・会場・具体的な曲目・参加条件などは、団員数や楽器編成、練習環境などが整った段階で正式決定します。</p>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="program-title">
      <div class="container container--narrow">
{title("Program", "program-title", "プログラム構成（予定）")}
        <ol class="program-list">
          <li><span class="program-list__part">オープニング</span><span class="program-list__detail">{pending("曲目は調整中です")}</span></li>
          <li><span class="program-list__part">メイン前の作品</span><span class="program-list__detail">{pending("曲目は調整中です")}</span></li>
          <li class="program-list__main"><span class="program-list__part">メインプログラム</span><span class="program-list__detail">ドヴォルザーク：交響曲第7番 {planned()}</span></li>
          <li><span class="program-list__part">アンコール（2曲予定）</span><span class="program-list__detail">{pending("曲目は調整中です")}</span></li>
        </ol>
      </div>
    </section>

    <section class="section" aria-labelledby="dvorak-title">
      <div class="container container--narrow">
{title("About the work", "dvorak-title", "メインプログラムについて")}
        <div class="card">
          <h3 class="card__title">ドヴォルザーク　交響曲第7番 ニ短調 作品70</h3>
          <p>チェコの作曲家アントニン・ドヴォルザーク（1841–1904）による交響曲です。1885年にロンドンで初演された全4楽章の作品で、引き締まった構成と、情熱的で劇的な音楽が特徴です。</p>
        </div>
        <div class="card u-mt-md">
          <h3 class="card__title">この曲に挑戦する理由</h3>
          <p>この作品は、経験者にとっても挑みがいのある交響曲です。第1回演奏会でこの曲に取り組むこと自体が、私たちの音楽的な目標のひとつです。</p>
          <p>初めてオーケストラに参加する方も、経験を重ねてきた方も、それぞれの経験を持ち寄り、一つの音楽をつくりあげていきます。</p>
        </div>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="news-title">
      <div class="container container--narrow text-center">
{title("News", "news-title", "最新情報について")}
        <p>演奏会の最新情報は、本サイトと公式Instagramでお知らせします。</p>
        <a class="btn btn--outline" href="{INSTAGRAM}" target="_blank" rel="noopener noreferrer">{ICON_IG}公式Instagram{NEW_TAB}</a>
      </div>
    </section>

{cta_band("この演奏会を、一緒につくりませんか。", "第1回演奏会に向けて、一緒に演奏する仲間を募集しています。<br>「詳しい話を聞いてみたい」という段階でも、気軽にご連絡ください。")}'''

# ================================================================ ACTIVITY
activity_body = page_header("Activity", "活動について", "2026年12月頃の合奏開始に向けて、<br>準備を進めています。") + f'''
    <section class="section" aria-labelledby="overview-title">
      <div class="container container--narrow">
{title("Overview", "overview-title", "活動概要")}
        <dl class="info-list">
{row("活動地域", "神奈川県を中心に活動予定です（特に神奈川県東部を中心に、オーケストラ活動に適した会場を選定）。神奈川県外からの参加も歓迎します。")}
{row("活動開始", "2026年12月頃からの合奏開始を予定しています（団員募集や会場準備の状況により変更の場合があります）。")}
{row("練習頻度", "通常は月1〜2回程度を想定しています。<br>演奏会前は月2〜4回程度に増える予定です。")}
{row("練習時間", "1回あたり約3時間を想定しています。演奏会前はセクション練習なども柔軟に行います。")}
{row("練習日・曜日", pending("今後決定予定です"))}
{row("練習会場", pending("今後決定予定です"))}
{row("当面の目標", "第1回演奏会（メインプログラム：ドヴォルザーク 交響曲第7番を予定）")}
        </dl>
        <p class="note">※ 未定の項目は、決定次第お知らせします。</p>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="style-title">
      <div class="container">
{title("Our style", "style-title", "私たちの活動のかたち")}
        <div class="grid-2">
{card("学生が中心となって", "<p>運営も演奏も、学生が中心となってつくっていきます。年齢や所属に関係なく、一人ひとりが団体づくりの担い手です。</p>")}
{card("それぞれのレベルで挑戦する", "<p>初めての方も経験者も、それぞれのレベルで挑戦できる環境を目指します。うまくいかない経験も、成長の糧に。</p>")}
{card("みんなで音楽をつくる", "<p>演奏する一人ひとりが「どうしたらもっと良くなるか」を考えながら、質の高い音楽を目指します。</p>")}
{card("垣根を越えてつながる", "<p>年齢・経験・所属を問わず、音楽をつくりたい人が集まり、ともに学び合います。</p>")}
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="roadmap-title">
      <div class="container container--narrow">
{title("Roadmap", "roadmap-title", "これからの予定")}
        <ol class="steps">
          <li><span class="steps__title">団員募集（現在）</span><span class="steps__text">学生を中心に、年齢・経験・所属を問わずメンバーを募集しています。</span></li>
          <li><span class="steps__title">合奏開始（2026年12月頃予定）</span><span class="steps__text">具体的な練習日・会場は今後決定予定です。</span></li>
          <li><span class="steps__title">第1回演奏会</span><span class="steps__text">ドヴォルザークの交響曲第7番をメインプログラムとして予定しています。開催日・会場は決定次第お知らせします。</span></li>
        </ol>
      </div>
    </section>

{cta_band()}'''

# ================================================================ CONTACT
contact_body = page_header("Contact", "お問い合わせ", "ご用件に合わせて、<br>以下の窓口をご利用ください。") + f'''
    <section class="section" aria-labelledby="routes-title">
      <div class="container">
{title("Contact", "routes-title", "お問い合わせ窓口")}
        <div class="contact-grid">
          <div class="card contact-card">
            <p class="card__eyebrow">参加のご相談</p>
            <h3 class="card__title">参加希望フォーム</h3>
            <p>参加を希望される方、興味のある方はこちらから。「まだ参加を決めていない」「詳しい話を聞いてみたい」という段階でも送信できます。</p>
            {btn_form("primary", "フォームを開く")}
          </div>
          <div class="card contact-card">
            <p class="card__eyebrow">その他のお問い合わせ</p>
            <h3 class="card__title">メール</h3>
            <p>団体へのご質問・ご連絡は、こちらのメールアドレスまでお送りください。</p>
            <a class="contact-card__link" href="mailto:{MAIL}">{ICON_MAIL}<span>{MAIL.replace("@", "<wbr>@")}</span></a>
          </div>
          <div class="card contact-card">
            <p class="card__eyebrow">最新情報</p>
            <h3 class="card__title">公式Instagram</h3>
            <p>活動や演奏会の最新情報をお知らせします。</p>
            <a class="contact-card__link" href="{INSTAGRAM}" target="_blank" rel="noopener noreferrer">{ICON_IG}<span>{INSTAGRAM_ID}</span>{NEW_TAB}</a>
          </div>
        </div>
      </div>
    </section>

    <section class="section section--tinted" aria-labelledby="privacy-title">
      <div class="container container--narrow">
{title("Privacy", "privacy-title", "個人情報の取り扱いについて")}
        <p>参加希望フォームでいただいた情報は、団体の活動に関するご連絡や参加確認などの目的で使用します。本人の同意なく第三者へ提供したり、SNSなどで公開したりすることはありません。</p>
        <p>未成年の方の正式な活動参加にあたっては、必要に応じて保護者の方への確認を行います。</p>
        <p class="note">※ 団員募集の詳細は<a href="recruit.html">団員募集ページ</a>をご覧ください。</p>
      </div>
    </section>
'''

# ================================================================ 404
nf_body = f'''    <div class="page-header">
      <div class="container">
        <span class="page-header__en" aria-hidden="true">Not Found</span>
        <h1 class="page-header__title">ページが見つかりません</h1>
      </div>
    </div>
    <section class="section">
      <div class="container container--narrow text-center">
        <p>お探しのページは移動または削除された可能性があります。</p>
        <div class="btn-group btn-group--center">
          <a class="btn btn--primary" href="/">ホームへ戻る</a>
          <a class="btn btn--outline" href="/recruit.html">団員募集を見る</a>
        </div>
      </div>
    </section>
'''

PAGES = [
    ("index.html", "ホーム",
     "神奈川県を中心に活動する「かながわコネクトオーケストラ」。学生を中心に活動する、年齢・経験を問わないオーケストラです。初心者も経験者も、音楽を通してともに成長する仲間を募集しています。",
     index_body, ORG_LD),
    ("about.html", "私たちについて",
     "かながわコネクトオーケストラは、年齢や経験に関係なく、音楽を通して人と人がつながる場所をつくるオーケストラです。コンセプト「すべてのひとのためのオーケストラ」と理念をご紹介します。",
     about_body, breadcrumb_ld("私たちについて", "about.html")),
    ("recruit.html", "団員募集",
     "かながわコネクトオーケストラの団員募集。学生を中心に、年齢・経験・所属を問わず募集しています。オーケストラ未経験の方、吹奏楽経験者、経験豊富な方も歓迎です。",
     recruit_body, breadcrumb_ld("団員募集", "recruit.html")),
    ("concert.html", "第1回演奏会",
     "かながわコネクトオーケストラ第1回演奏会のご案内。メインプログラムとしてドヴォルザーク 交響曲第7番を予定しています。開催日・会場は決定次第お知らせします。",
     concert_body, breadcrumb_ld("第1回演奏会", "concert.html")),
    ("activity.html", "活動について",
     "かながわコネクトオーケストラの活動概要。神奈川県を中心に、2026年12月頃から合奏開始予定。練習は通常月1〜2回程度、1回約3時間を想定しています。",
     activity_body, breadcrumb_ld("活動について", "activity.html")),
    ("contact.html", "お問い合わせ",
     "かながわコネクトオーケストラへのお問い合わせ窓口。参加希望は参加希望フォーム、その他のご連絡はメールで受け付けています。",
     contact_body, breadcrumb_ld("お問い合わせ", "contact.html")),
]

for fn, t, d, body, ld in PAGES:
    (OUT / fn).write_text(doc(fn, t, d, body, ld), encoding="utf-8")

(OUT / "404.html").write_text(
    doc("404.html", "ページが見つかりません", PAGES[0][2], nf_body, None, root="/", noindex=True), encoding="utf-8")

sitemap = ['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
for fn, *_ in PAGES:
    loc = f"{BASE}/" if fn == "index.html" else f"{BASE}/{fn}"
    pr = "1.0" if fn == "index.html" else ("0.9" if fn == "recruit.html" else "0.8")
    sitemap.append(f"  <url>\n    <loc>{loc}</loc>\n    <lastmod>{LASTMOD}</lastmod>\n    <changefreq>monthly</changefreq>\n    <priority>{pr}</priority>\n  </url>")
sitemap.append("</urlset>\n")
(OUT / "sitemap.xml").write_text("\n".join(sitemap), encoding="utf-8")
print("built", len(PAGES) + 1, "pages + sitemap")
