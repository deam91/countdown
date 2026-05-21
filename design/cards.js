/* ========================================================================
   Countdown — card data + DOM injection
   ======================================================================== */

// SVG sprite helpers
const svg = (id, cls = '') => `<svg class="${cls}"><use href="#${id}"/></svg>`;

// ---------- Image (CSS gradient) palettes -------------------------
// Desaturated, photo-like color blocks. Each entry returns the inline
// background CSS for a 96×96 image block, tinted to suggest its kind.
const imgRamen1 = `background:
  radial-gradient(circle at 50% 60%, #8a5b32 0 38%, transparent 39%),
  radial-gradient(circle at 50% 60%, #2b1a0f 0 46%, transparent 47%),
  linear-gradient(180deg, #3a2718, #1c120a);`;
const imgRamen2 = `background:
  radial-gradient(circle at 40% 55%, #c4884d 0 32%, transparent 33%),
  radial-gradient(ellipse at 60% 70%, #6e3e1e 0 28%, transparent 30%),
  linear-gradient(180deg, #2d1e10, #181008);`;
const imgRamen3 = `background:
  radial-gradient(circle at 50% 55%, #b87d44 0 36%, transparent 38%),
  radial-gradient(circle at 30% 30%, rgba(245,196,106,0.25) 0 18%, transparent 20%),
  linear-gradient(180deg, #2a1c10, #14080a);`;
const imgRamen4 = `background:
  radial-gradient(circle at 55% 60%, #a26e3c 0 34%, transparent 36%),
  linear-gradient(180deg, #221610, #110a08);`;
const imgRamen5 = `background:
  radial-gradient(circle at 45% 55%, #d39556 0 30%, transparent 32%),
  linear-gradient(180deg, #2a1810, #150b09);`;
const imgBowl   = `background:
  radial-gradient(circle at 50% 55%, #c98a48 0 38%, transparent 40%),
  radial-gradient(circle at 35% 40%, rgba(0,0,0,0.4) 0 8%, transparent 10%),
  radial-gradient(circle at 65% 60%, rgba(0,0,0,0.35) 0 7%, transparent 9%),
  linear-gradient(180deg, #2e1e12, #1a0f0a);`;
// Book cover
const imgBook = `background:
  linear-gradient(180deg, rgba(245,196,106,0.18), transparent 40%),
  radial-gradient(circle at 50% 30%, rgba(239,184,200,0.30) 0 22%, transparent 23%),
  linear-gradient(160deg, #3b2a1b 0%, #1a1108 100%);`;
// Person avatar — warm portrait
const imgPerson = `background:
  radial-gradient(circle at 50% 38%, #8a6a4b 0 18%, transparent 19%),
  radial-gradient(ellipse at 50% 80%, #5a3f28 0 40%, transparent 42%),
  linear-gradient(180deg, #4a3526, #20140d);`;

// ---------- Data --------------------------------------------------
// Tokyo ramen list — kinds intentionally mixed to demo the card system.
const items = [
  { rank: 10, kind: 'place',   title: 'Ichiran Shibuya',  sub: '5-1 Udagawa-chō · Shibuya',         why: 'The original solo booth — tonkotsu by the bowlful',     score: 82, img: imgRamen1, address: 'Shibuya' },
  { rank: 9,  kind: 'place',   title: 'Afuri Roppongi',   sub: '4-2-35 Nishi-Azabu · Minato',       why: 'Yuzu-shio so bright it almost glows in the bowl',       score: 85, img: imgRamen2 },
  { rank: 8,  kind: 'book',    title: 'Ramen Otaku',      sub: 'by Brian MacDuckston · 2024',       why: 'The cookbook every Tokyo ramen pilgrim quietly owns',   score: 86, img: imgBook, stars: 4.3 },
  { rank: 7,  kind: 'place',   title: 'Tsuta',            sub: '1-14-1 Sugamo · Toshima',           why: 'First Michelin star in ramen history. Truffle shoyu.',  score: 88, img: imgRamen3 },
  { rank: 6,  kind: 'person',  title: 'Ivan Orkin',       sub: 'The gaijin who taught Tokyo shoyu', why: 'Brooklyn import. Reverse-engineered the dashi rulebook.', score: 89, img: imgPerson },
  { rank: 5,  kind: 'place',   title: 'Nakiryu',          sub: '2-34-4 Minami-Ōtsuka · Toshima',    why: 'Tantanmen rated 9.1 by every chili-oil obsessive',      score: 91, img: imgRamen4 },
  { rank: 4,  kind: 'generic', title: 'Hand-pulled tsukemen', sub: 'a signature regional style',    why: 'Thick noodle, thicker broth, dunked then devoured',     score: 92, img: imgBowl },
];

// Top-3 for the reveal screen
const topThree = [
  { rank: 3, tier: 3, kind: 'place', title: 'Tanaka Shoten',  sub: '1-12-3 Sangenjaya · Setagaya',  why: 'Iekei pork-and-soy gold standard. Garlic optional.',     score: 93, img: imgRamen5 },
  { rank: 2, tier: 2, kind: 'place', title: 'Tonchin',        sub: '1-22-1 Higashi-Ikebukuro',      why: 'The miso bowl that converted Hokkaido sceptics',         score: 95, img: imgRamen2 },
  { rank: 1, tier: 1, kind: 'place', title: 'Mensho Tokyo',   sub: '2-4-1 Shimo-Ochiai · Shinjuku', why: 'A lamb-broth maverick. Hand-pulled, koji-aged, perfect.', score: 96, img: imgRamen3 },
];

// Full ranking for the share preview (10 items)
const fullList = [
  { rank: 1,  tier: 1, title: 'Mensho Tokyo',        score: 9.6 },
  { rank: 2,  tier: 2, title: 'Tonchin',             score: 9.5 },
  { rank: 3,  tier: 3, title: 'Tanaka Shoten',       score: 9.3 },
  { rank: 4,  title: 'Hand-pulled tsukemen',         score: 9.2 },
  { rank: 5,  title: 'Nakiryu',                      score: 9.1 },
  { rank: 6,  title: 'Ivan Orkin',                   score: 8.9 },
  { rank: 7,  title: 'Tsuta',                        score: 8.8 },
  { rank: 8,  title: 'Ramen Otaku',                  score: 8.6 },
  { rank: 9,  title: 'Afuri Roppongi',               score: 8.5 },
  { rank: 10, title: 'Ichiran Shibuya',              score: 8.2 },
];

// ---------- Card renderer ----------------------------------------
function tierCls(tier) {
  return tier === 1 ? 'tier-ring-gold' : tier === 2 ? 'tier-ring-silver' : tier === 3 ? 'tier-ring-bronze' : '';
}
function stripCls(tier) {
  return tier === 1 ? 'strip-gold' : tier === 2 ? 'strip-silver' : tier === 3 ? 'strip-bronze' : 'strip-neutral';
}
function pillCls(tier) {
  return tier === 1 ? 'pill-gold' : tier === 2 ? 'pill-silver' : tier === 3 ? 'pill-bronze' : '';
}
function pillLabel(tier) {
  return tier === 1 ? 'GOLD' : tier === 2 ? 'SILVER' : tier === 3 ? 'BRONZE' : '';
}

function thumbHTML(item, podiumLarge = false) {
  if (item.kind === 'book') {
    return `<div class="thumb book" style="${item.img}"></div>`;
  }
  if (item.kind === 'person') {
    return `<div class="thumb circ" style="${item.img}"></div>`;
  }
  // generic / place — square
  return `<div class="thumb" style="${item.img}"></div>`;
}

function sublineHTML(item) {
  if (item.kind === 'book') {
    const filled = Math.round((item.stars || item.score/2));
    let stars = '';
    for (let i = 0; i < 5; i++) {
      stars += `<svg class="${i < filled ? '' : 'off'}"><use href="#${i < filled ? 'i-star' : 'i-star-empty'}"/></svg>`;
    }
    return `<div class="subline">${item.sub} <span class="star-mini">${stars}</span></div>`;
  }
  if (item.kind === 'person') {
    return `<div class="subline" style="font-style:italic">${item.sub}</div>`;
  }
  if (item.kind === 'place') {
    return `<div class="subline">${svg('i-pin','icon-14')} ${item.sub}</div>`;
  }
  // generic — no subline
  return '';
}

function placeMapStrip() {
  return `<div class="map-strip">
    <div class="tile-bg"></div>
    <div class="road r1"></div>
    <div class="road r2"></div>
    <div class="road r3"></div>
    <div class="pin-mini">${svg('i-pin')}</div>
  </div>`;
}

function rankNumHTML(rank, tier) {
  const top = tier && tier <= 3;
  return top
    ? `<span class="rank-num" style="color:#fff">${rank}</span>`
    : `<span class="rank-num rank-num-rest">${rank}</span>`;
}

function cardHTML(item, opts = {}) {
  const tier = item.tier;
  const isTop = tier && tier <= 3;
  const tierClass = isTop ? `tier-${tier} ${tierCls(tier)}` : '';
  const rankClass = isTop ? 'rank-top' : '';
  const animClass = opts.animClass || `r${item.rank}`;
  const podiumClass = opts.podiumClass || '';
  const kindClass = item.kind === 'place' ? 'card-place' : `card-${item.kind}`;

  const badge = isTop
    ? `<div class="badge-row"><span class="badge ${pillCls(tier)}">${pillLabel(tier)}</span></div>`
    : '';

  const subline = sublineHTML(item);

  // place cards get a map strip in addition to subline
  const mapStrip = item.kind === 'place' ? placeMapStrip() : '';

  // score bar width
  const scoreStyle = `--score:${item.score}%`;

  return `
    <div class="card ${kindClass} ${rankClass} ${tierClass} ${animClass} ${podiumClass}" style="${scoreStyle}">
      <div class="strip ${stripCls(tier)}">
        ${rankNumHTML(item.rank, tier)}
      </div>
      <div class="content">
        ${badge}
        <div class="title">${item.title}</div>
        ${subline}
        <div class="why">${item.why}</div>
        ${mapStrip}
        <div class="score-track"><span class="score-fill"></span></div>
      </div>
      ${thumbHTML(item)}
    </div>
  `;
}

function skeletonHTML(rank) {
  return `
    <div class="skeleton-card">
      <div class="sk-strip"><span class="sk-q">?</span></div>
      <div class="sk-body">
        <div class="sk-row shimmer" style="width:30%"></div>
        <div class="sk-row shimmer" style="width:75%; height:18px"></div>
        <div class="sk-row shimmer" style="width:55%"></div>
        <div class="sk-bar shimmer" style="width:100%"></div>
      </div>
      <div class="sk-thumb shimmer"></div>
    </div>
  `;
}

// ---------- Mount ranking screen ----------------------------------
const list = document.getElementById('streaming-cards');
if (list) {
  // 7 visible cards (ranks 10 → 4), then 3 skeletons (3,2,1)
  list.innerHTML =
    items.map(it => cardHTML(it)).join('') +
    [3, 2, 1].map(r => skeletonHTML(r)).join('');
}

// ---------- Mount reveal screen (podium) --------------------------
const podium = document.getElementById('podium-cards');
if (podium) {
  // Order: 3, 2, 1 stacked; #1 largest at bottom
  podium.innerHTML = [
    cardHTML(topThree[0], { podiumClass: 'podium-3' }),
    cardHTML(topThree[1], { podiumClass: 'podium-2' }),
    cardHTML(topThree[2], { podiumClass: 'podium-1' }),
  ].join('');
}

// ---------- Mount share mini list ---------------------------------
const sharelist = document.getElementById('share-mini-list');
if (sharelist) {
  sharelist.innerHTML = fullList.map(it => `
    <div class="mini-card ${it.tier ? `mc-${it.tier}` : ''}">
      <div class="mc-rank">${it.rank}</div>
      <div class="mc-title">${it.title}</div>
      <div class="mc-score">${it.score.toFixed(1)}</div>
    </div>
  `).join('');
}

// ---------- Confetti burst (static, hand-placed for the mockup) ---
const confetti = document.getElementById('confetti');
if (confetti) {
  // 12 gold particles arranged around the #1 card area (lower-mid)
  // {x, y, rot, w, h, color}
  const particles = [
    { x: 80,  y: 470, r:  -20, w: 5, h: 11, c: '#F5C46A' },
    { x: 120, y: 440, r:   15, w: 6, h: 10, c: '#E2A647' },
    { x: 160, y: 420, r:  -45, w: 4, h: 12, c: '#F5C46A' },
    { x: 200, y: 410, r:   25, w: 6, h: 9,  c: '#C9892A' },
    { x: 240, y: 425, r:    8, w: 5, h: 11, c: '#F5C46A' },
    { x: 280, y: 450, r:  -10, w: 4, h: 10, c: '#E2A647' },
    { x: 320, y: 480, r:   40, w: 6, h: 10, c: '#F5C46A' },
    { x: 100, y: 510, r:    0, w: 4, h: 12, c: '#C9892A' },
    { x: 180, y: 530, r:  -25, w: 5, h: 9,  c: '#F5C46A' },
    { x: 250, y: 520, r:   55, w: 6, h: 11, c: '#E2A647' },
    { x: 60,  y: 540, r:   30, w: 4, h: 9,  c: '#C9892A' },
    { x: 300, y: 560, r:  -15, w: 5, h: 11, c: '#F5C46A' },
  ];
  confetti.innerHTML = particles.map(p => `
    <span class="p" style="
      left:${p.x}px; top:${p.y}px;
      width:${p.w}px; height:${p.h}px;
      background:${p.c}; color:${p.c};
      transform: rotate(${p.r}deg);
    "></span>
  `).join('');
}

// ---------- Retry countdown (decrementing) ------------------------
(function retryCountdown(){
  const a = document.getElementById('retry-n');
  const b = document.getElementById('retry-n2');
  if (!a || !b) return;
  let n = 12;
  setInterval(() => {
    n -= 1;
    if (n < 0) n = 12;
    a.textContent = n;
    b.textContent = n;
  }, 1000);
})();
