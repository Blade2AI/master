def task_log_cleanup(params):
    print(f"[EXEC] Cleaning logs older than {params.get('days')} days.")
    return {"success": True, "freed_mb": 120}

def task_security_scan(params):
    print(f"[EXEC] Scanning target {params.get('target')}.")
    return {"success": True, "vulns": 0}

REGISTRY = {
    "log_cleanup": task_log_cleanup,
    "security_scan": task_security_scan
}
