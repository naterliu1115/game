class MCPError extends Error {
    constructor(message, code, details = {}) {
        super(message);
        this.name = 'MCPError';
        this.code = code;
        this.details = details;
        this.timestamp = new Date().toISOString();
    }
}

class MCPErrorHandler {
    constructor() {
        this.errorLog = [];
    }

    // 記錄錯誤
    logError(error) {
        const errorEntry = {
            timestamp: new Date().toISOString(),
            type: error.name || 'Error',
            code: error.code || 'UNKNOWN',
            message: error.message,
            details: error.details || {},
            stack: error.stack
        };

        this.errorLog.push(errorEntry);
        console.error(`[${errorEntry.type}] ${errorEntry.code}: ${errorEntry.message}`);
        
        if (error.details && Object.keys(error.details).length > 0) {
            console.error('詳細信息:', error.details);
        }

        return errorEntry;
    }

    // 獲取錯誤日誌
    getErrorLog() {
        return this.errorLog;
    }

    // 清除錯誤日誌
    clearErrorLog() {
        this.errorLog = [];
    }

    // 創建檔案系統錯誤
    static createFileError(operation, path, originalError) {
        return new MCPError(
            `檔案操作失敗: ${operation}`,
            'FILE_ERROR',
            {
                operation,
                path,
                originalError: originalError.message
            }
        );
    }

    // 創建驗證錯誤
    static createValidationError(field, value, constraint) {
        return new MCPError(
            `驗證失敗: ${field}`,
            'VALIDATION_ERROR',
            {
                field,
                value,
                constraint
            }
        );
    }

    // 創建整合錯誤
    static createIntegrationError(component, action, reason) {
        return new MCPError(
            `整合失敗: ${component}`,
            'INTEGRATION_ERROR',
            {
                component,
                action,
                reason
            }
        );
    }
}

module.exports = {
    MCPError,
    MCPErrorHandler
}; 