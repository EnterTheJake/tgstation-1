import { type ReactNode, useEffect, useRef, useState } from 'react';
import { useBackend } from '../../backend';
import { Dossier } from './Dossier';
import { EmptyChamber } from './EmptyChamber';
import { useFlag } from './helpers';
import { Monitor } from './Monitor';
import { RepairList } from './RepairList';
import { RevivalMatrix } from './RevivalMatrix';
import type { Data } from './types';

const SwapView = (props: { animate: boolean; children: ReactNode }) => {
  const [className] = useState(props.animate ? 'viewswap' : '');
  return <div className={className}>{props.children}</div>;
};

type OccupantViewProps = {
  jitter: boolean;
};

export const OccupantView = (props: OccupantViewProps) => {
  const { jitter } = props;
  const { data } = useBackend<Data>();
  const { occupant, identity, contract, is_handler } = data;
  const dead = !!occupant?.dead;
  const [flash, fireFlash] = useFlag(560);
  const [lingering, fireLinger] = useFlag(1800);
  const [armed, fireArmed] = useFlag(1000);
  const wasDead = useRef<boolean | null>(null);
  const hadOccupant = useRef(!!occupant);
  const swapped = hadOccupant.current !== !!occupant;
  hadOccupant.current = !!occupant;

  useEffect(() => {
    const previous = wasDead.current;
    wasDead.current = occupant ? dead : null;
    if (previous === true && occupant && !dead) {
      fireFlash();
      fireLinger();
    }
    if (occupant && dead && previous !== true) {
      fireArmed();
    }
  }, [!!occupant, dead]);

  const showArray = !!occupant && (dead || lingering);

  return (
    <>
      <Monitor jitter={jitter} flash={flash} />
      <div className="scrollzone">
        {occupant ? (
          <SwapView animate={swapped} key="occupied">
            <Dossier
              occupant={occupant}
              identity={identity}
              contract={contract}
              handler={!!is_handler}
            />
            <RepairList occupant={occupant} />
          </SwapView>
        ) : (
          <SwapView animate={swapped} key="empty">
            <EmptyChamber />
          </SwapView>
        )}
      </div>
      <div
        className={`panel panel--pin panel--array ${showArray ? '' : 'is-gone'} ${armed ? 'just-armed' : ''}`}
      >
        {occupant && <RevivalMatrix occupant={occupant} />}
      </div>
    </>
  );
};
