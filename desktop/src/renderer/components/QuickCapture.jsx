import { useEffect, useRef, useState } from 'react';
import { FileImage, Film, ImagePlus, Music2, Type, X } from 'lucide-react';
import { AssetPreview } from './AssetPreview';
import { MediaViewer } from './MediaViewer';
import { Button } from './ui/Button';
import { IconButton } from './ui/IconButton';
import { SelectField } from './ui/SelectField';
import { DatePicker } from './ui/DatePicker';
import { fileName, mediaKind } from '../lib/format';

const categoryOptions = ['生活', '灵感', '心情', '工作'];
const moodOptions = [{ value: '0.9', label: '很好' }, { value: '0.7', label: '平静' }, { value: '0.5', label: '一般' }, { value: '0.3', label: '低落' }];

function DateControl({ draft, setDraft }) {
  return <DatePicker className="paper-date-control" value={draft.date} onChange={(date) => setDraft({ ...draft, date })} />;
}

export function QuickCapture({ draft, setDraft, attachments, setAttachments, editing, inline = false, onSave, onClose, onNotify }) {
  const contentRef = useRef(null);
  const titleRef = useRef(null);
  const [showTitle, setShowTitle] = useState(Boolean(draft.title));
  const [previewIndex, setPreviewIndex] = useState(null);

  useEffect(() => { contentRef.current?.focus(); }, []);
  useEffect(() => { if (draft.title) setShowTitle(true); }, [draft.title]);

  const append = (paths) => {
    const valid = paths.filter(Boolean);
    setAttachments([...new Set([...attachments, ...valid])]);
    if (valid.length) onNotify?.(`已添加 ${valid.length} 个附件`);
  };

  const pickMedia = async () => {
    const paths = await window.diaryAPI.assets.pickMedia();
    if (paths?.length) append(paths);
  };

  const importFiles = async (files) => {
    const paths = [];
    const buffers = [];
    for (const file of Array.from(files || []).slice(0, 20)) {
      if (!file.type?.startsWith('image/') && !file.type?.startsWith('video/') && !file.type?.startsWith('audio/')) continue;
      const path = window.diaryAPI.assets.pathForFile(file);
      if (path) paths.push(path);
      else buffers.push({ name: file.name, mime: file.type, buffer: await file.arrayBuffer() });
    }
    const imported = await window.diaryAPI.assets.importFiles(paths);
    const saved = await Promise.all(buffers.map((payload) => window.diaryAPI.assets.saveClipboard(payload)));
    append([...imported, ...saved]);
  };

  const handlePaste = async (event) => {
    const mediaItems = Array.from(event.clipboardData?.items || []).filter((item) => item.type?.startsWith('image/') || item.type?.startsWith('video/') || item.type?.startsWith('audio/'));
    if (mediaItems.length) {
      event.preventDefault();
      await importFiles(mediaItems.map((item) => item.getAsFile()).filter(Boolean));
    } else if (event.clipboardData?.files?.length) {
      event.preventDefault();
      await importFiles(event.clipboardData.files);
    }
  };

  const handleDrop = async (event) => {
    if (!event.dataTransfer?.files?.length) return;
    event.preventDefault();
    await importFiles(event.dataTransfer.files);
  };

  const revealTitle = () => {
    setShowTitle(true);
    window.requestAnimationFrame(() => titleRef.current?.focus());
  };

  const hideTitle = () => setShowTitle(false);

  const attachmentList = attachments.length > 0 && <div className="attachment-list">{attachments.map((path, index) => {
    const kind = mediaKind(path);
    return <div className={`attachment-item attachment-${kind}`} key={path}>
      <button type="button" className="attachment-open" onClick={() => setPreviewIndex(index)} aria-label={`查看${fileName(path)}`} title={fileName(path)}>
        <AssetPreview path={path} className="attachment-preview" controls={false} />
        {kind === 'audio' && <span>{fileName(path)}</span>}
      </button>
      <IconButton label="移除附件" onClick={() => setAttachments(attachments.filter((item) => item !== path))}><X size={12} /></IconButton>
      {kind === 'video' && <Film className="attachment-kind" size={12} />}
      {kind === 'audio' && <Music2 className="attachment-kind" size={12} />}
    </div>;
  })}</div>;

  const titleField = showTitle && <div className="title-field"><input ref={titleRef} className="composer-title" value={draft.title} onChange={(event) => setDraft({ ...draft, title: event.target.value })} maxLength={120} placeholder="标题（可选）" /><button type="button" className="title-dismiss" onClick={hideTitle} aria-label="收起标题"><X size={14} /></button></div>;
  const controls = <div className="composer-controls"><Button variant="ghost" size="sm" icon={ImagePlus} className="attachment-button" onClick={pickMedia}>附件</Button>{!showTitle && <button type="button" className="title-toggle" onClick={revealTitle}><Type size={13} />{draft.title ? '编辑标题' : '添加标题'}</button>}<SelectField value={draft.category} onChange={(value) => setDraft({ ...draft, category: value })} options={categoryOptions} label="分类" />{!inline && <SelectField value={draft.mood} onChange={(value) => setDraft({ ...draft, mood: value })} options={moodOptions} label="心情" />}<span className="capture-shortcut"><kbd>Ctrl</kbd><span>+</span><kbd>Enter</kbd></span></div>;

  const editor = <section className={`composer-dialog ${inline ? 'composer-inline paper-editor' : 'detail-editor'}`} role={inline ? 'region' : 'dialog'} aria-modal={inline ? undefined : 'true'} aria-label={editing ? '编辑日记' : '新建日记'} onMouseDown={(event) => event.stopPropagation()} onPaste={handlePaste} onDragOver={(event) => event.preventDefault()} onDrop={handleDrop}>
    {inline ? <div className="paper-editor-header"><span>新的一段</span><DateControl draft={draft} setDraft={setDraft} /></div> : <div className="composer-header"><div className="detail-editor-heading"><span>{editing ? '编辑记录' : '新建记录'}</span><DateControl draft={draft} setDraft={setDraft} /></div>{onClose && <IconButton className="icon-only-button" label="关闭" onClick={onClose}><X size={17} /></IconButton>}</div>}
    {titleField}
    <textarea ref={contentRef} className="composer-content" id={inline ? 'inline-content-input' : 'content-input'} rows={inline ? '12' : '10'} maxLength={10000} value={draft.content} onChange={(event) => setDraft({ ...draft, content: event.target.value })} placeholder="此刻想到什么？先写下来……" />
    {controls}
    {attachmentList}
    <footer className="composer-footer"><span className="composer-note">{inline ? '自动保留在本机' : '内容会先保存到本机 · 支持一天多次记录'}</span><div>{!inline && <Button variant="ghost" size="sm" onClick={onClose}>取消</Button>}<Button size="sm" onClick={onSave}>{editing ? '保存修改' : inline ? '记下' : '保存日记'}</Button></div></footer>
  </section>;

  const capture = inline ? editor : <div className="composer-dialog-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose?.(); }}>{editor}</div>;
  return <>{capture}{previewIndex !== null && <MediaViewer items={attachments.map((path) => ({ path }))} activeIndex={previewIndex} onActiveIndexChange={setPreviewIndex} onClose={() => setPreviewIndex(null)} />}</>;
}
