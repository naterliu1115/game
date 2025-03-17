const MCPQuery = require('../tools/mcp_query');

async function testQueries() {
    console.log('開始測試 MCP 查詢功能...\n');
    const query = new MCPQuery();

    try {
        // 1. 測試對話歷史查詢
        console.log('1. 測試對話歷史查詢');
        const conversations = await query.getConversationHistory({
            topic: 'MCP實現'
        });
        console.log('找到相關對話:', conversations.length, '條');
        console.log('對話主題:', conversations[0].topics);
        console.log('\n');

        // 2. 測試決策查詢
        console.log('2. 測試決策查詢');
        const decisions = await query.getDecisions({
            topic: 'MCP存儲架構設計'
        });
        console.log('找到相關決策:', decisions.length, '條');
        console.log('決策內容:', decisions[0].decision);
        console.log('\n');

        // 3. 測試需求查詢
        console.log('3. 測試需求查詢');
        const requirements = await query.getRequirements({
            status: 'in_progress'
        });
        console.log('找到進行中的需求:', requirements.length, '條');
        console.log('需求標題:', requirements[0].title);
        console.log('\n');

        // 4. 測試進度查詢
        console.log('4. 測試進度查詢');
        const progress = await query.getProgress({
            taskStatus: 'in_progress'
        });
        console.log('當前衝刺:', progress.currentSprint);
        console.log('進行中的任務數:', progress.tasks.length);
        console.log('\n');

        // 5. 測試當前上下文
        console.log('5. 測試當前上下文');
        const context = await query.getCurrentContext();
        console.log('當前對話ID:', context.conversation.id);
        console.log('當前任務:', context.development.currentTask);

    } catch (error) {
        console.error('測試過程中發生錯誤:', error);
    }
}

// 運行測試
testQueries(); 