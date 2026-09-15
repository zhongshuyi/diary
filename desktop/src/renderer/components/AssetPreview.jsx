import { useEffect, useState } from 'react';
import { FileImage, Film, Music2 } from 'lucide-react';
import { fileName, mediaKind } from '../lib/format';

export function AssetPreview({ path, className = '', controls = true }) {
  const [source, setSource] = useState(path?.startsWith('data:') ? path : null);
  const kind = mediaKind(path);

  useEffect(() => {
    let active = true;
    if (!path || path.startsWith('data:')) {
      setSource(path || null);
      return () => { active = false; };
    }
    setSource(null);
    if (!window.diaryAPI?.assets?.read) return () => { active = false; };
    window.diaryAPI.assets.read(path).then((value) => {
      if (active) setSource(value);
    });
    return () => { active = false; };
  }, [path]);

  if (!source) {
    return <div className={`asset-placeholder ${className}`} title={fileName(path)}>{kind === 'video' ? <Film size={20} /> : kind === 'audio' ? <Music2 size={20} /> : <FileImage size={20} />}</div>;
  }
  if (kind === 'video') {
    return <video className={`asset-preview ${className}`} src={source} controls={controls} muted={!controls} playsInline preload="metadata" aria-label={fileName(path)} onError={() => setSource(null)} />;
  }
  if (kind === 'audio') {
    if (controls) return <audio className={`asset-preview ${className}`} src={source} controls preload="metadata" aria-label={fileName(path)} onError={() => setSource(null)} />;
    return <div className={`asset-audio ${className}`} title={fileName(path)}><Music2 size={20} /><span>音频</span></div>;
  }
  return <img className={`asset-preview ${className}`} src={source} alt={fileName(path)} onError={() => setSource(null)} />;
}
