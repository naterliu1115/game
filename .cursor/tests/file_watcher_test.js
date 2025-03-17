const MCPFileTracker = require('../tools/mcp_file_tracker');
const fs = require('fs');
const path = require('path');

async function testFileWatcher() {
    console.log('===== 測試檔案監控功能 =====\n');
    
    const tracker = new MCPFileTracker();
    const testDir = path.join(__dirname, 'test_files');
    
    try {
        // 創建測試目錄
        if (!fs.existsSync(testDir)) {
            fs.mkdirSync(testDir);
        }

        // 開始監控
        console.log('開始監控檔案...');
        await tracker.watchProjectFiles();

        // 模擬檔案操作
        console.log('\n1. 測試檔案創建...');
        const testFile = path.join(testDir, 'test.gml');
        fs.writeFileSync(testFile, '// 測試GML檔案');
        await new Promise(resolve => setTimeout(resolve, 2500));

        console.log('\n2. 測試檔案修改...');
        fs.appendFileSync(testFile, '\n// 新增的內容');
        await new Promise(resolve => setTimeout(resolve, 2500));

        console.log('\n3. 測試檔案刪除...');
        fs.unlinkSync(testFile);
        await new Promise(resolve => setTimeout(resolve, 2500));

        // 檢查通知
        console.log('\n4. 檢查變更通知...');
        const notificationsPath = path.join(__dirname, '../context/changes/notifications.json');
        if (fs.existsSync(notificationsPath)) {
            const notifications = JSON.parse(fs.readFileSync(notificationsPath, 'utf8'));
            console.log('變更通知:', JSON.stringify(notifications, null, 2));
        }

        // 停止監控
        console.log('\n5. 停止檔案監控...');
        await tracker.stopWatching();

        // 清理測試目錄
        fs.rmdirSync(testDir);
        
    } catch (error) {
        console.error('測試過程中發生錯誤:', error);
        console.error('錯誤堆疊:', error.stack);
    }
}

// 執行測試
console.log('開始檔案監控測試...\n');
testFileWatcher().catch(error => {
    console.error('程序執行出錯:', error);
    process.exit(1);
}); 