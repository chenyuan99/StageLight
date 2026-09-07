import type { NextConfig } from 'next';

const assetPrefix = process.env.NEXT_PUBLIC_BASE_PATH ?? '';

const nextConfig: NextConfig = {
  output: 'export',
  assetPrefix: assetPrefix || undefined,
  images: { unoptimized: true },
};

export default nextConfig;
