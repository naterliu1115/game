const MCPIntegrator = require('../tools/mcp_integrator');
const { MCPErrorHandler } = require('../tools/mcp_error_handler');
const fs = require('fs');
const path = require('path');

class TestResult {
    constructor() {
        this.total = 0;
        this.passed = 0;
        this.failed = 0;
        this.errors = [];
    }

    addResult(name, passed, error = null) {
        this.total++;
        if (passed) {
            this.passed++;
            console.log(`✓ ${name} 通過`);
        } else {
            this.failed++;
            console.log(`✗ ${name} 失敗${error ? ': ' + error.message : ''}`);
            if (error) {
                this.errors.push({ name, error });
            }
        }
    }

    printSummary() {
        console.log('\n===== 測試結果摘要 =====');
        console.log(`總計: ${this.total} 測試`);
        console.log(`通過: ${this.passed} 測試`);
        console.log(`失敗: ${this.failed} 測試`);
        
        if (this.failed > 0) {
            console.log('\n失敗的測試:');
            this.errors.forEach(({ name, error }) => {
                console.log(`- ${name}:`);
                console.log(`  錯誤: ${error.message}`);
                if (error.details) {
                    console.log(`  詳細信息:`, error.details);
                }
            });
        }
    }

    isAllPassed() {
        return this.failed === 0;
    }
}

async function validateFileOperation(result, filePath, operation, expectedExists) {
    const exists = fs.existsSync(filePath);
    const testName = `檔案${operation}驗證`;
    
    if (exists === expectedExists) {
        result.addResult(testName, true);
        return true;
    } else {
        result.addResult(testName, false, new Error(
            `檔案${expectedExists ? '應該存在' : '不應該存在'}: ${filePath}`
        ));
        return false;
    }
}

async function validateJsonContent(result, filePath, validator) {
    const testName = `JSON內容驗證: ${path.basename(filePath)}`;
    
    try {
        const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        const validationResult = validator(content);
        
        if (validationResult === true) {
            result.addResult(testName, true);
            return true;
        } else {
            result.addResult(testName, false, new Error(validationResult));
            return false;
        }
    } catch (error) {
        result.addResult(testName, false, error);
        return false;
    }
}

async function testIntegrator() {
    console.log('===== 測試 MCP 整合器 =====\n');
    
    const result = new TestResult();
    const integrator = new MCPIntegrator();
    const testDir = path.join(__dirname, 'test_files');
    const errorHandler = new MCPErrorHandler();
    
    try {
        // 1. 測試初始化
        console.log('1. 測試初始化...');
        if (!fs.existsSync(testDir)) {
            fs.mkdirSync(testDir);
        }
        result.addResult('創建測試目錄', true);

        // 2. 測試整合器初始化
        console.log('\n2. 測試整合器初始化...');
        await integrator.initialize();
        
        // 驗證必要文件是否存在
        const requiredFiles = [
            '../context/changes/notifications.json',
            '../context/conversations/history.json',
            '../context/decisions/decisions.json',
            '../context/requirements/changes.json',
            '../context/progress/status.json',
            '../state/current.json'
        ];

        for (const file of requiredFiles) {
            await validateFileOperation(
                result,
                path.join(__dirname, file),
                '初始化',
                true
            );
        }

        // 3. 測試檔案操作
        console.log('\n3. 測試檔案操作...');
        const testFile = path.join(testDir, 'test.gml');
        
        // 測試創建檔案
        fs.writeFileSync(testFile, '// 測試GML檔案');
        await validateFileOperation(result, testFile, '創建', true);
        await new Promise(resolve => setTimeout(resolve, 2500));

        // 測試修改檔案
        fs.appendFileSync(testFile, '\n// 新增的內容');
        await validateFileOperation(result, testFile, '修改', true);
        await new Promise(resolve => setTimeout(resolve, 2500));

        // 測試刪除檔案
        fs.unlinkSync(testFile);
        await validateFileOperation(result, testFile, '刪除', false);
        await new Promise(resolve => setTimeout(resolve, 2500));

        // 4. 驗證整合結果
        console.log('\n4. 驗證整合結果...');
        
        // 驗證進度更新
        await validateJsonContent(
            result,
            path.join(__dirname, '../context/progress/status.json'),
            content => {
                if (!content.tasks || !Array.isArray(content.tasks)) {
                    return '進度文件格式無效';
                }
                return true;
            }
        );

        // 驗證決策更新
        await validateJsonContent(
            result,
            path.join(__dirname, '../context/decisions/decisions.json'),
            content => {
                if (!content.decisions || !Array.isArray(content.decisions)) {
                    return '決策文件格式無效';
                }
                return true;
            }
        );

        // 驗證需求更新
        await validateJsonContent(
            result,
            path.join(__dirname, '../context/requirements/changes.json'),
            content => {
                if (!content.requirements || !Array.isArray(content.requirements)) {
                    return '需求文件格式無效';
                }
                return true;
            }
        );

        // 5. 停止整合器
        console.log('\n5. 停止整合器...');
        await integrator.stop();
        result.addResult('停止整合器', true);

        // 清理測試目錄
        fs.rmdirSync(testDir);
        result.addResult('清理測試目錄', true);
        
    } catch (error) {
        errorHandler.logError(error);
        result.addResult('整體測試', false, error);
    }

    // 輸出測試結果摘要
    result.printSummary();
    return result.isAllPassed();
}

// 執行測試
console.log('開始 MCP 整合器測試...\n');
testIntegrator().then(passed => {
    process.exit(passed ? 0 : 1);
}).catch(error => {
    console.error('程序執行出錯:', error);
    process.exit(1);
}); 