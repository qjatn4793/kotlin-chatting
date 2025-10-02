import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("org.springframework.boot") version "3.3.3" apply false
    id("io.spring.dependency-management") version "1.1.6" apply false
    kotlin("jvm") version "1.9.25" apply false
    kotlin("plugin.spring") version "1.9.25" apply false
    kotlin("plugin.jpa") version "1.9.25" apply false
}

// 공통 group/version (원하면 조직/버전 규칙에 맞게 수정)
allprojects {
    group = "com.bspay"
    version = "0.0.1-SNAPSHOT"
}

// 모든 서브프로젝트 공통 설정
subprojects {

    // Java 17 Toolchain (자바/코틀린 모두 17 타깃)
    plugins.withType<JavaPlugin> {
        the<JavaPluginExtension>().toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    // Kotlin 컴파일러 옵션
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
            // Nullable 어노테이션 인식 강화 (Spring/JPA와 궁합 좋음)
            freeCompilerArgs.addAll(listOf("-Xjsr305=strict"))
        }
    }

    // 테스트 플랫폼(JUnit 5)
    tasks.withType<Test>().configureEach {
        useJUnitPlatform()
    }
}
