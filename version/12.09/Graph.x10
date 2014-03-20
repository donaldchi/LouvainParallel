import x10.lang.*;
import x10.compiler.*;
import x10.util.*;
import x10.io.File;
import x10.io.FileReader;
import x10.lang.Error;
import x10.util.ArrayList;
import x10.util.List; 
import x10.lang.Math;
import x10.io.FileWriter;

public class Graph {
    var total_weight:double;
    var nb_nodes:int;
    var nb_links:int;
    
    var degrees:ArrayList[int];
    var links:ArrayList[int];
    var weights:ArrayList[double];
    var links_r:Array[ArrayList[Pair[int,double]]];

    var startIndex:int; //for iterating links and weights
    var deg:int;

    var indexs:Array[int];

    public def this()
    {
        links = new ArrayList[int]();
        weights = new ArrayList[double]();
        links.clear();
        weights.clear(); 
    }

    public def this( filename:String, filename_w:String, type_file:int)
    {
        val finput = new File(filename);
        val freader = finput.openRead();
        
        nb_nodes = freader.readInt();
        Console.OUT.println("nb_nodes = " + nb_nodes);
        
        degrees = new ArrayList[int](nb_nodes+1);
        degrees(0) = 0;
        deg = nb_nodes+1;
        for (startIndex=1; startIndex<deg; startIndex++) 
        {
            degrees(startIndex) = freader.readInt();
        }
        
        nb_links = degrees(nb_nodes);
        
        links = new ArrayList[int](nb_links);
        deg = nb_links;
        for (startIndex=0; startIndex<deg; startIndex++) {
            links(startIndex) = freader.readInt();
            //Console.OUT.println("links("+startIndex+")= " + links(startIndex));
        }

        weights = new ArrayList[double]();
        if (type_file == 1) 
        {
            val finput_w = new File(filename_w);
            val freader_w = finput_w.openRead();
            weights = new ArrayList[double](nb_links);
            deg = nb_links;
            for (startIndex=0; startIndex<deg; startIndex++) 
            {    
                weights(startIndex) = freader_w.readDouble();
            }
        }

        /*deg = nb_nodes;
        indexs = new Array[int](nb_nodes);
        for (startIndex=0; startIndex<deg; startIndex++) 
        {    
                indexs(startIndex) = freader.readInt();
        }*/

        total_weight = 0.0;
        for (startIndex=0; startIndex<nb_nodes; startIndex++) 
        {
            total_weight += weighted_degree(startIndex);    
        }

        Console.OUT.println("total_weight = " + total_weight);
        nb_nodes = nb_nodes - 1;
    }

    public def this( filename:String, type_file:int, maxNode:int, direct:int, do_renumber:boolean )
    {
        Console.OUT.println("In read file part!!");
        val finput = new File(filename);
        var keys:Array[String];
        var math:Math = new Math();

        //Console.OUT.println("maxNode, fileSize =" + maxNode + ", " + finput.size());

        links_r = new Array[ArrayList[Pair[int, double]]](maxNode+1);
        for (startIndex = 0; startIndex<=maxNode; startIndex++) 
        {
                links_r(startIndex) = new ArrayList[Pair[int, double]]();
        }

        nb_links = 0;
        for (line in finput.lines()) {
            var src:int;
            var dest:int;
            var weight:double = 1.0;

            keys = line.split(" ");

            if (type_file == 1) 
            {
                src = Int.parse(keys(0));
                dest = Int.parse(keys(1));
                weight = Int.parse(keys(2));    
            }
            else
            {
                src = Int.parse(keys(0));
                dest = Int.parse(keys(1));
            }
            
            links_r(src).add(new Pair(dest, weight));
            if (direct==1&&src!=dest) 
            {
                links_r(dest).add(new Pair(src,weight));
                nb_links++;
            }

            nb_links++;
        }
        Console.OUT.println("nb_links, links_r.size() = " + nb_links + ", " + links_r.size);
    }

    public  def this( filename:String, type_file:int, maxNode:int, edgeNum:int) //did not reset g.degrees
    {  
        nb_nodes = maxNode;

        degrees = new ArrayList[int](nb_nodes+1);
        links = new ArrayList[int]();
        weights = new ArrayList[double]();

        links.clear();
        weights.clear();
        nb_links = edgeNum;

        val finput = new File(filename);
        var keys:Array[String];
        var num:Int = 0; //iterate the edges num from the same src node
        var frontID:String = "0";
        var index:int = 0;
        
        for(line in finput.lines())
        {
            keys = line.split(" ");
            if(frontID.equals(keys(0)))
                {
                    num = num + 1;
                }
            else
                {   
                    if( index != 0 )
                        degrees(index) = ( num + degrees(index-1));
                    else
                        degrees(index) = ( num );
                    num = 1;
                    frontID = keys(0);
                    index++;
                }
            links.add(int.parse(keys(1)));
            if(type_file != 0)
                weights.add(double.parse(keys(2)));   
        }

        if(degrees.size() != 0)
            degrees(index) = ( num + degrees(index-1));
        else
            degrees(index) = ( num );

        for (var i:int = 0; i <= nb_nodes; i++) {
           total_weight += weighted_degree(i);
        }    
    }

    @Inline @NonEscaping final def weighted_degree( node:int ) 
    {
    //return sum of src node`s linked edge`s weight or the num of linked nodes
    //   val ae = new  AssertionError("Node`s ID not correct!!",(node < nb_nodes));
        
        var res:double = 0.0;

        if(weights.size()==0)
        {
            res = nb_neighbors(node); //it will use lots of time to convert//            
            
        }
        else
        {            
            /*if (node == 0) 
                startIndex = 0;
            else
                startIndex = degrees(node-1);*/
            startIndex = degrees(node) - degrees(0);
            deg = degrees(node+1) - degrees(0);

            for (var i:int = startIndex; i<deg; i++) {
                res += weights(i);
            }      
        }   

        return res;     
    }

     @Inline @NonEscaping final def  nb_neighbors( node:int)
    {
        //return the num of the linked node`s from this node
        //AssertionError("Node`s ID not correct!!",(node < nb_nodes));
        /*if( node == 0 ) 
            return degrees(0);
        else 
            return degrees( node ) - degrees( node-1 );*/
            return degrees( node+1 ) - degrees( node ); 
    }

    @Inline @NonEscaping final def nb_selfloops( node:int )
    {
        //AssertionError("Node`s ID not correct!!",(node < nb_nodes));
        
        /*if (node == 0) 
            startIndex = 0;
        else
            startIndex = degrees(node-1);
        deg = degrees(node);*/
        startIndex = degrees(node) - degrees(0);
        deg = degrees(node+1) - degrees(0);

        for (var i:int = startIndex; i<deg; i++)
        {
            //Console.OUT.println("i, links(i) -- " +i + ", " + links(i));
            if (links(i) == node) {
                if (weights.size()!=0)
                    return weights(i);
                else
                    return 1.0;
            }
        }
        return 0.0;
    }

    public def display_binary( filename:String, filename_w:String, type_file:int )
    {
        Console.OUT.println("in display_binary part!!");
        Console.OUT.println("filename, filename_w = " + filename + ", " + filename_w);
        val foutput = new File(filename);
        var fwriter:FileWriter = foutput.openWrite();
        deg = links_r.size;

        indexs = new Array[int](deg); //storage index info with degree
        //outputs number of nodes
        fwriter.writeInt(deg);

        var tot:int = 0;

        //outputs cumulative degree sequence
        for (startIndex=0; startIndex<deg; startIndex++) {
            tot += links_r(startIndex).size();
            indexs(startIndex) = links_r(startIndex).size();
            fwriter.writeInt(tot);
        }

        //outputs links
        for (startIndex=0; startIndex<deg; startIndex++) {
            for (var i:int=0; i<links_r(startIndex).size(); i++) {
                var dest:int = links_r(startIndex)(i).first;
                fwriter.writeInt(dest);
            }
        }

        //outputs indexs ordered by degree
        /*for (var j:int=0; j<indexs.size; j++) 
        {    
            var k:int = 0;
            for (var i:int=1; i<indexs.size; i++) 
            {
                if (indexs(i)>indexs(k)) 
                {
                    k=i;
                }
            }
            //Console.OUT.println("index - degree = " + k + " - " + indexs(k));
            indexs(k) = 0;
            fwriter.writeInt(k);

        }*/

        fwriter.close();
        //foutput.exists();

        //outputs weights in a separate file
        if (type_file == 1) {
            val foutput_w = new File(filename_w);
            var fwriter_w:FileWriter = foutput_w.openWrite();
            for (startIndex=0; startIndex<deg; startIndex++) 
            {
                for (var i:int=0; i<links_r(startIndex).size(); i++) 
                {
                    var weight:double = links_r(startIndex)(i).second;
                    fwriter_w.writeDouble(weight);
                }
            }
            fwriter_w.close();
            //foutput_w.exists();
        }
    }
    
    public def renumber(type_file:int)
    {
        /*var linked:Array[int] = new Array[int](links_r.size, -1);
        var renum:Array[int] = new Array[int](links_r.size, -1);
        var nb:int = 0;

        deg = links_r.size;
        for (startIndex=0; startIndex<deg; startIndex++) 
        {
            for (var i:int=0; i<links_r(startIndex).size(); i++) 
            {
                linked(i) = 1;
                linked(links_r(startIndex)(i).first) = 1;        
            }
        }

        for (startIndex=0; startIndex<deg; startIndex++) 
        {
            if (linked(startIndex)==1) 
            {
                    renum(i) = nb++;
            }    
        }

        for (startIndex=0; startIndex<deg; startIndex++) 
        {
            if (linked(startIndex)==1) 
            {
                for (var i:int=0; i<links_r(startIndex).size(); i++) 
                {
                    links_r(startIndex)(i).first =renum(links_r(startIndex)(i).first);
                }
                links_r(renum(startIndex)) = links_r(startIndex);
            }    
        }
        //links_r.resize();*/
    }

    public static def main(args: Array[String]) {
        val timer = new Timer();
        var start:Long = timer.milliTime();
        var fileName:String = "../../Data/BlondelMethod/arxiv.txt";
        val g = new Graph(fileName,0,9376,48214);
        
        var end:Long = timer.milliTime();
        Console.OUT.println("It used "+(end-start)+"ms");
    }
}