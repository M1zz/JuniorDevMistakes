// 실수 100 웹 체험: 무료로 열린 첫 분야(코드 작성 습관)의 실수 10개를 앱과 같은 글로 읽고, 겪어 본 것은 체크한다.
// 글과 이름표는 앱의 문자열 카탈로그(Mistakes.xcstrings · Localizable.xcstrings)에서 그대로 가져온다.
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text), L = T.labels;
  const esc = s => s.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  const num = n => "#" + String(n).padStart(3, "0");
  const done = new Set();
  let current = 0;

  root.innerHTML = `
    <div class="jm-list">
      <div class="jm-head"><strong>${esc(T.category)}</strong><span class="jm-count" aria-live="polite"></span></div>
      <div class="jm-bar" aria-hidden="true"><i></i></div>
      <ol>${T.items.map((it, i) => `<li><button type="button" data-i="${i}">
        <span class="jm-check" aria-hidden="true"></span>
        <span><small>${num(it.n)}</small>${esc(it.mistake)}</span></button></li>`).join("")}</ol>
    </div>
    <article class="jm-detail" tabindex="-1"></article>`;

  const list = root.querySelector(".jm-list"), detail = root.querySelector(".jm-detail");
  const section = (cls, title, text) => `<section class="jm-sec ${cls}"><h3>${esc(title)}</h3><p>${esc(text)}</p></section>`;

  function render() {
    const it = T.items[current], isDone = done.has(current);
    detail.innerHTML = `
      <header><small>${num(it.n)}</small><h3 class="jm-title">${esc(it.mistake)}</h3>
        <button type="button" class="jm-done" aria-pressed="${isDone}">${esc(L.done)}</button></header>
      ${section("happens", L.happens, it.situation)}
      ${section("todo", L.todo, it.action)}
      ${section("learn", L.learn, it.growth)}
      <section class="jm-sec retro"><h3>${esc(L.retro)}</h3><p class="q"><b>Q1</b> ${esc(it.retro)}</p></section>`;
    list.querySelectorAll("[data-i]").forEach((b, i) => {
      b.classList.toggle("on", i === current);
      b.classList.toggle("done", done.has(i));
      b.setAttribute("aria-current", i === current ? "true" : "false");
    });
    list.querySelector(".jm-count").textContent = `${done.size} / ${T.items.length}`;
    list.querySelector(".jm-bar i").style.width = (done.size / T.items.length * 100) + "%";
  }

  root.addEventListener("click", e => {
    const pick = e.target.closest("[data-i]");
    if (pick) {
      current = +pick.dataset.i; render();
      if (matchMedia("(max-width: 760px)").matches) detail.focus({ preventScroll: true }), detail.scrollIntoView({ block: "start", behavior: "smooth" });
      return;
    }
    if (e.target.closest(".jm-done")) {
      done.has(current) ? done.delete(current) : done.add(current);
      render();
      root.querySelector(".jm-done").focus();
    }
  });

  render();
})();
