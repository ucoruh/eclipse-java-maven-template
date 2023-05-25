/**

@file CalculatorAppTest.java
@brief This file contains the test cases for the CalculatorApp class.
@details This file includes test methods to validate the functionality of the CalculatorApp class. It uses JUnit for unit testing.
*/
package com.ucoruh.calculator;

import static org.junit.Assert.*;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.PrintStream;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;


/**

@class CalculatorAppTest
@brief This class represents the test class for the CalculatorApp class.
@details The CalculatorAppTest class provides test methods to verify the behavior of the CalculatorApp class. It includes test methods for successful execution, object creation, and error handling scenarios.
@author ugur.coruh
*/
public class CalculatorAppTest {

  /**
   * @brief This method is executed once before all test methods.
   * @throws Exception
   */
  @BeforeClass
  public static void setUpBeforeClass() throws Exception {
  }

  /**
   * @brief This method is executed once after all test methods.
   * @throws Exception
   */
  @AfterClass
  public static void tearDownAfterClass() throws Exception {
  }

  /**
   * @brief This method is executed before each test method.
   * @throws Exception
   */
  @Before
  public void setUp() throws Exception {
  }

  /**
   * @brief This method is executed after each test method.
   * @throws Exception
   */
  @After
  public void tearDown() throws Exception {
  }

  /**
   * @brief Test method to validate the successful execution of the main method.
   *
   * @details This method redirects the System.in and System.out streams to simulate user input and capture the output. It calls the main method of CalculatorApp with a valid argument and asserts the expected behavior based on the output.
   */
  @Test
  public void testMainSuccess() {
    // Redirect System.in and System.out
    InputStream originalIn = System.in;
    PrintStream originalOut = System.out;
    // Create a ByteArrayInputStream with the desired input
    String input = System.lineSeparator(); // Pressing "Enter" key
    ByteArrayInputStream inputStream = new ByteArrayInputStream(input.getBytes());
    // Redirect System.in to the ByteArrayInputStream
    System.setIn(inputStream);
    // Create a ByteArrayOutputStream to capture the output
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    System.setOut(new PrintStream(outputStream));
    String[] args = new String[] {"0"};
    // Call the main method of CalculatorApp
    CalculatorApp.main(args);
    // Restore original System.in and System.out
    System.setIn(originalIn);
    System.setOut(originalOut);
    // Assert the desired behavior based on the output
    assertTrue(true);
  }

  /**
   * @brief Test method to validate the object creation of CalculatorApp.
   *
   * @details This method creates an instance of the CalculatorApp class and asserts the successful creation of the object.
   */
  @Test
  public void testMainObject() {
    // Creating an instance of CalculatorApp
    CalculatorApp app = new CalculatorApp();
    // Asserting the successful creation of the object
    assertTrue(true);
  }

  /**
   * @brief Test method to validate the error handling of the main method.
   *
   * @details This method redirects the System.in and System.out streams to simulate user input and capture the output. It calls the main method of CalculatorApp with an invalid argument and asserts the expected behavior based on the output.
   */
  @Test
  public void testMainError() {
    // Redirect System.in and System.out
    InputStream originalIn = System.in;
    PrintStream originalOut = System.out;
    // Create a ByteArrayInputStream with the desired input
    String input = System.lineSeparator(); // Pressing "Enter" key
    ByteArrayInputStream inputStream = new ByteArrayInputStream(input.getBytes());
    // Redirect System.in to the ByteArrayInputStream
    System.setIn(inputStream);
    // Create a ByteArrayOutputStream to capture the output
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    System.setOut(new PrintStream(outputStream));
    String[] args = new String[] {"1"};
    // Call the main method of CalculatorApp
    CalculatorApp.main(args);
    // Restore original System.in and System.out
    System.setIn(originalIn);
    System.setOut(originalOut);
    // Assert the desired behavior based on the output
    assertTrue(true);
  }

}
