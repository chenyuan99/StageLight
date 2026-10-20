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
    'Keep a private theatre diary on iPhone and iPad. Share memory cards and discover what is coming in StageLight 1.5.0.',
  openGraph: {
    title: 'StageLight — Remember the Show. Share the Moment.',
    description:
      'Keep a private theatre diary on iPhone and iPad. Share memory cards and discover what is coming in StageLight 1.5.0.',
    images: [socialImageURL],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'StageLight — Remember the Show. Share the Moment.',
    description:
      'Keep a private theatre diary on iPhone and iPad. Share memory cards and discover what is coming in StageLight 1.5.0.',
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
