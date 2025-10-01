import org.springframework.boot.gradle.tasks.bundling.BootJar

plugins {
    id("org.springframework.boot")
    id("io.spring.dependency-management")
    kotlin("jvm")
    kotlin("plugin.spring")
}

java {
    toolchain { languageVersion.set(JavaLanguageVersion.of(17)) }
}

val springCloudVersion: String by extra("2023.0.3")

dependencies {
    // Boot 기본 스타터(autoconfigure 포함) — @SpringBootApplication 인식에 필요
    implementation("org.springframework.boot:spring-boot-starter")

    implementation("org.springframework.cloud:spring-cloud-starter-gateway")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.cloud:spring-cloud-dependencies:$springCloudVersion")
    }
}

// ✅ 자동탐지 실패해도 확실히 빌드되도록 mainClass 명시
tasks.named<BootJar>("bootJar") {
    mainClass.set("com.bspay.gateway.GatewayApplication")
}