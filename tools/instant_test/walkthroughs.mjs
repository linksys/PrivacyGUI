import assert from 'node:assert/strict';

// Feature-path acceptance against the isolated preview. Probe query values are
// consumed only by PrototypeRoot; they cannot configure the real router route.
export async function walkthroughs({check,button,visible,clickInScrollView,url}) {
  const click=(p,target)=>clickInScrollView(p,typeof target==='string'?button(p,target).last():target);
  const tap=(p,label)=>click(p,p.getByText(label,{exact:false}).last());
  // Some transient overlay messages have painted HTML before semantics catches up.
  const contentText=(p,text)=>p.locator('body').getByText(text,{exact:false}).filter({visible:true}).last().waitFor();
  async function open(p,probe='healthy',flow) {
    const target=new URL(url);
    const query=new URLSearchParams({probe});
    if(flow)query.set('instant',String(flow));
    target.hash=`/instant-prototype?${query}`;
    await p.goto('about:blank');
    await p.goto(target.href);
    await visible(p,'Instant-Test preview');
  }
  async function guide(p,steps) {
    for(let i=1;i<steps;i++) await click(p,button(p,'Try the next step').first());
    await visible(p,`Step ${steps} of ${steps}`);
    if(steps>1) await click(p,button(p,'Previous step').first());
  }
  async function tick(p,ms) {
    await p.clock.fastForward(ms);
    await p.clock.runFor(40);
  }
  await check('restart-request-rejected', async p => {
    await open(p, 'restartRejected');
    await click(p, 'Restart Router'); await click(p, 'Restart');
    await contentText(p, 'The restart could not be confirmed');
    assert.equal(await p.getByText(/Restarting your router/).count(), 0);
  });
  await check('reconnect-request-rejected', async p => {
    await open(p, 'reconnectRejected');
    await click(p, 'One device is slow'); await click(p, 'Office-Printer WiFi');
    await click(p, 'Change problem'); await click(p, 'Keeps disconnecting');
    await click(p, 'Force reconnect a device'); await click(p, 'Reconnect');
    await contentText(p, 'The reconnect request could not be confirmed');
    assert.equal(await p.getByText(/Office-Printer disconnected/).count(), 0);
  });
  for(const [probe,result,heading] of [
    ['gatewayDown',"Your device can't reach the router",'Check your connection to the router'],
    ['internetDown',"Your router can't reach the internet",'Check the connection to your modem'],
    ['dnsFailure',"Your router is online, but websites aren't loading",'Try restarting your router'],
    ['probeError','Connection check could not finish','Try the connection check again'],
  ]) {
    await check(`internet-${probe}`,async p=>{
      await open(p,probe,1); await visible(p,result); await visible(p,heading);
      assert.equal(await p.getByText('This device reached your router',{exact:true}).count(),0);
      await click(p,'View test details'); await click(p,'Hide test details');
      if(probe==='gatewayDown'||probe==='internetDown') await guide(p,3);
      if(probe==='probeError') {
        await click(p,'Try connection check again');await visible(p,result);
        await open(p,'healthy',1);await visible(p,'Your router can reach the internet');
      }
      if(probe==='dnsFailure') {
        await click(p,'Restart Router');await click(p,'Cancel');
        assert.equal(await p.getByText('Diagnostics ran again after restart.',{exact:true}).count(),0);
        await click(p,'Restart Router');await click(p,'Restart');
        await p.getByText(/Restarting your router/).waitFor();await p.keyboard.press('Escape');
        await visible(p,'Diagnostics ran again after restart.');
        await visible(p,"If restarting didn't fix it:");
        await contentText(p,'Not loading');
      }
      if(probe==='internetDown') await click(p,'Done — my internet is working now');
      else await click(p,'Back to Instant-Test');
      await button(p,"Internet isn't working").waitFor();
    },probe==='gatewayDown');
  }
  await check('speed-failure-retry',async p=>{
    await open(p,'speedError',2);await click(p,'Check my speed');
    await contentText(p,'The speed check could not finish');
    assert.equal(await p.getByText("Here's what your connection can do",{exact:true}).count(),0);
    await click(p,'Check my speed');await contentText(p,'no speed conclusion is available');
    await open(p,'healthy',2);await click(p,'Check my speed');
    await visible(p,"Here's what your connection can do");
  });
  for(const probe of ['healthy','slowSpeed','laggySpeed']) {
    await check(`speed-${probe}`,async p=>{
      await open(p,probe,2);await click(p,'Check my speed');
      await visible(p,"Here's what your connection can do");
      await click(p,'View speed test details');await click(p,'Hide speed test details');
      if(probe==='laggySpeed') {
        await click(p,'Games or video calls are laggy');await visible(p,'Latency / lag troubleshooting');
        await guide(p,3);await click(p,'Done');
      } else {
        await click(p,'Everything in my home is slow');
        await click(p,'Restart + Run Speed Test Again');await click(p,'Cancel');
        await button(p,'Restart + Run Speed Test Again').waitFor();
        await click(p,'Skip — already restarted');await visible(p,'Contact your internet provider');
        await click(p,'Done');
      }
      await button(p,"Internet isn't working").waitFor();
    },probe==='slowSpeed');
  }
  for(const probe of ['healthy','slowSpeed','speedAfterRestartError']) {
    await check(`speed-restart-${probe}`,async p=>{
      await open(p,probe,2);await click(p,'Check my speed');
      await click(p,'Everything in my home is slow');
      await click(p,'Restart + Run Speed Test Again');await click(p,'Restart');
      await p.getByText(/Restarting your router/).waitFor();await p.keyboard.press('Escape');
      if(probe==='speedAfterRestartError') {
        await contentText(p,'The speed check after restart could not finish');
        assert.equal(await p.getByText('Contact your internet provider',{exact:true}).count(),0);
        await button(p,'Check my speed').waitFor();
      } else {
        await visible(p,probe==='healthy'?"Here's what your connection can do":'Contact your internet provider');
        if(probe==='slowSpeed')await contentText(p,'3 Mbps down');
      }
    });
  }
  await check('speed-device-handoff',async p=>{
    await click(p,'Whole internet is slow');await click(p,'Check my speed');
    await click(p,'Just one specific device');await click(p,'Office-Printer WiFi');
    await visible(p,'Weak WiFi signal');
    await click(p,'Back to speed check');
    await visible(p,"Here's what your connection can do");
  });
  await check('device-manual-and-wired',async p=>{
    await click(p,"Device won't connect");await click(p,'Office-Printer WiFi');
    await click(p,'Yes — I can see it');await visible(p,'Check your WiFi details');
    await guide(p,4);await click(p,'Device is connected now');
    await click(p,"Device won't connect");await click(p,"I don't see my device");
    await click(p,"No — I don't see it");
    await visible(p,"We checked your router's WiFi — here's what we found");
    await click(p,'My device uses an Ethernet cable');await visible(p,'Wired device troubleshooting');
    await guide(p,5);await click(p,'Problem solved');
    await button(p,"Device won't connect").waitFor();
  },true);
  await check('device-problem-switching',async p=>{
    await click(p,'One device is slow');await click(p,'Office-Printer WiFi');
    await click(p,'Connection details');await visible(p,'Band');await click(p,'Hide connection details');
    await click(p,'Why this might help');await click(p,'Hide why this might help');
    await click(p,'More things to try');await click(p,'Hide more things to try');
    await click(p,'Change problem');await click(p,'Something else');
    await visible(p,'General troubleshooting');await guide(p,4);
    await click(p,'Keeps disconnecting');await visible(p,'Device keeps dropping WiFi');
    await guide(p,3);await click(p,'Force reconnect a device');
    await visible(p,'Force reconnect?');await click(p,'Reconnect');
    await contentText(p,/Office-Printer disconnected/);
    await click(p,'Device stopped dropping');await button(p,'One device is slow').waitFor();
  });
  await check('coverage-placement-options',async p=>{
    await click(p,"Doesn't reach a room");
    for(const label of ['Center of my home or close to it','Near a wall, door, or in a corner','Inside a closet, cabinet, or behind the TV']) {
      await click(p,p.getByRole('radio',{name:label,exact:true}));await visible(p,'Placement tip');
    }
    await click(p,'More coverage tips');await visible(p,'Need more coverage?');
    await click(p,'Hide more coverage tips');await click(p,'Done');
    await button(p,"Doesn't reach a room").waitFor();
  },true);
  for(const [probe,frequency,expected] of [
    ['healthy','Every few minutes','No drops caught during the test.'],
    ['healthy','A few times a day','No drops detected right now.'],
    ['monitorDrops','Every few minutes','5 drops detected during the test'],
    ['probeError','Every few minutes','The connection check could not finish. Try again; no conclusion is available.'],
  ]) {
    await check(`monitor-${probe}-${frequency==='Every few minutes'?'frequent':'occasional'}`,async p=>{
      await open(p,probe,5);await click(p,frequency);await click(p,'All devices');
      await p.clock.install();await click(p,'Start connection test');
      for(let i=0;i<(probe==='probeError'?1:5);i++)await tick(p,24000);
      await visible(p,expected);
      if(probe==='monitorDrops') {
        await click(p,'Restart Router');await click(p,'Cancel');
        await tick(p,31000);await visible(p,expected);
      }
      if(probe==='probeError')await button(p,'Start connection test').waitFor();
      if(probe==='monitorDrops'||(probe==='healthy'&&frequency==='Every few minutes')) {
        await click(p,'Restart Router');await click(p,'Restart');
        await p.getByText(/Restarting your router/).waitFor();await p.keyboard.press('Escape');
        for(let i=0;i<3;i++)await tick(p,10000);
        await visible(p,probe==='monitorDrops'?'Still dropping after restart':'Looks like the restart fixed it!');
        await click(p,probe==='monitorDrops'?"I'll call my provider":'Done');
      }
    });
  }
  for(const [label,heading,done] of [
    ['Enable bridge mode on the ISP gateway','Enabling bridge mode','Done'],
    ['Switch Linksys to WiFi access point mode','Switch Linksys to access point mode','Done'],
    ['Leave it as two routers — contact my internet provider','Contact your internet provider','Done'],
    ['Leave as-is — internet is working fine',null,'Got it — my internet is working'],
  ]) {
    await check(`two-routers-${done==='Done'?heading.split(' ')[0].toLowerCase():'leave'}`,async p=>{
      await open(p,'healthy',6);await visible(p,'Two routers detected');await tap(p,label);
      if(heading)await visible(p,heading);
      await click(p,done);await button(p,"Internet isn't working").waitFor();
    });
  }
  await check('router-light-guide',async p=>{
    await click(p,'What does my router light mean?');
    for(const text of ['Solid white','Pulsing blue','Solid red','Solid yellow','Solid green','Off'])assert.equal(await p.getByText(text,{exact:true}).count(),1);
    await p.keyboard.press('Escape');await button(p,"Internet isn't working").waitFor();
  },true);
  for(const title of ['No internet connection',"Websites aren't loading",'Slow internet + weak WiFi','Router overloaded + mesh issues','Configuration blocks']) {
    await check(`overview-${title.split(' ')[0].toLowerCase()}`,async p=>{
      await click(p,'Test scenarios');await tap(p,title);
      await click(p,'View test details');await p.getByText(/Router reached/).waitFor();
      await click(p,p.locator('flt-semantics[flt-tappable]').filter({hasText:'Router reached'}).last());await p.getByText(/We connected to your router/).waitFor();
      await click(p,'Hide test details');
      await p.goto(p.url().replace(/([?&])instant=[^&]*/,'$1').replace(/[?&]$/,'') + (p.url().includes('?') ? '&' : '?') + 'instant=network');await visible(p,'Your Network');
      if(title==='Slow internet + weak WiFi') {
        await click(p,'Update Now');await visible(p,'Your Network');
      }
      await click(p,'Back to Instant-Test');await click(p,'One device is slow');
      await click(p,'Back to Instant-Test');
      await button(p,"Internet isn't working").waitFor();
    });
  }
}
