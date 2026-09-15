import { Images } from 'lucide-react';
import { AssetPreview } from './AssetPreview';
import { fileName, mediaKind, shortDateLabel } from '../lib/format';

export function LibraryView({ entries, search, onPreview }) {
  const query = search.trim().toLowerCase();
  const media = entries
    .filter((entry) => !entry.isInTrash)
    .flatMap((entry) => [...(entry.imagePaths || []), ...(entry.videoPaths || []), ...(entry.audioPaths || [])].map((path) => ({ path, id: `${entry.id}-${path}`, title: entry.title || entry.contentText || '一段记录', createdAt: entry.createdAt, kind: mediaKind(path) })))
    .filter((item) => !query || `${item.title} ${fileName(item.path)}`.toLowerCase().includes(query))
    .sort((left, right) => new Date(right.createdAt) - new Date(left.createdAt));

  return <section className="media-wall-page">
    <header className="media-wall-header"><div><p className="section-kicker">YOUR VISUAL ARCHIVE</p><h2>相册</h2><p>被记录下来的光影、声音和片段。</p></div><span className="media-wall-count"><Images size={15} />{media.length} 个媒体</span></header>
    {media.length ? <div className="media-masonry">{media.map((item, index) => <button key={item.id} type="button" className={`media-wall-tile ${item.kind}`} aria-label={`查看${fileName(item.path)}`} onClick={() => onPreview?.(media, index)}><AssetPreview path={item.path} className="media-wall-asset" controls={false} /><span className="media-wall-date">{shortDateLabel(item.createdAt)}</span></button>)}</div> : <div className="media-wall-empty"><Images size={24} /><strong>{query ? '没有找到匹配的媒体' : '还没有媒体内容'}</strong><span>{query ? '试试换一个关键词。' : '在日记里粘贴或拖入图片、视频，都会收进这里。'}</span></div>}
  </section>;
}
