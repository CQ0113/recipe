import fs from 'node:fs/promises';
import path from 'node:path';
import { chromium } from 'playwright';

const baseUrl = process.argv[2] ?? 'http://127.0.0.1:7357';
const output = path.resolve('artifacts', 'validation');
await fs.mkdir(output, { recursive: true });

const browser = await chromium.launch({ headless: true });
const results = [];

for (const target of [
  { name: 'desktop', width: 1440, height: 960, scale: 1 },
  { name: 'mobile', width: 390, height: 844, scale: 1 },
]) {
  const context = await browser.newContext({
    viewport: { width: target.width, height: target.height },
    deviceScaleFactor: target.scale,
  });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (error) => errors.push(`pageerror: ${error.message}`));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(`console: ${message.text()}`);
  });

  const response = await page.goto(baseUrl, { waitUntil: 'networkidle', timeout: 45_000 });
  if (!response?.ok()) throw new Error(`${target.name} returned HTTP ${response?.status()}`);
  await page.waitForTimeout(1500);

  const semantics = page.locator('flt-semantics-placeholder');
  if (await semantics.count()) {
    await semantics.press('Enter');
    await page.waitForTimeout(300);
  }

  const title = await page.title();
  if (!title.startsWith('Savora')) throw new Error(`Unexpected title: ${title}`);
  const signIn = page.getByText('Continue with Google', { exact: true });
  const signInCount = await signIn.count();
  if (signInCount !== 1) {
    throw new Error(`${target.name}: expected one Google sign-in action, found ${signInCount}`);
  }
  if (!(await signIn.isVisible())) throw new Error(`${target.name}: sign-in action is not visible`);

  await page.screenshot({
    path: path.join(output, `sign-in-${target.name}.png`),
    fullPage: true,
  });
  results.push({ target: target.name, title, signInCount, errors });
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
