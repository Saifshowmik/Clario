/* Clario Social Studio: text posts and reactions backed by RLS-protected Supabase tables. */
(function () {
  "use strict";
  function el(tag, attrs, text) {
    var n = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "className") n.className = attrs[k]; else n.setAttribute(k, attrs[k]);
    });
    if (text != null) n.textContent = text;
    return n;
  }
  function init() {
    if (document.getElementById("p-social")) return;
    var main = document.querySelector("main");
    if (!main) return;
    var page = el("div", { id: "p-social", className: "pg", hidden: "" });
    var section = el("section");
    section.appendChild(el("h2", {}, "Clario Social"));
    section.appendChild(el("p", { className: "sub" }, "Share text updates with the audience you choose. Access is enforced by database row-level security; private media uploads are not enabled yet."));
    var composer = el("div", { className: "panel" });
    composer.appendChild(el("h3", {}, "Create a post"));
    var label = el("label", { for: "social-caption" }, "What would you like to share?");
    var caption = el("textarea", { id: "social-caption", rows: "4", maxlength: "3000", placeholder: "Share an update, thought, or question…", style: "width:100%;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:10px;font:inherit" });
    composer.appendChild(label); composer.appendChild(caption);
    var audienceLabel = el("label", { for: "social-audience" }, "Who can see this post?");
    var audience = el("select", { id: "social-audience", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit;margin-bottom:12px" });
    [["followers","Followers"],["private","Only me"],["public","Public (requires a public profile)"]].forEach(function (v) { audience.appendChild(el("option", { value: v[0] }, v[1])); });
    composer.appendChild(audienceLabel); composer.appendChild(audience);
    var post = el("button", { type: "button", className: "btn" }, "Publish post");
    var composerStatus = el("p", { id: "social-compose-status", role: "status", className: "sub" }, "");
    composer.appendChild(post); composer.appendChild(composerStatus);
    section.appendChild(composer);
    var storyPanel = el("div", { className: "panel" });
    storyPanel.appendChild(el("h3", {}, "24-hour story"));
    var storyText = el("input", { id: "social-story-text", type: "text", maxlength: "1000", placeholder: "A short update for the next 24 hours…", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit" });
    var storyAudience = el("select", { id: "social-story-audience", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit;margin:10px 0" });
    [["followers","Followers"],["private","Only me"],["public","Public (requires a public profile)"]].forEach(function (v) { storyAudience.appendChild(el("option", { value: v[0] }, v[1])); });
    var storyPublish = el("button", { type: "button", className: "btn s" }, "Share story");
    var storyStatus = el("p", { id: "social-story-status", role: "status", className: "sub" }, "");
    var storyList = el("div", { id: "social-story-list" });
    storyPanel.appendChild(storyText); storyPanel.appendChild(storyAudience); storyPanel.appendChild(storyPublish); storyPanel.appendChild(storyStatus); storyPanel.appendChild(storyList);
    storyPublish.addEventListener("click", publishStory);
    section.appendChild(storyPanel);
    var followPanel = el("div", { className: "panel" });
    followPanel.appendChild(el("h3", {}, "Find a member"));
    var username = el("input", { id: "social-follow-username", type: "text", maxlength: "24", placeholder: "Enter an exact username", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit" });
    var followButton = el("button", { type: "button", className: "btn s" }, "Request to follow");
    var followStatus = el("p", { id: "social-follow-status", role: "status", className: "sub" }, "");
    followButton.addEventListener("click", function () { requestFollow(username.value); });
    followPanel.appendChild(username); followPanel.appendChild(followButton); followPanel.appendChild(followStatus);
    section.appendChild(followPanel);
    var requestsPanel = el("div", { className: "panel" });
    requestsPanel.appendChild(el("h3", {}, "Incoming follow requests"));
    var requestsStatus = el("p", { id: "social-requests-status", role: "status", className: "sub" }, "");
    var requestsList = el("div", { id: "social-requests-list" });
    var requestsRefresh = el("button", { type: "button", className: "btn s" }, "Refresh requests");
    requestsRefresh.addEventListener("click", loadFollowRequests);
    requestsPanel.appendChild(requestsRefresh); requestsPanel.appendChild(requestsStatus); requestsPanel.appendChild(requestsList);
    section.appendChild(requestsPanel);
    var safetyPanel = el("div", { className: "panel" });
    safetyPanel.appendChild(el("h3", {}, "Safety controls"));
    var safetyUsername = el("input", { id: "social-safety-username", type: "text", maxlength: "24", placeholder: "Username to block or mute", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit" });
    var safetyButtons = el("div", { style: "display:flex;gap:8px;flex-wrap:wrap;margin-top:10px" });
    [["Block member", blockMember],["Mute member", muteMember]].forEach(function (item) {
      var b = el("button", { type: "button", className: "btn s" }, item[0]);
      b.addEventListener("click", function () { item[1](safetyUsername.value); });
      safetyButtons.appendChild(b);
    });
    var safetyStatus = el("p", { id: "social-safety-status", role: "status", className: "sub" }, "");
    var reportReason = el("select", { id: "social-report-reason", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit;margin-top:12px" });
    [["spam","Spam"],["harassment","Harassment"],["hate","Hate or abuse"],["sexual_content","Sexual content"],["violence","Violence"],["self_harm","Self-harm concern"],["impersonation","Impersonation"],["other","Other"]].forEach(function (v) { reportReason.appendChild(el("option", { value: v[0] }, v[1])); });
    var reportDetails = el("textarea", { id: "social-report-details", rows: "2", maxlength: "1500", placeholder: "Optional details about a concern", style: "width:100%;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:10px;font:inherit;margin-top:8px" });
    var reportButton = el("button", { type: "button", className: "btn s" }, "Submit report");
    reportButton.addEventListener("click", submitReport);
    safetyPanel.appendChild(safetyUsername); safetyPanel.appendChild(safetyButtons);
    safetyPanel.appendChild(reportReason); safetyPanel.appendChild(reportDetails); safetyPanel.appendChild(reportButton); safetyPanel.appendChild(safetyStatus);
    section.appendChild(safetyPanel);
    var moderationPanel = el("div", { className: "panel" });
    moderationPanel.appendChild(el("h3", {}, "Moderation queue (owners only)"));
    var moderationStatus = el("p", { id: "social-moderation-status", role: "status", className: "sub" }, "Owner access required.");
    var moderationList = el("div", { id: "social-moderation-list" });
    var moderationRefresh = el("button", { type: "button", className: "btn s" }, "Load reports");
    moderationRefresh.addEventListener("click", loadModerationQueue);
    moderationPanel.appendChild(moderationRefresh); moderationPanel.appendChild(moderationStatus); moderationPanel.appendChild(moderationList);
    section.appendChild(moderationPanel);
    var feed = el("div", { className: "panel" });
    feed.appendChild(el("h3", {}, "Your feed"));
    var feedStatus = el("p", { id: "social-feed-status", role: "status", className: "sub" }, "");
    var list = el("div", { id: "social-feed-list" });
    var refresh = el("button", { type: "button", className: "btn s" }, "Refresh feed");
    feed.appendChild(refresh); feed.appendChild(feedStatus); feed.appendChild(list); section.appendChild(feed);
    var back = el("button", { type: "button", className: "btn s" }, "Back to dashboard");
    section.appendChild(back); page.appendChild(section); main.appendChild(page);
    var open = el("button", { type: "button", className: "btn s" }, "Open Clario Social");
    open.addEventListener("click", function () { window.go("social"); loadFeed(); });
    var dashboard = document.getElementById("p-dash");
    if (dashboard) { var target = dashboard.querySelector("section"); if (target) target.appendChild(open); }
    back.addEventListener("click", function () { window.go("dash"); });
    refresh.addEventListener("click", loadFeed);
    post.addEventListener("click", publish);
    loadFeed();
    loadStories();
    loadFollowRequests();
  }
  function status(id, text, good) {
    var n = document.getElementById(id);
    if (n) { n.textContent = text; n.style.color = good ? "var(--teal)" : "var(--er)"; }
  }
  function clientAndUser() { return { client: window.sb || null, user: window.U || null }; }
  function publish() {
    var ctx = clientAndUser();
    if (!ctx.client || !ctx.user) { status("social-compose-status", "Sign in to publish a post.", false); return; }
    var caption = document.getElementById("social-caption").value.trim();
    var audience = document.getElementById("social-audience").value;
    if (!caption) { status("social-compose-status", "Write something before publishing.", false); return; }
    if (caption.length > 3000) { status("social-compose-status", "Posts are limited to 3,000 characters.", false); return; }
    status("social-compose-status", "Publishing…", true);
    ctx.client.from("social_posts").insert({ author_id: ctx.user.id, caption: caption, audience: audience, status: "published" })
      .then(function (res) {
        if (res.error) { status("social-compose-status", res.error.message || "Could not publish. Apply the social migrations to staging first.", false); return; }
        document.getElementById("social-caption").value = "";
        status("social-compose-status", "Post published.", true);
        loadFeed();
      });
  }
  function publishStory() {
    var ctx = clientAndUser(), input = document.getElementById("social-story-text");
    if (!ctx.client || !ctx.user) { status("social-story-status", "Sign in to share a story.", false); return; }
    var text = input.value.trim();
    if (!text || text.length > 1000) { status("social-story-status", "Enter a story of 1–1,000 characters.", false); return; }
    ctx.client.from("social_stories").insert({ author_id: ctx.user.id, text_content: text, audience: document.getElementById("social-story-audience").value })
      .then(function (res) {
        if (res.error) { status("social-story-status", "Could not share story. Apply the social migration in staging first.", false); return; }
        input.value = ""; status("social-story-status", "Story shared; it expires after 24 hours.", true); loadStories();
      });
  }
  function loadStories() {
    var ctx = clientAndUser(), list = document.getElementById("social-story-list");
    if (!list) return;
    list.replaceChildren();
    if (!ctx.client || !ctx.user) return;
    ctx.client.from("social_stories").select("id,author_id,text_content,audience,created_at,expires_at")
      .gt("expires_at", new Date().toISOString()).order("created_at", { ascending: false }).limit(30)
      .then(function (res) {
        if (res.error) { status("social-story-status", "Stories are unavailable until the social migration is applied.", false); return; }
        (res.data || []).forEach(function (story) {
          var card = el("article", { className: "panel" });
          card.appendChild(el("p", { className: "sub" }, (story.author_id === ctx.user.id ? "Your story" : "Member story") + " · expires " + new Date(story.expires_at).toLocaleString()));
          card.appendChild(el("p", {}, story.text_content));
          if (story.author_id === ctx.user.id) {
            var remove = el("button", { type: "button", className: "btn s" }, "Delete story");
            remove.addEventListener("click", function () {
              ctx.client.from("social_stories").delete().eq("id", story.id).eq("author_id", ctx.user.id)
                .then(function (done) { if (done.error) status("social-story-status", "Could not delete story.", false); else loadStories(); });
            });
            card.appendChild(remove);
          }
          list.appendChild(card);
        });
      });
  }
  function loadFollowRequests() {
    var ctx = clientAndUser(), list = document.getElementById("social-requests-list");
    if (!list) return;
    list.replaceChildren();
    if (!ctx.client || !ctx.user) { status("social-requests-status", "Sign in to manage follow requests.", false); return; }
    ctx.client.from("social_follows").select("id,requester_id,created_at").eq("target_id", ctx.user.id).eq("status", "pending").order("created_at", { ascending: false }).limit(50)
      .then(function (res) {
        if (res.error) { status("social-requests-status", "Follow requests are unavailable until the social migration is applied.", false); return; }
        var rows = res.data || [];
        if (!rows.length) { status("social-requests-status", "No pending requests.", true); return; }
        status("social-requests-status", rows.length + " pending request(s).", true);
        rows.forEach(function (request) {
          var row = el("div", { className: "panel" });
          row.appendChild(el("p", {}, "Member request · " + new Date(request.created_at).toLocaleString()));
          ["accepted","rejected"].forEach(function (decision) {
            var button = el("button", { type: "button", className: "btn s" }, decision === "accepted" ? "Accept" : "Decline");
            button.addEventListener("click", function () {
              ctx.client.from("social_follows").update({ status: decision, updated_at: new Date().toISOString() }).eq("id", request.id).eq("target_id", ctx.user.id)
                .then(function (done) { if (done.error) status("social-requests-status", "Could not update request.", false); else loadFollowRequests(); });
            });
            row.appendChild(button);
          });
          list.appendChild(row);
        });
      });
  }
  function resolveUsername(raw) {
    var ctx = clientAndUser(), name = (raw || "").trim().replace(/^@/, "").toLowerCase();
    if (!ctx.client || !ctx.user) { status("social-safety-status", "Sign in to use safety controls.", false); return Promise.reject(new Error("Sign in required")); }
    if (!/^[a-z0-9_]{3,24}$/.test(name)) { status("social-safety-status", "Enter a valid username.", false); return Promise.reject(new Error("Invalid username")); }
    return Promise.resolve({ ctx: ctx, name: name });
  }
  function blockMember(raw) {
    resolveUsername(raw).then(function (v) {
      return v.ctx.client.rpc("block_social_member", { p_username: v.name });
    }).then(function (res) {
      if (res && res.error) throw new Error(res.error.message);
      status("social-safety-status", "Member blocked. Their content will be hidden where block policies apply.", true); loadFeed();
    }).catch(function (e) { status("social-safety-status", e.message || "Could not block member.", false); });
  }
  function muteMember(raw) {
    resolveUsername(raw).then(function (v) {
      return v.ctx.client.rpc("mute_social_member", { p_username: v.name });
    }).then(function (res) {
      if (res && res.error) throw new Error(res.error.message);
      status("social-safety-status", "Member muted. Feed filtering is being applied.", true); loadFeed();
    }).catch(function (e) { status("social-safety-status", e.message || "Could not mute member.", false); });
  }
  function submitReport() {
    var ctx = clientAndUser(), raw = document.getElementById("social-safety-username").value;
    resolveUsername(raw).then(function (v) {
      return v.ctx.client.rpc("resolve_social_username", { p_username: v.name }).then(function (lookup) {
        if (lookup.error || !lookup.data) throw new Error("No available member found.");
        return v.ctx.client.from("social_reports").insert({
          reporter_id: v.ctx.user.id, reported_user_id: lookup.data,
          reason: document.getElementById("social-report-reason").value,
          details: document.getElementById("social-report-details").value.trim()
        });
      });
    }).then(function (res) {
      if (res && res.error) throw new Error(res.error.message);
      document.getElementById("social-report-details").value = "";
      status("social-safety-status", "Report submitted privately for moderator review.", true);
    }).catch(function (e) { status("social-safety-status", e.message || "Could not submit report.", false); });
  }
  function loadModerationQueue() {
    var ctx = clientAndUser(), list = document.getElementById("social-moderation-list");
    if (!ctx.client || !ctx.user || !list) { status("social-moderation-status", "Sign in with the owner account to review reports.", false); return; }
    list.replaceChildren(); status("social-moderation-status", "Loading moderation queue…", true);
    ctx.client.rpc("list_social_reports").then(function (res) {
      if (res.error) { status("social-moderation-status", "Owner-only moderation queue unavailable: " + (res.error.message || "access denied"), false); return; }
      var rows = res.data || [];
      if (!rows.length) { status("social-moderation-status", "No open reports.", true); return; }
      status("social-moderation-status", rows.length + " report(s) awaiting review.", true);
      rows.forEach(function (report) {
        var card = el("article", { className: "panel" });
        card.appendChild(el("p", {}, report.reason + " · " + report.status + " · " + new Date(report.created_at).toLocaleString()));
        if (report.details) card.appendChild(el("p", {}, report.details));
        ["reviewing","resolved","dismissed"].forEach(function (nextStatus) {
          var b = el("button", { type: "button", className: "btn s" }, nextStatus);
          b.addEventListener("click", function () {
            ctx.client.rpc("review_social_report", { p_report_id: report.id, p_status: nextStatus }).then(function (done) {
              if (done.error) status("social-moderation-status", done.error.message || "Could not update report.", false);
              else loadModerationQueue();
            });
          });
          card.appendChild(b);
        });
        list.appendChild(card);
      });
    });
  }
  function requestFollow(rawUsername) {
    var ctx = clientAndUser(), name = (rawUsername || "").trim().replace(/^@/, "").toLowerCase();
    if (!ctx.client || !ctx.user) { status("social-follow-status", "Sign in to request a follow.", false); return; }
    if (!/^[a-z0-9_]{3,24}$/.test(name)) { status("social-follow-status", "Enter a valid username (3–24 letters, numbers, or underscores).", false); return; }
    status("social-follow-status", "Sending follow request…", true);
    ctx.client.rpc("request_social_follow", { p_username: name }).then(function (res) {
      if (res.error) { status("social-follow-status", res.error.message || "Follow request could not be sent.", false); return; }
      status("social-follow-status", "Follow request sent. Private profiles can accept or decline it.", true);
    });
  }
  function loadFeed() {
    var ctx = clientAndUser(), list = document.getElementById("social-feed-list");
    if (!list) return;
    list.replaceChildren();
    if (!ctx.client || !ctx.user) { status("social-feed-status", "Sign in to view your feed.", false); return; }
    status("social-feed-status", "Loading posts…", true);
    ctx.client.from("social_posts")
      .select("id,author_id,caption,audience,created_at")
      .eq("status", "published").order("created_at", { ascending: false }).limit(50)
      .then(function (res) {
        if (res.error) { status("social-feed-status", "Feed unavailable. Apply the social migrations to staging and confirm RLS policies.", false); return; }
        var posts = res.data || [];
        if (!posts.length) { status("social-feed-status", "No posts are visible yet. Create the first post or follow someone whose posts you want to see.", true); return; }
        status("social-feed-status", "Showing posts your account is allowed to access.", true);
        posts.forEach(function (p) {
          var card = el("article", { className: "panel" });
          card.appendChild(el("p", { className: "sub" }, (p.author_id === ctx.user.id ? "You" : "Clario member") + " · " + new Date(p.created_at).toLocaleString() + " · " + p.audience));
          var body = el("p", {}, p.caption); body.style.whiteSpace = "pre-wrap"; card.appendChild(body);
          var actions = el("div", { style: "display:flex;gap:8px;flex-wrap:wrap" });
          var like = el("button", { type: "button", className: "btn s" }, "Like");
          like.addEventListener("click", function () { toggleLike(p.id, like); });
          actions.appendChild(like);
          if (p.author_id !== ctx.user.id) {
            var reportPostButton = el("button", { type: "button", className: "btn s" }, "Report post");
            reportPostButton.addEventListener("click", function () { reportPost(p.id); });
            actions.appendChild(reportPostButton);
          }
          if (p.author_id === ctx.user.id) {
            var edit = el("button", { type: "button", className: "btn s" }, "Edit post");
            edit.addEventListener("click", function () { editPost(p.id, p.caption); });
            var remove = el("button", { type: "button", className: "btn s" }, "Delete post");
            remove.addEventListener("click", function () { deletePost(p.id); });
            actions.appendChild(edit);
            actions.appendChild(remove);
          }
          card.appendChild(actions);
          var comments = el("div", { style: "margin-top:12px" });
          var commentInput = el("input", { type: "text", maxlength: "1500", placeholder: "Write a comment…", style: "width:100%;min-height:48px;background:var(--nv);color:#fff;border:1px solid var(--cb);border-radius:12px;padding:8px 12px;font:inherit" });
          var commentButton = el("button", { type: "button", className: "btn s" }, "Comment");
          var commentList = el("div", {});
          commentButton.addEventListener("click", function () { addComment(p.id, commentInput, commentList); });
          comments.appendChild(commentInput); comments.appendChild(commentButton); comments.appendChild(commentList);
          card.appendChild(comments); list.appendChild(card);
          loadComments(p.id, commentList);
        });
      });
  }
  function reportPost(postId) {
    var ctx = clientAndUser();
    if (!ctx.client || !ctx.user) return;
    var reason = document.getElementById("social-report-reason");
    var details = document.getElementById("social-report-details");
    if (!window.confirm("Submit a private report for this post using the selected reason: " + reason.value + "?")) return;
    ctx.client.rpc("report_social_post", {
      p_post_id: postId,
      p_reason: reason.value,
      p_details: (details.value || "").trim()
    }).then(function (res) {
      if (res.error) { status("social-safety-status", res.error.message || "Could not report post.", false); return; }
      details.value = "";
      status("social-safety-status", "Post report submitted privately for moderator review.", true);
    });
  }
  function toggleLike(postId, button) {
    var ctx = clientAndUser();
    if (!ctx.client || !ctx.user) return;
    ctx.client.from("social_reactions").select("post_id").eq("post_id", postId).eq("user_id", ctx.user.id).maybeSingle()
      .then(function (res) {
        if (res.error) { button.textContent = "Reaction unavailable"; return; }
        var action = res.data
          ? ctx.client.from("social_reactions").delete().eq("post_id", postId).eq("user_id", ctx.user.id)
          : ctx.client.from("social_reactions").insert({ post_id: postId, user_id: ctx.user.id, reaction: "like" });
        action.then(function (done) { button.textContent = done.error ? "Try again" : (res.data ? "Like" : "Liked"); });
      });
  }
  function addComment(postId, input, list) {
    var ctx = clientAndUser(), body = input.value.trim();
    if (!ctx.client || !ctx.user) return;
    if (!body || body.length > 1500) return;
    ctx.client.from("social_comments").insert({ post_id: postId, author_id: ctx.user.id, body: body })
      .then(function (res) {
        if (res.error) { status("social-feed-status", "Comment could not be added: " + res.error.message, false); return; }
        input.value = ""; loadComments(postId, list);
      });
  }
  function loadComments(postId, list) {
    var ctx = clientAndUser();
    ctx.client.from("social_comments").select("id,author_id,body,created_at").eq("post_id", postId).order("created_at", { ascending: true }).limit(30)
      .then(function (res) {
        list.replaceChildren();
        if (res.error) return;
        (res.data || []).forEach(function (c) {
          var line = el("p", { style: "font-size:14px;color:var(--t2);margin:8px 0" }, (c.author_id === (ctx.user && ctx.user.id) ? "You: " : "Member: ") + c.body);
          list.appendChild(line);
          if (ctx.user && c.author_id === ctx.user.id) {
            var removeComment = el("button", { type: "button", className: "btn s" }, "Delete comment");
            removeComment.addEventListener("click", function () {
              if (!window.confirm("Delete your comment?")) return;
              ctx.client.from("social_comments").delete().eq("id", c.id).eq("author_id", ctx.user.id)
                .then(function (done) {
                  if (done.error) status("social-feed-status", "Comment could not be deleted: " + done.error.message, false);
                  else loadComments(postId, list);
                });
            });
            list.appendChild(removeComment);
          }
        });
      });
  }
  function editPost(postId, currentCaption) {
    var ctx = clientAndUser();
    if (!ctx.client || !ctx.user) return;
    var nextCaption = window.prompt("Edit your post (maximum 3000 characters):", currentCaption || "");
    if (nextCaption === null) return;
    nextCaption = nextCaption.trim();
    if (!nextCaption || nextCaption.length > 3000) {
      status("social-feed-status", "Post text must be between 1 and 3000 characters.", false);
      return;
    }
    ctx.client.from("social_posts")
      .update({ caption: nextCaption, updated_at: new Date().toISOString() })
      .eq("id", postId).eq("author_id", ctx.user.id)
      .then(function (res) {
        if (res.error) { status("social-feed-status", "Could not edit post: " + res.error.message, false); return; }
        loadFeed();
      });
  }
  function deletePost(postId) {
    var ctx = clientAndUser();
    if (!ctx.client || !ctx.user || !window.confirm("Delete this post? This cannot be undone.")) return;
    ctx.client.from("social_posts").delete().eq("id", postId).eq("author_id", ctx.user.id)
      .then(function (res) {
        if (res.error) { status("social-feed-status", "Could not delete post: " + res.error.message, false); return; }
        loadFeed();
      });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init); else init();
})();
