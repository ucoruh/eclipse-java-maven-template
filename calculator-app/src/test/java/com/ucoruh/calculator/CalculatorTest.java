/**

@file CalculatorTest.java
@brief This file contains the test cases for the Calculator class.
@details This file includes test methods to validate the functionality of the Calculator class. It uses JUnit 5 (Jupiter) for unit testing.
*/
package com.ucoruh.calculator;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**

@class CalculatorTest
@brief This class represents the test class for the Calculator class.
@details The CalculatorTest class provides test methods to verify the behavior of the Calculator class: normal
         operation, boundary values (zero, negative numbers, Integer.MIN_VALUE/MAX_VALUE) and invalid input
         (division by zero).
@author ugur.coruh
*/
class CalculatorTest {

  private Calculator calculator;

  @BeforeEach
  void setUp() {
    calculator = new Calculator();
  }

  @Nested
  @DisplayName("add")
  class Add {

    @Test
    @DisplayName("adds two positive numbers")
    void addsPositiveNumbers() {
      assertEquals(5, calculator.add(2, 3));
    }

    @Test
    @DisplayName("adds a negative and a positive number")
    void addsNegativeAndPositive() {
      assertEquals(-1, calculator.add(-4, 3));
    }

    @Test
    @DisplayName("zero is the additive identity")
    void addZero() {
      assertEquals(7, calculator.add(7, 0));
    }
  }

  @Nested
  @DisplayName("subtract")
  class Subtract {

    @Test
    @DisplayName("subtracts two positive numbers")
    void subtractsPositiveNumbers() {
      assertEquals(1, calculator.subtract(4, 3));
    }

    @Test
    @DisplayName("result can be negative")
    void subtractResultingInNegative() {
      assertEquals(-5, calculator.subtract(0, 5));
    }
  }

  @Nested
  @DisplayName("multiply")
  class Multiply {

    @Test
    @DisplayName("multiplies two positive numbers")
    void multipliesPositiveNumbers() {
      assertEquals(12, calculator.multiply(3, 4));
    }

    @Test
    @DisplayName("multiplying by zero yields zero")
    void multiplyByZero() {
      assertEquals(0, calculator.multiply(123, 0));
    }

    @Test
    @DisplayName("multiplying two negatives yields a positive")
    void multiplyTwoNegatives() {
      assertEquals(6, calculator.multiply(-2, -3));
    }
  }

  @Nested
  @DisplayName("divide")
  class Divide {

    @Test
    @DisplayName("divides two positive numbers exactly")
    void dividesEvenly() {
      assertEquals(2.0, calculator.divide(6, 3), 0.0001);
    }

    @Test
    @DisplayName("division that does not divide evenly keeps the fraction")
    void dividesWithRemainder() {
      assertEquals(1.0 / 3.0, calculator.divide(1, 3), 0.0001);
    }

    @Test
    @DisplayName("dividing by zero throws ArithmeticException (invalid input)")
    void divideByZeroThrows() {
      ArithmeticException thrown = assertThrows(ArithmeticException.class, () -> calculator.divide(10, 0));
      assertEquals("Division by zero", thrown.getMessage());
    }

    @Test
    @DisplayName("zero dividend with a non-zero divisor is zero, not an error")
    void zeroDividend() {
      assertEquals(0.0, calculator.divide(0, 42), 0.0001);
    }
  }

  @ParameterizedTest(name = "boundary: {0} {1} {2} = {3}")
  @DisplayName("boundary values: Integer.MIN_VALUE / Integer.MAX_VALUE")
  @CsvSource({
    "2147483647, add, 0, 2147483647",       // Integer.MAX_VALUE + 0
    "-2147483648, add, 0, -2147483648",      // Integer.MIN_VALUE + 0
    "0, subtract, 2147483647, -2147483647",  // 0 - Integer.MAX_VALUE
  })
  void boundaryValues(int a, String operation, int b, int expected) {
    int result;

    switch (operation) {
      case "add":
        result = calculator.add(a, b);
        break;

      case "subtract":
        result = calculator.subtract(a, b);
        break;

      default:
        throw new IllegalArgumentException("Unsupported operation in test data: " + operation);
    }

    assertEquals(expected, result);
  }
}
