FROM openjdk:17-oracle
RUN groupadd staff && useradd  asgup3 -g staff
USER asgup3:staff
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]