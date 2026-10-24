(function () {
  "use strict";
  function node(tag, attrs, text) {
    var n=document.createElement(tag);
    Object.keys(attrs||{}).forEach(function(k){if(k==="className")n.className=attrs[k];else n.setAttribute(k,attrs[k]);});
    if(text!==undefined)n.textContent=text;
    return n;
  }
  function field(parent,labelText,id,type,placeholder) {
    var wrap=node("div",{}), label=node("label",{for:id},labelText);
    var input=node(type==="select"?"select":"input",{id:id});
    if(type!=="select")input.type=type||"text";
    if(placeholder)input.placeholder=placeholder;
    wrap.appendChild(label);wrap.appendChild(input);parent.appendChild(wrap);return input;
  }
  function init() {
    var main=document.querySelector("main"); if(!main||document.getElementById("p-travel"))return;
    var page=node("div",{id:"p-travel",className:"pg"});page.hidden=true;
    var section=node("section",{});page.appendChild(section);
    section.appendChild(node("h2",{},"Tour & Travel Planner"));
    section.appendChild(node("p",{className:"sub"},"Organize a solo trip, a duo getaway, or a group itinerary. Saved plans are private to your account. This planner does not confirm live prices, transport availability, bookings, or visa requirements."));
    var form=node("form",{id:"travel-form",className:"panel"});
    form.appendChild(node("h3",{},"Create a trip draft"));
    var grid=node("div",{className:"grid"});
    var title=field(grid,"Trip name","travel-title","text","e.g. Cox’s Bazar weekend");
    var origin=field(grid,"Starting from","travel-origin","text","Dhaka");
    var destination=field(grid,"Destination","travel-destination","text","City, region, or country");
    var start=field(grid,"Start date","travel-start","date","");
    var end=field(grid,"End date","travel-end","date","");
    var style=field(grid,"Travel style","travel-style","select","");
    [["solo","Solo"],["duo","Duo"],["group","Group"]].forEach(function(x){style.appendChild(node("option",{value:x[0]},x[1]));});
    var size=field(grid,"Group size","travel-size","number","1");size.min="1";size.max="30";size.value="1";
    var budget=field(grid,"Estimated total budget","travel-budget","number","Optional");budget.min="0";budget.step="0.01";
    var currency=field(grid,"Currency","travel-currency","select","");
    [["BDT","BDT (৳)"],["USD","USD ($)"],["EUR","EUR (€)"],["INR","INR (₹)"],["GBP","GBP (£)"]].forEach(function(x){currency.appendChild(node("option",{value:x[0]},x[1]));});
    form.appendChild(grid);
    var interestWrap=node("div",{});interestWrap.appendChild(node("label",{},"Interests (choose any)"));
    var interests=node("div",{className:"prio"});
    [["history","Historic places"],["culture","Culture and museums"],["nature","Nature"],["food","Local food"],["adventure","Adventure"],["family","Family-friendly"],["relax","Relaxation"],["accessibility","Accessible travel"]].forEach(function(x){
      var l=node("label",{}), i=node("input",{type:"checkbox",value:x[0]});l.appendChild(i);l.appendChild(node("span",{},x[1]));interests.appendChild(l);
    });
    interestWrap.appendChild(interests);form.appendChild(interestWrap);
    var access=field(form,"Accessibility, dietary, or other practical notes","travel-access","text","Optional needs and constraints");
    access.maxLength=1000;
    var notesWrap=node("div",{}),notesLabel=node("label",{for:"travel-notes"},"Itinerary notes / day-by-day ideas");
    var notes=node("textarea",{id:"travel-notes",rows:"5",maxlength:"10000",style:"width:100%;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:12px;font:inherit"});notes.placeholder="Day 1: arrival and check-in… Add places you want to visit, transport preferences, and backup plans.";
    notesWrap.appendChild(notesLabel);notesWrap.appendChild(notes);form.appendChild(notesWrap);
    var status=node("p",{id:"travel-status",role:"status",className:"sub"},"");form.appendChild(status);
    var buttons=node("div",{});
    var save=node("button",{type:"submit",className:"btn"},"Save private trip draft");
    var clear=node("button",{type:"button",className:"btn s"},"Clear form");clear.addEventListener("click",function(){form.reset();size.value="1";status.textContent="Form cleared.";});
    buttons.appendChild(save);buttons.appendChild(clear);form.appendChild(buttons);section.appendChild(form);
    var savedPanel=node("div",{className:"panel"});savedPanel.appendChild(node("h3",{},"Your saved trips"));
    var refresh=node("button",{type:"button",className:"btn s"},"Refresh trips");var list=node("div",{id:"travel-saved-list"});
    refresh.addEventListener("click",loadTrips);savedPanel.appendChild(refresh);savedPanel.appendChild(list);section.appendChild(savedPanel);main.appendChild(page);
    style.addEventListener("change",function(){size.value=style.value==="solo"?"1":style.value==="duo"?"2":Math.max(3,Number(size.value)||3);});
    function clientUser(){return {client:window.sb||null,user:window.U||null};}
    form.addEventListener("submit",function(ev){
      ev.preventDefault();var ctx=clientUser();
      if(!ctx.client||!ctx.user){status.textContent="Please sign in before saving a trip.";return;}
      if(!title.value.trim()||!origin.value.trim()||!destination.value.trim()){status.textContent="Trip name, origin, and destination are required.";return;}
      if(start.value&&end.value&&end.value<start.value){status.textContent="End date must be on or after the start date.";return;}
      var count=Number(size.value);
      if(!Number.isInteger(count)||count<1||count>30){status.textContent="Group size must be between 1 and 30.";return;}
      var picked=Array.from(interests.querySelectorAll("input:checked")).map(function(i){return i.value;});
      save.disabled=true;status.textContent="Saving private trip…";
      ctx.client.from("travel_trips").insert({user_id:ctx.user.id,title:title.value.trim(),origin:origin.value.trim(),destination:destination.value.trim(),start_date:start.value||null,end_date:end.value||null,travel_style:style.value,group_size:count,budget_amount:budget.value?Number(budget.value):null,budget_currency:currency.value,interests:picked,accessibility_notes:access.value.trim(),itinerary_notes:notes.value.trim(),status:"draft"})
      .then(function(res){if(res.error)throw res.error;status.textContent="Trip draft saved privately.";form.reset();size.value="1";loadTrips();})
      .catch(function(err){status.textContent="Could not save trip. Apply migration 202610240008_travel_planner.sql and retry. "+(err&&err.message?err.message:"");})
      .finally(function(){save.disabled=false;});
    });
    function loadTrips(){
      var ctx=clientUser();list.replaceChildren();
      if(!ctx.client||!ctx.user){list.appendChild(node("p",{className:"sub"},"Sign in to view saved trips."));return;}
      list.appendChild(node("p",{className:"sub"},"Loading…"));
      ctx.client.from("travel_trips").select("id,title,origin,destination,start_date,end_date,travel_style,group_size,budget_amount,budget_currency,interests,accessibility_notes,itinerary_notes,status,updated_at").order("updated_at",{ascending:false}).limit(50)
      .then(function(res){
        list.replaceChildren();
        if(res.error){list.appendChild(node("p",{className:"sub"},"Saved trips are not available yet. Apply the travel planner migration."));return;}
        if(!res.data||!res.data.length){list.appendChild(node("p",{className:"sub"},"No saved trips yet. Create your first draft above."));return;}
        res.data.forEach(function(t){
          var card=node("article",{className:"card"});card.appendChild(node("h3",{},t.title));
          card.appendChild(node("p",{},t.origin+" → "+t.destination));
          card.appendChild(node("p",{},(t.start_date||"Dates flexible")+" – "+(t.end_date||"not set")+" · "+t.travel_style+" · "+t.group_size+" traveller(s)"));
          if(t.budget_amount!==null)card.appendChild(node("p",{},"Budget: "+t.budget_currency+" "+Number(t.budget_amount).toLocaleString()));
          if(t.interests&&t.interests.length)card.appendChild(node("p",{},"Interests: "+t.interests.join(", ")));
          if(t.itinerary_notes)card.appendChild(node("p",{},"Notes: "+t.itinerary_notes));
          var row=node("div",{}), archive=node("button",{type:"button",className:"btn s"},"Archive"),remove=node("button",{type:"button",className:"btn s"},"Delete");
          archive.addEventListener("click",function(){updateTrip(t.id,{status:t.status==="archived"?"draft":"archived"});});
          remove.addEventListener("click",function(){if(!window.confirm("Permanently delete this trip draft?"))return;var c=clientUser();c.client.from("travel_trips").delete().eq("id",t.id).eq("user_id",c.user.id).then(function(r){if(r.error)status.textContent="Could not delete trip.";else loadTrips();});});
          row.appendChild(archive);row.appendChild(remove);card.appendChild(row);list.appendChild(card);
        });
      }).catch(function(){list.replaceChildren(node("p",{className:"sub"},"Could not load saved trips. Please retry."));});
    }
    function updateTrip(id,patch){var c=clientUser();if(!c.client||!c.user)return;c.client.from("travel_trips").update(patch).eq("id",id).eq("user_id",c.user.id).then(function(r){if(r.error)status.textContent="Could not update trip.";else loadTrips();});}
    loadTrips();
    window.ClarioTravel={refresh:loadTrips};
  }
  if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",init);else init();
})();