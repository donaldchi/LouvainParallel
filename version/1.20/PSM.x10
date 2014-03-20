//======================================================

//This Class is using to make graph data in Planted Solution Model.

//======================================================
import x10.util.*;
import x10.util.ArrayList;
import x10.compiler.*;
import x10.lang.*;
public class PSM{

	public static def main(args:Array[String])  
	{
	
		var n:int = Int.parse(args(0));
		var p:double = 0.0;
		p = Double.parse(args(1));
		var r:double = 0.0;
		r = Double.parse(args(2));

		var data:Array[ArrayList[int]] = new Array[ArrayList[int]](2*n);
		var cluster:Array[int] = new Array[int](2*n);
		for (var i:int=0; i<n; i++) 
		{
			data(i) = new ArrayList[int]();
			data(i+n) = new ArrayList[int]();

			cluster(i) = i;
			cluster(i+n) = i+n;
		}	
		var size:int = 2*n;
		var inside:double = size*p;
		var out:double = size*r;

		var random:Random = new Random();
		var start:int = 0;
		var end:int = 0;

		//vConsole.OUT.println("0");

		while (inside>0.0)
		{	
			start = random.nextInt(n);
			end = random.nextInt(n);
			if (start!=end) 
			{
				data(start).add(end);				
			}

			start = random.nextInt(n);
			end = random.nextInt(n);
			if (start!=end) 
			{
				data(start+n).add(end+n);				
			}

			inside--;
		}

		while (out>0.0)
		{	
			start = random.nextInt(n);
			end = random.nextInt(n);
			data(start).add(end+n);
			out--;
		}
		for (var i:int=0; i<data.size; i++) 
		{
			var neigh:ArrayList[int] = data(i);
			neigh.sort();
			for (var j:int=0; j<neigh.size(); j++) 
			{
				Console.OUT.println(i + " " + j);		
			}		
		}
			
	}
}