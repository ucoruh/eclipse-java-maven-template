/**

@file Calculator.java
@brief This file serves as a demonstration file for the Calculator class.
@details This file contains the implementation of the Calculator class, which provides various mathematical operations.
*/

/**

@package com.ucoruh.calculator
@brief The com.ucoruh.calculator package contains all the classes and files related to the Calculator App.
*/
package com.ucoruh.calculator;

import org.slf4j.LoggerFactory;

import ch.qos.logback.classic.Logger;
/**

@class Calculator
@brief This class represents a Calculator that performs mathematical operations.
@details The Calculator class provides methods to perform mathematical operations such as addition, subtraction, multiplication, and division. It also supports logging functionality using the logger object.
@author ugur.coruh
*/
public class Calculator {

  /**
   * @brief Logger for the Calculator class.
   */
  private static final Logger logger = (Logger) LoggerFactory.getLogger(Calculator.class);

  /**
   * @brief Calculates the sum of two integers.
   *
   * @details This function takes two integer values, `a` and `b`, and returns their sum. It also logs a message using the logger object.
   *
   * @param a The first integer value.
   * @param b The second integer value.
   * @return The sum of `a` and `b`.
   */
  public int add(int a, int b) {
    logger.info("add({}, {})", a, b);
    return a + b;
  }

  /**
   * @brief Calculates the difference between two integers.
   *
   * @param a The value to subtract from.
   * @param b The value to subtract.
   * @return The result of `a` minus `b`.
   */
  public int subtract(int a, int b) {
    logger.info("subtract({}, {})", a, b);
    return a - b;
  }

  /**
   * @brief Calculates the product of two integers.
   *
   * @param a The first integer value.
   * @param b The second integer value.
   * @return The product of `a` and `b`.
   */
  public int multiply(int a, int b) {
    logger.info("multiply({}, {})", a, b);
    return a * b;
  }

  /**
   * @brief Divides one integer by another.
   *
   * @details Division is performed as floating point division so that, for
   *          example, dividing 1 by 3 does not silently truncate to 0.
   *
   * @param a The dividend.
   * @param b The divisor.
   * @return The result of `a` divided by `b`.
   * @throws ArithmeticException if `b` is zero.
   */
  public double divide(int a, int b) {
    logger.info("divide({}, {})", a, b);

    if (b == 0) {
      logger.error("divide by zero requested for dividend {}", a);
      throw new ArithmeticException("Division by zero");
    }

    return (double) a / (double) b;
  }
}
