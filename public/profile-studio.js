/* Clario Profile Studio: user-editable profile fields only; privilege fields are never sent. */
(function () {
  "use strict";
  var pageId = "p-profile";
  function node(tag, attrs, text) {
    var n = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "className") n.className = attrs[k];
      else n.setAttribute(k, attrs[k]);
    });
    if (text != null) n.textContent = text;
    return n;
  }
  function field(parent, labelText, id, type, value, hint) {
    var wrap = node("div", { style: "margin-bottom:14px" });
    wrap.appendChild(node("label", { for: id }, labelText));
    var input = type === "textarea"
      ? node("textarea", { id: id, rows: "4", maxlength: id === "profile-bio" ? "240" : "500", style: "width:100%;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:10px;font:inherit" })
      : node("input", { id: id, type: type || "text", maxlength: id === "profile-username" ? "24" : "100", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit" });
    input.value = value || "";
    if (hint) input.placeholder = hint;
    wrap.appendChild(input); parent.appendChild(wrap);
    return input;
  }
  function init() {
    if (document.getElementById(pageId)) return;
    var main = document.querySelector("main");
    if (!main) return;
    var page = node("div", { id: pageId, className: "pg", hidden: "" });
    var section = node("section");
    section.appendChild(node("h2", {}, "Profile Studio"));
    section.appendChild(node("p", { className: "sub" }, "Choose how your Clario profile appears. Profile visibility is enforced by database policies. Private is the safest default; only share information you intend the selected audience to see."));
    var panel = node("div", { className: "panel" });
    panel.appendChild(node("p", { className: "sub" }, "Your display name, username, bio, interests, and visibility can be edited here. Account role and subscription plan are intentionally not editable."));
    var displayName = field(panel, "Display name", "profile-display-name", "text", "", "Name shown on your profile (max 80 characters)");
    var username = field(panel, "Username", "profile-username", "text", "", "3–24 characters: letters, numbers, underscores");
    var bio = field(panel, "Bio", "profile-bio", "textarea", "", "Tell people a little about yourself (max 240 characters)");
    var interests = field(panel, "Interests (comma-separated, up to 12)", "profile-interests", "text", "", "technology, travel, learning");
    var visibilityWrap = node("div", { style: "margin-bottom:16px" });
    visibilityWrap.appendChild(node("label", { for: "profile-visibility" }, "Profile visibility"));
    var visibility = node("select", { id: "profile-visibility", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit" });
    [["private","Private (recommended)"],["public","Public"],["followers","Followers only"]].forEach(function (v) {
      var o = node("option", { value: v[0] }, v[1]); visibility.appendChild(o);
    });
    visibilityWrap.appendChild(visibility); panel.appendChild(visibilityWrap);
    var status = node("p", { id: "profile-status", role: "status", className: "sub" }, "Sign in to load and save your profile.");
    var actions = node("div", { style: "display:flex;gap:8px;flex-wrap:wrap" });
    var save = node("button", { type: "button", className: "btn" }, "Save profile");
    var back = node("button", { type: "button", className: "btn s" }, "Back to dashboard");
    actions.appendChild(save); actions.appendChild(back); panel.appendChild(actions); panel.appendChild(status);
    section.appendChild(panel); page.appendChild(section); main.appendChild(page);
    var open = node("button", { type: "button", className: "btn s", id: "profile-studio-open" }, "Edit social profile");
    var dashboard = document.getElementById("p-dash");
    if (dashboard) {
      var target = dashboard.querySelector("section");
      if (target) target.appendChild(open);
    }
    open.addEventListener("click", function () { window.go("profile"); load(); });
    back.addEventListener("click", function () { window.go("dash"); });
    save.addEventListener("click", saveProfile);
    username.addEventListener("input", function () { username.value = username.value.toLowerCase().replace(/[^a-z0-9_]/g, "").slice(0,24); });
    load();
  }
  function say(message, good) {
    var s = document.getElementById("profile-status");
    if (s) { s.textContent = message; s.style.color = good ? "var(--teal)" : "var(--er)"; }
  }
  function load() {
    var client = window.sb, u = window.U;
    if (!client || !u) { say("Sign in to edit your profile.", false); return; }
    client.from("profiles").select("display_name,username,bio,interests,profile_visibility").eq("id", u.id).maybeSingle()
      .then(function (res) {
        if (res.error) { say("Could not load profile. Apply the social profile migration to staging first.", false); return; }
        var p = res.data || {};
        document.getElementById("profile-display-name").value = p.display_name || "";
        document.getElementById("profile-username").value = p.username || "";
        document.getElementById("profile-bio").value = p.bio || "";
        document.getElementById("profile-interests").value = Array.isArray(p.interests) ? p.interests.join(", ") : "";
        document.getElementById("profile-visibility").value = p.profile_visibility || "private";
        say("Profile loaded. Review visibility before saving.", true);
      });
  }
  function saveProfile() {
    var client = window.sb, u = window.U;
    if (!client || !u) { say("Sign in before saving.", false); return; }
    var displayName = document.getElementById("profile-display-name").value.trim();
    var username = document.getElementById("profile-username").value.trim().toLowerCase();
    var bio = document.getElementById("profile-bio").value.trim();
    var interests = document.getElementById("profile-interests").value.split(",").map(function (s) { return s.trim(); }).filter(Boolean);
    var visibility = document.getElementById("profile-visibility").value;
    if (displayName.length > 80) { say("Display name must be 80 characters or fewer.", false); return; }
    if (username && !/^[a-z0-9_]{3,24}$/.test(username)) { say("Username must be 3–24 characters using letters, numbers, or underscores.", false); return; }
    if (bio.length > 240) { say("Bio must be 240 characters or fewer.", false); return; }
    if (interests.length > 12 || interests.some(function (s) { return s.length > 40; })) { say("Use up to 12 interests, each 40 characters or fewer.", false); return; }
    say("Saving profile…", true);
    client.from("profiles").update({
      display_name: displayName,
      username: username || null,
      bio: bio,
      interests: interests,
      profile_visibility: visibility
    }).eq("id", u.id).then(function (res) {
      if (res.error) { say(res.error.code === "23505" ? "That username is already taken." : (res.error.message || "Could not save profile."), false); return; }
      say("Profile saved. Database access policies enforce your selected visibility.", true);
    });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
