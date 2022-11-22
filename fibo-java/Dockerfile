# syntax=docker/dockerfile:1

FROM eclipse-temurin:11
WORKDIR /fibo
COPY Main.java ./
RUN javac Main.java
ENTRYPOINT ["java", "-XX:+PreserveFramePointer", "Main"]
