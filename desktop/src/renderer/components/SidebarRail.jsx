import { CalendarDays, FileImage, PenLine, Settings, Sparkles, Tags, Trash2 } from 'lucide-react';

const navigation = [
  ['timeline', PenLine, '今天'],
  ['calendar', CalendarDays, '日历'],
  ['media', FileImage, '媒体'],
  ['insights', Sparkles, '洞察'],
];

const resources = [
  ['tags', Tags, '标签'],
  ['recycle', Trash2, '回收'],
];

function NavItem({ view, onView, item }) {
  const [key, Icon, label] = item;
  return <button className={`nav-item ${view === key ? 'active' : ''}`} onClick={() => onView(key)} title={label}><Icon size={19} strokeWidth={1.9} /><span>{label}</span></button>;
}

export function SidebarRail({ view, onView, syncKind, syncLabel }) {
  return <aside className="sidebar">
    <nav className="side-nav" aria-label="工作区导航"><p className="nav-label">工作区</p>{navigation.map((item) => <NavItem key={item[0]} view={view} onView={onView} item={item} />)}<p className="nav-label secondary">资料</p>{resources.map((item) => <NavItem key={item[0]} view={view} onView={onView} item={item} />)}</nav>
    <div className="sidebar-bottom"><NavItem view={view} onView={onView} item={['settings', Settings, '设置']} /><div className={`sync-summary ${syncKind}`} title={syncLabel}><span className="sync-dot"></span><span>{syncLabel}</span></div><div className="sidebar-footnote">DESKTOP 0.1</div></div>
  </aside>;
}
