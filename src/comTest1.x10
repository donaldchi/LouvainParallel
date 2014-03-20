import x10.util.*;
import x10.lang.Place;
import x10.array.PlaceGroup;
import x10.compiler.*;

public class comTest1 
{
    //val BUFF =  PlaceLocalHandle.make[ArrayList[int]](Dist.makeUnique(), ()=>new ArrayList[int]());
    public def this(){ }

    public  def init(id:int)
    {
        var A:Array[int] = new Array[int](2);
        //var tot:Array[double] = new Array[double](4);
        var b:int = 0;
        if (id==0) {
            A = new Array[int](7, 0);
            b=10;
        }
        if (id==1) {
            A = new Array[int](3);
            A(0) = 10;
            A(1) = 6;
            b=20; 
        }
        if (id==2) {
            A = new Array[int](5);
            A(0) = 3;
            A(1) = 6;
            A(2) = 8;
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
    public  def init_w(id:int)
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
    public  def sum(A:Array[int])
    {
        var sum:int = 0;
        for (var i:int=0; i<A.size; i++) {
            sum += A(i);
        }
        //Console.OUT.println("sum in Function = " + sum);
        return sum;
    }

    public static def main(args:Array[String]) 
    {
        val timer = new Timer();
        var start:Long = timer.milliTime();
 
        var i:int = 0, j:int = 0;
        //val p:Array[Place] = new Array[Place](Place.ALL_PLACES); 
        val AA:Array[int] = new Array[int](1000000, 0); 
        //var pg:PlaceGroup = new PlaceGroup();
        val dst_offs:Array[int] = new Array[int](3,0);
        dst_offs(0) = 0;
        dst_offs(1) = 0;
        dst_offs(2) = 0;
        val dst_counts:Array[int] = new Array[int](3);
        dst_counts(0) = AA.size;
        dst_counts(1) = AA.size;
        dst_counts(2) = AA.size;
        

        val random:Random = new Random();
        for ( i=0; i<AA.size; i++) {
            AA(i) = random.nextInt();
           // Console.OUT.println(AA(i));
        }
        val refAA = new GlobalRef[Array[Int]](AA);
        val refDst_offs = new GlobalRef[Array[Int]](dst_offs);
        val refDst_counts = new GlobalRef[Array[Int]](dst_counts);
        //val buf = BUFF();
        val moves:int = 0;

        var commStart:Long = Timer.milliTime();

        PlaceGroup.WORLD.broadcastFlat(()=>{

            val tt:Team = Team.WORLD;
            val role = Runtime.hereInt(); 
        
            val id:int = here.id;
            val cd:comTest1 = new comTest1();
            //val A:Array[int] = cd.init(Runtime.hereInt());
            //val tot:Array[double] = cd.init_w(Runtime.hereInt());

            val A:Array[int] = new Array[int](AA.size, 0);

             tt.scatterv(here.id, 0, (here == refAA.home) ? refAA.getLocalOrCopy() : null, (here == refAA.home) ? refDst_offs.getLocalOrCopy() : null,
             (here == refAA.home) ? refDst_counts.getLocalOrCopy() : null, A, 0, A.size );
            //tt.scatterv(here.id, 0, (here == refAA.home) ? refAA.getLocalOrCopy() : null, 0, A, 0, A.size);

            Console.OUT.println("Place, sum::" + here.id + ", " + cd.sum(A));

            // if (here.id !=0 ) 
            //     tt.gatherv(role, 0, A, 0, A.size, (here == refAA.home) ? refAA.getLocalOrCopy() : null, dst_offs, dst_counts);
            // else
            //     tt.gatherv(role, 0, A, 0, A.size, (here == refAA.home) ? refAA.getLocalOrCopy() : null, dst_offs, dst_counts);
               
        });

        var commEnd:Long = Timer.milliTime();
        Console.OUT.println("scatter::" + (commEnd - commStart) + " ms");

        var commStart1:Long = Timer.milliTime();

        PlaceGroup.WORLD.broadcastFlat(()=>{

            val cd:comTest1 = new comTest1();
            Console.OUT.println("sum::" + cd.sum(AA));
               
        });

        var commEnd1:Long = Timer.milliTime();
        Console.OUT.println("Reference::" + (commEnd1 - commStart1) + " ms" );

        val size:Long = AA.size*4;
        val commSize:Long = size/(commEnd - commStart);
        Console.OUT.println("Transfer Rate: " + commSize + "KB/s");
        
        //at(Place.place(0))
       // Console.OUT.println("OUT OF PLACEGROUP AA::" + AA);

        var end:Long = timer.milliTime();
        
        Console.OUT.println("All: "+(end-start)+"ms");

    }
}
