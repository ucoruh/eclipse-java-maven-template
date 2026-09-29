/**

@file CalculatorApp.java
@brief This file serves as the main application file for the Calculator App.
@details This file contains the entry point of the application, which is the main method. It initializes the necessary components and executes the Calculator App.
*/
/**

@package com.ucoruh.calculator
@brief The com.ucoruh.calculator package contains all the classes and files related to the Calculator App.
*/
package com.ucoruh.calculator;

import org.slf4j.LoggerFactory;

import ch.qos.logback.classic.Logger;

/**
 *
 * @class CalculatorApp
 * @brief This class represents the main application class for the Calculator
 *        App.
 * @details The CalculatorApp class provides the entry point for the Calculator
 *          App. It parses three command-line arguments (operand, operator,
 *          operand), computes the result with {@link Calculator} and prints
 *          it. It never reads from standard input, so it is safe to run from
 *          a non-interactive script and to unit test directly.
 * @author ugur.coruh
 */
public class CalculatorApp {
  /**
   * @brief Logger for the CalculatorApp class.
   */
  private static final Logger logger = (Logger) LoggerFactory.getLogger(CalculatorApp.class);

  /**
   * @brief Usage message shown when the arguments do not describe a single
   *        binary operation.
   */
  static final String USAGE = "Usage: CalculatorApp <number> <+|-|*|/> <number>";

  private CalculatorApp() {
    // Utility/entry-point class: not meant to be instantiated.
  }

  /**
   * @brief The main entry point of the Calculator App.
   *
   * @details Delegates all the work to {@link #run(String[])} and prints its
   *          result. Kept deliberately thin so that the parsing/calculation
   *          logic in `run` can be unit tested without touching the console.
   *
   * @param args The command-line arguments passed to the application:
   *             `<number> <operator> <number>`.
   */
  public static void main(String[] args) {
    System.out.println(run(args));
  }

  /**
   * @brief Parses `args` as `<number> <operator> <number>` and computes the
   *        result.
   *
   * @details This is the testable core of the application: it performs no
   *          I/O (it neither reads from `System.in` nor writes to
   *          `System.out`) and never blocks, so it can be called directly
   *          from tests and from scripts alike. Recognized operators are
   *          `+`, `-`, `*` and `/`. Invalid input (wrong argument count,
   *          non-numeric operand, unknown operator, division by zero) is
   *          reported as a descriptive `"Error: ..."` string instead of an
   *          uncaught exception, so the process always exits cleanly with a
   *          printable message.
   *
   * @param args The command-line arguments.
   * @return A human-readable result or error message.
   */
  static String run(String[] args) {
    if (args == null || args.length != 3) {
      logger.warn("Expected 3 arguments, got {}", args == null ? 0 : args.length);
      return USAGE;
    }

    final int left;
    final int right;

    try {
      left = Integer.parseInt(args[0]);
      right = Integer.parseInt(args[2]);
    } catch (NumberFormatException e) {
      logger.error("Invalid operand: {}", e.toString());
      return "Error: operands must be integers. " + USAGE;
    }

    String operator = args[1];
    Calculator calculator = new Calculator();

    switch (operator) {
      case "+":
        return String.valueOf(calculator.add(left, right));

      case "-":
        return String.valueOf(calculator.subtract(left, right));

      case "*":
        return String.valueOf(calculator.multiply(left, right));

      case "/":
        try {
          return String.valueOf(calculator.divide(left, right));
        } catch (ArithmeticException e) {
          logger.error("Division by zero requested");
          return "Error: division by zero";
        }

      default:
        logger.warn("Unknown operator: {}", operator);
        return "Error: unknown operator '" + operator + "'. " + USAGE;
    }
  }
}
