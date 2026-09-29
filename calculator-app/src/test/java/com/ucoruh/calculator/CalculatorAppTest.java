/**

@file CalculatorAppTest.java
@brief This file contains the test cases for the CalculatorApp class.
@details This file includes test methods to validate the functionality of the CalculatorApp class. It uses JUnit 5
         (Jupiter) for unit testing. None of these tests touch System.in: CalculatorApp#run takes its input only
         from the argument array, so it never blocks and is safe to run from a script or CI pipeline.
*/
package com.ucoruh.calculator;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**

@class CalculatorAppTest
@brief This class represents the test class for the CalculatorApp class.
@details The CalculatorAppTest class provides test methods to verify the behavior of CalculatorApp#run for normal
         operation, boundary/edge input (missing or extra arguments) and invalid input (non-numeric operands,
         unknown operator, division by zero).
@author ugur.coruh
*/
class CalculatorAppTest {

  @Nested
  @DisplayName("run: normal input")
  class NormalInput {

    @Test
    @DisplayName("adds two numbers")
    void add() {
      assertEquals("5", CalculatorApp.run(new String[] {"2", "+", "3"}));
    }

    @Test
    @DisplayName("subtracts two numbers")
    void subtract() {
      assertEquals("-1", CalculatorApp.run(new String[] {"2", "-", "3"}));
    }

    @Test
    @DisplayName("multiplies two numbers")
    void multiply() {
      assertEquals("12", CalculatorApp.run(new String[] {"3", "*", "4"}));
    }

    @Test
    @DisplayName("divides two numbers")
    void divide() {
      assertEquals("2.0", CalculatorApp.run(new String[] {"6", "/", "3"}));
    }
  }

  @Nested
  @DisplayName("run: boundary / edge input")
  class BoundaryInput {

    @Test
    @DisplayName("no arguments prints usage instead of blocking")
    void noArguments() {
      assertEquals(CalculatorApp.USAGE, CalculatorApp.run(new String[] {}));
    }

    @Test
    @DisplayName("null argument array prints usage instead of throwing")
    void nullArguments() {
      assertEquals(CalculatorApp.USAGE, CalculatorApp.run(null));
    }

    @Test
    @DisplayName("too few arguments prints usage")
    void tooFewArguments() {
      assertEquals(CalculatorApp.USAGE, CalculatorApp.run(new String[] {"1", "+"}));
    }

    @Test
    @DisplayName("too many arguments prints usage")
    void tooManyArguments() {
      assertEquals(CalculatorApp.USAGE, CalculatorApp.run(new String[] {"1", "+", "2", "3"}));
    }

    @Test
    @DisplayName("Integer.MAX_VALUE operand is accepted")
    void maxIntOperand() {
      assertEquals("2147483647", CalculatorApp.run(new String[] {"2147483647", "+", "0"}));
    }
  }

  @Nested
  @DisplayName("run: invalid input")
  class InvalidInput {

    @Test
    @DisplayName("non-numeric first operand is reported, not thrown")
    void nonNumericFirstOperand() {
      String result = CalculatorApp.run(new String[] {"abc", "+", "3"});
      assertTrue(result.startsWith("Error: operands must be integers"));
    }

    @Test
    @DisplayName("non-numeric second operand is reported, not thrown")
    void nonNumericSecondOperand() {
      String result = CalculatorApp.run(new String[] {"3", "+", "xyz"});
      assertTrue(result.startsWith("Error: operands must be integers"));
    }

    @Test
    @DisplayName("unknown operator is reported, not thrown")
    void unknownOperator() {
      String result = CalculatorApp.run(new String[] {"1", "%", "2"});
      assertTrue(result.startsWith("Error: unknown operator"));
    }

    @Test
    @DisplayName("division by zero is reported, not thrown")
    void divisionByZero() {
      assertEquals("Error: division by zero", CalculatorApp.run(new String[] {"1", "/", "0"}));
    }
  }

  @Nested
  @DisplayName("main: prints run()'s result and returns without reading stdin")
  class MainMethod {

    private final PrintStream originalOut = System.out;
    private ByteArrayOutputStream capturedOut;

    @BeforeEach
    void redirectOut() {
      capturedOut = new ByteArrayOutputStream();
      System.setOut(new PrintStream(capturedOut, true, StandardCharsets.UTF_8));
    }

    @AfterEach
    void restoreOut() {
      System.setOut(originalOut);
    }

    @Test
    @DisplayName("prints the computed result and exits without waiting for input")
    void printsResult() {
      // System.in is intentionally left untouched: main() must complete without
      // ever reading from it.
      CalculatorApp.main(new String[] {"4", "*", "5"});
      assertEquals("20", capturedOut.toString(StandardCharsets.UTF_8).trim());
    }

    @Test
    @DisplayName("prints the usage message for invalid arguments and exits")
    void printsUsageForInvalidArguments() {
      CalculatorApp.main(new String[] {"not-enough-args"});
      assertEquals(CalculatorApp.USAGE, capturedOut.toString(StandardCharsets.UTF_8).trim());
    }
  }
}
