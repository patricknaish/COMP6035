
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.util.HashSet;
import java.util.Stack;

import org.aspectj.lang.Signature;
import org.aspectj.lang.reflect.MethodSignature;

/**
 * 
 * Aspect for graphing calls between methods annotated with @Graph,
 * excluding those which throw an exception during execution
 * 
 * @author Patrick
 *
 */
public aspect RefinedGraphAspect {	
	
	private static Stack<MethodSignature> methodStack = new Stack<>();
	private static HashSet<String> callSet = new HashSet<>();
	
	/* Static setup */
	static {
		
		/* Try to clear out an existing graphrefined.csv if one exists */
		try {
			if (Files.exists(new File("graphrefined.csv").toPath())) {
				Files.delete(new File("graphrefined.csv").toPath());
			}
		} catch (IOException e) {
			System.out.println("Couldn't delete graphrefined.csv... another process has a lock.");
			System.exit(1);
		}

		/* Add a shutdown hook to dump data to a file when JVM dies */
		Runtime.getRuntime().addShutdownHook(new Thread() {
			public void run() {
				try(FileWriter writer = new FileWriter("graphrefined.csv", true)) {
					for (String s: callSet) {
						writer.append(s+"\n");										
					}
				} catch (IOException e) {
					System.out.println("Couldn't output to graphrefined.csv");
					System.exit(1);
				}
			}
		});

	}

	/* Pointcut to match all methods annotated with @Graph */
	pointcut graph(): execution(@Graph * *.*(..));

	/* Pointcut to match all Exceptions thrown within a method annotated with @Graph */
	pointcut exception(): call(Exception.new(..)) && withincode(@Graph * *.*(..));

	
	/* If an exception occurs, pop the current method from the stack before a call is stored */
	before(): exception() {
		popMethod();
		/* Then empty out the stack (as execution of the main thread will not continue) */
		while (methodStack.size() > 0) {
			storeCall();
			popMethod();
		}
	}

	/* Push each method onto the stack before execution */
	before(): graph() {
		pushMethod(thisJoinPointStaticPart.getSignature());
	}

	/* Store the last method call, then pop the current method from the stack after execution */
	after() returning: graph() {
		storeCall();
		popMethod();
	}

	/* Store a representation of a method call in the HashSet */
	static void storeCall() {
		/* If there's only one method on the stack, no calls have occurred */
		if (methodStack.size() < 2) {
			return;
		} else {
			/* Get the top two items on the stack, and create a CSV entry to store in the HashSet */
			MethodSignature callerSignature = methodStack.get(methodStack.size() - 2);
			MethodSignature targetSignature = methodStack.peek();
			callSet.add("\""+callerSignature+"\",\""+targetSignature+"\"");
		}
	}

	/* Push a method signature onto the stack */
	static void pushMethod(Signature s) {
		methodStack.push((MethodSignature)s);
	}

	/* Pop a method signature from the stack */
	static void popMethod() {
		if (methodStack.size() > 0) {
			methodStack.pop();
		}
	}

}
