async function fetchJson(url, options) {
  const res = await fetch(url, {
    headers: { "Content-Type": "application/json", ...(options && options.headers) },
    ...options,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || res.statusText || "Request failed");
  }
  return data;
}

function el(tag, attrs, ...children) {
  const node = document.createElement(tag);
  Object.entries(attrs || {}).forEach(([key, value]) => {
    if (key === "className") node.className = value;
    else if (key.startsWith("on") && typeof value === "function") node.addEventListener(key.slice(2).toLowerCase(), value);
    else if (key === "checked") node.checked = value;
    else node.setAttribute(key, value);
  });
  children.flat().forEach((child) => {
    if (child == null || child === false) return;
    node.append(child.nodeType ? child : document.createTextNode(child));
  });
  return node;
}

const list = document.getElementById("task-list");
const empty = document.getElementById("empty");
const count = document.getElementById("count");
const listError = document.getElementById("list-error");
const form = document.getElementById("task-form");
const formStatus = document.getElementById("form-status");
const titleInput = document.getElementById("title");
const notesInput = document.getElementById("notes");

async function refreshInfo() {
  try {
    const info = await fetchJson("/api/info");
    document.getElementById("az").textContent = info.availability_zone;
    document.getElementById("iid").textContent = info.instance_id;
    document.getElementById("storage").textContent = info.storage;
  } catch {
    /* local render already has defaults */
  }
}

function render(tasks) {
  list.innerHTML = "";
  count.textContent = tasks.length ? `${tasks.length} item${tasks.length === 1 ? "" : "s"}` : "";
  empty.hidden = tasks.length > 0;
  tasks.forEach((task) => {
    const item = el("li", { className: task.done ? "done" : "" },
      el("input", {
        type: "checkbox",
        checked: task.done,
        "aria-label": "Mark done",
        onChange: async (event) => {
          try {
            await fetchJson(`/api/tasks/${task.id}`, {
              method: "PATCH",
              body: JSON.stringify({ done: event.target.checked }),
            });
            await load();
          } catch (err) {
            showListError(err.message);
          }
        },
      }),
      el("div", {},
        el("h3", {}, task.title),
        task.notes ? el("p", {}, task.notes) : null,
      ),
      el("div", { className: "actions" },
        el("button", {
          type: "button",
          className: "danger",
          onClick: async () => {
            try {
              await fetchJson(`/api/tasks/${task.id}`, { method: "DELETE" });
              await load();
            } catch (err) {
              showListError(err.message);
            }
          },
        }, "Delete"),
      ),
    );
    list.append(item);
  });
}

function showListError(message) {
  listError.hidden = !message;
  listError.textContent = message || "";
}

async function load() {
  showListError("");
  try {
    const data = await fetchJson("/api/tasks");
    render(data.tasks || []);
  } catch (err) {
    showListError(err.message);
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  formStatus.textContent = "Saving…";
  try {
    await fetchJson("/api/tasks", {
      method: "POST",
      body: JSON.stringify({
        title: titleInput.value,
        notes: notesInput.value,
      }),
    });
    titleInput.value = "";
    notesInput.value = "";
    formStatus.textContent = "Saved.";
    await load();
  } catch (err) {
    formStatus.textContent = err.message;
  }
});

refreshInfo();
load();
