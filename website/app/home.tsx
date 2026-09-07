'use client';

import { useEffect, useState } from 'react';
import { Cloud, ImageDown, Languages, LockKeyhole, MapPin, NotebookPen, Palette, Share2 } from 'lucide-react';

const appStoreURL = 'https://apps.apple.com/us/app/stagelight-theatre-diary/id6806575225';
const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '';
type Language = 'en' | 'zh-Hans' | 'zh-Hant';

const copy = {
  en: {
    brand: 'StageLight', skip: 'Skip to content', nav: ['Memory cards', 'Privacy', 'Support'], download: 'Download free',
    heroEyebrow: 'Your private theatre diary for iPhone', heroTitle: 'Remember the show. Share the moment.',
    heroDescription: 'Keep every theatre night in one private diary, then turn it into a beautiful memory card you can share anywhere or save to Photos.',
    downloadOn: 'Download free on the', appStore: 'App Store', availability: 'Free · No account · No ads', privacy: 'No tracking. Your memories stay yours.', floating: 'Made with StageLight.\nReady to share.',
    memoryEyebrow: 'From curtain call to camera roll', memoryTitle: 'Make the memory as beautiful as the night.',
    memoryIntro: 'Turn any saved performance into a personal keepsake made for Messages, Instagram Stories, or your own photo library.',
    memorySteps: [
      ['Capture the night', 'Start with a performance already saved in your private theatre diary.'],
      ['Make it yours', 'Choose a Spotlight or Story design and include only the details you want.'],
      ['Share or save', 'Send your card anywhere or keep a beautiful copy in your photo library.'],
    ],
    memoryCta: 'Create your first memory card', freeIPhone: 'Free on iPhone', featureEyebrow: 'Private by design', featureTitle: 'Your theatre life belongs to you.',
    features: [
      ['Keep the whole night', 'Save the show, date, theatre, seats, rating, notes, and the photos that bring it back.'],
      ['Private iCloud sync', 'Your collection stays available across your Apple devices without a separate StageLight account.'],
      ['Find theatres faster', 'Use optional Apple Maps search or enter any venue manually—from Broadway to your local stage.'],
      ['Now in your language', 'Use StageLight in English, Simplified Chinese, or Traditional Chinese, and switch anytime from Profile.'],
    ],
    storyEyebrow: 'A diary that grows with you', storyTitle: 'See your theatre story take shape.',
    storyCopy: 'Browse performances chronologically, search by show or theatre, and look back on the places and productions that meant the most.',
    closingTitle: 'Remember the show. Share the moment.', closingCopy: 'Start your private theatre diary and make your first memory card.', closingCta: 'View StageLight on the App Store', languageLabel: 'Page language',
  },
  'zh-Hans': {
    brand: '剧光灯', skip: '跳到主要内容', nav: ['回忆卡', '隐私', '支持'], download: '免费下载',
    heroEyebrow: '你的 iPhone 私人观剧日记', heroTitle: '记住舞台，共享此刻。',
    heroDescription: '把每个剧场之夜珍藏在私人日记中，再制成精美回忆卡，随时分享或保存到照片。',
    downloadOn: '免费下载自', appStore: 'App Store', availability: '免费 · 无需账户 · 无广告', privacy: '不追踪。你的回忆只属于你。', floating: '由剧光灯制作。\n随时分享。',
    memoryEyebrow: '从谢幕到相册', memoryTitle: '让回忆和那个夜晚一样动人。',
    memoryIntro: '把任何一场演出制成专属纪念，分享至信息、社交平台，或珍藏在自己的照片图库。',
    memorySteps: [
      ['记录夜晚', '从私人观剧日记中已经保存的一场演出开始。'],
      ['随心创作', '选择聚光灯或故事版式，只展示你想分享的细节。'],
      ['分享或保存', '把回忆卡发送到任何地方，或保存一份到照片图库。'],
    ],
    memoryCta: '制作第一张回忆卡', freeIPhone: 'iPhone 免费下载', featureEyebrow: '为隐私而设计', featureTitle: '你的观剧生活只属于你。',
    features: [
      ['珍藏完整夜晚', '记录演出、日期、剧院、座位、评分、笔记，以及唤醒回忆的照片。'],
      ['私人 iCloud 同步', '无需单独注册剧光灯账户，你的收藏也能在 Apple 设备间保持同步。'],
      ['更快找到剧院', '可选择使用 Apple 地图搜索，也能手动输入任何场馆。'],
      ['现已支持中文', '支持 English、简体中文和繁體中文，可随时在个人资料中切换。'],
    ],
    storyEyebrow: '与你一起成长的日记', storyTitle: '看见自己的观剧故事。',
    storyCopy: '按时间浏览演出，搜索剧目或剧院，重温那些对你意义非凡的地点与作品。',
    closingTitle: '记住舞台，共享此刻。', closingCopy: '开始记录私人观剧日记，制作你的第一张回忆卡。', closingCta: '前往 App Store 查看剧光灯', languageLabel: '页面语言',
  },
  'zh-Hant': {
    brand: '劇光燈', skip: '跳到主要內容', nav: ['回憶卡', '隱私', '支援'], download: '免費下載',
    heroEyebrow: '你的 iPhone 私人觀劇日記', heroTitle: '記住舞台，分享此刻。',
    heroDescription: '把每個劇場之夜珍藏在私人日記中，再製成精美回憶卡，隨時分享或儲存到照片。',
    downloadOn: '免費下載自', appStore: 'App Store', availability: '免費 · 無需帳戶 · 無廣告', privacy: '不追蹤。你的回憶只屬於你。', floating: '由劇光燈製作。\n隨時分享。',
    memoryEyebrow: '從謝幕到相簿', memoryTitle: '讓回憶和那個夜晚一樣動人。',
    memoryIntro: '把任何一場演出製成專屬紀念，分享至訊息、社交平台，或珍藏在自己的照片圖庫。',
    memorySteps: [
      ['記錄夜晚', '從私人觀劇日記中已經儲存的一場演出開始。'],
      ['隨心創作', '選擇聚光燈或故事版式，只展示你想分享的細節。'],
      ['分享或儲存', '把回憶卡傳送到任何地方，或儲存一份到照片圖庫。'],
    ],
    memoryCta: '製作第一張回憶卡', freeIPhone: 'iPhone 免費下載', featureEyebrow: '為隱私而設計', featureTitle: '你的觀劇生活只屬於你。',
    features: [
      ['珍藏完整夜晚', '記錄演出、日期、劇院、座位、評分、筆記，以及喚醒回憶的照片。'],
      ['私人 iCloud 同步', '無需單獨註冊劇光燈帳戶，你的收藏也能在 Apple 裝置間保持同步。'],
      ['更快找到劇院', '可選擇使用 Apple 地圖搜尋，也能手動輸入任何場館。'],
      ['現已支援中文', '支援 English、简体中文和繁體中文，可隨時在個人資料中切換。'],
    ],
    storyEyebrow: '與你一起成長的日記', storyTitle: '看見自己的觀劇故事。',
    storyCopy: '按時間瀏覽演出，搜尋劇目或劇院，重溫那些對你意義非凡的地點與作品。',
    closingTitle: '記住舞台，分享此刻。', closingCopy: '開始記錄私人觀劇日記，製作你的第一張回憶卡。', closingCta: '前往 App Store 查看劇光燈', languageLabel: '頁面語言',
  },
} as const;

const memoryImages = [
  ['/memory-card-share.jpg', 'A finished StageLight memory card ready to share'],
  ['/memory-card-customize.jpg', 'Customizing a theatre memory card in StageLight'],
  ['/memory-card-save.jpg', 'Saving a StageLight theatre memory card to Photos'],
] as const;
const memoryIcons = [NotebookPen, Palette, ImageDown];
const featureIcons = [NotebookPen, Cloud, MapPin, Languages];

export default function Home() {
  const [language, setLanguage] = useState<Language>('en');
  const [languageReady, setLanguageReady] = useState(false);
  const text = copy[language];

  useEffect(() => {
    const saved = window.localStorage.getItem('stagelight-site-language') as Language | null;
    if (saved && saved in copy) {
      setLanguage(saved);
    } else {
      const browserLanguage = navigator.language.toLowerCase();
      if (browserLanguage.startsWith('zh-hant') || browserLanguage.includes('tw') || browserLanguage.includes('hk')) setLanguage('zh-Hant');
      else if (browserLanguage.startsWith('zh')) setLanguage('zh-Hans');
    }
    setLanguageReady(true);
  }, []);

  useEffect(() => {
    if (!languageReady) return;
    document.documentElement.lang = language;
    window.localStorage.setItem('stagelight-site-language', language);
  }, [language, languageReady]);

  return (
    <main id="top">
      <a className="skip-link" href="#content">{text.skip}</a>
      <header className="site-header">
        <a className="brand" href={`${basePath}/`} aria-label={`${text.brand} home`}>
          <img src={`${basePath}/app-icon.png`} alt="" width="40" height="40" /><span>{text.brand}</span>
        </a>
        <div className="header-actions">
          <nav aria-label="Primary navigation">
            <a href="#memory-cards">{text.nav[0]}</a><a href={`${basePath}/privacy.html`}>{text.nav[1]}</a><a href={`${basePath}/support.html`}>{text.nav[2]}</a>
          </nav>
          <label className="language-picker">
            <Languages size={16} aria-hidden="true" /><span className="visually-hidden">{text.languageLabel}</span>
            <select value={language} onChange={(event) => setLanguage(event.target.value as Language)} aria-label={text.languageLabel}>
              <option value="en">English</option><option value="zh-Hans">简体中文</option><option value="zh-Hant">繁體中文</option>
            </select>
          </label>
        </div>
      </header>
      <a className="mobile-download" href={appStoreURL}>{text.download}</a>

      <section className="hero" id="content">
        <div className="hero-copy">
          <p className="eyebrow">{text.heroEyebrow}</p><h1>{text.heroTitle}</h1><p className="hero-description">{text.heroDescription}</p>
          <div className="hero-actions">
            <a className="app-store-button" href={appStoreURL} aria-label={text.download}><span>{text.downloadOn}</span><strong>{text.appStore}</strong></a>
            <span className="availability">{text.availability}</span>
          </div>
          <div className="trust-line"><LockKeyhole size={17} aria-hidden="true" /><span>{text.privacy}</span></div>
        </div>
        <div className="hero-visual" aria-label="A shareable StageLight theatre memory card">
          <div className="spotlight" /><div className="memory-card-preview"><img src={`${basePath}/memory-card-share.jpg`} alt="StageLight memory card" width="760" height="1644" /></div>
          <div className="floating-note"><Share2 size={16} aria-hidden="true" /><span>{text.floating.split('\n').map((line, index) => <span key={line}>{index > 0 && <br />}{line}</span>)}</span></div>
        </div>
      </section>

      <section className="memory-section" id="memory-cards">
        <div className="section-heading"><p className="eyebrow">{text.memoryEyebrow}</p><h2>{text.memoryTitle}</h2><p className="section-intro">{text.memoryIntro}</p></div>
        <div className="memory-grid">
          {text.memorySteps.map(([title, description], index) => {
            const Icon = memoryIcons[index];
            return <article className="memory-step" key={title}>
              <div className="memory-step-image"><img src={`${basePath}${memoryImages[index][0]}`} alt={memoryImages[index][1]} width="760" height="1644" loading="lazy" /></div>
              <div className="memory-step-copy"><span>{String(index + 1).padStart(2, '0')}</span><Icon aria-hidden="true" /><h3>{title}</h3><p>{description}</p></div>
            </article>;
          })}
        </div>
        <div className="section-cta"><a className="primary-link" href={appStoreURL}>{text.memoryCta}</a><span>{text.freeIPhone}</span></div>
      </section>

      <section className="feature-section" id="features">
        <div className="section-heading"><p className="eyebrow">{text.featureEyebrow}</p><h2>{text.featureTitle}</h2></div>
        <div className="feature-grid">
          {text.features.map(([title, description], index) => {
            const Icon = featureIcons[index];
            return <article className="feature-card" key={title}><Icon aria-hidden="true" /><h3>{title}</h3><p>{description}</p></article>;
          })}
        </div>
      </section>

      <section className="story-section">
        <div className="story-copy"><p className="eyebrow">{text.storyEyebrow}</p><h2>{text.storyTitle}</h2><p>{text.storyCopy}</p></div>
        <div className="story-phone phone"><img src={`${basePath}/profile.png`} alt="StageLight personal theatre statistics" width="1284" height="2778" loading="lazy" /></div>
      </section>

      <section className="closing-section">
        <img src={`${basePath}/app-icon.png`} alt={`${text.brand} icon`} width="84" height="84" /><h2>{text.closingTitle}</h2><p>{text.closingCopy}</p><a className="primary-link" href={appStoreURL}>{text.closingCta}</a>
      </section>
      <footer><span>© 2026 Yuan Chen</span><div><a href={`${basePath}/privacy.html`}>{text.nav[1]}</a><a href={`${basePath}/support.html`}>{text.nav[2]}</a></div></footer>
    </main>
  );
}
