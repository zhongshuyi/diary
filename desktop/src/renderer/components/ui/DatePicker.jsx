import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { CalendarDays, ChevronLeft, ChevronRight } from 'lucide-react';
import { dateKey } from '../../lib/format';

const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

function toLocalDate(value) {
  const date = value ? new Date(`${value}T12:00:00`) : new Date();
  return Number.isNaN(date.getTime()) ? new Date() : date;
}

function monthTitle(date) {
  return new Intl.DateTimeFormat('zh-CN', { year: 'numeric', month: 'long' }).format(date);
}

export function DatePicker({ value, onChange, className = '' }) {
  const rootRef = useRef(null);
  const triggerRef = useRef(null);
  const popoverRef = useRef(null);
  const [open, setOpen] = useState(false);
  const [month, setMonth] = useState(() => toLocalDate(value));
  const [popoverPosition, setPopoverPosition] = useState({ top: -9999, left: -9999 });
  const selected = toLocalDate(value);
  const selectedKey = dateKey(selected);
  const todayKey = dateKey(new Date());

  useEffect(() => {
    const closeOnOutside = (event) => {
      if (!rootRef.current?.contains(event.target) && !popoverRef.current?.contains(event.target)) setOpen(false);
    };
    const closeOnEscape = (event) => {
      if (event.key === 'Escape') setOpen(false);
    };
    document.addEventListener('mousedown', closeOnOutside);
    document.addEventListener('keydown', closeOnEscape);
    return () => {
      document.removeEventListener('mousedown', closeOnOutside);
      document.removeEventListener('keydown', closeOnEscape);
    };
  }, []);

  useLayoutEffect(() => {
    if (!open) return undefined;
    const positionPopover = () => {
      const trigger = triggerRef.current?.getBoundingClientRect();
      if (!trigger) return;
      const popover = popoverRef.current;
      const width = popover?.offsetWidth || 244;
      const height = popover?.offsetHeight || 286;
      const gap = 7;
      const edge = 12;
      const left = Math.max(edge, Math.min(trigger.right - width, window.innerWidth - width - edge));
      const below = trigger.bottom + gap;
      const above = trigger.top - height - gap;
      const top = below + height <= window.innerHeight - edge || above < edge ? Math.min(below, window.innerHeight - height - edge) : above;
      setPopoverPosition({ top, left });
    };
    positionPopover();
    window.addEventListener('resize', positionPopover);
    window.addEventListener('scroll', positionPopover, true);
    return () => {
      window.removeEventListener('resize', positionPopover);
      window.removeEventListener('scroll', positionPopover, true);
    };
  }, [open]);

  const first = new Date(month.getFullYear(), month.getMonth(), 1);
  const startOffset = (first.getDay() + 6) % 7;
  const days = Array.from({ length: 42 }, (_, index) => new Date(month.getFullYear(), month.getMonth(), index - startOffset + 1));
  const moveMonth = (offset) => setMonth(new Date(month.getFullYear(), month.getMonth() + offset, 1));
  const selectDay = (day) => {
    onChange(dateKey(day));
    setMonth(new Date(day.getFullYear(), day.getMonth(), 1));
    setOpen(false);
  };

  const popover = open && typeof document !== 'undefined' ? createPortal(<div ref={popoverRef} className="date-picker-popover" role="dialog" aria-label="选择日期" style={popoverPosition}>
    <div className="date-picker-heading"><button type="button" aria-label="上个月" onClick={() => moveMonth(-1)}><ChevronLeft size={15} /></button><strong>{monthTitle(month)}</strong><button type="button" aria-label="下个月" onClick={() => moveMonth(1)}><ChevronRight size={15} /></button></div>
    <div className="date-picker-weekdays">{weekdays.map((day) => <span key={day}>{day}</span>)}</div>
    <div className="date-picker-days">{days.map((day) => {
      const key = dateKey(day);
      const outside = day.getMonth() !== month.getMonth();
      return <button type="button" key={key} className={`${outside ? 'outside ' : ''}${key === selectedKey ? 'selected ' : ''}${key === todayKey ? 'today ' : ''}`} onClick={() => selectDay(day)} aria-pressed={key === selectedKey}>{day.getDate()}</button>;
    })}</div>
  </div>, document.body) : null;

  return <div className={`date-picker ${className}`} ref={rootRef}>
    <button ref={triggerRef} type="button" className="date-picker-trigger" aria-haspopup="dialog" aria-expanded={open} onClick={() => setOpen(!open)}>
      <CalendarDays size={14} /><span>{value || '选择日期'}</span>
    </button>
    {popover}
  </div>;
}
