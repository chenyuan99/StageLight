import { ArrowLeft, CircleHelp, Cloud, Image as ImageIcon, MapPin } from 'lucide-react';

const issuesURL = 'https://github.com/chenyuan99/StageLight/issues';
const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '';

export const dynamic = 'force-static';

const questions = [
  {
    icon: Cloud,
    question: 'How does iCloud sync work?',
    answer:
      'StageLight syncs automatically through your private iCloud account when iCloud is available. Check the current status from the Profile tab.',
  },
  {
    icon: ImageIcon,
    question: 'Where are my photos stored?',
    answer:
      'Photos stay with your private diary on your device and may sync through your private iCloud account. StageLight does not upload them to a developer-operated server.',
  },
  {
    icon: MapPin,
    question: 'Do I have to use Apple Maps search?',
    answer:
      'No. Theatre search is optional. You can always enter a theatre and city manually when adding or editing a performance.',
  },
];

export default function Support() {
  return (
    <main className="legal-shell">
      <header className="subpage-header">
        <a href={`${basePath}/`} className="back-link"><ArrowLeft size={17} /> StageLight</a>
        <a href={`${basePath}/privacy.html`}>Privacy</a>
      </header>
      <section className="legal-hero">
        <CircleHelp aria-hidden="true" />
        <p className="eyebrow">Support</p>
        <h1>How can we help?</h1>
        <p>Answers to common questions about your private theatre diary.</p>
      </section>
      <section className="faq-grid">
        {questions.map(({ icon: Icon, question, answer }) => (
          <article key={question}>
            <Icon aria-hidden="true" />
            <h2>{question}</h2>
            <p>{answer}</p>
          </article>
        ))}
      </section>
      <section className="support-cta">
        <h2>Still need help?</h2>
        <p>Report a problem or suggest an improvement and include the steps that led to it.</p>
        <a className="primary-link" href={issuesURL}>Contact StageLight support</a>
      </section>
    </main>
  );
}
