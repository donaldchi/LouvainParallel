/* 
 *  This file is part of the ScaleGraph project (https://sites.google.com/site/scalegraph/).
 * 
 *  This file is licensed to You under the Eclipse Public License (EPL);
 *  You may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *      http://www.opensource.org/licenses/eclipse-1.0.php
 * 
 *  (C) Copyright ScaleGraph Team 2011-2012.
 */

import x10.compiler.Inline;
import x10.util.Team;
import x10.util.ArrayList;
import x10.util.concurrent.AtomicLong;
import x10.io.SerialData;
import x10.io.File;
import x10.io.FileReader;
import x10.io.FileWriter;
import x10.io.IOException;
import x10.util.Pair;
import x10.util.Timer;

import org.scalegraph.io.SimpleText;
import org.scalegraph.io.CSV;
import org.scalegraph.util.Dist2D;
import org.scalegraph.util.Parallel;
import org.scalegraph.fileread.DistributedReader;
import org.scalegraph.blas.DistSparseMatrix;
import org.scalegraph.graph.Graph;
import org.scalegraph.blas.SparseMatrix;
import org.scalegraph.util.tuple.*;
import org.scalegraph.metrics.DistBetweennessCentrality;
import org.scalegraph.util.DistMemoryChunk;

public class SGGraph {

    var total_weight:double;
    var nb_nodes:int;
    var nb_links:long;
    
    var degrees:ArrayList[int];
    var links:ArrayList[int];
    var weights:ArrayList[double];
    var links_r:Array[ArrayList[Pair[int,double]]];

    var startIndex:int; //for iterating links and weights
    var deg:int;

    var indexs:Array[int];

    var graph:Graph;

    public def this()
    {

    }

    public def this( filename:String, type_file:int, direct:int, do_renumber:boolean )
    { //using when read data for converting
        Console.OUT.println("In read file part!!");
        graph = Graph.make(SimpleText.read(filename, inputFormat));

        var keys:Array[String];
        var math:Math = new Math();
        var maxNode:int = Int.operator_as(graph.numberOfVertices() - 1);

        links_r = new Array[ArrayList[Pair[int, double]]](maxNode+1);
        for (startIndex = 0; startIndex<=maxNode; startIndex++) 
        {
                links_r(startIndex) = new ArrayList[Pair[int, double]]();
        }

        nb_links = 0;
        nb_links = direct == 1 ? graph.numberOfEdges()*2 : graph.numberOfEdges();
        var src:int;
        var dest:int;
        var weight:double = 1.0;

        val srcMChunk = graph.source().operator()();
        val dstMchunk =  graph.target().operator()();

        for ( var i:int = 0; i < srcMChunk.size(); i++) {
            src = Int.operator_as(srcMChunk(i));
            dest = Int.operator_as(dstMchunk(i));
            links_r(src).add(new Pair(dest, weight));
            if (direct==1&&src!=dest) 
            {
                links_r(dest).add(new Pair(src,weight));
            }
            //Console.OUT.println("src, dest::" + src + ", " + dest );
        }

        Console.OUT.println("nb_links, nodes = " + nb_links + ", " + links_r.size);
    }

    public def display_binary( filename:String, filename_w:String, type_file:int )
    {   //using when convert to binary data and write them as a binary file
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

        fwriter.close();

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
    
    public static val inputFormat = (s: String) => {
        val items = s.split(" ");
        try {
            val x = Long.parse(items(0).trim());
            val y = Long.parse(items(1).trim());
            
        } catch(e: Exception) {
            Console.OUT.println(items(0).trim() + " " + items(1).trim());
        }
        return Tuple3[long, long, double] (
                Long.parse(items(0).trim()),
                Long.parse(items(1).trim()),
                0.0
        );
    };
    
    public static def main(args: Array[String]) {
        if (args.size < 1) {
            Console.OUT.println("Please enter file");
            return;
        }
        
       // Load Graph
        // The weight is stored as an edge atrribute named "weight".
        val readStart:Long = Timer.milliTime();

        val g = Graph.make(SimpleText.read(args(0), inputFormat));
        
        val readEnd:Long = Timer.milliTime(); 

        Console.OUT.println("node, edge:" + g.numberOfVertices() + ", " + g.numberOfEdges());

        Console.OUT.println("Used " + (readEnd - readStart) + " ms");
        Console.OUT.println("Complete!");
    }
}

