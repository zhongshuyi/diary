"use client";

import { useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import { CheckCircle2, Code2, FileText, Film, ImagePlus, LoaderCircle, Music2, Type, UploadCloud, X } from 'lucide-react';
import { AssetPreview } from './AssetPreview';
import { MarkdownEditor } from './MarkdownEditor';
import { MediaViewer } from './MediaViewer';
import { RichTextEditor } from './RichTextEditor';
import { Button } from './ui/Button';
import { IconButton } from './ui/IconButton';
import { DatePicker } from './ui/DatePicker';
import { draftContentText, EDITOR_TYPES, editorTypeLabel, normalizeEditorType, toRichTextContent } from '../lib/content';
import { fileName, mediaKind } from '../lib/format';
import { motionTokens, springs, useMotionPreference } from '../lib/motion';

const moodOptions = [{ value: '0.9', label: '很好' }, { value: '0.7', label: '平静' }, { value: '0.5', label: '一般' }, { value: '0.3', label: '低落' }];
const defaultCategoryOptions = ['生活', '灵感', '心情', '工作'];
const editorOptions = [
  { value: EDITOR_TYPES.plainText, label: '纯文本', icon: Type },
  { value: EDITOR_TYPES.markdown, label: 'Markdown', icon: Code2 },
  { value: EDITOR_TYPES.richText, label: '富文本', icon: FileText },
];

function DraftSaveStatus({ status }) {
  if (status === 'idle') return null;

  const statusContent = {
    saving: { icon: LoaderCircle, label: '正在保存草稿' },
    saved: { icon: CheckCircle2, label: '草稿已保存在本机' },
    error: { icon: FileText, label: '草稿未保存' },
  }[status];
  if (!statusContent) return null;

  const Icon = statusContent.icon;
  return <span className={`draft-save-status is-${status}`} role="status" aria-live="polite"><Icon size={13} strokeWidth={2} aria-hidden="true" />{statusContent.label}</span>;
}

function AttachmentDropHint({ visible, shouldAnimate }) {
  const hint = <div className="composer-drop-hint" role="status" aria-live="polite"><UploadCloud size={24} strokeWidth={1.8} aria-hidden="true" /><strong>松开即可添加附件</strong><span>支持图片、视频和音频</span></div>;
  if (!shouldAnimate) return visible ? hint : null;

  return <AnimatePresence initial={false}>{visible ? <motion.div initial={{ opacity: 0, scale: motionTokens.scale.press }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: motionTokens.scale.press }} transition={springs.gentle}>{hint}</motion.div> : null}</AnimatePresence>;
}

function DateControl({ draft, setDraft }) {
  return <DatePicker className="paper-date-control" value={draft.date} onChange={(date) => setDraft({ ...draft, date })} />;
}

export function QuickCapture({ draft, setDraft, attachments, setAttachments, editing, inline = false, windowed = false, categoryOptions = defaultCategoryOptions, tagOptions = [], draftStatus = 'idle', onSave, onClose, onNotify }) {
  const contentRef = useRef(null);
  const titleRef = useRef(null);
  const [showTitle, setShowTitle] = useState(Boolean(draft.title));
  const [previewIndex, setPreviewIndex] = useState(null);
  const [tagInput, setTagInput] = useState('');
  const [isDragging, setIsDragging] = useState(false);
  const dragDepthRef = useRef(0);
  const { shouldAnimate } = useMotionPreference();
  const editorType = normalizeEditorType(draft.editorType);

  useEffect(() => { contentRef.current?.focus(); }, []);
  useEffect(() => { if (draft.title) setShowTitle(true); }, [draft.title]);
  useEffect(() => { if (!draft.title && !draftContentText(draft) && attachments.length === 0) setShowTitle(false); }, [draft.title, draft.content, draft.contentText, attachments.length]);

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

  const isFileTransfer = (transfer) => Array.from(transfer?.types || []).includes('Files');

  const handleDragEnter = (event) => {
    if (!isFileTransfer(event.dataTransfer)) return;
    event.preventDefault();
    dragDepthRef.current += 1;
    setIsDragging(true);
  };

  const handleDragOver = (event) => {
    if (!isFileTransfer(event.dataTransfer)) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
  };

  const handleDragLeave = (event) => {
    if (!isFileTransfer(event.dataTransfer)) return;
    event.preventDefault();
    dragDepthRef.current = Math.max(0, dragDepthRef.current - 1);
    if (dragDepthRef.current === 0) setIsDragging(false);
  };

  const handleDrop = async (event) => {
    if (!event.dataTransfer?.files?.length) return;
    event.preventDefault();
    dragDepthRef.current = 0;
    setIsDragging(false);

    const mediaFiles = Array.from(event.dataTransfer.files).filter((file) => (
      file.type.startsWith('image/') || file.type.startsWith('video/') || file.type.startsWith('audio/')
    ));
    if (!mediaFiles.length) {
      onNotify?.('仅支持图片、视频和音频文件');
      return;
    }

    await importFiles(mediaFiles);
  };

  const revealTitle = () => {
    setShowTitle(true);
    window.requestAnimationFrame(() => titleRef.current?.focus());
  };

  const toggleTag = (tag) => {
    const tags = Array.isArray(draft.tags) ? draft.tags : [];
    setDraft({ ...draft, tags: tags.includes(tag) ? tags.filter((item) => item !== tag) : [...tags, tag].slice(0, 12) });
  };

  const addTags = (value) => {
    const next = String(value || '').split(/[,，]/).map((tag) => tag.trim()).filter(Boolean);
    if (!next.length) return;
    const tags = [...new Set([...(draft.tags || []), ...next])].slice(0, 12);
    setDraft({ ...draft, tags });
    setTagInput('');
  };

  const switchEditorType = (nextEditorType) => {
    const next = normalizeEditorType(nextEditorType);
    if (next === editorType) return;
    const plainText = draftContentText(draft);
    if (editorType === EDITOR_TYPES.richText && plainText.trim() && !window.confirm('切换格式会将当前富文本转换为纯文本，字体、列表和链接样式将不再保留。是否继续？')) return;
    const content = next === EDITOR_TYPES.richText ? toRichTextContent(plainText) : plainText;
    setDraft({ ...draft, editorType: next, content, contentText: plainText });
    window.requestAnimationFrame(() => contentRef.current?.focus());
  };

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

  const titleField = showTitle && <div className="title-field"><input ref={titleRef} className="composer-title" value={draft.title} onChange={(event) => setDraft({ ...draft, title: event.target.value })} maxLength={120} placeholder="标题（可选）" /><button type="button" className="title-dismiss" onClick={() => setShowTitle(false)} aria-label="收起标题"><X size={14} /></button></div>;
  const selectedTags = Array.isArray(draft.tags) ? draft.tags : [];
  const visibleTags = [...new Set([...selectedTags, ...tagOptions])].slice(0, 16);
  const plainText = draftContentText(draft);
  const contentLength = plainText.trim().length;
  const editorModeControl = <div className="editor-mode-control"><div className="editor-mode-switch" role="group" aria-label="记录格式">{editorOptions.map((option) => {
    const Icon = option.icon;
    const selected = editorType === option.value;
    return <button type="button" key={option.value} className={selected ? 'selected' : ''} aria-pressed={selected} onClick={() => switchEditorType(option.value)} title={`使用${option.label}`}><Icon size={13} /><span>{option.label}</span></button>;
  })}</div></div>;
  const controls = <div className="composer-controls"><div className="composer-utility-row"><div className="composer-utility-actions"><Button variant="ghost" size="sm" icon={ImagePlus} className="attachment-button" onClick={pickMedia}>添加附件</Button>{!showTitle && <button type="button" className="title-toggle" onClick={revealTitle}><Type size={13} />{draft.title ? '编辑标题' : '添加标题'}</button>}</div><span className="capture-shortcut"><kbd>Ctrl</kbd><span>+</span><kbd>Enter</kbd> 保存</span></div><div className="composer-metadata-row"><div className="composer-taxonomy-group"><span className="composer-taxonomy-label">分类</span><div className="composer-chips" role="group" aria-label="分类">{categoryOptions.map((category) => <button type="button" key={category} className={`composer-chip ${draft.category === category ? 'selected' : ''}`} aria-pressed={draft.category === category} onClick={() => setDraft({ ...draft, category })}>{category}</button>)}</div></div><div className="composer-taxonomy-group composer-tags-group"><span className="composer-taxonomy-label">标签</span><div className="composer-chips tag-chips" role="group" aria-label="常用标签">{visibleTags.map((tag) => <button type="button" key={tag} className={`composer-chip ${selectedTags.includes(tag) ? 'selected' : ''}`} aria-pressed={selectedTags.includes(tag)} onClick={() => toggleTag(tag)}>#{tag}</button>)}<input className="composer-tag-input" value={tagInput} onChange={(event) => setTagInput(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter' || event.key === ',' || event.key === '，') { event.preventDefault(); addTags(tagInput); } }} onBlur={() => addTags(tagInput)} placeholder="添加标签" aria-label="添加标签，回车确认" /></div></div>{!inline && <div className="composer-taxonomy-group composer-mood"><span className="composer-taxonomy-label">心情</span><div className="composer-chips mood-chips" role="group" aria-label="心情">{moodOptions.map((option) => <button type="button" key={option.value} className={`composer-chip ${draft.mood === option.value && draft.moodSet ? 'selected' : ''}`} aria-pressed={draft.mood === option.value && draft.moodSet} onClick={() => setDraft({ ...draft, mood: option.value, moodSet: true })}>{option.label}</button>)}</div></div>}</div></div>;
  const textArea = <textarea ref={contentRef} className="composer-content" id={inline ? 'inline-content-input' : 'content-input'} rows={inline ? '12' : '10'} maxLength={10000} value={draft.content} onChange={(event) => setDraft({ ...draft, content: event.target.value, contentText: event.target.value })} placeholder={editorType === EDITOR_TYPES.markdown ? '# 今天\n\n写下你的 Markdown 日记……' : '此刻想到什么？先写下来……'} />;
  const editorBody = editorType === EDITOR_TYPES.richText
    ? <RichTextEditor ref={contentRef} value={draft.content} onChange={({ content, contentText }) => setDraft({ ...draft, content, contentText })} className={inline ? 'inline-rich-text' : ''} />
    : editorType === EDITOR_TYPES.markdown
      ? <MarkdownEditor ref={contentRef} value={draft.content} editorKey={inline ? 'inline-draft' : editing ? 'entry-draft' : 'new-draft'} onChange={(content) => setDraft({ ...draft, content, contentText: content })} />
      : textArea;
  const editor = <section className={`composer-dialog ${inline ? 'composer-inline paper-editor' : 'detail-editor'} ${isDragging ? 'is-dragging' : ''}`} role={inline ? 'region' : 'dialog'} aria-modal={inline ? undefined : 'true'} aria-label={editing ? '编辑日记' : '新建日记'} onMouseDown={(event) => event.stopPropagation()} onPaste={handlePaste} onDragEnter={handleDragEnter} onDragLeave={handleDragLeave} onDragOver={handleDragOver} onDrop={handleDrop}>
    <AttachmentDropHint visible={isDragging} shouldAnimate={shouldAnimate} />
    {inline ? <div className="paper-editor-header"><div className="paper-editor-title"><span>写下此刻</span><small>让今天留下一个清晰的片段</small></div><div className="editor-header-actions">{editorModeControl}<DateControl draft={draft} setDraft={setDraft} /></div></div> : <div className="composer-header"><div className="detail-editor-heading"><span>{editing ? '编辑记录' : '新建记录'}</span><span className="editor-type-hint">{editorTypeLabel(editorType)}</span><DateControl draft={draft} setDraft={setDraft} /></div><div className="editor-header-actions">{editorModeControl}{onClose && <IconButton className="icon-only-button" label="关闭" onClick={onClose}><X size={17} /></IconButton>}</div></div>}
    {titleField}
    {editorBody}
    <p className="editor-format-note">{editorType === EDITOR_TYPES.richText ? '格式会以富文本保存，并与手机端同步。' : editorType === EDITOR_TYPES.markdown ? '使用所见即所得编辑，仍以 Markdown 源文保存。' : '适合快速、不带格式地记录。'}</p>
    {controls}
    {attachmentList}
    <footer className="composer-footer"><div className="composer-footer-meta"><span className="composer-note">{inline ? '自动保留在本机' : '内容会先保存到本机 · 支持一天多次记录'}</span><DraftSaveStatus status={draftStatus} /><span className="composer-word-count" aria-live="polite">{contentLength ? `${contentLength} 字` : '尚未开始'}</span></div><div>{!inline && <Button variant="ghost" size="sm" onClick={onClose}>取消</Button>}<Button size="sm" onClick={onSave}>{editing ? '保存修改' : inline ? '记下' : '保存日记'}</Button></div></footer>
  </section>;

  const capture = inline || windowed ? editor : <div className="composer-dialog-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose?.(); }}>{editor}</div>;
  return <>{capture}{previewIndex !== null && <MediaViewer items={attachments.map((path) => ({ path }))} activeIndex={previewIndex} onActiveIndexChange={setPreviewIndex} onClose={() => setPreviewIndex(null)} />}</>;
}
