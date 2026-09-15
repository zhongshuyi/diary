import { ArrowLeft, Construction } from 'lucide-react';

export function PlaceholderView({ title, description, onBack }) {
  return <div className="placeholder-view"><span className="placeholder-symbol"><Construction size={24} /></span><p className="section-kicker">WORKSPACE / {title.toUpperCase()}</p><h2>{title}</h2><p>{description}</p><button className="outline-button" onClick={onBack}><ArrowLeft size={14} />回到今天</button></div>;
}
