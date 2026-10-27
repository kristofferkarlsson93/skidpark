// Local interaction sketches. Curves and metrics are deliberately fictional.
'use strict';

const icons = {
  back: '<path d="m14 5-7 7 7 7"/>',
  next: '<path d="m9 5 7 7-7 7"/>',
  down: '<path d="m6 9 6 6 6-6"/>',
  close: '<path d="m6 6 12 12M18 6 6 18"/>',
  play: '<circle cx="12" cy="12" r="9"/><path d="m10 8 6 4-6 4Z"/>',
  more: '<circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/>',
  filter: '<path d="M4 6h6m4 0h6M4 12h10m4 0h2M4 18h2m4 0h10M10 3v6m4 0v6m-8 0v6"/>',
  expand: '<path d="M8 3H3v5m13-5h5v5M3 16v5h5m8 0h5v-5"/>',
  graph: '<path d="M3 3v18h18M5 17l5-8 4 3 6-7"/>',
  release: '<path d="M12 3v18M3 8h6L6 5m3 3-3 3m15 5h-6l3-3m-3 3 3 3"/>',
  book: '<path d="M12 5c-3-2-6-2-9-1v15c3-1 6-1 9 1m0-15c3-2 6-2 9-1v15c-3-1-6-1-9 1Zm0 0v15"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6m0-10v1"/>',
  volume: '<path d="M11 4 5 9H2v6h3l6 5ZM15 8c3 2 3 6 0 8m3-11c5 4 5 10 0 14"/>',
  skis: '<path d="m7 3 5 17c1 3 4 1 3-1L10 3M3 3l5 17c1 3 4 1 3-1L6 3M17 3l4 18"/>',
  check: '<path d="m5 12 4 4L19 6"/>',
};
const icon = (name) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name] || icons.info}</svg>`;
const button = (action, content, className = '', label = '') => `<button class="${className}" data-action="${action}"${label ? ` aria-label="${label}" title="${label}"` : ''}>${content}</button>`;
const iconButton = (action, name, label, extra = '') => button(action, icon(name), `icon-button ${extra}`, label);
const runs = [
  { id: 1, ski: 'SP1', color: '#70ddc5', max: '33,4', mean: '22,6', distance: '142', time: '22,6', phase: 0, delta: 'Referens' },
  { id: 2, ski: 'SP2', color: '#b1a4ff', max: '33,1', mean: '22,4', distance: '140', time: '22,5', phase: 1, delta: '+1,1 m' },
  { id: 3, ski: 'SP1', color: '#f5c86b', max: '33,6', mean: '22,9', distance: '145', time: '22,8', phase: 2, delta: '+2,0 m' },
  { id: 4, ski: 'SP2', color: '#7db9ff', max: '33,2', mean: '22,5', distance: '141', time: '22,6', phase: 3, delta: '+0,7 m', warning: true },
];
const concepts = {
  a: { title: 'A / SYNLIGA FLIKAR', heading: 'Allt syns. Inget behöver upptäckas.', description: 'Vyvalen får namn i en flikrad under grafen. Hjälp ligger i en egen flik. Sidopanelen behåller åkurval och beräkning; den öppnas med reglageknappen vid grafen.', tradeoff: 'Lätt att förstå. Vid fler vyer behöver flikraden kunna rullas i sidled.', tasks: ['Byt mellan Översikt, Släppunkt och Guide.', 'Öppna reglagen och välj bort ett åk.', 'Markera en åkrad och dra över grafen.'] },
  b: { title: 'B / SVEPSIDOR', heading: 'En liten guidebok runt grafen.', description: 'Guide, Översikt och Släppunkt blir sidor. Svep i nederdelen eller använd pilarna. Ett tomt test öppnas på guiden; ett test med åk öppnas på översikten.', tradeoff: 'Lugn och rymlig. Svepytan måste läras in, och många sidor blir fler svep.', tasks: ['Svep åt vänster i nederdelen.', 'Dra i grafen: sidan ska ligga kvar.', 'Öppna reglagen och byt sedan sida.'] },
  c: { title: 'C / SAMLAD VYVÄLJARE', heading: 'Välj efter vad du vill undersöka.', description: 'En namngiven vyväljare öppnar en meny med korta förklaringar. Urval har en egen knapp bredvid. Sidopanelens innehåll gäller alla vyer.', tradeoff: 'Rymmer många analyser utan fler knappar. Ett vybyte kräver två tryck.', tasks: ['Öppna Översikt-knappen och välj Släppunkt.', 'Tryck Urval och prova Medel per skida.', 'Öppna guiden via vyväljaren.'] },
};
function initialState(concept, hasRuns) {
  return { concept, hasRuns, page: concept === 'b' && !hasRuns ? 'guide' : 'overview', selected: new Set([1, 2, 3, 4]), highlight: null, average: false, fusion: true, release: 78, analyzed: false, overlay: null, recordingSki: 'SP1', recording: false };
}
const route = location.hash.slice(1).split('/');
let state = initialState(concepts[route[0]] ? route[0] : 'a', route[1] === 'runs');
let overlayOrigin = null;
const app = document.querySelector('#app');
const overlays = document.querySelector('#overlays');
const viewNames = { overview: 'Översikt', release: 'Släppunkt', guide: 'Guide' };

function displayRuns() {
  const selected = state.hasRuns ? runs.filter(run => state.selected.has(run.id)) : [];
  if (!state.average) return selected;
  return ['SP1', 'SP2'].flatMap(ski => {
    const group = selected.filter(run => run.ski === ski);
    return group.length ? [{ ...group[0], id: ski, count: group.length, warning: group.some(run => run.warning) }] : [];
  });
}
function routeState() {
  history.replaceState(null, '', `#${state.concept}/${state.hasRuns ? 'runs' : 'empty'}`);
}
function render() {
  document.querySelectorAll('[data-concept]').forEach(el => el.setAttribute('aria-pressed', el.dataset.concept === state.concept));
  document.querySelectorAll('[data-scenario]').forEach(el => el.setAttribute('aria-pressed', (el.dataset.scenario === 'runs') === state.hasRuns));
  const concept = concepts[state.concept];
  document.querySelector('#preview-name').textContent = concept.title;
  document.querySelector('#concept-note').innerHTML = `<h2>${concept.heading}</h2><p>${concept.description}</p><p class="tradeoff"><strong>Avvägning.</strong> ${concept.tradeoff}</p><ol>${concept.tasks.map(task => `<li>${task}</li>`).join('')}</ol>`;
  app.innerHTML = `<section class="graph-region" aria-label="${state.page === 'guide' ? 'Guide till glidtestet' : 'Graf: hastighet över sträcka'}">${topbar()}${graphContent()}${graphTools()}</section><section class="lower" aria-label="Vyval och åk" data-swipe-zone>${navigation()}${lowerContent()}</section>`;
  bindGraph(app);
  bindSwipe();
  renderOverlay();
}
function topbar() {
  return `<header class="topbar">${iconButton('tests', 'back', 'Till tester')}<div class="test-name"><strong>Sörskog</strong>27 okt · 2 skidor</div>${button('new-run', `${icon('play')}Nytt åk`, 'new-run')}${iconButton('more', 'more', 'Mer om testet')}</header>`;
}
function graphTools() {
  if (state.page === 'guide') return '';
  const changed = state.selected.size < 4 || state.average || !state.fusion;
  return `<div class="graph-tools">${state.concept !== 'c' ? button('drawer', `${icon('filter')}${changed && state.hasRuns ? '<span class="badge">•</span>' : ''}`, 'icon-button tool', 'Urval och beräkning') : ''}${state.hasRuns && displayRuns().length ? iconButton('fullscreen', 'expand', 'Visa graf i helskärm', 'tool') : ''}</div>`;
}
function skiChips() { return '<div class="ski-chips"><span class="ski-chip"><i></i>SP1</span><span class="ski-chip"><i></i>SP2</span></div>'; }
function emptyArt() { return `<div class="empty-art"><svg viewBox="0 0 110 66" fill="none" aria-hidden="true"><path d="M8 58C20 58 30 13 52 13S82 58 102 58" stroke="currentColor" stroke-width="2" stroke-dasharray="3 5" opacity=".5"/><circle cx="8" cy="58" r="4" fill="#70ddc5"/><circle cx="52" cy="13" r="4" fill="currentColor"/><path d="M48 59h12m-6-6v12" stroke="currentColor" stroke-width="2"/></svg></div>`; }
function graphContent() {
  if (state.page === 'guide') return `<div class="guide-hero"><span class="eyebrow">EN PERSON. FLERA GLIDÅK.</span><h2>Lär känna glidet.<br>Ett åk i taget.</h2><p>Gör upprepade åk i samma backe. Jämför sedan kurvorna och variationen mellan åken.</p><div class="guide-step"><span>1</span>Välj skida och spela in.</div><div class="guide-step"><span>2</span>Upprepa med nästa skida.</div><div class="guide-step"><span>3</span>Granska skillnaderna i grafen.</div>${button('new-run', 'Spela in ett åk →', 'text-button')}</div>`;
  if (!state.hasRuns) {
    const headline = state.concept === 'c' ? 'Två skidor.\nNästa steg: ett åk.' : 'Ditt test är redo.';
    return `<div class="empty-hero">${emptyArt()}<span class="eyebrow">SÖRSKOG · INGA ÅK ÄN</span><h2>${headline.replace('\n', '<br>')}</h2><p>${state.page === 'release' ? 'Spela först in några åk. Sedan kan du undersöka glidet från en gemensam, simulerad släppunkt.' : 'Spela in ditt första glidåk. Här växer kurvorna fram när du har sparat.'}</p>${skiChips()}${button('new-run', `${icon('play')}Spela in första åket`, 'primary')}</div>`;
  }
  if (!displayRuns().length) return `<div class="empty-hero"><span class="eyebrow">4 ÅK FINNS I TESTET</span><h2>Vilka åk vill du se?</h2><p>Alla åk är dolda just nu. Välj i sidopanelen eller visa alla igen.</p><div style="height:20px"></div>${button('select-all', 'Visa alla 4 åk', 'primary')}</div>`;
  return `${chart()}<span class="graph-caption">${state.page === 'release' ? 'Streckad linje = vald släppunkt' : 'Tryck eller dra för att läsa av'}</span>`;
}
function speedAt(run, distance) {
  const duration = 142 + (run.phase === 2 ? 3 : -run.phase);
  const fraction = Math.max(0, Math.min(1, distance / duration));
  return Math.pow(Math.sin(Math.PI * fraction), 0.92) * (33.4 + Math.sin(run.phase * 2) * .3) + Math.sin(fraction * 15 + run.phase) * Math.sin(Math.PI * fraction) * .23;
}
const graphX = distance => 44 + distance / 150 * 327;
const graphY = speed => 424 - speed / 40 * 310;
function chart() {
  const lines = displayRuns();
  const ordered = [...lines].sort((a, b) => Number(a.id === state.highlight) - Number(b.id === state.highlight));
  return `<svg class="chart" viewBox="0 0 390 475" preserveAspectRatio="none" role="img" aria-label="Fiktiv hastighetsgraf. Hastighet i kilometer per timme, sträcka i meter.">
    ${[0, 10, 20, 30, 40].map(value => `<line class="grid" x1="44" x2="371" y1="${graphY(value)}" y2="${graphY(value)}"/><text x="33" y="${graphY(value) + 3}" text-anchor="end">${value}</text>`).join('')}
    <text x="17" y="94">km/h</text>
    ${[0, 30, 60, 90, 120, 150].map(value => `<text x="${graphX(value)}" y="445" text-anchor="${value === 150 ? 'end' : 'middle'}">${value === 150 ? '150 m' : value}</text>`).join('')}
    ${ordered.map(run => `<path data-curve="${run.id}" class="curve ${state.highlight !== null && run.id !== state.highlight ? 'dim' : ''} ${run.id === state.highlight ? 'highlight' : ''}" stroke="${run.color}" ${run.ski === 'SP2' ? 'stroke-dasharray="7 4"' : ''} d="${Array.from({ length: 101 }, (_, i) => { const x = i * 1.5; return `${i ? 'L' : 'M'}${graphX(x).toFixed(2)},${graphY(speedAt(run, x)).toFixed(2)}`; }).join(' ')}"/>`).join('')}
    ${state.page === 'release' ? `<line data-release-line x1="${graphX(state.release)}" x2="${graphX(state.release)}" y1="126" y2="424" stroke="#f5c86b" stroke-width="1.5" stroke-dasharray="5 4"/><text data-release-label x="${graphX(state.release) + 5}" y="141" style="fill:#f5c86b">${state.release} m</text>` : ''}
    <g data-cursor visibility="hidden"><line x1="0" x2="0" y1="128" y2="424" stroke="#f7f5ff" opacity=".6"/><circle r="4" fill="#f7f5ff"/></g>
  </svg>`;
}
function navigation() {
  if (state.concept === 'a') return `<nav class="view-nav" aria-label="Analysvyer" role="tablist">${['overview', 'release', 'guide'].map(page => `<button role="tab" aria-selected="${state.page === page}" data-page="${page}">${viewNames[page]}</button>`).join('')}</nav>`;
  if (state.concept === 'b') {
    const pages = ['guide', 'overview', 'release'];
    const index = pages.indexOf(state.page);
    return `<nav class="swipe-nav" aria-label="Byt sida"><button class="icon-button" data-step="-1" aria-label="Föregående sida" ${index === 0 ? 'disabled' : ''}>${icon('back')}</button><div class="swipe-title">${viewNames[state.page]}<span class="page-dots" aria-label="Sida ${index + 1} av 3">${pages.map(page => `<i class="${page === state.page ? 'active' : ''}"></i>`).join('')}</span></div><button class="icon-button" data-step="1" aria-label="Nästa sida" ${index === 2 ? 'disabled' : ''}>${icon('next')}</button></nav>`;
  }
  return `<nav class="view-picker-bar" aria-label="Analys och urval">${button('view-picker', `${icon(state.page === 'overview' ? 'graph' : state.page === 'release' ? 'release' : 'book')}${viewNames[state.page]}${icon('down')}`, 'view-picker-trigger')}${button('drawer', `${icon('filter')}Urval${state.hasRuns ? ` ${state.selected.size}/4` : ''}`, 'filter-trigger')}</nav>`;
}
function summary() {
  if (!state.hasRuns || state.page === 'guide') return '';
  return `<div class="selection-summary">${button('drawer', `${icon('filter')}${state.selected.size} av 4 åk · ${state.average ? 'Medel per skida' : 'Enskilda åk'}`)}<span class="selection-method">${state.fusion ? 'GPS + sensorer' : 'GPS'}</span></div>`;
}
function lowerContent() {
  const swipeHint = state.concept === 'b' ? '<div class="swipe-hint">← Svep här nere för att byta sida →</div>' : '';
  let content;
  if (state.page === 'guide') content = helpCards();
  else if (!state.hasRuns) content = emptyLower();
  else if (!displayRuns().length) content = '<div class="empty-inline"><h3>Inga åk valda</h3><p>Åken finns kvar i testet.</p></div>';
  else if (state.page === 'release') content = releaseContent();
  else content = runList();
  return `${summary()}<div class="lower-scroll ${!state.hasRuns ? 'empty-lower' : ''}">${content}</div>${swipeHint}`;
}
function emptyLower() {
  if (state.concept === 'c') return `<div class="help-title"><strong>Vad vill du göra?</strong></div>${button('new-run', `${icon('play')}<span><strong>Spela in ett åk</strong><small>Välj skida och börja i backen</small></span><span class="task-arrow">→</span>`, 'task-link')}${button('guide', `${icon('book')}<span><strong>Få grepp om glidtestet</strong><small>Teståk, volymknappar och analys</small></span><span class="task-arrow">→</span>`, 'task-link')}`;
  return `<div class="help-title"><strong>${state.page === 'release' ? 'Innan du simulerar ett släpp' : 'Bra att veta i backen'}</strong></div>${helpCards(true)}`;
}
function runList() {
  return displayRuns().map(run => `<button class="run-row ${state.highlight === run.id ? 'selected' : ''}" data-run="${run.id}" aria-pressed="${state.highlight === run.id}"><div class="run-title"><span class="line-symbol ${run.ski === 'SP2' ? 'dashed' : ''}" style="--line:${run.color}"></span>${state.average ? run.ski : `Åk ${run.id} · ${run.ski}`}<small>${state.average ? `${run.count} åk` : 'Visa kurva'}</small></div><div class="run-stats"><div><label>Medelfart</label><span>${run.mean}</span> <em>km/h</em></div><div><label>Maxfart</label><span>${run.max}</span> <em>km/h</em></div><div><label>Sträcka</label><span>${run.distance}</span> <em>m</em></div><div><label>Tid</label><span>${run.time}</span> <em>s</em></div></div>${run.warning ? '<div class="quality-warning">△ GPS-avbrott i åk 4 · tolka med försiktighet</div>' : ''}</button>`).join('');
}
function helpCards(compact = false) {
  return `<details class="help-card"><summary>${icon('skis')}Så gör du ett glidåk</summary><div class="help-body"><ol><li>Välj en backe där du kan glida säkert. Starta på samma plats.</li><li>Välj skida och starta inspelningen. Håll telefonen i handen på liknande sätt.</li><li>Glid utan att staka. Försök hålla samma kroppsställning.</li><li>Stoppa och spara. Upprepa med båda skidorna, gärna flera gånger.</li></ol></div></details><details class="help-card"><summary>${icon('volume')}Använd volymknapparna</summary><div class="help-body"><span class="platform-tag">ANDROID</span><p><strong>I testet:</strong> håll in volym ner för Nytt åk.</p><p><strong>I skidvalet:</strong> kort tryck upp/ner byter markering. Håll in volym ner för att starta med markerad skida.</p><p><strong>Under åket:</strong> ett kort tryck på volym ner stoppar och sparar.</p><p>På iPhone använder du knapparna på skärmen.</p></div></details>${compact ? '' : `<details class="help-card"><summary>${icon('graph')}Läs kurvorna tillsammans</summary><div class="help-body"><p>I Översikt ser du hastighet över sträcka. Tryck på ett åk för att markera dess kurva, och dra i grafen för att läsa av.</p><p>Jämför upprepade åk: är skillnaden mellan skidor större än variationen med samma skida? GPS-avbrott visas vid åket.</p></div></details><details class="help-card"><summary>${icon('release')}Vad är simulerad släppunkt?</summary><div class="help-body"><p>Ett sätt att undersöka hur glidet skiljer sig efter en vald punkt, med en beräknad gemensam startfart.</p><p>Det är en modellbaserad uppskattning. Välj punkt, granska kurvorna och jämför med variationen mellan upprepade åk. Vyn avgör inte vilken skida som är bäst.</p></div></details>`}`;
}
function releaseContent() {
  if (!state.analyzed) return `<div class="release-intro">Undersök glidet från en gemensam punkt. Flytta linjen med reglaget.</div><div class="release-slider"><label for="release-distance">Simulerad släppunkt <output id="release-value">${state.release} m</output></label><input id="release-distance" data-control="release" type="range" min="30" max="115" step="1" value="${state.release}">${button('analyze', 'Analysera från punkten', 'primary')}</div>`;
  return `<div class="release-heading"><strong>Simulerat släpp · ${state.release} m</strong>${button('adjust', 'Justera')}</div><div class="notice">Uppskattade skillnader. Jämför också variationen mellan åk med samma skida.</div>${displayRuns().map(run => `<div class="release-result"><span class="line-symbol ${run.ski === 'SP2' ? 'dashed' : ''}" style="--line:${run.color}"></span><span>${state.average ? run.ski : `Åk ${run.id} · ${run.ski}`}<small>${run.warning ? '△ GPS-avbrott i åk 4' : 'Beräknad sträcka efter punkten'}</small></span><strong>${run.delta}</strong></div>`).join('')}`;
}

function drawerContent() {
  return `<div class="overlay-body"><p class="panel-note">Samma urval och beräkning följer med mellan analysvyerna.</p><div class="section-label"><span>Åk att visa · ${state.hasRuns ? `${state.selected.size} av 4` : '0 åk'}</span>${state.hasRuns ? button('toggle-all', state.selected.size === 4 ? 'Avmarkera alla' : 'Markera alla') : ''}</div>${state.hasRuns ? runs.map(run => `<label class="check-row"><input type="checkbox" data-control="run" data-id="${run.id}" ${state.selected.has(run.id) ? 'checked' : ''}><span class="line-symbol ${run.ski === 'SP2' ? 'dashed' : ''}" style="--line:${run.color}"></span><span>Åk ${run.id} · ${run.ski}</span><small>${run.warning ? '△ GPS' : `${run.max} km/h`}</small></label>`).join('') : '<p class="panel-note">Här väljer du åk när du har spelat in ditt första.</p>'}<div class="drawer-group"><span class="eyebrow">VISNING</span><label class="switch-row"><span><strong>Medel per skida</strong><small>Samla valda åk till en kurva per skida.</small></span><input type="checkbox" aria-label="Medel per skida" data-control="average" ${state.average ? 'checked' : ''} ${!state.hasRuns ? 'disabled' : ''}></label></div><div class="drawer-group"><span class="eyebrow">BERÄKNING</span><label class="switch-row"><span><strong>GPS + sensorer</strong><small>${state.fusion ? 'Hastigheten uppskattas med båda källorna.' : 'Endast GPS används för hastigheten.'}</small></span><input type="checkbox" aria-label="GPS och sensorer" data-control="fusion" ${state.fusion ? 'checked' : ''}></label><details class="expert"><summary>Vad påverkar det här?</summary><p>Beräkningssättet kan påverka kurvor och värden. Rådata bevaras. Ett jämnare utseende säger inte i sig att uppskattningen är säkrare.</p><p>I den här prototypen ändras etiketten, men inga värden räknas om.</p></details></div>${button('drawer-guide', `${icon('book')} Hjälp med test och analys`, 'text-button')}</div><footer class="drawer-footer">${button('close', `Visa ${state.hasRuns ? state.selected.size : '0'} åk`, 'primary')}<p>Valen används direkt · gäller alla analysvyer</p></footer>`;
}
function sheet(title, body, extra = '') {
  return `<section class="bottom-sheet ${extra}" role="dialog" aria-modal="true" aria-label="${title}" tabindex="-1"><div class="sheet-handle"></div><header class="overlay-header"><h2>${title}</h2>${iconButton('close', 'close', 'Stäng')}</header><div class="overlay-body">${body}</div></section>`;
}
function viewChoices() {
  const descriptions = { overview: 'Se hela åket och jämför hastighetskurvor.', release: 'Undersök glidet efter en vald punkt.', guide: 'Så testar du, navigerar och tolkar.' };
  return `<p class="panel-note">Vad vill du titta närmare på?</p>${['overview', 'release', 'guide'].map(page => `<button class="view-choice ${state.page === page ? 'active' : ''}" data-page="${page}"><span class="choice-icon">${icon(page === 'overview' ? 'graph' : page === 'release' ? 'release' : 'book')}</span><span><strong>${page === 'release' ? 'Simulerad släppunkt' : viewNames[page]}</strong><small>${descriptions[page]}</small></span>${state.page === page ? `<span class="checkmark">${icon('check')}</span>` : ''}</button>`).join('')}<p class="panel-note" style="margin-top:16px">Åkurvalet följer med när du byter vy.</p>`;
}
function recordingScreen() {
  const title = state.recording ? 'Spelar in' : 'Nytt åk';
  return `<section class="full-screen" role="dialog" aria-modal="true" aria-label="${title}" tabindex="-1"><header class="overlay-header"><h2>${title}</h2>${iconButton('close', 'close', 'Avbryt och återgå till testet')}</header><div class="recording-body">${state.recording ? '<div class="recording-clock">00:12</div><p class="demo-label">Demoinspelning · inga sensorer används</p>' : `<span class="eyebrow">SÖRSKOG</span><h2 style="margin-top:14px">Vilken skida åker du med?</h2><p>Välj en av testets skidor.</p>${['SP1', 'SP2'].map(ski => `<button class="view-choice ${state.recordingSki === ski ? 'active' : ''}" data-ski="${ski}"><span class="choice-icon">${icon('skis')}</span><span><strong>${ski}</strong><small>${ski === 'SP1' ? 'Fischer Speedmax' : 'Atomic Redster'}</small></span>${state.recordingSki === ski ? `<span class="checkmark">${icon('check')}</span>` : ''}</button>`).join('')}<p class="panel-note">Förenklad skiss av inspelningsflödet. Start och spara visar bara nästa exempelbild.</p>`}</div><footer class="recording-footer">${button(state.recording ? 'save-demo' : 'start-demo', state.recording ? 'Stoppa och spara' : `${icon('play')}Starta åk`, 'primary')}</footer></section>`;
}
function renderOverlay() {
  const scrollTop = overlays.querySelector('.overlay-body')?.scrollTop || 0;
  const focusedControl = document.activeElement?.dataset.control;
  const focusedId = document.activeElement?.dataset.id;
  if (!state.overlay) { overlays.innerHTML = ''; return; }
  let content = '';
  if (state.overlay === 'drawer') content = `<aside class="drawer" role="dialog" aria-modal="true" aria-label="Urval och beräkning" tabindex="-1"><header class="overlay-header"><h2>Urval & beräkning</h2>${iconButton('close', 'close', 'Stäng sidopanelen')}</header>${drawerContent()}</aside>`;
  if (state.overlay === 'view-picker') content = sheet('Välj analysvy', viewChoices());
  if (state.overlay === 'more') content = sheet('Sörskog', `${button('test-info', `${icon('info')}<span><strong>Om testet</strong><small>Skidor, datum och antal åk</small></span><span class="task-arrow">→</span>`, 'task-link')}${button('drawer-guide', `${icon('book')}<span><strong>Guide till glidtestet</strong><small>Teståk, volymknappar och analys</small></span><span class="task-arrow">→</span>`, 'task-link')}`);
  if (state.overlay === 'test-info') content = sheet('Om testet', `<div class="test-info"><strong>Sörskog</strong>27 oktober 2026 · ${state.hasRuns ? 4 : 0} åk<strong>Skidor i testet</strong>SP1 · Fischer Speedmax<br>SP2 · Atomic Redster<strong>Anteckning</strong>Jämför i samma backe. Upprepa med båda paren.</div>`);
  if (state.overlay === 'help') content = sheet('Guide till glidtestet', helpCards(), 'help-sheet');
  if (state.overlay === 'fullscreen') content = `<section class="full-screen" role="dialog" aria-modal="true" aria-label="Graf i helskärm" tabindex="-1"><header class="overlay-header"><h2>${viewNames[state.page]}</h2>${iconButton('close', 'close', 'Stäng helskärm')}</header><div class="selection-summary">${state.selected.size} av 4 åk · ${state.average ? 'Medel per skida' : 'Enskilda åk'}<span class="selection-method">${state.fusion ? 'GPS + sensorer' : 'GPS'}</span></div><div class="graph-region">${chart()}</div><div class="selection-summary">Tryck eller dra för att läsa av · fiktiva kurvor</div></section>`;
  if (state.overlay === 'recording') content = recordingScreen();
  if (state.overlay === 'tests') content = `<section class="full-screen" role="dialog" aria-modal="true" aria-label="Tester" tabindex="-1"><header class="overlay-header"><h2>Tester</h2>${iconButton('close', 'close', 'Återgå till testet')}</header><div class="overlay-body"><p class="panel-note">Endast testarbetsytan utforskas i den här prototypen.</p>${button('close', `${icon('graph')}<span><strong>Sörskog</strong><small>27 oktober · 2 skidor · ${state.hasRuns ? 4 : 0} åk</small></span><span class="task-arrow">→</span>`, 'task-link')}</div></section>`;
  overlays.innerHTML = `<div class="overlay"><button class="scrim" data-action="close" aria-label="Stäng panelen" tabindex="-1"></button>${content}</div>`;
  if (state.overlay === 'fullscreen') bindGraph(overlays);
  if (focusedControl) {
    const candidates = [...overlays.querySelectorAll('[data-control]')];
    const restore = candidates.find(el => el.dataset.control === focusedControl && el.dataset.id === focusedId);
    restore?.focus({ preventScroll: true });
  }
  const body = overlays.querySelector('.overlay-body');
  if (body) body.scrollTop = scrollTop;
}
function openOverlay(name) {
  overlayOrigin = document.activeElement;
  state.overlay = name;
  renderOverlay();
  overlays.querySelector('[role="dialog"]')?.focus();
}
function closeOverlay() {
  state.overlay = null;
  renderOverlay();
  if (overlayOrigin?.isConnected) overlayOrigin.focus({ preventScroll: true });
  else app.querySelector('[data-action="more"]')?.focus({ preventScroll: true });
}
function changePage(page) {
  state.page = page;
  state.overlay = null;
  render();
}
function stepPage(step) {
  const pages = ['guide', 'overview', 'release'];
  const next = pages.indexOf(state.page) + step;
  if (next >= 0 && next < pages.length) changePage(pages[next]);
}
function changeScenario(hasRuns) {
  state = initialState(state.concept, hasRuns);
  routeState();
  render();
}
const actions = {
  drawer: () => openOverlay('drawer'),
  'view-picker': () => openOverlay('view-picker'),
  more: () => openOverlay('more'),
  'test-info': () => openOverlay('test-info'),
  tests: () => openOverlay('tests'),
  fullscreen: () => openOverlay('fullscreen'),
  close: closeOverlay,
  guide: () => changePage('guide'),
  'drawer-guide': () => { state.overlay = 'help'; renderOverlay(); overlays.querySelector('[role="dialog"]')?.focus(); },
  'select-all': () => { state.selected = new Set([1, 2, 3, 4]); render(); },
  'toggle-all': () => { state.selected = state.selected.size === 4 ? new Set() : new Set([1, 2, 3, 4]); state.highlight = null; render(); },
  analyze: () => { state.analyzed = true; render(); },
  adjust: () => { state.analyzed = false; render(); },
  'new-run': () => { state.recording = false; openOverlay('recording'); },
  'start-demo': () => { state.recording = true; renderOverlay(); overlays.querySelector('[role="dialog"]')?.focus(); },
  'save-demo': () => changeScenario(true),
};
let suppressClickUntil = 0;
document.addEventListener('click', event => {
  if (Date.now() < suppressClickUntil) { event.preventDefault(); return; }
  const conceptButton = event.target.closest('[data-concept]');
  if (conceptButton) {
    state.concept = conceptButton.dataset.concept;
    state.page = state.concept === 'b' && !state.hasRuns ? 'guide' : 'overview';
    state.overlay = null;
    routeState();
    render();
    return;
  }
  const scenario = event.target.closest('[data-scenario]');
  if (scenario) { changeScenario(scenario.dataset.scenario === 'runs'); return; }
  const pageButton = event.target.closest('[data-page]');
  if (pageButton) { changePage(pageButton.dataset.page); return; }
  const step = event.target.closest('[data-step]');
  if (step && !step.disabled) { stepPage(Number(step.dataset.step)); return; }
  const run = event.target.closest('[data-run]');
  if (run) {
    const id = state.average ? run.dataset.run : Number(run.dataset.run);
    const scrollTop = app.querySelector('.lower-scroll').scrollTop;
    state.highlight = state.highlight === id ? null : id;
    render();
    app.querySelector('.lower-scroll').scrollTop = scrollTop;
    app.querySelector(`[data-run="${id}"]`)?.focus({ preventScroll: true });
    return;
  }
  const ski = event.target.closest('[data-ski]');
  if (ski) { state.recordingSki = ski.dataset.ski; renderOverlay(); overlays.querySelector(`[data-ski="${state.recordingSki}"]`)?.focus(); return; }
  const action = event.target.closest('[data-action]')?.dataset.action;
  if (action && actions[action]) actions[action]();
});
document.querySelector('#reset').addEventListener('click', () => changeScenario(state.hasRuns));
document.addEventListener('change', event => {
  const control = event.target.dataset.control;
  if (!control || control === 'release') return;
  if (control === 'run') {
    const id = Number(event.target.dataset.id);
    if (event.target.checked) state.selected.add(id); else state.selected.delete(id);
    state.highlight = null;
  }
  if (control === 'average') { state.average = event.target.checked; state.highlight = null; }
  if (control === 'fusion') state.fusion = event.target.checked;
  render();
});
document.addEventListener('input', event => {
  if (event.target.dataset.control !== 'release') return;
  state.release = Number(event.target.value);
  document.querySelector('#release-value').textContent = `${state.release} m`;
  const x = graphX(state.release);
  app.querySelectorAll('[data-release-line]').forEach(line => { line.setAttribute('x1', x); line.setAttribute('x2', x); });
  app.querySelectorAll('[data-release-label]').forEach(label => { label.setAttribute('x', x + 5); label.textContent = `${state.release} m`; });
});
document.addEventListener('keydown', event => {
  if (!state.overlay) return;
  if (event.key === 'Escape') { event.preventDefault(); closeOverlay(); return; }
  if (event.key !== 'Tab') return;
  const dialog = overlays.querySelector('[role="dialog"]');
  const focusable = [...dialog.querySelectorAll('button:not(:disabled), input:not(:disabled), summary, a[href]')].filter(el => el.getClientRects().length);
  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  if (event.shiftKey && (document.activeElement === first || document.activeElement === dialog)) { event.preventDefault(); last?.focus(); }
  else if (!event.shiftKey && (document.activeElement === last || document.activeElement === dialog)) { event.preventDefault(); first?.focus(); }
});
function bindGraph(root) {
  root.querySelectorAll('.chart').forEach(svg => {
    let dragging = false;
    function readGraph(event) {
      const rect = svg.getBoundingClientRect();
      const svgX = (event.clientX - rect.left) / rect.width * 390;
      const distance = Math.round(Math.max(0, Math.min(150, (svgX - 44) / 327 * 150)));
      const run = displayRuns().find(item => item.id === state.highlight) || displayRuns()[0];
      if (!run) return;
      const speed = speedAt(run, distance);
      const cursor = svg.querySelector('[data-cursor]');
      const x = graphX(distance);
      cursor.setAttribute('visibility', 'visible');
      cursor.querySelector('line').setAttribute('x1', x);
      cursor.querySelector('line').setAttribute('x2', x);
      cursor.querySelector('circle').setAttribute('cx', x);
      cursor.querySelector('circle').setAttribute('cy', graphY(speed));
      let tooltip = svg.parentElement.querySelector('.chart-tooltip');
      if (!tooltip) { tooltip = document.createElement('div'); tooltip.className = 'chart-tooltip'; svg.parentElement.append(tooltip); }
      tooltip.innerHTML = `${state.average ? run.ski : `Åk ${run.id} · ${run.ski}`} &nbsp; ${distance} m &nbsp; <strong>${speed.toFixed(1).replace('.', ',')} km/h</strong>`;
    }
    svg.addEventListener('pointerdown', event => { dragging = true; svg.setPointerCapture(event.pointerId); readGraph(event); });
    svg.addEventListener('pointermove', event => { if (dragging) readGraph(event); });
    svg.addEventListener('pointerup', () => { dragging = false; });
    svg.addEventListener('pointercancel', () => { dragging = false; });
  });
}
function bindSwipe() {
  if (state.concept !== 'b') return;
  const zone = app.querySelector('[data-swipe-zone]');
  let start = null;
  zone.addEventListener('pointerdown', event => {
    if (event.target.closest('input, .swipe-nav, .selection-summary')) return;
    start = { x: event.clientX, y: event.clientY };
  });
  zone.addEventListener('pointerup', event => {
    if (!start) return;
    const dx = event.clientX - start.x;
    const dy = event.clientY - start.y;
    start = null;
    if (Math.abs(dx) > 55 && Math.abs(dx) > Math.abs(dy) * 1.6) {
      suppressClickUntil = Date.now() + 300;
      stepPage(dx < 0 ? 1 : -1);
    }
  });
  zone.addEventListener('pointercancel', () => { start = null; });
}
window.addEventListener('hashchange', () => {
  const next = location.hash.slice(1).split('/');
  state = initialState(concepts[next[0]] ? next[0] : 'a', next[1] === 'runs');
  render();
});
render();
