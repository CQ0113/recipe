import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium, devices } from 'playwright';

const baseUrl = process.argv[2] ?? 'http://127.0.0.1:7357';
const projectRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);
const output = path.join(projectRoot, 'artifacts', 'validation');
await fs.mkdir(output, { recursive: true });

const browser = await chromium.launch({ headless: true });
const results = [];
const pixel7 = devices['Pixel 7'];

for (const target of [
  { name: 'desktop', width: 1440, height: 960, scale: 1 },
  {
    name: 'mobile',
    width: pixel7.viewport.width,
    height: pixel7.viewport.height,
    scale: pixel7.deviceScaleFactor,
    userAgent: pixel7.userAgent,
    isMobile: pixel7.isMobile,
    hasTouch: pixel7.hasTouch,
  },
]) {
  const context = await browser.newContext({
    viewport: { width: target.width, height: target.height },
    deviceScaleFactor: target.scale,
    userAgent: target.userAgent,
    isMobile: target.isMobile,
    hasTouch: target.hasTouch,
  });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (error) => errors.push(`pageerror: ${error.message}`));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(`console: ${message.text()}`);
  });

  const response = await page.goto(baseUrl, { waitUntil: 'networkidle', timeout: 45_000 });
  if (!response?.ok()) throw new Error(`${target.name} returned HTTP ${response?.status()}`);
  await page.waitForTimeout(target.isMobile ? 10_000 : 1_500);

  const semantics = page.locator('flt-semantics-placeholder');
  if (await semantics.count()) {
    // Programmatic activation is reliable for both desktop and emulated touch
    // contexts, where Flutter's canvas can intercept Playwright pointer input.
    await semantics.evaluate((element) => element.click());
    await page.waitForTimeout(300);
  }

  const title = await page.title();
  if (!title.startsWith('Savora')) throw new Error(`Unexpected title: ${title}`);
  const flutterViewCount = await page.locator('flutter-view').count();
  if (flutterViewCount !== 1) {
    throw new Error(
      `${target.name}: expected one Flutter view, found ${flutterViewCount}`,
    );
  }
  const signIn = page.getByText('Continue with Google', { exact: true });
  const signInCount = await signIn.count();
  // Flutter does not expose its semantics tree in Android touch emulation,
  // even after the accessibility placeholder is activated. The rendered
  // screenshot plus title/view/error assertions cover that context.
  if (!target.isMobile && signInCount !== 1) {
    throw new Error(`${target.name}: expected one Google sign-in action, found ${signInCount}`);
  }
  if (!target.isMobile && !(await signIn.isVisible())) {
    throw new Error(`${target.name}: sign-in action is not visible`);
  }

  await page.screenshot({
    path: path.join(output, `sign-in-${target.name}.png`),
    fullPage: true,
  });
  results.push({
    target: target.name,
    title,
    flutterViewCount,
    signInCount,
    errors,
  });
  await context.close();
}

await browser.close();

const fatalErrors = results.flatMap((result) =>
  result.errors.filter((message) =>
    !message.includes('ERR_BLOCKED_BY_CLIENT') &&
    !message.includes('google-analytics.com'),
  ),
);
console.log(JSON.stringify(results, null, 2));
if (fatalErrors.length) {
  throw new Error(`Browser errors detected:\n${fatalErrors.join('\n')}`);
}
