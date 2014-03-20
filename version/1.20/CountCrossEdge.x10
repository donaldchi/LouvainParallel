//======================================================

//This program is for counting cross edge of the graph data which is segmented by PsudoBP.

//======================================================
import x10.util.*;
import x10.util.ArrayList;
import x10.compiler.*;
import x10.lang.*;
public class CountCrossEdge {
	public def this() {

	}

	public static def main(args:Array[String])  
	{
		val timer = new Timer();
        val start:Long = timer.milliTime();
		
		val bp:PsudoBP = new PsudoBP(args(0), 0);
		val n:int = bp.size;
		val const:double = 1.0/3.0;
		val sqrtn:double = 1.0/(bp.M.sqrt(n));

		var p:double = const + (1.0/3.0)*sqrtn;
		var r:double = const - (2.0/3.0)*sqrtn;
		if (args.size==3) {
			p = Double.parse(args(1));
			r = Double.parse(args(2));
		}

		var vPlus:int=0, vMinus:int=0;
		var vPlus_opt:int=0, vMinus_opt:int=0;

		Console.OUT.println("------------");
		Console.OUT.println("p, r::" + p + ", " + r);
		
		//val A:Array[double] = bp.getBp_opt(p, r);
		val B:ArrayList[double] = bp.getBp(p, r);
		var C:Array[int] = new Array[int](B.size(), 0); //Correspend to B
		var D:Array[int] = new Array[int](B.size(), 0);
		//var E:Array[int] = new Array[int](B.size(), 0); //correspend to A

		var sg:int;
		//var sg_opt:int;
		val size:int = (B.size()-1)/2;
		for (var i:int=0; i<B.size(); i++) 
		{
			sg = bp.getSg(B(i));
			//sg_opt = bp.getSg(A(i));
			//C(i)=1;
			//C(i) = sg > 0 ? 1 : -1;
			if (i<size) {
				D(i) = 1;
			}
			else D(i) =  -1;

			//Console.OUT.println("node, C, B::" + i + ", " + C(i) + ", " + B(i));
			if (i==0) {
				vPlus++;
				//vPlus_opt++;
				C(i) = 1;
				//E(i) = 1;

			}
			else
			{
				if (sg>0) {
				vPlus++;
				}
				else vMinus++;

				/*if (sg_opt>0) {
					vPlus_opt++;
				}
				else vMinus_opt++;*/

				C(i) = sg > 0 ? 1 : -1;
				//E(i) = sg_opt > 0 ? 1 : -1;
			}
		}
		Console.OUT.println("vPlus : vZero : vMinus = " + vPlus + " : " + (B.size() - vPlus - vMinus) + " : " + vMinus);
		//Console.OUT.println("vPlus_opt : vZero_opt : vMinus_opt = " + vPlus_opt + " : " + (B.size ()- vPlus_opt - vMinus_opt) + " : " + vMinus_opt);


		vPlus = 0;
		vMinus = 0; //store cross edges with PusdoPB

		//vPlus_opt=0;
		//vMinus_opt=0; //store cross edges with PusdoPB_opt

		for (var i:int=0; i<B.size(); i++) {
			val neighList:List[int] = bp.g.links.subList(bp.g.degrees(i), bp.g.degrees(i+1));
			for (var node:int=0; node<neighList.size(); node++) 
			{	
				val neigh:int = neighList(node);
				vPlus = C(i)!=C(neigh) ? vPlus+1 : vPlus+0; 
				vMinus = D(i)!=D(neigh) ? vMinus+1 : vMinus+0;
				//vPlus_opt = E(i)!=E(neigh) ? vPlus_opt+1 : vPlus_opt+0;
			}
		}

		Console.OUT.println("Cross Edges:: PsudoBP_opt : PsudoBP : Sequential = " + vPlus_opt/2 + " : " + vPlus/2 + " : " + vMinus/2);

	
		val end:Long = timer.milliTime();
        Console.OUT.println("Time: "+(end-start)+"ms");
	}
}