import { Check, Database, ExternalLink, Keyboard, RefreshCw, Server, Settings2, Sparkles } from 'lucide-react';
import { useEffect, useState } from 'react';

export function SettingsView({ serverUrl, setServerUrl, onSave, attachmentHealth, onExportBackup, onImportBackup }) {
  const [quickCaptureStatus, setQuickCaptureStatus] = useState({ label: 'Ctrl + Shift + Space', registered: true });
  const [shortcut, setShortcut] = useState('Ctrl + Shift + Space');
  const [shortcutError, setShortcutError] = useState('');
  const [syncToken, setSyncToken] = useState('');
  const [updateEndpoint, setUpdateEndpoint] = useState('');
  const [updateState, setUpdateState] = useState({ status: 'idle', message: '未检查', result: null });

  useEffect(() => {
    const result = globalThis.diaryAPI?.quickCapture?.status?.();
    if (result) result.then((status) => {
      if (status) {
        setQuickCaptureStatus(status);
        setShortcut(status.label || shortcut);
      }
    }).catch(() => {});
  }, []);

  useEffect(() => {
    const load = globalThis.diaryAPI?.db?.snapshot;
    if (!load) return undefined;
    let active = true;
    load().then((snapshot) => {
      if (!active) return;
      const settings = snapshot?.settings || {};
      if (typeof settings.syncToken === 'string') setSyncToken(settings.syncToken);
      if (typeof settings.updateEndpoint === 'string') setUpdateEndpoint(settings.updateEndpoint);
    }).catch(() => {});
    return () => { active = false; };
  }, []);

  const saveShortcut = async () => {
    const result = await globalThis.diaryAPI?.quickCapture?.setShortcut?.(shortcut);
    if (!result) return;
    setQuickCaptureStatus(result);
    if (result.label) setShortcut(result.label);
    setShortcutError(result.error || '');
  };

  const checkForUpdate = async () => {
    const action = globalThis.diaryAPI?.updates?.check;
    if (!action) {
      setUpdateState({ status: 'error', message: '桌面运行时可用', result: null });
      return;
    }
    if (!updateEndpoint.trim()) {
      setUpdateState({ status: 'error', message: '请先填写公开更新地址', result: null });
      return;
    }
    setUpdateState({ status: 'checking', message: '检查中…', result: null });
    try {
      const response = await action(updateEndpoint);
      if (!response?.ok) throw new Error(response?.error?.message || '检查更新失败');
      const result = response.data;
      setUpdateState({ status: result?.hasUpdate ? 'available' : 'latest', message: result?.hasUpdate ? `发现新版本 ${result.latestVersion}` : '当前已是最新版本', result });
    } catch (error) {
      setUpdateState({ status: 'error', message: error.message || '检查更新失败', result: null });
    }
  };

  const openUpdate = () => {
    const url = updateState.result?.downloadUrl;
    if (url) void globalThis.diaryAPI?.updates?.open?.(url);
  };

  const healthLabel = attachmentHealth
    ? `${attachmentHealth.ready} 个可用${attachmentHealth.missing ? ` · ${attachmentHealth.missing} 个缺失` : ''}${attachmentHealth.orphaned ? ` · ${attachmentHealth.orphaned} 个待清理` : ''}`
    : '检查中…';

  return <div className="settings-layout">
    <div className="settings-intro">
      <span className="settings-icon"><Settings2 size={19} /></span>
      <div><p className="section-kicker">APPLICATION / SETTINGS</p><h2>设置</h2><p>桌面端的工作区、同步和记录习惯都在这里。</p></div>
    </div>
    <div className="settings-list">
      <label className="setting-row">
        <span className="setting-label"><Server size={17} /><span><strong>同步服务地址</strong><small>用于受保护的日记与附件同步。</small></span></span>
        <input className="text-input" value={serverUrl} onChange={(event) => setServerUrl(event.target.value)} />
      </label>
      <label className="setting-row">
        <span className="setting-label"><Server size={17} /><span><strong>同步访问令牌</strong><small>仅随同步请求发送，不会用于检查更新。</small></span></span>
        <input className="text-input" type="password" autoComplete="off" value={syncToken} onChange={(event) => setSyncToken(event.target.value)} />
      </label>
      <label className="setting-row">
        <span className="setting-label"><RefreshCw size={17} /><span><strong>公开更新地址</strong><small>仅用于读取版本信息和打开下载链接。</small></span></span>
        <input className="text-input" value={updateEndpoint} onChange={(event) => setUpdateEndpoint(event.target.value)} />
      </label>
      <div className="setting-row">
        <span className="setting-label"><RefreshCw size={17} /><span><strong>应用更新</strong><small>当前版本 {globalThis.diaryAPI?.appVersion || 'preview'}</small></span></span>
        <div className="update-setting-control"><span className={`status-badge ${updateState.status === 'error' ? 'warning' : updateState.status === 'idle' ? 'muted' : ''}`}>{updateState.message}</span><button className="outline-button compact" type="button" onClick={checkForUpdate} disabled={updateState.status === 'checking'}>{updateState.status === 'checking' ? '检查中…' : '检查更新'}</button>{updateState.result?.hasUpdate && <button className="outline-button compact" type="button" onClick={openUpdate}><ExternalLink size={13} />前往下载</button>}{updateState.result?.hasUpdate && updateState.result.notes && <small className="setting-update-notes">{updateState.result.notes}</small>}</div>
      </div>
      <div className="setting-row"><span className="setting-label"><Database size={17} /><span><strong>数据策略</strong><small>先保存到本机，再在网络可用时同步</small></span></span><span className="status-badge"><Check size={12} />离线优先</span></div>
      <div className="setting-row"><span className="setting-label"><Database size={17} /><span><strong>附件状态</strong><small>附件复制到应用数据目录，并通过哈希记录完整性</small></span></span><span className={`status-badge ${attachmentHealth?.missing ? 'warning' : ''}`}>{attachmentHealth?.missing ? '需要检查 · ' : ''}{healthLabel}</span></div>
      <div className="setting-row"><span className="setting-label"><Database size={17} /><span><strong>备份与恢复</strong><small>导出正文、回收站、标签、分类和附件；导入时先预览并合并</small></span></span><div className="setting-action-group"><button className="outline-button compact" type="button" onClick={onExportBackup}>导出备份</button><button className="outline-button compact" type="button" onClick={onImportBackup}>导入备份</button></div></div>
      <div className="setting-row"><span className="setting-label"><Sparkles size={17} /><span><strong>系统级速记</strong><small>{quickCaptureStatus.label} 唤起独立窗口，保存后恢复此前焦点</small></span></span><div className="shortcut-setting-control"><input className="text-input shortcut-input" value={shortcut} onChange={(event) => { setShortcut(event.target.value); setShortcutError(''); }} aria-label="系统级速记快捷键" /><button className="outline-button compact" type="button" onClick={saveShortcut}>应用</button>{shortcutError && <small className="setting-error">{shortcutError}</small>}</div></div>
      <div className="setting-row"><span className="setting-label"><Keyboard size={17} /><span><strong>编辑快捷键</strong><small>Ctrl + N 新建，Ctrl + Enter 保存，Esc 关闭编辑器</small></span></span><span className="status-badge muted">已启用</span></div>
    </div>
    <button className="primary-button compact" onClick={() => onSave({ syncToken, updateEndpoint })}>保存设置</button>
  </div>;
}
