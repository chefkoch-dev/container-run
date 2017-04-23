@test "--self-update repalces run executable" {
    cp -a run ${BATS_TMPDIR}/run
    local before=$(stat -c '%Y' ${BATS_TMPDIR}/run)
    ${BATS_TMPDIR}/run --self-update
    local after=$(stat -c '%Y' ${BATS_TMPDIR}/run)
    (( $before < $after ))
}

@test "run simple command" {
    ./run --rm debian true
}

@test "failures are propagated" {
    run ./run --rm debian false
    [[ $status == 1 ]]
}

@test "host user is known in container" {
    local name=$(id -u -n)
    run ./run --rm debian id -u -n
    [[ $output == $name ]]
}

@test "host group is known in container" {
    local group=$(id -g -n)
    run ./run --rm debian id -g -n
    [[ $output == $group ]]
}

@test "docker server is accessible" {
    ./run --rm docker docker info
}

@test "home directories are persistent" {
    local fileName=$(uuidgen)
    ./run --rm debian touch ${HOME}/${fileName}
    ./run --rm debian stat ${HOME}/${fileName}
}

@test "ssh agent is accessible" {
    SSH_AUTH_SOCK=$(mktemp) ./run --rm debian sh -c 'stat ${SSH_AUTH_SOCK}'
}

@test "current directory is preserved" {
    local testFile=${BATS_TEST_DIRNAME##*/}/${BATS_TEST_FILENAME##*/}
    ./run --rm debian stat $testFile
}

@test "current directory is mounted as /app" {
    local testFile=${BATS_TEST_DIRNAME##*/}/${BATS_TEST_FILENAME##*/}
    ./run --rm debian stat /app/$testFile
}
