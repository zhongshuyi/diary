import { forwardRef, useCallback, useEffect, useImperativeHandle, useRef } from 'react';
import { Editor, defaultValueCtx, rootCtx } from '@milkdown/core';
import { clipboard } from '@milkdown/plugin-clipboard';
import { cursor } from '@milkdown/plugin-cursor';
import { history } from '@milkdown/plugin-history';
import { listener, listenerCtx } from '@milkdown/plugin-listener';
import { commonmark } from '@milkdown/preset-commonmark';
import { gfm } from '@milkdown/preset-gfm';
import { Milkdown, MilkdownProvider, useEditor } from '@milkdown/react';
import { nord } from '@milkdown/theme-nord';
import { replaceAll } from '@milkdown/utils';

function MarkdownEditorInner({ value, onChange, editorKey = 'markdown' }, ref) {
  const hostRef = useRef(null);
  const onChangeRef = useRef(onChange);
  const valueRef = useRef(String(value || ''));
  const lastValueRef = useRef(String(value || ''));
  const applyingValueRef = useRef(false);

  useEffect(() => { onChangeRef.current = onChange; }, [onChange]);
  useEffect(() => { valueRef.current = String(value || ''); }, [value]);

  const editorFactory = useCallback((root) => {
    hostRef.current = root;
    return Editor.make()
      .config((ctx) => {
        ctx.set(rootCtx, root);
        ctx.set(defaultValueCtx, valueRef.current);
        ctx.get(listenerCtx).markdownUpdated((_, markdown) => {
          if (applyingValueRef.current) return;
          lastValueRef.current = markdown;
          onChangeRef.current?.(markdown);
        });
      })
      .config(nord)
      .use(commonmark)
      .use(gfm)
      .use(history)
      .use(listener)
      .use(clipboard)
      .use(cursor);
  }, [editorKey]);

  const { loading, get: getEditor } = useEditor(editorFactory, [editorKey]);

  useEffect(() => {
    const nextValue = String(value || '');
    const editor = getEditor();
    if (!editor || nextValue === lastValueRef.current) return;
    applyingValueRef.current = true;
    editor.action(replaceAll(nextValue));
    lastValueRef.current = nextValue;
    window.requestAnimationFrame(() => { applyingValueRef.current = false; });
  }, [getEditor, value]);

  useImperativeHandle(ref, () => ({ focus: () => hostRef.current?.querySelector('.ProseMirror')?.focus() }), []);

  return <div className="milkdown-editor"><Milkdown />{loading && <div className="milkdown-loading" role="status">正在载入 Markdown 编辑器…</div>}</div>;
}

const MarkdownEditorInnerWithRef = forwardRef(MarkdownEditorInner);

export const MarkdownEditor = forwardRef(function MarkdownEditor(props, ref) {
  return <MilkdownProvider><MarkdownEditorInnerWithRef {...props} ref={ref} /></MilkdownProvider>;
});
