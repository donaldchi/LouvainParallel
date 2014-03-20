import x10.util.*;
import x10.lang.*;
import x10.io.File;
import x10.io.FileReader;
import x10.util.Pair;
import x10.util.Random;

public class Communication 
{   
    public static def map()
    {

    }

    public static def shuffle()
    {

    }

    public static def reduce()
    {

    }

    public static def makeData(comm:HashMap,size:int)
    {
        val r:Random = new Random(size);

    }

    public static def main( args:Array[String]) 
    {
        val timer = new Timer();
        var start:Long = timer.milliTime();
        


        var end:Long = timer.milliTime();
        Console.OUT.println("Sort: "+(end-start)+"ms");

    }
}