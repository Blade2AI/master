export interface LogEntry {
    timestamp: Date;
    level: 'info' | 'warn' | 'error';
    message: string;
    context?: string;
}

export interface AuditLog {
    id: string;
    userId: string;
    action: string;
    timestamp: Date;
    details?: Record<string, any>;
}