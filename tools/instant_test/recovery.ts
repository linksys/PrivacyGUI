import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import {mkdir,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
// Run explicitly against one registered device. Credentials stay inside this process.
assert(process.argv[3] === '--reconnect-and-restart', 'Explicit recovery mode required');
const mac=process.argv[2];
const clientMac=process.argv[4];
const clientName=process.argv[5];
assert.match(clientMac||'', /^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/i);
assert(clientName, 'Client display name required');
assert.match(mac||'',/^(?:[0-9a-f]{2}:){5}[0-9a-f]{2}$/i,'Supply the registered hardware MAC');
const mcpRoot=process.env.LINKSYS_MCP_ROOT||fileURLToPath(new URL('../../../linksys-mcp/',import.meta.url));
const {loadRegistry,resolveDevice,resolveCredential,DeviceIdentityVerifier}=await import(join(mcpRoot,'packages/common/src/index.ts'));
const {default:pino}=await import(join(mcpRoot,'node_modules/pino/pino.js'));
const device=resolveDevice(loadRegistry({scope:'devices'}),mac);
const verified=await new DeviceIdentityVerifier(pino({level:'silent'})).verify(device);
const origin=`https://${verified.device.host}`;
const output=fileURLToPath(new URL('./artifacts/recovery/',import.meta.url));
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
let rebootSent=false;
let reconnectSent=false;
await page.route('**/JNAP/',async route=>{const req=route.request();const action=req.headers()['x-jnap-action']?.split('/').pop()||'';const data=req.postDataJSON();
 const unchangedFirmwareSettings=action==='SetFirmwareUpdateSettings'&&currentFirmwareSettings&&data?.updatePolicy===currentFirmwareSettings.updatePolicy&&JSON.stringify(data?.autoUpdateWindow)===JSON.stringify(currentFirmwareSettings.autoUpdateWindow);
 const setupAcknowledgement=action==='SetUserAcknowledgedAutoConfiguration'&&data&&Object.keys(data).length===0;
 if(setupAcknowledgement||unchangedFirmwareSettings)setupRequests.push(action);
 const recovery=(action==='Reboot'&&!rebootSent&&Object.keys(data||{}).length===0)||(action==='ClientDeauth'&&!reconnectSent&&data?.macAddress?.toLowerCase()===clientMac.toLowerCase());
 if(recovery){if(action==='Reboot')rebootSent=true;else reconnectSent=true;}
 const permitted=recovery||setupAcknowledgement||unchangedFirmwareSettings||/^(Get|Check|Is|Has)/.test(action)||(action==='UpdateFirmwareNow'&&data?.onlyCheck===true)||(action==='Transaction'&&Array.isArray(data)&&data.every(a=>/\/(Get|Check|Is|Has)[^/]*$/.test(a.action)));
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

 await click('One device is slow');
 await click(page.getByRole('button',{name:`${clientName} WiFi`,exact:true}));
 await click('Change problem');await click('Keeps disconnecting');
 await click('Force reconnect a device');await click('Reconnect');
 await page.getByText(`${clientName} disconnected — it should reconnect in a moment.`,{exact:true}).waitFor();
 completed.push('reconnect-request-accepted');
 await click('Back to Instant-Test');
 await click('Whole internet is slow');await click('Check my speed');
 await page.getByText("Here's what your connection can do",{exact:true}).waitFor({timeout:60000});
 await click('Everything in my home is slow');
 await click('Restart + Run Speed Test Again');await click('Restart');
 await page.getByText(/Restarting your router/).waitFor();
 completed.push('restart-request-submitted');
 await snap('restart-progress');
 console.log('Waiting for router recovery');
 const deadline=Date.now()+180000;
 let recovered=false;
 await page.waitForTimeout(20000);
 while(Date.now()<deadline){
   try{const r=await context.request.get(`${origin}/`,{timeout:3000});if(r.ok()){recovered=true;break;}}catch{}
   await page.waitForTimeout(3000);
 }
 assert(recovered,'Router HTTPS did not recover within three minutes');
 await page.screenshot({path:`${output}/after-restart-before-reload.png`});
 // Revalidate the router identity before the browser resumes authenticated work.
 await new DeviceIdentityVerifier(pino({level:'silent'})).verify(device);
 await page.reload();
 await page.getByText('What needs help?',{exact:true}).waitFor({timeout:60000});
 await page.getByText("We didn't detect any issues",{exact:true}).waitFor({timeout:60000});
 completed.push('router-recovered-and-diagnostics-passed');
 await snap('recovered-overview');
 assert.deepEqual(blocked,[]);
 assert.deepEqual(errors,[]);
 pass=true;
}finally{await writeFile(`${output}/results.json`,JSON.stringify({mac,pass,completed,requests,errors,blocked,setupRequests},null,2));await browser.close();}
