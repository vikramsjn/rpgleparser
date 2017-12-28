package org.rpgleparser.trydclprparsing;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonToken;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTreeWalker;
import org.rpgleparser.RpgLexer;
import org.rpgleparser.RpgParser;
import org.rpgleparser.utils.TestUtils;

public class TestFullyFreeRpgParsing {

	public static void main(String[] args) throws IOException 
	{
		String userDir = System.getProperty("user.dir");
		System.out.println("userDir: " + userDir);
		
		// NOTE: Reading LE0025R2.SQLRPGLE - parsing failed because ** was taken as "End of source"
		// Also for now simply copied these file at the root - but if more then place properly
		// This program taken from: Library XA5400, related to issue XA-5400
		
		//String fname = "F:\\RDi95Wks\\192.168.21.102_XA5400\\QRPGLESRC\\LE0025R2.SQLRPGLE";
		//String fname = "F:\\RDi95Wks\\192.168.21.102_XA5400\\QRPGLESRC\\LE0025R2woFREE.SQLRPGLE";
		String fname = "LE0025R2woFREE.SQLRPGLE";
		
		List<String> errors = new ArrayList<String>();
		File file = new File(fname);
		
		String rpgsource = TestUtils.loadFile(file);
		
		System.out.println("original rpgsource: " + rpgsource);
		System.out.println("\n");
		
		// This pads 8 char space at start of every line
		// + makes every line 112 char long - as generally source record len is 112
        rpgsource = TestUtils.padSourceLines(rpgsource, true);
		
        System.out.println("padded rpgsource: " + rpgsource);
        System.out.println("\n");
        
		ANTLRInputStream input = new ANTLRInputStream(rpgsource);
		
		RpgLexer lexer = new RpgLexer(input);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		
		RpgParser parser = new RpgParser(tokens);
		
		RpgParser.RContext parseTree = parser.r();
		
		// Dump the tokens for review
		//---------------
		List<CommonToken> tokenList = new ArrayList<CommonToken>();
		for (int i = 0; i < parseTree.getChildCount(); i++) 
		{
			TestUtils.fillTokenList(parseTree.getChild(i), tokenList);
		}

		for (CommonToken token : tokenList) 
		{
			System.out.println(token);
		}
		//---------------
		
		// Parser the tree to collect items of interest
		ParseTreeWalker walker = new ParseTreeWalker();
		walker.walk(new RpgParserListener(), parseTree);
		
		System.out.println();        
	}

}
