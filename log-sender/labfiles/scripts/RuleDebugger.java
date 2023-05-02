import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintStream;
import java.io.Serializable;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.BitSet;
import java.util.Collection;
import java.util.List;

import com.q1labs.ariel.ICursor;
import com.q1labs.ariel.ui.QueryHandle;
import com.q1labs.ariel.ui.UIArielServices;
import com.q1labs.ariel.ui.bean.ArielForm;
import com.q1labs.ariel.ui.bean.ArielSearchForm;
import com.q1labs.core.dao.ariel.ArielProperty;
import com.q1labs.core.dao.cre.CustomRule;
import com.q1labs.core.dao.cre.rules.gen.ParameterType;
import com.q1labs.core.dao.cre.rules.gen.TestType;
import com.q1labs.core.shared.cre.CustomRuleNode;
import com.q1labs.core.types.event.NormalizedEvent;
import com.q1labs.frameworks.core.FrameworksContext;
import com.q1labs.frameworks.exceptions.FrameworksException;
import com.q1labs.frameworks.session.ISessionContext;
import com.q1labs.semsources.cre.CRE;
import com.q1labs.semsources.cre.CREResult;
import com.q1labs.semsources.cre.CustomRuleReader;
import com.q1labs.semsources.cre.CustomRuleSet;
import com.q1labs.semsources.cre.tests.ICREEventTest;

import au.com.bytecode.opencsv.CSVReader;
import gnu.trove.TIntObjectHashMap;

public class RuleDebugger
{
	/*
	 *	javac -cp "/opt/qradar/jars/*" RuleDebugger.java
	 * 	java -cp "/opt/qradar/jars/*:." RuleDebugger
	 * 
	 */

	private static ISessionContext session;

	public static void main(String[] args)
	{

		System.out.println("----- Rule debugger -----");

		if(args.length < 3 || Integer.parseInt(args[1]) < 1)
		{
			System.out.println("wrong arguments, the correct syntax is");
			System.out.println("java -cp \"/opt/qradar/jars/*:.\" RuleDebugger fileName eventLineNumber rulename");
			System.out.println("**** usage example*****");
			System.out.println("java -cp \"/opt/qradar/jars/*:.\" RuleDebugger events.csv 1 \"rule name\"");
			System.out.println("the header in the event file is optional");
			System.out.println("event line number starts from 1 (without counting the header if exist)");

			System.exit(10);
		}

		System.out.println("DataSource: " + args[0]);
		System.out.println("event Number # " + args[1]);


		try
		{
			session = FrameworksContext.initFrameworks().createSessionContext();
			session.beginDatabaseRead();
		} catch (FrameworksException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}



		// the following to suppress SLF4J Warning about multiple bindings, later on the problem can be solved with the class path
		PrintStream filterOut = new PrintStream(System.err) {
			public void println(String l) {
				if (! l.startsWith("SLF4J") )
					super.println(l);
			}
		};
		System.setErr(filterOut);


		int selectedIndex = Integer.parseInt(args[1])-1;

		NormalizedEvent selectedEvent = null;
		if(args[0].endsWith(".csv"))
		{
			selectedEvent = RuleDebugger.importEvents(args[0]).get(selectedIndex);
		}
		else if(args[0].startsWith("handleId"))
		{
			//handleId=65157a28-8091-44b5-8a37-6b7161525c5c
			selectedEvent = getNormalizedEventFromSearchHandleId(args[0].split("=")[1],selectedIndex);
		}
		else
		{
			System.out.println("Wrong arguments");
			
			System.exit(0);
		}
		

		BitSet bitset = new BitSet(new CustomRuleSet().getMaxID());

		int ruleID = (int) getRuleIDFromRuleName(session, args[2]).getId();

		evaluateRule(ruleID,selectedEvent,bitset);

		session.endDatabaseRead();
		System.exit(0);
	}

	public static CustomRule getRuleIDFromRuleName(ISessionContext session, String ruleName)
	{
		StringBuilder sql = new StringBuilder("SELECT * FROM custom_rule WHERE");
		sql.append(" convert_from(rule_data,'UTF8') like '%<name>");
		sql.append(escapeForLike(ruleName, "\t"));
		sql.append("</name>%' ESCAPE '\t'");
		List<CustomRule> resultList = (List<CustomRule>)session.getPersistenceSession().createNativeQuery(sql.toString(), (Class)CustomRule.class).getResultList();

		return (resultList.size()>0)?resultList.get(0):null;
	}

	private static String escapeForLike(String value, final String escapeValue) {
		value = value.replace("\\", "\\\\");
		value = value.replace("'", "''");
		value = value.replace("_", escapeValue + "_");
		value = value.replace("%", escapeValue + "%");
		return value;
	}

	public static boolean evaluateRule(int ruleID, NormalizedEvent event, BitSet bitset)
	{
		boolean ruleOverAllRank = true;

		try 
		{
			CustomRuleReader ruleReader = new CustomRuleReader(1, new CRE());
			ruleReader.start();

			//CustomRule customRule = (CustomRule)session.getPersistenceSession().queryForSingleResult("SELECT r FROM CustomRule r WHERE r.id in("+ruleID+")", new Object[0]);

			CustomRule customRule = (CustomRule)session.createPersistentObject("CustomRule", (Serializable)new Long(ruleID));

			printRuleHeaders(customRule);

			CustomRuleNode customRuleNode = customRule.getRule();

			TIntObjectHashMap<CustomRule> ruleMap = new TIntObjectHashMap<CustomRule>();

			com.q1labs.semsources.cre.CustomRule customrule = new com.q1labs.semsources.cre.CustomRule(customRuleNode.getRule(),ruleMap,12,ruleReader); 
			//customrule.getRuleMap().put(ruleID, customrule);
			//ruleMap = customrule.getRuleMap();


			List<TestType> testList = (List<TestType>)customRuleNode.getRule().getTestDefinitions().getTest();

			for (int i = 0; i < testList.size(); i++) 
			{
				System.out.println("---------------------------------------");
				TestType test = testList.get(i);
				final Class c = Class.forName(test.getName());
				final ICREEventTest testObj = (ICREEventTest) c.newInstance();

				testObj.init(test, ruleMap, customrule);
				testObj.postInit();

				// resolving the dependent rules

				for(int j = 0 ; j < testObj.getDependents().size() ; j++)
				{
					int innerruleID = testObj.getDependents().toArray()[j]; 
					System.out.println("\t*** checking internal dependent rule");
					boolean innerRuleResult = evaluateRule(innerruleID, event,bitset);

					if(!innerRuleResult)
					{
						bitset.clear(innerruleID);
					}
				}

				CREResult testResult = testObj.test(event, bitset, null);
				/*System.out.println("Test Name "+ testList.get(i).getName());
				System.out.println("Test Name "+ testList.get(i).getRequiredCapabilities());
				if(testList.get(i).getParameter().size() > 0)
				{
					System.out.println("input parameters are ");
					List<ParameterType> parameterList = testList.get(i).getParameter();

					for (ParameterType parameterType : parameterList)
					{
						System.out.println("parms data");
						System.out.println(parameterType.getInitialText());
						System.out.println(parameterType.getName());
						System.out.println(parameterType.getUserSelection());
						System.out.println(parameterType.toString());
					}

					System.out.println("================================");
				}*/


				String conditionText = testList.get(i).getText().replaceAll("<a href='javascript:editParameter\\(\"\\d\", \"\\d\"\\)' class='dynamic'", "").replaceAll("</a>", "");

				if(!testObj.isNegate())
				{

					System.out.println(ruleID + "\t" + conditionText + "\t--> " + testResult.isFullMatch());

					if(testResult.isFullMatch())
					{
						bitset.set(ruleID);
					}
					else
					{
						ruleOverAllRank = false;
					}

				}
				else
				{
					conditionText = "NOT " + conditionText;
					System.out.println(ruleID + "\t" + conditionText + "\t--> " + !testResult.isFullMatch());

					if(!testResult.isFullMatch())
					{
						bitset.set(ruleID);
					}
					else
					{
						ruleOverAllRank = false;
					}
				}


			}


		} catch (FrameworksException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(10);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(10);
		}

		System.out.println("rule overall rank for ruleID "+ ruleID + " is "+ruleOverAllRank);

		return ruleOverAllRank;
	}

	public static void printRuleHeaders(CustomRule rule)
	{
		System.out.println("rule ID: "+ rule.getId());
		System.out.println("rule Name: "+ rule.getRule().getName());
		//System.out.println("rule XML\n" + rule.getRuleXml());
	}


	public static ArrayList<NormalizedEvent> importEvents(String fileName)
	{

		ArrayList<NormalizedEvent> eventsArrayList = new ArrayList<NormalizedEvent>();

		try
		{

			CSVReader reader = new CSVReader(new FileReader(fileName));

			String [] nextLine;

			while ((nextLine = reader.readNext()) != null)
			{

				if(nextLine[0].equals("magnitude")) // to skip the header if exist
				{
					continue;
				}

				NormalizedEvent event = null;
				//event = events[i] = new NormalizedEvent();
				event = new NormalizedEvent();


				event.setQid(Integer.parseInt(nextLine[55]));
				event.setPayload(nextLine[54].getBytes());

				event.setUsername(nextLine[67]);

				event.setSourceIP(ipToInt(nextLine[9]));
				event.setSourcePort(Short.parseShort(nextLine[10]));

				event.setDestinationIP(ipToInt(nextLine[7]));
				event.setDestinationPort(Short.parseShort(nextLine[8]));

				event.setStartTime(Long.parseLong(nextLine[3]));
				event.setStopTime(Long.parseLong(nextLine[4]));

				event.setProtocol(Short.parseShort(nextLine[1]));

				event.setCategory(Short.parseShort(nextLine[46]));

				event.setDeviceId(Integer.parseInt(nextLine[50]));

				event.setEventCount(Integer.parseInt(nextLine[61]));

				event.setDomainID(Integer.parseInt(nextLine[16]));


				event.setDstMACAddress(nextLine[69]);
				event.setSrcMACAddress(nextLine[70]);

				event.setCredibility(Integer.parseInt(nextLine[47]));
				event.setSeverity(Integer.parseInt(nextLine[56]));
				event.setRelevance(Integer.parseInt(nextLine[58]));

				// deviceCategory and deviceType

				getCustomProperties(event, nextLine[13].replaceAll("\\{|\\}", ""));

				eventsArrayList.add(event);
				//i++;
			}



		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(10);

		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(10);
		}

		return eventsArrayList;
	}

	public static void getCustomProperties(NormalizedEvent event, String customProperties)
	{

		String[] splittedCustomProperties = customProperties.split(", ");

		for (int i = 0; i < splittedCustomProperties.length; i++)
		{
			String[] inner = splittedCustomProperties[i].split("=");
			// inner[0] is the custom property name 
			int propertySequenceID = ArielProperty.getByName(session, inner[0]).getSequenceid();
			event.addCustomProperty(propertySequenceID, (short)0, (short)inner[1].length(), inner[1]);
			//System.out.println("parsing custom "+ inner[0] + "->"+inner[1]);
		}

	}

	private static int ipToInt(String input)
	{
		InetAddress ip = null;
		int intRepresentation = -1;
		try {
			ip = InetAddress.getByName(input);
		} catch (UnknownHostException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		intRepresentation= ByteBuffer.wrap(ip.getAddress()).getInt();

		return intRepresentation;
	}

	private static NormalizedEvent getNormalizedEventFromSearchHandleId(String handleID, int recordNumber)
	{

		UIArielServices arielSvc = UIArielServices.getInstance();

		QueryHandle queryHandle = arielSvc.fetchQuery(session, handleID);

		ArielSearchForm searchForm = queryHandle.getSearch();

		Collection<ArielForm> results = new ArrayList<ArielForm>();

		ICursor cursor = arielSvc.getCursor(session, queryHandle, true);

		// if (handle != null)
		// if (cursor.size() > 0)

		try {

			Collection<Object> records = (Collection<Object>)cursor.getSorted(0, cursor.size());
			int recordIndex = 0;
		
			for (Object record : records)
			{
				if(recordIndex != recordNumber)
				{
					continue;
				}
				
				NormalizedEvent normalizedEvent = (NormalizedEvent) record;
				
				System.out.println(normalizedEvent.getQid());
				
				return normalizedEvent;
			}


		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}


		return null;
	}
}
