// =============================================================================
//  modes.js — Traduit une "intention" de menu en configuration de partie
//  prête pour World.init() : thème d'arène, équipes, objectif, nb de viewports.
// =============================================================================

import { WORLDS, buildCampaign } from '../data/campaign.js';

const CAMPAIGN = buildCampaign();

export function buildMatch(intent) {
  if (intent.type === 'campaign') return buildCampaignMatch(intent.missionIndex);
  if (intent.type === 'skirmish') return buildSkirmish(intent);
  if (intent.type === 'versus') return buildVersus(intent);
  throw new Error('Intention inconnue : ' + intent.type);
}

function buildCampaignMatch(missionIndex) {
  const mission = CAMPAIGN[missionIndex];
  const worldTheme = WORLDS[mission.world];
  let objective = { ...mission.objective };
  let enemyRespawn = !(objective.type === 'eliminate' || objective.type === 'boss');

  // Les missions "boss" deviennent un affrontement final (équipe pleine).
  if (mission.boss) { objective = { type: 'eliminate', label: '👑 BOSS — Anéantissez la garde divine !' }; enemyRespawn = false; }

  const enemyColor = (mission.world % 3) + 1;
  const teamConfigs = [
    { colorIndex: 0, controller: 'human', viewport: 0, initialBuddies: 1, canRespawn: true },
    {
      colorIndex: enemyColor, controller: 'ai',
      aiLevel: mission.boss ? 1.0 : mission.aiLevel,
      initialBuddies: mission.boss ? 4 : mission.enemyBuddies,
      canRespawn: enemyRespawn,
    },
  ];
  return { worldTheme, teamConfigs, objective, playerCount: 1, mode: 'campaign', context: { type: 'campaign', missionIndex } };
}

function buildSkirmish({ bots, difficulty, worldId }) {
  const worldTheme = WORLDS[worldId || 0];
  const teamConfigs = [{ colorIndex: 0, controller: 'human', viewport: 0, initialBuddies: 1, canRespawn: true }];
  const nb = Math.min(3, Math.max(1, bots));
  for (let i = 0; i < nb; i++)
    teamConfigs.push({ colorIndex: i + 1, controller: 'ai', aiLevel: difficulty, initialBuddies: 1, canRespawn: false });
  // Sur petite arène, 2 équipes max sont alignées ; au-delà on passe en coins.
  const objective = { type: 'eliminate', label: 'Éliminez tous les rivaux' };
  return { worldTheme, teamConfigs, objective, playerCount: 1, mode: 'skirmish', context: { type: 'skirmish' } };
}

function buildVersus({ players, modeId, fill, worldId }) {
  const worldTheme = WORLDS[worldId || 0];
  const P = Math.min(4, Math.max(2, players));
  const F = Math.min(Math.max(0, fill || 0), 4 - P);
  const teamConfigs = [];
  for (let i = 0; i < P; i++)
    teamConfigs.push({ colorIndex: i, controller: 'human', viewport: i, initialBuddies: 1, canRespawn: true });
  for (let j = 0; j < F; j++)
    teamConfigs.push({ colorIndex: P + j, controller: 'ai', aiLevel: 0.6, initialBuddies: 1, canRespawn: true });

  let objective;
  switch (modeId) {
    case 'domination': objective = { type: 'domination', T: 45, label: 'Domination — tenez le sanctuaire 45s' }; break;
    case 'football': objective = { type: 'domination', T: 45, label: 'Buddy Football — contrôlez le centre 45s' }; break;
    case 'destroy_base': objective = { type: 'destroy_base', label: 'Base Assault — dernier temple debout' }; break;
    default: objective = { type: 'deathmatch', score: 15, label: 'Deathmatch — 15 éliminations' };
  }
  return { worldTheme, teamConfigs, objective, playerCount: P, mode: 'versus', context: { type: 'versus' } };
}
