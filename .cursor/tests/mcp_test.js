const fs = require('fs');
const path = require('path');

// 測試結果統計
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

// 測試配置
const TEST_CONFIG = {
    contextDir: '../context',
    stateFile: '../state/current.json',
    testCases: [
        {
            name: '測試對話歷史記錄',
            file: 'conversations/history.json',
            checks: ['version', 'conversations[0].id', 'conversations[0].messages']
        },
        {
            name: '測試決策追蹤',
            file: 'decisions/decisions.json',
            checks: ['decisions[0].topic', 'decisions[0].status']
        },
        {
            name: '測試需求變更',
            file: 'requirements/changes.json',
            checks: ['requirements[0].title', 'requirements[0].status']
        },
        {
            name: '測試進度監控',
            file: 'progress/status.json',
            checks: ['currentSprint', 'tasks[0].completion']
        }
    ]
};

// 輔助函數：格式化輸出
function printHeader(text) {
    console.log('\n' + '='.repeat(50));
    console.log(text);
    console.log('='.repeat(50) + '\n');
}

function printResult(name, passed, details = '') {
    totalTests++;
    if (passed) {
        passedTests++;
        console.log(`✓ 通過: ${name}`);
        if (details) console.log(`  詳情: ${details}`);
    } else {
        failedTests++;
        console.log(`✗ 失敗: ${name}`);
        if (details) console.log(`  錯誤: ${details}`);
    }
}

// 測試函數
function runTests() {
    printHeader('開始 MCP 系統測試');
    
    // 測試文件存在性和內容
    TEST_CONFIG.testCases.forEach(testCase => {
        const filePath = path.join(__dirname, TEST_CONFIG.contextDir, testCase.file);
        printHeader(testCase.name);
        
        try {
            const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
            printResult('文件格式檢查', true, '文件存在且格式正確');
            
            // 檢查必要字段
            testCase.checks.forEach(check => {
                try {
                    const value = check.split('.').reduce((obj, key) => {
                        if (key.includes('[')) {
                            const arrayKey = key.split('[')[0];
                            const index = parseInt(key.split('[')[1]);
                            return obj[arrayKey][index];
                        }
                        return obj[key];
                    }, data);
                    
                    if (value !== undefined) {
                        printResult(
                            `檢查字段 ${check}`, 
                            true, 
                            `值: ${JSON.stringify(value)}`
                        );
                    } else {
                        printResult(
                            `檢查字段 ${check}`, 
                            false, 
                            '字段不存在'
                        );
                    }
                } catch (error) {
                    printResult(
                        `檢查字段 ${check}`, 
                        false, 
                        error.message
                    );
                }
            });
        } catch (error) {
            printResult('文件檢查', false, error.message);
        }
    });
    
    // 測試狀態文件
    printHeader('測試當前狀態');
    try {
        const statePath = path.join(__dirname, TEST_CONFIG.stateFile);
        const stateData = JSON.parse(fs.readFileSync(statePath, 'utf8'));
        
        printResult('檢查版本', true, `版本: ${stateData.version}`);
        printResult('檢查更新時間', true, `最後更新: ${stateData.lastUpdated}`);
        printResult(
            '檢查當前任務', 
            true, 
            `任務: ${stateData.currentContext.development.currentTask}`
        );
    } catch (error) {
        printResult('狀態文件檢查', false, error.message);
    }
    
    // 輸出總結
    printHeader('測試結果總結');
    console.log(`總測試數: ${totalTests}`);
    console.log(`通過: ${passedTests}`);
    console.log(`失敗: ${failedTests}`);
    console.log(`通過率: ${((passedTests/totalTests)*100).toFixed(2)}%`);
}

// 運行測試
runTests(); 