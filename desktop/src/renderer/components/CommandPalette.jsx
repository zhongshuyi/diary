'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import { BookOpen, CalendarDays, FilePlus2, Images, Moon, RefreshCw, Search, Settings, Sparkles, Sun } from 'lucide-react';
import { motionTokens, useMotionPreference } from '../lib/motion';

export function CommandPalette({ open, theme, onClose, onNew, onSearch, onNavigate, onSync, onToggleTheme }) {
  const [query, setQuery] = useState('');
  const [activeIndex, setActiveIndex] = useState(0);
  const inputRef = useRef(null);
  const { shouldAnimate } = useMotionPreference();

  const actions = useMemo(() => [
    { id: 'new', label: '新建日记', description: '立即开始记录这一刻', shortcut: 'Ctrl N', Icon: FilePlus2, run: onNew },
    { id: 'search', label: '搜索全部记录', description: '按文字、标签或分类查找', shortcut: 'Ctrl K', Icon: Search, run: onSearch },
    { id: 'today', label: '返回今天', description: '回到当前的写作桌面', Icon: BookOpen, run: () => onNavigate('timeline') },
    { id: 'calendar', label: '打开日历', description: '按日期回看记录', Icon: CalendarDays, run: () => onNavigate('calendar') },
    { id: 'media', label: '打开媒体库', description: '浏览照片、视频和音频', Icon: Images, run: () => onNavigate('media') },
    { id: 'insights', label: '查看洞察', description: '回顾记录中的变化', Icon: Sparkles, run: () => onNavigate('insights') },
    { id: 'settings', label: '打开设置', description: '备份、同步与桌面偏好', shortcut: 'Ctrl ,', Icon: Settings, run: () => onNavigate('settings') },
    { id: 'sync', label: '立即同步', description: '将本地变更与服务器同步', Icon: RefreshCw, run: onSync },
    { id: 'theme', label: theme === 'dark' ? '切换浅色模式' : '切换深色模式', description: '调整当前工作区外观', Icon: theme === 'dark' ? Sun : Moon, run: onToggleTheme },
  ], [onNavigate, onNew, onSearch, onSync, onToggleTheme, theme]);

  const matches = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase('zh-CN');
    if (!normalized) return actions;
    return actions.filter((action) => `${action.label} ${action.description}`.toLocaleLowerCase('zh-CN').includes(normalized));
  }, [actions, query]);

  useEffect(() => {
    if (!open) return;
    setQuery('');
    setActiveIndex(0);
    window.requestAnimationFrame(() => inputRef.current?.focus());
  }, [open]);

  useEffect(() => {
    if (activeIndex >= matches.length) setActiveIndex(Math.max(0, matches.length - 1));
  }, [activeIndex, matches.length]);

  useEffect(() => {
    if (!open) return undefined;
    const onKeyDown = (event) => {
      if (event.key === 'Escape') { event.preventDefault(); onClose(); return; }
      if (!matches.length) return;
      if (event.key === 'ArrowDown') { event.preventDefault(); setActiveIndex((index) => (index + 1) % matches.length); }
      if (event.key === 'ArrowUp') { event.preventDefault(); setActiveIndex((index) => (index - 1 + matches.length) % matches.length); }
      if (event.key === 'Enter') { event.preventDefault(); const action = matches[activeIndex]; onClose(); action?.run?.(); }
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [activeIndex, matches, onClose, open]);

  const content = open && <div className="command-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
    <div className="command-palette" role="dialog" aria-modal="true" aria-label="命令面板">
      <div className="command-search"><Search size={18} aria-hidden="true" /><input ref={inputRef} value={query} onChange={(event) => { setQuery(event.target.value); setActiveIndex(0); }} placeholder="搜索命令或页面…" aria-label="搜索命令" /><kbd>Esc</kbd></div>
      <div className="command-results" role="listbox" aria-label="可用命令">
        {matches.length ? matches.map((action, index) => <button key={action.id} type="button" role="option" aria-selected={index === activeIndex} className={`command-result ${index === activeIndex ? 'active' : ''}`} onMouseEnter={() => setActiveIndex(index)} onClick={() => { onClose(); action.run?.(); }}>
          <span className="command-result-icon"><action.Icon size={17} /></span><span className="command-result-copy"><strong>{action.label}</strong><small>{action.description}</small></span>{action.shortcut && <kbd>{action.shortcut}</kbd>}
        </button>) : <div className="command-empty">没有匹配的命令</div>}
      </div>
      <footer className="command-footer"><span><kbd>↑</kbd><kbd>↓</kbd> 选择</span><span><kbd>Enter</kbd> 执行</span></footer>
    </div>
  </div>;

  if (!open || !shouldAnimate) return content;

  return <AnimatePresence>
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: motionTokens.duration.fast, ease: motionTokens.easing.smooth }}>
      <motion.div initial={{ opacity: 0, y: motionTokens.distance.md, scale: motionTokens.scale.press }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: motionTokens.distance.xs, scale: motionTokens.scale.press }} transition={{ duration: motionTokens.duration.normal, ease: motionTokens.easing.smooth }}>
        {content}
      </motion.div>
    </motion.div>
  </AnimatePresence>;
}
