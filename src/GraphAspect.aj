import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.util.HashSet;
import java.util.Stack;

import org.aspectj.lang.Signature;
import org.aspectj.lang.reflect.MethodSignature;

public aspect GraphAspect {

	static {
		try {
			if (Files.exists(new File("graph.csv").toPath())) {
				Files.delete(new File("graph.csv").toPath());
			}
		} catch (IOException e) {
			e.printStackTrace();
		}

		Runtime.getRuntime().addShutdownHook(new Thread() {
			public void run() {
				try(FileWriter writer = new FileWriter("graph.csv", true)) {
					for (String s: callSet) {
						writer.append(s+"\n");										
					}
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		});

	}

	pointcut graph(): execution(@Graph * *.*(..));

	private static Stack<MethodSignature> methodStack = new Stack<>();
	private static HashSet<String> callSet = new HashSet<>();

	before(): graph() {
		pushMethod(thisJoinPointStaticPart.getSignature());
	}

	after(): graph() {
		writeCall();
		popMethod();
	}

	static void writeCall() {
		if (methodStack.size() < 2) {
			return;
		} else {
			MethodSignature callerSignature = methodStack.get(methodStack.size() - 2);
			MethodSignature targetSignature = methodStack.peek();
			callSet.add(callerSignature.getName()+","+targetSignature.getName());
		}
	}

	static void pushMethod(Signature s) {
		methodStack.push((MethodSignature)s);
	}

	static void popMethod() {
		methodStack.pop();
	}

}
