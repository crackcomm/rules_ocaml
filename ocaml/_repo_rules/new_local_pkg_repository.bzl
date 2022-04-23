load("@bazel_skylib//lib:paths.bzl", "paths")

load("@bazel_tools//tools/build_defs/repo:utils.bzl",
     "workspace_and_buildfile")

#######################################
def impl_new_local_pkg_repository(repo_ctx):

    print("impl_new_local_pkg_repository")

    if "OPAM_SWITCH_PREFIX" in repo_ctx.os.environ:
        opam_switch_prefix = repo_ctx.os.environ["OPAM_SWITCH_PREFIX"] + "/lib"
    else:
        fail("env var OPAM_SWITH_PREFIX must be passed  in attr 'environ'")

    print("opam_switch_prefix: %s" % opam_switch_prefix)

    ## symlinks before build files

    ## FIXME: get opam switch prefix and add to path

    ## top-level subdir and bldfile
    linkpath = opam_switch_prefix + "/" + repo_ctx.attr.path
    linkpath = repo_ctx.path(linkpath).realpath
    print("LINKPATH: %s" % linkpath)
    # if repo_ctx.name == "ocaml.ffi":
    #     print("OCAML.FFI linkpath: %s" % linkpath)

    cmd = ["ls", "-p", str(linkpath) + "/"]
    r = repo_ctx.execute(
        cmd,
    )
    if r.return_code == 0:
        dirlist = r.stdout.strip().splitlines()

        # print("DIRLIST %s" % dirlist)
    elif r.return_code == 1:
        print("{cmd} rc    : {rc}".format(
            cmd=cmd, rc= r.return_code))
        # print("  stdout: {stdout}".format(
        #     cmd=cmd, stdout= r.stdout))
        # print("  stderr: {stderr}".format(
        #     cmd=cmd, stderr= r.stderr))
        dirlist = []
    else:
        print("{cmd} rc    : {rc}".format(
            cmd=cmd, rc= r.return_code))
        print("  stdout: {stdout}".format(
            cmd=cmd, stdout= r.stdout))
        print("  stderr: {stderr}".format(
            cmd=cmd, stderr= r.stderr))
        fail(" cmd failure.")

    for f in dirlist:
        if (not f.endswith("/")):
            fpath = repo_ctx.path(str(linkpath) + "/" + f)

            if (fpath.basename not in [
                "BUILD.bazel", "BUILD", "WORKSPACE.bazel",  "WORKSPACE",
                "META", "opam"
            ]):
                # if repo_ctx.name == "cmdliner":
                #     print("cmdliner F: %s" % fpath.basename)
                print("symlinking {src} => {dst}".format(
                    src=fpath, dst=fpath.basename))

                repo_ctx.symlink(fpath, fpath.basename)

    workspace_and_buildfile(repo_ctx)

    # print("SUBPACKAGES: %s" % repo_ctx.attr.subpackages)

    # if repo_ctx.attr.subpackages:

    for [build_file, linkage] in repo_ctx.attr.subpackages.items():
        lst = linkage.split(" ", 2)
        # print("Linkage: {sd} <= {lnk}".format(
        #     sd = lst[0], lnk = lst[1]))
        linkpath = opam_switch_prefix + "/" + lst[1]
        linkpath = repo_ctx.path(linkpath).realpath

        # print("LINKPATH: %s" % linkpath)
        cmd = ["ls", "-p", str(linkpath) + "/"]
        r = repo_ctx.execute(
            cmd,
            # working_directory = str(linkpath)
        )
        if r.return_code == 0:
            dirlist = r.stdout.strip().splitlines()
            # print("DIRLIST %s" % dirlist)
        elif r.return_code == 1:
            print("{cmd} rc    : {rc}".format(
                cmd=cmd, rc= r.return_code))
            # print("  stdout: {stdout}".format(
            #     cmd=cmd, stdout= r.stdout))
            # print("  stderr: {stderr}".format(
            #     cmd=cmd, stderr= r.stderr))
            dirlist = []
        else:
            print("{cmd} rc    : {rc}".format(
                cmd=cmd, rc= r.return_code))
            print("  stdout: {stdout}".format(
                cmd=cmd, stdout= r.stdout))
            print("  stderr: {stderr}".format(
                cmd=cmd, stderr= r.stderr))
            fail(" cmd failure.")

        # dirs = linkpath.readdir()
        for f in dirlist:
            # print("LINKING: %s" % f)

            if not f.endswith("/") and f not in ["META"]:
                fpath = repo_ctx.path(str(linkpath) + "/" + f)
                [bn, ext] = paths.split_extension(fpath.basename)
                repo_ctx.symlink(fpath, lst[0] + "/" + fpath.basename)

        repo_ctx.file(lst[0] + "/BUILD.bazel", repo_ctx.read(build_file))

###################
new_local_pkg_repository = repository_rule(
    implementation = impl_new_local_pkg_repository,
    environ = ["OPAM_SWITCH_PREFIX"],
    attrs = dict(
        path = attr.string(
            doc = "Path to opam, relative to OPAM_SWITCH_PREFIX"
        ),
        build_file = attr.label(
            allow_single_file = True,
        ),

        subpackages = attr.label_keyed_string_dict(
            doc = """Entry key is path to build file, value is 'linkage' pair. First element is directory path to be created under repo root; the build file will be copied to it. Second element is a directory under $OPAM_SWITCH_PREFIX/lib; files therein will be linked to the repo subdirectory made by first element.  I.e. first element is a repo subdir that will contain the BUILD file and the symlinks into the OPAM lib tree.
            """
        ),

        build_file_content = attr.string(
            doc =
            "The content for the BUILD file for this repository. " +
            "Either build_file or build_file_content can be specified, but " +
            "not both.",
        ),
        workspace_file = attr.label(
            doc =
            "The file to use as the `WORKSPACE` file for this repository. " +
            "Either `workspace_file` or `workspace_file_content` can be " +
            "specified, or neither, but not both.",
        ),
        workspace_file_content = attr.string(
            doc =
            "The content for the WORKSPACE file for this repository. " +
            "Either `workspace_file` or `workspace_file_content` can be " +
            "specified, or neither, but not both.",
        ),
    )
)
