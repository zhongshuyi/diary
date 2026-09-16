import { Check, Folder, Hash, Pencil, Search, Tag, Trash2, X } from 'lucide-react';
import { useMemo, useState } from 'react';

function usageMap(entries, field) {
  const counts = new Map();
  entries.filter((entry) => !entry.isInTrash).forEach((entry) => {
    const latest = Date.parse(entry.occurredAt || entry.updatedAt || entry.createdAt) || 0;
    const values = field === 'tags' ? (entry.tags || []) : [entry.category || '未分类'];
    values.filter(Boolean).forEach((value) => {
      const current = counts.get(value) || { count: 0, latest: 0 };
      current.count += 1;
      current.latest = Math.max(current.latest, latest);
      counts.set(value, current);
    });
  });
  return counts;
}

function sortValues(values, usage) {
  return [...new Set(values.filter(Boolean))].sort((left, right) => {
    const a = usage.get(left) || { count: 0, latest: 0 };
    const b = usage.get(right) || { count: 0, latest: 0 };
    return b.count - a.count || b.latest - a.latest || left.localeCompare(right, 'zh-CN');
  });
}

function TaxonomyCard({ type, name, count, editing, editValue, onEditValue, onStartEdit, onCancelEdit, onCommitEdit, onSelect, onDelete }) {
  if (editing) {
    return <div className="taxonomy-card is-editing">
      <input className="taxonomy-edit-input" value={editValue} onChange={(event) => onEditValue(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') onCommitEdit(); if (event.key === 'Escape') onCancelEdit(); }} aria-label={`重命名${type === 'tag' ? '标签' : '分类'}`} autoFocus />
      <div className="taxonomy-card-actions"><button type="button" className="taxonomy-action confirm" onClick={onCommitEdit} aria-label="保存重命名"><Check size={13} /></button><button type="button" className="taxonomy-action" onClick={onCancelEdit} aria-label="取消重命名"><X size={13} /></button></div>
    </div>;
  }
  return <div className="taxonomy-card">
    <button type="button" className="taxonomy-card-main" onClick={onSelect} aria-label={`筛选${type === 'tag' ? '标签' : '分类'} ${name}`}><span>{type === 'tag' ? <Hash size={14} /> : <Folder size={14} />}{name}</span><strong>{count}</strong><small>条记录</small></button>
    <div className="taxonomy-card-actions"><button type="button" className="taxonomy-action" onClick={onStartEdit} aria-label={`重命名${name}`}><Pencil size={12} /></button><button type="button" className="taxonomy-action danger" onClick={onDelete} aria-label={`删除${name}`}><Trash2 size={12} /></button></div>
  </div>;
}

export function TagsView({ entries, taxonomy, categories = [], onSelect, onSelectCategory, onRenameTag, onDeleteTag, onRenameCategory, onDeleteCategory }) {
  const [query, setQuery] = useState('');
  const [editing, setEditing] = useState(null);
  const [editValue, setEditValue] = useState('');
  const tagUsage = useMemo(() => usageMap(entries, 'tags'), [entries]);
  const categoryUsage = useMemo(() => usageMap(entries, 'category'), [entries]);
  const tagStats = useMemo(() => new Map((taxonomy?.tagStats || []).map((item) => [item.value, item])), [taxonomy]);
  const categoryStats = useMemo(() => new Map((taxonomy?.categoryStats || []).map((item) => [item.value, item])), [taxonomy]);
  const tags = useMemo(() => taxonomy?.tags?.length ? taxonomy.tags : sortValues([...tagUsage.keys()], tagUsage), [taxonomy, tagUsage]);
  const categoryValues = useMemo(() => {
    const usage = new Map(categoryUsage);
    categoryStats.forEach((value, key) => usage.set(key, value));
    return sortValues([...(taxonomy?.categories || categories), '未分类', '生活', '灵感', '心情', '工作'], usage);
  }, [taxonomy, categories, categoryUsage, categoryStats]);
  const normalizedQuery = query.trim().toLowerCase();
  const visibleTags = tags.filter((tag) => !normalizedQuery || tag.toLowerCase().includes(normalizedQuery));
  const visibleCategories = categoryValues.filter((category) => !normalizedQuery || category.toLowerCase().includes(normalizedQuery));

  const startEdit = (type, name) => { setEditing({ type, name }); setEditValue(name); };
  const cancelEdit = () => { setEditing(null); setEditValue(''); };
  const commitEdit = async () => {
    const next = editValue.trim();
    if (!editing || !next || next === editing.name) { cancelEdit(); return; }
    const values = editing.type === 'tag' ? tags : categoryValues;
    if (values.includes(next)) {
      const sourceCount = editing.type === 'tag' ? (tagStats.get(editing.name)?.count ?? tagUsage.get(editing.name)?.count ?? 0) : (categoryStats.get(editing.name)?.count ?? categoryUsage.get(editing.name)?.count ?? 0);
      const targetCount = editing.type === 'tag' ? (tagStats.get(next)?.count ?? tagUsage.get(next)?.count ?? 0) : (categoryStats.get(next)?.count ?? categoryUsage.get(next)?.count ?? 0);
      if (!window.confirm(`“${editing.name}”已存在目标${editing.type === 'tag' ? '标签' : '分类'}“${next}”。确认合并吗？\n${sourceCount} 条记录将并入已有的 ${targetCount} 条记录。`)) return;
    }
    const action = editing.type === 'tag' ? onRenameTag : onRenameCategory;
    try { await action?.(editing.name, next); cancelEdit(); } catch { /* parent presents the error */ }
  };
  const remove = async (type, name) => {
    const kind = type === 'tag' ? '标签' : '分类';
    const count = type === 'tag' ? (tagStats.get(name)?.count ?? tagUsage.get(name)?.count ?? 0) : (categoryStats.get(name)?.count ?? categoryUsage.get(name)?.count ?? 0);
    const detail = type === 'tag' ? `${count} 条关联记录会移除该标签。` : `${count} 条关联记录会改为“未分类”。`;
    if (!window.confirm(`删除${kind}“${name}”？${detail}`)) return;
    try { await (type === 'tag' ? onDeleteTag : onDeleteCategory)?.(name); } catch { /* parent presents the error */ }
  };
  const empty = !visibleTags.length && !visibleCategories.length;
  return <section className="tags-page" aria-label="分类和标签管理">
    <div className="tags-intro"><div className="tags-intro-icon"><Tag size={19} /></div><div><p className="section-kicker">LIBRARY / ORGANIZE</p><h2>分类与标签</h2><p>一次点击即可筛选；重命名和删除只会更新组织关系，不会删除记录。</p></div></div>
    <label className="tags-search"><Search size={14} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="筛选分类或标签…" aria-label="筛选分类或标签" /></label>
    {!normalizedQuery || visibleCategories.length > 0 ? <section className="taxonomy-section"><div className="taxonomy-section-heading"><h3>分类</h3><span>单选 · {visibleCategories.length}</span></div><div className="tags-grid">{visibleCategories.length ? visibleCategories.map((category) => <TaxonomyCard key={category} type="category" name={category} count={categoryStats.get(category)?.count ?? categoryUsage.get(category)?.count ?? 0} editing={editing?.type === 'category' && editing.name === category} editValue={editValue} onEditValue={setEditValue} onStartEdit={() => startEdit('category', category)} onCancelEdit={cancelEdit} onCommitEdit={commitEdit} onSelect={() => onSelectCategory?.(category)} onDelete={() => remove('category', category)} />) : <div className="taxonomy-empty">暂无分类记录</div>}</div></section> : null}
    {!normalizedQuery || visibleTags.length > 0 ? <section className="taxonomy-section"><div className="taxonomy-section-heading"><h3>标签</h3><span>多选 · {visibleTags.length}</span></div><div className="tags-grid">{visibleTags.length ? visibleTags.map((tag) => <TaxonomyCard key={tag} type="tag" name={tag} count={tagStats.get(tag)?.count ?? tagUsage.get(tag)?.count ?? 0} editing={editing?.type === 'tag' && editing.name === tag} editValue={editValue} onEditValue={setEditValue} onStartEdit={() => startEdit('tag', tag)} onCancelEdit={cancelEdit} onCommitEdit={commitEdit} onSelect={() => onSelect?.(tag)} onDelete={() => remove('tag', tag)} />) : <div className="taxonomy-empty">保存记录时添加第一个标签</div>}</div></section> : null}
    {empty && <div className="tags-empty">没有匹配的分类或标签</div>}
  </section>;
}
