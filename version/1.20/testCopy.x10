import x10.util.*;
import x10.lang.*;
import x10.io.File;
import x10.io.FileReader;
import x10.util.Pair;
import x10.util.Random;
import x10.compiler.Pragma;
public class testCopy 
{   
    public static def  main( args:Array[String]) 
    {
        val timer = new Timer();
        //var start:Long = timer.milliTime(); 
            

        var start:Long = timer.milliTime();

        val n = PlaceLocalHandle.make[HashMap[int, double]](Dist.makeUnique(), ()=>new HashMap[int, double]());      



        Console.OUT.println(Place.ALL_PLACES);
        //Console.OUT.println(PlaceGroup.numPlaces());

        finish for(p in Place.places())
        {
            at(p)
            {    val hm = n();
                val r:Random = new Random((here.id+1)*100);
                val size:int = (here.id + 1)*100000;
                Console.OUT.println("Size made in Place:" + here.id + ", " + size);
                while(hm.size() < size)
                {
                hm.put(r.nextInt(size*100000), r.nextDouble());
                }
                /*for(e in hm.entries())
                {
                    Console.OUT.println("key - value = " + e.getKey() + " - " + e.getValue());
                }*/

                
                at(Place.place(0))
                {   val hmm = n();
                    for(e in hm.entries())
                    {   
                        val key = e.getKey();
                        val value = e.getValue();
                        if (hmm.containsKey(key)) 
                        {
                            val oldValue = hmm.get(key);
                            hmm.put(key, value + oldValue.value);       
                        }
                        else   
                            hmm.put(key, value);  
                    }
                    //Console.OUT.println("HMM size==" + hmm.size());
                }
            }
        }

        
        val hmm = n();
        Console.OUT.println("Total size = " + hmm.size());

        val totalNode:ArrayList[int] = new ArrayList[int]();
        for (ee in hmm.entries()) {
            totalNode.add(ee.getKey());
        }

        totalNode.sort();

        var startConvert:Long = timer.milliTime();

        val totalNode_Array:Array[int] = totalNode.toArray();

        var endConvert:Long = timer.milliTime();
        Console.OUT.println( (endConvert - startConvert) +"ms to convert!");
        /*@Pragma(Pragma.FINISH_SPMD) finish
        PlaceGroup.WORLD.broadcastFlat(()=>{

            val a=[1,2,3];

            

            at(here.next())
            {
                Console.OUT.println("In changeable place:");
                a(1) = 5;
                Console.OUT.println(here.id + "::" + a);
            }

            Console.OUT.println(here.id + "::" + a);

        });*/

        //Console.OUT.println("Original: " + a);

       /* @Pragma(Pragma.FINISH_SPMD) finish
        PlaceGroup.WORLD.broadcastFlat(()=>{
            //val team = Team.WORLD;
            val hm = n();
            val r:Random = new Random((here.id+1)*100);
            val size:int = here.id + 1;
            Console.OUT.println("Size made in Place:" + here.id + ", " + size);
            while(hm.size() < size)
            {
            hm.put(r.nextInt(size*10), r.nextDouble());
            }
            for(e in hm.entries())
            {
                Console.OUT.println("key - value = " + e.getKey() + " - " + e.getValue());
            }
            if (here.id!=0) {
                for(e in hm.entries())
                 {
                     at(Place.place(0))
                     {
                         hmTotal.put(e.getKey(), e.getValue());
                         Console.OUT.println("size=" + hmTotal.size());
                     }
                 }
            }
            

            //Console.OUT.println("In " + here.id + " the copy is end");
            //team.barrier(here.id);
            //team.barrier(here.id);
        });*/
           

        var end:Long = timer.milliTime();
        Console.OUT.println("Sort ArrayList: "+(end-start)+"ms");
    }
}
