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

public class TestLoggingListener {

	public static void main(String[] args) throws IOException 
	{
		//String fname = "F:\\RDi95Wks\\192.168.21.102_XA5400\\QRPGLESRC\\LE0025R2.SQLRPGLE";
		String fname = "F:\\RDi95Wks\\192.168.21.102_XA5400\\QRPGLESRC\\LE0025R2woFREE.SQLRPGLE";
		
		
		List<String> errors = new ArrayList<String>();
		File file = new File(fname);
		
		String rpgsource = TestUtils.loadFile(file);
		
		System.out.println("rpgsource: " + rpgsource);
		System.out.println("\n");
		
        rpgsource = TestUtils.padSourceLines(rpgsource, true);
		
        System.out.println("rpgsource: " + rpgsource);
        System.out.println("\n");
        
//        List<CommonToken> tokenList = TestUtils.getParsedTokens(rpgsource, errors);
//        if (errors.size() > 0) {
//       		System.out.println("The failing file is :"  + file.getName());
//        	errors.clear();
//        }
//        
//        for (CommonToken token : tokenList) 
//        {
//			System.out.println(token);
//		}
//        //System.out.println(tokenList);
        
        //----------------------------------------------------
		
		
		
//		//InputStream is;
//		FileInputStream fis = new FileInputStream(fname);
//		//is = fis;
//		ANTLRInputStream input = new ANTLRInputStream(fis);
//		
//		RpgLexer lexer = new RpgLexer(input);
//		CommonTokenStream tokens = new CommonTokenStream(lexer);
//		
//		RpgParser parser = new RpgParser(tokens);
//		
//		RpgParser.RContext parseTree = parser.r();
//		
//		ParseTreeWalker walker = new ParseTreeWalker();
//		walker.walk(new TestRpgParserListener(), parseTree);
//		
//		System.out.println();
//		
//		//is.close();
        
        
        
//		//InputStream is;
//		FileInputStream fis = new FileInputStream(fname);
//		//is = fis;
		ANTLRInputStream input = new ANTLRInputStream(rpgsource);
		
		RpgLexer lexer = new RpgLexer(input);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		
		RpgParser parser = new RpgParser(tokens);
		
		RpgParser.RContext parseTree = parser.r();
		
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
		
		ParseTreeWalker walker = new ParseTreeWalker();
		walker.walk(new TestRpgParserListener(), parseTree);
		
		System.out.println();        
	}

}
