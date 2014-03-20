//======================================================

//This program is for computing a pseudo belief from Mr. watanabe`s Paper.

//======================================================
import x10.util.*;
import x10.util.ArrayList;
import x10.compiler.*;
import x10.lang.*;
public class PsudoBP {

	var filename:String;
    var it_random:int = 0; //0: randomly iterate, non-zero: sequencially iterate 
    var precision:double = 0.001;//0.000001; //min_modularity.   
    var type_file:int = 0; // 0: unweighted, 1: weighted
    var passTimes:int = -1;  // -1: detect until be stopped itself, else detect decided times. 

    val M:Math = new Math();

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

	public def getH(symbol:int, p:double, r:double) {
		//symbol=1 means plus symbol, else means minus
		val denominator:double = symbol == 1 ? p + r : 2 - r - p;
		val molecule: double = r - p;
		return M.abs(molecule / denominator);
	}

	public def getTH(node:int, z:double, threshold:double) {
		//symbol=1 means plus symbol, else means minus
		val sg:double = node == 0 ? 1.0 : z > 0.0 ? 1.0 : z < 0.0 ? -1.0 : 0.0;
		return sg * M.min(M.abs(z), threshold);
	}

	public def getThreshold(symbol:int, p:double, r:double, h:double){
		//symbol=1 means plus symbol, else means minus
		val molecule:double = symbol==1 ? M.log(p/r) : M.log((1-p)/(1-r));
		return M.abs(molecule/h);
	}

	public def getSg(z : double) {
		return M.signum(z);
	}

	public def getBp_opt( p:double, r:double )
	{
		var B:Array[double] = new Array[double](size+1, 0);
		val MAXSTEP:int = 2;
		
		val h_plus:double = getH(1, p, r);
		val h_minus:double = getH(0, p, r);

		val threshold_plus:double = getThreshold(1, p, r, h_plus);
		val threshold_minus:double = getThreshold(0, p, r, h_minus);

		//val threshold:double = M.max(threshold_plus, threshold_minus);

		Console.OUT.println("h_plus, h_minus, threshold_plus, threshold_minus::" 
			+ h_plus + ", " + h_minus + ", " + threshold_plus + ", " + threshold_minus);

		var change:int = 0;

		for ( var i:int=0; i<MAXSTEP; i++ ) 
		{	
			//B(0) = 1.0;
			//B(size-1) = -1.0;
			//B(size) = -1.0;
			B(0) = Double.POSITIVE_INFINITY;
			if (i==1) {
				B(0) = 0;
			}
			change = 0;
			for (var k:int=1; k<=size; k++) 
			{	
			    val origin:double = B(k);
			    B(k) = 0.0;
		
				val neighList:List[int] = g.links.subList(g.degrees(k), g.degrees(k+1));

				val checkList:List[int] = g.links.subList(g.degrees(0), g.degrees(1));

				for (var node:int=0; node<neighList.size(); node++) 
				{	
					var neigh:int = neighList(node);
					var belief:double = B(neigh);
					var tmp_pluse:double=0.0;
					var tmp_minus:double=0.0;
					if (checkList.contains(neigh)) 
					{
						//PlusPart
						tmp_pluse = (belief-threshold_plus)>0.0 ?  h_plus*threshold_plus : 
						   (belief+threshold_plus) < 0.0 ? -1*h_plus*threshold_plus : h_plus*belief;
					}
					else
					{
						//MinusPart
						tmp_minus = (belief-threshold_minus)>0.0 ? -1*h_minus*threshold_minus : 
						   (belief+threshold_minus) < 0.0 ? h_minus*threshold_minus : -1*h_minus*belief;
					}
						
						
						   //Console.OUT.println("node, neigh, belief, lex_Plus, lex_Minus::" + k + ", " + neigh + ", " + belief + ", " + tmp_pluse + ", " + tmp_minus);



						B(k) += tmp_pluse + tmp_minus;

				}

				//Console.OUT.println("PlusPart, MinusPart::" + PlusPart + ", " + MinusPart);

				if(B(k)-origin!=0.0)
				{
					change++;
				}
			}

			if (change==0) {
				Console.OUT.println("computed " + i + "times");
				break;
			}
		}	
		return B;
	}

	public def getBp( p:double, r:double )
	{
		var B:ArrayList[double] = new ArrayList[double](size+1);
		for (var k:int=0; k<=size; k++) 
		{
			B(k)=0.0;
		}

		val MAXSTEP:int = 2;
		
		val h_plus:double = getH(1, p, r);
		val h_minus:double = getH(0, p, r);

		val threshold_plus:double = getThreshold(1, p, r, h_plus);
		val threshold_minus:double = getThreshold(0, p, r, h_minus);

		Console.OUT.println("h_plus, h_minus, threshold_plus, threshold_minus::" 
			+ h_plus + ", " + h_minus + ", " + threshold_plus + ", " + threshold_minus);

		if ((g.nb_nodes+1)==g.degrees.size()) {
			g.degrees.add(g.degrees(size));
		}

		var change:int = 0;

		for ( var i:int=0; i<MAXSTEP; i++ ) 
		{	
			//B(0) = 1.0;
			//B(size) = -1.0;
			B(0) = Double.POSITIVE_INFINITY;
			change = 0;
			for (var k:int=1; k<=size; k++) 
			{	
				//Console.OUT.println("k, g.nb_nodes, g.degrees.size()::" + k + ", " + g.nb_nodes + ", " + g.degrees.size());
			    val origin:double = B(k);
			    B(k) = 0.0;
		
				val neighList:List[int] = g.links.subList(g.degrees(k), g.degrees(k+1));
				
				for (var j:int=0; j<=size; j++)  {
					if (neighList.contains(j)) {
						B(k) += h_plus * getTH(j, B(j), threshold_plus);
					}
					else{
						B(k) += -1 * h_minus * getTH(j, B(j), threshold_minus);
					}
					
				}

				if(B(k)-origin!=0.0)
				{
					change++;
				}
			}

			if (change==0) {
				Console.OUT.println("computed " + i + "times");
				break;
			}
		}	
		return B;
	}

	public def LEBAPP( a:double, x:double ){
	var h:double =(a-1)/(a+1);
	var threashold:double = Math.abs((a+1)*Math.log(a)/(a-1));

	if (x - threashold > 0) 
		return Math.log(a);
	else if(x + threashold < 0)
		return -1 * Math.log(a);
	else
		return h*x;
	}

	public def getBpLex( p:double, r:double )
	{
		var B:ArrayList[double] = new ArrayList[double](size+1);
		for (var k:int=0; k<=size; k++) 
		{
			B(k)=0.0;
		}

		val MAXSTEP:int = 5;

		if ((g.nb_nodes+1)==g.degrees.size()) {
			g.degrees.add(g.degrees(size));
		}

		var change:int = 0;
		var a1:double = p/r;
		var a0:double = (1-p)/(1-r);
		var a:double = a1;

		for ( var i:int=0; i<MAXSTEP; i++ ) 
		{	
			//B(0) = 1.0;
			//B(size) = -1.0;
			B(0) = 1;
			change = 0;
			for (var k:int=1; k<=size; k++) 
			{	
				//Console.OUT.println("k, g.nb_nodes, g.degrees.size()::" + k + ", " + g.nb_nodes + ", " + g.degrees.size());
			    val origin:double = B(k);
			    B(k) = 0.0;
		
				val neighList:List[int] = g.links.subList(g.degrees(k), g.degrees(k+1));
				
				for (var j:int=0; j<neighList.size(); j++)  {
					
					//a = neighList.contains(j) ? a1 : a0;

					B(k) += LEBAPP(a0, B(neighList(j)));
					B(k) += LEBAPP(a1, B(neighList(j)));

				}

				if(B(k)-origin!=0.0)
				{
					change++;
				}
			}

			if (change==0) {
				Console.OUT.println("computed " + i + "times");
				break;
			}
		}	
		return B;
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

		var vPlus:int=0;
		var vMinus:int=0;
		var vPlus_opt:int=0;
		var vMinus_opt:int=0;

		Console.OUT.println("------------");

		val B:ArrayList[double] = bp.getBpLex(p, r);

		var sg:int;
		var sg_opt:int;

		for (var i:int=0; i<B.size(); i++) 
		{
			sg = bp.getSg(B(i));
			Console.OUT.println("node, B::" + i + ", " + B(i));
			if (i==0) {
				vPlus++;
			}
			else
			{
				if (sg>0) {
				vPlus++;
				}
				else vMinus++;
			}
		}
		Console.OUT.println("vPlus : vZero : vMinus = " + vPlus + " : " + (B.size() - vPlus - vMinus) + " : " + vMinus);

		var countCrossEdge:int = 0;
		for (var k:int=1; k<=bp.size; k++) 
		{	
	
			val neighList:List[int] = bp.g.links.subList(bp.g.degrees(k), bp.g.degrees(k+1));
			
			for (var j:int=0; j<neighList.size(); j++)  {
				countCrossEdge += B(k)*B(neighList(j))>0 ? 0 : 1;
			}
		}
		Console.OUT.println("CrossEdge:: " + countCrossEdge);

		

		val end:Long = timer.milliTime();
        Console.OUT.println("Time: "+(end-start)+"ms");
	}
}