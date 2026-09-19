import { useEffect, useState } from 'react';
import { useReducedMotion } from 'motion/react';

export const motionTokens = Object.freeze({
  duration: Object.freeze({ instant: 0.08, fast: 0.18, normal: 0.32, slow: 0.5 }),
  easing: Object.freeze({ smooth: [0.22, 1, 0.36, 1], sharp: [0.4, 0, 0.2, 1] }),
  distance: Object.freeze({ xs: 4, sm: 8, md: 16 }),
  scale: Object.freeze({ press: 0.97, pop: 1.02 }),
});

export const springs = Object.freeze({
  snappy: Object.freeze({ type: 'spring', stiffness: 300, damping: 30 }),
  gentle: Object.freeze({ type: 'spring', stiffness: 150, damping: 18 }),
  instant: Object.freeze({ type: 'spring', stiffness: 600, damping: 35 }),
});

function detectLowEndDevice() {
  if (typeof navigator === 'undefined') return false;
  return Number(navigator.hardwareConcurrency || 8) <= 4;
}

export function useMotionPreference() {
  const prefersReducedMotion = useReducedMotion();
  const [isLowEnd, setIsLowEnd] = useState(detectLowEndDevice);

  useEffect(() => {
    setIsLowEnd(detectLowEndDevice());
  }, []);

  return { shouldAnimate: !prefersReducedMotion && !isLowEnd, prefersReducedMotion: Boolean(prefersReducedMotion) };
}
