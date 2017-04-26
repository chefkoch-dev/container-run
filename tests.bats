setup() {
    PROJECT=$(mktemp -d)
    mkdir ${PROJECT}/docker
    RUN=${PROJECT}/docker/run
    cp -p run ${RUN}
}

teardown() {
    rm -rf ${PROJECT}
    unset PROJECT RUN
}

@test "--self-update replaces run executable" {
    local before=$(stat -c '%Y' ${RUN})
    ${RUN} --self-update
    local after=$(stat -c '%Y' ${RUN})
    (( $before < $after ))
}

@test "run simple command" {
    ${RUN} --rm debian true
}

@test "failures are propagated" {
    run ${RUN} --rm debian false
    [[ $status == 1 ]]
}

@test "host user is known in container" {
    local name=$(id -u -n)
    run ${RUN} --rm debian id -u -n
    [[ $output == $name ]]
}

@test "host group is known in container" {
    local group=$(id -g -n)
    run ${RUN} --rm debian id -g -n
    [[ $output == $group ]]
}

@test "docker server is accessible" {
    ${RUN} --rm docker docker info
}

@test "home directories are persistent" {
    local fileName=$(mktemp -p ${HOME})
    ${RUN} --rm debian touch ${fileName}
    ${RUN} --rm debian stat ${fileName}
}

@test "ssh agent is accessible" {
    SSH_AUTH_SOCK=$(mktemp) ${RUN} --rm debian sh -c 'stat ${SSH_AUTH_SOCK}'
}

@test "current directory is preserved" {
    local testFile=$(mktemp -p ${PROJECT})
    ${RUN} --rm debian stat ${testFile##*/}
}

@test "current directory is mounted as /app" {
    local testFile=$(mktemp -p ${PROJECT})
    ${RUN} --rm debian stat /app/${testFile##*/}
}
