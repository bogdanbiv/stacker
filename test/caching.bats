load helpers

function teardown() {
    cleanup
    rm -rf tree1 tree2 link foo >& /dev/null || true
}

@test "import caching" {
    cat > stacker.yaml <<EOF
import-cache:
    from:
        type: docker
        url: docker://centos:latest
    import:
        - link/foo
    run: cp /stacker/foo/zomg /zomg
EOF
    mkdir -p tree1/foo
    echo foo >> tree1/foo/zomg
    mkdir -p tree2/foo
    echo bar >> tree2/foo/zomg

    ln -s tree1 link
    stacker build
    rm link && ln -s tree2 link
    stacker build
    rm link
    umoci unpack --image oci:import-cache dest
    [ "$(sha tree2/foo/zomg)" == "$(sha dest/rootfs/zomg)" ]
}

@test "remove from a dir" {
    cat > stacker.yaml <<EOF
a:
    from:
        type: docker
        url: docker://centos:latest
    import:
        - foo
    run: |
        [ -f /stacker/foo/bar ]
EOF

    mkdir -p foo
    touch foo/bar
    stacker build
    [ "$status" -eq 0 ]

    cat > stacker.yaml <<EOF
a:
    from:
        type: docker
        url: docker://centos:latest
    import:
        - foo
    run: |
        [ -f /stacker/foo/baz ]
EOF
    rm foo/bar
    touch foo/baz
    stacker build
    [ "$status" -eq 0 ]
}
