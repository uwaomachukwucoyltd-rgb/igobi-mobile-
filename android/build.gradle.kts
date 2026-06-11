allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force Kotlin language/api version >= 1.8 for every subproject. Some Flutter
// plugins (sentry_flutter 8.x at minimum) still declare languageVersion = "1.6"
// internally, and Kotlin 2.2 refuses to compile that. We invoke via Groovy
// builder so we don't need the Kotlin Gradle plugin on the root buildscript
// classpath.
subprojects {
    // configureEach is lazy — fires when matching tasks are later registered,
    // so we don't need an afterEvaluate wrapper (which would fail here because
    // evaluationDependsOn(":app") above has already evaluated subprojects).
    tasks.matching { it.name.startsWith("compile") && it.name.endsWith("Kotlin") }
        .configureEach {
            // Don't touch jvmTarget — each plugin keeps its own to stay in
            // sync with its Java compile task (sign_in_with_apple targets 1.8,
            // others target 17). We only force languageVersion / apiVersion
            // forward to satisfy Kotlin 2.2's drop of 1.6.
            withGroovyBuilder {
                getProperty("kotlinOptions").withGroovyBuilder {
                    setProperty("languageVersion", "1.8")
                    setProperty("apiVersion", "1.8")
                }
            }
        }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
