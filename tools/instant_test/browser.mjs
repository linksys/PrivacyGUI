import assert from 'node:assert/strict';
import {mkdir, writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {chromium} from 'playwright';

const url = process.argv[2] || 'http://127.0.0.1:8105/#/instant-prototype';
const target = new URL(url);
assert(['127.0.0.1', 'localhost', '[::1]'].includes(target.hostname), 'This harness is for a local simulated preview.');
assert.equal(target.hash, '#/instant-prototype', 'Use the clean prototype URL, without workflow parameters.');
const output = fileURLToPath(new URL('./artifacts/', import.meta.url));
await mkdir(output, {recursive:true});
const browser = await chromium.launch({headless:true});
const results = [];
const expected404s = ['/assets/roboto/', '/assets/notosanssymbols/', '/assets/assets/resources/versions.json'];
const button = (page, name) => page.getByRole('button', {name, exact:true});
const visible = (page, text) => page.getByText(text, {exact:true}).last().waitFor({state:'visible', timeout:10000});
// Flutter scrolls its canvas viewport; reveal the contextual links with real
// scrolling rather than only moving their accessibility elements in the DOM.
async function clickInScrollView(page, label) {
  const link = button(page,label);
  await link.waitFor();
  for (let n=0;n<12;n++) {
    const box = await link.boundingBox();
    const size = page.viewportSize();
    if (box && box.y >= 0 && box.y + box.height < size.height) {
      await link.click();return;
    }
    await page.mouse.move(size.width/2,size.height*0.7);
    await page.mouse.wheel(0,box && box.y < 0 ? -420 : 420);
    await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
  }
  throw Error(`Could not reach ${label} in the scrollable page`);
}
async function check(name, run, mobile = false) {
  const context = await browser.newContext({viewport:mobile ? {width:390,height:844} : {width:1440,height:1000}, colorScheme:mobile?'light':'dark'});
  const page = await context.newPage();
  const errors=[], failures=[], known=[];
  page.on('pageerror', e => errors.push(e.message));
  page.on('requestfailed', request => {
    if (!request.failure()?.errorText.includes('ERR_ABORTED')) failures.push({url:request.url(), error:request.failure()?.errorText});
  });
  page.on('response', response => {
    if (response.status() < 400) return;
    const item={url:response.url(),status:response.status()};
    if (response.status() === 404 && expected404s.some(path=>new URL(response.url()).pathname.startsWith(path))) known.push(item);
    else failures.push(item);
  });
  try {
    await page.goto(url);
    await visible(page, 'Instant-Test preview');
    await visible(page, 'What needs help?');
    for (const oldLayout of ['Single page', 'Home card', 'A · 2-tab + glance', 'B · Verify top-tab', 'Current · 4-tab']) {
      assert.equal(await page.getByText(oldLayout,{exact:true}).count(),0,'Retired preview layout is still visible');
    }
    assert.equal(await button(page,'Device details').count(),0);
    assert.equal(await button(page,'Network details').count(),0);
    await run(page);
    await page.screenshot({path:`${output}/${name}.png`,fullPage:false});
    assert.deepEqual(errors, [], 'Uncaught browser errors');
    assert.deepEqual(failures, [], 'Unexpected failed requests');
    results.push({name,pass:true,knownAssetFailures:known});
    console.log(`PASS ${name}`);
  } catch(error) {
    await page.screenshot({path:`${output}/${name}-failure.png`,fullPage:false});
    results.push({name,pass:false,error:String(error),errors,failures,knownAssetFailures:known});
    console.error(`FAIL ${name}: ${error.message}`);
  } finally {await context.close();}
}
try {
  for (const mobile of [false,true]) {
    await check(mobile?'compact-followup-mobile':'compact-followup-wide',async p=>{
      if (!mobile) await p.setViewportSize({width:2048,height:1100});
      const start=await button(p,"Internet isn't working").boundingBox();
      const end=await button(p,'Keeps cutting out').boundingBox();
      if (!mobile) assert(end.x+end.width-start.x>1800,'Wide layout still wastes the available width');
      await button(p,"Internet isn't working").click();
      await visible(p,'Still seeing an issue?');
      assert.equal(await p.getByText(/Everything looks fine right now/).count(),0);
      await p.getByText(/The connection looks healthy/).waitFor();
      const action=await button(p,'Yes — troubleshoot a specific device').boundingBox();
      assert(action.width<420,'Follow-up action should fit its label');
      assert(action.x>=0 && action.x+action.width<=p.viewportSize().width);
      const support=p.getByText('Still need help?',{exact:true});
      assert.equal(await support.count(),1,'Support should appear once in the shared footer');
      const supportBox=await support.boundingBox();
      const returnBox=await button(p,'Back to Instant-Test').last().boundingBox();
      assert(supportBox.y>returnBox.y+returnBox.height,'Support must follow the page actions');
      await p.screenshot({path:`${output}/followup-${mobile?'mobile':'wide'}.png`});
      await clickInScrollView(p,'Yes — troubleshoot a specific device');
      await button(p,'Office-Printer WiFi').waitFor();
    },mobile);
  }
  for (const mobile of [false,true]) {
    await check(mobile?'home-actions-mobile':'home-actions-desktop',async p=>{
      const labels=["Internet isn't working",'Whole internet is slow','Keeps cutting out','One device is slow',"Device won't connect","Doesn't reach a room"];
      for(const label of labels) {
        const tile=button(p,label);
        assert.equal(await tile.count(),1);
        const box=await tile.boundingBox();
        assert(box.x>=0 && box.x+box.width<=p.viewportSize().width,'Action tile exceeds the viewport');
      }
      const last=await button(p,"Doesn't reach a room").boundingBox();
      const details=await button(p,'View devices').boundingBox();
      assert(details.y>last.y+last.height,'Detail links must follow the action section and diagnostics');
    },mobile);
  }
  for (const mobile of [false,true]) {
    await check(mobile?'optional-details-mobile':'optional-details-desktop',async p=>{
      assert.equal(await p.getByText('Test details',{exact:true}).count(),0);
      await clickInScrollView(p,'View test details');
      await button(p,'Hide test details').waitFor();
      await clickInScrollView(p,'Hide test details');
      await clickInScrollView(p,'One device is slow');
      await button(p,'Office-Printer WiFi').click();
      await visible(p,'Weak WiFi signal');
      assert.equal(await button(p,'Office-Printer WiFi').count(),0,'Device list should collapse after selection');
      assert.equal(await p.getByText('Band',{exact:true}).count(),0);
      if (mobile) {
        await clickInScrollView(p,'Connection details');
      } else {
        await button(p,'Connection details').focus();
        await p.keyboard.press('Enter');
      }
      await visible(p,'Band');
      await clickInScrollView(p,'Hide connection details');
      await p.getByText('Band',{exact:true}).waitFor({state:'detached'});
      assert.equal(await p.getByText('Band',{exact:true}).count(),0);
      await clickInScrollView(p,'Change device');
      await button(p,'Office-Printer WiFi').waitFor();
      await clickInScrollView(p,'Hide change device');
      await clickInScrollView(p,'Change problem');
      await clickInScrollView(p,'Keeps disconnecting');
      await clickInScrollView(p,'Hide change problem');
      await clickInScrollView(p,'Try the next step');
      await visible(p,'Forget this WiFi network on the device, then reconnect fresh. Have your WiFi password ready.');
      await clickInScrollView(p,'Previous step');
      await visible(p,'Move the device closer to your router or a child node');
    },mobile);
  }
  await check('weak-device-finding', async p=>{
    await clickInScrollView(p,'Troubleshoot these devices');
    await button(p,'Office-Printer WiFi').click();
    await visible(p,'Help for Office-Printer');
    assert.equal(await p.getByText('Link rate',{exact:true}).count(),0);
    await visible(p,'Try this first');
    await button(p,'Connection details').click();
    await visible(p,'Link rate');
    assert.equal(await button(p,'Yes — I can see it').count(),0);
    assert.match(p.url(),/instant=31/);
  });
  await check('mesh-health',async p=>{
    await visible(p,'A WiFi node has a weak connection.');
    await clickInScrollView(p,'View network');
    await visible(p,'Connected wirelessly — Weak (45 Mbps)');
    assert.equal(await p.getByText('Connected wirelessly — Good (45 Mbps)',{exact:true}).count(),0);
  });
  await check('diagnostic-completion',async p=>{
    await button(p,"Internet isn't working").click();
    await visible(p,'Your router can reach the internet');
    assert.equal(await p.getByText('This device reached your router',{exact:true}).count(),0,'Outcome must be visible while individual checks remain collapsed');
    assert.equal(await p.getByText('Running diagnostics…',{exact:true}).count(),0);
  });
  await check('browser-history',async p=>{
    await clickInScrollView(p,'View devices');
    await button(p,'Back to Instant-Test').waitFor();
    assert.match(p.url(),/instant=devices/);
    await p.goBack();await button(p,'Whole internet is slow').waitFor();
    await p.goForward();await button(p,'Back to Instant-Test').waitFor();
    await p.reload();await button(p,'Back to Instant-Test').waitFor();
    await button(p,'Back to Instant-Test').click();
    await button(p,'Whole internet is slow').waitFor();
    assert(!p.url().includes('instant='));
  });
  await check('lateral-history',async p=>{
    await button(p,'Keeps cutting out').click();
    await button(p,'A few times a day').click();
    await button(p,'Specific devices').click();
    await button(p,'Choose the affected device').click();
    await button(p,'Office-Printer WiFi').click();
    await visible(p,'Device keeps dropping WiFi');
    await p.goBack();await button(p,'Choose the affected device').waitFor();
    await p.goForward();await button(p,'Office-Printer WiFi').waitFor();
    await p.reload();await button(p,'Office-Printer WiFi').waitFor();
    assert.equal(await button(p,'Device stopped dropping').count(),0, 'Refresh must not restore device data');
    await button(p,'Back to connection check').click();
    await button(p,'Start connection test').waitFor();
    assert.equal(await button(p,'Start connection test').isEnabled(),false, 'Refresh must not restart the monitor');
  });
  await check('mobile-keyboard',async p=>{
    async function activate(label) {
      for(let n=0;n<70;n++) {
        await p.keyboard.press('Tab');
        await p.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
        const active=await p.evaluate(()=>document.activeElement?.getAttribute('aria-label')||document.activeElement?.innerText);
        if(active===label){await p.keyboard.press('Enter');return;}
      }
      throw Error(`Not reachable with Tab: ${label}`);
    }
    await activate("Device won't connect");await button(p,'Office-Printer WiFi').waitFor();
    await activate('Office-Printer WiFi');await button(p,'Yes — I can see it').waitFor();
    await activate('Yes — I can see it');await visible(p,'Check your WiFi details');
  },true);
  await check('device-details-handoff',async p=>{
    await clickInScrollView(p,'View devices');
    // Device details exposes an InkWell row with a merged name/band/health label.
    await p.locator('flt-semantics[flt-tappable]').filter({hasText:/^Office-Printer\b/}).first().click();
    await button(p,'Troubleshoot this device').click();
    await visible(p,'Help for Office-Printer');
    assert.match(p.url(),/instant=devices/);
    await button(p,'Back to device details').first().click();
    await visible(p,'4 devices connected');
    // Device details exposes an InkWell row with a merged name/band/health label.
    await p.locator('flt-semantics[flt-tappable]').filter({hasText:/^Office-Printer\b/}).first().click();
    await button(p,'Troubleshoot this device').waitFor();
    await p.keyboard.press('Escape');
  },true);
  await check('confirmation-cancellation',async p=>{
    await button(p,'Restart Router').first().click();
    await visible(p,'Restart your router?');
    await button(p,'Cancel').click();
    await button(p,'Restart Router').first().click();
    await visible(p,'Restart your router?');
    await p.keyboard.press('Escape');
    await button(p,"Device won't connect").click();
    await button(p,'Office-Printer WiFi').click();
    await button(p,'Change problem').click();
    await button(p,'Keeps disconnecting').click();
    await button(p,'Force reconnect a device').click();
    await visible(p,'Force reconnect?');
    await button(p,'Cancel').click();
    await button(p,'Force reconnect a device').click();
    await visible(p,'Force reconnect?');
    await p.keyboard.press('Escape');
    await visible(p,'Device keeps dropping WiFi');
  });
  await check('browser-back-during-confirmation',async p=>{
    await button(p,"Device won't connect").click();
    await button(p,'My device uses an Ethernet cable').click();
    await button(p,'Restart Router').click();
    await visible(p,'Restart your router?');
    await p.goBack();
    await button(p,'Whole internet is slow').waitFor();
    assert.equal(await p.getByText('Restart your router?',{exact:true}).count(),0,
      'Leaving a workflow must dismiss its pending confirmation');
  });
  await check('leave-running-monitor',async p=>{
    await button(p,'Keeps cutting out').click();
    await button(p,'A few times a day').click();
    await button(p,'All devices').click();
    await button(p,'Start connection test').click();
    await p.getByText(/Monitoring…/).waitFor();
    await p.goBack();await button(p,'Whole internet is slow').waitFor();
    await p.goForward();await button(p,'Start connection test').waitFor();
    assert.equal(await button(p,'Start connection test').isEnabled(),false);
    assert.equal(await p.getByText(/Monitoring…/).count(),0);
  });
  await check('remaining-workflows',async p=>{
    await button(p,'Whole internet is slow').click();await button(p,'Check my speed').click();
    await button(p,'Just one specific device').waitFor();
    await button(p,'Back to Instant-Test').last().click();
    await button(p,"Doesn't reach a room").click();await visible(p,'Improve coverage in that room');
    await button(p,'Back to Instant-Test').last().click();
    await button(p,"Device won't connect").click();await button(p,"I don't see my device").click();
    await button(p,"No — I don't see it").click();await visible(p,"We checked your router's WiFi — here's what we found");
    await button(p,'My device uses an Ethernet cable').click();await visible(p,'Wired device troubleshooting');
  });
} finally {
  await writeFile(`${output}/results.json`, JSON.stringify({url,results},null,2));
  await browser.close();
}
if(results.some(result=>!result.pass)) process.exitCode=1;
