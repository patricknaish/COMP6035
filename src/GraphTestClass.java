public class GraphTestClass {

	@Graph
	public void foo(String s, String l) throws Exception {
		bar();
	}

	public void bar() throws Exception {
		baz();
	}

	@Graph
	public void baz() throws Exception {
		throw new Exception("I am the Great Exceptio!");
	}

	public void lol() {
		System.out.println("Hello");
	}

	@Graph
	public static void main(String[] args) throws Exception {
		new GraphTestClass().foo("s", "l");
	}
}
