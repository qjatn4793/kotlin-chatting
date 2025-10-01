// 루트 settings.gradle.kts

pluginManagement {
    repositories {
        // Gradle 플러그인 가져올 저장소
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    // 모든 의존성은 "루트"에 정의된 저장소만 사용 (서브프로젝트에서 repositories{} 쓰지 않도록)
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        mavenCentral()
    }
}

rootProject.name = "ledgerflow"

include(":modules:gateway")
include(":modules:order-command")
include(":modules:payment")
include(":modules:order-query")
