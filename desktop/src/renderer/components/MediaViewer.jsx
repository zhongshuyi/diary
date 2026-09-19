import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import { ChevronLeft, ChevronRight, X } from 'lucide-react';
import { AssetPreview } from './AssetPreview';
import { fileName, mediaKind } from '../lib/format';
import { motionTokens, springs, useMotionPreference } from '../lib/motion';

export function MediaViewer({ items, activeIndex, onActiveIndexChange, onClose, onOpenEntry, onRelocate }) {
  const [isClosing, setIsClosing] = useState(false);
  const [direction, setDirection] = useState(1);
  const closeTimer = useRef(null);
  const closeButtonRef = useRef(null);
  const triggerRef = useRef(null);
  const { shouldAnimate } = useMotionPreference();
  const item = items[activeIndex];
  const hasPrevious = activeIndex > 0;
  const hasNext = activeIndex < items.length - 1;

  const requestClose = useCallback((afterClose = onClose) => {
    if (isClosing) return;
    if (!shouldAnimate) {
      afterClose?.();
      return;
    }
    setIsClosing(true);
    closeTimer.current = window.setTimeout(() => afterClose?.(), motionTokens.duration.fast * 1000);
  }, [isClosing, onClose, shouldAnimate]);

  const goTo = useCallback((nextIndex) => {
    if (nextIndex < 0 || nextIndex >= items.length || nextIndex === activeIndex) return;
    setDirection(nextIndex > activeIndex ? 1 : -1);
    onActiveIndexChange(nextIndex);
  }, [activeIndex, items.length, onActiveIndexChange]);

  useEffect(() => {
    const onKeyDown = (event) => {
      if (event.key === 'Escape') requestClose();
      if (event.key === 'ArrowLeft' && hasPrevious) goTo(activeIndex - 1);
      if (event.key === 'ArrowRight' && hasNext) goTo(activeIndex + 1);
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [activeIndex, goTo, hasNext, hasPrevious, requestClose]);

  useEffect(() => {
    triggerRef.current = document.activeElement;
    closeButtonRef.current?.focus();
    document.body.classList.add('media-viewer-open');
    return () => {
      window.clearTimeout(closeTimer.current);
      document.body.classList.remove('media-viewer-open');
      triggerRef.current?.focus?.();
    };
  }, []);

  if (!item) return null;
  const label = item.title?.trim() || fileName(item.path);
  const kind = mediaKind(item.path);
  const kindLabel = kind === 'video' ? '视频' : kind === 'audio' ? '音频' : '图片';
  const dialogTransition = shouldAnimate ? springs.snappy : { duration: 0 };
  const backdropTransition = shouldAnimate ? { duration: motionTokens.duration.fast, ease: motionTokens.easing.smooth } : { duration: 0 };
  const assetTransition = shouldAnimate ? { duration: motionTokens.duration.fast, ease: motionTokens.easing.smooth } : { duration: 0 };
  const assetVariants = {
    enter: { opacity: 0, x: direction * motionTokens.distance.md, scale: 0.985 },
    center: { opacity: 1, x: 0, scale: 1 },
    exit: { opacity: 0, x: direction * -motionTokens.distance.md, scale: 0.985 },
  };

  return <motion.div className="media-viewer-backdrop" role="presentation" initial={shouldAnimate ? { opacity: 0 } : false} animate={{ opacity: isClosing ? 0 : 1 }} transition={backdropTransition} onMouseDown={(event) => { if (event.target === event.currentTarget) requestClose(); }}>
    <motion.section className="media-viewer" role="dialog" aria-modal="true" aria-label={`查看${kindLabel}`} initial={shouldAnimate ? { opacity: 0, scale: 0.92, y: motionTokens.distance.md } : false} animate={{ opacity: isClosing ? 0 : 1, scale: isClosing ? 0.96 : 1, y: isClosing ? motionTokens.distance.sm : 0 }} transition={dialogTransition} onMouseDown={(event) => event.stopPropagation()}>
      <header className="media-viewer-header"><div><strong>{label}</strong><span>{kindLabel} · {activeIndex + 1} / {items.length}</span></div><button ref={closeButtonRef} type="button" className="media-viewer-close" aria-label="关闭预览" onClick={() => requestClose()}><X size={18} /></button></header>
      <div className="media-viewer-stage">
        {hasPrevious && <button type="button" className="media-viewer-nav previous" aria-label="上一张" onClick={() => goTo(activeIndex - 1)}><ChevronLeft size={21} /></button>}
        <AnimatePresence initial={false} mode="wait" custom={direction}>
          <motion.div key={`${activeIndex}:${item.path}`} className="media-viewer-asset-frame" custom={direction} variants={assetVariants} initial="enter" animate="center" exit="exit" transition={assetTransition}>
            <AssetPreview path={item.path} className="media-viewer-asset" onRelocate={onRelocate} />
          </motion.div>
        </AnimatePresence>
        {hasNext && <button type="button" className="media-viewer-nav next" aria-label="下一张" onClick={() => goTo(activeIndex + 1)}><ChevronRight size={21} /></button>}
      </div>
      <footer className="media-viewer-footer"><span>{fileName(item.path)}</span><div className="media-viewer-footer-actions">{item.entryId && onOpenEntry && <button type="button" className="media-viewer-entry-link" onClick={() => requestClose(() => onOpenEntry(item.entryId))}>打开所属记录</button>}<span>← → 切换 · Esc 关闭</span></div></footer>
    </motion.section>
  </motion.div>;
}
