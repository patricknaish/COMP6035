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
 * Aspect for graphing calls between methods annotated with @Graph
 * 
 * @author Patrick
 *
 */
public aspect GraphAspect {

	private static Stack<MethodSignature> methodStack = new Stack<>();
	private static HashSet<String> callSet = new HashSet<>();
	
	/* Static setup */
	static {
		
		/* Try to clear out an existing graph.csv if one exists */
		try {
			if (Files.exists(new File("graph.csv").toPath())) {
				Files.delete(new File("graph.csv").toPath());
			}
		} catch (IOException e) {
			System.out.println("Couldn't delete graph.csv... another process has a lock.");
			System.exit(1);
		}

		/* Add a shutdown hook to dump data to a file when JVM dies */
		Runtime.getRuntime().addShutdownHook(new Thread() {
			public void run() {
				try(FileWriter writer = new FileWriter("graph.csv", true)) {
					for (String s: callSet) {
						writer.append(s+"\n");										
					}
				} catch (IOException e) {
					System.out.println("Couldn't output to graph.csv");
					System.exit(1);
				}
			}
		});
		
	}

	/* Pointcut to match all methods annotated with @Graph */
	pointcut graph(): execution(@Graph * *.*(..));

	/* Push each method onto the stack before execution */
	before(): graph() {
		pushMethod(thisJoinPointStaticPart.getSignature());
	}

	/* Store the last method call, then pop the current method from the stack after execution */
	after(): graph() {
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
