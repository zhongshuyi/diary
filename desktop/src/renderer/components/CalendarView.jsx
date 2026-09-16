import { ChevronLeft, ChevronRight, FileImage, PenLine, Plus } from 'lucide-react';
import { dateKey, dateLabel, mediaCount, monthLabel } from '../lib/format';
import { EntryCard } from './EntryCard';

function buildMonthDays(month) {
  const first = new Date(month.getFullYear(), month.getMonth(), 1);
  const mondayOffset = (first.getDay() + 6) % 7;
  return Array.from({ length: 42 }, (_, index) => new Date(month.getFullYear(), month.getMonth(), index - mondayOffset + 1));
}

export function CalendarView({ entries, selectedDate, setSelectedDate, onNew, onEdit, onPreview }) {
  const days = buildMonthDays(selectedDate);
  const selectedKey = dateKey(selectedDate);
  const selectedEntries = entries.filter((entry) => !entry.isInTrash && dateKey(entry.occurredAt || entry.createdAt) === selectedKey).sort((a, b) => new Date(a.occurredAt || a.createdAt) - new Date(b.occurredAt || b.createdAt));
  const monthIndex = selectedDate.getMonth();
  const goMonth = (offset) => setSelectedDate(new Date(selectedDate.getFullYear(), monthIndex + offset, 1));
  return <div className="calendar-layout"><section className="calendar-surface"><div className="calendar-toolbar"><div><p className="section-kicker">YOUR ARCHIVE</p><h2>{monthLabel(selectedDate)}</h2></div><div className="calendar-actions"><button className="icon-only-button" onClick={() => goMonth(-1)} title="上个月"><ChevronLeft size={17} /></button><button className="today-button" onClick={() => setSelectedDate(new Date())}>今天</button><button className="icon-only-button" onClick={() => goMonth(1)} title="下个月"><ChevronRight size={17} /></button></div></div><div className="calendar-weekdays">{['一', '二', '三', '四', '五', '六', '日'].map((day) => <span key={day}>{day}</span>)}</div><div className="calendar-grid">{days.map((day) => { const key = dateKey(day); const dayEntries = entries.filter((entry) => !entry.isInTrash && dateKey(entry.occurredAt || entry.createdAt) === key); const isCurrentMonth = day.getMonth() === monthIndex; const isSelected = key === selectedKey; const isToday = key === dateKey(new Date()); return <button key={key} className={`calendar-cell ${isCurrentMonth ? '' : 'outside'} ${isSelected ? 'selected' : ''} ${isToday ? 'today' : ''}`} onClick={() => setSelectedDate(day)}><span className="calendar-number">{day.getDate()}</span>{dayEntries.length > 0 && <span className="calendar-count">{dayEntries.length}</span>}<span className="calendar-dots">{dayEntries.slice(0, 3).map((entry) => <i className={`dot-${entry.category || '生活'}`} key={entry.id}></i>)}</span></button>; })}</div></section><aside className="calendar-detail"><div className="detail-header"><div><p className="section-kicker">SELECTED DAY</p><h3>{dateLabel(selectedDate)}</h3></div><button className="primary-button icon-label" onClick={() => onNew(selectedDate)}><Plus size={15} />写入这天</button></div><div className="detail-summary"><strong>{selectedEntries.length}</strong><span>条记录</span><span className="detail-summary-divider"></span><FileImage size={14} /><span>{selectedEntries.reduce((total, entry) => total + mediaCount(entry), 0)} 个附件</span></div><div className="selected-entries">{selectedEntries.length ? selectedEntries.map((entry) => <EntryCard key={entry.id} entry={entry} onEdit={onEdit} onPreview={onPreview} />) : <div className="detail-empty"><PenLine size={20} /><p>这一天还没有记录</p><span>把某个瞬间留在这里。</span><button className="text-button" onClick={() => onNew(selectedDate)}>新建第一条 <ChevronRight size={14} /></button></div>}</div></aside></div>;
}
