import x10.compiler.Native;
import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;
@NativeCPPInclude("MyCppCode.h")
@NativeCPPCompilationUnit("MyCppCode.cc")
public class mapred
{
	public static def main(args:Array[String](1))
	{
		{@Native ("c++","foo();"){}}
	}
}