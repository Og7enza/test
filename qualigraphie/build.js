// Génère les artefacts de la Noōgraphie depuis noemes.js :
//   - glyphes/<id>.svg          (un fichier par noème, réutilisable)
//   - planche.svg               (la planche spécimen complète)
//   - index.html                (la vitrine interactive, SVG en ligne)
//
// Usage : node qualigraphie/build.js
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { VIEWBOX, TRAITS, VERBES, OBJETS, PENSEES } from "./noemes.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const GLYPH_DIR = join(HERE, "glyphes");
mkdirSync(GLYPH_DIR, { recursive: true });

const STROKE = 8.5;

// Transforme un « élément » (path abrégé ou balise complète) en SVG.
function renderEl(el) {
  const t = el.trim();
  if (t.startsWith("<")) return "    " + t;
  return `    <path d="${t}"/>`;
}

// Le groupe stylé qui contient tous les traits d'un noème.
function glyphGroup(g, { dash = false } = {}) {
  const extra = dash || g.dash ? ' stroke-dasharray="4 9"' : "";
  const body = g.els.map(renderEl).join("\n");
  return `  <g fill="none" stroke="currentColor" stroke-width="${STROKE}" stroke-linecap="round" stroke-linejoin="round"${extra}>
${body}
  </g>`;
}

// Un SVG autonome pour un noème.
function standaloneSvg(g) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${VIEWBOX} ${VIEWBOX}" role="img" aria-label="${g.nom}">
  <title>${g.nom} — ${g.code}</title>
${glyphGroup(g)}
</svg>
`;
}

const groups = [
  { key: "verbe", titre: "Verbes", data: VERBES },
  { key: "objet", titre: "Objets", data: OBJETS },
  { key: "pensee", titre: "Pensées", data: PENSEES },
];

// 1) SVG individuels
let count = 0;
for (const grp of groups) {
  for (const g of grp.data) {
    writeFileSync(join(GLYPH_DIR, `${g.id}.svg`), standaloneSvg(g));
    count++;
  }
}

// 2) Planche spécimen : tous les noèmes sur une grille.
function planche() {
  const cols = 6;
  const cell = 150;
  const pad = 26;
  const rows = [];
  let items = [];
  const push = (label) => items.push({ label });
  for (const grp of groups) {
    // saut de section : compléter la ligne courante
    while (items.length % cols !== 0) push(null);
    for (const g of grp.data) items.push({ g, section: grp.titre });
  }
  const total = Math.ceil(items.length / cols) * cols;
  while (items.length < total) items.push(null);
  const rowsN = items.length / cols;
  const W = cols * cell + pad * 2;
  const H = rowsN * cell + pad * 2 + 60;
  let out = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" font-family="Georgia, 'Times New Roman', serif">
  <rect width="${W}" height="${H}" fill="#0f1220"/>
  <text x="${W / 2}" y="42" fill="#e9e4d6" font-size="30" text-anchor="middle" letter-spacing="3">NOŌGRAPHIE — PLANCHE DES NOÈMES</text>
`;
  items.forEach((it, i) => {
    if (!it || !it.g) return;
    const c = i % cols;
    const r = Math.floor(i / cols);
    const x = pad + c * cell;
    const y = 60 + pad + r * cell;
    const g = it.g;
    out += `  <g transform="translate(${x} ${y})" color="#e9e4d6">
    <rect x="6" y="6" width="${cell - 12}" height="${cell - 12}" fill="none" stroke="#2c3350" stroke-width="1"/>
    <text x="18" y="30" fill="#e7b455" font-size="18" font-weight="700">${escapeXml(g.code)}</text>
    <g transform="translate(${cell / 2 - VIEWBOX / 2}, 14) scale(1)">
${glyphGroup(g).replace(/^/gm, "  ")}
    </g>
    <text x="${cell / 2}" y="${cell - 18}" fill="#e9e4d6" font-size="16" text-anchor="middle">${g.nom}</text>
  </g>
`;
  });
  out += "</svg>\n";
  return out;
}

function escapeXml(s) {
  return String(s).replace(/[<>&]/g, (m) => ({ "<": "&lt;", ">": "&gt;", "&": "&amp;" }[m]));
}

writeFileSync(join(HERE, "planche.svg"), planche());

// 3) Vitrine HTML interactive
function cardsFor(grp) {
  return grp.data
    .map(
      (g) => `      <figure class="noeme" data-code="${escapeXml(g.code)}">
        <div class="glyph">
          <svg viewBox="0 0 ${VIEWBOX} ${VIEWBOX}" aria-label="${g.nom}">
${glyphGroup(g).replace(/^/gm, "    ")}
          </svg>
        </div>
        <figcaption>
          <span class="code">${escapeXml(g.code)}</span>
          <b>${g.nom}</b>
          <small>${g.trait ? "trait&nbsp;: " + g.trait : g.formule ? "= " + escapeXml(g.formule) : ""}</small>
          <p>${g.sens}</p>
        </figcaption>
      </figure>`
    )
    .join("\n");
}

// Table de correspondance pour le petit traducteur.
const map = {};
for (const g of [...VERBES, ...OBJETS, ...PENSEES]) map[g.code] = g;
const jsMap = JSON.stringify(
  Object.fromEntries(
    Object.entries(map).map(([k, g]) => [k, { id: g.id, nom: g.nom, els: g.els, dash: !!g.dash }])
  )
);

const html = `<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Noōs — la qualigraphie des idées</title>
<style>
  :root{
    --bg:#0f1220; --ink:#ece7d8; --dim:#8b93c0; --line:#2c3350;
    --accent:#e7b455; --accent2:#7fd0c4;
  }
  *{box-sizing:border-box}
  body{margin:0;background:radial-gradient(1200px 600px at 50% -10%,#1a2038,#0f1220 60%);
    color:var(--ink);font-family:Georgia,"Times New Roman",serif;line-height:1.6}
  header{padding:64px 24px 28px;text-align:center}
  header h1{font-size:clamp(38px,7vw,74px);margin:0;letter-spacing:6px;font-weight:400}
  header .sub{color:var(--accent);letter-spacing:3px;text-transform:uppercase;font-size:13px;margin-top:8px}
  header p{max-width:640px;margin:18px auto 0;color:var(--dim)}
  main{max-width:1080px;margin:0 auto;padding:0 20px 100px}
  h2{font-size:26px;font-weight:400;letter-spacing:1px;margin:56px 0 6px;
    border-bottom:1px solid var(--line);padding-bottom:10px}
  h2 small{color:var(--dim);font-size:14px;letter-spacing:0;margin-left:10px}
  .grid{display:grid;gap:14px;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));margin-top:22px}
  .noeme{margin:0;border:1px solid var(--line);border-radius:14px;overflow:hidden;
    background:linear-gradient(180deg,#161b31,#11142400);transition:.25s}
  .noeme:hover{border-color:var(--accent);transform:translateY(-3px)}
  .glyph{aspect-ratio:1/1;display:grid;place-items:center;padding:18px;color:var(--ink);
    background:repeating-linear-gradient(0deg,#12162700,#12162700 22px,#1b2140 23px),
               repeating-linear-gradient(90deg,#12162700,#12162700 22px,#1b2140 23px);
    border-bottom:1px solid var(--line)}
  .noeme:hover .glyph{color:var(--accent2)}
  .glyph svg{width:74%;height:74%}
  figcaption{padding:12px 14px 16px}
  figcaption .code{float:right;font-size:22px;color:var(--accent);font-weight:700}
  figcaption b{display:block;font-size:17px}
  figcaption small{color:var(--dim)}
  figcaption p{margin:8px 0 0;font-size:13.5px;color:#c8c8dd}
  .traits{display:grid;gap:10px;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));margin-top:22px}
  .trait{border:1px dashed var(--line);border-radius:10px;padding:12px 14px}
  .trait b{color:var(--accent2)} .trait .m{font-size:26px;margin-right:8px}
  .lab{margin-top:26px;border:1px solid var(--line);border-radius:16px;padding:22px;background:#12162a}
  .lab input{width:100%;font:inherit;font-size:20px;padding:12px 14px;border-radius:10px;
    border:1px solid var(--line);background:#0c0f1c;color:var(--ink)}
  .lab .out{display:flex;flex-wrap:wrap;gap:12px;margin-top:18px;min-height:90px;align-items:center}
  .lab .tok{display:grid;place-items:center;width:76px}
  .lab .tok svg{width:60px;height:60px;color:var(--accent2)}
  .lab .tok small{color:var(--dim);font-size:11px;margin-top:4px}
  .lab .hint{color:var(--dim);font-size:13px;margin-top:10px}
  .compo{display:flex;gap:14px;align-items:center;flex-wrap:wrap;margin-top:20px}
  .compo .op{font-size:34px;color:var(--accent)}
  .compo .box{width:120px;height:120px;border:1px solid var(--line);border-radius:12px;
    display:grid;place-items:center;color:var(--ink)}
  .compo .box svg{width:80%;height:80%}
  footer{text-align:center;color:var(--dim);padding:40px 20px;border-top:1px solid var(--line);font-size:13px}
  a{color:var(--accent)}
</style>
</head>
<body>
<header>
  <div class="sub">langage cognitif · une idée = un signe</div>
  <h1>NOŌS</h1>
  <p>Un langage qui ne compresse plus les <i>mots</i> mais les <i>idées</i>.
     Sa qualigraphie — la <b>Noōgraphie</b> — dessine chaque unité de pensée
     (chaque <b>noème</b>) en un seul geste tracé.</p>
</header>
<main>

  <h2>Les traits primitifs <small>l'alphabet des gestes</small></h2>
  <div class="traits">
${TRAITS.map(([n, m, d]) => `    <div class="trait"><span class="m">${escapeXml(m)}</span><b>${n}</b><br><small>${d}</small></div>`).join("\n")}
  </div>

  <h2>Verbes <small>primitives cognitives</small></h2>
  <div class="grid">
${cardsFor(groups[0])}
  </div>

  <h2>Objets <small>les référents</small></h2>
  <div class="grid">
${cardsFor(groups[1])}
  </div>

  <h2>Clé de composition <small>verbe (haut) + objet (bas) = noème composé</small></h2>
  <div class="compo">
    <div class="box" id="c-verbe"></div>
    <span class="op">+</span>
    <div class="box" id="c-objet"></div>
    <span class="op">→</span>
    <div class="box" id="c-fusion"></div>
    <div style="color:var(--dim);max-width:320px">
      Exemple : <b>Observer</b> (l'arc) posé sur <b>Monde</b> (l'arc fermé) se lit
      <code>Ow</code> et se dessine d'un trait : « regarder le monde ».
    </div>
  </div>

  <h2>Pensées <small>un dessin = un raisonnement entier</small></h2>
  <div class="grid">
${cardsFor(groups[2])}
  </div>

  <h2>Le traducteur <small>tapez un code Noōs, lisez la qualigraphie</small></h2>
  <div class="lab">
    <input id="src" value="O w C p + s Φ" spellcheck="false"
      placeholder="ex : O w C p + s Φ"/>
    <div class="out" id="out"></div>
    <div class="hint">Codes reconnus : verbes (O C + ? ! M P = &amp; X), objets (w m k p s h u b),
      pensées (Ω Φ Ψ Δ α). Les espaces sont optionnels.</div>
  </div>

</main>
<footer>
  Noōgraphie — écriture inventée pour le langage Noōs.
  Voir <a href="planche.svg">la planche des noèmes</a> et
  <a href="CONCEPT.md">le concept complet</a>.
</footer>

<script>
const MAP = ${jsMap};
const VB = ${VIEWBOX};
function svgFor(g){
  const dash = g.dash ? ' stroke-dasharray="4 9"' : '';
  const body = g.els.map(function(e){
    e = e.trim();
    return e[0]==='<' ? e : '<path d="'+e+'"/>';
  }).join('');
  return '<svg viewBox="0 0 '+VB+' '+VB+'"><g fill="none" stroke="currentColor" stroke-width="${STROKE}" stroke-linecap="round" stroke-linejoin="round"'+dash+'>'+body+'</g></svg>';
}
function tokenize(s){
  const known = Object.keys(MAP);
  const toks = [];
  for(const ch of s){ if(ch.trim()==='') continue; if(known.includes(ch)) toks.push(ch); }
  return toks;
}
function render(){
  const out = document.getElementById('out');
  out.innerHTML='';
  const toks = tokenize(document.getElementById('src').value);
  if(!toks.length){ out.innerHTML='<span style="color:var(--dim)">…</span>'; return; }
  for(const t of toks){
    const g = MAP[t];
    const d = document.createElement('div'); d.className='tok';
    d.innerHTML = svgFor(g) + '<small>'+g.nom+'</small>';
    out.appendChild(d);
  }
}
document.getElementById('src').addEventListener('input', render);
render();

// démonstration de composition
document.getElementById('c-verbe').innerHTML = svgFor(MAP['O']);
document.getElementById('c-objet').innerHTML = svgFor(MAP['w']);
// fusion : verbe en haut (réduit) + objet en bas (réduit)
(function(){
  const v = MAP['O'], o = MAP['w'];
  function scaled(g, ty, s){
    const dash = g.dash ? ' stroke-dasharray="4 9"' : '';
    const body = g.els.map(function(e){e=e.trim();return e[0]==='<'?e:'<path d="'+e+'"/>';}).join('');
    return '<g transform="translate('+(VB/2-VB*s/2)+' '+ty+') scale('+s+')"><g fill="none" stroke="currentColor" stroke-width="'+(${STROKE}/s)+'" stroke-linecap="round" stroke-linejoin="round"'+dash+'>'+body+'</g></g>';
  }
  document.getElementById('c-fusion').innerHTML =
    '<svg viewBox="0 0 '+VB+' '+VB+'" style="color:var(--accent)">'+
    scaled(v, -6, 0.6) + scaled(o, 46, 0.55) + '</svg>';
})();
</script>
</body>
</html>
`;

writeFileSync(join(HERE, "index.html"), html);

console.log(`✓ ${count} glyphes SVG écrits dans qualigraphie/glyphes/`);
console.log("✓ planche.svg");
console.log("✓ index.html");
