package org.rpgleparser.trydclprparsing;

import java.util.List;

import org.rpgleparser.RpgParser.AllContext;
import org.rpgleparser.RpgParser.Dcl_piContext;
import org.rpgleparser.RpgParser.Dcl_pi_fieldContext;
import org.rpgleparser.RpgParser.Dcl_prContext;
import org.rpgleparser.RpgParser.KeywordContext;
import org.rpgleparser.RpgParser.RContext;
import org.rpgleparser.RpgParserBaseListener;

public class RpgParserListener extends RpgParserBaseListener 
{
	@Override
	public void enterR(RContext ctx) 
	{
		super.enterR(ctx);
		System.out.println("enterR(RContext ctx)");
	}

	@Override
	public void exitR(RContext ctx) 
	{
		super.exitR(ctx);
		System.out.println("exitR(RContext ctx)");
	}

	@Override
	public void enterAll(AllContext ctx) 
	{
		super.enterAll(ctx);
		//System.out.println("enterAll(AllContext ctx)");
	}

	@Override
	public void enterDcl_pr(Dcl_prContext ctx) 
	{
		super.enterDcl_pr(ctx);
		System.out.println("enterDcl_pr(Dcl_prContext ctx)");
	}

	@Override
	public void exitDcl_pr(Dcl_prContext ctx) 
	{
		super.exitDcl_pr(ctx);
		System.out.println("exitDcl_pr(Dcl_prContext ctx)");
	}

	@Override
	public void enterDcl_pi(Dcl_piContext ctx) 
	{
		super.enterDcl_pi(ctx);
		System.out.println("enterDcl_pi(Dcl_piContext ctx)");
	}

	@Override
	public void exitDcl_pi(Dcl_piContext ctx) 
	{
		super.exitDcl_pi(ctx);
		System.out.println("exitDcl_pi(Dcl_piContext ctx)");
		
		String identifierText = ctx.identifier().getText();
		System.out.println("identifierText: " + identifierText);
		
		//ctx.datatype()
		
		List<KeywordContext> keywords = ctx.keyword();
		for (KeywordContext keywordContext : keywords) {
			String keywordText = keywordContext.getText();
			System.out.println("keywordText: " + keywordText);
		}
		
		
		List<Dcl_pi_fieldContext> dcl_pi_field = ctx.dcl_pi_field();
		for (Dcl_pi_fieldContext dcl_pi_fieldContext : dcl_pi_field) {
			String fieldIdentifierText = dcl_pi_fieldContext.identifier().getText();
			String fieldDatatypeText = dcl_pi_fieldContext.datatype().getText();
			
			System.out.println("fieldIdentifierText: " + fieldIdentifierText);
			System.out.println("fieldDatatypeText: " + fieldDatatypeText);
		}
		
		System.out.println("");
	}
}
