pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        providers.environmentVariable("SACHET_LOCAL_MAVEN").orNull?.let { maven(it) }
        maven("https://repo.huaweicloud.com/repository/maven/"); google(); mavenCentral()
    }
}
rootProject.name = "Glasmio"
include(":glasmio-core", ":glasmio-glass", ":glasmio-ui", ":glasmio-scaffold", ":glasmio-preference", ":glasmio-icons")
