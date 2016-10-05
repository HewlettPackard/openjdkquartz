import sun.misc.UnsafeFTM;

class SimpleAllocation{

 public static void main(String[] args) {
	UnsafeFTM u = UnsafeFTM.getUnsafe();
	System.out.println("Got an unsafe");
	long addrs = u.allocateMemory(1024);
	System.out.println("Allocated 1KB to address " + addrs);
	u.freeMemory(addrs,1024);
	System.out.println("Freed memory");
	
    }
}
 
