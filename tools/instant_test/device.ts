import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import {mkdir,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
// Run explicitly against one registered device. Credentials stay inside this process.
const mac=process.argv[2];
assert.match(mac||'',/^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/i,'Supply the registered hardware MAC');
const mcpRoot=process.env.LINKSYS_MCP_ROOT||fileURLToPath(new URL('../../../linksys-mcp/',import.meta.url));
const {loadRegistry,resolveDevice,resolveCredential,DeviceIdentityVerifier}=await import(join(mcpRoot,'packages/common/src/index.ts'));
const {default:pino}=await import(join(mcpRoot,'node_modules/pino/pino.js'));
const device=resolveDevice(loadRegistry({scope:'devices'}),mac);
const verified=await new DeviceIdentityVerifier(pino({level:'silent'})).verify(device);
const origin=`https://${verified.device.host}`;
const output=fileURLToPath(new URL('./artifacts/device/',import.meta.url));
await mkdir(output,{recursive:true});
const completed=[];
let pass=false;
const browser=await chromium.launch({headless:true});
const context=await browser.newContext({ignoreHTTPSErrors:true,viewport:{width:1440,height:1000},serviceWorkers:'block'});
const page=await context.newPage();const errors=[];const requests=[];
page.on('pageerror',e=>errors.push({message:e.message,stack:e.stack}));
page.on('response',async r=>{if(new URL(r.url()).pathname==='/JNAP/') {try {const d=await r.json();if(r.request().headers()['x-jnap-action']?.endsWith('/GetFirmwareUpdateSettings')&&d.result==='OK')currentFirmwareSettings=d.output;requests.push({action:r.request().headers()['x-jnap-action'],http:r.status(),result:d.result,onlyCheck:r.request().postDataJSON()?.onlyCheck});}catch{}}});
const blocked=[];
let currentFirmwareSettings;
const setupRequests=[];
await page.route('**/JNAP/',async route=>{const req=route.request();const action=req.headers()['x-jnap-action']?.split('/').pop()||'';const data=req.postDataJSON();
 const unchangedFirmwareSettings=action==='SetFirmwareUpdateSettings'&&currentFirmwareSettings&&data?.updatePolicy===currentFirmwareSettings.updatePolicy&&JSON.stringify(data?.autoUpdateWindow)===JSON.stringify(currentFirmwareSettings.autoUpdateWindow);
 const setupAcknowledgement=action==='SetUserAcknowledgedAutoConfiguration'&&data&&Object.keys(data).length===0;
 if(setupAcknowledgement||unchangedFirmwareSettings)setupRequests.push(action);
 const permitted=setupAcknowledgement||unchangedFirmwareSettings||/^(Get|Check|Is|Has)/.test(action)||(action==='UpdateFirmwareNow'&&data?.onlyCheck===true)||(action==='Transaction'&&Array.isArray(data)&&data.every(a=>/\/(Get|Check|Is|Has)[^/]*$/.test(a.action)));
 if(!permitted){blocked.push(action);await route.abort();return;}await route.continue();});
try{
 await page.goto(`${origin}/#/dashboardMenu/menuInstantTest`);
 await page.locator('input[type=password]').waitFor({timeout:30000});
 assert(page.url().includes('localLoginPassword'),'Protected route must require login');
 completed.push('unauthenticated-redirect');
 try{await page.locator('input[type=password]').fill(resolveCredential(device.credentialRef));}catch{throw Error('Unable to fill router login');}
 await page.getByRole('button',{name:'Log in',exact:true}).click();
 await page.waitForURL(/#\/dashboard(Home|Menu)(?:[/?]|$)/,{timeout:60000});
 if(page.url().includes('localLoginPassword'))throw Error('Router login did not complete');
 await page.goto(`${origin}/#/dashboardMenu/menuInstantTest`);
 await page.getByText('What needs help?',{exact:true}).waitFor({timeout:30000});
 await page.getByText("We didn't detect any issues",{exact:true}).waitFor({timeout:60000});
 const btn=(name)=>page.getByRole('button',{name,exact:true}).last();
 const click=async name=>{const link=typeof name==='string'?btn(name):name;await link.waitFor();for(let i=0;i<12;i++){const box=await link.boundingBox();if(box&&box.y>=0&&box.y+box.height<990){await link.click();return;}await page.mouse.move(720,700);await page.mouse.wheel(0,box&&box.y<0?-420:420);await page.waitForTimeout(100);}throw Error('Control not reachable');};
 const snap=async name=>{await page.screenshot({path:`${output}/${name}.png`});completed.push(name);console.log(`PASS ${name}`);};
 await snap('live-overview');
 for(const [name,label] of [['internet',"Internet isn't working"],['speed','Whole internet is slow'],['device-connect',"Device won't connect"],['device-slow','One device is slow'],['coverage',"Doesn't reach a room"],['drops','Keeps cutting out']]){
  await click(label);await page.waitForTimeout(1800);
  if(name==='speed'){await click('Check my speed');await page.getByText("Here's what your connection can do",{exact:true}).waitFor({timeout:60000});}
  if(name==='device-connect'){await click(page.getByRole('button',{name:/ WiFi$/}).first());await click('Yes — I can see it');await page.getByText('Check your WiFi details',{exact:true}).waitFor();}
  if(name==='device-slow'){await click(page.getByRole('button',{name:/ WiFi$/}).first());await click('Connection details');await page.getByText('Link rate',{exact:true}).waitFor();await click('Hide connection details');await click('Change problem');await click('Keeps disconnecting');await click('Force reconnect a device');await page.getByText('Force reconnect?',{exact:true}).waitFor();await click('Cancel');await page.getByText('Force reconnect?',{exact:true}).waitFor({state:'hidden'});}
  if(name==='drops'){await click('Every few minutes');await click('All devices');await click('Start connection test');await page.getByText('No drops caught during the test.',{exact:true}).waitFor({timeout:150000});}
  await snap(name);
  await click('Back to Instant-Test');await btn("Internet isn't working").waitFor();
 }
 for(const [name,label] of [['live-devices','View devices'],['live-network','View network']]){await click(label);await page.waitForTimeout(800);await snap(name);await click('Back to Instant-Test');}
 assert.deepEqual(blocked,[],'Unexpected setting-changing request');
 assert.deepEqual(errors,[],'Uncaught browser errors');
 await context.clearCookies();
 await page.evaluate(()=>{localStorage.clear();sessionStorage.clear();});
 await page.reload();
 await page.locator('input[type=password]').waitFor({timeout:30000});
 completed.push('cleared-session-redirect');
 console.log('PASS cleared-session-redirect');
 assert.deepEqual(errors,[],'Uncaught errors after session removal');
 pass=true;
}finally{await writeFile(`${output}/results.json`,JSON.stringify({mac,pass,completed,requests,errors,blocked,setupRequests},null,2));await browser.close();}
