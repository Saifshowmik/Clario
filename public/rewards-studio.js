(function(){
"use strict";
function el(tag,attrs,text){var n=document.createElement(tag);Object.keys(attrs||{}).forEach(function(k){n.setAttribute(k,attrs[k]);});if(text!==undefined)n.textContent=text;return n;}
function init(){
 var main=document.querySelector("main");if(!main||document.getElementById("p-rewards"))return;
 var page=el("div",{id:"p-rewards",class:"pg"});page.hidden=true;
 var wrap=el("section",{});page.appendChild(wrap);wrap.appendChild(el("h2",{},"Referrals & Loyalty"));
 wrap.appendChild(el("p",{class:"sub"},"Share your referral code and review eligible rewards. Referral rewards and loyalty points are issued only after a paid subscription is approved. Current reward values depend on the policy configured by Clario’s owner."));
 var status=el("p",{id:"rewards-status",role:"status",class:"sub"},"");
 var panel=el("div",{class:"panel"});panel.appendChild(el("h3",{},"Your referral code"));
 var code=el("code",{id:"rewards-code"},"Sign in to load your code");panel.appendChild(code);
 var copy=el("button",{type:"button",class:"btn s"},"Copy code");copy.addEventListener("click",function(){if(code.textContent&&code.textContent!=="Sign in to load your code"&&navigator.clipboard){navigator.clipboard.writeText(code.textContent).then(function(){status.textContent="Referral code copied.";}).catch(function(){status.textContent="Copy failed. Select the code and copy it manually.";});}});panel.appendChild(copy);
 var applyForm=el("form",{});applyForm.appendChild(el("h3",{},"Apply a referral code"));
 var input=el("input",{id:"rewards-referral-input",type:"text",maxlength:"12",placeholder:"Enter referral code",autocomplete:"off"});input.style.cssText="padding:10px;border-radius:10px;max-width:100%;";
 applyForm.appendChild(input);var apply=el("button",{type:"submit",class:"btn"},"Apply code");applyForm.appendChild(apply);panel.appendChild(applyForm);wrap.appendChild(panel);
 var ledger=el("div",{class:"panel"});ledger.appendChild(el("h3",{},"Reward history"));var list=el("div",{id:"rewards-ledger"});ledger.appendChild(list);wrap.appendChild(ledger);wrap.appendChild(status);main.appendChild(page);
 function ctx(){return {db:window.sb||null,user:window.U||null};}
 function refresh(){
  var c=ctx();code.textContent="Sign in to load your code";list.replaceChildren();
  if(!c.db||!c.user){list.appendChild(el("p",{class:"sub"},"Sign in to view referral and reward information."));return;}
  c.db.rpc("clario_ensure_referral_code").then(function(r){if(r.error)throw r.error;code.textContent=r.data;}).catch(function(){code.textContent="Referral code unavailable. Apply migration 202610240009_referrals_loyalty.sql.";});
  Promise.all([
   c.db.from("reward_ledger").select("id,kind,amount,points,currency,created_at").order("created_at",{ascending:false}).limit(50),
   c.db.from("referrals").select("id,status,created_at,qualified_at").order("created_at",{ascending:false}).limit(50),
   c.db.from("reward_policy").select("referral_credit_amount,loyalty_points_per_paid_payment,credit_currency").limit(1)
  ]).then(function(results){
   list.replaceChildren();var failed=results.find(function(x){return x.error;});if(failed){list.appendChild(el("p",{class:"sub"},"Reward history is unavailable. Check the rewards migration and database permissions."));return;}
   var p=results[2].data&&results[2].data[0];
   if(p)list.appendChild(el("p",{class:"sub"},"Current policy: "+p.referral_credit_amount+" "+p.credit_currency+" referral credit; "+p.loyalty_points_per_paid_payment+" points per approved paid subscription. These values may be zero until configured."));
   var referrals=results[1].data||[];list.appendChild(el("h4",{},"Invitations"));
   if(!referrals.length)list.appendChild(el("p",{class:"sub"},"No referrals yet."));
   referrals.forEach(function(x){list.appendChild(el("p",{},x.status+" · added "+new Date(x.created_at).toLocaleDateString()+(x.qualified_at?" · qualified "+new Date(x.qualified_at).toLocaleDateString():"")));});
   list.appendChild(el("h4",{},"Earned rewards"));
   var rows=results[0].data||[];if(!rows.length)list.appendChild(el("p",{class:"sub"},"No rewards earned yet. Free-plan activity does not earn loyalty points."));
   rows.forEach(function(x){list.appendChild(el("p",{},x.kind==="loyalty_points"?(x.points+" loyalty points"):(x.amount+" "+x.currency+" referral credit")+" · "+new Date(x.created_at).toLocaleDateString()));});
  }).catch(function(){list.replaceChildren(el("p",{class:"sub"},"Could not load reward history. Please retry."));});
 }
 applyForm.addEventListener("submit",function(e){e.preventDefault();var c=ctx(),v=input.value.trim().toUpperCase();if(!c.db||!c.user){status.textContent="Sign in before applying a referral code.";return;}if(!/^[A-Z0-9]{8,12}$/.test(v)){status.textContent="Enter a valid 8–12 character code.";return;}apply.disabled=true;status.textContent="Applying code…";c.db.rpc("clario_apply_referral",{p_code:v}).then(function(r){if(r.error)throw r.error;status.textContent="Referral code applied. Reward eligibility depends on a successful paid subscription.";input.value="";refresh();}).catch(function(err){status.textContent=err&&err.message?err.message:"Could not apply referral code.";}).finally(function(){apply.disabled=false;});});
 refresh();window.ClarioRewards={refresh:refresh};
}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",init);else init();
})();