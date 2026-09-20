import type { BooleanLike } from 'tgui-core/react';

export type Organ = {
  slot: string;
  name: string;
  damage: number;
  max: number;
  failing: BooleanLike;
};

export type Blocker = {
  reason: string;
  thread: string;
  target: string;
};

export type Occupant = {
  dead: BooleanLike;
  breathing: BooleanLike;
  health: number;
  max_health: number;
  sealed: number;
  damage: Record<string, number>;
  revive_limit: number;
  body: Record<string, number>;
  blood_max: number;
  temperature_target: number;
  focus: Record<string, string | null>;
  rates: Record<string, number>;
  thread_power: string;
  charge_cost: string;
  charge_time: number;
  charge_elapsed: number | null;
  charged: BooleanLike;
  organs: Organ[];
  blockers: Blocker[];
  fatal?: string;
  revivable?: BooleanLike;
  stat_text?: string;
  pulse?: number;
  blood_oxygen?: number;
  blood_pressure?: string;
  rhythm?: string;
};

export type Identity = {
  name: string;
  rank: string;
  department?: string;
  department_color?: string;
  implant: BooleanLike;
  mugshot?: string;
};

export type Contract = {
  payout: number;
  bonus: number;
};

export type LastOccupant = {
  name: string;
  rank: string;
  alive: BooleanLike;
  ago: number;
};

export type Target = {
  name: string;
  is_head?: BooleanLike;
  target_rank?: string;
  tc_reward?: number;
  payout_bonus?: number;
  dropoff_location_unsafe?: string;
  dropoff_location_dangerous?: string;
  mugshot_icon?: string;
  contract_id: number;
};

export type Data = {
  integrity: number;
  damage_pulses: number;
  last_hit: number;
  cell_percent: number;
  target_locations: Record<string, string>;
  tracked_contract_id?: number;
  designated_contract_id?: number | null;
  extracting?: BooleanLike;
  last_occupant?: LastOccupant | null;
  occupant?: Occupant | null;
  targets: Target[];
  identity?: Identity | null;
  contract?: Contract | null;
  is_handler?: BooleanLike;
};
