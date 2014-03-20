//======================================================

//This program is for computing a pseudo belief from Mr. watanabe`s Paper.

//======================================================
import x10.util.*;
import x10.util.ArrayList;
import x10.compiler.*;
import x10.lang.*;
import org.scalegraph.util.tuple.*;
public class MLP {

	var filename:String;
    var it_random:int = 0; //0: randomly iterate, non-zero: sequencially iterate 
    var precision:double = 0.001;//0.000001; //min_modularity.   
    var type_file:int = 0; // 0: unweighted, 1: weighted
    var passTimes:int = -1;  // -1: detect until be stopped itself, else detect decided times. 

    var g:Graph;
	var size:int;
	
	public def this()
	{
		
	}

	public def this(filename:String, type_file:int)
	{
		g = new Graph(filename, null, type_file);
		size = g.nb_nodes;		
	}

	public def getH(symbol:int, p:double, r:double)
	{
		//symbol=1 means plus symbol, else means minus
		var h:double;
		val m:Math = new Math();
		val molecule:double = r - p;
		var denominator:double = 0.0;
		if ( symbol==1) 
		{
			denominator = p + r;
		}
		else
		{
			denominator = 2-r-p;
		}
		h = m.abs(molecule/denominator);
		return h;
	}

	public def getTH(symbol:int, node:int, z:double, p:double, r:double, threshold:double)
	{
		//symbol=1 means plus symbol, else means minus
		var Th:double = 0.0;
		var sg:double = 0.0;
		if ( z>0.0 ) 
		{
			sg = 1.0;	
		}
		else if ( z==0.0 ) 
		{
			sg = 0.0;
		}
		else sg = -1.0;

		var min:double = 0.0;
		if (z - threshold < 0) {
			min = z;
		}
		else min = threshold;

		if(node == 0) sg = 1;

		Th = sg*min;

		return Th;
	}

	public def getThreshold(symbol:int, p:double, r:double)
	{
		//symbol=1 means plus symbol, else means minus
		var threshold:double = 0.0;
		val m:Math = new Math();
		var molecule:double = 0.0;
		var denominator:double = 0.0;
		var tmp:double = 0.0;
		if (symbol == 1) 
		{
			tmp = p/r;
			denominator = tmp -1;
		}
		else
		{
			tmp = (1-p)/(1-r);
			denominator = tmp -1;
		}
		molecule = (1+tmp)*m.log(tmp);
		threshold = m.abs(molecule/denominator);

		return threshold;
	}

	public def getSg(z:double)
	{
		var cluster:int = 0;

		if ( z >0.0) {
			cluster = +1;
		}
		else if (z==0.0) {
			cluster = 0;
		}
		else cluster = -1;

		return cluster;
	}

	public def getBp( p:double, r:double)
	{
		var B:Array[double] = new Array[double](size, 0);
		var MAXSTEP:int = 100;
		var threshold_plus:double = getThreshold(1, p, r);
		var threshold_minus:double = getThreshold(0, p, r);

		var h_plus:double = getH(1, p, r);
		var h_minus:double = getH(0, p, r);

		var PlusPart:double = 0.0;
		var MinusPart:double = 0.0;

		var change:int = 0;

		for ( var i:int=0; i<MAXSTEP; i++ ) 
		{
			//B(0) = Double.POSITIVE_INFINITY; 	
			B(0) = 1;
			for (var k:int=1; k<size; k++) 
			{	
				var startIndex:int = g.degrees(k);
			    var deg:int = g.degrees(k+1);
		
				val neighList:List[int] = g.links.subList(startIndex, deg);
				//var it:ListIterator[int] = neighList.iterator();
				/*Console.OUT.print("node::" + k + " ");
				while(it.hasNext()){
					Console.OUT.print(" " + it.next());

				}
				Console.OUT.println();*/
				for (var node:int=0; node<size; node++) 
				{	
					if (neighList.contains(node)) 
					{
						PlusPart += h_plus*getTH(1, node, B(node), p, r, threshold_plus);
					}
					else
						MinusPart += h_minus*getTH(0, node, B(node), p, r, threshold_minus);		
				}

				if (B(k)-PlusPart+MinusPart!=0.0) 
				{
					B(k) = PlusPart - MinusPart;
					change++;					
				}
			}
			if (change==0) 
			{	
				Console.OUT.println("Run " + i + "times.");
				return B;
				//break;		
			}	
		}
		Console.OUT.println("Run " + MAXSTEP + "times.");
		return B;
	}

	public static def main(args:Array[String])  
	{	
		val timer = new Timer();
        var start:Long = timer.milliTime();
		
		var bp:PsudoBP = new PsudoBP(args(0), 0);
		var B:Array[double] = new Array[double](bp.size);
		var p:double = Double.parse(args(1));
		var r:double = Double.parse(args(2));
		B = bp.getBp(p, r);

		for (var i:int=0; i<B.size; i++) {
			Console.OUT.println("node, bp, cluster::" + i + ", " + B(i) + ", " + bp.getSg(B(i)));
		}

		var end:Long = timer.milliTime();
        Console.OUT.println("Time: "+(end-start)+"ms");
	}
}