import { Copy, FileImage, Film, Heart, MoreHorizontal, Music2, RotateCcw, Trash2 } from 'lucide-react';
import { Fragment, useEffect, useId, useRef, useState } from 'react';
import { AssetPreview } from './AssetPreview';
import { entryContentText } from '../lib/content';
import { fileName, mediaKind, timeLabel } from '../lib/format';

function HighlightedText({ text, query }) {
  const value = String(text || '');
  const normalized = String(query || '').trim();
  if (!normalized) return value;
  const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const parts = value.split(new RegExp(`(${escaped})`, 'ig'));
  return parts.map((part, index) => part.toLowerCase() === normalized.toLowerCase() ? <mark key={`${part}-${index}`}>{part}</mark> : <Fragment key={`${part}-${index}`}>{part}</Fragment>);
}

export function EntryCard({ entry, highlightQuery = '', selectable = false, selected = false, onSelect, onEdit, onPreview, onToggleFavorite, onCopy, onTrash, onRestore, onDeletePermanent, isTrash = false }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const cardRef = useRef(null);
  const menuId = useId();
  const media = [...(entry.imagePaths || []), ...(entry.videoPaths || []), ...(entry.audioPaths || [])];
  const content = entryContentText(entry);
  const firstLine = content.split(/\r?\n/)[0].trim();
  const hasTitle = Boolean(entry.title?.trim());
  const displayTitle = hasTitle ? entry.title : (firstLine.slice(0, 42) || '一段记录');
  const previewItems = media.map((path) => ({ path, entryId: entry.id, title: displayTitle }));
  const excerpt = hasTitle ? content : content.split(/\r?\n/).slice(1).join(' ').trim();
  const isImageOnly = media.length > 0 && media.every((path) => mediaKind(path) === 'image') && !hasTitle && !content.trim();
  const MediaIcon = media.some((path) => mediaKind(path) === 'video') ? Film : media.some((path) => mediaKind(path) === 'audio') ? Music2 : FileImage;
  const canManage = isTrash ? Boolean(onRestore || onDeletePermanent) : Boolean(onToggleFavorite || onCopy || onTrash);
  const runAction = (action) => { setMenuOpen(false); action?.(entry.id); };

  useEffect(() => {
    if (!menuOpen) return undefined;
    const closeOnOutsidePointer = (event) => { if (!cardRef.current?.contains(event.target)) setMenuOpen(false); };
    const closeOnEscape = (event) => { if (event.key === 'Escape') setMenuOpen(false); };
    document.addEventListener('pointerdown', closeOnOutsidePointer);
    document.addEventListener('keydown', closeOnEscape);
    return () => {
      document.removeEventListener('pointerdown', closeOnOutsidePointer);
      document.removeEventListener('keydown', closeOnEscape);
    };
  }, [menuOpen]);

  const actions = canManage && <>
    <button type="button" className="entry-menu" aria-label="记录操作" aria-controls={menuId} aria-expanded={menuOpen} onClick={(event) => { event.stopPropagation(); setMenuOpen((open) => !open); }}><MoreHorizontal size={16} /></button>
    {menuOpen && <div id={menuId} className="entry-actions-menu" role="menu" onClick={(event) => event.stopPropagation()}>
      {isTrash ? <>
        <button type="button" onClick={() => runAction(onRestore)}><RotateCcw size={13} />恢复记录</button>
        <button type="button" className="danger" onClick={() => runAction(onDeletePermanent)}><Trash2 size={13} />永久删除</button>
      </> : <>
        <button type="button" onClick={() => runAction(onToggleFavorite)}><Heart size={13} fill={entry.isFavorite ? 'currentColor' : 'none'} />{entry.isFavorite ? '取消收藏' : '收藏'}</button>
        <button type="button" onClick={() => runAction(onCopy)}><Copy size={13} />复制一份</button>
        <button type="button" className="danger" onClick={() => runAction(onTrash)}><Trash2 size={13} />移入回收站</button>
      </>}
    </div>}
  </>;

  return <article ref={cardRef} className={`entry-card ${isTrash ? 'trashed' : ''} ${selected ? 'selected' : ''} ${menuOpen ? 'is-menu-open' : ''} ${isImageOnly ? 'image-only' : ''}`} tabIndex="0" aria-label={isImageOnly ? '仅图片记录' : displayTitle} onClick={() => onEdit?.(entry.id)} onKeyDown={(event) => { if (event.target !== event.currentTarget) return; if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); onEdit?.(entry.id); } }}>
    {!isImageOnly && <div className="entry-card-line"><span className="entry-card-dot"></span><span className="entry-time">{timeLabel(entry.occurredAt || entry.createdAt)}</span></div>}
    <div className="entry-card-body">
      {isImageOnly ? <div className="image-only-actions">{actions}</div> : <div className="entry-card-title">
        {selectable && <label className="entry-select" onClick={(event) => event.stopPropagation()}><input type="checkbox" checked={selected} onChange={() => onSelect?.(entry.id)} aria-label={`选择${displayTitle}`} /></label>}
        <h3 className={!hasTitle ? 'generated-title' : ''}><HighlightedText text={displayTitle} query={highlightQuery} /></h3>
        {entry.isFavorite && <Heart className="entry-favorite" size={13} fill="currentColor" aria-label="已收藏" />}
        <span className="entry-category"><HighlightedText text={entry.category || '生活'} query={highlightQuery} /></span>
        {actions}
      </div>}
      {!isImageOnly && excerpt && <p><HighlightedText text={excerpt} query={highlightQuery} /></p>}
      {media.length > 0 && <div className="entry-images">{media.slice(0, 3).map((path, index) => <button type="button" className="entry-media-button" key={path} aria-label={`预览${fileName(path)}`} onClick={(event) => { event.stopPropagation(); onPreview?.(previewItems, index); }}><AssetPreview path={path} className="entry-image" controls={false} /></button>)}{media.length > 3 && <button type="button" className="more-images" onClick={(event) => { event.stopPropagation(); onPreview?.(previewItems, 3); }}>+{media.length - 3}</button>}</div>}
      {!isImageOnly && <div className="entry-meta"><span>{content.length} 字</span>{media.length > 0 && <span><MediaIcon size={13} />{media.length} 个附件</span>}<span className="entry-edit-hint">打开编辑</span></div>}
    </div>
  </article>;
}

export function MediaTile({ path, title, onClick }) {
  return <button className="media-tile" onClick={onClick}><AssetPreview path={path} className="media-tile-image" controls={false} /><span className="media-tile-name">{fileName(path)}</span><span className="media-tile-title">{title}</span></button>;
}
