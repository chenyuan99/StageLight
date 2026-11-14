import type { Metadata } from 'next';
import './globals.css';

const siteURL = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://yuanchen.io/StageLight/';
const socialImageURL = new URL('og.png', siteURL).toString();
const iconURL = `${process.env.NEXT_PUBLIC_BASE_PATH ?? ''}/golden-premiere-icon.png`;

const description = 'StageLight 1.6.0 is available for iPhone and iPad. Version 1.7.0, with upcoming performances and private post-show reflections, is waiting for review.';

export const metadata: Metadata = {
  metadataBase: new URL(siteURL),
  icons: {
    icon: { url: iconURL, type: 'image/png' },
    apple: { url: iconURL, type: 'image/png' },
  },
  title: 'StageLight — Remember the Show. Share the Moment.',
  description,
  openGraph: {
    title: 'StageLight — Remember the Show. Share the Moment.',
    description,
    images: [socialImageURL],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'StageLight — Remember the Show. Share the Moment.',
    description,
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
