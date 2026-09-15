import { useEffect, useRef, useState } from 'react';
import { Check, ChevronDown } from 'lucide-react';

export function SelectField({ value, onChange, options, label, className = '' }) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef(null);
  const selected = options.find((option) => (typeof option === 'string' ? option : option.value) === value) || options[0];
  const selectedLabel = typeof selected === 'string' ? selected : selected?.label;

  useEffect(() => {
    const close = (event) => { if (!rootRef.current?.contains(event.target)) setOpen(false); };
    const escape = (event) => { if (event.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', close);
    document.addEventListener('keydown', escape);
    return () => { document.removeEventListener('mousedown', close); document.removeEventListener('keydown', escape); };
  }, []);

  return <div className={`ui-select ${open ? 'open' : ''} ${className}`} ref={rootRef}>
    <button type="button" className="ui-select-trigger" aria-haspopup="listbox" aria-expanded={open} aria-label={label} onClick={() => setOpen(!open)}><span>{selectedLabel}</span><ChevronDown size={14} /></button>
    {open && <div className="ui-select-menu" role="listbox" aria-label={label}>{options.map((option) => { const optionValue = typeof option === 'string' ? option : option.value; const optionLabel = typeof option === 'string' ? option : option.label; return <button type="button" role="option" aria-selected={optionValue === value} className={`ui-select-option ${optionValue === value ? 'selected' : ''}`} key={optionValue} onClick={() => { onChange(optionValue); setOpen(false); }}>{optionValue === value ? <Check size={13} /> : <span className="select-check-space" />}<span>{optionLabel}</span></button>; })}</div>}
  </div>;
}
