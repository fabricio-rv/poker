plugins {
    // MUDE AQUI DE 8.1.0 PARA 8.11.1
    id("com.android.application") version "8.11.1" apply false
    
    // SE TIVER ESSE ABAIXO, MUDE TAMBÉM
    id("com.android.library") version "8.11.1" apply false
    
    // O Kotlin pode deixar como está (1.9.0 ou similar)
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
