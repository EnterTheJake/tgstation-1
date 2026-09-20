import { useContext } from 'react';
import { useBackend } from '../../backend';
import { GlitchContext } from './glitch';
import { clock } from './helpers';
import type { Data } from './types';

export const EmptyChamber = () => {
  const { data } = useBackend<Data>();
  const { g } = useContext(GlitchContext);
  const { last_occupant, cell_percent, integrity } = data;

  return (
    <div className="panel">
      <div className="empty">
        <div className="empty__art">
          <svg width="206" height="116" viewBox="0 0 206 116">
            <path
              d="M18 20 H52 M154 20 H188 M18 20 V96 M188 20 V96 M18 96 H52 M154 96 H188"
              fill="none"
              stroke="rgba(212,132,20,.65)"
              strokeWidth="2.5"
              strokeLinecap="round"
            />
            <g fill="none" stroke="rgba(212,132,20,.45)" strokeWidth="2">
              <path d="M34 34 H62 M34 82 H62 M172 34 H144 M172 82 H144" />
              <circle cx="66" cy="34" r="3.5" />
              <circle cx="66" cy="82" r="3.5" />
              <circle cx="140" cy="34" r="3.5" />
              <circle cx="140" cy="82" r="3.5" />
            </g>
            <g
              className="empty__body"
              fill="none"
              stroke="var(--color-title)"
              strokeWidth="1.6"
              strokeDasharray="4 5"
            >
              <circle cx="103" cy="34" r="11" />
              <rect x="88" y="49" width="30" height="34" rx="7" />
              <rect x="72" y="51" width="12" height="30" rx="6" />
              <rect x="122" y="51" width="12" height="30" rx="6" />
            </g>
            <rect
              className="empty__scan"
              x="20"
              y="6"
              width="166"
              height="2"
              fill="var(--color-title)"
              opacity=".55"
            />
          </svg>
        </div>
        <div className="empty__head">CHAMBER EMPTY</div>
        <div className="empty__sub">
          The Holding Chamber is empty. Life support and the revival matrix are
          on standby.
        </div>
        <div className="empty__chips">
          <span className="chip">
            LIFE SUPPORT <b>STANDBY</b>
          </span>
          <span className="chip">
            MATRIX <b>STANDBY</b>
          </span>
          <span className="chip">
            CELL <b>{g(`${cell_percent}%`, 'cell')}</b>
          </span>
          <span className="chip">
            INTEGRITY <b>{g(`${Math.round(integrity * 100)}%`, 'integrity')}</b>
          </span>
        </div>
        <div className="empty__how">
          <div className="empty__howl">TO SEAL A TARGET</div>
          <div className="empty__step">
            <span className="empty__no">1</span>
            <span>Click and drag a person onto yourself.</span>
          </div>
          <div className="empty__step">
            <span className="empty__no">2</span>
            <span>
              <em>Incapacitated, helpless, restrained or authorized</em> people
              are placed inside instantly.
            </span>
          </div>
          <div className="empty__step">
            <span className="empty__no">3</span>
            <span>Otherwise, a brief interaction timer is required.</span>
          </div>
        </div>
        {last_occupant && (
          <div
            className={`empty__last ${last_occupant.alive ? '' : 'empty__last--dead'}`}
          >
            <span className="empty__lastl">LAST SUBJECT</span>
            <span className="empty__lastn">
              {last_occupant.name} · {last_occupant.rank}
            </span>
            <span className="empty__ok">
              RELEASED {last_occupant.alive ? 'ALIVE' : 'DEAD'} ·{' '}
              {g(clock(last_occupant.ago), 'ago')} AGO
            </span>
          </div>
        )}
      </div>
    </div>
  );
};
