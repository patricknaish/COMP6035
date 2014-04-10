public class ProfilingTestClass {

	@Perf
	public void foo() {
		bar();
	}

	public void bar() {
		try {
			Thread.sleep(5000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		baz();
	}

	@Perf
	public void baz() {
		try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	public static void main(String[] args) throws Exception {
		new ProfilingTestClass().foo();
	}

}
