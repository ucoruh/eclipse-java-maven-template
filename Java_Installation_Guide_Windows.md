# How to Install Java on Windows

Introduction

The Java Development Kit (**JDK**) is software used for [Java](https://phoenixnap.com/glossary/java-definition) programming, along with the Java Virtual Machine (**JVM**) and the Java Runtime Environment (**JRE**). The JDK includes the [compiler](https://phoenixnap.com/glossary/what-is-a-compiler) and class libraries, allowing developers to create Java programs executable by the JVM and JRE.

**In this tutorial, you will learn to install the Java Development Kit on Windows.**

Prerequisites

- A system running Windows 10.
- A network connection.
- Administrator privileges.

## Check if Java Is Installed

1. Open a command prompt by typing cmd in the search bar and press **Enter**.
2. Run the following command:

```bash
java -version
```

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-42-00-image.png)

## Download Java for Windows 10

Download the latest Java Development Kit installation file for Windows 10 to have the latest features and bug fixes.

1. Using your preferred web browser, navigate to the [Oracle Java Downloads page](https://www.oracle.com/java/technologies/downloads/#jdk17-windows).
2. On the *Downloads* page, click the **x64 Installer** download link under the **Windows** category. At the time of writing this article, Java version 17 is the latest long-term support Java version.

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-42-50-image.png)

Wait for the download to complete.

## Install Java on Windows 10

After downloading the installation file, proceed with installing Java on your Windows system.

Follow the steps below:

### Step 1: Run the Downloaded File

Double-click the **downloaded file** to start the installation.

### Step 2: Configure the Installation Wizard

After running the installation file, the installation wizard welcome screen appears.

1. Click **Next** to proceed to the next step.

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-45-34-image.png)

2. Choose the destination folder for the Java installation files or stick to the default path. Click **Next** to proceed.

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-45-55-image.png)

3. Wait for the wizard to finish the installation process until the *Successfully Installed* message appears. Click **Close** to exit the wizard.

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-46-21-image.png)

## Set Environmental Variables in Java

Set Java environment variables to enable program compiling from any directory. To do so, follow the steps below:

### Step 1: Add Java to System Variables

1. Open the **Start** menu and search for *environment variables*.

2. Select the **Edit the system environment variables** result.

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-47-56-image.png)

3. In the *System Properties* window, under the *Advanced* tab, click **Environment Variables…**

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-48-20-image.png)

4. Under the *System variables* category, select the **Path** variable and click **Edit**:

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-49-22-image.png)

5. Click the **New** button and enter the path to the Java bin directory:

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-49-42-image.png)

**Note:** The default path is usually *C:\Program Files\Java\jdk-17.0.1\bin*.

6. Click **OK** to save the changes and exit the variable editing window.

### Step 2: Add JAVA_HOME Variable

Some applications require the **JAVA_HOME** variable. Follow the steps below to create the variable:

1. In the *Environment Variables* window, under the *System variables* category, click the **New…** button to create a new variable.

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-50-27-image.png)

2. Name the variable as ***JAVA_HOME***.

3. In the variable value field, paste the path to your Java jdk directory and click **OK**.

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-50-48-image.png)

4. Confirm the changes by clicking **OK** in the *Environment Variables* and *System properties* windows.

## Test the Java Installation

Run the **`java -version`** command in the command prompt to make sure Java installed correctly:

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-51-33-image.png)

If installed correctly, the command outputs the Java version. Make sure everything works by writing a simple program and compiling it. Follow the steps below:

### Step 1: Write a Test Java Script

1. Open a text editor such as Notepad++ and create a new file.

2. Enter the following lines of code and click **Save**:

```java
class HelloWorld{
    public static void main(String args[]){
        System.out.println("Hello world!");
        }
}
```

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-54-38-image.png)

Name the file and save it as a **Java source file (*.java)**.

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-52-38-image.png)

**Note:** When using Notepad, select **All files** for the Save as type option and add the *.java* extension to the file name.

### Step 2: Compile the Test Java Code

1. In the command prompt, change the directory to the file's location and use the following syntax to compile the program:

```bash
javac [filename]
```

For example:

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-55-41-image.png)

After a successful compilation, the program generates a *.class* file in the file directory.

2. Run the program with the following syntax:

```bash
java [filename]
```

![](C:\Users\ugur.coruh\AppData\Roaming\marktext\images\2023-10-27-19-56-59-image.png)
