# Path to JDK of target platform. 
# If you want to make a release for a client that runs on Windows, JAVA_HOME should point to
# a Windows JDK.
# For a client that runs on Linux, JAVA_HOME should point to a Linux JDK.
# Note: the platform on which you make the build does not matter: you can make a Windows build 
# on Linux and vice versa; but you have to have the target JDK on your build system.

#JAVA_HOME=<path-to-jdk-of-client-platform>      # e.g. /opt/jdk-11.0.3

echo "Java x is $JAVA_X"
#jlink --output custom_jre --module-path=$JAVA_HOME/jmods --add-modules java.instrument,java.security.jgss,java.compiler,java.desktop,java.logging,java.rmi,java.security.sasl,java.xml,java.sql,java.naming,java.management,jdk.management.agent,jdk.httpserver

