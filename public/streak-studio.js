(function(){
"use strict";
function el(tag,attrs,text){var n=document.createElement(tag);Object.keys(attrs||{}).forEach(function(k){n.setAttribute(k,attrs[k]);});if(text!==undefined)n.textContent=text;return n;}
function init(){
 var main=document.querySelector("main");if(!main||document.getElementById("p-streaks"))return;
 var page=el("div",{id:"p-streaks",class:"pg"});page.hidden=true;
 var wrap=el("section",{});page.appendChild(wrap);wrap.appendChild(el("h2",{},"Decision Streak Rewards"));
 wrap.appendChild(el("p",{class:"sub"},"Qualifying days use Bangladesh time (Asia/Dhaka) and require at least five saved decisions. Logins alone do not count. A missed day resets the current streak."));
 var status=el("p",{id:"streak-status",role:"status",class:"sub"},"");
 var panel=el("div",{class:"panel"});panel.appendChild(el("h3",{},"Your streak"));
 var stats=el("div",{class:"grid"});
 [["Today’s completed decisions","streak-today-count"],["Current consecutive days","streak-current"],["Best recorded streak","streak-best"],["Next milestone","streak-next"]].forEach(function(x){var box=el("div",{class:"card"});box.appendChild(el("p",{class:"sub"},x[0]));box.appendChild(el("strong",{id:x[1]},"—"));stats.appendChild(box);});
 panel.appendChild(stats);
 panel.appendChild(el("p",{class:"sub"},"60 consecutive qualifying days: 7 days of Pro. Every 365 consecutive qualifying days: 1 day of Extra Premium. Earned milestones create expiring plan entitlements automatically when this dashboard refreshes. Your existing paid plan is never downgraded by a temporary reward."));
 var refresh=el("button",{type:"button",class:"btn"},"Refresh streak");refresh.addEventListener("click",load);panel.appendChild(refresh);wrap.appendChild(panel);
 var history=el("div",{class:"panel"});history.appendChild(el("h3",{},"Earned milestones"));var list=el("div",{id:"streak-milestones"});history.appendChild(list);wrap.appendChild(history);wrap.appendChild(status);main.appendChild(page);
 function load(){
  var db=window.sb||null,user=window.U||null;
  if(!db||!user){status.textContent="Sign in to view your streak.";return;}
  refresh.disabled=true;status.textContent="Checking qualifying decisions…";
  db.rpc("clario_deliver_streak_rewards").then(function(grants){
   if(grants.error)throw grants.error;
   return db.rpc("clario_refresh_streak");
  }).then(function(res){
   if(res.error)throw res.error;var d=res.data||{};
   document.getElementById("streak-today-count").textContent=String(d.today_decisions||0);
   document.getElementById("streak-current").textContent=String(d.current_streak||0);
   document.getElementById("streak-best").textContent=String(d.best_streak||0);
   document.getElementById("streak-next").textContent=String(d.next_milestone||60)+" days";
   status.textContent=(d.qualifying_today?"Today qualifies.":"Today has not yet qualified.")+" Bangladesh date: "+(d.today||"—")+".";
   return db.from("streak_milestones").select("id,milestone_days,achieved_on,reward_code,created_at").order("created_at",{ascending:false}).limit(100);
  }).then(function(res){
   if(!res)return;if(res.error)throw res.error;list.replaceChildren();
   if(!res.data||!res.data.length){list.appendChild(el("p",{class:"sub"},"No milestones earned yet."));return;}
   res.data.forEach(function(m){list.appendChild(el("p",{},m.milestone_days+" consecutive days · "+(m.reward_code==="pro_7_days"?"7 days of Pro":"1 day of Extra Premium")+" · "+m.achieved_on));});
  }).catch(function(err){status.textContent=err&&err.message?err.message:"Streak service unavailable. Apply migration 202610240010_streak_rewards.sql.";}).finally(function(){refresh.disabled=false;});
 }
 load();window.ClarioStreaks={refresh:load};
}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",init);else init();
})();