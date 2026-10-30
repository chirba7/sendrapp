// =============================================================================
// EPAVIE — test de charge k6 (API backend des apps citoyen et agent)
// -----------------------------------------------------------------------------
// CIBLE : PREPRODUCTION. Jamais la production (vraies données, vrais SMS).
// Si la préprod est sur la même machine que la prod, lancer la nuit.
//
//   k6 run -e SCENARIO=smoke   charge-epavie.js      (1 min, vérifie que tout répond)
//   k6 run -e SCENARIO=charge  charge-epavie.js      (journée chargée, ~20 min)
//   k6 run -e SCENARIO=stress  charge-epavie.js      (monte jusqu'à la rupture, ~25 min)
//   k6 run -e SCENARIO=pic     charge-epavie.js      (afflux soudain, ~5 min)
//   k6 run -e SCENARIO=endurance charge-epavie.js    (1 h, fuites mémoire)
//   k6 run -e SCENARIO=login   charge-epavie.js      (rafale de connexions, bcrypt)
//
// Options : -e BASE_URL=https://backpreprod.sendra.sn  -e ECRITURE=0 (pas de
// création de signalements)  -e PHOTO=1 (télécharge aussi les images comme
// l'app) ; résultats : --summary-export=output/k6-<scenario>.json
// =============================================================================
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { SharedArray } from 'k6/data';
import { Trend, Counter, Rate } from 'k6/metrics';
import encoding from 'k6/encoding';
import exec from 'k6/execution';

const BASE = (__ENV.BASE_URL || 'https://backpreprod.sendra.sn').replace(/\/$/, '') + '/api';
const SCENARIO = __ENV.SCENARIO || 'smoke';
const ECRITURE = (__ENV.ECRITURE || '1') === '1';
const PHOTO = (__ENV.PHOTO || '0') === '1';

if (BASE.includes('//backend.sendra.sn') && __ENV.JE_SAIS_CE_QUE_JE_FAIS !== 'oui') {
  throw new Error('BASE_URL pointe sur la PRODUCTION. Utiliser la préprod.');
}

const jetons = JSON.parse(open('./k6-jetons.json'));
const CITOYENS = new SharedArray('citoyens', () => jetons.citoyens);
const AGENTS = new SharedArray('agents', () => jetons.agents);
const PHOTO_B64 = encoding.b64encode(open('./photo-test.jpg', 'b'));

// Durées par endpoint, pour savoir lequel cède en premier.
const t = {
  communaute: new Trend('t_signalementsCommunaute', true),
  mes: new Trend('t_voirSignalements', true),
  me: new Trend('t_me', true),
  creation: new Trend('t_faireSignalement', true),
  liste: new Trend('t_listerSignalements', true),
  detail: new Trend('t_listerSignalement', true),
  stats: new Trend('t_statistiques', true),
  missions: new Trend('t_missions', true),
  login: new Trend('t_login', true),
  image: new Trend('t_image', true),
};
const limite429 = new Counter('reponses_429');
const erreurs5xx = new Counter('reponses_5xx');
const echecsMetier = new Rate('echecs_metier');

// --- Profils de charge ------------------------------------------------------
// 1 utilisateur virtuel (VU) = 1 personne qui enchaîne les écrans avec 3 à 10 s
// de pause : c'est PLUS intense qu'un vrai utilisateur (qui ouvre l'app quelques
// minutes par jour). Conversion VU → utilisateurs réels dans le rapport.
const profils = {
  smoke: { executor: 'constant-vus', vus: 2, duration: '1m' },
  charge: { executor: 'ramping-vus', startVUs: 0, stages: [
    { duration: '3m', target: 30 }, { duration: '5m', target: 60 },
    { duration: '10m', target: 60 }, { duration: '2m', target: 0 } ] },
  stress: { executor: 'ramping-vus', startVUs: 0, stages: [
    { duration: '2m', target: 50 }, { duration: '3m', target: 50 },
    { duration: '2m', target: 100 }, { duration: '3m', target: 100 },
    { duration: '2m', target: 200 }, { duration: '3m', target: 200 },
    { duration: '2m', target: 300 }, { duration: '3m', target: 300 },
    { duration: '2m', target: 400 }, { duration: '2m', target: 0 } ] },
  pic: { executor: 'ramping-vus', startVUs: 0, stages: [
    { duration: '30s', target: 10 }, { duration: '20s', target: 250 },
    { duration: '3m', target: 250 }, { duration: '1m', target: 0 } ] },
  endurance: { executor: 'constant-vus', vus: 50, duration: '1h' },
  login: { executor: 'ramping-arrival-rate', startRate: 1, timeUnit: '1s',
    preAllocatedVUs: 50, maxVUs: 200, stages: [
      { duration: '1m', target: 5 }, { duration: '2m', target: 20 },
      { duration: '1m', target: 0 } ], exec: 'connexion' },
};

export const options = {
  scenarios: { [SCENARIO]: profils[SCENARIO] },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
    't_signalementsCommunaute': ['p(95)<1500'],
    't_voirSignalements': ['p(95)<1500'],
    't_faireSignalement': ['p(95)<4000'],
    't_listerSignalements': ['p(95)<800'],
  },
  summaryTrendStats: ['avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
  insecureSkipTLSVerify: false,
};

function entetes(jeton) {
  return { headers: { Authorization: `Bearer ${jeton}`, Accept: 'application/json',
    'Content-Type': 'application/json' }, timeout: '30s' };
}

function suivre(res, trend, nom) {
  trend.add(res.timings.duration);
  if (res.status === 429) limite429.add(1);
  if (res.status >= 500) erreurs5xx.add(1);
  const ok = check(res, { [`${nom} 200`]: (r) => r.status === 200 });
  echecsMetier.add(!ok);
  return ok;
}

function pause(min, max) { sleep(min + Math.random() * (max - min)); }

// --- Parcours citoyen -------------------------------------------------------
function citoyen(jeton) {
  const p = entetes(jeton);
  group('citoyen : ouverture de l’app', () => {
    suivre(http.post(`${BASE}/me`, null, p), t.me, 'me');
    const r = http.get(`${BASE}/voirSignalements`, p);
    suivre(r, t.mes, 'voirSignalements');
  });
  pause(3, 8);

  group('citoyen : onglet Autres / carte', () => {
    const r = http.get(`${BASE}/signalementsCommunaute`, p);
    if (suivre(r, t.communaute, 'signalementsCommunaute') && PHOTO) {
      // L'app affiche les vignettes visibles : ~8 images à l'écran.
      const urls = (r.json() || []).map((s) => s.image_url).filter(Boolean).slice(0, 8);
      urls.forEach((u) => t.image.add(http.get(u, { timeout: '30s' }).timings.duration));
    }
  });
  pause(5, 10);

  // ~1 ouverture sur 10 se termine par un signalement.
  if (ECRITURE && Math.random() < 0.1) {
    group('citoyen : signaler', () => {
      const corps = JSON.stringify({
        vehicle_kind: 'Voiture',
        description: 'k6-test',
        commune: 'Dakar-Plateau',
        latitude: 14.67 + Math.random() * 0.05,
        longitude: -17.44 + Math.random() * 0.05,
        uuid: `k6-${exec.vu.idInTest}-${exec.vu.iterationInScenario}-${Date.now()}`,
        photos: [{ position: 'vue_ensemble', image: PHOTO_B64 }],
      });
      const r = http.post(`${BASE}/faireSignalement`, corps, entetes(jeton));
      suivre(r, t.creation, 'faireSignalement');
    });
    pause(3, 6);
  }
}

// --- Parcours agent ---------------------------------------------------------
function agent(jeton) {
  const p = entetes(jeton);
  let ids = [];
  group('agent : accueil', () => {
    const r = http.get(`${BASE}/listerSignalements`, p);
    if (suivre(r, t.liste, 'listerSignalements')) {
      ids = ((r.json() || {}).data || []).map((s) => s.signalementId);
    }
    suivre(http.get(`${BASE}/statistiques`, p), t.stats, 'statistiques');
  });
  pause(3, 8);
  if (ids.length) {
    group('agent : fiche', () => {
      const id = ids[Math.floor(Math.random() * ids.length)];
      suivre(http.get(`${BASE}/listerSignalement/${id}`, p), t.detail, 'listerSignalement');
    });
    pause(5, 12);
  }
  group('agent : missions', () => {
    suivre(http.get(`${BASE}/missions`, p), t.missions, 'missions');
  });
  pause(5, 10);
}

export default function () {
  // ~1 utilisateur sur 8 est un agent (rapport réel à ajuster).
  const vu = exec.vu.idInTest;
  if (vu % 8 === 0 && AGENTS.length) agent(AGENTS[vu % AGENTS.length]);
  else citoyen(CITOYENS[vu % CITOYENS.length]);
}

// Rafale de connexions : bcrypt coûte du CPU, et le limiteur par IP s'applique.
export function connexion() {
  const i = 1 + Math.floor(Math.random() * 200);
  const r = http.post(`${BASE}/login`, JSON.stringify({
    telephone: `700000${String(i).padStart(3, '0')}`, password: 'K6-Epavie-2026' }),
    { headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, timeout: '30s' });
  suivre(r, t.login, 'login');
}
