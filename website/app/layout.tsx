import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  metadataBase: new URL('https://stagelight-theatre-diary.cysbc1999.chatgpt.site'),
  title: 'StageLight — Your Private Theatre Diary',
  description:
    'Remember every show with photos, seats, ratings, notes, and private iCloud sync. Free for iPhone.',
  openGraph: {
    title: 'StageLight — Your Private Theatre Diary',
    description:
      'Remember every show with photos, seats, ratings, notes, and private iCloud sync. Free for iPhone.',
    images: ['/og.png'],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'StageLight — Your Private Theatre Diary',
    description:
      'Remember every show with photos, seats, ratings, notes, and private iCloud sync. Free for iPhone.',
    images: ['/og.png'],
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
