const MCPFileTracker = require('../tools/mcp_file_tracker');
const fs = require('fs');
const path = require('path');

async function testFileTracker() {
    console.log('===== 測試檔案追蹤功能 =====\n');
    
    const tracker = new MCPFileTracker();
    
    try {
        // 1. 測試初始化
        console.log('1. 檢查初始化...');
        const changesPath = path.join(__dirname, '../context/changes/file_changes.json');
        if (fs.existsSync(changesPath)) {
            console.log('✓ 變更記錄檔案已創建');
            const content = JSON.parse(fs.readFileSync(changesPath, 'utf8'));
            console.log('初始內容:', JSON.stringify(content, null, 2));
        }
        console.log('\n');

        // 2. 測試記錄檔案變更
        console.log('2. 測試記錄檔案變更...');
        // 創建測試檔案
        const testFilePath = path.join(__dirname, 'test.gml');
        fs.writeFileSync(testFilePath, '// 測試GML檔案');
        
        const change = await tracker.recordChange(
            testFilePath,
            'create',
            'dec_001',  // 關聯決策ID
            'req_001'   // 關聯需求ID
        );
        console.log('記錄的變更:', JSON.stringify(change, null, 2));
        console.log('\n');

        // 3. 測試獲取檔案歷史
        console.log('3. 測試獲取檔案歷史...');
        const history = await tracker.getFileHistory(testFilePath);
        console.log('檔案變更歷史:', JSON.stringify(history, null, 2));
        console.log('\n');

        // 4. 測試按決策查詢變更
        console.log('4. 測試按決策查詢變更...');
        const decisionChanges = await tracker.getChangesByDecision('dec_001');
        console.log('決策相關變更:', JSON.stringify(decisionChanges, null, 2));
        console.log('\n');

        // 5. 測試按檔案類型查詢變更
        console.log('5. 測試按檔案類型查詢變更...');
        const gmlChanges = await tracker.getChangesByFileType('.gml');
        console.log('GML檔案變更:', JSON.stringify(gmlChanges, null, 2));

        // 清理測試檔案
        fs.unlinkSync(testFilePath);
        
    } catch (error) {
        console.error('測試過程中發生錯誤:', error);
        console.error('錯誤堆疊:', error.stack);
    }
}

// 執行測試
console.log('開始檔案追蹤測試...\n');
testFileTracker().catch(error => {
    console.error('程序執行出錯:', error);
    process.exit(1);
}); 