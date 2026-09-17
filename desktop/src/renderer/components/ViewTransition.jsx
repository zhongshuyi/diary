'use client';

import { AnimatePresence, motion } from 'motion/react';
import { motionTokens, useMotionPreference } from '../lib/motion';

export function ViewTransition({ view, children }) {
  const { shouldAnimate } = useMotionPreference();

  if (!shouldAnimate) return children;

  return <AnimatePresence initial={false} mode="wait">
    <motion.div
      key={view}
      className="workspace-motion"
      initial={{ opacity: 0, y: motionTokens.distance.sm }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -motionTokens.distance.xs }}
      transition={{ duration: motionTokens.duration.normal, ease: motionTokens.easing.smooth }}
    >
      {children}
    </motion.div>
  </AnimatePresence>;
}
