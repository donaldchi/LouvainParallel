import x10.util.*;

public class ComDetect 
{
    var filename:String;
    //var maxNode:int = 0;
    //var edgeNum:int = 0;

    var it_random:int = 0; //0: randomly iterate, non-zero: sequencially iterate 
    var precision:double = 0.000001; //min_modularity.   
    var type_file:int = 0; // 0: unweighted, 1: weighted
    var passTimes:int = -1;  // -1: detect until be stopped itself, else detect decided times. 

    public  def checkArgs(args:Array[String])
    {
        Console.OUT.println("Check args!");
 
        filename = args(0);

        if(args.size > 1)
        {
            it_random = Int.parse(args(1));
            
            if(args.size > 2)
            {
                precision = Double.parse(args(2));
                
                if(args.size > 3)
                {
                    type_file = Int.parse(args(3));
                    
                    if (args.size > 4)
                    {
                        passTimes = Int.parse(args(4));  
                    }                    
                }               
            }
        }
    }

	public static def main(args:Array[String]) 
	{
    	val timer = new Timer();
        var start:Long = timer.milliTime();
 
        var cd:ComDetect = new ComDetect(); 
        cd.checkArgs(args);

        var readStart:Long = timer.milliTime();
    	//var com:Community = new Community(cd.filename, cd.type_file, cd.maxNode, cd.edgeNum, cd.passTimes, cd.precision);
       
        var com:Community = new Community(cd.filename, cd.type_file, cd.passTimes, cd.precision);
       
        var readEnd:Long = timer.milliTime();


    	var g:Graph = new Graph();
    	var improvement:boolean = true;
    	var mod:double = 0.0;
        
        mod = com.modularity();
    	
        var new_mod:double = 0.0; 
        var level:int = 0;
        var verbose:boolean = true;

        var resetTotal:Long = 0;
        var computeTotal:Long = 0;

        do{
            //if(verbose)
            //{
                Console.OUT.println("-------------------------------------------------------------------------------------------------------------");
                Console.OUT.println("level: " + level );
                Console.OUT.println("start computation");
                Console.OUT.println("network size:" + (com.g.nb_nodes + 1) + " nodes, " + com.g.nb_links + " links, " + com.g.total_weight + " weight.");
                level++;
            //}

            
 
            var startCompute:Long = timer.milliTime();
            
            improvement = com.one_level( level );
            
            var endCompute:Long = timer.milliTime();

            Console.OUT.println("It used "+(endCompute-startCompute)+"ms to Compute");
            

            computeTotal += (endCompute-startCompute);

            new_mod = com.modularity();

            var startReset:Long = timer.milliTime();
            
            g = com.resetCom(); //the same role as partition2graph in c++ version
            
            com = new Community(g, -1, cd.precision, com.inside_tmp);
            var endReset:Long = timer.milliTime();
            Console.OUT.println("It used "+(endReset-startReset)+"ms to Reset");
            resetTotal += (endReset-startReset);

            //if (verbose) 
            //{
            Console.OUT.println("mod -> new_mod: " + mod + "->" + new_mod);

            if (new_mod-mod <=0) {
                break;
                        
            }            
            //break;
            //}
            mod = new_mod;
            if (level == 1) 
            {
                improvement = true;    
            }

        }while(improvement);
	
        var end:Long = timer.milliTime();
        Console.OUT.println("Read: " + (readEnd - readStart) + "ms");
        Console.OUT.println("Compute: " + computeTotal + "ms");
        Console.OUT.println("Reset: " + resetTotal + "ms");
        Console.OUT.println("All: "+(end-start)+"ms");
        Console.OUT.println(new_mod);

    }
}
