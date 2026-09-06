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
    await visible(page, 'Instant-Test — Front-End Prototypes');
    await button(page, 'Device details').waitFor();
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
  await check('weak-device-finding', async p=>{
    await button(p,'Troubleshoot these devices').click();
    await button(p,'Office-Printer 2.4 GHz').click();
    await visible(p,'Help for Office-Printer');
    await visible(p,'Link rate');
    assert.equal(await button(p,'Yes — I can see it').count(),0);
    assert.match(p.url(),/instant=31/);
  });
  await check('mesh-health',async p=>{
    await visible(p,'Weak backhaul');
    await button(p,'Network details').click();
    await visible(p,'Connected wirelessly — Weak (45 Mbps)');
    assert.equal(await p.getByText('Connected wirelessly — Good (45 Mbps)',{exact:true}).count(),0);
  });
  await check('diagnostic-completion',async p=>{
    await button(p,"Internet isn't working").click();
    await visible(p,'Diagnostics complete');
    assert.equal(await p.getByText('Running diagnostics…',{exact:true}).count(),0);
  });
  await check('browser-history',async p=>{
    await button(p,'Device details').click();
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
    await button(p,'Office-Printer 2.4 GHz').click();
    await visible(p,'Device keeps dropping WiFi');
    await p.goBack();await button(p,'Choose the affected device').waitFor();
    await p.goForward();await button(p,'Office-Printer 2.4 GHz').waitFor();
    await p.reload();await button(p,'Office-Printer 2.4 GHz').waitFor();
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
    await activate("Device won't connect");await button(p,'Office-Printer 2.4 GHz').waitFor();
    await activate('Office-Printer 2.4 GHz');await button(p,'Yes — I can see it').waitFor();
    await activate('Yes — I can see it');await visible(p,'Check your WiFi details');
  },true);
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
