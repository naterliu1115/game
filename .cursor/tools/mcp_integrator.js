const MCPQuery = require('./mcp_query');
const MCPFileTracker = require('./mcp_file_tracker');
const fs = require('fs');
const path = require('path');

class MCPIntegrator {
    constructor() {
        this.query = new MCPQuery();
        this.fileTracker = new MCPFileTracker();
        this.contextDir = path.join(__dirname, '../context');
        
        // 確保所有必要的目錄和文件存在
        this.ensureDirectoriesExist();
        this.ensureFilesExist();
    }

    // 確保必要的目錄存在
    ensureDirectoriesExist() {
        const directories = [
            path.join(this.contextDir, 'changes'),
            path.join(this.contextDir, 'conversations'),
            path.join(this.contextDir, 'decisions'),
            path.join(this.contextDir, 'requirements'),
            path.join(this.contextDir, 'progress')
        ];

        directories.forEach(dir => {
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
        });
    }

    // 確保必要的文件存在
    ensureFilesExist() {
        const files = {
            notifications: path.join(this.contextDir, 'changes/notifications.json'),
            conversations: path.join(this.contextDir, 'conversations/history.json'),
            decisions: path.join(this.contextDir, 'decisions/decisions.json'),
            requirements: path.join(this.contextDir, 'requirements/changes.json'),
            progress: path.join(this.contextDir, 'progress/status.json'),
            state: path.join(this.contextDir, '../state/current.json')
        };

        Object.entries(files).forEach(([key, filePath]) => {
            if (!fs.existsSync(filePath)) {
                const initialContent = this.getInitialContent(key);
                fs.writeFileSync(filePath, JSON.stringify(initialContent, null, 2));
            }
        });
    }

    // 獲取文件的初始內容
    getInitialContent(fileType) {
        const baseContent = {
            version: "1.0",
            lastUpdated: new Date().toISOString()
        };

        switch (fileType) {
            case 'notifications':
                return {
                    ...baseContent,
                    notifications: []
                };
            case 'conversations':
                return {
                    ...baseContent,
                    conversations: []
                };
            case 'decisions':
                return {
                    ...baseContent,
                    decisions: []
                };
            case 'requirements':
                return {
                    ...baseContent,
                    requirements: []
                };
            case 'progress':
                return {
                    ...baseContent,
                    currentSprint: "MCP-Implementation-Sprint-1",
                    milestones: [],
                    tasks: []
                };
            case 'state':
                return {
                    ...baseContent,
                    currentContext: {
                        conversation: null,
                        development: {
                            currentTask: null,
                            activeBranch: "main"
                        }
                    }
                };
            default:
                return baseContent;
        }
    }

    // 初始化整合器
    async initialize() {
        console.log('初始化 MCP 整合器...');
        
        // 啟動檔案監控
        await this.fileTracker.watchProjectFiles();
        
        // 訂閱檔案變更事件
        this.subscribeToFileChanges();
    }

    // 訂閱檔案變更事件
    subscribeToFileChanges() {
        // 監聽檔案變更通知
        const notificationsPath = path.join(this.contextDir, 'changes/notifications.json');
        fs.watch(notificationsPath, async (eventType) => {
            if (eventType === 'change') {
                await this.handleFileChangeNotification();
            }
        });
    }

    // 處理檔案變更通知
    async handleFileChangeNotification() {
        try {
            // 獲取最新的變更通知
            const notificationsPath = path.join(this.contextDir, 'changes/notifications.json');
            const notifications = JSON.parse(fs.readFileSync(notificationsPath, 'utf8'));
            const latestNotification = notifications[notifications.length - 1];

            if (!latestNotification) return;

            // 獲取當前上下文
            const currentContext = await this.fileTracker.getCurrentContext();
            
            // 更新進度狀態
            await this.updateProgress(latestNotification, currentContext);
            
            // 更新決策狀態
            await this.updateDecisions(latestNotification, currentContext);
            
            // 更新需求狀態
            await this.updateRequirements(latestNotification, currentContext);
        } catch (error) {
            console.error('處理檔案變更通知時發生錯誤:', error);
        }
    }

    // 更新進度狀態
    async updateProgress(notification, context) {
        try {
            const progressPath = path.join(this.contextDir, 'progress/status.json');
            const progress = JSON.parse(fs.readFileSync(progressPath, 'utf8'));

            // 更新相關任務的進度
            if (context?.development?.currentTask) {
                const task = progress.tasks.find(t => t.name === context.development.currentTask);
                if (task) {
                    // 根據檔案變更類型更新任務狀態
                    if (notification.type === 'create' || notification.type === 'modify') {
                        task.completion = Math.min(100, task.completion + 10);
                        if (task.completion >= 100) {
                            task.status = 'completed';
                        } else if (task.status === 'pending') {
                            task.status = 'in_progress';
                        }
                    }
                }
            }

            // 更新最後修改時間
            progress.lastUpdated = new Date().toISOString();
            
            // 保存更新
            fs.writeFileSync(progressPath, JSON.stringify(progress, null, 2));
            
        } catch (error) {
            console.error('更新進度狀態時發生錯誤:', error);
        }
    }

    // 更新決策狀態
    async updateDecisions(notification, context) {
        try {
            const decisionsPath = path.join(this.contextDir, 'decisions/decisions.json');
            const decisions = JSON.parse(fs.readFileSync(decisionsPath, 'utf8'));

            // 如果檔案變更與當前決策相關
            if (context?.currentDecision?.id) {
                const decision = decisions.decisions.find(d => d.id === context.currentDecision.id);
                if (decision) {
                    // 更新決策實現狀態
                    decision.status = 'implemented';
                    decision.implementationDetails = {
                        ...decision.implementationDetails,
                        lastFile: notification.file,
                        lastChangeType: notification.type,
                        lastChangeTime: notification.timestamp
                    };
                }
            }

            // 保存更新
            fs.writeFileSync(decisionsPath, JSON.stringify(decisions, null, 2));

        } catch (error) {
            console.error('更新決策狀態時發生錯誤:', error);
        }
    }

    // 更新需求狀態
    async updateRequirements(notification, context) {
        try {
            const requirementsPath = path.join(this.contextDir, 'requirements/changes.json');
            const requirements = JSON.parse(fs.readFileSync(requirementsPath, 'utf8'));

            // 如果檔案變更與當前需求相關
            if (context?.currentRequirement?.id) {
                const requirement = requirements.requirements.find(r => r.id === context.currentRequirement.id);
                if (requirement) {
                    // 更新需求實現進度
                    if (requirement.status === 'pending') {
                        requirement.status = 'in_progress';
                    }
                    requirement.implementation = {
                        ...requirement.implementation,
                        lastFile: notification.file,
                        lastChangeType: notification.type,
                        lastChangeTime: notification.timestamp
                    };
                }
            }

            // 保存更新
            fs.writeFileSync(requirementsPath, JSON.stringify(requirements, null, 2));

        } catch (error) {
            console.error('更新需求狀態時發生錯誤:', error);
        }
    }

    // 停止整合器
    async stop() {
        await this.fileTracker.stopWatching();
        console.log('MCP 整合器已停止');
    }
}

module.exports = MCPIntegrator; 