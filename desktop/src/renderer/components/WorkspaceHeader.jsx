import { CalendarDays, List, Plus, RefreshCw, Search, Settings, Sparkles, Images, PenLine, Tags, Trash2 } from 'lucide-react';
import { shortDateLabel, dateLabel } from '../lib/format';
import { Button } from './ui/Button';

const viewConfig = {
  timeline: { title: '今天', icon: PenLine },
  all: { title: '全部记录', icon: List },
  calendar: { title: '日历', icon: CalendarDays },
  media: { title: '媒体库', icon: Images },
  insights: { title: '洞察', icon: Sparkles },
  tags: { title: '标签', icon: Tags },
  recycle: { title: '回收站', icon: Trash2 },
  settings: { title: '设置', icon: Settings },
};

export function WorkspaceHeader({ view, entryCount, search, onSearch, onSync, onNew, showNew = true }) {
  const config = viewConfig[view] || viewConfig.timeline;
  const Icon = config.icon;
  return <div className="main-topbar"><div className="page-heading"><span className="page-icon"><Icon size={18} /></span><div><h1>{config.title}</h1><p>{view === 'timeline' ? `${dateLabel(new Date())} · ${entryCount} 条记录` : view === 'settings' ? '桌面端工作区偏好与同步配置' : '工作区'}</p></div></div><div className="header-center-search"><Search size={15} /><input id="global-search-input" value={search} onChange={(event) => onSearch(event.target.value)} placeholder="搜索日记…" aria-label="搜索日记" /></div><div className="topbar-actions"><Button variant="outline" size="sm" icon={CalendarDays} className="date-button">{shortDateLabel(new Date())}</Button><Button variant="ghost" size="sm" icon={RefreshCw} className="header-sync" onClick={onSync} title="立即同步">同步</Button>{showNew && <Button size="sm" icon={Plus} className="primary-button" onClick={onNew}>新建日记</Button>}</div></div>;
}
