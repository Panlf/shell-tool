# 设置控制台编码为 UTF-8，防止字符编码问题
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 定义根目录
$rootDir = "C:\Data\CodeProject"

# 定义需要排除的目录前缀
$excludedDirs = @(
    "C:\Data\CodeProject\fronted"
)

# 初始化计数器
$count = 0

# 递归查找 pom.xml 并检查内容，自动跳过无效路径
Get-ChildItem -Path $rootDir -Recurse -File -Include "pom.xml" -ErrorAction SilentlyContinue | Where-Object {
    # 排除指定目录
    $isExcluded = $false
    foreach ($dir in $excludedDirs) {
        if ($_.FullName.StartsWith($dir)) {
            $isExcluded = $true
            break
        }
    }
    -not $isExcluded
} | ForEach-Object {
    # 更新计数器
    $count++
    
    # 生成当前处理信息
    $currentMessage = "Processed $count files"
       
    # 在原位置刷新显示处理计数，确保完全覆盖旧内容
    Write-Host -NoNewLine "`r$currentMessage"
    
    # 检查文件是否包含 ebean
    if (Select-String -Path $_.FullName -Pattern "ebean" -Quiet) {
        # 输出符合条件的文件路径
        Write-Output "`n**Found ebean: $($_.FullName)**"
    }
}

# 完成后输出总结
Write-Output "`n`nScan completed, processed $count files."