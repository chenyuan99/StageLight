import type { Metadata } from 'next';
import './globals.css';

const siteURL = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://stagelight-theatre-diary.cysbc1999.chatgpt.site';
const socialImageURL = new URL('og.png', siteURL).toString();

export const metadata: Metadata = {
  metadataBase: new URL(siteURL),
  title: 'StageLight — Remember the Show. Share the Moment.',
  description:
    'Keep a private theatre diary and turn every performance into a beautiful memory card to share or save. Free for iPhone.',
  openGraph: {
    title: 'StageLight — Remember the Show. Share the Moment.',
    description:
      'Keep a private theatre diary and turn every performance into a beautiful memory card to share or save. Free for iPhone.',
    images: [socialImageURL],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'StageLight — Remember the Show. Share the Moment.',
    description:
      'Keep a private theatre diary and turn every performance into a beautiful memory card to share or save. Free for iPhone.',
    images: [socialImageURL],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
