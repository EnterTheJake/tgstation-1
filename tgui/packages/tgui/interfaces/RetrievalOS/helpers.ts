import { useEffect, useRef, useState } from 'react';

export const clock = (seconds: number) =>
  `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`;

export const titleCase = (text: string) =>
  text.replace(/\b\w/g, (letter) => letter.toUpperCase());

export function useTicker(active: boolean, ms: number) {
  const [, setTick] = useState(0);
  useEffect(() => {
    if (!active) {
      return;
    }
    const id = setInterval(() => setTick((tick) => tick + 1), ms);
    return () => clearInterval(id);
  }, [active, ms]);
}

export function useFlag(ms: number): [boolean, () => void] {
  const [on, setOn] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => () => clearTimeout(timer.current), []);
  const fire = () => {
    clearTimeout(timer.current);
    setOn(true);
    timer.current = setTimeout(() => setOn(false), ms);
  };
  return [on, fire];
}
