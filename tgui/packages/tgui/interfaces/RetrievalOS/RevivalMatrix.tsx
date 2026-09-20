import { type ReactNode, useContext, useRef } from 'react';
import { useBackend } from '../../backend';
import { GlitchContext } from './glitch';
import { useTicker } from './helpers';
import { OsButton } from './OsButton';
import type { Data, Occupant } from './types';

type ArrayProps = {
  occupant: Occupant;
};

const THREAD_LABELS: Record<string, string> = {
  damage: 'DAMAGE',
  organ: 'ORGANS',
};

export const RevivalMatrix = (props: ArrayProps) => {
  const { occupant } = props;
  const { act } = useBackend<Data>();
  const { g } = useContext(GlitchContext);
  const dead = !!occupant.dead;
  const charging = occupant.charge_elapsed !== null;
  const charged = !!occupant.charged;
  const received = useRef({ elapsed: -1, at: 0 });
  useTicker(charging, 100);

  if (charging && received.current.elapsed !== occupant.charge_elapsed) {
    received.current = {
      elapsed: occupant.charge_elapsed as number,
      at: Date.now(),
    };
  }
  const progress = charged
    ? 1
    : charging
      ? Math.min(
          1,
          ((occupant.charge_elapsed as number) * 100 +
            (Date.now() - received.current.at)) /
            (occupant.charge_time * 100),
        )
      : 0;
  const lit = charged ? 10 : Math.floor(progress * 10);

  let gate: ReactNode;
  let gateClass = 'gate--ready';
  let status = 'Ready';
  let statusClass = '';
  let canCharge = false;
  if (!dead) {
    gate = (
      <>
        <b>Heart rhythm restored.</b> Bring your target to your handler's chosen
        dropoff.
      </>
    );
    status = 'Discharged';
    statusClass = 'dfb__st--good';
  } else if (occupant.fatal) {
    gateClass = 'gate--block';
    gate = (
      <>
        <b>The revival matrix cannot restart the heart.</b>
        <span className="gate__item">{occupant.fatal}</span>
      </>
    );
    status = 'Unrecoverable';
  } else if (occupant.blockers.length) {
    gateClass = 'gate--block';
    gate = (
      <>
        <b>The revival matrix cannot restart the heart.</b>
        {occupant.blockers.map((blocker) => {
          const working = occupant.focus[blocker.thread] === blocker.target;
          const isTissue = blocker.thread === 'damage';
          const amount = occupant.damage[blocker.target] || 0;
          const rate = occupant.rates.damage;
          return (
            <span
              className="gate__item"
              key={`${blocker.thread}-${blocker.target}`}
            >
              {blocker.reason} —{' '}
              {isTissue
                ? `${blocker.target} ${Math.round(amount)}, over the ${occupant.revive_limit} limit`
                : 'organ at its limit'}{' '}
              ·{' '}
              {working ? (
                <>
                  being repaired
                  {isTissue && (
                    <>
                      , clears in{' '}
                      <b>
                        {Math.max(
                          1,
                          Math.ceil((amount - occupant.revive_limit) / rate),
                        )}{' '}
                        s
                      </b>
                    </>
                  )}
                </>
              ) : (
                <>
                  assign the <b>{THREAD_LABELS[blocker.thread]}</b> thread
                </>
              )}
            </span>
          );
        })}
      </>
    );
    status = `${occupant.blockers.length} obstruction${occupant.blockers.length === 1 ? '' : 's'}`;
  } else {
    gate = (
      <>
        No obstructions. <b>The revival matrix is ready</b> to charge.
      </>
    );
    canCharge = !charging && !charged;
    if (charging) {
      status = 'Charging';
      statusClass = 'dfb__st--hot';
    } else if (charged) {
      status = 'Charged — 360 J';
      statusClass = 'dfb__st--hot';
    }
  }

  return (
    <>
      <div className="dfb__head">
        <span className="dfb__t">Revival Matrix</span>
        <span className={`pill ${dead ? 'pill--dead' : 'pill--good'}`}>
          ● {dead ? 'Subject deceased' : 'Rhythm restored'}
        </span>
        <span className={`dfb__st ${statusClass}`}>{status}</span>
      </div>
      <div className="dfb__row">
        <div className="bank">
          <div className="bank__cells">
            {Array.from({ length: 10 }, (_, index) => (
              <span
                key={index}
                className={`cell ${index < lit ? 'is-lit' : ''}`}
              />
            ))}
          </div>
          <div className="bank__scale">
            <span>0 J</span>
            <span>CAPACITOR STACK</span>
            <span>360 J</span>
          </div>
        </div>
        <div className="joule">
          <span className="joule__v">
            {g(Math.round(progress * 360), 'joules')}
          </span>
          <span className="joule__u">JOULES</span>
        </div>
        <div className="dfb__btns">
          <OsButton disabled={!canCharge} onClick={() => act('charge')}>
            Charge<span className="cost">⚡{occupant.charge_cost}</span>
          </OsButton>
          <OsButton
            className={`btn--fire ${charged && dead ? 'is-armed' : ''}`}
            disabled={!charged || !dead}
            onClick={() => act('discharge')}
          >
            Discharge
          </OsButton>
        </div>
      </div>
      <div className={`gate ${gateClass}`}>{gate}</div>
    </>
  );
};
