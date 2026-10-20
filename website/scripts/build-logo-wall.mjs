import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';

// Standalone SVG presentation frames work in GitHub README images, where
// inline CSS is stripped. Embed the unchanged artwork; never edit app assets.
export const logos = [
  ['golden-premiere', 'StageLight/Resources/Assets.xcassets/DefaultAppIcon.appiconset/GoldenPremiereIcon.png'],
  ['cream-bunny', 'StageLight/Resources/Assets.xcassets/CreamBunnyIcon.appiconset/CreamBunnyIcon.png'],
  ['theatre-bunny', 'StageLight/Resources/Assets.xcassets/BunnyIcon.appiconset/BunnyIcon.png'],
  ['original', 'StageLight/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png'],
  ['golden-premiere-cat', 'docs/images/logo-concepts/golden-premiere-cat.png'],
];
const root = new URL('../../', import.meta.url);
const output = new URL('../public/logo-wall/', import.meta.url);
mkdirSync(output, { recursive: true });
for (const [name, source] of logos) {
  const artwork = readFileSync(new URL(source, root)).toString('base64');
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 1024" width="1024" height="1024">
<defs><clipPath id="icon"><rect width="1024" height="1024" rx="224"/></clipPath></defs>
<image width="1024" height="1024" clip-path="url(#icon)" xlink:href="data:image/png;base64,${artwork}"/>
</svg>\n`;
  writeFileSync(new URL(`${name}.svg`, output), svg);
}
