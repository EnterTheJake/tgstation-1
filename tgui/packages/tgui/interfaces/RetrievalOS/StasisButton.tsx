import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../../backend';
import type { Data } from './types';

type Props = {
  on: BooleanLike;
  auto: BooleanLike;
};

export const StasisButton = (props: Props) => {
  const { act } = useBackend<Data>();
  const on = !!props.on;
  const auto = !!props.auto;
  return (
    <button
      type="button"
      className={`stasis ${on ? 'stasis--on' : ''} ${auto ? 'stasis--auto' : ''}`}
      onClick={() => act('toggle_stasis')}
      title={
        auto
          ? 'Held for you in critical condition and death. Clicking takes manual control.'
          : 'Hold the occupant in stasis, the way a stasis bed does'
      }
    >
      <span className="stasis__flake">❄</span>
      STASIS
      <span className="stasis__power">{auto ? 'AUTO' : on ? 'ON' : 'OFF'}</span>
    </button>
  );
};
