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
	private static HashMap<Integer,Long> timeOffset = new HashMap<>();
	
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
	
	/* Before execution of the method, push it onto the stack */
	before(): graph() {
		pushMethod(thisJoinPointStaticPart.getSignature());
	}

	/* After execution of the method, pop it off the stack */
	after(): graph() {
		popMethod();
	}
	
	/* Push the method signature onto the stack, along with the current time at the start of execution */
	static void pushMethod(Signature s) {
		methodStack.push(new AbstractMap.SimpleEntry<MethodSignature, Long>((MethodSignature)s,System.currentTimeMillis()));
	}

	/* Pop the method from the stack, as well as handling timing */
	static void popMethod() {
		
		/* Immediately get the time at the end of execution, to get the most accurate results */
		Long stopTime = System.currentTimeMillis();
		
		/* If there's nothing on the stack to pop, stop */
		if (methodStack.size() == 0) {
			return;
		}
		
		/* 
		 * Get the offsets for the current and next layer in the stack 
		 * These offsets contain the execution times for the layers, so
		 * as the stack unwinds, the execution time for a given layer
		 * is subtracted from the one above, giving the execution time 
		 * for that layer alone.                                       
		 */
		Long currentOffset = timeOffset.get(methodStack.size());
		Long nextOffset = timeOffset.get(methodStack.size()+1);
		
		/* If we're reaching this layer for the first time, store a 0 for offset */
		if (currentOffset == null) {
			timeOffset.put(methodStack.size(), 0L);
			currentOffset = 0L;
		}
		
		/* If the next layer down has an offset value... */
		if (nextOffset != null) {
			/* Subtract that from the current stop time (so that we have the execution time for the current method only) */
			stopTime -= nextOffset;
			/* Store 0 into the next layer down, as we've already accounted for it */
			timeOffset.put(methodStack.size()+1, 0L);
			/* Add the offset from the next layer down into the current layer, so the layer above can take it into account */
			timeOffset.put(methodStack.size(), currentOffset + nextOffset);
		}
		
		/* Get the current method off the stack */
		AbstractMap.SimpleEntry<MethodSignature, Long> entry = methodStack.pop();
		MethodSignature signature = entry.getKey();
		
		/* Calculate the time taken for the current method's execution */
		Long startTime = entry.getValue(), timeTaken = (stopTime - startTime);
		
		/* If there isn't currently an entry in the hashmap for this method signature... */
		if (perfMap.get(signature) == null) {
			/* Create a new one, with a single execution and the time taken for this run */
			perfMap.put(signature, new AbstractMap.SimpleEntry<Integer, Long>(1,timeTaken));
		} else {
			/* Otherwise, get the execution count and current average time */
			AbstractMap.SimpleEntry<Integer, Long> methodPerformance = perfMap.get(signature);
			Integer runCount = methodPerformance.getKey();
			Long avgTime = methodPerformance.getValue();
			/* Adjust the average to account for the new run, and increment the run counter */
			avgTime *= runCount++;
			avgTime += timeTaken;
			avgTime /= runCount;
			/* Store the new run count and average time in the hashmap */
			perfMap.put(signature, new AbstractMap.SimpleEntry<Integer, Long>(runCount,avgTime));
		}
		
		/* Add the current method's runtime to the offset for the current stack layer */
		timeOffset.put(methodStack.size()+1, currentOffset+timeTaken);
		
	}

}
