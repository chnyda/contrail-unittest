// Load shared libs
def common = new com.mirantis.mk.Common()
def git = new com.mirantis.mk.Git()
def debian = new com.mirantis.mk.Debian()

// Define global variables
def timestamp = common.getDatetime()
def version = SOURCE_BRANCH.replace('R', '') + "~${timestamp}"

def components = [
    ["contrail-build", "tools/build", SOURCE_BRANCH],
    ["contrail-controller", "controller", SOURCE_BRANCH],
    ["contrail-vrouter", "vrouter", SOURCE_BRANCH],
    ["contrail-third-party", "third_party", SOURCE_BRANCH],
    ["contrail-generateDS", "tools/generateds", SOURCE_BRANCH],
    ["contrail-sandesh", "tools/sandesh", SOURCE_BRANCH],
    ["contrail-packages", "tools/packages", SOURCE_BRANCH],
    ["contrail-nova-vif-driver", "openstack/nova_contrail_vif", SOURCE_BRANCH],
    ["contrail-neutron-plugin", "openstack/neutron_plugin", SOURCE_BRANCH],
    ["contrail-nova-extensions", "openstack/nova_extensions", SOURCE_BRANCH],
    ["contrail-heat", "openstack/contrail-heat", SOURCE_BRANCH],
    ["contrail-ceilometer-plugin", "openstack/ceilometer_plugin", "master"],
    ["contrail-web-storage", "contrail-web-storage", SOURCE_BRANCH],
    ["contrail-web-server-manager", "contrail-web-server-manager", SOURCE_BRANCH],
    ["contrail-web-controller", "contrail-web-controller", SOURCE_BRANCH],
    ["contrail-web-core", "contrail-web-core", SOURCE_BRANCH],
    ["contrail-webui-third-party", "contrail-webui-third-party", SOURCE_BRANCH]
]

def sourcePackages = [
    "contrail-web-core",
    "contrail-web-controller",
    "contrail",
    "contrail-vrouter-dpdk",
    "ifmap-server",
    "neutron-plugin-contrail",
    "ceilometer-plugin-contrail",
    "contrail-heat"
]

def git_commit = [:]
def properties = [:]


def buildSourcePackageStep(img, pkg, version) {
    return {
        sh("rm -f src/build/packages/${pkg}_* || true")
        img.inside {
            sh("cd src; VERSION='${version}' make -f packages.make source-package-${pkg}")
        }
    }
}

node('docker') {
    try{
        checkout scm
        git_commit['contrail-pipeline'] = git.getGitCommit()

        
        def jenkinsUID = sh (
            script: 'id -u',
            returnStdout: true
        ).trim()

        def imgName = "${OS}-${DIST}-${ARCH}"
        def img = docker.build(
                    "${imgName}:${timestamp}",
                    [
                        "--build-arg uid=${jenkinsUID}",
                        "--build-arg timestamp=${timestamp}",
                        "-f docker/${imgName}.Dockerfile",
                        "docker"
                    ].join(' ')
                )

        stage("cleanup") {
            img.inside{
                sh("sudo chown -R jenkins:jenkins * || true")
                sh("sudo rm -rf src/ || true")
            }
        }

        stage("checkout") {
            for (component in components) {
                    git.checkoutGitRepository(
                        "src/${component[1]}",
                        "${SOURCE_URL}/${component[0]}.git",
                        component[2],
                        SOURCE_CREDENTIALS,
                        true,
                        30,
                        1
                    )
            }

            for (component in components) {
                dir("src/${component[1]}") {
                    commit = git.getGitCommit()
                    git_commit[component[0]] = commit
                    properties["git_commit_"+component[0].replace('-', '_')] = commit
                }
            }

            sh("test -e src/SConstruct || ln -s tools/build/SConstruct src/SConstruct")
            sh("test -e src/packages.make || ln -s tools/packages/packages.make src/packages.make")
            sh("test -d src/build && rm -rf src/build || true")
        }

        try {

            stage("build-source") {

                img.inside {
                    sh("cd src/third_party; python fetch_packages.py")
                    sh("cd src/contrail-webui-third-party; python fetch_packages.py -f packages.xml")
                    sh("rm -rf src/contrail-web-core/node_modules")
                    sh("mkdir src/contrail-web-core/node_modules")
                    sh("cp -rf src/contrail-webui-third-party/node_modules/* src/contrail-web-core/node_modules/")
                }

                buildSteps = [:]
                for (pkg in sourcePackages) {
                    buildSteps[pkg] = buildSourcePackageStep(img, pkg, version)
                }
                //parallel buildSteps
                common.serial(buildSteps)
            }

            //for (arch in ARCH.split(',')) {
            stage("build-binary-${ARCH}") {
                img.inside{
                    sh("cd src; bash -c ../scripts/run_tests.sh")
                }
            }
            //}
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
            if (KEEP_REPOS.toBoolean() == false) {
                println "Cleaning up docker images"
                sh("docker images | grep -E '[-:\\ ]+${timestamp}[\\.\\ /\$]+' | awk '{print \$3}' | xargs docker rmi -f || true")
            }
            throw e
        }


    } catch (Throwable e) {
       // If there was an exception thrown, the build failed
       currentBuild.result = "FAILURE"
       throw e
    } finally {
       common.sendNotification(currentBuild.result,"",["slack"])
    }
}
