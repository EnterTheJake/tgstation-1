import { useContext } from 'react';
import { ExtractionRow } from './ExtractionRow';
import { GlitchContext } from './glitch';
import type { Contract, Identity, Occupant } from './types';

const statPill = (occupant: Occupant) => {
  if (occupant.dead) {
    return 'pill--dead';
  }
  switch (occupant.stat_text) {
    case 'CONSCIOUS':
      return 'pill--good';
    case 'ASLEEP':
    case 'UNCONSCIOUS':
      return 'pill--warn';
    default:
      return 'pill--bad';
  }
};

type DossierProps = {
  occupant: Occupant;
  identity?: Identity | null;
  contract?: Contract | null;
  handler: boolean;
};

export const Dossier = (props: DossierProps) => {
  const { occupant, identity, contract, handler } = props;
  const { g } = useContext(GlitchContext);
  const dead = !!occupant.dead;
  const hp = occupant.health;
  const hpColor =
    hp > 50
      ? 'var(--color-good)'
      : hp > 0
        ? 'var(--color-warn)'
        : 'var(--color-dead)';
  const position = dead
    ? 11
    : hp < 0
      ? 22 + ((Math.max(hp, -100) + 100) / 100) * 22
      : 44 + Math.min(hp / occupant.max_health, 1) * 56;
  const band =
    position < 22
      ? 'dead'
      : position < 44
        ? 'crit'
        : position < 70
          ? 'hurt'
          : 'ok';
  const department = identity?.department
    ? `${identity.department} · ${identity.rank}`
    : identity?.rank || 'Unknown';

  return (
    <div className="panel">
      <div className="dossier">
        <div className="shot">
          <span className="shot__br shot__br--tl" />
          <span className="shot__br shot__br--tr" />
          <span className="shot__br shot__br--bl" />
          <span className="shot__br shot__br--br" />
          {identity?.mugshot ? (
            <img src={`data:image/png;base64,${identity.mugshot}`} />
          ) : (
            '◖'
          )}
        </div>
        <div className="dossier__mid">
          <div className="nm">{identity?.name || 'Unknown subject'}</div>
          <div className="dossier__chips">
            <span
              className="dept"
              style={{ color: identity?.department_color || '#a89383' }}
            >
              {department}
            </span>
            <span className={`pill ${statPill(occupant)}`}>
              ● {dead ? 'No pulse' : occupant.stat_text || 'Pulse'}
            </span>
          </div>
          <div className="lad">
            {['dead', 'crit', 'hurt', 'ok'].map((zone) => (
              <span
                key={zone}
                className={`lad__z lad__z--${zone} ${zone === band ? 'is-current' : ''}`}
              >
                {zone.toUpperCase()}
              </span>
            ))}
            <span
              className="lad__m"
              style={{ left: `calc(${position.toFixed(1)}% - 1.5px)` }}
            />
          </div>
        </div>
        <div className="dossier__hp">
          <div className="dossier__hpn" style={{ color: hpColor }}>
            {g(hp, 'hp')}
          </div>
          <div className="dossier__hpl">HEALTH</div>
          <div
            className={`dossier__imp ${identity?.implant ? 'dossier__imp--yes' : ''}`}
          >
            {identity?.implant ? 'AUTHORIZED' : 'UNAUTHORIZED'}
            <br />
            {identity?.implant ? 'STEALTH OK' : 'STEALTH BLOCKED'}
          </div>
        </div>
      </div>
      {contract ? (
        <>
          <div className="tgt tgt--yes">
            <span className="tgt__l">CONTRACT</span>
            <span className="tgt__b">
              Designated target of your <b>handler</b>. Deliver <b>alive</b> for
              +{contract.bonus} TC.
            </span>
            <span className="tgt__tc">{g(contract.payout, 'payout')} TC</span>
          </div>
          <ExtractionRow />
        </>
      ) : handler ? (
        <div className="tgt tgt--handler">
          <span className="tgt__l">HANDLER</span>
          <span className="tgt__b">
            Your <b>handler</b> is in the Holding Chamber. Ensure that your{' '}
            <b>handler</b> is <b>safe</b>.
          </span>
          <span className="tgt__tc">◆</span>
        </div>
      ) : (
        <div className="tgt tgt--no">
          <span className="tgt__l">NO CONTRACT</span>
          <span className="tgt__b">
            Not designated by your <b>handler</b>. No value to the company.
          </span>
          <span className="tgt__tc">—</span>
        </div>
      )}
    </div>
  );
};
