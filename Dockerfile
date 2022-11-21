FROM openjdk:17-oracle
RUN groupadd mygroup && useradd  myuser -g mygroup
USER myuser:mygroup
ARG JAR_FILE=build/*.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]