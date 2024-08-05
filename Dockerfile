FROM maven:latest

LABEL authors="Volodymyr_Butko"

WORKDIR /app

COPY . .

RUN mvn clean package -DskipTests

ENTRYPOINT ["java", "-jar", "./target/spring-petclinic-3.3.3.jar"]
