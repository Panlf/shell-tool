$java11 = "D:\Programme\Java\Java11"
$java8 = "D:\Programme\Java\Java8\jdk"
$current_java_path = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine')
if ($current_java_path -eq $java8) {
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $java11, 'Machine')
} else {
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $java8, 'Machine')
}
