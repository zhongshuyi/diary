import { FileImage, Film, MoreHorizontal, Music2 } from 'lucide-react';
import { AssetPreview } from './AssetPreview';
import { fileName, mediaKind, timeLabel } from '../lib/format';

export function EntryCard({ entry, onEdit, onPreview }) {
  const media = [...(entry.imagePaths || []), ...(entry.videoPaths || []), ...(entry.audioPaths || [])];
  const content = entry.contentText || entry.content || '';
  const firstLine = content.split(/\r?\n/)[0].trim();
  const hasTitle = Boolean(entry.title?.trim());
  const displayTitle = hasTitle ? entry.title : (firstLine.slice(0, 42) || '一段记录');
  const excerpt = hasTitle ? content : content.split(/\r?\n/).slice(1).join(' ').trim();
  const MediaIcon = media.some((path) => mediaKind(path) === 'video') ? Film : media.some((path) => mediaKind(path) === 'audio') ? Music2 : FileImage;
  return <article className="entry-card" onClick={() => onEdit(entry.id)}><div className="entry-card-line"><span className="entry-card-dot"></span><span className="entry-time">{timeLabel(entry.createdAt)}</span></div><div className="entry-card-body"><div className="entry-card-title"><h3 className={!hasTitle ? 'generated-title' : ''}>{displayTitle}</h3><span className="entry-category">{entry.category || '生活'}</span><MoreHorizontal size={16} className="entry-menu" /></div>{excerpt && <p>{excerpt}</p>}{media.length > 0 && <div className="entry-images">{media.slice(0, 3).map((path, index) => <button type="button" className="entry-media-button" key={path} aria-label={`预览${fileName(path)}`} onClick={(event) => { event.stopPropagation(); onPreview?.(media, index); }}><AssetPreview path={path} className="entry-image" controls={false} /></button>)}{media.length > 3 && <button type="button" className="more-images" onClick={(event) => { event.stopPropagation(); onPreview?.(media, 3); }}>+{media.length - 3}</button>}</div>}<div className="entry-meta"><span>{content.length} 字</span>{media.length > 0 && <span><MediaIcon size={13} />{media.length} 个附件</span>}<span className="entry-edit-hint">打开编辑</span></div></div></article>;
}

export function MediaTile({ path, title, onClick }) {
  return <button className="media-tile" onClick={onClick}><AssetPreview path={path} className="media-tile-image" controls={false} /><span className="media-tile-name">{fileName(path)}</span><span className="media-tile-title">{title}</span></button>;
}
