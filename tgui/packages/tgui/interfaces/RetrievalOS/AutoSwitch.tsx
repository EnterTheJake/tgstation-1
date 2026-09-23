import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../../backend';
import type { Data } from './types';

type Props = {
  on: BooleanLike;
};

export const AutoSwitch = (props: Props) => {
  const { act } = useBackend<Data>();
  const on = !!props.on;
  return (
    <button
      type="button"
      className={`sw ${on ? 'sw--on' : ''}`}
      onClick={() => act('toggle_automatic')}
      title="Automatic First-Aid"
    >
      <span className="sw__lamp" />
      <span className="sw__track">
        <span className="sw__side sw__side--off">MAN</span>
        <span className="sw__side sw__side--on">AUTO</span>
        <span className="sw__knob">{on ? 'AUTO' : 'MAN'}</span>
      </span>
    </button>
  );
};
