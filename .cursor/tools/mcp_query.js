const fs = require('fs');
const path = require('path');

class MCPQuery {
    constructor() {
        this.contextDir = path.join(__dirname, '../context');
        this.stateFile = path.join(__dirname, '../state/current.json');
    }

    // 查詢對話歷史
    async getConversationHistory(options = {}) {
        const { id, topic, timeRange } = options;
        const historyPath = path.join(this.contextDir, 'conversations/history.json');
        const history = JSON.parse(fs.readFileSync(historyPath, 'utf8'));
        
        let results = history.conversations;
        
        if (id) {
            results = results.filter(conv => conv.id === id);
        }
        
        if (topic) {
            results = results.filter(conv => conv.topics.includes(topic));
        }
        
        if (timeRange) {
            const { start, end } = timeRange;
            results = results.filter(conv => {
                const convTime = new Date(conv.startTime);
                return (!start || convTime >= new Date(start)) && 
                       (!end || convTime <= new Date(end));
            });
        }
        
        return results;
    }

    // 查詢決策記錄
    async getDecisions(options = {}) {
        const { topic, status, timeRange } = options;
        const decisionsPath = path.join(this.contextDir, 'decisions/decisions.json');
        const decisions = JSON.parse(fs.readFileSync(decisionsPath, 'utf8'));
        
        let results = decisions.decisions;
        
        if (topic) {
            results = results.filter(dec => dec.topic.includes(topic));
        }
        
        if (status) {
            results = results.filter(dec => dec.status === status);
        }
        
        if (timeRange) {
            const { start, end } = timeRange;
            results = results.filter(dec => {
                const decTime = new Date(dec.timestamp);
                return (!start || decTime >= new Date(start)) && 
                       (!end || decTime <= new Date(end));
            });
        }
        
        return results;
    }

    // 查詢需求變更
    async getRequirements(options = {}) {
        const { title, status, priority } = options;
        const requirementsPath = path.join(this.contextDir, 'requirements/changes.json');
        const requirements = JSON.parse(fs.readFileSync(requirementsPath, 'utf8'));
        
        let results = requirements.requirements;
        
        if (title) {
            results = results.filter(req => req.title.includes(title));
        }
        
        if (status) {
            results = results.filter(req => req.status === status);
        }
        
        if (priority) {
            results = results.filter(req => req.priority === priority);
        }
        
        return results;
    }

    // 查詢開發進度
    async getProgress(options = {}) {
        const { milestone, taskStatus } = options;
        const progressPath = path.join(this.contextDir, 'progress/status.json');
        const progress = JSON.parse(fs.readFileSync(progressPath, 'utf8'));
        
        let results = {
            currentSprint: progress.currentSprint,
            milestones: progress.milestones,
            tasks: progress.tasks
        };
        
        if (milestone) {
            results.milestones = results.milestones.filter(m => m.name.includes(milestone));
        }
        
        if (taskStatus) {
            results.tasks = results.tasks.filter(t => t.status === taskStatus);
        }
        
        return results;
    }

    // 獲取當前上下文
    async getCurrentContext() {
        const stateData = JSON.parse(fs.readFileSync(this.stateFile, 'utf8'));
        return stateData.currentContext;
    }
}

// 導出查詢類
module.exports = MCPQuery; 