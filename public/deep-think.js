/* Clario Deep Think: human-only review. This module deliberately makes no AI/API calls. */
(function () {
  "use strict";
  var boardId = "p-deep-think";
  var activeCase = null;
  function el(tag, attrs, text) {
    var node = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (key) {
      if (key === "className") node.className = attrs[key];
      else if (key === "textContent") node.textContent = attrs[key];
      else node.setAttribute(key, attrs[key]);
    });
    if (text != null) node.textContent = text;
    return node;
  }
  function field(parent, labelText, name, type, placeholder) {
    var wrap = el("div", { style: "margin-bottom:14px" });
    var label = el("label", { for: "dt-" + name }, labelText);
    var input = type === "textarea" ? el("textarea", { id: "dt-" + name, name: name, rows: "3", placeholder: placeholder || "", style: "width:100%;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:10px;font:inherit" }) : el("input", { id: "dt-" + name, name: name, type: type || "text", placeholder: placeholder || "", style: "width:100%;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:10px;min-height:48px;font:inherit" });
    wrap.appendChild(label); wrap.appendChild(input); parent.appendChild(wrap);
    return input;
  }
  function status(message, good) {
    var n = document.getElementById("dt-status");
    if (n) { n.textContent = message; n.style.color = good ? "var(--teal)" : "var(--er)"; }
  }
  function addBoard() {
    if (document.getElementById(boardId)) return;
    var main = document.querySelector("main");
    var page = el("div", { id: boardId, className: "pg", hidden: "" });
    var section = el("section");
    section.appendChild(el("h2", {}, "Deep Think Board"));
    section.appendChild(el("p", { className: "sub" }, "A private, human-only review. No AI analysis, summaries, rankings, or recommendations are used in this workflow."));
    var notice = el("div", { className: "panel" });
    notice.appendChild(el("h3", {}, "Before you submit"));
    notice.appendChild(el("p", {}, "Your board can contain sensitive personal information. Share only what is relevant. It will be visible to you and authorized Clario admins/owner reviewing your case. Do not include passwords, payment card details, or information about others that you do not have permission to share."));
    section.appendChild(notice);
    var form = el("form", { id: "dt-form", className: "panel" });
    form.appendChild(el("h3", {}, "Your decision"));
    field(form, "What decision do you need help with? *", "title", "text", "e.g. choosing a career path");
    field(form, "Your background and current situation", "background", "textarea", "Share the context you feel is relevant");
    field(form, "Your goals and what matters most", "goals", "textarea", "What outcome would be best for you?");
    field(form, "Options you are considering", "options", "textarea", "List each option and its pros/cons");
    field(form, "Constraints (budget, time, family, location, etc.)", "constraints", "textarea", "What limits or requirements matter?");
    field(form, "Risks, concerns, or uncertainties", "risks", "textarea", "What are you worried about?");
    field(form, "Additional context (optional)", "additional", "textarea", "Anything else the human reviewer should know");
    var consent = el("label", { style: "display:flex;gap:10px;align-items:flex-start;margin:12px 0;color:var(--t2)" });
    var check = el("input", { type: "checkbox", id: "dt-consent", required: "" });
    consent.appendChild(check);
    consent.appendChild(el("span", {}, "I understand this is a human-only review, that authorized admins/owner will read the information I submit, and that a response time is not guaranteed."));
    form.appendChild(consent);
    var actions = el("div", { style: "display:flex;gap:8px;flex-wrap:wrap" });
    actions.appendChild(el("button", { type: "submit", className: "btn" }, "Submit for human review"));
    actions.appendChild(el("button", { type: "button", className: "btn s", id: "dt-back" }, "Back"));
    form.appendChild(actions);
    form.appendChild(el("p", { id: "dt-status", role: "status", className: "sub", style: "margin-top:12px" }, ""));
    section.appendChild(form);
    var mine = el("div", { className: "panel" });
    mine.appendChild(el("h3", {}, "My Deep Think cases"));
    mine.appendChild(el("div", { id: "dt-mine" }, "Sign in to view submitted cases."));
    section.appendChild(mine);
    var admin = el("div", { className: "panel", id: "dt-admin", hidden: "" });
    admin.appendChild(el("h3", {}, "Human review queue"));
    admin.appendChild(el("p", { className: "sub" }, "Restricted to the owner account. Review the user's original submission; do not use AI tools for this workflow."));
    admin.appendChild(el("div", { id: "dt-queue" }));
    section.appendChild(admin);
    page.appendChild(section); main.appendChild(page);
    document.getElementById("deep-think-start").addEventListener("click", function () {
      if (typeof window.go === "function") window.go("deep-think");
      else showPage("deep-think");
      refresh();
    });
    document.getElementById("dt-back").addEventListener("click", function () { if (typeof window.go === "function") window.go("decide"); else showPage("decide"); });
    form.addEventListener("submit", submit);
  }
  function showPage(id) {
    document.querySelectorAll("main>.pg").forEach(function (p) { p.hidden = p.id !== "p-" + id; });
    window.scrollTo(0, 0);
  }
  function sb() { return window.sb || null; }
  function user() { return window.U || null; }
  function role() { return window.PR || null; }
  function submit(event) {
    event.preventDefault();
    var client = sb(), u = user();
    if (!client || !u) { status("Please sign in before submitting a private Deep Think case.", false); return; }
    var title = document.getElementById("dt-title").value.trim();
    if (!title) { status("Please enter the decision you need help with.", false); return; }
    if (!document.getElementById("dt-consent").checked) { status("Please confirm the privacy and human-review notice.", false); return; }
    var payload = {
      p_title: title,
      p_background: document.getElementById("dt-background").value.trim(),
      p_goals: document.getElementById("dt-goals").value.trim(),
      p_options: document.getElementById("dt-options").value.trim(),
      p_constraints: document.getElementById("dt-constraints").value.trim(),
      p_risks: document.getElementById("dt-risks").value.trim(),
      p_additional: document.getElementById("dt-additional").value.trim()
    };
    var button = document.querySelector("#dt-form button[type=submit]");
    button.disabled = true; status("Submitting securely for human review…", true);
    client.rpc("submit_deep_think_case", payload).then(function (result) {
      button.disabled = false;
      if (result.error) { status("Submission unavailable: " + result.error.message + ". The database migration must be installed before this can be used.", false); return; }
      document.getElementById("dt-form").reset();
      status("Submitted. Your case reference: " + String(result.data || "created") + ". No AI was used by this page.", true);
      refresh();
    }).catch(function () { button.disabled = false; status("Could not submit. Please try again later.", false); });
  }
  function refresh() {
    var client = sb(), u = user(), r = role();
    var mine = document.getElementById("dt-mine");
    var admin = document.getElementById("dt-admin");
    if (!client || !u) { if (mine) mine.textContent = "Sign in to view submitted cases."; if (admin) admin.hidden = true; return; }
    client.from("deep_think_cases").select("id,title,status,created_at,final_decision").order("created_at", { ascending: false }).then(function (res) {
      if (res.error) { mine.textContent = "Case history will appear after the Deep Think database migration is installed."; return; }
      mine.replaceChildren();
      if (!res.data.length) mine.textContent = "No submitted cases yet.";
      res.data.forEach(function (c) {
        var card = el("div", { className: "card", style: "margin:10px 0" });
        card.appendChild(el("h3", {}, c.title));
        card.appendChild(el("p", {}, "Status: " + c.status + " · " + new Date(c.created_at).toLocaleDateString()));
        if (c.final_decision) card.appendChild(el("p", {}, "Decision: " + c.final_decision));
        mine.appendChild(card);
      });
    });
    var allowed = r && r.role === "owner";
    admin.hidden = !allowed;
    if (allowed) {
      client.from("deep_think_cases").select("id,user_id,title,background,goals,options_text,constraints_text,risks,additional_text,status,created_at,final_decision").order("created_at", { ascending: true }).then(function (res) {
        var queue = document.getElementById("dt-queue"); queue.replaceChildren();
        if (res.error) { queue.textContent = "Review queue unavailable until the database migration is installed."; return; }
        if (!res.data.length) { queue.textContent = "No pending cases."; return; }
        res.data.forEach(function (c) {
          var card = el("div", { className: "card", style: "margin:10px 0" });
          card.appendChild(el("h3", {}, c.title));
          [["Background",c.background],["Goals",c.goals],["Options",c.options_text],["Constraints",c.constraints_text],["Risks",c.risks],["Additional context",c.additional_text]].forEach(function (pair) { if (pair[1]) { card.appendChild(el("h3", {}, pair[0])); card.appendChild(el("p", {}, pair[1])); } });
          var statusSelect = el("select", { "aria-label": "Case status", style: "margin:8px 0" });
          ["in_review","needs_information","decision_ready","delivered","closed"].forEach(function (s) { var o = el("option", { value: s }, s.replace(/_/g, " ")); if (s === c.status) o.selected = true; statusSelect.appendChild(o); });
          card.appendChild(statusSelect);
          var decision = field(card, "Official human decision (visible to the user when delivered)", "decision-" + c.id, "textarea", "Write the decision based on your human review");
          decision.value = c.final_decision || "";
          var note = field(card, "Internal admin-only note", "note-" + c.id, "textarea", "Optional internal note");
          var save = el("button", { type: "button", className: "btn" }, "Save review");
          save.addEventListener("click", function () {
            if (!decision.value.trim() && statusSelect.value === "delivered") { window.alert("Add the final decision before delivering."); return; }
            save.disabled = true;
            client.rpc("review_deep_think_case", { p_case_id: c.id, p_status: statusSelect.value, p_final_decision: decision.value.trim(), p_internal_note: note.value.trim() }).then(function (out) {
              save.disabled = false;
              if (out.error) window.alert("Review not saved: " + out.error.message);
              else { window.alert("Review saved."); refresh(); }
            });
          });
          card.appendChild(save); queue.appendChild(card);
        });
      });
    }
  }
  document.addEventListener("DOMContentLoaded", function () {
    addBoard();
    // Existing app state is declared with var in the main script; poll-free hooks are refreshed on auth/page changes.
    document.addEventListener("click", function (e) { if (e.target.closest('[data-go="dash"],[data-go="deep-think"]')) refresh(); });
    if (window.sb && window.sb.auth) window.sb.auth.onAuthStateChange(function () { setTimeout(refresh, 0); });
    setTimeout(refresh, 0);
  });
})();
