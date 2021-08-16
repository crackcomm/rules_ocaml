def _null_impl(ctx):

    print("null rule: %s" % ctx.label)

    tc = ctx.toolchains["@obazl_rules_ocaml//ocaml:toolchain"]

    print("bootstrapper: %s" % tc.opam_bootstrapper)

####################
ocaml_null = rule(
    implementation = _null_impl,
    doc = """Rule for testing toolchains, etc.""",
    executable = False,
    toolchains = ["@obazl_rules_ocaml//ocaml:toolchain"],
)
