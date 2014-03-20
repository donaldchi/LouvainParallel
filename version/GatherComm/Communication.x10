import x10.util.*;
import x10.lang.*;
import x10.io.File;
import x10.io.FileReader;
import x10.util.Pair;
import x10.util.Random;
import org.scalegraph.util.*;
import example.TeamExample;
import org.scalegraph.util.tuple.*;


public class Communication 
{   

    public def init(id:int)
    {   
        var mem:MemoryChunk[Pair[int,int]] = new MemoryChunk[Pair[int,int]](5);
        var r:Random = new Random((id+10)*5);
        for (var i:int=0; i<5; i++) 
        {
             mem(i) = new Pair(r.nextInt(30), r.nextInt(20));
        }
        return mem;
    }

    public static def main( args:Array[String]) 
    {
        val timer = new Timer();
        var start:Long = timer.milliTime();

        val t:Team = Team.WORLD;
        val tt:Team2 = new Team2(t);
        val memT:MemoryChunk[Pair[int,int]] = new MemoryChunk[Pair[int,int]](15);
        
        PlaceGroup.WORLD.broadcastFlat(()=>{
            val role = Runtime.hereInt(); 
            val id:int = here.id;
            //val mem:MemoryChunk[int]new MemoryChunk[int](5);
            val comm:Communication = new Communication();
            val mem = comm.init(id);

            /*if (id==0) 
            {
                mem = new MemoryChunk[int](5);
            }
            else
            {
                mem = comm.init();
                Console.OUT.println("In Place" + id + ": ");
                Console.OUT.println(mem);
            }*/

            
            
            tt.gather(0,mem, memT);
            Console.OUT.println("In Place" + id + ": ");
            Console.OUT.println(mem);
            

            if (id==0) 
            {
                Console.OUT.println("Result:: Place" + id + ": ");
                Console.OUT.println(memT);
                /*for (var i:int=0; i<30; i++) 
                {
                    Console.OUT.println(mem(i));        
                } */   
            }

            //tt.gatherv(id, 0, A, 0, A.size, A, 0, A.size);                        
        
        });

        var end:Long = timer.milliTime();
        Console.OUT.println("Used:: "+(end-start)+"ms");

    }
}