
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.util.Stack;

import org.aspectj.lang.Signature;
import org.aspectj.lang.reflect.MethodSignature;

public aspect RefinedGraphAspect {	
	static {
		try {
			if (Files.exists(new File("graphrefined.csv").toPath())) {
				Files.delete(new File("graphrefined.csv").toPath());
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	pointcut graph(): execution(@Graph * *.*(..));

	private static Stack<MethodSignature> methodStack = new Stack<>();

	before() : graph() {
		pushMethod(thisJoinPointStaticPart.getSignature());
		writeCall();
	}

	after() throwing (Exception ex): graph() {
		popMethod();
	}

	static void printCall() {
		if (methodStack.size() < 2) {
			return;
		} else {
			MethodSignature callerSignature = methodStack.get(methodStack.size() - 2);
			MethodSignature targetSignature = methodStack.peek();

			String[] callerParameterNames = callerSignature.getParameterNames();
			Class<?>[] callerParameterTypes = callerSignature.getParameterTypes();

			String[] targetParameterNames = targetSignature.getParameterNames();
			Class<?>[] targetParameterTypes = targetSignature.getParameterTypes();

			StringBuilder csb = new StringBuilder();
			csb.append(callerSignature.getName() + "(");
			for (int i = 0; i < callerParameterNames.length; i++) {
				csb.append(callerParameterTypes[i].getSimpleName());
				csb.append(" ");
				csb.append(callerParameterNames[i]);
				if (i < callerParameterNames.length - 1) {
					csb.append(", ");
				}
			}
			csb.append(")");

			StringBuilder tsb = new StringBuilder();
			tsb.append(targetSignature.getName() + "(");
			for (int i = 0; i < targetParameterNames.length; i++) {
				tsb.append(targetParameterTypes[i].getSimpleName());
				tsb.append(" ");
				tsb.append(targetParameterNames[i]);
				if (i < targetParameterNames.length - 1) {
					tsb.append(", ");
				}
			}
			tsb.append(")");

			try(FileWriter writer = new FileWriter("graphrefined.csv", true)) {
				writer.append("\""+csb.toString() + "\",\"" + tsb.toString()+"\"\n");
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	static void writeCall() {
		if (methodStack.size() < 2) {
			return;
		} else {
			MethodSignature callerSignature = methodStack.get(methodStack.size() - 2);
			MethodSignature targetSignature = methodStack.peek();

			try(FileWriter writer = new FileWriter("graphrefined.csv", true)) {
				writer.append(callerSignature.getName()+","+targetSignature.getName()+"\n");
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	static void pushMethod(Signature s) {
		methodStack.push((MethodSignature)s);
	}

	static void popMethod() {
		methodStack.pop();
	}

}
