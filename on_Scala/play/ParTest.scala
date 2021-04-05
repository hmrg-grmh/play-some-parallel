package play

object ParTest extends App
{
    (1 to 4).toList.zip(11 to 14)
            .par
            .foreach(println)
    
    println("----------")
    
    ((1 to 4).toList.par zip (11 to 14).toList.par)
        .foreach(println)
    
    
    println("----------")
    
    
    val x : scala.collection.parallel.immutable.ParSeq[Int] = (1 to 4).toList.par
    val xx : scala.collection.parallel.immutable.ParRange = (1 to 4).par
    
    (xx zip xx) foreach println
}
