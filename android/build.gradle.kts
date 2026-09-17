allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// NOTE: Windows' LongPathsEnabled registry key has been set (pending a
// reboot to take effect) - once confirmed that fixes the MAX_PATH build
// failure some plugins' long asset filenames caused (e.g.
// google_mlkit_text_recognition's OCR models), this can stay as the normal
// project-relative path below. If the failure returns after rebooting,
// switch back to the short-path override, kept here for quick re-enabling:
//
// val newBuildDir: Directory =
//     rootProject.layout.projectDirectory.dir("D:/ryDevelop/fbuild/sgt")
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
