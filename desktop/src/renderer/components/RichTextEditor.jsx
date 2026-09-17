import { forwardRef, useEffect, useImperativeHandle, useRef } from 'react';
import Quill from 'quill';
import 'quill/dist/quill.snow.css';
import { richTextOps, toRichTextContent } from '../lib/content';

const toolbar = [
  [{ header: [1, 2, 3, false] }],
  ['bold', 'italic', 'underline', 'strike'],
  [{ list: 'ordered' }, { list: 'bullet' }, { indent: '-1' }, { indent: '+1' }],
  ['blockquote', 'code-block', 'link'],
  ['clean'],
];

function editorOps(value) {
  return richTextOps(value) || richTextOps(toRichTextContent(value)) || [{ insert: '\n' }];
}

export const RichTextEditor = forwardRef(function RichTextEditor({ value, onChange, placeholder = '从一个词开始……', className = '' }, ref) {
  const containerRef = useRef(null);
  const quillRef = useRef(null);
  const onChangeRef = useRef(onChange);
  const lastValueRef = useRef('');

  useEffect(() => { onChangeRef.current = onChange; }, [onChange]);
  useImperativeHandle(ref, () => ({ focus: () => quillRef.current?.focus() }), []);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return undefined;
    const editorShell = container.parentElement;
    const removeOwnedToolbars = () => editorShell?.querySelectorAll(':scope > .ql-toolbar').forEach((toolbarElement) => toolbarElement.remove());
    // Quill inserts an array-configured toolbar beside its container, not inside
    // it. Clear both locations so remounts cannot leave a toolbar behind.
    removeOwnedToolbars();
    container.replaceChildren();
    const quill = new Quill(container, { theme: 'snow', placeholder, modules: { toolbar } });
    quillRef.current = quill;
    const initial = editorOps(value);
    const serialized = JSON.stringify(initial);
    quill.setContents(initial, 'silent');
    lastValueRef.current = serialized;
    const handleChange = () => {
      const content = JSON.stringify(quill.getContents().ops);
      lastValueRef.current = content;
      onChangeRef.current?.({ content, contentText: quill.getText().replace(/\n$/, '') });
    };
    quill.on('text-change', handleChange);
    return () => {
      quill.off('text-change', handleChange);
      quillRef.current = null;
      container.replaceChildren();
      removeOwnedToolbars();
    };
  }, []);

  useEffect(() => {
    const quill = quillRef.current;
    if (!quill) return;
    const next = editorOps(value);
    const serialized = JSON.stringify(next);
    if (serialized === lastValueRef.current) return;
    quill.setContents(next, 'silent');
    lastValueRef.current = serialized;
  }, [value]);

  return <div className={`rich-text-editor ${className}`.trim()} ref={containerRef} />;
});
