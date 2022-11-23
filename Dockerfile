FROM gradle:7.5.1-jdk17 AS build
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle build --no-daemon


FROM openjdk:17-oracle
EXPOSE 8080
RUN groupadd mygroup && useradd  myuser -g mygroup
USER myuser:mygroup
ARG JAR_FILE=build/*.jar
COPY --from=build /home/gradle/src/build/libs/*.jar /app/ashutestapi.jar
ENTRYPOINT ["java","-jar","/app/ashutestapi.jar"]
