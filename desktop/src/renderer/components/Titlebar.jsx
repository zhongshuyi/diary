import { BookOpen, Minus, Moon, Square, Sun, X } from 'lucide-react';
import { IconButton } from './ui/IconButton';

function WindowButton({ label, className = '', children, onClick }) {
  return <IconButton className={`window-button ${className}`} label={label} onClick={onClick}>{children}</IconButton>;
}

export function Titlebar({ theme, onToggleTheme }) {
  return <header className="titlebar">
    <div className="titlebar-brand" aria-label="此刻">
      <span className="brand-icon"><BookOpen size={16} strokeWidth={2.2} /></span>
      <strong>此刻</strong><span className="brand-divider">/</span><span className="brand-context">个人日记</span>
    </div>
    <div className="titlebar-hint">离线优先 · 记录属于你</div>
    <div className="window-actions">
      <IconButton className="header-action" label={theme === 'dark' ? '切换浅色模式' : '切换暗色模式'} onClick={onToggleTheme}>{theme === 'dark' ? <Sun size={15} /> : <Moon size={15} />}</IconButton>
      <WindowButton label="最小化" className="minimize" onClick={() => window.diaryAPI.window.minimize()}><Minus size={15} /></WindowButton>
      <WindowButton label="最大化" onClick={() => window.diaryAPI.window.maximize()}><Square size={13} /></WindowButton>
      <WindowButton label="关闭" className="close" onClick={() => window.diaryAPI.window.close()}><X size={15} /></WindowButton>
    </div>
  </header>;
}
