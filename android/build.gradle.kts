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

// ponytail: blue_thermal_printer 1.2.3 belum di-update untuk AGP terbaru yang
// mewajibkan `namespace`. Suntikkan dari AndroidManifest lama-nya di sini
// daripada nge-patch pub cache (akan hilang tiap `flutter pub get`). Harus di
// plugins.withId, bukan afterEvaluate — evaluationDependsOn(":app") di atas
// membuat subproject ini sudah evaluated duluan.
subprojects {
    if (project.name == "blue_thermal_printer") {
        // Harus jalan SETELAH script build.gradle plugin ini sendiri selesai
        // (dia set compileSdkVersion 31 di baris terakhirnya, akan overwrite
        // kalau kita set duluan). evaluationDependsOn(":app") di atas bisa
        // membuat project ini sudah evaluated duluan sebelum baris ini jalan,
        // jadi afterEvaluate() akan error — cek state.executed dulu.
        val applyFix: () -> Unit = {
            extensions.findByName("android")?.let { ext ->
                ext.javaClass.getMethod("setNamespace", String::class.java)
                    .invoke(ext, "id.kakzaki.blue_thermal_printer")
                ext.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                    .invoke(ext, 36)
            }
        }
        if (state.executed) applyFix() else afterEvaluate { applyFix() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
