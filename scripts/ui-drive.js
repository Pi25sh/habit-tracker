// Drive the Flutter web app by coordinates (CanvasKit renders to canvas, layout
// is deterministic at a fixed viewport): login -> new habit -> complete -> verify.
const { chromium } = require('playwright');

const APP = 'http://localhost:5178';
const API = 'http://localhost:8010/api/v1';
const EMAIL = `ui-test-${Date.now()}@test.dev`;
const PASSWORD = 'UiTestPass123';
const SHOTS = 'C:/Users/piyus/Projects/habit-tracker/screenshots';
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function main() {
  const reg = await fetch(`${API}/auth/register`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASSWORD, full_name: 'UI Tester' }),
  });
  console.log('register:', reg.status);

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 850 } });
  page.on('console', (m) => { if (m.type() === 'error') console.log('console-error:', m.text().slice(0, 200)); });

  await page.goto(APP);
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
  await sleep(12000);

  // --- LOGIN (fields centered at x=640; see 01-login.png) ---
  await page.mouse.click(640, 373);            // Email field
  await sleep(500);
  await page.keyboard.type(EMAIL, { delay: 15 });
  await page.mouse.click(640, 437);            // Password field
  await sleep(500);
  await page.keyboard.type(PASSWORD, { delay: 15 });
  await page.screenshot({ path: `${SHOTS}/02-filled.png` });
  await page.mouse.click(640, 505);            // Sign in
  console.log('clicked sign in');
  await sleep(10000);
  await page.screenshot({ path: `${SHOTS}/03-home.png` });

  // --- CREATE HABIT: FAB "New habit" bottom-right of the body area ---
  await page.mouse.click(1150, 780);
  await sleep(5000);
  await page.screenshot({ path: `${SHOTS}/04-editor.png` });

  // Habit name field is the first input near the top of the editor.
  await page.mouse.click(640, 140);
  await sleep(500);
  await page.keyboard.type('Drink water', { delay: 15 });
  await page.screenshot({ path: `${SHOTS}/05-editor-filled.png` });

  // Scroll to the bottom of the form and click "Create habit".
  await page.mouse.move(640, 500);
  await page.mouse.wheel(0, 900);
  await sleep(1500);
  await page.screenshot({ path: `${SHOTS}/06-editor-bottom.png` });

  // Verify via API whether the button click landed after we find its position
  // from the screenshot; try a few candidate Y positions.
  for (const y of [770, 720, 660, 600]) {
    await page.mouse.click(640, y);
    await sleep(2500);
    const login0 = await fetch(`${API}/auth/login`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: EMAIL, password: PASSWORD }),
    }).then(r => r.json());
    const habits0 = await fetch(`${API}/habits`, {
      headers: { Authorization: `Bearer ${login0.access_token}` },
    }).then(r => r.json());
    if (Array.isArray(habits0) && habits0.length) { console.log('created at y=', y); break; }
  }
  await sleep(3000);
  await page.screenshot({ path: `${SHOTS}/07-home-with-habit.png` });

  // --- COMPLETE IT: checkbox at the right edge of the habit tile ---
  await page.mouse.click(1215, 180);
  await sleep(1000);
  await page.mouse.click(1195, 180);
  await sleep(4000);
  await page.screenshot({ path: `${SHOTS}/08-completed.png` });

  await browser.close();

  // --- INDEPENDENT VERIFICATION through the API ---
  const login = await fetch(`${API}/auth/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASSWORD }),
  }).then(r => r.json());
  const habits = await fetch(`${API}/habits`, {
    headers: { Authorization: `Bearer ${login.access_token}` },
  }).then(r => r.json());
  console.log('VERIFY habits:', JSON.stringify(
    habits.map(h => ({ name: h.name, streak: h.current_streak }))));
  if (habits.length) {
    const hist = await fetch(`${API}/habit-history?habit_id=${habits[0].id}`, {
      headers: { Authorization: `Bearer ${login.access_token}` },
    }).then(r => r.json());
    console.log('VERIFY history:', JSON.stringify(hist));
  }
}

main().catch(e => { console.error('FATAL', String(e).slice(0, 300)); process.exit(1); });
