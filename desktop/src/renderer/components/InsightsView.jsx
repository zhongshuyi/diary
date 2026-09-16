import { BookOpen, FileImage, PenLine, Sparkles } from 'lucide-react';
import { dateKey, mediaCount } from '../lib/format';

export function InsightsView({ entries }) {
  const active = entries.filter((entry) => !entry.isInTrash);
  const today = active.filter((entry) => dateKey(entry.occurredAt || entry.createdAt) === dateKey(new Date()));
  const words = active.reduce((total, entry) => total + (entry.contentText || '').length, 0);
  const images = active.reduce((total, entry) => total + mediaCount(entry), 0);
  const categories = [...new Set(active.map((entry) => entry.category || '生活'))].map((category) => ({ category, count: active.filter((entry) => (entry.category || '生活') === category).length })).sort((a, b) => b.count - a.count);
  return <div className="insights-page"><div className="insights-intro"><div><p className="section-kicker">A QUIET LOOK BACK</p><h2>洞察</h2><p>不评价生活，只帮你看见已经发生的部分。</p></div><span className="insight-mark"><Sparkles size={19} /></span></div><div className="insight-metrics"><div className="insight-metric"><PenLine size={17} /><span>今天记录</span><strong>{today.length}</strong></div><div className="insight-metric"><BookOpen size={17} /><span>累计文字</span><strong>{words}</strong></div><div className="insight-metric"><FileImage size={17} /><span>图片附件</span><strong>{images}</strong></div></div><div className="insight-columns"><section className="insight-panel"><div className="panel-title"><h3>记录分类</h3><span>{categories.length} 个</span></div>{categories.length ? categories.map((item) => <div className="category-bar" key={item.category}><div><span>{item.category}</span><strong>{item.count}</strong></div><div className="bar-track"><i style={{ width: `${Math.max(8, item.count / active.length * 100)}%` }}></i></div></div>) : <div className="panel-empty">写下几条记录后，这里会出现你的节奏。</div>}</section><section className="insight-panel quote-panel"><Sparkles size={18} /><h3>留给自己的一句话</h3><p>{active[0]?.contentText || '没有哪一个瞬间太小，不值得被认真记住。'}</p></section></div></div>;
}
