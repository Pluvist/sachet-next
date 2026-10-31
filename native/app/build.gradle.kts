import java.util.Properties

plugins { id("com.android.application"); id("org.jetbrains.kotlin.plugin.compose") }

// Signing material stays outside the repository and is never printed or bundled.
val releaseSigningPath=providers.environmentVariable("XACHET_SIGNING_PROPERTIES").orNull
val releaseKeys=Properties().apply {
    if(releaseSigningPath!=null)file(releaseSigningPath).inputStream().use(::load)
}
val releaseAbis=providers.gradleProperty("xachetReleaseAbis").orNull
    ?.split(',')?.map(String::trim)?.filter(String::isNotEmpty)

android {
    namespace = "com.pluvist.sachet.next"
    compileSdk = 37
    defaultConfig {
        applicationId = "com.pluvist.sachet.next"
        minSdk = 33
        targetSdk = 37
        versionCode = 54
        versionName = "0.19.78"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    signingConfigs {
        if(releaseSigningPath!=null)create("xachetRelease") {
            storeFile=file(requireNotNull(releaseKeys.getProperty("storeFile")))
            storePassword=requireNotNull(releaseKeys.getProperty("storePassword"))
            keyAlias=requireNotNull(releaseKeys.getProperty("keyAlias"))
            keyPassword=requireNotNull(releaseKeys.getProperty("keyPassword"))
        }
    }
    buildTypes {
        debug { applicationIdSuffix = ".localtest" }
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            if(releaseSigningPath!=null)signingConfig=signingConfigs.getByName("xachetRelease")
        }
        create("benchmark") {
            initWith(getByName("release"))
            applicationIdSuffix = ".benchmark"
            signingConfig = signingConfigs.getByName("debug")
            matchingFallbacks += "release"
        }
        // Daily preview uses the same optimized code as release while retaining the
        // existing preview package/data and its development signing certificate.
        create("preview") {
            initWith(getByName("release"))
            applicationIdSuffix = ".localtest"
            signingConfig = signingConfigs.getByName("debug")
            matchingFallbacks += "release"
        }
    }
    if(releaseAbis!=null)splits { abi {
        isEnable=true
        reset()
        include(*releaseAbis.toTypedArray())
        isUniversalApk=false
    } }
    buildFeatures { compose = true; buildConfig = true }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_21; targetCompatibility = JavaVersion.VERSION_21 }
    testOptions { unitTests.isReturnDefaultValues = true }
    sourceSets.getByName("main").assets.directories.add(layout.buildDirectory.dir("generated/legal-assets").get().asFile.path)
}
tasks.matching{it.name=="packageRelease"}.configureEach {
    doFirst{check(releaseSigningPath!=null){"Release packaging requires XACHET_SIGNING_PROPERTIES."}}
}
val prepareLegalAssets=tasks.register<Copy>("prepareLegalAssets") {
    from(rootProject.file("../LICENSE"),rootProject.file("../LICENSE-MIT"),rootProject.file("../THIRD_PARTY_NOTICES.md"))
    into(layout.buildDirectory.dir("generated/legal-assets/legal"))
}
tasks.named("preBuild").configure{dependsOn(prepareLegalAssets)}
dependencies {
    implementation("io.github.kyant0:shapes:1.2.1")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("io.github.neoruaa.glasmio:glasmio-scaffold:0.1.0")
    implementation("io.github.neoruaa.glasmio:glasmio-preference:0.1.0")
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.11.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.0")
    implementation("org.jsoup:jsoup:1.22.1")
    implementation("com.google.re2j:re2j:1.8")
    implementation("com.google.errorprone:error_prone_annotations:2.36.0")
    implementation("com.google.code.findbugs:jsr305:3.0.2")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250517")
}
