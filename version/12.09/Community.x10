import x10.util.*;
import x10.util.ArrayList;
import x10.compiler.*;
import x10.lang.*;
import org.scalegraph.util.tuple.*;

public class Community {

	var g:Graph;
	var size:int;

	var neigh_weight:HashMap[int, double];
	var neigh_pos:HashMap[int, int];
	
	var n2c:ArrayList[int];
	var inside:ArrayList[double];
	var inside_tmp:ArrayList[double];
	//node self`s inside weight when be reset
	var inside_node:Array[double];
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
	val N2C =  PlaceLocalHandle.make[HashMap[int, int]](Dist.makeUnique(), ()=>new HashMap[int, int]());
	val TOTIN = PlaceLocalHandle.make[HashMap[int, Tuple2[double, double]]](Dist.makeUnique(), ()=>new HashMap[int, Tuple2[double,double]]());

	val LINKS =  PlaceLocalHandle.make[ArrayList[int]](Dist.makeUnique(), ()=>new ArrayList[int]());
	val WEIGHTS =  PlaceLocalHandle.make[ArrayList[double]](Dist.makeUnique(), ()=>new ArrayList[double]());
	val DEGREES =  PlaceLocalHandle.make[ArrayList[int]](Dist.makeUnique(), ()=>new ArrayList[int]());

	val GRAPH = PlaceLocalHandle.make[Graph](Dist.makeUnique(), ()=>new Graph());

	val MOD_P = PlaceLocalHandle.make[Array[double]](Dist.makeUnique(), ()=>new Array[double](1, 0.0));
	val MOVES = PlaceLocalHandle.make[Array[int]](Dist.makeUnique(), ()=>new Array[int](1, 0));

	public def this(){  }

	public def this(total_weight:double, precision:double, size:int)
	{
		this.size = size;

		neigh_weight = new HashMap[int, double]( );
		neigh_pos = new HashMap[int, int]( );

		min_modularity = precision;
		m2 = total_weight;
	}

	public def this(filename:String, type_file:int, passTimes:int, precision:double)
	{
		
		g = new Graph(filename, null, type_file);
		
		size = g.nb_nodes;

		neigh_weight = new HashMap[int, double]( );
		neigh_pos = new HashMap[int, int]( );

		n2c = new ArrayList[int](size+1);
		inside = new ArrayList[double](size+1);
		inside_node = new Array[double](size+1);
		tot = new ArrayList[double](size+1);

		for ( i=0; i <= size; i++) 
		{			
			n2c(i) = i;
			tot(i) = g.weighted_degree(i);
			inside(i) = g.nb_selfloops(i);
			inside_node(i) = 0.0;
		}
		nb_pass = passTimes;
		min_modularity = precision;
		m2 = g.total_weight;
		
	}
	
	public def this(gc:Graph, passTimes:int, precision:double, inside_tmp:ArrayList[double])
	{  //using when reset graph, precision == minm(in c++ version)
		g = gc;
		size = g.nb_nodes - 1;

		neigh_weight = new HashMap[int, double]( );
		neigh_pos = new HashMap[int, int]( );

		n2c = new ArrayList[int](size+1);
		inside = new ArrayList[double](size+1);
		inside_node = new Array[double](size+1);
		tot = new ArrayList[double](size+1);

		for ( i=0; i <= size; i++) 
		{
			n2c(i) = i;
			tot(i) = g.weighted_degree(i);
			inside(i) = inside_tmp(i);
			inside_node(i) = inside_tmp(i);
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
		var total:double = 0.0;

		for (i=0; i <= size; i++) {
			if(tot(i)>0)
			{
				out = 0.0;
				out = tot(i) - inside(i);
				q += inside(i)/m2 - (tot(i)/m2)*(tot(i)/m2);
				total = total + tot(i);
			}	
		}
		return q;
	}

	@Inline public def neigh_comm( node:int, start_p:int, end_p:int, n2c_p:HashMap[int, int], totin_p:HashMap[int, Tuple2[double, double]], gg:Graph, nodeBand:int )
	{

		if (neigh_weight.size() > 0) 
		{
			neigh_weight.clear();	
		}

		neigh_weight.put(n2c_p.get(node).value, 0.0);
		
	    startIndex = gg.degrees(node-nodeBand) - gg.degrees(0);
	    deg = gg.degrees(node-nodeBand+1) - gg.degrees(0);

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
					if (!neigh_weight.containsKey(neigh_comm)) 
					{
						neigh_weight.put(neigh_comm, 0.0);
					}
					val swapWeight:double = neigh_weight.get(neigh_comm).value;
					neigh_weight.remove(neigh_comm);
					neigh_weight.put(neigh_comm, swapWeight + neigh_w);
			}
	    }
	}

	@Inline public def remove( node:int, originNode:int, comm:int, dnodecomm:double, totin_p:HashMap[int, Tuple2[double, double]], gg:Graph, n2c_p:HashMap[int, int])
	{
		//AssertionError("Node`s ID not correct!!",(node < size));
		var tot_tmp:double = totin_p.get(comm).value.val1;
		var in_tmp:double = totin_p.get(comm).value.val2;
		tot_tmp -= gg.weighted_degree(node);
		in_tmp -= 2*dnodecomm + gg.nb_selfloops(node);

		totin_p.put(comm, new Tuple2(tot_tmp, in_tmp));

		n2c_p.put(originNode, -1);
	}

	@Inline public def insert( node:int, originNode:int, comm:int, dnodecomm:double, totin_p:HashMap[int, Tuple2[double, double]], gg:Graph, n2c_p:HashMap[int, int])
	{
		//AssertionError("Node`s ID not correct!!",(node < size));
		
		var tot_tmp:double = totin_p.get(comm).value.val1;
		var in_tmp:double =  totin_p.get(comm).value.val2;

		tot_tmp += gg.weighted_degree(node);
		in_tmp += 2*dnodecomm + gg.nb_selfloops(node);

		totin_p.put(comm, new Tuple2(tot_tmp, in_tmp));

		n2c_p.put(originNode, comm);

	}

	@Inline public def modularity_gain( node:int, totc:double, dnodecomm:double, w_degree:double)
	{
		//AssertionError("Node`s ID not correct!!",(node < size));
		//if (node == comm) return 0.0;
		
		degc = w_degree;
		dnc = dnodecomm;
		return (dnc - totc*degc/m2);
	}

	public def Init_Info(start_p:int, end_p:int, band:int)  
	{
		//init info per place
		//save segment node`s info
    	//init data structure per place to compute independence

    	val totin_p = TOTIN();
    	val weights_p = WEIGHTS();

    	val links_p = LINKS();
    	val degrees_p = DEGREES();
    	val n2c_p = N2C();

		if(start_p!=0)
			degrees_p.add(g.degrees(start_p));
		else
			degrees_p.add(start_p);
		
		for (var k:int=start_p; k < end_p; k++) 
		{
			var comm:int = n2c(k);
			var tot_tmp:double = tot(comm);
			var in_tmp:double =  inside(comm);

			n2c_p.put(k, comm);
			totin_p.put(comm, new Tuple2(tot_tmp, in_tmp));
			degrees_p.add(g.degrees(k+1));
		}

		//init links and border nodes
		var placeid:int = here.id;
		var end_ppp:int;

		for (var nodeNum:int=start_p; nodeNum < end_p; nodeNum++) 
		{
			val newNodeNum:int = nodeNum - (placeid-1)*band;
			var start_pp:int;
			
			start_pp = degrees_p(newNodeNum);			
			end_ppp = degrees_p(newNodeNum+1);
				
			for (var k:int = start_pp; k <end_ppp; k++) 
			{
				val linkNode:int = g.links(k);
				links_p.add(linkNode);

				if( linkNode < start_p || linkNode >= end_p)
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
		
		val gg = GRAPH();
		gg.degrees = degrees_p;
		gg.links = links_p;
		gg.weights = weights_p;
	}

	public def Init_Info_P(start_p:int, end_p:int, band:int)  
	{
		//use this function from the second pass
		//init info per place 
		//save segment node`s info
    	//init data structure per place to compute independence

    	val totin_p = TOTIN();
    	val n2c_p = N2C();
    	val degrees_p = DEGREES();
    	totin_p.clear();
    	n2c_p.clear();
		
		for (var k:int=start_p; k < end_p; k++) 
		{
			var comm:int = n2c(k);
			var tot_tmp:double = tot(comm);
			var in_tmp:double =  inside(comm);

			n2c_p.put(k, comm);
			totin_p.put(comm, new Tuple2(tot_tmp, in_tmp));
		}

		//init links and border nodes
		var placeid:int = here.id;
		var end_ppp:int;

		for (var nodeNum:int=start_p; nodeNum < end_p; nodeNum++) 
		{
			val newNodeNum:int = nodeNum - (placeid-1)*band;
			var start_pp:int;
			
			start_pp = degrees_p(newNodeNum);
			end_ppp = degrees_p(newNodeNum+1);
				
			for (var k:int = start_pp; k <end_ppp; k++) 
			{
				val linkNode:int = g.links(k);
				var id:int = here.id;
				if( linkNode < start_p || linkNode >= end_p)
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

	public def one_level_parallel(total_weight:double, precision:double, start_p:int, end_p:int, band:int)
	{
    	val totin_p = TOTIN();
    	val weights_p = WEIGHTS();

    	val links_p = LINKS();
    	val degrees_p = DEGREES();
    	val n2c_p = N2C();

    	val gg = GRAPH();

    	var nb_moves:int = 0;

    	val comm_p:Community = new Community(total_weight, precision, (end_p-start_p)); 

    	val nodeBand:int = (here.id-1)*band;

    	for (var nodeNum:int=start_p; nodeNum<end_p;  nodeNum++) 
    	{
  				
    		val newNodeNum:int = nodeNum - nodeBand;

    		comm_p.node_comm = n2c_p.get(nodeNum).value;
    		comm_p.w_degree = gg.weighted_degree(newNodeNum);
    		
    		comm_p.neigh_comm(nodeNum, start_p, end_p, n2c_p, totin_p, gg, nodeBand);

    		comm_p.remove(newNodeNum, nodeNum, comm_p.node_comm, comm_p.neigh_weight.get(comm_p.node_comm).value, totin_p, gg, n2c_p);

    		comm_p.best_comm = comm_p.node_comm;
    		comm_p.best_nblinks = 0.0;
    		comm_p.best_increase = 0.0;

    		for (e in comm_p.neigh_weight.entries())
 			{

	 			val neigh_comm_tmp:int = e.getKey();

				comm_p.increase = comm_p.modularity_gain(newNodeNum, totin_p.get(neigh_comm_tmp).value.val1, e.getValue(), comm_p.w_degree);

	 			if ((comm_p.increase > comm_p.best_increase)) 
	 			{
					comm_p.best_comm = neigh_comm_tmp;
					comm_p.best_nblinks = e.getValue();
					comm_p.best_increase = comm_p.increase;
				}

 			}

 			comm_p.insert(newNodeNum, nodeNum, comm_p.best_comm, comm_p.best_nblinks, totin_p, gg, n2c_p);

 			if (comm_p.best_comm!=comm_p.node_comm) {
 				nb_moves++;
 			}

    	}
    	Console.OUT.println("Place::" + here.id + ", nb_moves=" + nb_moves);
    	return nb_moves;
	}

	public def one_level(  )
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
					Init_Info(start_p, end_p, band);
				}
				else
				{
					val end_p:int = size+1;
					Init_Info(start_p, end_p, band);
				}
					
					Clock.advanceAll();
            	}
    		}
        } 

		do{
			cur_mod = new_mod;
			nb_moves = 0;
			nb_pass_done++;

			Console.OUT.println("Pass::" + nb_pass_done);

			if (nb_pass_done >= 2 ) {
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
								Init_Info_P(start_p, end_p, band);
							}
							else
							{
								val end_p:int = size+1;
								Init_Info_P(start_p, end_p, band);
							}	
							Clock.advanceAll();
		            	}
		    		}
		        }
			}

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
							moves(0) = one_level_parallel(m2, min_modularity, start_p, end_p, band);
						}
						else
						{
							val end_p:int = size+1;
							moves(0) = one_level_parallel(m2, min_modularity, start_p, end_p, band);
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
							SendComm2Master(start_p, end_p);
						}
						else
						{
							val end_p:int = size+1;
							SendComm2Master(start_p, end_p);
						}
	            	}
	        	}
	        }

	        SetTotIn_Master();

			new_mod = modularity();

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

	    i = 0;
        for ( e in n2c_master.entries()) {
        	val node:int = e.getKey();
        	val comm:int = e.getValue();
        	n2c(node) = comm;

        	tot(i) = 0.0;
        	inside(i) = 0.0;
        	i++;
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
	}

	public def SendComm2Master(start_p:int, end_p:int)
	{
		val n2c_p = N2C();
		for (var node:int=start_p; node<end_p; node++) 
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

	public def SyncN2C(start_p:int, end_p:int, band:int)
	{
    	val n2c_p = N2C();
    	val totin_tmp:HashMap[int, Tuple2[double, double]] = new HashMap[int, Tuple2[double, double]]();
    	for(e in n2c_p.entries()) 
    	{
    		val node:int = e.getKey();

    		if (node<start_p || node>=end_p) 
    		{
    			val comm:int = e.getValue();
				var placeid:int = node/band+1;
				if(placeid==Place.ALL_PLACES)
				{
					placeid = Place.ALL_PLACES -1;
				}
				at(Place.place(placeid))
				{
					val n2c_remote = N2C();
					val comm_n:int = n2c_remote.get(node).value;
					if (comm != comm_n) 
					{
						n2c_p.put(node, comm_n);
					}
				}	
    		}
    	}
	}

	public def SetTotIn(start_p:int, end_p:int, band:int)
	{
		val totin_p = TOTIN();
		totin_p.clear();
    	val weights_p = WEIGHTS();

    	val links_p = LINKS();
    	val degrees_p = DEGREES();
    	val n2c_p = N2C();

    	val gg = GRAPH();
		val nodeBand:int = (here.id-1)*band;
		
		for (var node:int=start_p; node<end_p; node++) 
		{
			startIndex = gg.degrees(node-nodeBand) - gg.degrees(0);
		    deg = gg.degrees(node-nodeBand+1) - gg.degrees(0);
		    
		    for ( var i:int = startIndex; i<deg; i++)
		    {
				neigh = gg.links(i);

				
				neigh_comm = n2c_p.get(neigh).value;
		    }				
		}
	}

	public def resetCom()
	{
		
		renumber = new Array[int](size+1, -1);
		
		for (node=0; node<=size; node++) {
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
