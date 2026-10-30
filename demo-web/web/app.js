/* Démo du back-office EPAVIE : mêmes vues que les gabarits Blade de sendraApp,
   alimentées par des données fictives gardées dans le navigateur du visiteur. */
(function () {
'use strict';
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const ph = n => 'photos/' + n;
const MOIS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const p2 = n => String(n).padStart(2, '0');
// Mêmes formats que les vues (Carbon::format, non traduit).
const fLong = d => `${p2(d.getDate())} ${MOIS[d.getMonth()]} ${d.getFullYear()} à ${p2(d.getHours())}h${p2(d.getMinutes())}`;
const fCourt = d => `${p2(d.getDate())}/${p2(d.getMonth() + 1)}/${d.getFullYear()} à ${p2(d.getHours())}:${p2(d.getMinutes())}`;
const fDate = d => `${p2(d.getDate())}/${p2(d.getMonth() + 1)}/${d.getFullYear()}`;
const fDH = d => `${p2(d.getDate())}/${p2(d.getMonth() + 1)}/${d.getFullYear()} ${p2(d.getHours())}:${p2(d.getMinutes())}`;
const J = (jours, h, m) => { const d = new Date(2026, 9, 29, h, m); d.setDate(d.getDate() - jours); return d.toISOString(); };

/* ───────── Données fictives (mêmes signalements que les apps de démo) ───────── */
const USERS = [
  { id: 1, first_name: 'Mariama', last_name: 'Diallo', email: 'admin@sendra.sn', telephone: '774102210', role: 1 },
  { id: 6, first_name: 'Serigne', last_name: 'Mbaye', email: 's.mbaye@sendra.sn', telephone: '774102211', role: 1 },
  { id: 2, first_name: 'Cheikh', last_name: 'Ndiaye', email: 'c.ndiaye@sendra.sn', telephone: '771234567', role: 2 },
  { id: 3, first_name: 'Aminata', last_name: 'Sow', email: 'a.sow@sendra.sn', telephone: '762223140', role: 2 },
  { id: 4, first_name: 'Ibrahima', last_name: 'Sarr', email: 'i.sarr@sendra.sn', telephone: '785551022', role: 2 },
  { id: 5, first_name: 'Moussa', last_name: 'Diallo', email: 'm.diallo@sendra.sn', telephone: '709014418', role: 2 },
  { id: 7, first_name: 'Lamine', last_name: 'Thiam', email: 'l.thiam@mairie-hann.sn', telephone: '773001212', role: 3 },
  { id: 8, first_name: 'Astou', last_name: 'Seck', email: 'a.seck@mairie-medina.sn', telephone: '773004545', role: 3 },
  { id: 9, first_name: 'Aliou', last_name: 'Ba', email: 'prefecture.dakar@demo.sn', telephone: '338001010', role: 4 },
  { id: 12, first_name: 'Bineta', last_name: 'Ndour', email: 'operations@sendra.sn', telephone: '774102230', role: 7 },
  { id: 10, first_name: 'Awa', last_name: 'Diop', email: 'awa.diop@exemple.sn', telephone: '771234567', role: 5 },
  { id: 11, first_name: 'Fatou', last_name: 'Ba', email: 'fatou.ba@exemple.sn', telephone: '781112233', role: 5 },
  { id: 13, first_name: 'Mamadou', last_name: 'Gueye', email: 'm.gueye@exemple.sn', telephone: '766543210', role: 5 },
  { id: 14, first_name: 'Khady', last_name: 'Fall', email: 'khady.fall@exemple.sn', telephone: '705551212', role: 5 },
];
const ROLE_UI = { 1: ['admin', 'Administration', 'lni-cog'], 3: ['commune', 'Autorité communale', 'lni-apartment'], 4: ['prefecture', 'Autorité préfectorale', 'lni-library'], 7: ['operateur', 'Opérateur', 'lni-delivery'] };
const TITRE_ROLE = { 1: 'Administration', 3: 'Autorité communale', 4: 'Autorité préfectorale', 7: 'Espace Opérateur' };
// Comptes de démonstration proposés à la connexion (un par rôle).
const COMPTES_DEMO = [[1, 1, 'admin@sendra.sn'], [3, 7, 'l.thiam@mairie-hann.sn'], [4, 9, 'prefecture.dakar@demo.sn'], [7, 12, 'operations@sendra.sn']];
// Pages autorisées par rôle (mêmes listes que le menu du back-office).
const DROITS = { '/': [1, 2, 3, 4, 7], '/cartographie': [1, 2, 3, 4], '/signales': [1, 2, 3, 4, 7], '/encours': [1, 2, 3, 4, 7], '/non-resolus': [1, 2, 3, 4, 7], '/enleves': [1, 2, 3, 4, 7], '/rejetes': [1, 2, 3, 4, 7],
  '/details': [1, 2, 3, 4, 7], '/approbations': [1, 3, 4], '/missions': [1, 7], '/fourrieres': [1], '/pointage': [1], '/communes': [1], '/messages': [1], '/comptes': [1], '/profil': [1, 2, 3, 4, 7] };
const ROLES = { 1: 'Admin', 2: 'Agent', 3: 'Autorité - Commune', 4: 'Autorité - Préfecture', 5: 'Citoyen', 7: 'Opérateur' };
function seedSigs() {
  const s = (id, kind, marque, model, plaque, commune, adresse, etat, created, o = {}) => Object.assign({
    id, title: kind, vehicle_kind: kind, commune, adresse_precise: adresse, etat, created_at: created, updated_at: created,
    user_id: 11, agent_id: null, soumis: false, is_approve: false, motife_approbation: null, non_removal_reason: null, non_removed_at: null,
    description: '', latitude: 14.6837 + (o.dLat || 0), longitude: -17.4483 + (o.dLng || 0), pv: false,
    _marque: marque, _model: model, _plaque: plaque, photosAgent: 0,
  }, o);
  const L = [
    s(1088, 'Voiture', 'Hyundai', 'H100', 'DK-5502-AH', 'Ouakam', 'Cité Avion, rue OKM-12', 'SIGNALE', J(0, 7, 48), { dLat: .012, dLng: -.03, description: 'Fourgon abandonné, pneus à plat.', user_id: 13 }),
    s(1087, 'Voiture', 'Mitsubishi', 'L200', 'DK-2658-AH', 'Cambérène', 'Cambérène 2', 'SIGNALE', J(0, 6, 55), { dLat: .07, dLng: .02, user_id: 14 }),
    s(1086, 'Moto', 'TVS', 'Apache', '', 'Dieuppeul-Derklé', 'Derklé, rue DD-15', 'SIGNALE', J(1, 20, 10), { dLat: .03, dLng: .004 }),
    s(1085, 'Voiture', 'Renault', 'Clio', 'DK-3307-AF', 'Mermoz-Sacré-Cœur', 'Rue MZ-74, face pharmacie', 'SIGNALE', J(1, 18, 5), { user_id: 10, dLat: .02, dLng: -.02, description: 'Garée depuis plus de trois mois, pneus à plat.' }),
    s(1084, 'Camion', 'Isuzu', 'NPR', 'DK-9050-BA', 'Biscuiterie', 'Route de Rufisque', 'SIGNALE', J(1, 9, 44), { dLat: .025, dLng: .03, user_id: 13 }),
    s(1083, 'Voiture', 'Mercedes-Benz', '190', 'DK-0921-AC', 'Plateau', 'Avenue Pompidou', 'SIGNALE', J(2, 15, 31), { agent_id: 3, pris: J(1, 9, 0), dLat: -.017, dLng: .01, user_id: 14 }),
    s(1082, 'Voiture', 'Renault', '19', 'DK-0412-AA', 'Ngor', 'Ngor village, route de la plage', 'EN COURS', J(4, 17, 17), { agent_id: 3, soumis: true, pv: true, photosAgent: 1, dLat: .065, dLng: -.06 }),
    s(1081, 'Voiture', 'Peugeot', '406', 'DK-4821-BF', 'Médina', 'Rue 11 × Blaise Diagne', 'EN COURS', J(5, 9, 12), { user_id: 10, agent_id: 2, soumis: true, pv: true, photosAgent: 2 }),
    s(1080, 'Voiture', 'Kia', 'Picanto', 'DK-7751-AE', 'HLM', 'HLM 5, marché', 'EN COURS', J(6, 11, 2), { agent_id: 4, soumis: true, pv: true, photosAgent: 1, dLat: .012, dLng: .02, photoBase: 's1087', user_id: 13 }),
    s(1079, 'Voiture', 'Nissan', 'Sunny', 'DK-6618-AD', 'Yoff', 'Yoff Tonghor, rue YF-33', 'SIGNALE', J(3, 10, 15), { agent_id: 2, pris: J(2, 10, 0), dLat: .06, dLng: .01 }),
    s(1077, 'Voiture', 'Honda', 'Civic', 'DK-3981-AE', 'Hann Bel-Air', 'Zone de Hann, quai de pêche', 'EN COURS', J(15, 13, 40), { agent_id: 2, soumis: true, is_approve: true, pv: true, photosAgent: 1, dLat: .01, dLng: .05 }),
    s(1074, 'Voiture', 'Toyota', 'Corolla', 'DK-1196-AM', 'Sicap-Liberté', 'Liberté 6, près du rond-point', 'ENLEVE', J(17, 17, 40), { user_id: 10, agent_id: 3, soumis: true, is_approve: true, pv: true, dLat: .015, dLng: .002 }),
    s(1072, 'Voiture', 'Peugeot', '504 Break', 'DK-8403-AA', 'Hann Bel-Air', 'Hann Maristes, rue HB-8', 'EN COURS', J(18, 11, 11), { agent_id: 3, soumis: true, is_approve: true, pv: true, photosAgent: 1, dLat: .014, dLng: .055 }),
    s(1070, 'Voiture', 'Toyota', 'HiAce', 'DK-4471-AG', 'Parcelles Assainies', 'Unité 17', 'ENLEVE', J(19, 9, 0), { agent_id: 5, soumis: true, is_approve: true, pv: true, dLat: .055, dLng: .03, user_id: 14 }),
    s(1069, 'Camion', 'Mercedes-Benz', '1517', 'DK-7710-BB', 'Hann Bel-Air', 'Route du Front de Terre', 'EN COURS', J(20, 8, 20), { user_id: 10, agent_id: 2, soumis: true, is_approve: true, pv: true, photosAgent: 1, dLat: .008, dLng: .06 }),
    s(1066, 'Moto', 'Jakarta', 'JK 125', '', 'Grand Yoff', 'Arafat, rue GY-210', 'REJETE', J(24, 12, 2), { user_id: 10, agent_id: 3, soumis: true, motife_approbation: 'Véhicule en réparation, propriétaire identifié', dLat: .035, dLng: .02 }),
    s(1063, 'Voiture', 'Ford', 'Focus', 'DK-1735-AF', "Patte d'Oie", 'Patte d’Oie Builders', 'ENLEVE', J(27, 14, 0), { agent_id: 5, soumis: true, is_approve: true, pv: true, dLat: .045, dLng: .025, user_id: 13 }),
    s(1061, 'Voiture', 'Kia', 'Rio', 'DK-2240-AB', 'Fann-Point E-Amitié', 'Point E, rue de Kaolack', 'EN COURS', J(29, 16, 0), { agent_id: 5, soumis: true, is_approve: true, pv: true, non_removal_reason: 'Véhicule introuvable lors de la mission', non_removed_at: J(26, 11, 0), dLat: .006, dLng: -.012 }),
    s(1059, 'Voiture', 'Peugeot', '307', 'DK-5530-AC', 'Biscuiterie', 'Rue BS-41', 'EN COURS', J(25, 10, 20), { agent_id: 4, soumis: true, is_approve: true, pv: true, dLat: .028, dLng: .035 }),
    s(1058, 'Voiture', 'Toyota', 'Yaris', 'DK-7123-AD', 'Biscuiterie', 'Cité Biscuiterie', 'EN COURS', J(26, 8, 5), { agent_id: 4, soumis: true, is_approve: true, pv: true, photosAgent: 1, dLat: .027, dLng: .033, user_id: 14 }),
  ];
  // Les données de constatation n'existent qu'une fois la constatation saisie.
  L.forEach(x => {
    const moto = x.vehicle_kind === 'Moto';
    if (x.soumis) Object.assign(x, {
      marque: x._marque, model: x._model, numero_vehicule: x._plaque || null,
      type_car: moto ? 'CYCL — deux-roues' : x.vehicle_kind === 'Camion' ? 'VTM — transport de marchandises' : 'VPP — voiture particulière',
      categorie: moto ? 'CYCL' : x.vehicle_kind === 'Camion' ? 'Camion' : 'Berline', couleur: ['Gris', 'Blanc', 'Rouge', 'Bleu'][x.id % 4],
      entretien: 'DEGRADE', pays_etranger: 'NON', pneumatiques_manquantes: x.id % 2, defauts_techniques_irreversibles: 1,
      motif_infraction: 'Véhicule abandonné sur la voie publique', explication_infraction: 'Véhicule immobilisé depuis plusieurs mois, signalé par les riverains.',
      lieu: 'PUBLIC', pieces_manquantes: x.id % 2 ? 'Roue avant gauche, rétroviseurs' : '', dommage: true,
    });
  });
  return L;
}
function seedMissions() {
  return [
    { id: 14, code: 'MIS-2026-014', title: 'Enlèvement programmé — Hann Bel-Air', type: 'programmee', status: 'en_cours', scheduled_at: '2026-10-29T09:00', commune: 'Hann Bel-Air',
      provider_name: 'Transports Diallo & Fils', agents: [2, 5], checked: { 2: '2026-10-29T08:52', 5: '2026-10-29T08:57' }, reception_agent: 4, reception_pound: 'Fourrière de Hann', pounds: ['Fourrière de Hann'],
      trucks: [{ trailer_brand: 'Renault Kerax', registration: 'DK-2210-AT', driver_name: 'Mamadou Faye', seats: 3, destination_pound_name: 'Fourrière de Hann' }, { trailer_brand: 'Mercedes Actros', registration: 'DK-8841-BC', driver_name: 'Ousmane Ba', seats: 2, destination_pound_name: null }],
      vehicles: [1069, 1072, 1077], nonRemoved: { 1072: 'Véhicule introuvable sur place' }, removals: [{ sig: 1069, truck: 0, reception: null }], validated: null, completed: null, created_by: 1 },
    { id: 11, code: 'MIS-2026-011', title: 'Enlèvement ponctuel — Biscuiterie', type: 'brute', status: 'en_reception', scheduled_at: '2026-10-28T08:30', commune: 'Biscuiterie',
      provider_name: 'Transports Diallo & Fils', agents: [4], checked: { 4: '2026-10-28T08:21' }, reception_agent: 2, reception_pound: 'Fourrière de Hann', pounds: ['Fourrière de Hann'],
      trucks: [{ trailer_brand: 'Renault Kerax', registration: 'DK-2210-AT', driver_name: 'Mamadou Faye', seats: 3, destination_pound_name: 'Fourrière de Hann' }],
      vehicles: [1058, 1059], nonRemoved: {}, removals: [{ sig: 1058, truck: 0, reception: '2026-10-28T14:40' }, { sig: 1059, truck: 0, reception: null }, { sig: null, label: 'Toyota Corolla grise (imprévu)', plate: 'DK-6402-AB', base: 's1050', truck: 0, reception: null }],
      validated: '2026-10-28T12:10', completed: null, created_by: 1 },
    { id: 9, code: 'MIS-2026-009', title: 'Enlèvement ponctuel — Parcelles Assainies', type: 'brute', status: 'terminee', scheduled_at: '2026-10-17T08:30', commune: 'Parcelles Assainies',
      provider_name: 'SENDRA Logistique', agents: [2, 5], checked: { 2: '2026-10-17T08:44', 5: '2026-10-17T08:49' }, reception_agent: 3, reception_pound: 'Fourrière de Mbao', pounds: ['Fourrière de Mbao'],
      trucks: [{ trailer_brand: 'Mercedes Actros', registration: 'DK-8841-BC', driver_name: 'Ousmane Ba', seats: 2, destination_pound_name: 'Fourrière de Mbao' }],
      vehicles: [1070], nonRemoved: {}, removals: [{ sig: 1070, truck: 0, reception: '2026-10-17T15:10' }], validated: '2026-10-17T11:00', completed: '2026-10-17T15:20', created_by: 6 },
    { id: 7, code: 'MIS-2026-007', title: 'Enlèvement programmé — Patte d’Oie', type: 'programmee', status: 'terminee', scheduled_at: '2026-10-05T07:30', commune: "Patte d'Oie",
      provider_name: 'Transports Diallo & Fils', agents: [5], checked: { 5: '2026-10-05T07:41' }, reception_agent: 3, reception_pound: 'Fourrière de Hann', pounds: ['Fourrière de Hann'],
      trucks: [{ trailer_brand: 'Renault Kerax', registration: 'DK-2210-AT', driver_name: 'Mamadou Faye', seats: 3, destination_pound_name: 'Fourrière de Hann' }],
      vehicles: [1063, 1074], nonRemoved: {}, removals: [{ sig: 1063, truck: 0, reception: '2026-10-09T10:40' }, { sig: 1074, truck: 0, reception: '2026-10-19T14:10' }], validated: '2026-10-05T11:30', completed: '2026-10-19T14:30', created_by: 1 },
  ];
}
const COMMUNES = [['Biscuiterie', 'Dakar', 150, 2], ['Cambérène', 'Dakar', 100, 0], ["Dieuppeul-Derklé", 'Dakar', 150, 0], ['Fann-Point E-Amitié', 'Dakar', 100, 0], ['Grand Yoff', 'Dakar', 200, 0],
  ['Gueule Tapée-Fass-Colobane', 'Dakar', 100, 0], ['Hann Bel-Air', 'Dakar', 150, 1], ['HLM', 'Dakar', 100, 0], ['Médina', 'Dakar', 100, 0], ['Mermoz-Sacré-Cœur', 'Dakar', 150, 0], ['Ngor', 'Dakar', 150, 0],
  ['Ouakam', 'Dakar', 200, 0], ['Parcelles Assainies', 'Dakar', 150, 1], ["Patte d'Oie", 'Dakar', 100, 1], ['Plateau', 'Dakar', 100, 0], ['Sicap-Liberté', 'Dakar', 100, 0], ['Yoff', 'Dakar', 150, 0],
  ['Rufisque Est', 'Rufisque', 200, 0], ['Pikine Nord', 'Pikine', 150, 0]];
const POUNDS = [['Fourrière de Hann', 'Dakar'], ['Fourrière de Mbao', 'Pikine'], ['Fourrière de Rufisque', 'Rufisque']];
const MESSAGES = [
  { id: 3, nom: 'Babacar Sène', email: 'babacar.sene@exemple.sn', telephone: '776020202', objet: 'Partenariat pour l’enlèvement à Rufisque', message: 'Bonjour, notre entreprise de dépannage souhaite proposer ses camions pour les missions dans le département de Rufisque. Pouvons-nous convenir d’un rendez-vous ?', statut: 'nouveau', created_at: J(0, 8, 12), lu: false },
  { id: 2, nom: 'Coumba Thiam', email: 'coumba.t@exemple.sn', telephone: '', objet: 'Mon signalement n’apparaît pas', message: 'J’ai signalé une voiture abandonnée rue 10 à la Médina mais je ne la vois pas dans l’application.', statut: 'en_cours', created_at: J(2, 19, 40), lu: true },
  { id: 1, nom: 'Mairie de Yoff', email: 'services.techniques@exemple.sn', telephone: '338201010', objet: 'Demande de statistiques mensuelles', message: 'Merci de nous transmettre le bilan des enlèvements réalisés sur la commune au mois de septembre.', statut: 'traite', created_at: J(5, 10, 5), lu: true },
];
const STATUTS_MSG = { nouveau: 'Nouveau', en_cours: 'En cours', traite: 'Traité' };

/* ───────── État (conservé dans le navigateur du visiteur) ───────── */
const CLE = 'epavie-bo-demo-v1';
let S;
function neuf() { return { logged: false, me: 1, sigs: seedSigs(), missions: seedMissions(), users: USERS.map(u => Object.assign({ archived: false }, u)), messages: MESSAGES.map(m => Object.assign({}, m)), flash: null }; }
function charger() { try { const v = JSON.parse(localStorage.getItem(CLE)); if (v && v.sigs) return v; } catch (e) { } return neuf(); }
function sauver() { try { localStorage.setItem(CLE, JSON.stringify(S)); } catch (e) { } }
S = charger();
const sig = id => S.sigs.find(x => x.id === +id);
const user = id => S.users.find(u => u.id === +id);
const nom = u => u ? `${u.first_name} ${u.last_name}`.trim() : '';
const me = () => user(S.me);
function flash(msg, type = 'success') { S.flash = { msg, type }; sauver(); }
function prendreFlash() { const f = S.flash; S.flash = null; sauver(); return f; }

/* ───────── Gabarit (layouts/master.blade.php) ───────── */
const SECTIONS = [
  ['Pilotage', [['Tableau de bord', '#/', 'lni-dashboard', ['/']], ['Cartographie', '#/cartographie', 'lni-map', ['/cartographie']]]],
  ['Signalements', [['Signalés', '#/signales', 'lni-alarm', ['/signales']], ['En cours', '#/encours', 'lni-reload', ['/encours']], ['Non résolus', '#/non-resolus', 'lni-warning', ['/non-resolus']],
    ['Résolus', '#/enleves', 'lni-checkmark-circle', ['/enleves']], ['Rejetés', '#/rejetes', 'lni-ban', ['/rejetes']], ['Approbations', '#/approbations', 'lni-shield', ['/approbations']]]],
  ['Opérations', [['Missions', '#/missions', 'lni-clipboard', ['/missions']], ['Fourrières', '#/fourrieres', 'lni-home', ['/fourrieres']], ['Pointage', '#/pointage', 'lni-timer', ['/pointage']], ['Communes', '#/communes', 'lni-map-marker', ['/communes']]]],
];
const COMPTES = [['Ajouter un compte', '#/comptes/ajouter', 'plus', '#64748b'], ['Admin', '#/comptes/admin', 'role', '#048b44'], ['Agents', '#/comptes/agents', 'role', '#1a73e8'],
  ['Autorité commune', '#/comptes/autorites', 'role', '#0f8a7e'], ['Autorité préfecture', '#/comptes/utilisateurs', 'role', '#7b3fc4'], ['Opérateurs', '#/comptes/operateurs', 'role', '#e37400'], ['Citoyens', '#/comptes/citoyens', 'role', '#94a3b8']];
function sidebar(chemin) {
  const actif = prefixes => prefixes.some(p => p === '/' ? chemin === '/' : chemin === p || chemin.startsWith(p + '/'));
  const comptesActif = chemin.startsWith('/comptes');
  const nouveaux = S.messages.filter(m => m.statut === 'nouveau').length;
  return `<aside class="sidebar-nav-wrapper">
    <div class="navbar-logo"><a href="#/"><img src="img/sendra-original.png" alt="logo" width="90%" height="80%" /></a></div>
    <nav class="sidebar-nav ">
      <div class="role-card"><span class="role-icon"><i class="lni ${ROLE_UI[me().role][2]}"></i></span><div><small>Espace de travail</small><strong>${ROLE_UI[me().role][1]}</strong></div></div>
      ${SECTIONS.map(([titre, tout]) => [titre, tout.filter(e => (DROITS[e[3][0]] || []).includes(me().role))]).filter(([, e]) => e.length).map(([titre, entrees]) => `<p class="nav-section">${titre}</p><ul class="nav-group">${entrees.map(([l, u, i, pre]) => `<li class="nav-item ${actif(pre) ? 'active' : ''}"><a href="${u}"><span class="icon"><i class="lni ${i}"></i></span><span class="text">${l}</span></a></li>`).join('')}</ul>`).join('')}
      ${me().role !== 1 ? '' : `<p class="nav-section">Administration</p>
      <ul class="nav-group">
        <li class="nav-item ${chemin.startsWith('/messages') ? 'active' : ''}"><a href="#/messages"><span class="icon"><i class="lni lni-envelope"></i></span><span class="text">Messages du site</span>${nouveaux ? `<span class="badge rounded-pill bg-danger ms-auto me-3" title="Messages non traités">${nouveaux}</span>` : ''}</a></li>
        <li class="nav-item nav-item-has-children ${comptesActif ? 'active' : ''}">
          <a href="#0" class="${comptesActif ? '' : 'collapsed'}" data-bs-toggle="collapse" data-bs-target="#ddmenu_comptes" aria-controls="ddmenu_comptes" aria-expanded="${comptesActif}"><span class="icon"><i class="lni lni-users"></i></span><span class="text">Comptes</span></a>
          <ul id="ddmenu_comptes" class="collapse dropdown-nav ${comptesActif ? 'show' : ''}">
            ${COMPTES.map(([l, u, f, c]) => `<li><a href="${u}" class="${chemin === u.slice(1) ? 'active' : ''}">${f === 'plus' ? `<i class="lni lni-circle-plus role-dot-icon" style="color: ${c}"></i>` : `<span class="role-dot" style="background: ${c}"></span>`} ${l}</a></li>`).join('')}
          </ul>
        </li>
      </ul>`}
    </nav>
  </aside><div class="overlay"></div>`;
}
function header() {
  const u = me();
  return `<header class="header"><div class="container-fluid"><div class="row">
    <div class="col-lg-5 col-md-5 col-6"><div class="header-left d-flex align-items-center">
      <div class="menu-toggle-btn mr-15"><button id="menu-toggle" class="main-btn success-btn btn-hover"><i class="lni lni-chevron-left me-2"></i> Menu</button></div>
      <div class="header-search d-none d-md-flex"><form id="recherche"><input type="text" placeholder="Rechercher…" /><button><i class="lni lni-search-alt"></i></button></form></div>
    </div></div>
    <div class="col-lg-7 col-md-7 col-6"><div class="header-right"><div class="profile-box ml-15">
      <button class="dropdown-toggle bg-transparent border-0" type="button" id="profile" data-bs-toggle="dropdown" aria-expanded="false"><div class="profile-info"><div class="info"><div class="image"><img src="assets/images/avatar.png" alt="" /></div><div><h6 class="fw-500">${esc(u.first_name)} ${esc(u.last_name)}</h6><p>${ROLES[u.role]}</p></div></div></div></button>
      <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="profile">
        <li><div class="author-info flex items-center !p-1"><div class="content"><h4 class="text-sm">${esc(u.first_name)} ${esc(u.last_name)}</h4><a class="text-black/40 text-xs" href="#/profil">${esc(u.email)}</a></div></div></li>
        <li class="divider"></li><li><a href="#/profil"><i class="lni lni-user"></i> Voir Profil</a></li><li class="divider"></li>
        <li><form id="logout"><button type="submit" class="main-btn danger-btn btn-hover w-100 text-center"><i class="lni lni-exit"></i> Se Déconecter </button></form></li>
      </ul></div></div></div>
  </div></div></header>`;
}
const FOOTER = `<footer class="footer"><div class="container-fluid"><div class="row"><div class="col-md-6 order-last order-md-first"><div class="copyright text-center text-md-start"><p class="text-sm">2024 © Designed by <a href="https://sendra.sn" rel="nofollow" target="_blank">SENDRA</a></p></div></div><div class="col-md-6"><div class="terms d-flex justify-content-center justify-content-md-end"><a href="#0" class="text-sm">SENDRA</a></div></div></div></div></footer>`;
const alertes = f => !f ? '' : f.type === 'success' ? `<div class="row alert-box success-alert"><div class="col-12 alert"><p class="text-medium">${esc(f.msg)}</p></div></div>` : `<div class="row alert-box danger-alert"><div class="col-12 alert"><p class="text-medium">${esc(f.msg)}</p></div></div>`;
const alerteBs = f => !f ? '' : `<div class="alert alert-${f.type === 'success' ? 'success' : 'danger'}">${esc(f.msg)}</div>`;

/* ───────── Affichage commun ───────── */
const photoCit = s => ph(`${s.photoBase || 's' + s.id}_left.jpg`);
function photosAgent(s) { const l = []; for (let i = 0; i < (s.photosAgent || 0); i++) l.push(ph(`${s.photoBase || 's' + s.id}_${s.vehicle_kind === 'Moto' ? (i ? 'right' : 'detail') : (i ? 'front' : 'detail')}.jpg`)); return l.concat(s.agentExtra || []); }
const etatAffiche = s => s.etat === 'REJETE' ? 'REJETE' : (s.etat !== 'ENLEVE' && s.non_removed_at) ? 'NON RESOLU' : s.etat;
const LIBELLES = { SIGNALE: 'Signalé', 'EN COURS': 'En cours', ENLEVE: 'Résolu', 'NON RESOLU': 'Non résolu', REJETE: 'Rejeté' };
function etapes(s) {
  const e = etatAffiche(s), rej = e === 'REJETE', nres = e === 'NON RESOLU', enl = e === 'ENLEVE';
  const appr = s.is_approve || enl || nres, cons = !!s.soumis || appr || rej;
  const d = iso => iso ? fCourt(new Date(iso)) : null;
  const ap = rej ? { libelle: 'Rejeté par l’autorité', statut: 'echec', detail: 'Motif : ' + (s.motife_approbation || 'non précisé'), date: d(s.updated_at) }
    : appr ? { libelle: 'Approuvé par l’autorité', statut: 'fait', detail: s.motife_approbation || null, date: d(s.approuve_at) }
      : cons ? { libelle: 'En attente d’approbation de l’autorité', statut: 'actuel', detail: 'Constatation transmise, décision attendue' }
        : { libelle: 'Approbation de l’autorité', statut: 'a_venir' };
  const en = enl ? { libelle: 'Véhicule enlevé', statut: 'fait', detail: 'Réceptionné en fourrière' } : nres ? { libelle: 'Véhicule non enlevé', statut: 'echec', detail: 'Motif : ' + (s.non_removal_reason || 'non précisé'), date: d(s.non_removed_at) }
    : appr ? { libelle: 'En attente d’enlèvement', statut: 'actuel', detail: 'Prêt pour une mission' } : { libelle: 'Enlèvement', statut: rej ? 'saute' : 'a_venir' };
  return [
    { libelle: 'Signalé', statut: 'fait', detail: 'Signalement reçu', date: d(s.created_at) },
    { libelle: 'Constaté par l’agent', statut: cons ? 'fait' : (s.agent_id ? 'actuel' : 'a_venir'), detail: cons ? 'Constatation transmise pour approbation' : (s.agent_id ? 'Pris en charge, constatation en cours' : 'En attente d’un agent'), date: cons ? d(s.created_at) : null },
    ap, en,
    { libelle: nres ? 'Non résolu' : 'Résolu', statut: enl ? 'fait' : nres ? 'echec' : rej ? 'saute' : 'a_venir' },
  ];
}
function avancement(s) {
  const C = { fait: '#188038', actuel: '#E37400', echec: '#D93025' }, att = e => ['fait', 'actuel', 'echec'].includes(e.statut);
  const E = etapes(s);
  return `<style>.avc{list-style:none;margin:0;padding:0}.avc-etape{position:relative;display:flex;gap:14px;padding-bottom:22px}.avc-etape:last-child{padding-bottom:0}.avc-rail{position:absolute;left:15px;top:34px;bottom:2px;width:4px;border-radius:2px;background:#e1e8e4;overflow:hidden}.avc-rail span{display:block;width:100%;height:0;border-radius:2px;animation:avc-glisse .8s ease-out forwards}.avc-etape:last-child .avc-rail{display:none}.avc-pastille{flex:0 0 34px;width:34px;height:34px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:800;border:2px solid #e1e8e4;background:#fff;z-index:1}.avc-actuel .avc-pastille{box-shadow:0 0 0 5px rgba(227,116,0,.18)}.avc-titre{font-weight:800;color:#15201a}.avc-echec .avc-titre,.avc-echec .avc-detail{color:#D93025}.avc-a_venir .avc-titre,.avc-saute .avc-titre{color:#5f6b65;font-weight:600}.avc-saute .avc-titre{text-decoration:line-through}.avc-detail{color:#5f6b65;font-size:14px}.avc-date{color:#5f6b65;font-size:13px}.avc-badge{font-size:11px;font-weight:700;border-radius:8px;padding:2px 7px;margin-left:6px;background:#E374001f;color:#E37400}@keyframes avc-glisse{to{height:100%}}</style>
  <ol class="avc">${E.map((e, i) => { const c = C[e.statut] || '#e1e8e4', n = E[i + 1]; return `<li class="avc-etape avc-${e.statut}"><div class="avc-rail">${n && att(n) ? `<span style="background:${C[n.statut]}"></span>` : ''}</div>
    <div class="avc-pastille" style="${att(e) ? `background:${c};border-color:${c}` : ''}">${{ saute: '–', actuel: '●', echec: '✕', fait: '✓' }[e.statut] || ''}</div>
    <div><div class="avc-titre">${esc(e.libelle)}${e.statut === 'actuel' ? '<span class="avc-badge">Étape actuelle</span>' : ''}</div>${e.detail ? `<div class="avc-detail">${esc(e.detail)}</div>` : ''}${att(e) && e.date ? `<div class="avc-date">${esc(e.date)}</div>` : ''}</div></li>`; }).join('')}</ol>`;
}
const vehiculeConstate = s => [`${s.marque || ''} ${s.model || ''}`.trim(), s.numero_vehicule].filter(Boolean).join(' · ');
function tableSignalements(liste, badge, sousLigne) {
  const th = t => `<th class="min-width"><h6 class="text-sm text-medium">${t}</h6></th>`;
  return `<div class="table-responsive"><table class="table top-selling-table"><thead><tr>${th('Image')}${th('Titre')}${th('Secteur')}${th('Date Signalement')}<th><h6 class="text-sm text-medium text-start">Etat</h6></th><th><h6 class="text-sm text-medium text-end">Constatation</h6></th></tr></thead><tbody>
  ${liste.map(s => `<tr><td><div class="employee-image"><img src="${photoCit(s)}" alt="" /></div></td>
    <td><p class="text-sm fw-semibold mb-0">${esc(s.vehicle_kind || s.title)}</p>${s.marque || s.numero_vehicule ? `<small class="text-muted d-block">${esc(vehiculeConstate(s))}</small>` : ''}</td>
    <td><p class="text-sm">${esc(s.commune)}</p></td><td><p class="text-sm">${fLong(new Date(s.created_at))}</p></td>
    <td>${badge(s)}${sousLigne ? sousLigne(s) : ''}</td><td><div class="action justify-content-center"><a href="#/details/${s.id}" class="edit text-success "><i class="lni lni-eye"></i></a></div></td></tr>`).join('')}
  </tbody></table><div class="d-flex justify-content-end mt-4"></div></div>`;
}
const titreSection = (t, extra = '') => `<div class="title-wrapper pt-30"><div class="row align-items-center"><div class="col-md-6"><div class="title"><h2 class="text-success">${t}</h2>${extra}</div></div></div></div>`;
const triDesc = l => l.slice().sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

/* ───────── Pages ───────── */
const P = {};
P['/'] = () => {
  const L = S.sigs, attente = L.filter(s => s.soumis && !s.is_approve && s.etat !== 'REJETE').length, u = me();
  const carte = (t, v, cls, ic = 'lni-car') => `<div class="col-xl-3 col-lg-4 col-sm-6"><div class="icon-card mb-30"><div class="icon ${cls}"><i class="lni ${ic}"></i></div><div class="content"><h6 class="mb-10">${t}</h6><h3 class="text-bold mb-10">${v}</h3></div></div></div>`;
  return `<section class="section "><div class="container-fluid ">
    <div class="title-wrapper pt-30"><div class="row align-items-center"><div class="col-md-6"><div class="title tesu"><h2 class="text-success">${TITRE_ROLE[u.role] || 'Espace Agent'} </h2><p class="text-muted mb-0">${ROLES[u.role]} · Bonjour ${esc(u.first_name)}</p></div></div></div></div>
    ${[1, 3, 4].includes(u.role) ? `<div class="card-style mb-30 role-banner"><div class="d-flex flex-wrap justify-content-between align-items-center gap-3"><div><h5>Décisions à prendre</h5><p class="mb-0">${attente} signalement(s) transmis pour approbation.</p></div><a href="#/approbations" class="main-btn success-btn btn-hover">Ouvrir la file d’approbation</a></div></div>` : ''}
    <div class="row">${carte('Signalements', L.length, '')}${carte('Pas résolus', L.filter(s => s.etat === 'SIGNALE').length, 'red')}${carte('En cours', L.filter(s => s.etat === 'EN COURS').length, 'orange')}${carte('Enlévements', L.filter(s => s.etat === 'ENLEVE').length, 'success ')}
      <div class="col-xl-3 col-lg-4 col-sm-6"><a href="#/non-resolus" class="text-decoration-none text-dark"><div class="icon-card mb-30"><div class="icon orange"><i class="lni lni-warning"></i></div><div class="content"><h6 class="mb-10">Non résolus</h6><h3 class="text-bold mb-10">${L.filter(s => etatAffiche(s) === 'NON RESOLU').length}</h3></div></div></a></div></div>
    <div class="row"><div class="col-lg-12"><div class="card-style mb-30"><div class="title d-flex flex-wrap align-items-center justify-content-between"><div class="left"><h6 class="text-medium mb-30">Liste des signalements</h6></div></div>
      ${tableSignalements(triDesc(L).slice(0, 10), s => s.etat !== 'ENLEVE' && s.etat !== 'REJETE' && s.non_removed_at ? '<span class="status-btn warning-btn">NON RÉSOLU</span>' : s.etat === 'SIGNALE' ? `<span class="status-btn close-btn">${s.etat}</span>` : s.etat === 'EN COURS' ? `<span class="status-btn warning-btn">${s.etat}</span>` : s.etat === 'ENLEVE' ? `<span class="status-btn success-btn">${s.etat}</span>` : `<span class="status-btn">${s.etat}</span>`)}
    </div></div></div></div></section>`;
};
const listePage = (titre, filtre, badge, sous) => () => `<section class="section "><div class="container-fluid ">${titreSection('Signalements')}
  <div class="row"><div class="col-lg-12"><div class="card-style mb-30"><div class="title d-flex flex-wrap align-items-center justify-content-between"><div class="left"><h6 class="text-medium mb-30">${titre}</h6></div></div>
  ${tableSignalements(triDesc(S.sigs.filter(filtre)), () => badge, sous)}</div></div></div></div></section>`;
P['/signales'] = listePage('Liste des signalements qui ne pas résolus', s => s.etat === 'SIGNALE' && !s.non_removed_at, '<span class="status-btn close-btn">Signalé</span>');
P['/encours'] = listePage('Liste des signalements en cours d\'enlévement', s => s.etat === 'EN COURS' && !s.non_removed_at, '<span class="status-btn warning-btn">En cours</span>');
P['/enleves'] = listePage('Signalements résolus (véhicule enlevé)', s => s.etat === 'ENLEVE', '<span class="status-btn success-btn">Résolu</span>');
P['/non-resolus'] = listePage('Véhicules non enlevés', s => etatAffiche(s) === 'NON RESOLU', '<span class="status-btn warning-btn">Non résolu</span>', s => `<small class="d-block mt-1">${esc(s.non_removal_reason)}</small>`);
P['/rejetes'] = listePage('Signalements rejetés par l’autorité', s => s.etat === 'REJETE', '<span class="status-btn close-btn">Rejeté</span>', s => `<small class="d-block mt-1">${esc(s.motife_approbation)}</small>`);

P['/details'] = (id, q) => {
  const s = sig(id); if (!s) return P['/']();
  const kind = s.vehicle_kind || 'Voiture', citoyen = user(s.user_id), agent = user(s.agent_id), f = prendreFlash();
  const transmis = !!s.dommage, decide = s.is_approve || s.etat === 'REJETE';
  const vc = vehiculeConstate(s);
  const details = [s.defaut_controle_technique && 'Contrôle technique', s.pneumatiques_manquantes && 'Pneumatiques manquants', s.vehicule_immerge && 'Véhicule immergé', s.defauts_techniques_irreversibles && 'Défauts techniques irréversibles', s.vehicule_non_identifiable && 'Véhicule non identifiable', s.vehicule_brule && 'Véhicule brûlé'].filter(Boolean).join(' · ');
  return `<style>.report-hero{background:linear-gradient(135deg,#073b2a,#0b8f55);color:#fff;border-radius:22px;padding:24px;box-shadow:0 16px 38px rgba(7,59,42,.18)}.report-hero .meta{color:rgba(255,255,255,.8)}.report-stat{height:100%;border:1px solid #e7eee9;border-radius:18px;padding:18px;background:#fff}.report-detail{border:1px solid #e1eae5;border-radius:18px;background:#fff;padding:20px;height:100%}.report-detail dt{color:#66736c;font-size:13px;margin-top:12px}.report-detail dd{font-weight:600;margin-bottom:0;overflow-wrap:anywhere}.report-agent-photo{width:100%;height:190px;object-fit:cover;border-radius:12px}.decision-choix{display:grid;grid-template-columns:repeat(2,minmax(140px,1fr));gap:12px;max-width:520px}.decision-choix input{position:absolute;opacity:0;pointer-events:none}.decision-choix span{display:flex;align-items:center;justify-content:center;gap:8px;min-height:64px;border:2px solid #dce5df;border-radius:16px;font-weight:700;font-size:16px;cursor:pointer;transition:.15s}.decision-choix span.ok{border-color:#188038;color:#0b6b30;background:#f3faf5}.decision-choix span.refus{border-color:#d93025;color:#b3261e;background:#fef6f5}.decision-choix label:hover span.ok{background:#e8f5ed}.decision-choix label:hover span.refus{background:#fdecea}.decision-choix input:checked+span.ok{background:#188038;border-color:#188038;color:#fff;box-shadow:0 6px 16px rgba(24,128,56,.28)}.decision-choix input:checked+span.refus{background:#d93025;border-color:#d93025;color:#fff;box-shadow:0 6px 16px rgba(217,48,37,.28)}.decision-choix input:focus-visible+span{outline:2px solid #0b8f55;outline-offset:2px}.decision-resultat{border-radius:14px;padding:14px 16px}.decision-resultat.ok{background:#e8f5ed;color:#0b6b30}.decision-resultat.refus{background:#fdecea;color:#b3261e}</style>
  <section class="tab-components"><div class="container-fluid"><div class="title-wrapper pt-30"><div class="row align-items-center"><div class="col-12 d-flex flex-wrap gap-2 mb-4">
    ${q.depuis === 'approbations' ? `<a class="btn btn-outline-secondary" href="#/approbations?filtre=${esc(q.filtre || 'attente')}"><i class="lni lni-arrow-left"></i> Retour aux approbations</a>` : ''}
    <a class="main-btn success-btn btn-hover" href="#/cartographie?id=${s.id}"><i class="lni lni-map-marker"></i> Localisation</a></div></div>${alertes(f)}</div>
    <div class="report-hero mb-4"><div class="row align-items-center g-3"><div class="col-lg-8"><span class="badge bg-light text-dark mb-2">${LIBELLES[etatAffiche(s)]}</span>
      <h2 class="text-white mb-1">Signalement n° ${s.id} ${vc ? `<span class="fs-5 fw-semibold ms-1" style="color:rgba(255,255,255,.88)">· ${esc(vc)}</span>` : ''}</h2><div class="meta">${esc(s.title || 'Véhicule signalé')} · ${fCourt(new Date(s.created_at))}</div></div>
      <div class="col-lg-4 text-lg-end"><div class="fs-5 fw-semibold">${esc(kind)} · ${esc(s.marque || 'Marque non renseignée')}</div><div class="meta">${esc(s.numero_vehicule || 'Plaque non renseignée')}</div></div></div></div>
    ${s.etat !== 'ENLEVE' && s.etat !== 'REJETE' && s.non_removed_at ? `<div class="alert alert-warning"><strong>Véhicule non enlevé</strong> · ${esc(s.non_removal_reason)}<br><small>Constaté le ${fCourt(new Date(s.non_removed_at))}</small></div>` : ''}
    <div class="row g-3 mb-4">
      <div class="col-md-4"><div class="report-stat"><div class="text-muted small">Citoyen</div><div class="fw-bold">${esc(nom(citoyen) || 'Non renseigné')}</div><small>${esc(citoyen?.telephone || 'Téléphone non renseigné')}</small></div></div>
      <div class="col-md-4"><div class="report-stat"><div class="text-muted small">Agent</div><div class="fw-bold">${esc(nom(agent) || 'Non pris en charge')}</div><small>${s.dommage ? 'Constatation transmise' : s.pris ? 'Pris en charge le ' + fCourt(new Date(s.pris)) : 'Constatation en attente'}${s.pv ? ' · PV signé' : ''}</small></div></div>
      <div class="col-md-4"><div class="report-stat"><div class="text-muted small">Décision</div><div class="fw-bold">${s.etat === 'REJETE' ? 'Refusée' : s.is_approve ? 'Approuvée' : 'En attente'}</div><small>${esc(s.motife_approbation || 'Aucun motif renseigné')}</small></div></div></div>
    <div class="row g-3 mb-4"><div class="col-12"><div class="report-detail"><h4 class="mb-3">Avancement du signalement</h4>${avancement(s)}</div></div></div>
    <div class="row g-3 mb-4"><div class="col-lg-6"><div class="report-detail"><h4>Informations du signalement</h4><dl class="mb-0">
      <dt>Description du citoyen</dt><dd>${esc(s.description || '—')}</dd><dt>Ville / commune / quartier</dt><dd>${esc([s.commune, s.adresse_precise].filter(Boolean).join(' · ') || 'Adresse non renseignée')}</dd>
      <dt>Position GPS</dt><dd><a href="https://www.google.com/maps/search/?api=1&query=${s.latitude},${s.longitude}" target="_blank" rel="noopener">Voir sur la carte</a></dd>
      <dt>Véhicule</dt><dd>${esc(kind)} · ${esc(s.type_car || 'Type non renseigné')} · ${esc(s.categorie || 'Catégorie non renseignée')}</dd>
      <dt>Plaque / marque / modèle</dt><dd>${esc(s.numero_vehicule || '—')} · ${esc(s.marque || '—')} · ${esc(s.model || '—')}</dd><dt>Couleur</dt><dd>${esc(s.couleur || '—')}</dd><dt>État général</dt><dd>${esc(s.entretien || '—')}</dd>
      <dt>Autre situation constatée</dt><dd>—</dd><dt>Détails du véhicule</dt><dd>${esc(details || 'Aucun détail renseigné')}</dd><dt>Pays étranger</dt><dd>${esc(s.pays_etranger || '—')}</dd></dl></div></div>
      <div class="col-lg-6"><div class="report-detail"><h4>Constatation de l’agent</h4><dl class="mb-0"><dt>Motif d’infraction</dt><dd>${esc(s.motif_infraction || '—')}</dd><dt>Explication</dt><dd>${esc(s.explication_infraction || '—')}</dd><dt>Lieu</dt><dd>${esc(s.lieu || '—')}</dd>
      <dt>Conditions</dt><dd>Jour / non précisé</dd><dt>Pièces manquantes</dt><dd>${esc(s.pieces_manquantes || '—')}</dd>
      <dt>Dommages</dt><dd>${s.dommage ? `<a href="${ph((s.photoBase || 's' + s.id) + '_detail.jpg')}" target="_blank" rel="noopener"><img class="report-agent-photo" style="max-width:400px;object-fit:contain;background:#f5f8f6" src="${ph((s.photoBase || 's' + s.id) + '_detail.jpg')}" alt="Schéma des dommages annoté"></a>` : 'Non renseignés'}</dd></dl></div></div></div>
    <div class="report-detail mb-4"><h4 class="mb-3">Photo du citoyen</h4><div class="row g-3"><div class="col-6 col-md-3"><a href="${photoCit(s)}" target="_blank" rel="noopener"><img class="report-agent-photo" src="${photoCit(s)}" alt="Photo du citoyen 1"></a></div></div></div>
    <div class="report-detail mb-4"><h4 class="mb-3">Photos de l’agent</h4><div class="row g-3">${photosAgent(s).length ? photosAgent(s).map((u, i) => `<div class="col-6 col-md-3"><a href="${u}" target="_blank" rel="noopener"><img class="report-agent-photo" src="${u}" alt="Photo de constatation ${i + 1}"></a></div>`).join('') : '<p class="text-muted mb-0">Aucune photo de constatation ajoutée.</p>'}</div></div>
    <div class="report-detail mb-4" id="decision"><div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3"><h4 class="mb-0">Approbation</h4>${transmis ? `<a href="pv_exemple.pdf" target="_blank" rel="noopener" class="btn btn-outline-success btn-sm"><i class="lni lni-empty-file"></i> Consulter le PV</a>` : ''}</div>
    ${!transmis ? '<p class="text-muted mb-0">La constatation n’a pas encore été transmise par l’agent : la décision n’est pas encore possible.</p>'
      : decide ? `<div class="decision-resultat ${s.is_approve ? 'ok' : 'refus'}"><strong>${s.is_approve ? 'Signalement approuvé' : 'Signalement rejeté'}</strong><div>${s.motife_approbation ? 'Motif : ' + esc(s.motife_approbation) : 'Aucun motif renseigné'}</div></div>`
        : ![1, 3, 4].includes(me().role) ? '<p class="text-muted mb-0">En attente de la décision de l’autorité.</p>'
        : `<form data-decision="${s.id}"><div class="decision-choix mb-3"><label><input type="radio" name="approbation" value="OUI" required><span class="ok"><i class="lni lni-checkmark-circle"></i> Approuver</span></label><label><input type="radio" name="approbation" value="NON"><span class="refus"><i class="lni lni-close"></i> Rejeter</span></label></div>
          <label class="form-label fw-semibold" for="motif-decision">Motif</label><textarea class="form-control" id="motif-decision" name="motife_approbation" rows="3" maxlength="225" placeholder="Obligatoire en cas de rejet, facultatif pour une approbation"></textarea><div class="invalid-feedback">Le motif est obligatoire en cas de rejet.</div>
          <div class="text-end mt-3"><button type="submit" class="main-btn success-btn btn-hover"><i class="lni lni-checkmark"></i> Enregistrer la décision</button></div></form>`}</div>
  </div></section>`;
};

P['/approbations'] = (_, q) => {
  const filtre = q.filtre || 'attente', r = (q.q || '').trim(), f = prendreFlash();
  const norm = t => String(t || '').toLowerCase().replace(/[^a-z0-9]/g, '');
  const enAttente = S.sigs.filter(s => s.soumis && !s.is_approve && s.etat !== 'REJETE');
  let L = filtre === 'attente' ? enAttente : filtre === 'approuves' ? S.sigs.filter(s => s.is_approve) : S.sigs.filter(s => s.etat === 'REJETE');
  if (r) L = L.filter(s => [s.id, s.numero_vehicule, s.marque, s.model, s.commune].some(v => norm(v).includes(norm(r))));
  L = L.slice().sort((a, b) => new Date(b.updated_at) - new Date(a.updated_at));
  const lien = f2 => `#/approbations?filtre=${f2}${r ? '&q=' + encodeURIComponent(r) : ''}`;
  return `<style>.appro{font-family:"Inter",system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:#15201a}.appro h2{font-size:26px;font-weight:800;letter-spacing:-.3px}.appro .sous-titre{color:#5f6b65;font-size:15px}.appro-filtres a{border-radius:12px;font-weight:600}.appro-recherche{display:flex;flex-wrap:wrap;gap:8px;max-width:560px}.appro-recherche input{flex:1;min-width:220px;border-radius:12px;height:46px;font-size:15px}.appro-recherche button{border-radius:12px;font-weight:600}.appro-carte{border:1px solid #e1e8e4;border-radius:18px;background:#fff;padding:18px;margin-bottom:14px}.appro-carte:hover{border-color:#b7dec4;box-shadow:0 10px 26px rgba(19,61,43,.08)}.appro-num{font-size:13px;font-weight:700;color:#5f6b65;text-transform:uppercase;letter-spacing:.4px}.appro-titre{font-size:19px;font-weight:800;margin:2px 0 6px}.appro-vehicule{display:inline-flex;gap:8px;flex-wrap:wrap;margin-bottom:8px}.appro-vehicule span{background:#f2f6f4;border-radius:10px;padding:4px 10px;font-weight:600;font-size:14px}.appro-vehicule .plaque{background:#15201a;color:#fff;letter-spacing:1px;font-family:"Inter",monospace}.appro-meta{color:#5f6b65;font-size:14px;line-height:1.6}.appro-meta strong{color:#15201a;font-weight:600}.appro-photos img{width:64px;height:64px;object-fit:cover;border-radius:10px}.appro-photos .legende{font-size:12px;font-weight:700;color:#5f6b65;text-transform:uppercase}.appro-decision textarea{border-radius:12px;font-size:14px}.appro-decision .btn{border-radius:12px;font-weight:700;min-height:44px}.appro-badge{display:inline-block;border-radius:10px;padding:4px 10px;font-weight:700;font-size:14px}.appro-badge.ok{background:#e8f5ed;color:#0b6b30}.appro-badge.refus{background:#fdecea;color:#b3261e}</style>
  <section class="section appro"><div class="container-fluid"><div class="title-wrapper pt-30"><h2 class="text-success mb-1">Décisions sur les signalements</h2><p class="sous-titre mb-0">${enAttente.length} dossier(s) à traiter. Ouvrez le PV avant de décider.</p></div>${alerteBs(f)}
  <div class="card-style mb-30"><div class="d-flex flex-wrap justify-content-between gap-3 mb-4">
    <div class="appro-filtres d-flex flex-wrap gap-2"><a class="btn ${filtre === 'attente' ? 'btn-success' : 'btn-outline-success'}" href="${lien('attente')}">À traiter (${enAttente.length})</a><a class="btn ${filtre === 'approuves' ? 'btn-success' : 'btn-outline-success'}" href="${lien('approuves')}">Approuvés</a><a class="btn ${filtre === 'refuses' ? 'btn-success' : 'btn-outline-success'}" href="${lien('refuses')}">Refusés</a></div>
    <form class="appro-recherche" data-recherche-appro="${filtre}"><input type="search" name="q" value="${esc(r)}" class="form-control" placeholder="Plaque (ex. AA-573-LP ou aa573lp), n°, marque, commune" aria-label="Rechercher"><button class="btn btn-success" type="submit"><i class="lni lni-search-alt"></i> Rechercher</button>${r ? `<a class="btn btn-outline-secondary" href="#/approbations?filtre=${filtre}">Effacer</a>` : ''}</form></div>
  ${L.length ? L.map(s => { const fiche = `#/details/${s.id}?depuis=approbations&filtre=${filtre}`, mm = `${s.marque || ''} ${s.model || ''}`.trim(); return `<article class="appro-carte"><div class="row g-3"><div class="col-lg-6">
    <div class="appro-num">Signalement n° ${s.id} · ${fCourt(new Date(s.updated_at))}</div><div class="appro-titre"><a href="${fiche}" class="text-reset">${esc(s.vehicle_kind || s.title)}</a></div>
    <div class="appro-vehicule">${mm ? `<span>${esc(mm)}</span>` : ''}<span class="${s.numero_vehicule ? 'plaque' : ''}">${esc(s.numero_vehicule || 'Plaque non renseignée')}</span></div>
    <div class="appro-meta"><div><strong>Commune :</strong> ${esc(s.commune || '—')}</div><div><strong>Citoyen :</strong> ${esc(nom(user(s.user_id)) || 'Non renseigné')} · <strong>Agent :</strong> ${esc(nom(user(s.agent_id)) || 'Non affecté')}</div></div>
    <div class="appro-photos d-flex flex-wrap gap-3 my-3"><div><div class="legende mb-1">Citoyen</div><a href="${photoCit(s)}" target="_blank" rel="noopener"><img src="${photoCit(s)}" alt="Photo du citoyen"></a></div>
      <div><div class="legende mb-1">Agent</div>${photosAgent(s).length ? photosAgent(s).map(u => `<a href="${u}" target="_blank" rel="noopener"><img src="${u}" alt="Photo de l’agent"></a>`).join(' ') : '<span class="text-muted small">Aucune</span>'}</div></div>
    <a href="${fiche}" class="btn btn-outline-secondary btn-sm"><i class="lni lni-eye"></i> Détails</a> <a href="pv_exemple.pdf" target="_blank" rel="noopener" class="btn btn-outline-success btn-sm"><i class="lni lni-empty-file"></i> Consulter le PV</a></div>
    <div class="col-lg-6 appro-decision">${filtre === 'attente' ? `<form data-appro="${s.id}"><label class="form-label fw-semibold">Motif</label><textarea name="motife_approbation" class="form-control mb-2" rows="3" maxlength="225" placeholder="Obligatoire en cas de refus"></textarea>
      <div class="d-flex flex-wrap gap-2"><button type="submit" name="approbation" value="OUI" class="btn btn-success flex-fill"><i class="lni lni-checkmark-circle"></i> Approuver</button><button type="submit" name="approbation" value="NON" class="btn btn-outline-danger flex-fill"><i class="lni lni-close"></i> Refuser</button></div></form>`
      : `<span class="appro-badge ${filtre === 'approuves' ? 'ok' : 'refus'}">${filtre === 'approuves' ? 'Approuvé' : 'Refusé'}</span>${s.motife_approbation ? `<p class="mt-2 mb-0">${esc(s.motife_approbation)}</p>` : ''}`}</div></div></article>`; }).join('')
    : `<p class="text-muted">Aucun dossier dans cette vue${r ? ' pour « ' + esc(r) + ' »' : ''}.</p>`}</div></div></section>`;
};

P['/cartographie'] = () => `<style>#map{height:500px}.leaflet-popup-content-wrapper{border-radius:0;width:250px;height:250px;display:flex;justify-content:center;align-items:center}</style>
  <section class="section "><div class="container-fluid ">${titreSection('Cartographie')}<div id="map"></div></div></section>`;

const ETATS_M = { brouillon: ['Brouillon', 'secondary'], planifiee: ['Planifiée', 'primary'], en_cours: ['En cours', 'warning text-dark'], en_reception: ['En réception', 'info text-dark'], terminee: ['Terminée', 'success'], annulee: ['Annulée', 'danger'] };
P['/missions'] = (_, q) => {
  const etat = q.etat || 'toutes', f = prendreFlash();
  const cpt = { toutes: S.missions.length, ouvertes: S.missions.filter(m => !['terminee', 'annulee'].includes(m.status)).length, terminees: S.missions.filter(m => m.status === 'terminee').length };
  const L = S.missions.filter(m => etat === 'toutes' || (etat === 'ouvertes' ? !['terminee', 'annulee'].includes(m.status) : m.status === 'terminee')).sort((a, b) => b.scheduled_at.localeCompare(a.scheduled_at));
  return `<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><div class="row align-items-center"><div class="col-md-6"><h2 class="text-success">Historique des missions</h2><p class="text-muted mb-0">Missions ouvertes et terminées, avec leur état.</p></div><div class="col-md-6 text-md-end mt-3 mt-md-0"><a href="#/missions/create" class="main-btn success-btn btn-hover"><i class="lni lni-plus"></i> Créer une mission</a></div></div></div>
    ${alerteBs(f)}
    <div class="d-flex flex-wrap gap-2 mb-3">${[['toutes', 'Toutes'], ['ouvertes', 'Ouvertes'], ['terminees', 'Terminées']].map(([k, l]) => `<a href="#/missions?etat=${k}" class="btn ${etat === k ? 'btn-success' : 'btn-outline-success'}">${l} <span class="badge ${etat === k ? 'bg-light text-dark' : 'bg-success'} ms-1">${cpt[k]}</span></a>`).join('')}</div>
    <div class="card-style mb-30"><div class="table-responsive"><table class="table align-middle"><thead><tr><th>Mission</th><th>État</th><th>Date</th><th>Commune</th><th>Équipe</th><th>Véhicules</th><th></th></tr></thead><tbody>
    ${L.length ? L.map(m => { const e = ETATS_M[m.status] || [m.status, 'secondary'], recus = m.removals.filter(r => r.reception).length; return `<tr>
      <td><strong>${esc(m.code || m.title)}</strong><br><small>${esc(m.title)}</small><br><span class="badge ${m.type === 'programmee' ? 'bg-success' : 'bg-warning text-dark'}">${m.type === 'programmee' ? 'Programmée' : 'Ponctuelle'}</span></td>
      <td><span class="badge bg-${e[1]}">${e[0]}</span><br><small class="text-muted">${m.status === 'terminee' ? 'Terminée le ' + (m.completed ? fDate(new Date(m.completed)) : '—') : m.status === 'annulee' ? 'Annulée' : 'Non terminée' + (m.validated ? ' · enlèvement validé' : '')}</small></td>
      <td>${m.scheduled_at ? fDH(new Date(m.scheduled_at)) : '—'}</td><td>${esc(m.commune || '—')}</td>
      <td>${m.agents.length || 'Tous'} sur le terrain<small class="d-block text-muted">${Object.keys(m.checked).length} pointé(s)</small><small class="d-block text-muted">Réception : ${esc(nom(user(m.reception_agent)) || '—')}</small></td>
      <td>${m.vehicles.length} ciblé(s)<small class="d-block text-muted">${m.removals.length} enlevé(s) · ${recus} en fourrière</small></td>
      <td class="text-end"><a class="btn btn-sm btn-outline-success" href="#/missions/${m.id}">Détails</a> <a class="btn btn-sm btn-outline-secondary" href="#/missions/${m.id}/edit">Modifier</a> <button class="btn btn-sm btn-outline-danger" data-suppr-mission="${m.id}" type="button">Supprimer</button></td></tr>`; }).join('')
      : '<tr><td colspan="7" class="text-center py-5">Aucune mission dans ce filtre.</td></tr>'}
    </tbody></table></div><div class="d-flex justify-content-end mt-4"></div></div></div></section>`;
};
P['/missions/create'] = (id) => {
  const m = id ? S.missions.find(x => x.id === +id) : null;
  const agents = S.users.filter(u => u.role === 2 && !u.archived);
  const pris = new Set(S.missions.filter(x => x !== m && x.status !== 'annulee').flatMap(x => x.vehicles));
  const vehicles = S.sigs.filter(s => s.is_approve && s.etat === 'EN COURS' && !s.non_removed_at && (!pris.has(s.id) || (m && m.vehicles.includes(s.id))));
  const selA = m ? m.agents : [], selV = m ? m.vehicles : [], selP = m ? m.pounds : [];
  return `<style>.mission-hero{background:linear-gradient(135deg,#073b2a,#0b8f55);color:#fff;border-radius:22px;padding:24px;box-shadow:0 16px 38px rgba(7,59,42,.18)}.mission-hero .meta{color:rgba(255,255,255,.78)}.form-card{border:1px solid #e7eee9;border-radius:18px;background:#fff;padding:22px;height:100%}.form-card h5{display:flex;align-items:center;gap:10px;margin-bottom:4px}.form-card .ico{width:40px;height:40px;border-radius:12px;display:grid;place-items:center;font-size:19px}.pick-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:10px;max-height:330px;overflow:auto;padding:2px}.pick{margin:0;cursor:pointer}.pick input{position:absolute;opacity:0;pointer-events:none}.pick-body{display:flex;align-items:center;gap:11px;border:2px solid #e1eae5;border-radius:14px;padding:11px 13px;background:#fff;transition:.15s;height:100%}.pick:hover .pick-body{border-color:#a8d9bf}.pick input:checked+.pick-body{border-color:#07834e;background:#e8f7ef;box-shadow:0 6px 16px rgba(8,120,68,.12)}.pick input:focus-visible+.pick-body{outline:2px solid #0b8f55;outline-offset:2px}.pick .avatar{min-width:38px;width:38px;height:38px;border-radius:12px;background:#e8f7ef;color:#07834e;display:grid;place-items:center;font-size:18px}.pick input:checked+.pick-body .avatar{background:#07834e;color:#fff}.pick .nom{font-weight:700;font-size:14px;line-height:1.2}.pick .detail{color:#77827c;font-size:12px}.pick-vide{color:#77827c;background:#f6f9f7;border-radius:14px;padding:18px;text-align:center}.compteur{font-size:12px;font-weight:700;color:#07834e;background:#e8f7ef;border-radius:20px;padding:4px 10px}@media(max-width:767px){.mission-hero{padding:18px}.pick-grid{grid-template-columns:1fr;max-height:none}}</style>
  <section class="section"><div class="container-fluid pb-5"><div class="pt-30 mb-4 d-flex flex-wrap align-items-center justify-content-between gap-3"><a href="#/missions" class="btn btn-outline-secondary">← Retour aux missions</a></div>
  <div class="mission-hero mb-4"><div class="d-flex gap-2 mb-2"><span class="badge bg-light text-dark">${m ? 'MODIFICATION' : 'NOUVELLE MISSION'}</span>${m ? `<span class="badge bg-light text-dark">${m.type === 'programmee' ? 'PROGRAMMÉE' : 'PONCTUELLE'}</span>` : ''}</div><h2 class="text-white mb-1">${m ? esc(m.code) : 'Créer une mission'}</h2><div class="meta">${m ? esc(m.title || 'Sans intitulé') : 'Renseignez l’organisation, l’équipe et les véhicules concernés.'}</div></div>
  <div id="erreurs"></div>
  <form id="form-mission" data-id="${m ? m.id : ''}">
  <div class="form-card mb-4"><h5><span class="ico" style="background:#e8f2ff;color:#1769aa">🗂️</span> Organisation</h5><p class="text-muted small mb-3">Type, commune et date de l’intervention.</p><div class="row g-3">
    <div class="col-md-4"><label class="form-label">Type *</label><select class="form-select" name="type" id="mission-type"><option value="programmee" ${!m || m.type === 'programmee' ? 'selected' : ''}>Programmée</option><option value="brute" ${m && m.type === 'brute' ? 'selected' : ''}>Ponctuelle</option></select></div>
    <div class="col-md-4"><label class="form-label">Commune</label><select class="form-select" name="commune"><option value="">Non renseignée</option>${COMMUNES.map(([c, d]) => `<option value="${esc(c)}" ${m && m.commune === c ? 'selected' : ''}>${esc(c)} — ${d}</option>`).join('')}</select></div>
    <div class="col-md-4"><label class="form-label">Date et heure</label><input type="datetime-local" class="form-control" name="scheduled_at" value="${m ? m.scheduled_at : ''}"></div>
    <div class="col-md-6"><label class="form-label">Intitulé facultatif</label><input class="form-control" name="title" value="${m ? esc(m.title) : ''}"></div>
    <div class="col-md-6"><label class="form-label">Nom du prestataire</label><input class="form-control" name="provider_name" value="${m ? esc(m.provider_name || '') : ''}"></div></div></div>
  <div class="row g-4 mb-4"><div class="col-lg-6"><div class="form-card"><h5><span class="ico" style="background:#e8f2ff;color:#1769aa">👥</span> Équipe terrain <span class="compteur ms-auto" id="compteur-agents">0</span></h5><p class="text-muted small mb-2" id="agents-help">Les agents qui interviennent sur place.</p>
    <div class="mb-2"><button type="button" class="btn btn-sm btn-outline-success" data-tout="agents">Tout cocher</button> <button type="button" class="btn btn-sm btn-outline-secondary" data-rien="agents">Tout décocher</button></div>
    <div class="pick-grid" id="grid-agents">${agents.map(a => `<label class="pick" data-agent="${a.id}"><input type="checkbox" name="agents" value="${a.id}" data-groupe="agents" ${selA.includes(a.id) ? 'checked' : ''}><span class="pick-body"><span class="avatar">👤</span><span><span class="nom">${esc(nom(a))}</span><br><span class="detail">${a.telephone}</span></span></span></label>`).join('')}</div></div></div>
    <div class="col-lg-6"><div class="form-card"><h5><span class="ico" style="background:#f0eaff;color:#6847b8">🏢</span> Réception en fourrière</h5><p class="text-muted small mb-3">Qui réceptionne les épaves, et où.</p>
      <div class="mb-3"><label class="form-label">Agent chargé de réceptionner *</label><select class="form-select" name="reception_agent_id" id="reception-agent" required><option value="">Sélectionner</option>${agents.map(a => `<option value="${a.id}" ${m && m.reception_agent === a.id ? 'selected' : ''}>${esc(nom(a))} — ${a.telephone}</option>`).join('')}</select><small class="text-muted">Un agent est soit sur le terrain, soit à la réception : celui choisi ici n’est plus sélectionnable dans l’équipe terrain, et inversement.</small></div>
      <div class="mb-3"><label class="form-label">Poste de fourrière *</label><select class="form-select" name="reception_pound" id="reception-pound" required><option value="">Sélectionner</option>${POUNDS.map(([n]) => `<option value="${esc(n)}" data-pound-name="${esc(n)}" ${m && m.reception_pound === n ? 'selected' : ''}>${esc(n)}</option>`).join('')}</select></div>
      <label class="form-label">Fourrières prêtes à accueillir les épaves</label><div class="pick-grid" id="grid-pounds" style="max-height:200px">${POUNDS.map(([n, d]) => `<label class="pick"><input type="checkbox" name="pounds" value="${esc(n)}" data-groupe="pounds" data-pound-name="${esc(n)}" ${selP.includes(n) ? 'checked' : ''}><span class="pick-body"><span class="avatar" style="background:#f0eaff;color:#6847b8">🏁</span><span><span class="nom">${esc(n)}</span><br><span class="detail">${d}</span></span></span></label>`).join('')}</div><small class="text-muted">Le poste de réception choisi est coché automatiquement.</small></div></div></div>
  <div class="form-card mb-4" id="vehicles-field"><h5><span class="ico" style="background:#e7f8f0;color:#087844">🚗</span> Véhicules approuvés à emporter <span class="compteur ms-auto" id="compteur-vehicles">0</span></h5><p class="text-muted small mb-2" id="vehicles-help">Obligatoire pour une mission programmée.</p><p class="text-muted small mb-2">Un véhicule déjà affecté à une autre mission (programmé, enlevé ou en fourrière) n’est plus proposé.</p>
    <div class="mb-2"><button type="button" class="btn btn-sm btn-outline-success" data-tout="vehicles">Tout cocher</button> <button type="button" class="btn btn-sm btn-outline-secondary" data-rien="vehicles">Tout décocher</button></div>
    <div class="pick-grid" id="grid-vehicles">${vehicles.length ? vehicles.map(v => `<label class="pick"><input type="checkbox" name="vehicles" value="${v.id}" data-groupe="vehicles" ${selV.includes(v.id) ? 'checked' : ''}><span class="pick-body"><span class="avatar">🚘</span><span><span class="nom">${esc(v.marque || 'Marque inconnue')} ${esc(v.model || '')}</span><br><span class="detail">#${v.id} · ${esc(v.numero_vehicule || 'sans plaque')}</span></span></span></label>`).join('') : '<div class="pick-vide">Aucun véhicule approuvé disponible : ceux déjà affectés à une autre mission n’apparaissent pas.</div>'}</div></div>
  <div class="form-card mb-4"><h5><span class="ico" style="background:#fff2db;color:#a26700">🚚</span> Camions et remorques</h5><p class="text-muted small mb-3">Le matériel mobilisé et son chauffeur.</p><div id="trucks"></div><button type="button" class="btn btn-outline-success btn-sm mt-2" id="add-truck">+ Ajouter un camion</button></div>
  <div class="text-end"><a href="#/missions" class="btn btn-outline-secondary me-2">Annuler</a><button class="main-btn success-btn" type="submit">${m ? 'Enregistrer les modifications' : 'Créer la mission'}</button></div></form></div></section>`;
};
P['/missions/show'] = (id) => {
  const m = S.missions.find(x => x.id === +id); if (!m) return P['/missions']({}, {});
  const st = ETATS_M[m.status] || [m.status, 'secondary'], f = prendreFlash(), stCls = st[1].split(' ')[0];
  const ready = [...new Set(m.pounds.concat([m.reception_pound]))];
  const parcours = m.vehicles.map(id2 => ({ key: 'v' + id2, v: sig(id2), r: m.removals.find(r => r.sig === id2) })).concat(m.removals.filter(r => !r.sig || !m.vehicles.includes(r.sig)).map((r, i) => ({ key: 'x' + i, v: r.sig ? sig(r.sig) : null, r })));
  const LBL = { front: 'Devant', back: 'Derrière', left: 'Gauche', right: 'Droite', sheet: 'Fiche' };
  const galerie = (media, cid, vide) => !media.length ? `<div class="empty-stage"><div><div class="fs-1">📷</div>${vide}</div></div>` : `<div id="${cid}" class="carousel slide" data-bs-touch="true"><div class="carousel-indicators">${media.map((x, i) => `<button type="button" data-bs-target="#${cid}" data-bs-slide-to="${i}" class="${i ? '' : 'active'}"></button>`).join('')}</div><div class="carousel-inner">${media.map((x, i) => `<div class="carousel-item ${i ? '' : 'active'}"><a href="${x.url}" target="_blank" rel="noopener"><img src="${x.url}" alt="${x.label}"></a><div class="carousel-caption"><span class="badge bg-dark">${x.label} · ${i + 1}/${media.length}</span></div></div>`).join('')}</div>${media.length > 1 ? `<button class="carousel-control-prev" type="button" data-bs-target="#${cid}" data-bs-slide="prev"><span class="carousel-control-prev-icon"></span></button><button class="carousel-control-next" type="button" data-bs-target="#${cid}" data-bs-slide="next"><span class="carousel-control-next-icon"></span></button>` : ''}</div>`;
  const label = j => j.r && j.r.label ? j.r.label : j.v ? `${j.v.marque || ''} ${j.v.model || ''}`.trim() || 'Véhicule' : 'Véhicule';
  const plaque = j => (j.r && j.r.plate) || (j.v && j.v.numero_vehicule) || 'Sans plaque';
  const base = j => j.r && j.r.base ? j.r.base : j.v ? (j.v.photoBase || 's' + j.v.id) : 's1050';
  const nonEnleve = j => j.v ? m.nonRemoved[j.v.id] : null;
  const stat = [['👥', '#e8f2ff', '#1769aa', 'Équipe terrain', m.agents.length + ' agent(s)', Object.keys(m.checked).length + ' pointé(s)'], ['🚚', '#fff2db', '#a26700', 'Transport', m.trucks.length + ' camion(s)', m.provider_name || 'Prestataire non renseigné'], ['🏁', '#f0eaff', '#6847b8', 'Fourrières prêtes', ready.length + ' site(s)', ready.join(', ') || 'Aucune'], ['🚗', '#e7f8f0', '#087844', 'Véhicules', parcours.length + ' dossier(s)', m.removals.length + ' enlèvement(s)']];
  return `<style>.mission-hero{background:linear-gradient(135deg,#073b2a,#0b8f55);color:#fff;border-radius:22px;padding:24px;box-shadow:0 16px 38px rgba(7,59,42,.18)}.mission-hero .meta{color:rgba(255,255,255,.78)}.mission-stat{height:100%;border:1px solid #e7eee9;border-radius:18px;padding:18px;background:#fff}.mission-stat .icon{width:44px;height:44px;border-radius:13px;display:grid;place-items:center;font-size:21px}.journey-card{border:1px solid #e1eae5;border-radius:18px;background:#fff;transition:.2s;overflow:hidden}.journey-card:hover{transform:translateY(-3px);box-shadow:0 14px 32px rgba(19,61,43,.11);border-color:#a8d9bf}.journey-card button{background:none;border:0;width:100%;text-align:left;padding:18px}.vehicle-avatar{min-width:52px;width:52px;height:52px;border-radius:16px;background:#e8f7ef;color:#07834e;display:grid;place-items:center;font-size:25px}.step-track{display:flex;gap:7px;flex-wrap:wrap}.step-chip{font-size:12px;font-weight:700;padding:6px 10px;border-radius:20px;background:#f0f3f1;color:#66736c}.step-chip.done{background:#e4f7ec;color:#087844}.step-chip.current{background:#fff2d7;color:#9b6500}.mission-gallery .carousel-item img{width:100%;height:430px;object-fit:contain;background:#101412;border-radius:14px}.empty-stage{min-height:240px;display:grid;place-items:center;text-align:center;background:#f6f9f7;border-radius:14px;color:#77827c}.nav-pills .nav-link{border-radius:12px;color:#405048}.nav-pills .nav-link.active{background:#07834e}@media(max-width:767px){.mission-hero{padding:18px}.mission-gallery .carousel-item img{height:280px}}</style>
  <section class="section"><div class="container-fluid pb-5"><div class="pt-30 mb-4 d-flex flex-wrap align-items-center justify-content-between gap-3"><a href="#/missions" class="btn btn-outline-secondary">← Retour aux missions</a><a href="#/missions/${m.id}/edit" class="main-btn success-btn">Modifier la mission</a></div>${alerteBs(f)}
  <div class="mission-hero mb-4"><div class="row align-items-center g-3"><div class="col-lg-8"><div class="d-flex gap-2 mb-2"><span class="badge bg-light text-dark">${m.type === 'programmee' ? 'PROGRAMMÉE' : 'PONCTUELLE'}</span><span class="badge bg-${stCls}">${st[0]}</span></div><h2 class="text-white mb-1">${esc(m.code)}</h2><div class="meta">${esc(m.title)} · Créée par ${esc(nom(user(m.created_by)) || '—')}</div></div><div class="col-lg-4 text-lg-end"><div class="fs-5 fw-semibold">${m.scheduled_at ? fCourt(new Date(m.scheduled_at)) : 'Date non renseignée'}</div><div class="meta">${esc(m.commune || 'Commune non renseignée')}</div></div></div></div>
  <div class="row g-3 mb-4">${stat.map(i => `<div class="col-sm-6 col-xl-3"><div class="mission-stat"><div class="icon mb-3" style="background:${i[1]};color:${i[2]}">${i[0]}</div><div class="text-muted small">${i[3]}</div><div class="fw-bold fs-6">${esc(i[4])}</div><small>${esc(i[5])}</small></div></div>`).join('')}</div>
  <div class="row g-4 mb-4"><div class="col-lg-7"><div class="card-style h-100"><h4 class="mb-3">Organisation</h4><div class="row g-3"><div class="col-md-6"><div class="text-muted small">Agents affectés</div>${m.agents.length ? m.agents.map(a => `<div class="py-2 border-bottom"><strong>${esc(nom(user(a)))}</strong><br><small class="${m.checked[a] ? 'text-success' : 'text-muted'}">${m.checked[a] ? 'Pointé le ' + fCourt(new Date(m.checked[a])) : 'Pas encore pointé'}</small></div>`).join('') : '<p>Ouverte à tous les agents</p>'}</div>
    <div class="col-md-6"><div class="text-muted small">Camions</div>${m.trucks.length ? m.trucks.map(t => `<div class="py-2 border-bottom"><strong>${esc(t.trailer_brand)} · ${esc(t.registration)}</strong><br><small>${esc(t.driver_name || 'Chauffeur non renseigné')} · ${esc(t.destination_pound_name || 'Destination à préciser')}</small></div>`).join('') : '<p>Aucun camion</p>'}</div></div></div></div>
    <div class="col-lg-5"><div class="card-style h-100"><h4 class="mb-3">Réception en fourrière</h4><div class="d-flex gap-3"><div class="vehicle-avatar" style="background:#f0eaff;color:#6847b8">🏢</div><div><strong>${esc(nom(user(m.reception_agent)) || 'Agent non renseigné')}</strong><div>${esc(m.reception_pound || 'Poste non renseigné')}</div><small class="text-muted">Pointage : ${m.status === 'en_reception' || m.completed ? fCourt(new Date(m.validated || m.scheduled_at)) : 'en attente'}</small><br><small class="text-muted">Fin : ${m.completed ? fCourt(new Date(m.completed)) : 'en attente'}</small></div></div></div></div></div>
  <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3"><div><h3 class="mb-1">Parcours des véhicules</h3><p class="text-muted mb-0">Cliquez sur un véhicule pour parcourir Signalement → Enlèvement → Réception.</p></div><span class="badge bg-light text-dark border">${parcours.length} véhicule(s)</span></div>
  <div class="row g-3">${parcours.length ? parcours.map(j => { const ne = nonEnleve(j); return `<div class="col-md-6 col-xl-4"><div class="journey-card h-100"><button type="button" data-bs-toggle="modal" data-bs-target="#journey-${j.key}"><div class="d-flex gap-3"><div class="vehicle-avatar">🚘</div><div class="flex-grow-1"><div class="fw-bold fs-6">${esc(label(j))}</div><div class="text-muted">${esc(plaque(j))}</div>
    <div class="step-track mt-3"><span class="step-chip done">✓ Signalement</span><span class="step-chip ${j.r ? 'done' : ne ? '' : 'current'}">${j.r ? '✓' : ne ? '✕' : '2'} ${ne ? 'Non enlevé' : 'Enlèvement'}</span><span class="step-chip ${j.r && j.r.reception ? 'done' : j.r ? 'current' : ''}">${j.r && j.r.reception ? '✓' : '3'} Réception</span></div>${ne ? `<div class="small text-warning mt-2">${esc(ne)}</div>` : ''}</div><span class="fs-4 text-muted">›</span></div></button></div></div>`; }).join('') : '<div class="col-12"><div class="card-style text-center text-muted py-5">Aucun véhicule associé à cette mission.</div></div>'}</div>
  ${parcours.map(j => { const id2 = 'journey-' + j.key, b = base(j), ne = nonEnleve(j), mediaSig = j.v ? [{ url: photoCit(j.v), label: 'Vue d’ensemble' }].concat(photosAgent(j.v).map(u => ({ url: u, label: 'Photo' }))) : [];
    const mediaRem = j.r ? ['front', 'back', 'left', 'right'].map(a => ({ url: (j.r.photos && j.r.photos[a]) || ph(`${b}_${a}.jpg`), label: LBL[a] })).concat([{ url: j.r.sheet || ph('fiche_1.jpg'), label: 'Fiche' }]) : [];
    const mediaRec = j.r && j.r.reception ? ['front', 'back', 'left', 'right'].map(a => ({ url: ph(`${b}_${a}.jpg`), label: LBL[a] })).concat([{ url: ph('fiche_2.jpg'), label: 'Fiche' }]) : [];
    return `<div class="modal fade" id="${id2}" tabindex="-1"><div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable"><div class="modal-content border-0 rounded-4"><div class="modal-header"><div><h4 class="modal-title">${esc(label(j))}</h4><div class="text-muted">${esc(plaque(j))}</div></div><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body">
    <ul class="nav nav-pills gap-2 mb-4"><li><button class="nav-link active" data-bs-toggle="pill" data-bs-target="#${id2}-report">1. Signalement</button></li><li><button class="nav-link" data-bs-toggle="pill" data-bs-target="#${id2}-removal">2. Enlèvement</button></li><li><button class="nav-link" data-bs-toggle="pill" data-bs-target="#${id2}-reception">3. Réception</button></li></ul>
    <div class="tab-content mission-gallery"><div class="tab-pane fade show active" id="${id2}-report">${galerie(mediaSig, id2 + '-report-carousel', 'Aucune photo de signalement disponible.')}</div>
    <div class="tab-pane fade" id="${id2}-removal">${!j.r ? `<div class="empty-stage"><div><div class="fs-1">${ne ? '🚫' : '⏳'}</div>${ne ? `<strong>Véhicule non enlevé</strong><br>${esc(ne)}` : 'Enlèvement pas encore effectué.'}</div></div>` : `<div class="row g-3 mb-3"><div class="col-md-4"><small class="text-muted">Camion</small><div class="fw-bold">${esc((m.trucks[j.r.truck] || {}).registration || '—')}</div></div><div class="col-md-4"><small class="text-muted">Fourrière</small><div class="fw-bold">${esc((m.trucks[j.r.truck] || {}).destination_pound_name || 'À préciser')}</div></div><div class="col-md-4"><small class="text-muted">Fiche</small><div class="fw-bold">Ajoutée</div></div></div>${galerie(mediaRem, id2 + '-removal-carousel', 'Aucune photo d’enlèvement.')}`}</div>
    <div class="tab-pane fade" id="${id2}-reception">${!(j.r && j.r.reception) ? '<div class="empty-stage"><div><div class="fs-1">🏁</div>Réception en attente.</div></div>' : `<div class="mb-3"><small class="text-muted">Réceptionné le</small><div class="fw-bold">${fCourt(new Date(j.r.reception))}</div></div>${galerie(mediaRec, id2 + '-reception-carousel', 'Aucune photo de réception.')}`}</div></div></div></div></div></div>`; }).join('')}
  </div></section>`;
};
P['/fourrieres'] = () => `<section class="section"><div class="container-fluid"><div class="title-wrapper pt-30 d-flex justify-content-between"><h2 class="text-success">Fourrières</h2><a class="main-btn success-btn" href="#/fourrieres" data-demo="Création d’une fourrière">Créer une fourrière</a></div>
  <div class="card-style"><div class="table-responsive"><table class="table"><thead><tr><th>Nom</th><th>Département</th><th>Missions</th><th></th></tr></thead><tbody>${POUNDS.map(([n, d]) => `<tr><td>${esc(n)}</td><td>${d}</td><td>${S.missions.filter(m => m.reception_pound === n).length}</td><td class="text-end"><a class="btn btn-sm btn-outline-secondary" href="#/fourrieres" data-demo="Modification d’une fourrière">Modifier</a></td></tr>`).join('')}</tbody></table></div></div></div></section>`;
P['/pointage'] = () => {
  const L = [['Cheikh', 'Ndiaye', 'Équipe terrain — matin', '29/10 08:00 – 29/10 16:00', '29/10 07:52:14', 38, 'early', null, '29/10 12:30:02', '29/10 13:15:40', null],
    ['Moussa', 'Diallo', 'Équipe terrain — matin', '29/10 08:00 – 29/10 16:00', '29/10 08:06:41', 12, 'on_time', null, null, null, null],
    ['Ibrahima', 'Sarr', 'Fourrière de Hann', '29/10 08:00 – 29/10 17:00', '29/10 08:21:09', 9, 'late', 21, null, null, null],
    ['Aminata', 'Sow', 'Équipe terrain — matin', '28/10 08:00 – 28/10 16:00', '28/10 07:58:30', 54, 'on_time', null, '28/10 12:40:11', '28/10 13:20:05', '28/10 15:41:22']];
  const ST = { early: 'En avance', on_time: 'À l’heure', late: 'En retard' };
  return `<section class="section"><div class="container-fluid"><div class="title-wrapper pt-30"><h2 class="text-success">Pointage des employés</h2></div>
  <nav class="d-flex flex-wrap gap-2 my-3" aria-label="Gestion du pointage"><a class="btn btn-success" href="#/pointage">Présences</a><a class="btn btn-outline-success" href="#/pointage" data-demo="Sites de pointage">Sites de pointage</a><a class="btn btn-outline-success" href="#/pointage" data-demo="Horaires et affectations">Horaires et affectations</a></nav>
  <form class="card-style mb-4" onsubmit="return false"><div class="row g-3 align-items-end"><div class="col-md-3"><label for="date" class="form-label">Date de début du service</label><input type="date" id="date" class="form-control" value="2026-10-29"></div><div class="col-md-3"><label for="site_id" class="form-label">Site</label><select id="site_id" class="form-select"><option>Tous les sites</option><option>Siège SENDRA</option><option>Fourrière de Hann</option></select></div><div class="col-md-3"><label for="status" class="form-label">Statut</label><select id="status" class="form-select"><option>Tous les statuts</option><option>En avance</option><option>À l’heure</option><option>En retard</option><option>Sans départ</option></select></div><div class="col-md-3"><button class="btn btn-success">Afficher</button></div></div></form>
  <div class="card-style table-responsive"><table class="table"><thead><tr><th>Employé / site</th><th>Service prévu</th><th>Début de travail</th><th>Statut</th><th>Début de pause</th><th>Fin de pause</th><th>Fin de travail</th><th>Départ anticipé</th></tr></thead><tbody>
  ${L.map(r => `<tr><td>${r[0]} ${r[1]}<br><small>${esc(r[2])}</small></td><td>${r[3]}<br><small>Africa/Dakar</small></td><td>${r[4]}<br><small>Distance : ${r[5]} m</small></td><td><span class="badge ${r[6] === 'late' ? 'bg-warning text-dark' : 'bg-success'}">${ST[r[6]]}</span>${r[7] ? `<br><small>Écart réel : ${r[7]} min</small>` : ''}</td><td>${r[8] || '—'}</td><td>${r[9] || '—'}</td><td>${r[10] || '<span class="text-muted">Sans départ</span>'}</td><td>—</td></tr>`).join('')}</tbody></table></div></div></section>`;
};
P['/communes'] = () => `<section class="section"><div class="container-fluid"><div class="title-wrapper pt-30"><div class="row align-items-center"><div class="col-md-6"><h2 class="text-success">Communes</h2></div><div class="col-md-6 text-md-end"><a href="#/communes" data-demo="Ajout d’une commune" class="main-btn success-btn btn-hover">Ajouter une commune</a></div></div></div>
  <div class="card-style mb-30"><div class="table-responsive"><table class="table align-middle"><thead><tr><th>Commune</th><th>Département</th><th>Marge</th><th>Missions</th><th></th></tr></thead><tbody>
  ${COMMUNES.map(([c, d, mg]) => `<tr><td><strong>${esc(c)}</strong></td><td>${d}</td><td>${mg} m</td><td>${S.missions.filter(m => m.commune === c).length}</td><td class="text-end"><a class="btn btn-sm btn-outline-success" href="#/communes" data-demo="Fiche de la commune">Détails</a> <a class="btn btn-sm btn-outline-secondary" href="#/communes" data-demo="Modification de la commune">Modifier</a></td></tr>`).join('')}</tbody></table></div></div></div></section>`;
P['/messages'] = (_, q) => {
  const statut = q.statut || '', L = S.messages.filter(m => !statut || m.statut === statut), C = { nouveau: 'bg-danger', en_cours: 'bg-warning text-dark', traite: 'bg-success' }, f = prendreFlash();
  return `<section class="section"><div class="container-fluid"><div class="title-wrapper pt-30 d-flex justify-content-between align-items-center flex-wrap gap-2"><div><h2 class="text-success">Messages du site web</h2><p class="text-muted mb-0">Reçus via le formulaire de la page Contact du site. Visibles par l'Admin uniquement.</p></div></div>${alerteBs(f)}
  <div class="card-style mb-3"><form class="d-flex flex-wrap gap-2 align-items-center" onsubmit="return false"><a href="#/messages" class="btn btn-sm ${!statut ? 'btn-success' : 'btn-outline-success'}">Tous (${S.messages.length})</a>${Object.entries(STATUTS_MSG).map(([k, l]) => `<a href="#/messages?statut=${k}" class="btn btn-sm ${statut === k ? 'btn-success' : 'btn-outline-success'}">${l} (${S.messages.filter(m => m.statut === k).length})</a>`).join('')}<input type="search" class="form-control form-control-sm ms-auto" style="max-width:260px" placeholder="Nom, e-mail, objet, texte…"><button class="btn btn-sm btn-outline-secondary">Rechercher</button></form></div>
  <div class="card-style"><div class="table-responsive"><table class="table align-middle"><thead><tr><th>Reçu le</th><th>Expéditeur</th><th>Objet</th><th>Statut</th><th></th></tr></thead><tbody>
  ${L.length ? L.map(m => `<tr class="${m.lu ? '' : 'fw-semibold'}"><td class="text-nowrap">${fDH(new Date(m.created_at))}</td><td>${esc(m.nom)}<br><small class="text-muted">${esc(m.email)}${m.telephone ? ' · ' + m.telephone : ''}</small></td><td>${esc(m.objet || '—')}<br><small class="text-muted">${esc(m.message.slice(0, 90))}${m.message.length > 90 ? '...' : ''}</small></td><td><span class="badge ${C[m.statut]}">${STATUTS_MSG[m.statut]}</span></td><td class="text-end"><a class="btn btn-outline-success btn-sm" href="#/messages/${m.id}">Ouvrir</a></td></tr>`).join('') : '<tr><td colspan="5">Aucun message.</td></tr>'}</tbody></table></div></div></div></section>`;
};
P['/messages/show'] = (id) => {
  const m = S.messages.find(x => x.id === +id); if (!m) return P['/messages']({}, {});
  if (!m.lu) { m.lu = true; sauver(); }
  return `<section class="section"><div class="container-fluid"><div class="title-wrapper pt-30"><a href="#/messages" class="btn btn-outline-secondary mb-3">← Retour aux messages</a><h2 class="text-success">${esc(m.objet || 'Message')}</h2></div>
  <div class="card-style mb-3"><dl class="row mb-0"><dt class="col-sm-3">Reçu le</dt><dd class="col-sm-9">${fDH(new Date(m.created_at))}</dd><dt class="col-sm-3">Expéditeur</dt><dd class="col-sm-9">${esc(m.nom)}</dd><dt class="col-sm-3">E-mail</dt><dd class="col-sm-9"><a href="mailto:${esc(m.email)}">${esc(m.email)}</a></dd>${m.telephone ? `<dt class="col-sm-3">Téléphone</dt><dd class="col-sm-9">${m.telephone}</dd>` : ''}</dl><hr><p class="mb-0" style="white-space:pre-line">${esc(m.message)}</p></div>
  <div class="card-style"><form class="d-flex flex-wrap gap-2 align-items-end" data-statut-msg="${m.id}"><div><label class="form-label">Statut</label><select class="form-select" name="statut">${Object.entries(STATUTS_MSG).map(([k, l]) => `<option value="${k}" ${m.statut === k ? 'selected' : ''}>${l}</option>`).join('')}</select></div><button class="main-btn success-btn btn-hover" type="submit">Enregistrer</button></form></div></div></section>`;
};
const ROLE_PAGE = { admin: [1, 'Admin'], agents: [2, 'Agent'], autorites: [3, 'Autorité - Commune'], utilisateurs: [4, 'Autorité - Préfecture'], operateurs: [7, 'Opérateur'], citoyens: [5, 'Citoyens'] };
P['/comptes'] = (role, q) => {
  if (role === 'ajouter') return P['/comptes/ajouter']();
  const [rid, lib] = ROLE_PAGE[role] || ROLE_PAGE.agents, archives = q.archives === '1' && rid !== 5, f = prendreFlash();
  const L = S.users.filter(u => u.role === rid && !!u.archived === archives);
  const th = t => `<th class="min-width"><h6 class="text-sm text-medium">${t}</h6></th>`;
  const titre = rid === 5 ? 'Comptes Citoyens' : `Comptes ${lib}`;
  return `<section class="section "><div class="container-fluid "><div class="title-wrapper pt-30"><div class="row align-items-center"><div class="col-md-6"><div class="title"><h2 class="text-success">${titre}</h2></div></div>
    ${rid !== 5 ? `<div class="col-md-6 d-flex justify-content-md-end mt-3 mt-md-0">${archives ? `<a href="#/comptes/${role}" class="main-btn light-btn btn-hover"><i class="lni lni-arrow-left"></i> Comptes actifs</a>` : `<a href="#/comptes/${role}?archives=1" class="main-btn light-btn btn-hover"><i class="lni lni-trash-can"></i> Comptes supprimés</a>`}</div>` : ''}</div></div>${alertes(f)}
  <div class="row"><div class="col-lg-12"><div class="card-style mb-30"><div class="title d-flex flex-wrap align-items-center justify-content-between"><div class="left"><h6 class="text-medium mb-30">${rid === 5 ? 'Liste des comptes Citoyens' : archives ? `Comptes ${lib} supprimés` : `Liste des comptes ${lib}`}</h6></div></div>
  <div class="table-responsive"><table class="table top-selling-table"><thead><tr>${th('Nom')}${th('Prénom')}${th('email')}${th('Téléphone')}${rid !== 5 ? '<th><h6 class="text-sm text-medium text-start">Role</h6></th>' : ''}<th><h6 class="text-sm text-medium text-end">Actions</h6></th></tr></thead><tbody>
  ${L.map(u => `<tr><td><p class="text-sm">${esc(u.first_name)}</p></td><td><p class="text-sm">${esc(u.last_name)}</p></td><td><p class="text-sm">${esc(u.email)}</p></td><td><p class="text-sm">${u.telephone}</p></td>${rid !== 5 ? `<td><p class="text-sm">${ROLES[u.role]}</p></td>` : ''}
    <td><div class="action d-flex justify-content-end align-items-center" style="gap: 14px;">${archives ? `<button type="button" class="border-0 bg-transparent p-0 text-success" title="Restaurer ce compte" data-restaurer="${u.id}"><i class="lni lni-reload"></i></button>`
      : `<a href="#/comptes/${role}" data-demo="Modification du compte" class="edit text-success" title="Modifier ce compte"><i class="lni lni-pencil"></i></a>${u.id !== S.me ? `<button type="button" class="border-0 bg-transparent p-0 text-danger" title="Supprimer ce compte" data-supprimer="${u.id}"><i class="lni lni-trash-can"></i></button>` : ''}`}</div></td></tr>`).join('')}
  </tbody></table><div class="d-flex justify-content-end mt-4"></div></div></div></div></div></div></section>`;
};
P['/comptes/ajouter'] = () => `<section class="tab-components"><div class="container-fluid">${titreSection('Ajouter un Compte')}<div class="title-wrapper pt-30" id="erreurs-compte"></div>
  <div class="form-elements-wrapper"><div class="row"><div class="col-lg-12"><div class="card-style mb-30"><div class="white_card_body"><div class="card-body"><form id="form-compte">
  <div class="row mb-3"><div class="col-md-12"><label class="form-label" for="inputEmail4">Email</label><input type="email" class="form-control" id="inputEmail4" name="email"></div></div>
  <div class="row mb-3"><div class="col-md-6"><label class="form-label" for="prenom">Prémon</label><input type="text" class="form-control" id="prenom" name="prenom"></div><div class=" col-md-6"><label class="form-label" for="nom">Nom</label><input type="text" class="form-control" id="nom" name="nom"></div></div>
  <div class="row mb-3"><div class=" col-md-6"><label class="form-label" for="telephone">Téléphone</label><input type="text" class="form-control" id="telephone" name="telephone"></div><div class="col-md-6"><label class="form-label" for="inputState">Role</label><select id="inputState" class="form-control" name="role"><option value="1">Admin</option><option value="2">Agent</option><option value="3">Autorité - Commune</option><option value="4">Autorité - Préfecture</option><option value="7">Opérateur</option></select></div></div>
  <button type="submit" class="main-btn success-btn-light btn-hover"><i class="lni lni-checkmark"></i> Ajouter</button></form></div></div></div></div></div></div></div></section>`;
P['/profil'] = () => { const u = me(); return `<section class="section"><div class="container-fluid">${titreSection('Profil')}<div class="row"><div class="col-lg-6"><div class="card-style mb-30"><h6 class="mb-25">Informations du profil</h6>
  <div class="input-style-1"><label>Prénom</label><input type="text" value="${esc(u.first_name)}" readonly></div><div class="input-style-1"><label>Nom</label><input type="text" value="${esc(u.last_name)}" readonly></div><div class="input-style-1"><label>E-mail</label><input type="email" value="${esc(u.email)}" readonly></div></div></div>
  <div class="col-lg-6"><div class="card-style mb-30"><h6 class="mb-25">Modifier le mot de passe</h6><form data-demo-form="Mot de passe modifié."><div class="input-style-1"><label>Mot de passe actuel</label><input type="password" required></div><div class="input-style-1"><label>Nouveau mot de passe</label><input type="password" required></div><button class="main-btn success-btn btn-hover">Enregistrer</button></form></div></div></div></div></section>`; };

/* ───────── Connexion (auth/login.blade.php) ───────── */
const LOGIN = () => `<section class="signin-section"><div class="container mt-5"><div class="title-wrapper pt-30"><div class="col-md-12"></div></div></div>
  <div class="row g-0 auth-row"><div class="col-lg-6"><div class="auth-cover-wrapper bg-success-100"><div class="auth-cover"><div class="title text-center"><h1 class="auth-title">Bienvenue</h1><p class="auth-subtitle">Connectez-vous à votre compte existant pour continuer.</p></div></div></div></div>
  <div class="col-lg-6"><div class="signin-wrapper"><div class="form-wrapper "><div class="shape-image mb-25 d-flex justify-content-center flex-wrap"><img src="img/EPAVIE.png" alt="" width="50%" height="50%"></div><h2 class="mb-25 text-center">Connexion</h2>
  <form id="form-login"><div class="row"><div class="col-12"><div class="demo-roles mb-25"><label class="d-block mb-2" style="font-weight:600">Se connecter en tant que <span class="text-muted" style="font-weight:400">(démo)</span></label>
    <div class="demo-roles-grid">${COMPTES_DEMO.map(([r, , mail], i) => `<label><input type="radio" name="role" value="${r}" ${i ? '' : 'checked'}><span><i class="lni ${ROLE_UI[r][2]}"></i>${ROLE_UI[r][1]}</span></label>`).join('')}</div></div></div>
  <div class="col-12"><div class="input-style-1"><label>E-mail</label><input type="email" name="email" class="form-control" placeholder="admin@sendra.sn" autocomplete="username"><div class="text-danger" id="err-email"></div></div></div>
  <div class="col-12"><div class="input-style-1"><label>Mot de passe</label><div style="position:relative"><input type="password" id="motDePasse" name="password" class="form-control" placeholder="Votre mot de passe" autocomplete="current-password" style="padding-right:52px">
  <button type="button" id="basculerMotDePasse" aria-label="Afficher le mot de passe" title="Afficher le mot de passe" style="position:absolute;top:50%;right:8px;transform:translateY(-50%);border:0;background:transparent;padding:8px;line-height:0;color:#6b7c72;cursor:pointer"><svg class="oeil-ouvert" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg><svg class="oeil-barre" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="display:none"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><path d="M14.12 14.12a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg></button></div><div class="text-danger" id="err-password"></div></div></div>
  <div class="col-12"><div class="button-group d-flex justify-content-center flex-wrap"><button class="main-btn success-btn btn-hover w-100 text-center">Connexion</button></div></div>
  <div class="col-12"><p class="text-center text-sm text-muted mt-3 mb-0">Démo : n’importe quelle adresse e-mail et n’importe quel mot de passe.</p></div></div></form></div></div></div></div></section>`;

/* ───────── Routeur ───────── */
let map = null;
function route() {
  const h = location.hash.replace(/^#/, '') || '/';
  const [chemin, qs] = h.split('?'); const q = Object.fromEntries(new URLSearchParams(qs || ''));
  const app = document.getElementById('app');
  if (!S.logged) { document.body.className = ''; app.innerHTML = LOGIN(); brancherLogin(); return; }
  document.body.className = 'role-' + ROLE_UI[me().role][0];
  const seg = chemin.split('/').filter(Boolean);
  if (!(DROITS['/' + (seg[0] || '')] || DROITS['/']).includes(me().role)) { location.replace('#/'); return; }
  let html, cle = '/' + (seg[0] || '');
  if (!seg.length) html = P['/']();
  else if (seg[0] === 'details') html = P['/details'](seg[1], q);
  else if (seg[0] === 'missions' && seg[1] === 'create') html = P['/missions/create']();
  else if (seg[0] === 'missions' && seg[2] === 'edit') html = P['/missions/create'](seg[1]);
  else if (seg[0] === 'missions' && seg[1]) html = P['/missions/show'](seg[1]);
  else if (seg[0] === 'messages' && seg[1]) html = P['/messages/show'](seg[1]);
  else if (seg[0] === 'comptes') html = P['/comptes'](seg[1] || 'agents', q);
  else html = (P[cle] || P['/'])(null, q);
  const ouvert = app.querySelector('.sidebar-nav-wrapper.active');
  const actifChemin = seg[0] === 'details' ? '/' + ({ SIGNALE: 'signales', 'EN COURS': 'encours', ENLEVE: 'enleves', REJETE: 'rejetes', 'NON RESOLU': 'non-resolus' }[etatAffiche(sig(seg[1]) || {})] || '') : chemin;
  app.innerHTML = sidebar(actifChemin) + `<main class="main-wrapper">${header()}${html}${FOOTER}</main>`;
  document.querySelectorAll('.modal-backdrop').forEach(b => b.remove()); document.body.classList.remove('modal-open'); document.body.style.overflow = '';
  if (ouvert) app.querySelector('.sidebar-nav-wrapper').classList.add('active');
  brancherCommun();
  if (cle === '/cartographie') carte(q.id);
  if (cle === '/missions' && (seg[1] === 'create' || seg[2] === 'edit')) brancherMission(seg[2] === 'edit' ? seg[1] : null);
  window.scrollTo(0, 0);
}
function brancherLogin() {
  const champ = document.getElementById('motDePasse'), bouton = document.getElementById('basculerMotDePasse');
  const mail = document.querySelector('#form-login input[name=email]');
  document.querySelectorAll('#form-login input[name=role]').forEach(r => r.addEventListener('change', () => { mail.placeholder = COMPTES_DEMO.find(c => c[0] === +r.value)[2]; }));
  bouton.addEventListener('click', () => { const v = champ.type === 'password'; champ.type = v ? 'text' : 'password'; bouton.querySelector('.oeil-ouvert').style.display = v ? 'none' : ''; bouton.querySelector('.oeil-barre').style.display = v ? '' : 'none'; const l = v ? 'Masquer le mot de passe' : 'Afficher le mot de passe'; bouton.setAttribute('aria-label', l); bouton.title = l; champ.focus(); });
  document.getElementById('form-login').addEventListener('submit', e => {
    e.preventDefault(); const f = e.target, email = f.email.value.trim();
    document.getElementById('err-email').textContent = /^\S+@\S+\.\S+$/.test(email) ? '' : 'Le champ e-mail doit être une adresse e-mail valide.';
    document.getElementById('err-password').textContent = f.password.value ? '' : 'Le champ mot de passe est obligatoire.';
    if (!/^\S+@\S+\.\S+$/.test(email) || !f.password.value) return;
    const role = +(f.role.value || 1), compte = COMPTES_DEMO.find(c => c[0] === role);
    S.logged = true; S.me = compte[1]; sauver();
    location.hash = '#/'; route();
  });
}
function brancherCommun() {
  const sb = document.querySelector('.sidebar-nav-wrapper'), mw = document.querySelector('.main-wrapper'), ov = document.querySelector('.overlay'), bt = document.getElementById('menu-toggle'), ic = bt.querySelector('i');
  bt.addEventListener('click', () => { sb.classList.toggle('active'); ov.classList.add('active'); mw.classList.toggle('active'); if (document.body.clientWidth > 1200 || ic.classList.contains('lni-chevron-left')) { ic.classList.toggle('lni-chevron-left'); ic.classList.toggle('lni-menu'); } });
  ov.addEventListener('click', () => { sb.classList.remove('active'); ov.classList.remove('active'); mw.classList.remove('active'); });
  document.querySelectorAll('.sidebar-nav a[href^="#/"]').forEach(a => a.addEventListener('click', () => { if (document.body.clientWidth <= 1200) { sb.classList.remove('active'); ov.classList.remove('active'); mw.classList.remove('active'); } }));
  document.getElementById('logout').addEventListener('submit', e => { e.preventDefault(); S.logged = false; sauver(); location.hash = '#/login'; route(); });
  document.getElementById('recherche').addEventListener('submit', e => { e.preventDefault(); const v = e.target.querySelector('input').value.trim().toLowerCase().replace(/[^a-z0-9]/g, ''); if (!v) return; const s = S.sigs.find(x => String(x.id) === v || (x.numero_vehicule || '').toLowerCase().replace(/[^a-z0-9]/g, '').includes(v)); if (s) location.hash = '#/details/' + s.id; else alert('Aucun signalement ne correspond à cette recherche.'); });
  // Décision sur la fiche
  const fd = document.querySelector('[data-decision]');
  if (fd) fd.addEventListener('submit', e => { e.preventDefault(); const v = fd.approbation.value, motif = fd.motife_approbation.value.trim(); if (v === 'NON' && !motif) { fd.motife_approbation.classList.add('is-invalid'); return; } decider(+fd.dataset.decision, v, motif); flash(v === 'OUI' ? 'Le signalement a été approuvé.' : 'Le signalement a été rejeté.'); route(); });
  document.querySelectorAll('[data-appro]').forEach(fm => fm.addEventListener('submit', e => { e.preventDefault(); const v = e.submitter ? e.submitter.value : 'OUI', motif = fm.motife_approbation.value.trim(); if (v === 'NON' && !motif) { flash('Le motif est obligatoire en cas de refus.', 'danger'); route(); return; } decider(+fm.dataset.appro, v, motif); flash(v === 'OUI' ? `Signalement n° ${fm.dataset.appro} approuvé.` : `Signalement n° ${fm.dataset.appro} refusé.`); route(); }));
  const ra = document.querySelector('[data-recherche-appro]');
  if (ra) ra.addEventListener('submit', e => { e.preventDefault(); const v = ra.q.value.trim(); location.hash = `#/approbations?filtre=${ra.dataset.rechercheAppro}${v ? '&q=' + encodeURIComponent(v) : ''}`; });
  document.querySelectorAll('[data-suppr-mission]').forEach(b => b.addEventListener('click', () => { if (!confirm('Supprimer cette mission ?')) return; S.missions = S.missions.filter(m => m.id !== +b.dataset.supprMission); flash('Mission supprimée.'); route(); }));
  document.querySelectorAll('[data-supprimer]').forEach(b => b.addEventListener('click', () => { if (!confirm('Supprimer ce compte ?\n\nIl ne pourra plus se connecter et ne recevra plus les e-mails de SENDRA. Ses signalements sont conservés, et le compte reste restaurable depuis « Comptes supprimés ».')) return; user(b.dataset.supprimer).archived = true; flash('Le compte a été supprimé.'); route(); }));
  document.querySelectorAll('[data-restaurer]').forEach(b => b.addEventListener('click', () => { if (!confirm('Restaurer ce compte ? Il pourra de nouveau se connecter au back-office.')) return; user(b.dataset.restaurer).archived = false; flash('Le compte a été restauré.'); route(); }));
  document.querySelectorAll('[data-demo]').forEach(a => a.addEventListener('click', e => { e.preventDefault(); alert(`Démo : « ${a.dataset.demo} » n’est pas disponible dans cette version de démonstration.`); }));
  document.querySelectorAll('[data-demo-form]').forEach(fm => fm.addEventListener('submit', e => { e.preventDefault(); alert(fm.dataset.demoForm); fm.reset(); }));
  const sm = document.querySelector('[data-statut-msg]');
  if (sm) sm.addEventListener('submit', e => { e.preventDefault(); S.messages.find(m => m.id === +sm.dataset.statutMsg).statut = sm.statut.value; flash('Statut du message mis à jour.'); location.hash = '#/messages'; });
  const fc = document.getElementById('form-compte');
  if (fc) fc.addEventListener('submit', e => {
    e.preventDefault(); const v = n => fc[n].value.trim(), err = [];
    if (!/^\S+@\S+\.\S+$/.test(v('email'))) err.push('Le champ email doit être une adresse e-mail valide.');
    if (!v('prenom')) err.push('Le champ prenom est obligatoire.'); if (!v('nom')) err.push('Le champ nom est obligatoire.');
    if (!/^\d{9}$/.test(v('telephone').replace(/\s/g, ''))) err.push('Le champ telephone doit contenir 9 chiffres.');
    if (S.users.some(u => u.email.toLowerCase() === v('email').toLowerCase())) err.push('La valeur du champ email est déjà utilisée.');
    if (err.length) { document.getElementById('erreurs-compte').innerHTML = `<div class="row alert-box danger-alert"><div class="col-12 alert"><p class="text-medium mb-1">Le formulaire n'a pas pu être enregistré :</p><ul class="mb-0">${err.map(m => `<li class="text-medium">${esc(m)}</li>`).join('')}</ul></div></div>`; return; }
    const role = +v('role'); S.users.push({ id: Math.max(...S.users.map(u => u.id)) + 1, first_name: v('prenom'), last_name: v('nom'), email: v('email'), telephone: v('telephone').replace(/\s/g, ''), role, archived: false });
    flash('Compte créé avec succès. Les identifiants ont été envoyés à l’utilisateur.');
    location.hash = '#/comptes/' + Object.keys(ROLE_PAGE).find(k => ROLE_PAGE[k][0] === role);
  });
  sauver();
}
function decider(id, v, motif) { const s = sig(id); s.updated_at = new Date().toISOString(); s.motife_approbation = motif || null; if (v === 'OUI') { s.is_approve = true; s.approuve_at = s.updated_at; } else { s.etat = 'REJETE'; s.is_approve = false; } sauver(); }
function carte(focus) {
  if (!window.L) { document.getElementById('map').innerHTML = '<p class="text-muted p-3">Carte indisponible : vérifiez la connexion à Internet.</p>'; return; }
  map = L.map('map', { center: { lat: 14.7627, lng: -17.3441 }, zoom: 10.5 });
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '© OpenStreetMap' }).addTo(map);
  const icone = L.icon({ iconUrl: 'img/icons8-location-pin-48.png', iconSize: [30, 30], iconAnchor: [15, 15], popupAnchor: [0, -15] });
  let cible = null;
  S.sigs.forEach(s => { const mk = L.marker([s.latitude, s.longitude], { icon: icone, draggable: false }).addTo(map); mk.bindPopup(`<div class="square-popup"><b>${esc(s.title)}</b><br><img src="${photoCit(s)}" alt="Marker Image" style="width: 230px; height: 230px; object-fit:cover"></div>`, { className: 'custom-popup' }); if (focus && s.id === +focus) cible = { mk, s }; });
  if (cible) { map.setView([cible.s.latitude, cible.s.longitude], 15); cible.mk.openPopup(); }
}
function brancherMission(id) {
  const form = document.getElementById('form-mission'), m = id ? S.missions.find(x => x.id === +id) : null;
  let i = 0; const ajouter = (v = {}) => { const d = document.createElement('div'); d.className = 'row g-2 mt-1 repeat-row align-items-center'; d.innerHTML = `<div class="col-md-3"><input class="form-control" data-name="trailer_brand" placeholder="Marque remorque" value="${esc(v.trailer_brand || '')}"></div><div class="col-md-3"><input class="form-control" data-name="registration" placeholder="Immatriculation" value="${esc(v.registration || '')}"></div><div class="col-md-3"><input class="form-control" data-name="driver_name" placeholder="Nom du chauffeur" value="${esc(v.driver_name || '')}"></div><div class="col-md-2"><input type="number" min="1" class="form-control" data-name="seats" placeholder="Places" value="${v.seats || ''}"></div><div class="col-md-1"><button type="button" class="btn btn-outline-danger remove-row">×</button></div>`; document.getElementById('trucks').appendChild(d); i++; };
  document.getElementById('add-truck').onclick = () => ajouter();
  form.addEventListener('click', e => { if (e.target.classList.contains('remove-row')) e.target.closest('.repeat-row').remove(); });
  (m && m.trucks.length ? m.trucks : [{}]).forEach(ajouter);
  const compteurs = { agents: 'compteur-agents', vehicles: 'compteur-vehicles' }, cases = g => [...form.querySelectorAll(`input[data-groupe="${g}"]`)];
  const maj = g => { const c = document.getElementById(compteurs[g]); if (c) c.textContent = cases(g).filter(x => x.checked).length + ' / ' + cases(g).length; };
  Object.keys(compteurs).forEach(g => { cases(g).forEach(c => c.addEventListener('change', () => maj(g))); maj(g); });
  form.querySelectorAll('[data-tout]').forEach(b => b.onclick = () => { cases(b.dataset.tout).forEach(c => { if (!c.disabled) c.checked = true; }); maj(b.dataset.tout); exclu(); });
  form.querySelectorAll('[data-rien]').forEach(b => b.onclick = () => { cases(b.dataset.rien).forEach(c => c.checked = false); maj(b.dataset.rien); exclu(); });
  const rp = document.getElementById('reception-pound'), coh = () => { const n = rp.selectedOptions[0]?.dataset.poundName; if (!n) return; const c = form.querySelector(`input[data-groupe="pounds"][data-pound-name="${CSS.escape(n)}"]`); if (c) c.checked = true; };
  rp.addEventListener('change', coh); coh();
  const ra = document.getElementById('reception-agent'), exclu = () => { const r = ra.value, t = cases('agents').filter(c => c.checked).map(c => c.value); cases('agents').forEach(c => { const b = r !== '' && c.value === r; if (b) c.checked = false; c.disabled = b; c.closest('.pick').style.opacity = b ? .45 : 1; c.closest('.pick').title = b ? 'Agent de réception de cette mission' : ''; }); [...ra.options].forEach(o => o.disabled = o.value !== '' && t.includes(o.value)); maj('agents'); };
  ra.addEventListener('change', exclu); cases('agents').forEach(c => c.addEventListener('change', exclu)); exclu();
  const type = document.getElementById('mission-type'), refresh = () => { const p = type.value === 'programmee'; document.getElementById('agents-help').textContent = p ? 'Au moins un agent est obligatoire pour une mission programmée.' : 'Facultatif : sans sélection, tous les agents verront la mission.'; document.getElementById('vehicles-help').textContent = p ? 'Au moins un véhicule approuvé est obligatoire.' : 'Facultatif : cochez les véhicules déjà connus pour que les agents les voient avant l’intervention.'; };
  type.onchange = refresh; refresh();
  form.addEventListener('submit', e => {
    e.preventDefault(); const err = [], sel = g => cases(g).filter(c => c.checked).map(c => g === 'pounds' ? c.value : +c.value);
    const p = type.value === 'programmee';
    if (p && !sel('agents').length) err.push('Choisissez au moins un agent pour une mission programmée.');
    if (p && !sel('vehicles').length) err.push('Choisissez au moins un véhicule approuvé pour une mission programmée.');
    if (!ra.value) err.push('Le champ agent chargé de réceptionner est obligatoire.');
    if (!rp.value) err.push('Le champ poste de fourrière est obligatoire.');
    if (err.length) { document.getElementById('erreurs').innerHTML = `<div class="alert alert-danger"><ul class="mb-0">${err.map(x => `<li>${esc(x)}</li>`).join('')}</ul></div>`; window.scrollTo(0, 0); return; }
    const trucks = [...document.querySelectorAll('#trucks .repeat-row')].map(r => { const o = {}; r.querySelectorAll('[data-name]').forEach(x => o[x.dataset.name] = x.value.trim()); return o; }).filter(t => t.trailer_brand || t.registration);
    const commune = form.commune.value;
    const data = { type: type.value, commune, scheduled_at: form.scheduled_at.value, title: form.title.value.trim() || `Enlèvement ${p ? 'programmé' : 'ponctuel'}${commune ? ' — ' + commune : ''}`, provider_name: form.provider_name.value.trim(), agents: sel('agents'), vehicles: sel('vehicles'), pounds: [...new Set(sel('pounds'))], reception_agent: +ra.value, reception_pound: rp.value, trucks: trucks.map(t => Object.assign({ destination_pound_name: null }, t)) };
    if (m) { Object.assign(m, data); flash('Mission mise à jour.'); location.hash = '#/missions/' + m.id; }
    else { const nid = Math.max(...S.missions.map(x => x.id)) + 1; S.missions.push(Object.assign({ id: nid, code: 'MIS-2026-0' + nid, status: 'planifiee', checked: {}, nonRemoved: {}, removals: [], validated: null, completed: null, created_by: S.me }, data)); flash('Mission créée. Les agents la voient dans epaVie Pro.'); location.hash = '#/missions/' + nid; }
    sauver();
  });
}
window.BO = { reinit() { if (!confirm('Réinitialiser la démo ? Vos décisions, missions et comptes créés seront effacés.')) return; const l = S.logged; S = neuf(); S.logged = l; sauver(); route(); } };
addEventListener('hashchange', route);
addEventListener('load', () => { const p = document.getElementById('preloader'); if (p) p.style.display = 'none'; });
route();
})();
