# row-field - awk
awk 'BEGIN{PROCINFO["sorted_in"]="@ind_num_asc"}{for(f=1;f<=NF;f++)a[f][NR]=$f}END{for(i in a){for(j in a[i]){printf a[i][j]" "};printf"\n"}}'

# test
seq -f%02g 32 | xargs -n8
seq -f%02g 32 | xargs -n8 | awk 'BEGIN{PROCINFO["sorted_in"]="@ind_num_asc"}{for(f=1;f<=NF;f++)a[f][NR]=$f}END{for(i in a){for(j in a[i]){printf a[i][j]" "};printf"\n"}}'

# fmt
seq -f%02g 32 |
    xargs -n8 |
    awk '
    BEGIN{PROCINFO["sorted_in"]="@ind_num_asc"}
    {for(f=1;f<=NF;f++)a[f][NR]=$f}
    END{for(i in a){for(j in a[i]){printf a[i][j]" "};printf"\n"}}'

# fmt2
seq -f%02g 32 |
    xargs -n8 |
    awk '
    BEGIN{
        PROCINFO["sorted_in"] = "@ind_num_asc" ;
    }
    {
        for (f = 1 ; f <= NF ; f++)
        {
            a[f][NR] = $f ;
        } ;
    }
    END{
        for (i in a)
        {
            for (j in a[i])
            {
                printf (a[i][j]" ") ;
            } ;
            printf ("\n") ;
        } ;
    }'


### 这是个 demo 
### 用 awk 行列转换

### 转换思路：二维数组两个下标反过来。
### 最简单的一个理解途径就是：
### 在 `# fmt2` 下面的 `a[f][NR] = $f` 如果换成 `a[NR][f] = $f` 的话，
### 输出就会和 `seq -f%02g 32 | xargs -n8` 一个样了。

### 我在 SHell 的并发的思路就是：
### 先制造队列，再依据队列执行。
### 该思路参考了 Scala 里的并发集合思想。

### 对于 `seq -f%02g 32 | xargs -n8` ：
### 我打算定义：一行就是一个队列，每行同时执行。
### 那么，如果想让 `xargs -n8` 里的数字能直接和并发度一一对应，
### 需要的就是这个行列转换了。
