
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.util.AbstractMap;
import java.util.HashSet;
import java.util.Stack;

import org.aspectj.lang.Signature;
import org.aspectj.lang.reflect.MethodSignature;


public aspect ProfilingAspect {

	static {
		try {
			if (Files.exists(new File("profile.csv").toPath())) {
				Files.delete(new File("profile.csv").toPath());
			}
		} catch (IOException e) {
			e.printStackTrace();
		}

		Runtime.getRuntime().addShutdownHook(new Thread() {
			public void run() {
				try(FileWriter writer = new FileWriter("profile.csv", true)) {
					for (String s: callSet) {
						writer.append(s+"\n");										
					}
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		});

	}

	pointcut graph(): execution(@Perf * *.*(..));

	private static Stack<AbstractMap.SimpleEntry<MethodSignature, Long>> methodStack = new Stack<>();
	private static HashSet<String> callSet = new HashSet<>();

	before(): graph() {
		pushMethod(thisJoinPointStaticPart.getSignature());
	}

	after(): graph() {
		popMethod();
	}

	static void writeCall() {
		if (methodStack.size() < 2) {
			return;
		} else {
			MethodSignature callerSignature = methodStack.get(methodStack.size() - 2).getKey();
			MethodSignature targetSignature = methodStack.peek().getKey();
			callSet.add(callerSignature.getName()+","+targetSignature.getName());
		}
	}

	static void startTimer(Signature s) {
		
	}
	
	static void pushMethod(Signature s) {
		methodStack.push(new AbstractMap.SimpleEntry<MethodSignature, Long>((MethodSignature)s,System.currentTimeMillis()));
	}

	static void popMethod() {
		Long stopTime = System.currentTimeMillis();
		AbstractMap.SimpleEntry<MethodSignature, Long> entry = methodStack.pop();
	}

}
