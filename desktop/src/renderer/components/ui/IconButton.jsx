export function IconButton({ label, className = '', children, type = 'button', ...props }) {
  return <button type={type} className={`ui-icon-button ${className}`} title={label} aria-label={label} {...props}>{children}</button>;
}
