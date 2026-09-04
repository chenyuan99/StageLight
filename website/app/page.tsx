import { Cloud, LockKeyhole, MapPin, NotebookPen, Star } from 'lucide-react';

const appStoreURL =
  'https://apps.apple.com/us/app/stagelight-theatre-diary/id6806575225';

const features = [
  {
    icon: NotebookPen,
    title: 'Keep the whole night',
    copy: 'Save the show, date, theatre, seats, rating, notes, and the photos that bring it back.',
  },
  {
    icon: Cloud,
    title: 'Private iCloud sync',
    copy: 'Your collection stays available across your Apple devices without a separate StageLight account.',
  },
  {
    icon: MapPin,
    title: 'Find theatres faster',
    copy: 'Use optional Apple Maps search or enter any venue manually—from Broadway to your local stage.',
  },
];

export default function Home() {
  return (
    <main>
      <header className="site-header">
        <a className="brand" href="#top" aria-label="StageLight home">
          <img src="/app-icon.png" alt="" width="40" height="40" />
          <span>StageLight</span>
        </a>
        <nav aria-label="Primary navigation">
          <a href="#features">Features</a>
          <a href="/privacy">Privacy</a>
          <a href="/support">Support</a>
        </nav>
      </header>

      <section className="hero" id="top">
        <div className="hero-copy">
          <p className="eyebrow">A private theatre diary for iPhone</p>
          <h1>Every theatre night, remembered.</h1>
          <p className="hero-description">
            Keep the photos, seats, ratings, notes, and little details that make
            each performance yours—beautifully organized and privately synced.
          </p>
          <div className="hero-actions">
            <a className="app-store-button" href={appStoreURL}>
              <span>Download free on the</span>
              <strong>App Store</strong>
            </a>
            <span className="availability">Free · No account · No ads</span>
          </div>
          <div className="trust-line" aria-label="StageLight privacy commitments">
            <LockKeyhole size={17} aria-hidden="true" />
            <span>No tracking. Your memories stay yours.</span>
          </div>
        </div>

        <div className="hero-visual" aria-label="StageLight app preview">
          <div className="spotlight" />
          <div className="phone phone-back">
            <img src="/diary.png" alt="StageLight chronological theatre diary" />
          </div>
          <div className="phone phone-front">
            <img src="/collection.png" alt="StageLight show collection" />
          </div>
          <div className="floating-note">
            <Star size={16} fill="currentColor" aria-hidden="true" />
            <span>More than a list.<br />A memory you can revisit.</span>
          </div>
        </div>
      </section>

      <section className="feature-section" id="features">
        <div className="section-heading">
          <p className="eyebrow">Your life in the audience</p>
          <h2>A quiet place for every standing ovation.</h2>
        </div>
        <div className="feature-grid">
          {features.map(({ icon: Icon, title, copy }) => (
            <article className="feature-card" key={title}>
              <Icon aria-hidden="true" />
              <h3>{title}</h3>
              <p>{copy}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="story-section">
        <div className="story-copy">
          <p className="eyebrow">A diary that grows with you</p>
          <h2>See your theatre story take shape.</h2>
          <p>
            Browse performances chronologically, search by show or theatre,
            and look back on the places and productions that meant the most.
          </p>
        </div>
        <div className="story-phone phone">
          <img src="/profile.png" alt="StageLight personal theatre statistics" />
        </div>
      </section>

      <section className="closing-section">
        <img src="/app-icon.png" alt="StageLight icon" width="84" height="84" />
        <h2>Your life on stage, remembered.</h2>
        <p>Start your private theatre diary today.</p>
        <a className="primary-link" href={appStoreURL}>View StageLight on the App Store</a>
      </section>

      <footer>
        <span>© 2026 Yuan Chen</span>
        <div>
          <a href="/privacy">Privacy</a>
          <a href="/support">Support</a>
        </div>
      </footer>
    </main>
  );
}
