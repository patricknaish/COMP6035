import java.util.Random;

public class ProfilingTestClass {

	@Perf
	public void foo(String l, String x) {
		bar();
		try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	public void bar() {
		try {
			Thread.sleep(5000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		baz();
		baz();
		baz();
	}

	@Perf
	public void baz() {
		try {
			Integer timeout = Math.abs(new Random().nextInt() % 1000);
			System.out.println("baz() timeout is " + timeout);
			Thread.sleep(timeout);
			bat();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	@Perf
	public void bat() {
		try {
			Thread.sleep(100);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	public static void main(String[] args) throws Exception {
		new ProfilingTestClass().foo("l", "x");
	}

}
