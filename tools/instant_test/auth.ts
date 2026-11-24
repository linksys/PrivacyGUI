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
const output=fileURLToPath(new URL(process.argv[3] === '--quick' ? './artifacts/auth-quick/' : './artifacts/auth/',import.meta.url));
await mkdir(output,{recursive:true});
const completed=[];
let pass=false;
const browser=await chromium.launch({headless:true});
const context=await browser.newContext({ignoreHTTPSErrors:true,viewport:{width:1440,height:1000},serviceWorkers:'block'});
const page=await context.newPage();const errors=[];const requests=[];let phase='login';
page.on('pageerror',e=>errors.push({message:e.message,stack:e.stack,phase,time:Date.now()}));
page.on('response',async r=>{if(new URL(r.url()).pathname==='/JNAP/') {try {const d=await r.json();if(r.request().headers()['x-jnap-action']?.endsWith('/GetFirmwareUpdateSettings')&&d.result==='OK')currentFirmwareSettings=d.output;requests.push({phase,time:Date.now(),action:r.request().headers()['x-jnap-action'],http:r.status(),result:d.result,onlyCheck:r.request().postDataJSON()?.onlyCheck});}catch{}}});
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
 await page.waitForLoadState('networkidle', {timeout:30000});
 await page.goto(`${origin}/#/dashboardMenu/menuInstantTest`);
 await page.getByText('What needs help?',{exact:true}).waitFor({timeout:30000});
 await page.getByText("We didn't detect any issues",{exact:true}).waitFor({timeout:60000});
 const rejectAuth = async (route) => {
   const req=route.request();
   const headers={...req.headers()};
   delete headers['x-jnap-authorization'];
   await route.fallback({headers});
 };
 phase='rejection';
 await page.route('**/JNAP/', rejectAuth);
 await page.reload();
 await page.locator('input[type=password]').waitFor({timeout:60000});
 assert(page.url().includes('localLoginPassword'));
 await page.screenshot({path:`${output}/rejected-auth.png`});
 completed.push('real-router-rejected-auth-redirect');
 console.log('PASS real-router-rejected-auth-redirect');
 await page.waitForTimeout(2500);
 phase='reauthentication';
 await page.unroute('**/JNAP/', rejectAuth);
 await page.waitForLoadState('networkidle', {timeout:30000});
 try{await page.locator('input[type=password]').fill(resolveCredential(device.credentialRef));}catch{throw Error('Unable to fill router login');}
 await page.getByRole('button',{name:'Log in',exact:true}).click();
 await page.waitForURL(/#\/dashboard(Home|Menu)(?:[/?]|$)/,{timeout:60000});
 await page.waitForLoadState('networkidle', {timeout:30000});
 await page.goto(`${origin}/#/dashboardMenu/menuInstantTest`);
 await page.getByText('What needs help?',{exact:true}).waitFor();
 await page.getByText("We didn't detect any issues",{exact:true}).waitFor({timeout:60000});
 completed.push('reauthentication');
 console.log('PASS reauthentication');
 if(process.argv[3] !== '--quick') {
 phase='idle';
 await page.locator('input[type=password]').waitFor({timeout:330000});
 completed.push('five-minute-idle-redirect');
 console.log('PASS five-minute-idle-redirect');
 }
 assert.deepEqual(blocked,[],'Unexpected setting-changing request');
 assert.deepEqual(errors,[],'Uncaught browser errors');
 pass=true;
}finally{await writeFile(`${output}/results.json`,JSON.stringify({mac,pass,completed,requests,errors,blocked,setupRequests},null,2));await browser.close();}
