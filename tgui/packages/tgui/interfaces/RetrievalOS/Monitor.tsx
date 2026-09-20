import { useContext, useEffect, useMemo, useRef, useState } from 'react';
import { useBackend } from '../../backend';
import {
  beatTrace,
  ECG_BASE,
  flatTrace,
  H,
  noiseTrace,
  PLETH_BASE,
  plethWave,
  pqrst,
  W,
} from './ecg';
import { GlitchContext } from './glitch';
import type { Data } from './types';

type MonitorProps = {
  jitter: boolean;
  flash: boolean;
};

export const Monitor = (props: MonitorProps) => {
  const { jitter, flash } = props;
  const { data } = useBackend<Data>();
  const { g } = useContext(GlitchContext);
  const { occupant } = data;
  const pulse = occupant?.pulse ?? 0;
  const beating = !!occupant && pulse > 0;
  const mode = !occupant ? 'empty' : beating ? 'alive' : 'flat';
  const [rate, setRate] = useState(Math.max(30, pulse));
  const pending = useRef(rate);
  if (beating && Math.abs(pulse - pending.current) >= 8) {
    pending.current = Math.max(30, pulse);
  }
  useEffect(() => {
    setRate(pending.current);
  }, [mode]);

  const traces = useMemo(() => {
    if (jitter) {
      return [noiseTrace(ECG_BASE, 30), noiseTrace(PLETH_BASE, 14)];
    }
    if (mode === 'alive') {
      return [
        beatTrace(pqrst, ECG_BASE, 38, 4),
        beatTrace(plethWave, PLETH_BASE, 14, 4),
      ];
    }
    const amp = mode === 'empty' ? 0 : 1;
    return [flatTrace(ECG_BASE, amp * 1.2), flatTrace(PLETH_BASE, amp * 0.7)];
  }, [mode, jitter]);

  const gridClass = `mon__grid ${mode === 'alive' ? 'is-alive' : ''} ${mode === 'empty' ? 'is-empty' : ''}`;

  return (
    <div className="panel panel--pin mon">
      <div className={gridClass}>
        <span className="mon__tag">
          {occupant ? 'LEAD II · 25 mm/s · ×1.0' : 'LEADS OFF · NO SUBJECT'}
        </span>
        <span className="mon__tag2">PLETH · SpO₂</span>
        <svg
          key={rate}
          className="mon__svg"
          onAnimationIteration={() => {
            if (pending.current !== rate) {
              setRate(pending.current);
            }
          }}
          viewBox={`0 0 ${W * 2} ${H}`}
          preserveAspectRatio="none"
          style={
            mode === 'alive'
              ? { animationDuration: `${240 / rate}s` }
              : undefined
          }
        >
          <polyline className="mon__ecg" points={traces[0]} />
          <polyline className="mon__pleth" points={traces[1]} />
        </svg>
        <span className="mon__rhythm">
          {occupant ? occupant.rhythm || 'ASYSTOLE' : 'NO SIGNAL'}
        </span>
        <div className="mon__hud">
          <div className="mon__bpmrow">
            <span
              key={rate}
              className="mon__heart"
              style={
                beating ? { animationDuration: `${60 / rate}s` } : undefined
              }
            >
              ❤
            </span>
            <span className="mon__bpm">
              {occupant ? g(pulse, 'bpm') : '--'}
            </span>
          </div>
          <span className="mon__unit">BPM</span>
          <span className="mon__spo2">
            {occupant
              ? beating
                ? g(occupant.blood_oxygen ?? 0, 'spo2')
                : '——'
              : '--'}{' '}
            <span>SpO₂</span>
          </span>
        </div>
        <span className={`mon__flash ${flash ? 'is-firing' : ''}`} />
      </div>
    </div>
  );
};
