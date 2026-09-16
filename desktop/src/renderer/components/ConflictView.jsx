import { Check, GitCompareArrows } from 'lucide-react';
import { useEffect, useState } from 'react';

function resolveEntry(conflict) {
  return conflict.entry || conflict.serverEntry || {};
}

export function ConflictView({ conflicts = [], onResolve }) {
  const [selected, setSelected] = useState(null);
  const [busy, setBusy] = useState(false);
  useEffect(() => { if (!selected && conflicts.length) setSelected(conflicts[0]); }, [conflicts, selected]);
  if (!conflicts.length) return <div className="empty-state"><GitCompareArrows size={28} /><h3>没有待处理冲突</h3><p>两端离线编辑产生差异时，会在这里保留两个版本。</p></div>;
  const current = selected || conflicts[0];
  const entry = resolveEntry(current);
  const choose = async (resolution) => {
    setBusy(true);
    try { await onResolve(current, resolution); } finally { setBusy(false); }
  };
  return <div className="conflict-layout"><div className="conflict-list">{conflicts.map((item) => <button key={item.conflictId} type="button" className={`conflict-item ${item.conflictId === current.conflictId ? 'active' : ''}`} onClick={() => setSelected(item)}><strong>{item.entry?.title || '无题'}</strong><small>{item.sourceDeviceId || '未知设备'} · {new Date(item.createdAt || Date.now()).toLocaleString()}</small></button>)}</div><section className="conflict-detail"><div className="section-heading"><div><p className="section-kicker">CONFLICT CENTER</p><h2>版本差异</h2></div><span className="status-badge warning">待处理</span></div><div className="conflict-columns"><article><h3>冲突版本</h3><p className="conflict-meta">{current.sourceDeviceId || '未知设备'} · {current.sourceMutationId || '未知 mutation'}</p><h4>{entry.title || '无题'}</h4><p>{entry.contentText || entry.content || '（无正文）'}</p><div className="tag-row">{(entry.tags || []).map((tag) => <span key={tag} className="tag-chip">#{tag}</span>)}</div></article><article><h3>当前主版本</h3><p className="conflict-meta">服务器当前版本</p><h4>{current.serverEntry?.title || '无题'}</h4><p>{current.serverEntry?.contentText || current.serverEntry?.content || '（无正文）'}</p></article></div><div className="conflict-actions"><button type="button" className="outline-button" disabled={busy} onClick={() => choose(current.serverEntry)}>保留主记录</button><button type="button" className="primary-button" disabled={busy} onClick={() => choose(entry)}><Check size={15} />保留冲突版本</button></div></section></div>;
}
