import { useContext, useEffect, useRef, useState } from 'react';
import { useBackend } from '../../backend';
import { GlitchContext } from './glitch';
import { titleCase } from './helpers';
import type { Data, Occupant, Organ } from './types';

type RowSpec = {
  key: string;
  kind: 'dmg' | 'body' | 'organ';
  name: string;
  thread: string;
  target: string;
  value: number;
  shown: string;
  pct: number;
  done: boolean;
  down: boolean;
  rate: number;
  remain: number;
  idleText?: string;
  idleColor?: string;
  movingText?: string;
  grad: string;
  color: string;
  gate?: number;
  leaving?: boolean;
};

const DAMAGE_ROWS: [string, string, string, string][] = [
  ['oxygen', 'Oxygen', 'linear-gradient(90deg,#1d4f78,#4fb8ff)', '#4fb8ff'],
  ['brute', 'Brute', 'linear-gradient(90deg,#8c2f1e,#ff5c46)', '#ff5c46'],
  ['burn', 'Burn', 'linear-gradient(90deg,#8c5a10,#ffab2e)', '#ffab2e'],
  ['toxin', 'Toxin', 'linear-gradient(90deg,#2c6b2c,#63d463)', '#63d463'],
];

const DAMAGE_MAX = 200;
const ORGAN_EXIT_MS = 450;

type OrganEntry = {
  row: RowSpec;
  index: number;
  until: number;
};
const TEMPERATURE_SPAN = 40;

type RepairListProps = {
  occupant: Occupant;
};

export const RepairList = (props: RepairListProps) => {
  const { occupant } = props;
  const { act } = useBackend<Data>();
  const { g, tear, torn } = useContext(GlitchContext);
  const { focus, rates, damage, body } = occupant;
  const dead = !!occupant.dead;
  const peaks = useRef<Record<string, number>>({});
  const settled = useRef<Record<string, number>>({});
  const previousFocus = useRef<Record<string, string | null>>({ ...focus });
  const [, setFlashTick] = useState(0);
  const shownOrgans = useRef<Map<string, OrganEntry>>(new Map());
  const exitingOrgans = useRef<Map<string, OrganEntry>>(new Map());

  const peak = (key: string, value: number) => {
    peaks.current[key] = Math.max(peaks.current[key] || 1, value);
    return peaks.current[key];
  };

  const damageRows: RowSpec[] = DAMAGE_ROWS.map(([key, name, grad, color]) => {
    const value = damage[key] || 0;
    const focused = focus.damage === key;
    const oxygen = key === 'oxygen' && !dead;
    const breathing = oxygen && !!occupant.breathing;
    const choking = oxygen && !occupant.breathing;
    return {
      key,
      kind: 'dmg',
      name,
      thread: 'damage',
      target: key,
      value,
      shown: value.toFixed(0),
      pct: (value / DAMAGE_MAX) * 100,
      done: value <= 0.05,
      down: true,
      rate: focused
        ? rates.damage + (key === 'oxygen' ? rates.oxy_bonus : 0)
        : 0,
      remain: value,
      idleText: choking
        ? 'NOT BREATHING'
        : breathing && value > 0.05
          ? 'BREATHING'
          : undefined,
      idleColor: choking
        ? 'var(--color-bad)'
        : breathing && value > 0.05
          ? 'var(--color-good)'
          : undefined,
      grad,
      color,
      gate:
        key === 'brute' || key === 'burn' ? occupant.revive_limit : undefined,
    };
  });

  const temperature = body.temperature;
  const target = occupant.temperature_target;
  const hot = temperature > target;
  const blood = body.blood;
  const bodyRows: RowSpec[] = [
    {
      key: 'blood',
      kind: 'body',
      name: 'Blood',
      thread: 'body',
      target: 'blood',
      value: blood,
      shown: `${Math.round(blood)} u`,
      pct: (blood / occupant.blood_max) * 100,
      done: blood >= occupant.blood_max - 0.05,
      down: false,
      rate: focus.body === 'blood' ? rates.blood : 0,
      remain: occupant.blood_max - blood,
      grad: 'linear-gradient(90deg,#5e1414,#c23b3b)',
      color: '#e06a6a',
    },
    {
      key: 'temperature',
      kind: 'body',
      name: 'Body temp',
      thread: 'body',
      target: 'temperature',
      value: temperature,
      shown: `${(temperature - 273.15).toFixed(1)} °C`,
      pct: hot
        ? 100
        : ((temperature - (target - TEMPERATURE_SPAN)) / TEMPERATURE_SPAN) *
          100,
      done: Math.abs(target - temperature) < 0.5,
      down: hot,
      rate: focus.body === 'temperature' ? rates.temperature : 0,
      remain: Math.abs(target - temperature),
      grad: hot
        ? 'linear-gradient(90deg,#7a2a08,#ff8a3a)'
        : 'linear-gradient(90deg,#123b5e,#4fb8ff)',
      color: hot ? '#ff8a3a' : '#4fb8ff',
    },
    {
      key: 'bleeding',
      kind: 'body',
      name: 'Bleeding',
      thread: 'body',
      target: 'bleeding',
      value: body.bleeding,
      shown: body.bleeding.toFixed(1),
      pct: (body.bleeding / peak('bleeding', body.bleeding)) * 100,
      done: body.bleeding <= 0.05,
      down: true,
      rate: focus.body === 'bleeding' ? rates.bleeding : 0,
      remain: body.bleeding,
      movingText: '▼ CLOTTING',
      grad: 'linear-gradient(90deg,#5e0606,#ff3b2f)',
      color: '#ff5c46',
    },
    {
      key: 'wounds',
      kind: 'body',
      name: 'Wounds',
      thread: 'body',
      target: 'wounds',
      value: body.wounds,
      shown: String(body.wounds),
      pct: (body.wounds / peak('wounds', body.wounds)) * 100,
      done: body.wounds <= 0,
      down: true,
      rate: focus.body === 'wounds' ? rates.wounds : 0,
      remain: body.wounds,
      movingText: '▼ CLOSING',
      grad: 'linear-gradient(90deg,#5e0606,#ff3b2f)',
      color: '#ff5c46',
    },
  ];

  const now = Date.now();
  const leaving = (key: string, slot: string) =>
    previousFocus.current.organ === slot || (settled.current[key] || 0) > now;
  const ordered = [...occupant.organs].sort((a, b) => {
    const rank = (organ: Organ) =>
      organ.slot === 'heart' ? 0 : organ.slot === 'brain' ? 1 : 2;
    return rank(a) - rank(b);
  });
  const organRows: RowSpec[] = ordered
    .filter(
      (organ) =>
        organ.damage > 0.05 ||
        focus.organ === organ.slot ||
        leaving(`organ-${organ.slot}`, organ.slot),
    )
    .map((organ) => ({
      key: `organ-${organ.slot}`,
      kind: 'organ',
      name: titleCase(organ.name),
      thread: 'organ',
      target: organ.slot,
      value: organ.damage,
      shown: organ.damage.toFixed(1),
      pct: (organ.damage / organ.max) * 100,
      done: organ.damage <= 0.05,
      down: true,
      rate: focus.organ === organ.slot ? rates.organ : 0,
      remain: organ.damage,
      idleText: organ.failing ? 'FAILING' : undefined,
      idleColor: organ.failing ? 'var(--color-dead)' : undefined,
      grad:
        organ.slot === 'heart'
          ? 'linear-gradient(90deg,#7a1208,#ff5c46)'
          : 'linear-gradient(90deg,#7a5c22,#ffab2e)',
      color: organ.slot === 'heart' ? '#ff5c46' : '#ffab2e',
    }));
  const liveKeys = new Set(organRows.map((row) => row.key));
  for (const [key, entry] of shownOrgans.current) {
    if (!liveKeys.has(key) && !exitingOrgans.current.has(key)) {
      exitingOrgans.current.set(key, { ...entry, until: now + ORGAN_EXIT_MS });
    }
  }
  for (const [key, entry] of exitingOrgans.current) {
    if (liveKeys.has(key) || entry.until <= now) {
      exitingOrgans.current.delete(key);
    }
  }
  shownOrgans.current = new Map(
    organRows.map((row, index) => [row.key, { row, index, until: 0 }]),
  );
  const organList = [...organRows];
  [...exitingOrgans.current.values()]
    .sort((a, b) => a.index - b.index)
    .forEach((entry) => {
      organList.splice(Math.min(entry.index, organList.length), 0, {
        ...entry.row,
        leaving: true,
      });
    });
  const nextExit = Math.min(
    Infinity,
    ...[...exitingOrgans.current.values()].map((entry) => entry.until),
  );
  useEffect(() => {
    if (nextExit === Infinity) {
      return;
    }
    const id = setTimeout(
      () => setFlashTick((tick) => tick + 1),
      Math.max(0, nextExit - Date.now()) + 20,
    );
    return () => clearTimeout(id);
  }, [nextExit]);

  const clean = ordered.filter(
    (organ) =>
      organ.damage <= 0.05 &&
      !organRows.some((row) => row.target === organ.slot),
  );
  const doneKeys = new Set(
    [...damageRows, ...bodyRows, ...organRows]
      .filter((row) => row.done)
      .map((row) => row.key),
  );
  const brainClean = clean.some((organ) => organ.slot === 'brain');

  useEffect(() => {
    const timers: ReturnType<typeof setTimeout>[] = [];
    for (const thread of ['damage', 'body', 'organ']) {
      const key = previousFocus.current[thread];
      if (!key || focus[thread]) {
        continue;
      }
      const rowKey = thread === 'organ' ? `organ-${key}` : key;
      if (doneKeys.has(rowKey)) {
        settled.current[rowKey] = Date.now() + 1200;
        setFlashTick((tick) => tick + 1);
        timers.push(setTimeout(() => setFlashTick((tick) => tick + 1), 1250));
      }
    }
    previousFocus.current = { ...focus };
    return () => timers.forEach(clearTimeout);
  }, [focus.damage, focus.body, focus.organ]);

  const nameOf = (thread: string) => {
    const key = focus[thread];
    if (!key) {
      return null;
    }
    const all =
      thread === 'damage'
        ? damageRows
        : thread === 'body'
          ? bodyRows
          : organRows;
    return all.find((row) => row.target === key)?.name ?? titleCase(key);
  };
  const running = ['damage', 'body', 'organ']
    .map(nameOf)
    .filter((name): name is string => !!name);

  const renderRow = (row: RowSpec) => {
    const focused = focus[row.thread] === row.target;
    const moving = !row.done && row.rate > 0;
    const justDone = (settled.current[row.key] || 0) > now;
    let eta: string;
    let etaColor: string;
    if (row.done) {
      eta = 'CLEAR';
      etaColor = 'var(--color-good)';
    } else if (moving) {
      eta =
        row.movingText ??
        `${row.down ? '▼' : '▲'}${row.rate.toFixed(1)}/s  ${Math.ceil(row.remain / row.rate)}s`;
      etaColor = 'var(--color-good)';
    } else if (focused) {
      eta = 'NO POWER';
      etaColor = 'var(--color-bad)';
    } else {
      eta = row.idleText ?? 'IDLE';
      etaColor = row.idleColor ?? 'var(--color-rest)';
    }
    const width = Math.max(
      0,
      Math.min(100, row.pct + (torn ? tear(row.key) : 0)),
    );
    const classes = [
      'rep',
      `rep--${row.kind}`,
      !moving && 'is-idle',
      (!row.done || focused) && 'can-pick',
      focused && 'is-focus',
      justDone && 'just-done',
      row.leaving && 'is-leaving',
    ]
      .filter(Boolean)
      .join(' ');
    return (
      <div
        key={row.key}
        className={classes}
        onClick={() => {
          if (!row.done || focused) {
            act('set_focus', { thread: row.thread, target: row.target });
          }
        }}
      >
        <span className="rep__n">
          <span className="rep__dot">◉</span>
          {g(row.name, `${row.key}-n`)}
        </span>
        <span className="rep__t">
          <span
            className="rep__f"
            style={{ width: `${width.toFixed(2)}%`, background: row.grad }}
          >
            <span
              className={`rep__stripes ${moving ? `rep__stripes--${row.down ? 'down' : 'up'}` : ''}`}
            />
          </span>
          {row.gate !== undefined && (
            <span
              className="rep__gate"
              style={{ left: `${(row.gate / DAMAGE_MAX) * 100}%` }}
            />
          )}
        </span>
        <span
          className="rep__v"
          style={{ color: row.done ? 'var(--color-good)' : row.color }}
        >
          {g(row.shown, `${row.key}-v`)}
        </span>
        <span className="rep__e" style={{ color: etaColor }}>
          {g(eta, `${row.key}-e`)}
        </span>
      </div>
    );
  };

  const header = (label: string, thread: string, verb: string) => {
    const name = nameOf(thread);
    return (
      <div className="rep__hdr">
        {label}
        <b>{name ? `${verb} ${name}` : 'idle — click one'}</b>
      </div>
    );
  };

  return (
    <div className="panel">
      <div className="lbl">
        Life Support{' '}
        <em>
          {running.length
            ? `— ${running.length} of 3 threads running: ${running.join(' + ')}`
            : '— all three threads idle'}
        </em>
        {running.length > 0 && (
          <span className="pwr">⚡ {g(occupant.thread_power, 'power')}</span>
        )}
      </div>
      <div>
        {header('DAMAGE', 'damage', 'repairing')}
        {damageRows.map(renderRow)}
        {header('BODY', 'body', 'running')}
        {bodyRows.map(renderRow)}
        {header('ORGANS', 'organ', 'repairing')}
        {organList.map(renderRow)}
        {clean.length > 0 && (
          <div className="nominal">
            ✓ {clean.length} {organRows.length ? 'further ' : ''}organ
            {clean.length === 1 ? '' : 's'} nominal
            {brainClean && dead ? ' — brain intact, within revival window' : ''}
          </div>
        )}
      </div>
    </div>
  );
};
