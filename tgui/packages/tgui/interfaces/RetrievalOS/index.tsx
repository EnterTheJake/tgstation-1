import { useEffect, useRef, useState } from 'react';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import '../../styles/interfaces/ContractorUplink.scss';
import '../../styles/interfaces/RetrievalOS.scss';
import { FieldManual } from './FieldManual';
import { datamosh, GARB, type Glitch, GlitchContext, hashOf } from './glitch';
import { clock, useFlag } from './helpers';
import { OccupantView } from './OccupantView';
import { TargetBoard } from './TargetBoard';
import type { Data } from './types';

const TABS = ['Field Manual', 'Occupant', 'Targets'];

export const RetrievalOS = () => {
  const { data } = useBackend<Data>();
  const { occupant, integrity, damage_pulses, last_hit } = data;
  const [tab, setTab] = useState(1);
  const [phase, setPhase] = useState(3);
  const [salt, setSalt] = useState(0);
  const [jitter, fireJitter] = useFlag(240);
  const seenPulses = useRef(damage_pulses);
  const mosh = useRef<HTMLDivElement>(null);
  const content = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (damage_pulses <= seenPulses.current) {
      seenPulses.current = damage_pulses;
      return;
    }
    seenPulses.current = damage_pulses;
    const severity = Math.min(1, last_hit + (1 - integrity) * 0.35);
    if (mosh.current && content.current) {
      datamosh(mosh.current, content.current, severity);
    }
    if (severity > 0.25) {
      fireJitter();
    }
    const duration = 1400 + severity * 1600;
    setSalt(Math.random());
    setPhase(0);
    const timers = [
      setTimeout(() => setPhase(1), duration * 0.45),
      setTimeout(() => setPhase(2), duration * 0.76),
      setTimeout(() => setPhase(3), duration),
    ];
    return () => timers.forEach(clearTimeout);
  }, [damage_pulses]);

  useEffect(() => {
    if (integrity > 0.5) {
      return;
    }
    const id = setInterval(() => {
      if (Math.random() > 0.35 || !mosh.current || !content.current) {
        return;
      }
      datamosh(mosh.current, content.current, 0.15 + (1 - integrity) * 0.3);
    }, 2200);
    return () => clearInterval(id);
  }, [integrity > 0.5]);

  const glitch: Glitch = {
    g: (text, key, letters) => {
      const shown = String(text);
      if (phase >= 3 || hashOf(key, salt) % 3 < phase) {
        return shown;
      }
      return shown.replace(letters ? /[0-9A-Za-z]/g : /[0-9]/g, (match) =>
        !letters || Math.random() < 0.45
          ? GARB[Math.floor(Math.random() * GARB.length)]
          : match,
      );
    },
    tear: (key) =>
      phase < 2 ? ((hashOf(key, salt) % 1000) / 1000 - 0.5) * 46 : 0,
    torn: phase < 2,
  };

  const level =
    integrity > 0.75 ? 0 : integrity > 0.5 ? 1 : integrity > 0.25 ? 2 : 3;

  return (
    <Window
      width={700}
      height={900}
      theme="contractor"
      title={`RetrievalOS — ${TABS[tab]}`}
      buttons={
        <span className="RetrievalOS-unit">
          {occupant
            ? `Chamber sealed · ${glitch.g(clock(occupant.sealed), 'clock')}`
            : 'Chamber empty'}
        </span>
      }
    >
      <Window.Content fitted scrollable>
        <GlitchContext.Provider value={glitch}>
          <div className="RetrievalOS">
            <div className="moshfx" ref={mosh} />
            <div className="tabs">
              {TABS.map((name, index) => (
                <div
                  key={name}
                  className={`tab ${index === tab ? 'tab--selected' : ''}`}
                  onClick={() => setTab(index)}
                >
                  {name}
                </div>
              ))}
            </div>
            <div className="content" ref={content} data-lvl={level}>
              <div className="tabview viewswap" key={tab}>
                {tab === 0 && <FieldManual />}
                {tab === 1 && <OccupantView jitter={jitter} />}
                {tab === 2 && <TargetBoard />}
              </div>
            </div>
          </div>
        </GlitchContext.Provider>
      </Window.Content>
    </Window>
  );
};
