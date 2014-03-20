import x10.util.*;
import x10.lang.Place;
import x10.array.PlaceGroup;
public class comTest1 
{
    public static def init(id:int)
    {
        var A:Array[int] = new Array[int](2);
        //var tot:Array[double] = new Array[double](4);
        var b:int = 0;
        if (id==0) {
            A = new Array[int](2, 0);
            /*A(0) = 0;
            A(1) = 0;
            A(2) = 0;
            A(3) = 0;
            A(4) = 0;
            A(5) = 0;*/
            b=10;
        }
        if (id==1) {
            //A = new Array[int](4);
            A(0) = 10;
            A(1) = 6;
            /*A(2) = 0;
            A(3) = 0;*/
            /*A(0) = 0;
            A(1) = 0;
            A(2) = 0;
            A(3) = 0;*/
            b=20; 
        }
        if (id==2) {
            A = new Array[int](3);
            A(0) = 3;
            A(1) = 6;
            A(2) = 8;
            /*A(2) = 7;
            A(3) = 8 ;
            A(0) = 0;
            A(1) = 0;
            A(2) = 0;
            A(3) = 0;*/
            b = 30;

        }
        if (id==3) {
            // A = new Array[int](30,0);
            A(0) = 7;
            A(1) = 1;
            b = 40;
        }
        return A;
    }
    public static def init_w(id:int)
    {
        var tot:Array[double];
        if (id==3) {
            tot = new Array[double](2,5.0);
        }
        else
        {
            tot = new Array[double](2,5.0);
        }
        return tot;
    }
    public static def sum(A:Array[int])
    {
        var sum:int = 0;
        for (var i:int=0; i<A.size; i++) {
            sum += A(i);
        }
        Console.OUT.println("sum in Function = " + sum);
        return sum;
    }

    public static def main(args:Array[String]) 
    {
        val timer = new Timer();
        var start:Long = timer.milliTime();
 
        // var cd:ComDetect = new ComDetect(); 
        //cd.checkArgs(args);
        
        //var place:Place = new Place();
        var i:int = 0, j:int = 0;
        val p:Array[Place] = new Array[Place](Place.ALL_PLACES); 
        val tt:Team = Team.WORLD;
        //var pg:PlaceGroup = new PlaceGroup();
        val dst_offs:Array[int] = new Array[int](3,0);
        dst_offs(0) = 0;
        dst_offs(1) = 0;
        dst_offs(2) = 2;
        val dst_counts:Array[int] = new Array[int](3);
        dst_counts(0) = 0;
        dst_counts(1) = 2;
        dst_counts(2) = 3;
        val AA:Array[int] = new Array[int](7, 0);
        AA[0] = -1;

        var commStart:Long = Timer.milliTime();
        PlaceGroup.WORLD.broadcastFlat(()=>{
            val role = Runtime.hereInt(); 
        
            val id:int = here.id;
            val cd:comTest1 = new comTest1();
            val A:Array[int] = cd.init(Runtime.hereInt());
            val tot:Array[double] = cd.init_w(Runtime.hereInt());

            tt.gatherv(role, 0, A, 0, A.size, AA, dst_offs, dst_counts);
            

            Console.OUT.println("In Place" + id + ": ");
            Console.OUT.println(A);
            
            if (id==0) 
            {
                Console.OUT.println("In Place" + id + ": ");
                Console.OUT.println("AA::" + AA);    
                AA[0] = -2;
            }                       
        });


        var commEnd:Long = Timer.milliTime();

        val size:Long = AA.size*32;
        val commSize:Long = size/(commEnd - commStart);
        Console.OUT.println("comm: " + commSize + "KB/s");
        
        at(Place.place(0))
        Console.OUT.println("OUT OF PLACEGROUP AA::" + AA);

        var end:Long = timer.milliTime();
        
        Console.OUT.println("All: "+(end-start)+"ms");

    }
}
