import x10.util.*;
import x10.util.ArrayList;
import x10.compiler.*;
import x10.lang.*;
import org.scalegraph.util.tuple.*;

public class Community_pre {

	var g:Graph;
	var size:int;

	/*var neigh_weight:HashMap[int, double];
	var neigh_pos:HashMap[int, int];*/
	var neigh_weight:Array[double];
	var neigh_pos:Array[int];
	var neigh_last:int;
	
	var n2c:ArrayList[int];
	var inside:ArrayList[double];
	var inside_tmp:ArrayList[double];
	var B:ArrayList[double];
	// var n2c_p:HashMap[int, int];
	// var totin_p:HashMap[int, Tuple2[double,double]];
	//node self`s inside weight when be reset
	//var inside_node:Array[double];
	var tot:ArrayList[double];

	var nb_pass:int;
	var min_modularity:double;

	var totc:double;
	var degc:double;
	var m2:double;
	var dnc:double;

	var i:int = 0; //using for iterating in for loops

	//for iterating links and weights
	var startIndex:int = 0; 
	var deg:int = 0;

	//used to compute neighbor
	var neigh:int;
	var neighNew:int; //store the num of reNumbered ID, neigh - nodeBand;
	var neigh_comm:int;
	var neigh_w:double;
	var posNew:int; //store the num of reNumbered ID

	//using in one_level part
	var node:int;
	var improvement:boolean = false;
	var nb_moves:int = 0;
	var nb_pass_done:int = 0;
	var new_mod:double = 0.0;
	var cur_mod:double = 0.0;
	var r:Random ;
	var rand_pos:int;
	var tmp:int;
	var node_comm:int;
	var w_degree:double;
	var best_comm:int;
	var best_nblinks:double = 0.0;
	var best_increase:double = 0.0;
	var increase:double = 0.0;
	//using in reset part
	var renumber:Array[int];
	var finalCount:int = 0;

	//Set the same DataStructure Per Place 
	val NODELIST =  PlaceLocalHandle.make[ArrayList[int]](Dist.makeUnique(), ()=>new ArrayList[int]());

	val N2C =  PlaceLocalHandle.make[HashMap[int, int]](Dist.makeUnique(), ()=>new HashMap[int, int]());
	val CHECK = PlaceLocalHandle.make[HashMap[int, boolean]](Dist.makeUnique(), ()=>new HashMap[int, boolean]());
	val TOTIN = PlaceLocalHandle.make[HashMap[int, Tuple2[double, double]]](Dist.makeUnique(), ()=>new HashMap[int, Tuple2[double,double]]());

	val LINKS =  PlaceLocalHandle.make[ArrayList[int]](Dist.makeUnique(), ()=>new ArrayList[int]());
	val WEIGHTS =  PlaceLocalHandle.make[ArrayList[double]](Dist.makeUnique(), ()=>new ArrayList[double]());
	val DEGREES =  PlaceLocalHandle.make[ArrayList[int]](Dist.makeUnique(), ()=>new ArrayList[int]());

	val GRAPH = PlaceLocalHandle.make[Graph](Dist.makeUnique(), ()=>new Graph());

	val MOD_P = PlaceLocalHandle.make[Array[double]](Dist.makeUnique(), ()=>new Array[double](1, 0.0));
	val MOVES = PlaceLocalHandle.make[Array[int]](Dist.makeUnique(), ()=>new Array[int](1, 0));

	public def this(){  }

	public def this(total_weight:double, nodeSize:int, precision:double)
	{

		neigh_weight = new Array[double](nodeSize+1,-1.0);
		neigh_pos = new Array[int](nodeSize);
		neigh_last = 0;

		min_modularity = precision;
		m2 = total_weight;
	}

	public def this(filename:String, type_file:int, passTimes:int, precision:double)
	{
		
		g = new Graph(filename, null, type_file);
		
		size = g.nb_nodes;

		neigh_weight = new Array[double](size+1,-1.0);
		neigh_pos = new Array[int](size);
		neigh_last = 0;

		n2c = new ArrayList[int](size+1);
		inside = new ArrayList[double](size+1);
		tot = new ArrayList[double](size+1);
		B = new ArrayList[double]();

		for ( i=0; i <= size; i++) 
		{			
			n2c(i) = i;
			tot(i) = g.weighted_degree(i);
			inside(i) = g.nb_selfloops(i);
		}
		nb_pass = passTimes;
		min_modularity = precision;
		m2 = g.total_weight;
		
	}
	
	public def this(gc:Graph, passTimes:int, precision:double, inside_tmp:ArrayList[double])
	{  //using when reset graph, precision == minm(in c++ version)
		g = gc;
		size = g.nb_nodes - 1;

		//Console.OUT.println("size in reset" + size);

		/*neigh_weight = new HashMap[int, double]( );
		neigh_pos = new HashMap[int, int]( );*/
		neigh_weight = new Array[double](size+1,-1.0);
		neigh_pos = new Array[int](size);
		neigh_last = 0;

		n2c = new ArrayList[int](size+1);
		inside = new ArrayList[double](size+1);
		//inside_node = new Array[double](size+1);
		tot = new ArrayList[double](size+1);
		B = new ArrayList[double]();

		for ( i=0; i <= size; i++) 
		{
			n2c(i) = i;
			tot(i) = g.weighted_degree(i);
			inside(i) = inside_tmp(i)/2;
		}

		nb_pass = passTimes;
		min_modularity = precision;
		m2 = g.total_weight;

	}

	public def modularity_parallel(start_p:int, end_p:int)
	{
		var subQ:double = 0.0;
		for (var k:int=start_p; k < end_p; k++) 
		{
			if(tot(k)>0)
			{
				subQ += inside(k)/m2 - (tot(k)/m2)*(tot(k)/m2);
			}	
		}
		return subQ;
	}

	public def modularity()
	{
		var q:double = 0.0;
		var out:double = 0.0;
		//var total:double = 0.0;

		for (i=0; i <= size; i++) {
			if(tot(i)>0)
			{
				out = 0.0;
				out = tot(i) - inside(i);
				q += inside(i)/m2 - (tot(i)/m2)*(tot(i)/m2);
				//total = total + tot(i);
			}	
		}
		return q;
	}

	@Inline public def neigh_comm( node:int, nodeIndex:int, n2c_p:HashMap[int, int], totin_p:HashMap[int, Tuple2[double, double]], gg:Graph)
	{

		for ( var i:int=0; i<neigh_last; i++) 
		{
			neigh_weight(neigh_pos(i)) = -1.0;
		}

		neigh_last = 0;
		neigh_pos(0)=n2c_p.get(node).value;

		neigh_weight(neigh_pos(0)) = 0;
		neigh_last = 1;
		

	    startIndex = gg.degrees(nodeIndex);
	    deg = gg.degrees(nodeIndex+1);

	    for ( var i:int = startIndex; i<deg; i++)
	    {
			neigh = 0;
			neighNew = 0;
			neigh_comm = 0;
			neigh_w = 0.0;
			
			neigh = gg.links(i);
			neigh_comm = n2c_p.get(neigh).value;	
			neigh_w = (gg.weights.size()==0)?1.0:gg.weights(i);

			if (node!=neigh) 
			{		
					if (neigh_weight(neigh_comm)==-1.0) 
					{
						neigh_weight(neigh_comm) = 0.0;
						neigh_pos(neigh_last++) = neigh_comm;
					}
					neigh_weight(neigh_comm) += neigh_w;
			}
	    }

	}

	@Inline public def remove( nodeIndex:int, originNode:int, comm:int, dnodecomm:double, totin_p:HashMap[int, Tuple2[double, double]], gg:Graph, n2c_p:HashMap[int, int])
	{
		//AssertionError("Node`s ID not correct!!",(node < size));
		var tot_tmp:double = totin_p.get(comm).value.val1;
		var in_tmp:double = totin_p.get(comm).value.val2;
		tot_tmp -= gg.weighted_degree(nodeIndex);
		in_tmp -= 2*dnodecomm + gg.nb_selfloops(nodeIndex);

		totin_p.put(comm, new Tuple2(tot_tmp, in_tmp));

		n2c_p.put(originNode, -1);
	}

	@Inline public def insert( nodeIndex:int, originNode:int, comm:int, dnodecomm:double, totin_p:HashMap[int, Tuple2[double, double]], gg:Graph, n2c_p:HashMap[int, int])
	{
		//AssertionError("Node`s ID not correct!!",(node < size));
		
		var tot_tmp:double = totin_p.get(comm).value.val1;
		var in_tmp:double =  totin_p.get(comm).value.val2;

		tot_tmp += gg.weighted_degree(nodeIndex);
		in_tmp += 2*dnodecomm + gg.nb_selfloops(nodeIndex);

		totin_p.put(comm, new Tuple2(tot_tmp, in_tmp));

		n2c_p.put(originNode, comm);

	}

	@Inline public def modularity_gain(totc:double, dnodecomm:double, w_degree:double)
	{
		//AssertionError("Node`s ID not correct!!",(node < size));
		//if (node == comm) return 0.0;
		
		degc = w_degree;
		dnc = dnodecomm;
		return (dnc - totc*degc/m2);
	}

	public def Init_Info()  
	{
		//init info per place
		//save segment node`s info
    	//init data structure per place to compute independence

    	val totin_p = TOTIN();
    	val weights_p = WEIGHTS();
    	val nodeList = NODELIST();

    	val links_p = LINKS();
    	val degrees_p = DEGREES();
    	val n2c_p = N2C();
    	val check_p = CHECK();

		degrees_p.add(0);

		//Console.OUT.println("nodeList::" + nodeList);

		for (var k:int=0; k < nodeList.size(); k++) 
		{
			var node:int = nodeList(k);
			var comm:int = n2c(node);
			var tot_tmp:double = tot(comm);
			var in_tmp:double =  inside(comm);

			n2c_p.put(node, comm);
			check_p.put(node, false);
			totin_p.put(comm, new Tuple2(tot_tmp, in_tmp));
			
			degrees_p.add(g.degrees(node+1)-g.degrees(node)+degrees_p(k));
		}

		//init links and border nodes
		var placeid:int = here.id;
		var end_ppp:int;
		var start_pp:int;

		for (var i:int=0; i < nodeList.size(); i++) 
		{
			start_pp = g.degrees(nodeList(i));			
			end_ppp = g.degrees(nodeList(i)+1);
				

			for (var k:int = start_pp; k <end_ppp; k++) 
			{
				val linkNode:int = g.links(k);
				links_p.add(linkNode);

				if(g.weights.size()>0)
				{
					val weight:double = g.weights(k);
					weights_p.add(weight);
				}

				if( !nodeList.contains(linkNode))
				{
					if (!n2c_p.containsKey(linkNode))
					{
						val neigh_comm:int = n2c(linkNode);
						n2c_p.put(linkNode, neigh_comm);
						totin_p.put(neigh_comm, new Tuple2(tot(neigh_comm), inside(neigh_comm)));					
					}
				}				
			}
		}

		// Console.OUT.println("print part info::");
		// for (var i:int=0; i<nodeList.size(); i++) 
		// {
		// 	Console.OUT.println("node, degrees, links, weights:::" + nodeList(i) + ", " + degrees_p(i+1));
		// 	start_pp = degrees_p(i);			
		// 	end_ppp = degrees_p(i+1);
		// 	Console.OUT.println("start, end::" + start_pp + ", " + end_ppp);

		// 	for (var k:int = start_pp; k <end_ppp; k++) 
		// 	{
		// 		//val linkNode:int = g.links(k);
		// 		Console.OUT.println("node, links, weights::" + nodeList(i) + ", " + links_p(k) + ",  0.0");
		// 	}
		// }
		
		val gg = GRAPH();
		gg.degrees = degrees_p;
		gg.links = links_p;
		gg.weights = weights_p;
	}

	public def Init_Info_P()  
	{
		//use this function from the second pass
		//init info per place 
		//save segment node`s info
    	//init data structure per place to compute independence

    	val totin_p = TOTIN();
    	val n2c_p = N2C();
    	val degrees_p = DEGREES();
    	val check_p = CHECK();
    	val nodeList = NODELIST();

    	totin_p.clear();
    	n2c_p.clear();
		
		for (var k:int=0; k < nodeList.size(); k++) 
		{
			var node:int = nodeList(k);
			var comm:int = n2c(node);
			var tot_tmp:double = tot(comm);
			var in_tmp:double =  inside(comm);

			n2c_p.put(node, comm);
			check_p.put(node, false);

			totin_p.put(comm, new Tuple2(tot_tmp, in_tmp));
		}

		//init links and border nodes
		var placeid:int = here.id;
		var end_ppp:int;

		for (var nodeNum:int=0; nodeNum < nodeList.size(); nodeNum++) 
		{
		
			var start_pp:int;
			
			start_pp = g.degrees(nodeList(nodeNum));			
			end_ppp = g.degrees(nodeList(nodeNum)+1);
				
			for (var k:int = start_pp; k <end_ppp; k++) 
			{
				val linkNode:int = g.links(k);
				var id:int = here.id;
				if( !nodeList.contains(linkNode))
				{
					if (!n2c_p.containsKey(linkNode))
					{
						val neigh_comm:int = n2c(linkNode);
						n2c_p.put(linkNode, neigh_comm);
						totin_p.put(neigh_comm, new Tuple2(tot(neigh_comm), inside(neigh_comm)));					
					}	
				}			
			}
		}
		
	}

	public def one_level_parallel(total_weight:double, nodeSize:int, precision:double)
	{
    	val totin_p = TOTIN();
    	val weights_p = WEIGHTS();

    	val links_p = LINKS();
    	val degrees_p = DEGREES();
    	val n2c_p = N2C();
    	val check_p = CHECK();

    	val gg = GRAPH();

    	val nodeList = NODELIST();

    	var nb_moves:int = 0;

    	val comm_p:Community_pre = new Community_pre(total_weight, nodeSize, precision); 

    	var a:int =0;

    	var random_order:Array[int] = new Array[int](nodeList.size());
		var r:Random = new Random();

		for ( var i:int=0; i<nodeList.size(); i++) {
			random_order(i) = i;
		}
		
		for ( var i:int=0; i<nodeList.size(); i++) {
			rand_pos = r.nextInt( nodeList.size() );
			tmp = random_order(i);
			random_order(i) = random_order(rand_pos);
			random_order(rand_pos) =tmp;
		}
    	for (var i:int=0; i<nodeList.size();  i++) 
    	{
  				
    		var nodeIndex:int = random_order(i);
    		var nodeNum:int = nodeList(nodeIndex);

    		comm_p.node_comm = n2c_p.get(nodeNum).value;
    		comm_p.w_degree = gg.weighted_degree(nodeIndex);
    		
    		//Console.OUT.println("node, nodeIndex, comm, w_degree::" + nodeNum + ", " + nodeIndex + ", " + comm_p.node_comm + ", " + comm_p.w_degree);
    		
    		comm_p.neigh_comm(nodeNum, nodeIndex, n2c_p, totin_p, gg);

     		comm_p.remove(nodeIndex, nodeNum, comm_p.node_comm, comm_p.neigh_weight(comm_p.node_comm), totin_p, gg, n2c_p);

    		comm_p.best_comm = comm_p.node_comm;
    		comm_p.best_nblinks = 0.0;
    		comm_p.best_increase = 0.0;

    		for ( var index:int=0; index< comm_p.neigh_last; index++) 
 			{

	 			val neigh_comm_tmp:int = comm_p.neigh_pos(index);

				comm_p.increase = comm_p.modularity_gain(totin_p.get(neigh_comm_tmp).value.val1, comm_p.neigh_weight(comm_p.neigh_pos(index)), comm_p.w_degree);
				
				if ((comm_p.increase > comm_p.best_increase)) 
	 			{
					comm_p.best_comm = neigh_comm_tmp;
					comm_p.best_nblinks = neigh_weight(neigh_pos(index));
					comm_p.best_increase = comm_p.increase;
				}

 			}

 			comm_p.insert(nodeIndex, nodeNum, comm_p.best_comm, comm_p.best_nblinks, totin_p, gg, n2c_p);

 			//Console.OUT.println("node, comm, newComm::" + nodeNum + ", " + comm_p.node_comm + ", " + comm_p.best_comm);

 			if (comm_p.best_comm!=comm_p.node_comm) {
 				nb_moves++;
 				check_p.put(nodeNum, true);
 			}

 			//Console.OUT.println("node, comm, best_comm::" + nodeNum + ", " + comm_p.node_comm + ", " + comm_p.best_comm);

    	}
    	Console.OUT.println("Place::" + here.id + ", nb_moves=" + nb_moves);
    	return nb_moves;
	}

	public def SetNodeList(){
		val nodeList = NODELIST();
		var sg:int;
		val bp:PsudoBP = new PsudoBP();

		for (var i:int=0; i<B.size(); i++) 
		{
			sg = bp.getSg(B(i));

			if(here.id!=(Place.ALL_PLACES-1) && sg<0)
			{
				nodeList.add(i);
			}
			else if (here.id==(Place.ALL_PLACES-1) && sg>=0) 
			{
				nodeList.add(i);
			}	
		}

		/*Console.OUT.println("Partition in Place " + here.id + " ::");
		for (var i:int=0; i<nodeList.size(); i++) {
			Console.OUT.println(nodeList(i));
		}*/
	}

	public def one_level( level:int )
	{
		var improvement:boolean = false;

		var nb_moves:int = 0;
		var nb_pass_done:int = 0;
		var new_mod:double = 0.0;
		var cur_mod:double = 0.0;
		
		var node_comm:int;
		var w_degree:double;
		var best_comm:int;
		var best_nblinks:double = 0.0;
		var best_increase:double = 0.0;
		var increase:double = 0.0;

		improvement = false;
		nb_moves = 0;
		nb_pass_done = 0;

		new_mod = modularity();

		cur_mod = new_mod;

		//Init data structure parallelly 
		
		val placeNum:int = Place.ALL_PLACES-1;
		val band:int = size / placeNum;

		var partStart:long = Timer.milliTime();
		val bp:PsudoBP = new PsudoBP();
		bp.g = g;
		bp.size = g.nb_nodes;
		val p_in:double = 0.6;
		val r_out:double = 0.1;
		B = bp.getBp(p_in, r_out);
		
		var partEnd:long = Timer.milliTime();
		

		finish for(p in Place.places())
        {        	
        	at(p)
            {   
            	if (here.id!=0) 
            	{
					SetNodeList();	
					Clock.advanceAll();
            	}
    		}
        } 
        Console.OUT.println("Partition::" + (partEnd - partStart) + "ms");


		finish for(p in Place.places())
        {        	
        	at(p)
            {   
            	if (here.id!=0) 
            	{

	            	val start_p:int = (here.id-1)*band;
	            	

	            	if(here.id!=(Place.ALL_PLACES-1))
					{
						val end_p:int = (here.id)*band;
						Init_Info();

					}
					else
					{
						val end_p:int = size+1;
						Init_Info();

					}
					
					Clock.advanceAll();
            	}
    		}
        } 

		do{
			cur_mod = new_mod;
			nb_moves = 0;
			nb_pass_done++;

			//Console.OUT.println("Pass::" + nb_pass_done);

			if (nb_pass_done >= 2 ) {
				

				//Init_Info_P(0, size+1, band);

				finish for(p in Place.places())
		        {
		        	at(p)
		            {   
		            	if (here.id!=0) 
		            	{
			            	val start_p:int = (here.id-1)*band;
			           
			            	if(here.id!=(Place.ALL_PLACES-1))
							{
								val end_p:int = (here.id)*band;
								Init_Info_P();
							}
							else
							{
								val end_p:int = size+1;
								Init_Info_P();
							}	
							Clock.advanceAll();
		            	}
		    		}
		        }
			}

			nb_moves = 0;

	        finish for(p in Place.places())
	        {
	        	at(p)
	        	{
		        	if (here.id!=0) 
		            {   
			            val start_p:int = (here.id-1)*band;
			            val moves = MOVES();

		            	if(here.id!=(Place.ALL_PLACES-1))
						{
							val end_p:int = (here.id)*band;
							moves(0) = one_level_parallel(m2, size, min_modularity);
						}
						else
						{
							val end_p:int = size+1;
							moves(0) = one_level_parallel(m2, size, min_modularity);
						}
						at(Place.place(0))
	                	{ 
	                		val totMove = MOVES();
	                		totMove(0) += moves(0);
	                	}					
						Clock.advanceAll();
		            }	
	        	}
	            
	        }

			val totMove = MOVES();
	        nb_moves = totMove(0);
	    	
	        new_mod = 0.0;

	        if (nb_moves>0) {
	        	improvement = true;
	        }


			var startComm:long = Timer.milliTime();

			finish for(p in Place.places())
	        {
	            at(p)
	            {  
	            	if (here.id!=0) 
	            	{
	            		val start_p:int = (here.id-1)*band;
		            	if(here.id!=(Place.ALL_PLACES-1))
						{
							val end_p:int = (here.id)*band;
							SendComm2Master( );
						}
						else
						{
							val end_p:int = size+1;
							SendComm2Master( );
						}
	            	}
	        	}
	        }
	        //SendComm2Master(0, size+1);
	        var endComm:long = Timer.milliTime();
	        //nb_moves=0;


	         SetTotIn_Master();

	         val n2c_master = N2C();
	         n2c_master.clear();

			 new_mod = modularity();

			Console.OUT.println("Pass"+ level + "_" + nb_pass_done + "," + new_mod + ", CommTime::" + (endComm - startComm) + "ms");
			/*if (level==2) {
				nb_moves=0;
				improvement=false;
			}*/

		}while(nb_moves>0 && (new_mod-cur_mod)>min_modularity);

		return improvement;
	}

	public def getTotalWeight()
	{
		val totin_p = TOTIN();
		var total:double = 0.0;
		for( e in totin_p.entries())
		{
			total += e.getValue().val1;
		}
	}

	public def modularity_p() 
	{
		//compute modularity per Place 
		var mod:double = 0.0;
    	val totin_p = TOTIN();
    	val n2c_p = N2C();
    	val m2:double = g.total_weight;

    	for ( e in totin_p.entries()) 
    	{
    		if(e.getValue().val1>0)
    		{
    			var out:double=0.0;
    			out = e.getValue().val1 - e.getValue().val2;
    			mod += e.getValue().val2/m2 - (e.getValue().val1/m2)*(e.getValue().val1/m2);
    		}
    	}
    	return mod;
	}

	public def SetTotIn_Master()
	{
		val n2c_master = N2C();

		tot.clear();
		inside.clear();
 		for (var node:int=0; node<n2c.size(); node++)
 		{
 			tot(node) = 0.0;
 			inside(node) = 0.0;
 		}


	    //Console.OUT.println("n2c_master.size, n2c.size = " + n2c_master.size() + ", "+ n2c.size());

        for ( e in n2c_master.entries()) {
        	val node:int = e.getKey();
        	val comm:int = e.getValue();
        	//Console.OUT.println("node, comm::" + node + ", " + comm);
        	n2c(node) = comm;

        	/*tot(i) = 0.0;
        	inside(i) = 0.0;
        	i++;*/
        }

        for (var node:int=0; node<n2c.size(); node++)
        {

        	val comm:int = n2c(node);
        	        	
		    startIndex = g.degrees(node);
		    deg = g.degrees(node+1);

		    for ( i = startIndex; i<deg; i++)
		    {
				neigh = 0;
				neigh_comm = 0;
				
				neigh = g.links(i);
				neigh_comm = n2c(neigh);
				neigh_w = (g.weights.size()==0)?1.0:g.weights(i);

				if (neigh_comm == comm) 
				{
					inside(comm) += neigh_w; 
				}
				tot(comm) += neigh_w;
			}

        }

        var total:double = 0.0;
        var num:int=0;
        for (i=0; i<tot.size(); i++) {
        	if(tot(i)>0.0)
        	{	
        		num++;
        		total += tot(i);
        	}
        }
        //Console.OUT.println("Total==" + total);
	}

	public def SendComm2Master()
	{
		val n2c_p = N2C();
		val check_p = CHECK();
		val nodeList = NODELIST();

		for (var i:int=0; i<nodeList.size(); i++) 
		{
			var node:int = nodeList(i);
			if (check_p.get(node).value) 
			{
				val comm:int = n2c_p.get(node).value;
				val id:int = node;
				at(Place.place(0))
			    {	
					val n2c_master = N2C();
					n2c_master.put(id, comm);
			    }	
			}				
		}
	}

	public def resetCom()
	{
		
		renumber = new Array[int](size+1, -1);

		for (node=0; node<=size; node++) {
			//Console.OUT.println("node, comm::" + node + ", " + n2c(node));
			renumber(n2c(node)) = 0;
		}

		for (i=0; i<=size; i++) {
			if (renumber(i)!=-1) {
				renumber(i)=finalCount;
				finalCount++;
			}
		}

		//Compute communities
		var comm_nodes:Array[ArrayList[int]] = new Array[ArrayList[int]](finalCount);
		inside_tmp = new ArrayList[double](finalCount);

		for ( i = 0; i<finalCount; i++) {
			comm_nodes(i) = new ArrayList[int]();
			inside_tmp(i) = 0.0;
		}

		for (node=0; node<=size; node++) 
		{

			comm_nodes(renumber(n2c(node))).add(node);
			inside_tmp(renumber(n2c(node))) += inside(node);
		}
		
		var g2:Graph = new Graph();
		g2.nb_nodes = comm_nodes.size;
		g2.degrees = new ArrayList[int](comm_nodes.size+1);
		g2.degrees(0) = 0;

		var comm_deg:int = comm_nodes.size;
		var set:Set[int];
		var it:Iterator[int];
		for (var comm:int=0; comm<comm_deg; comm++) 
		{
			var m:HashMap[int, double] = new HashMap[int, double]();
			var comm_size:int = comm_nodes(comm).size();
			for ( node = 0; node<comm_size; node++) 
			{
				//Console.OUT.println("comm, nodes::" + comm + ", " + comm_nodes(comm)(node));

		        startIndex = g.degrees(comm_nodes(comm)(node));
		        deg = g.degrees(comm_nodes(comm)(node)+1);

		        for ( i = startIndex; i<deg; i++)
		        {
					neigh = g.links(i);

					neigh_comm = renumber(n2c(neigh));
					neigh_w = (g.weights.size()==0)?1.0:g.weights(i);

					if (comm==neigh_comm) 
					{
						val inside_w:double = (g.weights.size()==0)?1.0:g.weights(i);
						inside_tmp(comm) = inside_tmp(comm) + inside_w;
					}
					
					if(!m.containsKey(neigh_comm))
					{
						m.put(neigh_comm, neigh_w);
					}
					else
					{
						var vbWeight:Box[double] = m.get(neigh_comm);
						neigh_w = neigh_w + vbWeight.value;
						m.remove(neigh_comm);
						m.put(neigh_comm, neigh_w);
					}
		        }								
			}

			g2.degrees(comm+1) = g2.degrees(comm)+m.size();
			g2.nb_links += m.size();

			set = m.keySet();
			it = set.iterator();
			var weight:Box[double];
			while(it.hasNext())
			{
				node = it.next();
				weight = m.get(node);

				g2.total_weight += weight.value;
				g2.links.add(node);
				g2.weights.add(weight.value);
			}
			
		}

		return g2;		
	}
	
	public static def main(Array[String]) {
        
      Console.OUT.println("Hello world");
    }

}
