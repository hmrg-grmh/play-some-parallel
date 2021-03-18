# simple demo

```bash
seq 32 | xargs -n8 | while read linep ; do for e in $linep ; do { sleep $e ; echo $e ; } & done | cat ; done | awk '{print"queue-par: "$0}'
### 顺序执行几个小组 组内并发
```

```bash
seq 32 | xargs -n8 | while read linep ; do for e in $linep ; do { sleep $e ; echo $e ; } ; done & done | awk '{print"par-queue: "$0}'
### 并发执行几个小组 组内顺序
```

第一个的 `8` 就是并发度但第二个的不是

不过第二个的好处在于打开进程的次数等于并发度：第一个只能确保同时打开的进程在给定并发度以内

因此:

- 第一个的执行情况会是：有8个进程，有7个进程，有6个，...，有1个，又有8个，...
- 第一个的执行情况会是：一直有32/8个进程，每个进程里不停地 loop ...

有一个结合二者优点的方案，即把 `seq 32 | xargs -n8` 的输出进行一下行列转换。

详情和使用示例见下文。


# desc

我在 SHell 的并发的思路就是：先制造队列，再依据队列执行。

该思路参考了 Scala 里的并发集合思想:

```scala
(1 to 32).par
         .map(x => s"""hi number. $x !""")
         .foreach(println) ;
```

## par collection

### simple

```bash
seq -f%02g 32 ;
```

out:

```
01
02
...
32
```

可以把它设想为*一维数组*

### line is collection

```bash
seq -f%02g 32 | xargs -n8 ;
```

out:

```
01 02 03 04 05 06 07 08
09 10 11 12 13 14 15 16
17 18 19 20 21 22 23 24
25 26 27 28 29 30 31 32
```

这个可以设想为*二维数组*，也就是**数组的元素还是数组**

即此处的一行回头要在一个局部再转为一竖条

### row <--> field

但是如果想在 `xargs -n8` 的地方就直接用这个数字控制并发度的话，就需要行列转换一下。

这里用 `awk` 的数组转换：

```bash
seq -f%02g 32 |
    xargs -n8 |
    awk '
    BEGIN{PROCINFO["sorted_in"]="@ind_num_asc"} # 有序数组 more see: https://blog.linux-code.com/articles/thread-1304.html
    {for(f=1;f<=NF;f++)a[f][NR]=$f} # 这里的 a[f][NR] 换成 a[NR][f] 就没有转换效果了
    END{for(i in a){for(j in a[i]){printf a[i][j]" "};printf"\n"}}' ;
```

更多见： [awk-rows-fields.demo.sh](./awk-rows-fields.demo.sh)

out:

```
01 09 17 25
02 10 18 26
03 11 19 27
04 12 20 28
05 13 21 29
06 14 22 30
07 15 23 31
08 16 24 32
```

然后，就可以***一行是一个队列、八个队列同时执行***了。

## par run use collection

### how to par

```bash
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
```

然后执行 `some_code_runinpar 4` 就好了。没有那个 `4` 就是默认八并发。

在这里：

- 指定并发度为4执行 some code
- 所开启的 parser 的进程数 (或者说打开的连接数) 等于并发度
- 每个并发内是顺序生成的 some code 被它的 parser 顺序执行

里头有两条 `SHell` 上不会为你提前准备好的命令。二者的位置是上述代码投入应用的关键：

- `get_some_code`: 用于在接受参数后，*标准输出***对应的***代码*
- `some_code_parser`: 用于通过*匿名管道*读取*标准输入*的内容并解释它们


更多见： [parallel-in-eight.demo.sh](./parallel-in-eight.demo.sh)


### some code eg

可以假定已经存在像这样的定义：

```bash
# some code 生成器
get_some_code ()
{
    item_id="$1" ;
    for h in $(seq 24) ;
    do
        echo 'dsl: from id='"$item_id"' add hour='"$h"' with value '"$(some_fn_get_val $h $item_id)" ;
    done ;
} ;
### 这只是一个可以用的示例

### 只是说具体这部分代码的话
### 在 some_code_runinpar 内换个位置可以有更简洁的写法 (即用 awk 代替掉循环体)

# some code 解释器
some_code_parser ()
{
    # ....
} ;
### parser 我就不给出定义示例了 ...
```

其中：

- some code 可以是易于拼接的某种 dsl 或什么脚本语言的代码
- some code parser 则是它的解释器
- *副作用*方面：
  
  - `get_some_code` 完全没必要有副作用
    (此处*标准输出*和*标准错误*都不算副作用,不然SHell上没法返回*256以内数字*以外的信息了)
  - `some_code_parser` 随意
    (比如sql的话在*增*/*删*/*改*上就有副作用)

需要注意的是：

这只是一些简单的示例。需要注意的是，实际上它们完全不必一定得是函数：
特别是 `parser` ，也就是 `some code` 这种*语言*的*解释器*，它应该是最不可能是在 SHell 上就能定义的了吧... (当然我不是说绝对不可能:万一是把啥封装了呢...)

总之，这部分的意思就是，之后会用到 `get_some_code` 和 `some_code_parser` 这两个命令，而这部分只是简单说下它们都是有着**哪类**功能。


# simple demo 2

一个简单的可用示例

```bash
get_some_code ()
{
    for i in $(seq "$1") ;
    do
        echo "sleep $1 ; echo '[$i/$((10#$1))]: $1 in [$2] , sleep time: $((10#$1))s'" ;
    done ;
} ;

some_code_parser ()
{
    bash ${1:-/dev/stdin} ;
} ;
```

```bash
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
                    get_some_code $elem "$linepipe" ;
                done |
                    some_code_parser /dev/stdin &
            done ;
            wait ;
        } ;
} ;

some_code_runinpar 4 ;
```

或者，下面这个就是把 `{ ... & done ; wait ; }` 换成了 `... & done | cat`

它也有一定的阻塞效果，但仅仅在后台进程有标准输出的时候才有效果。

好处是退出进程就会杀死后台。但是在部分情况下(尚未确定对这种情况的描述)，下面这个做法的打印效果并不理想，即不会按照预定时间进入日志。

```bash
function some_code_runinpar ()
{
    par_num="${1:-8}"
    seq -f%02g 32 |
        xargs -n"$par_num" |
        awk '
        BEGIN{PROCINFO["sorted_in"]="@ind_num_asc"}
        {for(f=1;f<=NF;f++)a[f][NR]=$f}
        END{for(i in a){for(j in a[i]){printf a[i][j]" "};printf"\n"}}' |
        while read linepipe ;
        do
            for elem in $linepipe ;
            do
                get_some_code $elem "$linepipe" ;
            done |
                some_code_parser /dev/stdin &
        done | cat ;
} ;

some_code_runinpar 4 ;
```



