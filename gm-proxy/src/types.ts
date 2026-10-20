/*
 * PURPOSE: JSON-Vertrags-Typen des GM-Proxy (Requests, Responses, Trigger-Event-Enum)
 * ARCHITECTURE: gm-proxy/contracts
 * DEPENDENCIES: none
 * PIPELINE: runtime, test
 * LAST_VALIDATED: 2026-09-17
 */

/** Geschlossenes Enum aller vom Client ausführbaren Welt-Events. */
import type { Lehre, LehreGenerateRequest } from './lehre.js';

export type TriggerEvent =
  | { type: 'add_item'; item: string }
  | { type: 'remove_item'; item: string }
  | { type: 'change_scene'; scene: string }
  | { type: 'modify_stat'; stat: 'alignment' | 'discipline'; delta: number }
  | { type: 'start_minigame'; game?: MinigameGame; params?: { lehre: LehreId } };

/** Minispiele des Vertrags; fehlt game, gilt beleidigungsfechten. */
export type MinigameGame = 'beleidigungsfechten' | 'widerlegung' | 'dame';
/** Lehren der Widerlegung (content/widerlegung/_common.json, order). */
/** 'bibliothek' = eine geprüfte, vom Spielleiter erfundene Lehre aus der Bibliothek des Clients. */
export type LehreId = 'akademie' | 'amt' | 'erfurt' | 'division7b' | 'spiel' | 'bibliothek';

export interface GmActionRequest {
  player_inventory: string[];
  current_scene: string;
  alignment_score: number;
  fraktionsdisziplin?: number;
  player_input: string;
  /** Optionaler Schlüssel für das GM-Gedächtnis (Chronik pro Spielstand). */
  session_id?: string;
}

export interface RollBonus {
  source: string;
  value: number;
}

export interface Roll {
  dice: string;
  value: number;
  bonuses: RollBonus[];
  total: number;
  difficulty_class: number;
  success: boolean;
}

export interface GmResultRequest extends GmActionRequest {
  roll: Roll;
}

/** Antwort auf /gm/action und /gm/result — exakt dieses Feld-Set liefert der Client. */
export interface GmResponse {
  gm_dialogue: string;
  required_roll: string;
  difficulty_class: number;
  trigger_event: TriggerEvent | null;
}

export interface MinigameRoundRequest {
  current_scene: string;
  alignment_score: number;
  round: number;
  won_rounds: number;
  lost_rounds: number;
}

export interface MinigameRoundResponse {
  accusation: string;
  phrases: string[];
}

export interface MinigameJudgeRequest {
  accusation: string;
  chosen_index: number;
  phrase: string;
}

export interface MinigameJudgeResponse {
  correct: boolean;
  correct_index: number;
  commentary: string;
}

/** Seams des Servers: Endpoints, produktionsreell per LLM, in Tests gemockt. */
export interface GmHandlers {
  action: (req: GmActionRequest) => Promise<GmResponse>;
  result: (req: GmResultRequest) => Promise<GmResponse>;
  minigameRound: (req: MinigameRoundRequest) => Promise<MinigameRoundResponse>;
  minigameJudge: (req: MinigameJudgeRequest) => Promise<MinigameJudgeResponse>;
  epitaph: (req: EpitaphRequest) => Promise<EpitaphResponse>;
  /** Phase 2: erfindet eine Lehre. Optional, damit alte Mocks gültig bleiben. */
  lehreGenerate?: (req: LehreGenerateRequest) => Promise<Lehre>;
}

/** Aggregate, die der Client zur Karriere-Akte (Perma-Death/Run-Ende) sendet. */
export interface RunStats {
  rolls: unknown[];
  items_burned: string[];
  minigame: Record<string, unknown>;
  alignment_timeline: number[];
  started_at: string;
  /** Ergebnisse von Minispielen nach dem Vertrag (Widerlegung), optional. */
  minigames?: unknown[];
}

/** Request an POST /run/epitaph — satirische Karriere-Zusammenfassung. */
export interface EpitaphRequest {
  session_id?: string;
  stats: RunStats;
}

/** Response von POST /run/epitaph. */
export interface EpitaphResponse {
  epitaph: string;
  highlights: string[];
}
