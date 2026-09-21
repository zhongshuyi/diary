import { Images } from 'lucide-react';
import { useMemo, useState } from 'react';
import { AssetPreview } from './AssetPreview';
import { entryContentText } from '../lib/content';
import { fileName, mediaKind, shortDateLabel } from '../lib/format';

export function LibraryView({ entries, search, onPreview }) {
  const [mediaQuery, setMediaQuery] = useState(search || '');
  const [kindFilter, setKindFilter] = useState('all');
  const query = mediaQuery.trim().toLowerCase();
  const allMedia = useMemo(() => entries
    .filter((entry) => !entry.isInTrash)
    .flatMap((entry) => [...(entry.imagePaths || []), ...(entry.videoPaths || []), ...(entry.audioPaths || [])].map((path) => ({ path, id: `${entry.id}-${path}`, entryId: entry.id, title: entry.title || entryContentText(entry) || '一段记录', createdAt: entry.occurredAt || entry.createdAt, kind: mediaKind(path) })))
    .sort((left, right) => new Date(right.createdAt) - new Date(left.createdAt)), [entries]);
  const mediaCounts = useMemo(() => allMedia.reduce((counts, item) => ({ ...counts, [item.kind]: counts[item.kind] + 1 }), { image: 0, video: 0, audio: 0 }), [allMedia]);
  const media = useMemo(() => allMedia
    .filter((item) => !query || `${item.title} ${fileName(item.path)}`.toLowerCase().includes(query))
    .filter((item) => kindFilter === 'all' || item.kind === kindFilter), [allMedia, kindFilter, query]);

  return <section className="media-wall-page">
    <header className="media-wall-header"><div><p className="section-kicker">MEDIA / LIBRARY</p><h2>媒体库</h2><p>被记录下来的图片、声音和片段。</p></div><span className="media-wall-count"><Images size={15} />{media.length} 个媒体</span></header>
    <div className="media-wall-toolbar"><label className="media-wall-search"><span>查找媒体</span><input value={mediaQuery} onChange={(event) => setMediaQuery(event.target.value)} placeholder="文件名或记录内容" aria-label="查找媒体" /></label><div className="media-kind-chips" role="group" aria-label="按媒体类型筛选">{[['all', '全部', allMedia.length], ['image', '图片', mediaCounts.image], ['video', '视频', mediaCounts.video], ['audio', '音频', mediaCounts.audio]].map(([value, label, count]) => <button type="button" key={value} className={`media-kind-chip ${kindFilter === value ? 'selected' : ''}`} aria-pressed={kindFilter === value} onClick={() => setKindFilter(value)}>{label}<small>{count}</small></button>)}</div></div>
    {media.length ? <div className={`media-masonry ${kindFilter === 'image' ? 'photo-grid' : ''}`}>{media.map((item, index) => <button key={item.id} type="button" className={`media-wall-tile ${item.kind}`} aria-label={`查看${fileName(item.path)}`} onClick={() => onPreview?.(media, index)}><AssetPreview path={item.path} className="media-wall-asset" controls={false} /><span className="media-wall-date">{shortDateLabel(item.createdAt)}</span></button>)}</div> : <div className="media-wall-empty"><Images size={24} /><strong>{query ? '没有找到匹配的媒体' : '还没有媒体内容'}</strong><span>{query ? '试试换一个关键词。' : '在日记里粘贴或拖入图片、视频，都会收进这里。'}</span></div>}
  </section>;
}
