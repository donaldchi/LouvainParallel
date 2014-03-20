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
            //A = new Array[int](4);
            A(0) = 0;
            A(1) = 0;
            /*A(2) = 3;
            A(3) = 4;*/
            b=10;
        }
        if (id==1) {
            //A = new Array[int](4);
            A(0) = 0;
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
            //A = new Array[int](4);
            A(0) = 3;
            A(1) = 6;
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

        PlaceGroup.WORLD.broadcastFlat(()=>{
            val role = Runtime.hereInt(); 
        
            val id:int = here.id;
            val cd:comTest1 = new comTest1();
            val A:Array[int] = cd.init(Runtime.hereInt());
            val tot:Array[double] = cd.init_w(Runtime.hereInt());
            
            tt.reduce(role,0, A, 0, A, 0, A.size, Team.MAX);

            Console.OUT.println("In Place" + id + ": ");
            Console.OUT.println(A);
            //Console.OUT.println("1, 2, 3, 4 =  " + at(0) A.size +", "+ at(1) A.size +", "+ at(2) A.size +", "+ at(3) A.size);
            //val sum:int = ComDetect.sum(A);
            //Console.OUT.println("Place: " + here.id + " sum = " + sum);
            //Console.OUT.println("Place: " + here.id + " isHost:" + p(index).isHost());
            //if (id!=3) {
            //tt.gatherv();
            //}

            //tt.gatherv(id, 0, A, 0, A.size, A, 0, A.size);                        
        
        });
 
        var end:Long = timer.milliTime();
        
        Console.OUT.println("All: "+(end-start)+"ms");

    }
}
