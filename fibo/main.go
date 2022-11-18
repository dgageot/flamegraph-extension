package main

import (
	"fmt"
	"math/big"
)

func fibonacci(n *big.Int) *big.Int {
	f2 := big.NewInt(0)
	f1 := big.NewInt(1)

	if n.Cmp(big.NewInt(1)) == 0 {
		return f2
	}

	if n.Cmp(big.NewInt(2)) == 0 {
		return f1
	}

	for i := 3; n.Cmp(big.NewInt(int64(i))) >= 0; i++ {
		next := big.NewInt(0)
		next.Add(f2, f1)
		f2 = f1
		f1 = next
	}

	return f1
}

func main() {
	one := big.NewInt(1)
	n := big.NewInt(0)
	for {
		fmt.Println(n, fibonacci(n))
		n.Add(n, one)
	}
}
