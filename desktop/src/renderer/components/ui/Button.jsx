export function Button({ variant = 'primary', size = 'md', icon: Icon, className = '', children, type = 'button', ...props }) {
  return <button type={type} className={`ui-button ui-button-${variant} ui-button-${size} ${className}`} {...props}>{Icon && <Icon size={size === 'sm' ? 14 : 16} strokeWidth={2} />}{children}</button>;
}
