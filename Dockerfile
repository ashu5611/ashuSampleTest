FROM gradle:7.5.1-jdk17 AS build
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle build --no-daemon


FROM openjdk:17-oracle
EXPOSE 8080

USER root
RUN mkdir -p /app
RUN groupadd mygroup && useradd  myuser -g mygroup
RUN chown myuser /app


USER myuser:mygroup


COPY --from=build /home/gradle/src/build/libs/*.jar /app/
ENTRYPOINT ["java","-jar","/app/ashutest-0.1.0.jar"]
