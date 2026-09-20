import { useEffect, useState } from 'react';
import { FileImage, Film, Music2 } from 'lucide-react';
import { fileName, mediaKind } from '../lib/format';

export function AssetPreview({ path, className = '', controls = true, onRelocate }) {
  const [source, setSource] = useState(path?.startsWith('data:') ? path : null);
  const [relocating, setRelocating] = useState(false);
  const kind = mediaKind(path);
  const thumbnail = !controls && kind === 'image';
  const useLocalUrl = !controls && kind === 'video';

  useEffect(() => {
    let active = true;
    if (!path || path.startsWith('data:')) {
      setSource(path || null);
      return () => { active = false; };
    }
    setSource(null);
    if (!window.diaryAPI?.assets?.read) return () => { active = false; };
    window.diaryAPI.assets.read(path, { thumbnail, url: useLocalUrl }).then((value) => {
      if (active) setSource(value);
    }).catch(() => { if (active) setSource(null); });
    return () => { active = false; };
  }, [controls, kind, path, thumbnail, useLocalUrl]);

  if (!source) {
    return <div className={`asset-placeholder ${className}`} title={fileName(path)} aria-label={`${fileName(path)}：文件不可用`}>{kind === 'video' ? <Film size={20} /> : kind === 'audio' ? <Music2 size={20} /> : <FileImage size={20} />}{controls && <><span>文件不可用</span>{onRelocate && <button type="button" className="asset-relocate-button" disabled={relocating} onClick={async (event) => { event.stopPropagation(); setRelocating(true); try { await onRelocate(path); } finally { setRelocating(false); } }}>{relocating ? '校验中…' : '重新定位'}</button>}</>}</div>;
  }
  if (kind === 'video') {
    return <video className={`asset-preview ${className} ${controls ? '' : 'asset-video-thumbnail'}`} src={source} controls={controls} muted={!controls} playsInline preload={controls ? 'metadata' : 'auto'} aria-label={fileName(path)} onLoadedMetadata={(event) => { if (controls) return; const video = event.currentTarget; if (!Number.isFinite(video.duration) || video.duration <= 0) return; try { video.currentTime = Math.min(.32, Math.max(.06, video.duration * .08)); } catch { /* show the browser's first decoded frame */ } }} onError={() => setSource(null)} />;
  }
  if (kind === 'audio') {
    if (controls) return <audio className={`asset-preview ${className}`} src={source} controls preload="metadata" aria-label={fileName(path)} onError={() => setSource(null)} />;
    return <div className={`asset-audio ${className}`} title={fileName(path)}><Music2 size={20} /><span>音频</span></div>;
  }
  return <img className={`asset-preview ${className}`} src={source} alt={fileName(path)} onError={() => setSource(null)} />;
}
