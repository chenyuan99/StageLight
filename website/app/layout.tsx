import type { Metadata } from 'next';
import './globals.css';

const siteURL = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://yuanchen.io/StageLight/';
const socialImageURL = new URL('og.png', siteURL).toString();
const iconURL = `${process.env.NEXT_PUBLIC_BASE_PATH ?? ''}/golden-premiere-icon.png`;

export const metadata: Metadata = {
  metadataBase: new URL(siteURL),
  icons: {
    icon: { url: iconURL, type: 'image/png' },
    apple: { url: iconURL, type: 'image/png' },
  },
  title: 'StageLight — Remember the Show. Share the Moment.',
  description:
    'StageLight 1.5.1 is now available for iPhone and iPad. Keep a private theatre diary, share memory cards, and meet your optional theatre bunny.',
  openGraph: {
    title: 'StageLight — Remember the Show. Share the Moment.',
    description:
      'StageLight 1.5.1 is now available for iPhone and iPad. Keep a private theatre diary, share memory cards, and meet your optional theatre bunny.',
    images: [socialImageURL],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'StageLight — Remember the Show. Share the Moment.',
    description:
      'StageLight 1.5.1 is now available for iPhone and iPad. Keep a private theatre diary, share memory cards, and meet your optional theatre bunny.',
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
