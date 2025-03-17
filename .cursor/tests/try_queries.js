const MCPQuery = require('../tools/mcp_query');
const fs = require('fs');
const path = require('path');

async function checkFiles() {
    const files = [
        '../context/conversations/history.json',
        '../context/decisions/decisions.json',
        '../context/requirements/changes.json',
        '../context/progress/status.json',
        '../state/current.json'
    ];

    console.log('檢查必要文件...');
    files.forEach(file => {
        const fullPath = path.join(__dirname, file);
        try {
            if (fs.existsSync(fullPath)) {
                console.log(`✓ ${file} 存在`);
                const content = fs.readFileSync(fullPath, 'utf8');
                console.log(`  文件內容: ${content.substring(0, 50)}...`);
            } else {
                console.log(`✗ ${file} 不存在`);
            }
        } catch (error) {
            console.log(`! 檢查 ${file} 時發生錯誤:`, error.message);
        }
    });
    console.log('\n');
}

async function tryDifferentQueries() {
    console.log('===== MCP 查詢功能展示 =====\n');
    
    // 首先檢查文件
    await checkFiles();
    
    const query = new MCPQuery();
    console.log('MCPQuery 實例已創建\n');

    try {
        // 1. 按時間範圍查詢對話
        console.log('1. 嘗試查詢最近一週的對話歷史...');
        const lastWeek = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const recentConversations = await query.getConversationHistory({
            timeRange: {
                start: lastWeek,
                end: new Date()
            }
        });
        console.log('查詢完成。結果：');
        console.log(JSON.stringify(recentConversations, null, 2));
        console.log('\n');

        // 2. 查詢高優先級需求
        console.log('2. 嘗試查詢高優先級需求...');
        const highPriorityReqs = await query.getRequirements({
            priority: 'high',
            status: 'in_progress'
        });
        console.log('查詢完成。結果：');
        console.log(JSON.stringify(highPriorityReqs, null, 2));
        console.log('\n');

        // 3. 查詢特定主題的決策
        console.log('3. 嘗試查詢MCP相關的所有決策...');
        const mcpDecisions = await query.getDecisions({
            topic: 'MCP'
        });
        console.log('查詢完成。結果：');
        console.log(JSON.stringify(mcpDecisions, null, 2));
        console.log('\n');

        // 4. 查詢當前開發狀態
        console.log('4. 嘗試查詢當前開發狀態...');
        const progress = await query.getProgress({});
        console.log('查詢完成。結果：');
        console.log(JSON.stringify(progress, null, 2));
        console.log('\n');
        
        // 5. 獲取當前上下文
        console.log('5. 嘗試獲取當前工作上下文...');
        const currentContext = await query.getCurrentContext();
        console.log('查詢完成。結果：');
        console.log(JSON.stringify(currentContext, null, 2));

    } catch (error) {
        console.error('查詢過程中發生錯誤:', error);
        console.error('錯誤堆疊:', error.stack);
    }
}

// 執行查詢
console.log('開始執行查詢測試...\n');
tryDifferentQueries().catch(error => {
    console.error('程序執行出錯:', error);
    process.exit(1);
}); 