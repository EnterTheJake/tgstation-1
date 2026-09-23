import { useContext } from 'react';
import { useBackend } from '../../backend';
import { ExtractionRow } from './ExtractionRow';
import { GlitchContext } from './glitch';
import type { Data } from './types';

export const TargetBoard = () => {
  const { data } = useBackend<Data>();
  const { g } = useContext(GlitchContext);
  const { targets = [], target_locations = {}, designated_contract_id } = data;

  return (
    <div className="manual">
      <div
        className="notice notice--note"
        style={{ marginTop: 0, marginBottom: 10 }}
      >
        <b>BOUNTY BOARD</b>
        Your <em>handler's</em> bounty board. Your <em>handler</em> designates
        the target. You can call an extraction pod for the designated target at
        its dropoff.
        {!designated_contract_id && targets.length > 0 && (
          <div className="board__hint">
            No target designated. Your <em>handler</em> designates one by
            tracking it on their uplink.
          </div>
        )}
      </div>
      {targets.length === 0 && (
        <div className="board__none">Your handler has no active bounties.</div>
      )}
      {targets.map((target) => {
        const designated = target.contract_id === designated_contract_id;
        return (
          <div
            key={target.contract_id}
            className={`board ${designated ? 'board--tracked' : ''}`}
          >
            <div className="board__row">
              <div className="board__mug">
                {target.mugshot_icon ? (
                  <img src={`data:image/png;base64,${target.mugshot_icon}`} />
                ) : (
                  '◖'
                )}
              </div>
              <div className="board__mid">
                <div className="board__name">
                  {g(target.name, `target-${target.contract_id}`, true)}
                  {!!target.is_head && (
                    <span className="board__tag board__tag--head">HEAD</span>
                  )}
                  {designated && (
                    <span className="board__tag board__tag--lock">
                      DESIGNATED
                    </span>
                  )}
                </div>
                <div className="board__rank">{target.target_rank}</div>
                <div className="board__loc">
                  <span>LAST SEEN</span>
                  {g(
                    target_locations[target.contract_id] || 'Unknown',
                    `loc-${target.contract_id}`,
                    true,
                  )}
                </div>
                <div className="board__drop">
                  <span>DROPOFF</span>
                  {target.dropoff_location_unsafe || 'Unknown'}
                  {target.dropoff_location_dangerous &&
                    ` · ${target.dropoff_location_dangerous}`}
                </div>
              </div>
              <div className="board__pay">
                <div className="board__tc">
                  {g(`${target.tc_reward} CC`, `tc-${target.contract_id}`)}
                </div>
                <div className="board__bonus">
                  {g(
                    `+${target.payout_bonus} ALIVE`,
                    `bonus-${target.contract_id}`,
                  )}
                </div>
              </div>
            </div>
            {designated && <ExtractionRow />}
          </div>
        );
      })}
    </div>
  );
};
