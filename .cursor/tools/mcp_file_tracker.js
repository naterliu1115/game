const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const chokidar = require('chokidar');

class MCPFileTracker {
    constructor() {
        this.contextDir = path.join(__dirname, '../context');
        this.fileChangesPath = path.join(this.contextDir, 'changes/file_changes.json');
        this.projectRoot = path.join(__dirname, '../../');
        this.watcher = null;
        
        // 確保changes目錄存在
        if (!fs.existsSync(path.join(this.contextDir, 'changes'))) {
            fs.mkdirSync(path.join(this.contextDir, 'changes'));
        }
        
        // 初始化或讀取變更記錄
        this.initChangeLog();
    }

    initChangeLog() {
        if (!fs.existsSync(this.fileChangesPath)) {
            const initialContent = {
                version: "1.0",
                lastUpdated: new Date().toISOString(),
                changes: []
            };
            fs.writeFileSync(this.fileChangesPath, JSON.stringify(initialContent, null, 2));
        }
    }

    // 計算檔案的雜湊值
    calculateFileHash(filePath) {
        const content = fs.readFileSync(filePath);
        return crypto.createHash('md5').update(content).digest('hex');
    }

    // 記錄檔案變更
    async recordChange(filePath, changeType, relatedDecision = null, relatedRequirement = null) {
        const changes = JSON.parse(fs.readFileSync(this.fileChangesPath, 'utf8'));
        
        const change = {
            id: `change_${Date.now()}`,
            timestamp: new Date().toISOString(),
            file: filePath,
            type: changeType, // 'create', 'modify', 'delete'
            fileType: path.extname(filePath),
            hash: changeType !== 'delete' ? this.calculateFileHash(filePath) : null,
            relatedDecision,
            relatedRequirement
        };

        changes.changes.push(change);
        changes.lastUpdated = new Date().toISOString();
        
        fs.writeFileSync(this.fileChangesPath, JSON.stringify(changes, null, 2));
        return change;
    }

    // 獲取特定檔案的變更歷史
    async getFileHistory(filePath) {
        const changes = JSON.parse(fs.readFileSync(this.fileChangesPath, 'utf8'));
        return changes.changes.filter(change => change.file === filePath);
    }

    // 獲取特定決策相關的檔案變更
    async getChangesByDecision(decisionId) {
        const changes = JSON.parse(fs.readFileSync(this.fileChangesPath, 'utf8'));
        return changes.changes.filter(change => change.relatedDecision === decisionId);
    }

    // 獲取特定需求相關的檔案變更
    async getChangesByRequirement(requirementId) {
        const changes = JSON.parse(fs.readFileSync(this.fileChangesPath, 'utf8'));
        return changes.changes.filter(change => change.relatedRequirement === requirementId);
    }

    // 獲取特定類型檔案的所有變更
    async getChangesByFileType(fileType) {
        const changes = JSON.parse(fs.readFileSync(this.fileChangesPath, 'utf8'));
        return changes.changes.filter(change => change.fileType === fileType);
    }

    // 監控GameMaker專案檔案
    async watchProjectFiles() {
        const watchPatterns = [
            '**/*.yy',   // GameMaker專案檔
            '**/*.gml',  // GameMaker程式碼
            'sprites/**/*',  // 精靈資源
            'sounds/**/*',   // 音效資源
            'rooms/**/*',    // 房間資源
            'objects/**/*'   // 物件資源
        ].map(pattern => path.join(this.projectRoot, pattern));

        // 配置監控選項
        const watchOptions = {
            ignored: /(^|[\/\\])\../, // 忽略隱藏檔案
            persistent: true,
            ignoreInitial: true,
            awaitWriteFinish: {
                stabilityThreshold: 2000,
                pollInterval: 100
            }
        };

        // 創建監控器
        this.watcher = chokidar.watch(watchPatterns, watchOptions);

        // 監聽檔案事件
        this.watcher
            .on('add', async filePath => {
                console.log(`檔案創建: ${filePath}`);
                await this.handleFileChange(filePath, 'create');
            })
            .on('change', async filePath => {
                console.log(`檔案修改: ${filePath}`);
                await this.handleFileChange(filePath, 'modify');
            })
            .on('unlink', async filePath => {
                console.log(`檔案刪除: ${filePath}`);
                await this.handleFileChange(filePath, 'delete');
            })
            .on('error', error => {
                console.error(`監控錯誤: ${error}`);
            });

        console.log('開始監控檔案變更...');
        return this.watcher;
    }

    // 處理檔案變更
    async handleFileChange(filePath, changeType) {
        try {
            // 獲取當前上下文
            const currentContext = await this.getCurrentContext();
            
            // 記錄變更
            await this.recordChange(
                filePath,
                changeType,
                currentContext?.currentDecision?.id,  // 關聯的決策ID
                currentContext?.currentRequirement?.id  // 關聯的需求ID
            );

            // 發出變更通知
            this.emitChangeNotification(filePath, changeType);

        } catch (error) {
            console.error(`處理檔案變更時發生錯誤: ${error}`);
        }
    }

    // 獲取當前上下文
    async getCurrentContext() {
        try {
            const stateFile = path.join(this.contextDir, '../state/current.json');
            if (fs.existsSync(stateFile)) {
                return JSON.parse(fs.readFileSync(stateFile, 'utf8'));
            }
            return null;
        } catch (error) {
            console.error(`獲取當前上下文時發生錯誤: ${error}`);
            return null;
        }
    }

    // 發出變更通知
    emitChangeNotification(filePath, changeType) {
        const notification = {
            timestamp: new Date().toISOString(),
            file: filePath,
            type: changeType,
            message: `檔案 ${path.basename(filePath)} 已${changeType === 'create' ? '創建' : changeType === 'modify' ? '修改' : '刪除'}`
        };

        // 將通知寫入日誌
        const notificationsPath = path.join(this.contextDir, 'changes/notifications.json');
        try {
            let notifications = [];
            if (fs.existsSync(notificationsPath)) {
                notifications = JSON.parse(fs.readFileSync(notificationsPath, 'utf8'));
            }
            notifications.push(notification);
            fs.writeFileSync(notificationsPath, JSON.stringify(notifications, null, 2));
        } catch (error) {
            console.error(`寫入通知時發生錯誤: ${error}`);
        }

        console.log(`通知: ${notification.message}`);
    }

    // 停止監控
    async stopWatching() {
        if (this.watcher) {
            await this.watcher.close();
            console.log('已停止檔案監控');
        }
    }
}

module.exports = MCPFileTracker; 