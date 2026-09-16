import { Archive, List, Trash2 } from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { EntryCard } from './EntryCard';

const MOOD_OPTIONS = [
  ['', '全部心情'],
  ['0.9', '很好'],
  ['0.7', '平静'],
  ['0.5', '一般'],
  ['0.3', '低落'],
];

function updateFilter(filters, key, value, onChange) {
  onChange({ ...filters, [key]: value });
}

export function SearchFilters({ filters, categories = [], tags = [], onChange, onClear }) {
  const activeCount = Object.values(filters || {}).filter((value) => Array.isArray(value) ? value.length > 0 : Boolean(value)).length;
  const categoryOptions = [...new Set([...categories, '生活', '灵感', '心情', '工作'])];
  const selectedTags = Array.isArray(filters.tags) ? filters.tags : [];
  const visibleTags = [...new Set([...selectedTags, ...tags])].slice(0, 24);
  const toggleTag = (tag) => onChange({ ...filters, tags: selectedTags.includes(tag) ? selectedTags.filter((item) => item !== tag) : [...selectedTags, tag] });
  return <div className="search-filters" aria-label="搜索筛选条件">
    <span className="search-filter-label">筛选</span>
    <div className="filter-chip-group" role="group" aria-label="按分类筛选"><span className="filter-group-label">分类</span><button type="button" className={`filter-chip ${!filters.category ? 'selected' : ''}`} aria-pressed={!filters.category} onClick={() => updateFilter(filters, 'category', '', onChange)}>全部</button>{categoryOptions.map((category) => <button type="button" key={category} className={`filter-chip ${filters.category === category ? 'selected' : ''}`} aria-pressed={filters.category === category} onClick={() => updateFilter(filters, 'category', filters.category === category ? '' : category, onChange)}>{category}</button>)}</div>
    {visibleTags.length > 0 && <div className="filter-chip-group tag-filter-group" role="group" aria-label="按标签筛选"><span className="filter-group-label">标签</span>{visibleTags.map((tag) => <button type="button" key={tag} className={`filter-chip ${selectedTags.includes(tag) ? 'selected' : ''}`} aria-pressed={selectedTags.includes(tag)} onClick={() => toggleTag(tag)}>#{tag}</button>)}</div>}
    <select aria-label="按心情筛选" value={filters.mood || ''} onChange={(event) => updateFilter(filters, 'mood', event.target.value, onChange)}>
      {MOOD_OPTIONS.map(([value, label]) => <option key={value || 'all'} value={value}>{label}</option>)}
    </select>
    <select aria-label="按附件类型筛选" value={filters.attachmentKind || ''} onChange={(event) => updateFilter(filters, 'attachmentKind', event.target.value, onChange)}>
      <option value="">全部附件</option>
      <option value="any">有附件</option>
      <option value="image">图片</option>
      <option value="video">视频</option>
      <option value="audio">音频</option>
    </select>
    <label className="search-filter-check"><input type="checkbox" checked={filters.favorite === true} onChange={(event) => updateFilter(filters, 'favorite', event.target.checked, onChange)} />只看收藏</label>
    <label className="search-filter-date">从 <input type="date" aria-label="开始日期" value={filters.dateFrom || ''} onChange={(event) => updateFilter(filters, 'dateFrom', event.target.value, onChange)} /></label>
    <label className="search-filter-date">至 <input type="date" aria-label="结束日期" value={filters.dateTo || ''} onChange={(event) => updateFilter(filters, 'dateTo', event.target.value, onChange)} /></label>
    {activeCount > 0 && <button type="button" className="search-filter-clear" onClick={onClear}>清除筛选 · {activeCount}</button>}
  </div>;
}

function EmptyRecords({ trash = false }) {
  return <div className="empty-state records-empty">
    <span className="empty-icon">{trash ? <Trash2 size={21} /> : <List size={21} />}</span>
    <strong>{trash ? '回收站是空的' : '还没有历史记录'}</strong>
    <span>{trash ? '移入回收站的内容会在这里保留，避免误删。' : '用右侧编辑区或 Ctrl + Shift + Space 记下第一条。'}</span>
  </div>;
}

export function EntriesView({ entries, hasMore = false, loading = false, searchError = '', search = '', filters, categories, tags, onFiltersChange, onClearFilters, onBatchAction, onLoadMore, onEdit, onPreview, onToggleFavorite, onCopy, onTrash }) {
  const [selectedIds, setSelectedIds] = useState([]);
  useEffect(() => {
    const available = new Set(entries.map((entry) => entry.id));
    setSelectedIds((current) => current.filter((id) => available.has(id)));
  }, [entries]);
  const selectedEntries = useMemo(() => entries.filter((entry) => selectedIds.includes(entry.id)), [entries, selectedIds]);
  const allVisibleSelected = entries.length > 0 && entries.every((entry) => selectedIds.includes(entry.id));
  const allSelectedFavorite = selectedEntries.length > 0 && selectedEntries.every((entry) => entry.isFavorite);
  const categoryOptions = [...new Set([...(categories || []), '生活', '灵感', '心情', '工作'])];
  const tagOptions = [...new Set(tags || [])].slice(0, 18);
  const allSelectedHaveTag = (tag) => selectedEntries.length > 0 && selectedEntries.every((entry) => (entry.tags || []).includes(tag));
  const toggleSelect = (id) => setSelectedIds((current) => current.includes(id) ? current.filter((item) => item !== id) : [...current, id]);
  const toggleSelectAll = () => setSelectedIds(allVisibleSelected ? [] : entries.map((entry) => entry.id));
  const runBatch = async (action) => { if (!selectedIds.length) return; await onBatchAction?.(action, selectedIds); setSelectedIds([]); };
  return <section className="records-page" aria-label="全部记录">
    <div className="records-intro"><div><p className="section-kicker">LIBRARY / ALL RECORDS</p><h2>所有记录</h2><p>按发生时间整理，工作和生活放在同一个资料库里。</p></div><span className="records-count">{entries.length} 条</span></div>
    {entries.length > 0 && <div className={`batch-toolbar ${selectedIds.length ? 'has-selection' : ''}`}><label className="batch-select-all"><input type="checkbox" checked={allVisibleSelected} onChange={toggleSelectAll} aria-label="选择当前列表全部记录" />{selectedIds.length ? `已选 ${selectedIds.length} 条` : '选择记录'}</label>{selectedIds.length > 0 && <><div className="batch-actions"><button type="button" onClick={() => runBatch({ type: 'favorite', value: !allSelectedFavorite })}>{allSelectedFavorite ? '取消收藏' : '收藏'}</button><button type="button" className="danger" onClick={() => runBatch({ type: 'trash' })}>移入回收站</button></div><div className="batch-organize" aria-label="批量分类和标签"><span className="batch-organize-label">分类</span>{categoryOptions.map((category) => <button type="button" key={category} className="batch-chip" onClick={() => runBatch({ type: 'organize', options: { category } })}>{category}</button>)}{tagOptions.length > 0 && <><span className="batch-organize-label">标签</span>{tagOptions.map((tag) => <button type="button" key={tag} className={`batch-chip ${allSelectedHaveTag(tag) ? 'active' : ''}`} onClick={() => runBatch({ type: 'organize', options: allSelectedHaveTag(tag) ? { removeTags: [tag] } : { addTags: [tag] } })}>{allSelectedHaveTag(tag) ? `− #${tag}` : `+ #${tag}`}</button>)}</>}</div></>}</div>}
    {filters && <SearchFilters filters={filters} categories={categories} tags={tags} onChange={onFiltersChange} onClear={onClearFilters} />}
    {searchError && <div className="records-error" role="alert">搜索失败：{searchError}</div>}
    <div className="timeline-list records-list">{entries.length ? entries.map((entry) => <EntryCard key={entry.id} entry={entry} highlightQuery={search} selectable selected={selectedIds.includes(entry.id)} onSelect={toggleSelect} onEdit={onEdit} onPreview={onPreview} onToggleFavorite={onToggleFavorite} onCopy={onCopy} onTrash={onTrash} />) : loading ? <div className="records-loading" role="status">正在查找记录…</div> : <EmptyRecords />}</div>
    {hasMore && <button type="button" className="load-more-button" onClick={onLoadMore} disabled={loading}>{loading ? '加载中…' : '加载更多记录'}</button>}
  </section>;
}

export function RecycleBinView({ entries, search = '', filters, categories, tags, searchError = '', loading = false, hasMore = false, onLoadMore, onFiltersChange, onClearFilters, onEdit, onPreview, onRestore, onDeletePermanent }) {
  return <section className="records-page" aria-label="回收站">
    <div className="records-intro"><div><p className="section-kicker">LIBRARY / TRASH</p><h2>回收站</h2><p>这里的记录不会出现在日常时间线，可恢复或永久删除。</p></div><span className="records-count">{entries.length} 条</span></div>
    <div className="trash-notice"><Archive size={15} /><span>永久删除会立即移除正文、搜索索引和待同步 mutation，无法撤销。</span></div>
    {filters && <SearchFilters filters={filters} categories={categories} tags={tags} onChange={onFiltersChange} onClear={onClearFilters} />}
    {searchError && <div className="records-error" role="alert">搜索失败：{searchError}</div>}
    <div className="timeline-list records-list">{entries.length ? entries.map((entry) => <EntryCard key={entry.id} entry={entry} isTrash highlightQuery={search} onEdit={onEdit} onPreview={onPreview} onRestore={onRestore} onDeletePermanent={onDeletePermanent} />) : loading ? <div className="records-loading" role="status">正在查找记录…</div> : <EmptyRecords trash />}</div>
    {hasMore && <button type="button" className="load-more-button" onClick={onLoadMore} disabled={loading}>{loading ? '加载中…' : '加载更多记录'}</button>}
  </section>;
}
