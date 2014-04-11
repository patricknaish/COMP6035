import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.util.AbstractMap;
import java.util.HashMap;
import java.util.Map;
import java.util.Stack;
import org.aspectj.lang.Signature;
import org.aspectj.lang.reflect.MethodSignature;

/**
 * 
 * Aspect for profiling performance on methods annotated with @Perf
 * 
 * @author Patrick
 *
 */
public aspect ProfilingAspect {

	private static Stack<AbstractMap.SimpleEntry<MethodSignature, Long>> methodStack = new Stack<>();
	private static HashMap<MethodSignature, AbstractMap.SimpleEntry<Integer, Long>> perfMap = new HashMap<>();
	
	/* Static setup */
	static {
		
		/* Try to clear out an existing profile.csv if one exists */
		try {
			if (Files.exists(new File("profile.csv").toPath())) {
				Files.delete(new File("profile.csv").toPath());
			}
		} catch (IOException e) {
			System.out.println("Couldn't delete profile.csv... another process has a lock.");
			System.exit(1);
		}

		/* Add a shutdown hook to dump data to a file when JVM dies */
		Runtime.getRuntime().addShutdownHook(new Thread() {
			public void run() {
				try(FileWriter writer = new FileWriter("profile.csv", true)) {
					/* Iterate through the hashmap of method signatures, writing them as CSV */
					for (Map.Entry<MethodSignature, AbstractMap.SimpleEntry<Integer, Long>> entry: perfMap.entrySet()) {
						MethodSignature signature = entry.getKey();
						AbstractMap.SimpleEntry<Integer, Long> methodPerformance = entry.getValue();
						Integer runCount = methodPerformance.getKey();
						Long avgTime = methodPerformance.getValue();
						writer.append("\""+signature+"\","+(avgTime/1000.0)+","+runCount+"\n");										
					}
				} catch (IOException e) {
					System.out.println("Couldn't output to profile.csv");
					System.exit(1);
				}
			}
		}); 
	}

	/* Pointcut to match all methods annotated with @Perf */
	pointcut graph(): execution(@Perf * *.*(..));
	
	before(): graph() {
		while (methodStack.size() > 0) {
			popMethod();
		}
		pushMethod(thisJoinPointStaticPart.getSignature());
	}

	after(): graph() {
		popMethod();
	}
	
	static void pushMethod(Signature s) {
		methodStack.push(new AbstractMap.SimpleEntry<MethodSignature, Long>((MethodSignature)s,System.currentTimeMillis()));
	}

	static void popMethod() {
		if (methodStack.size() == 0) {
			return;
		}
		
		Long stopTime = System.currentTimeMillis();
		
		AbstractMap.SimpleEntry<MethodSignature, Long> entry = methodStack.pop();
		MethodSignature signature = entry.getKey();
		
		Long startTime = entry.getValue(), timeTaken = stopTime - startTime;
		
		if (perfMap.get(signature) == null) {
			perfMap.put(signature, new AbstractMap.SimpleEntry<Integer, Long>(1,timeTaken));
			System.out.println(signature.getName()+": "+timeTaken);
		} else {
			AbstractMap.SimpleEntry<Integer, Long> methodPerformance = perfMap.get(signature);
			Integer runCount = methodPerformance.getKey();
			Long avgTime = methodPerformance.getValue();
			avgTime *= runCount++;
			avgTime += timeTaken;
			avgTime /= runCount;
			perfMap.put(signature, new AbstractMap.SimpleEntry<Integer, Long>(runCount,avgTime));
		}
	}

}
