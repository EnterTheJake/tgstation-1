import type { ReactNode } from 'react';
import type { BooleanLike } from 'tgui-core/react';

type Props = {
  children: ReactNode;
  onClick: () => void;
  className?: string;
  disabled?: BooleanLike;
};

export const OsButton = (props: Props) => (
  <button
    type="button"
    className={`btn ${props.className ?? ''}`}
    disabled={!!props.disabled}
    onClick={props.onClick}
  >
    {props.children}
  </button>
);
