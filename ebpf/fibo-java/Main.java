import java.math.BigInteger;

public class Main {
	public static BigInteger fibonacci(BigInteger n){
		BigInteger f2 = BigInteger.ZERO;
		BigInteger f1 = BigInteger.ONE;

		if (n == BigInteger.valueOf(1)) {
			return f2;
		}
		if (n == BigInteger.valueOf(2)) {
			return f1;
		}

		for(int i = 3; n.compareTo(BigInteger.valueOf(i)) >= 0; i++) {
			BigInteger next = f2.add(f1);
			f2 = f1;
			f1 = next;
		}
		return f1;
	}

  public static void main(String[] args) {
	BigInteger n = BigInteger.ZERO;
	while(true) {
		System.out.println(fibonacci(n));
		n = n.add(BigInteger.ONE);
	}
  }
}