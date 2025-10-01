import org.springframework.boot.gradle.tasks.bundling.BootJar

plugins {
    id("org.springframework.boot")
    id("io.spring.dependency-management")
    kotlin("jvm")
    kotlin("plugin.spring")
}
java { toolchain { languageVersion.set(JavaLanguageVersion.of(17)) } }

extra["springCloudVersion"] = "2023.0.3"
dependencies {
    implementation("org.springframework.boot:spring-boot-starter")
    implementation("org.springframework.cloud:spring-cloud-starter-gateway")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
}
dependencyManagement {
    imports { mavenBom("org.springframework.cloud:spring-cloud-dependencies:${extra["springCloudVersion"]}") }
}

tasks.named<BootJar>("bootJar") {
    mainClass.set("com.bspay.gateway.GatewayApplication")
}