load("//ocaml:providers.bzl",
     "CompilationModeSettingProvider",
     "OcamlProvider",
     "OcamlLibraryMarker",
     "OcamlModuleMarker",
     "OcamlNsMarker",
     "OcamlNsResolverProvider")

load("//ocaml/_transitions:transitions.bzl",
     "nslib_in_transition")

load("//ocaml/_transitions:ns_transitions.bzl",
     "ocaml_nslib_submodules_out_transition")

load(":impl_library.bzl", "impl_library")

load(":options.bzl",
     "options",
     "options_ns_opts",
     "options_ns_library")

###############################
def _ocaml_ns_library(ctx):

    tc = ctx.toolchains["@rules_ocaml//ocaml:toolchain"]

    mode = ctx.attr._mode[CompilationModeSettingProvider].value

    if mode == "native":
        tool = tc.ocamlopt # .basename
    else:
        tool = tc.ocamlc  #.basename

    tool_args = []

    return impl_library(ctx, mode, tool, tool_args)

################################
rule_options = options("ocaml")
rule_options.update(options_ns_opts("ocaml"))
rule_options.update(options_ns_library("ocaml"))
# rule_options.update(options_ppx)

################
ocaml_ns_library = rule(
    implementation = _ocaml_ns_library,
    doc = """Generate a 'namespace' module. [User Guide](../ug/ocaml_ns.md).  Provides: [OcamlNsMarker](providers_ocaml.md#ocamlnsmoduleprovider).

**NOTE** 'name' must be a legal OCaml module name string.  Leading underscore is illegal.

See [Namespacing](../ug/namespacing.md) for more information on namespaces.

    """,
    attrs = dict(
        rule_options,
        _rule = attr.string(default = "ocaml_ns_library")
    ),
    cfg     = nslib_in_transition,
    provides = [OcamlNsMarker, OcamlLibraryMarker, OcamlProvider],
    executable = False,
    toolchains = ["@rules_ocaml//ocaml:toolchain"],
)
