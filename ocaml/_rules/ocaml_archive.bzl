load("//ocaml:providers.bzl",
     "OcamlProvider",
     "OcamlArchiveMarker",
     "OcamlImportMarker",
     "OcamlLibraryMarker",
     "OcamlModuleMarker",
     "OcamlNsMarker",
     "OcamlSignatureMarker"
     )

load(":options.bzl", "options", "options_aggregators")

load("impl_archive.bzl", "impl_archive")

load("//ocaml/_transitions:ns_transitions.bzl", "nsarchive_in_transition")

load("//ocaml/_debug:colors.bzl", "CCUYEL", "CCRESET")

###############################
def _ocaml_archive(ctx):

    # if True:
    #     tc = ctx.toolchains["@rules_ocaml//toolchain:type"]
    #     print("BUILD TGT: {color}{lbl}{reset}".format(
    #         color=CCUYEL, reset=CCRESET, lbl=ctx.label))
    #     print("  TC.NAME: %s" % tc.name)
    #     print("  TC.HOST: %s" % tc.host)
    #     print("  TC.TARGET: %s" % tc.target)
    #     print("  TC.COMPILER: %s" % tc.compiler.basename)

    return impl_archive(ctx)

###############################
rule_options = options("ocaml")
rule_options.update(options_aggregators())

#####################
ocaml_archive = rule(
    implementation = _ocaml_archive,
    doc = """Generates an OCaml archive file.""",
    attrs = dict(
        rule_options,
        archive_name = attr.string(
            doc = "Name of generated archive file, without extension. If not provided, name will be derived from target 'name' attribute."
        ),
        ## CONFIGURABLE DEFAULTS
        _linkall     = attr.label(default = "@rules_ocaml//cfg/archive/linkall"),
        # _threads     = attr.label(default = "@rules_ocaml//cfg/archive/threads"),
        _warnings  = attr.label(default = "@rules_ocaml//cfg/archive:warnings"),
        #### end options ####

        shared = attr.bool(
            doc = "True: build a shared lib (.cmxs)",
            default = False
        ),

        standalone = attr.bool(
            doc = "True: link total depgraph. False: link only direct deps.",
            default = False
        ),

        ## FIXME: do archive rules need to support cc_deps?
        ## They should be attached to members of the archive.
        ## OTOH, if the ocaml wrapper on a cc_dep consists of multiple modules
        ## it makes sense to aggregate them into an archive or library
        ## and attach the cc_dep to the latter.
        cc_deps = attr.label_keyed_string_dict(
            doc = """Dictionary specifying C/C++ library dependencies. Key: a target label; value: a linkmode string, which determines which file to link. Valid linkmodes: 'default', 'static', 'dynamic', 'shared' (synonym for 'dynamic'). For more information see [CC Dependencies: Linkmode](../ug/cc_deps.md#linkmode).
            """,
            providers = [[CcInfo]]
        ),
        cc_linkopts = attr.string_list(
            doc = "List of C/C++ link options, to be passed to compiler using `-ccopt`. For example, `[\"-lstd++\"]`.",
        ),
        # cc_linkall = attr.label_list( ## FIXME: not needed
        #     doc     = "True: use `-whole-archive` (GCC toolchain) or `-force_load` (Clang toolchain). Deps in this attribute must also be listed in cc_deps.",
        #     providers = [CcInfo],
        # ),
        _cc_linkmode = attr.label( ## FIXME: not needed?
            doc     = "Override platform-dependent link mode (static or dynamic). Configurable default is platform-dependent: static on Linux, dynamic on MacOS.",
            # default is os-dependent, but settable to static or dynamic
        ),
        # _mode = attr.label(
        #     default = "@rules_ocaml//build/mode"
        # ),
        # _projroot = attr.label(
        #     default = "@rules_ocaml//cfg:projroot"
        # ),
        # _sdkpath = attr.label(
        #     default = Label("@rules_ocaml//cfg:sdkpath")
        # ),
        _rule = attr.string( default = "ocaml_archive" ),
        _allowlist_function_transition = attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist"
        ),
    ),
    incompatible_use_toolchain_transition = True,
    ## this is not an ns archive, and it does not use ns ConfigState,
    ## but we need to reset the ConfigState anyway, so the deps are
    ## not affected if this is a dependency of an ns aggregator.
    cfg     = nsarchive_in_transition,
    provides = [OcamlArchiveMarker, OcamlProvider],
    executable = False,
    toolchains = ["@rules_ocaml//toolchain:type"],
)
