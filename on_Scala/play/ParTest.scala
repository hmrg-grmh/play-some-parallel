package play

object ParTest extends App
{
    (1 to 9).toList.zip(11 to 19)
            .par
            .foreach(println)
    
    println("----------")
    
    ((1 to 9).toList.par zip (11 to 19).toList.par)
        .foreach(println)
}
