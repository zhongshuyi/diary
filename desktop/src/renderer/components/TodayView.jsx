import { PenLine } from 'lucide-react';
import { dateKey, dateLabel } from '../lib/format';
import { EntryCard } from './EntryCard';
import { QuickCapture } from './QuickCapture';

export function TodayView({ entries, onEdit, onPreview, onToggleFavorite, onCopy, onTrash, composer }) {
  const todayKey = dateKey(new Date());
  const today = entries
    .filter((entry) => !entry.isInTrash && dateKey(entry.occurredAt || entry.createdAt) === todayKey)
    .sort((left, right) => new Date(left.occurredAt || left.createdAt) - new Date(right.occurredAt || right.createdAt));

  return <div className="writing-desk">
    <section className="stream-pane" aria-label="今天的时间轴">
      <header className="stream-header">
        <div>
          <p className="stream-date">{dateLabel(new Date())}</p>
          <h1>今天</h1>
        </div>
        <span className="stream-count">{today.length.toString().padStart(2, '0')} 条记录</span>
      </header>
      <div className="stream-intro"><PenLine size={15} /><span>从早到晚，发生过的都在这里。</span></div>
      <div className="timeline-list">{today.length ? today.map((entry) => <EntryCard key={entry.id} entry={entry} onEdit={onEdit} onPreview={onPreview} onToggleFavorite={onToggleFavorite} onCopy={onCopy} onTrash={onTrash} />) : <div className="empty-state"><span className="empty-icon"><PenLine size={21} /></span><strong>今天还没有记录</strong><span>右侧已经为你留好第一段空白。</span></div>}</div>
    </section>
    <aside className="editor-pane" aria-label="快速记录">
      {composer && <QuickCapture {...composer} inline />}
    </aside>
  </div>;
}
