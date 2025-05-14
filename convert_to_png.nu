# 带颜色输出的辅助函数
def color [color: string, text: string] { $"(ansi $color)($text)(ansi reset)" }

def to_png [old_path: string, old_format: string] {
    # 生成新路径（自动处理多扩展名情况）
    let new_path = ($old_path | path parse | update extension "png" | path join)

    print (color "green" $"Converting '($old_path)' to '($new_path)'")

    # 使用 ffmpeg 进行格式转换
    ffmpeg -y -i $old_path $new_path

    # 删除旧文件（已备份所以安全）
    rm $old_path | ignore
}

def backup_file [path: string] {
    let backup_path = $"backup/($path)"

    print (color "cyan" $"Backing up '($path)' to '($backup_path)'")

    # 创建目标目录并复制文件
    mkdir ($backup_path | path dirname)
    cp -f $path $backup_path
}

def convert_format [old_format: string] {
    # 递归查找文件（使用显式错误处理）
    let matches = (try {
        glob --depth 100 $"**/*($old_format)"
    } catch { |e|
        print (color "red" $"Glob error: ($e.msg)")
        []
    } | where { |f|
        # 多条件过滤
        (
        ($f | path type) == file
        and
        (
        not (($f | path dirname ) | path split | any { |i| $i == "backup"})
        )
        )
    } )

    # 处理无匹配情况
    if ($matches | is-empty) {
        print (color "yellow" $"No ($old_format) files found in current directory tree")
        return
    }

    # 显示找到的文件列表
    print (color "blue" $"Found ($matches | length) ($old_format) files:")
    $matches | each { |it| print $"  (char -i 0x2022) ($it)" }

    # 执行备份和转换
    $matches | each { |it|
        backup_file $it
        to_png $it $old_format
    }

    print (color "green" $"($old_format) conversion completed ️✅")
}

# 主执行流程
print (color "white" "Starting image conversion workflow...")
convert_format ".webp"
convert_format ".svg"
convert_format ".avif"
print (color "white" "All conversions completed!")
