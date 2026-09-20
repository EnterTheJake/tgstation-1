import { useBackend } from '../../backend';
import { OsButton } from './OsButton';
import type { Data, Target } from './types';

const EXTRACTIONS: [string, string, keyof Target | null][] = [
  ['safe', 'Safe zone', null],
  ['unsafe', 'Unsafe', 'dropoff_location_unsafe'],
  ['dangerous', 'Dangerous', 'dropoff_location_dangerous'],
];

export const ExtractionRow = () => {
  const { act, data } = useBackend<Data>();
  const { targets = [], designated_contract_id, extracting } = data;
  const target = targets.find(
    (entry) => entry.contract_id === designated_contract_id,
  );
  if (!target) {
    return null;
  }
  return (
    <div className="board__extract">
      <span className="board__extractl">
        {extracting ? 'POD INBOUND' : 'CALL EXTRACTION'}
      </span>
      {EXTRACTIONS.map(([type, label, field]) => {
        const area = field ? target[field] : null;
        if (field && !area) {
          return null;
        }
        return (
          <OsButton
            key={type}
            className={`board__pod board__pod--${type}`}
            disabled={extracting}
            onClick={() => act('call_extraction', { extraction_type: type })}
          >
            {label}
            {area && <span>{String(area)}</span>}
          </OsButton>
        );
      })}
    </div>
  );
};
