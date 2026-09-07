import { ArrowLeft, Cloud, LockKeyhole } from 'lucide-react';

const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '';

export const dynamic = 'force-static';

export default function Privacy() {
  return (
    <main className="legal-shell">
      <header className="subpage-header">
        <a href={`${basePath}/`} className="back-link"><ArrowLeft size={17} /> StageLight</a>
        <a href={`${basePath}/support.html`}>Support</a>
      </header>
      <article className="policy">
        <div className="legal-hero">
          <LockKeyhole aria-hidden="true" />
          <p className="eyebrow">Privacy policy</p>
          <h1>Your memories stay yours.</h1>
          <p>Effective September 3, 2026</p>
        </div>

        <section>
          <h2>Data collection</h2>
          <p>The developer of StageLight does not collect, sell, or share personal data. StageLight contains no advertising, analytics, or third-party tracking.</p>
        </section>
        <section>
          <h2>Data stored on your device</h2>
          <p>Shows, performances, ratings, notes, venue details, and photos are stored on your device and used only to provide StageLight’s diary, collection, search, filtering, and statistics features.</p>
        </section>
        <section>
          <Cloud aria-hidden="true" />
          <h2>Private iCloud sync</h2>
          <p>When iCloud is available, StageLight uses Apple’s CloudKit service to sync your collection through your private iCloud account. The developer does not operate a StageLight server and cannot access your private iCloud data.</p>
        </section>
        <section>
          <h2>Camera and photo library</h2>
          <p>StageLight requests access only when you choose to capture or select an image. Selected images stay with your diary. Text recognition is performed on device.</p>
        </section>
        <section>
          <h2>Apple Maps</h2>
          <p>Optional theatre search uses Apple Maps. Search and location-related requests are handled by Apple under Apple’s privacy policy. StageLight saves only the venue details you choose, and manual entry is always available.</p>
        </section>
        <section>
          <h2>Accounts and children</h2>
          <p>StageLight does not require or provide a separate account. Because the developer does not collect personal data, StageLight does not knowingly collect personal information from children.</p>
        </section>
        <section>
          <h2>Changes and contact</h2>
          <p>If these practices change, this policy will be updated before the changed version is released. Privacy questions can be submitted through the StageLight support page.</p>
          <a className="text-link" href={`${basePath}/support.html`}>Visit support</a>
        </section>
      </article>
    </main>
  );
}
