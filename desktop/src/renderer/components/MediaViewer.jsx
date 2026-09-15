import { useEffect } from 'react';
import { ChevronLeft, ChevronRight, X } from 'lucide-react';
import { AssetPreview } from './AssetPreview';
import { fileName, mediaKind } from '../lib/format';

export function MediaViewer({ items, activeIndex, onActiveIndexChange, onClose }) {
  const item = items[activeIndex];
  const hasPrevious = activeIndex > 0;
  const hasNext = activeIndex < items.length - 1;

  useEffect(() => {
    const onKeyDown = (event) => {
      if (event.key === 'Escape') onClose();
      if (event.key === 'ArrowLeft' && hasPrevious) onActiveIndexChange(activeIndex - 1);
      if (event.key === 'ArrowRight' && hasNext) onActiveIndexChange(activeIndex + 1);
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [activeIndex, hasNext, hasPrevious, onActiveIndexChange, onClose]);

  if (!item) return null;
  const label = item.title?.trim() || fileName(item.path);
  const kind = mediaKind(item.path);
  const kindLabel = kind === 'video' ? '视频' : kind === 'audio' ? '音频' : '图片';

  return <div className="media-viewer-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
    <section className="media-viewer" role="dialog" aria-modal="true" aria-label={`查看${kindLabel}`} onMouseDown={(event) => event.stopPropagation()}>
      <header className="media-viewer-header"><div><strong>{label}</strong><span>{kindLabel} · {activeIndex + 1} / {items.length}</span></div><button type="button" className="media-viewer-close" aria-label="关闭预览" onClick={onClose}><X size={18} /></button></header>
      <div className="media-viewer-stage">
        {hasPrevious && <button type="button" className="media-viewer-nav previous" aria-label="上一张" onClick={() => onActiveIndexChange(activeIndex - 1)}><ChevronLeft size={21} /></button>}
        <AssetPreview path={item.path} className="media-viewer-asset" />
        {hasNext && <button type="button" className="media-viewer-nav next" aria-label="下一张" onClick={() => onActiveIndexChange(activeIndex + 1)}><ChevronRight size={21} /></button>}
      </div>
      <footer className="media-viewer-footer"><span>{fileName(item.path)}</span><span>← → 切换 · Esc 关闭</span></footer>
    </section>
  </div>;
}
