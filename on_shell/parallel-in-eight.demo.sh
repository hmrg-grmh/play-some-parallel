#! /bin/bash


function some_code_runinpar ()
{
    par_num="${1:-8}"
    seq -f%02g 32 |
        xargs -n"$par_num" |
        awk '
        BEGIN{PROCINFO["sorted_in"]="@ind_num_asc"}
        {for(f=1;f<=NF;f++)a[f][NR]=$f}
        END{for(i in a){for(j in a[i]){printf a[i][j]" "};printf"\n"}}' |
        {
            while read linepipe ;
            do
                for elem in $linepipe ;
                do
                    get_some_code $elem ;
                done |
                    some_code_parser --file /dev/stdin |
                    awk '
                    BEGIN{IGNORECASE=1}
                    /error/{print"'"?[$(date +%FT%T.%N%:::z)] :: eids:$line,... :: "'"$0;exit 2}
                    /sths/{printf"> "$0" "}' >&2 &&
                    {
                        echo 'Y:['"$(date +%FT%T.%3N%:::z)"'] eids:'"$line"' - OK !' >&2 ;
                    } ||
                    { 
                        echo 'X:['"$(date +%FT%T.%3N%:::z)"'] error have ! exit !' >&2 ;
                        exit 111 ;
                    } &
            done ;
            wait ;
        } ;
} ;


### 接下来，执行 some_code_runinpar 4 就可以：
### - 指定并发度为4执行 some code
### - 所开启的 parser 的进程数 (或者说打开的连接数) 等于并发度
### - 每个并发内是顺序生成的 some code 被它的 parser 顺序执行
### 其中：
### - some code 可以是易于拼接的某种 dsl 或什么脚本语言的代码
### - some code parser 则是它的解释器

### 下面给出一些简单的示例
### 实际上它们不一定是函数 : 特别是 parser 基本不会是在 SHell 上定义的函数...

## some code eg

get_some_code ()
{
    item_id="$1" ;
    for h in $(seq 24) ;
    do
        echo 'dsl: from id='"$item_id"' add hour='"$h"' with value '"$(some_fn_get_val $h $item_id)" ;
    done ;
} ;

some_code_parser ()
{
    # ....
} ;
