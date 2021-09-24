load("@obazl_rules_ocaml//ocaml:providers.bzl",
     "AdjunctDepsProvider",
     "CcDepsProvider",
     # "OcamlDepsetProvider",
     "OcamlSignatureProvider",
     "OcamlModuleProvider",
     "OcamlNsLibraryProvider",
     "OcamlNsResolverProvider",
     # "OpamDepsProvider",
     "OcamlSDK")

####################################
def _depsets_aspect_impl(target, ctx):
    print("depsets_aspect for rule: {}".format(ctx.label))
    # for a in dir(ctx.rule.attr):
    #     print("rule attr: %s" % a)
    if hasattr(ctx.rule.attr, 'deps'):
        for dep in ctx.rule.attr.deps:
            print("dep: %s" % dep)
            # for path in dep[DefaultMemo].paths.to_list():
            #     print("Path: %s" % path)
            # if OpamDepsProvider in dep:
            #     for pkg in dep[OpamDepsProvider].pkgs.to_list():
            #         print("OPAM dep pkg: %s" % pkg)
    if hasattr(ctx.rule.attr, 'deps_adjunct'):
        for dep in ctx.rule.attr.deps_adjunct:
            print("ppx dep: %s" % dep)

    # ocaml_library, ocaml_archive
    if hasattr(ctx.rule.attr, 'modules'):
        for m in ctx.rule.attr.modules:
            print("module: %s" % m)

    if hasattr(ctx.rule.attr, 'submodules'):
        for m in ctx.rule.attr.submodules:
            print("submodule: %s" % m)
        # for [f, m] in ctx.rule.attr.submodules.items():
        #     print("submod: %s" % m)
        #     for fdep in f[DefaultInfo].files.to_list():
        #         print("NOPAM dep: %s" % fdep.path)
        #     # for path in f[DefaultMemo].paths.to_list():
        #     #     print("Path: %s" % path)
        #     # if OpamDepsProvider in f:
        #     #     print("OPAM deps: %s" % f[OpamDepsProvider])
        #     # if OcamlModuleProvider in f:
        #     #     print("Module Paths: %s" % f[OcamlModuleProvider].paths)
        #     #     print("Module resolvers: %s" % f[OcamlModuleProvider].resolvers)
        #     print("Submod: {m} -> {f}".format(
        #         m = m, f = f.label)
        #           )
    return []

depsets_aspect = aspect(
    implementation = _depsets_aspect_impl,
    attr_aspects = ["deps", "deps_adjunct", "modules", "submodules"],
)

####################################
def _print_aspect_impl(target, ctx):
    print("TARGET: %s" % target)
    if hasattr(ctx.rule.attr, 'deps'):
        for dep in ctx.rule.attr.deps:
            print("dep: %s" % dep)
            # for path in dep[DefaultMemo].paths.to_list():
            #     print("Path: %s" % path)
            # if OpamDepsProvider in dep:
            #     for pkg in dep[OpamDepsProvider].pkgs.to_list():
            #         print("OPAM dep pkg: %s" % pkg)
    if hasattr(ctx.rule.attr, 'submodules'):
        print("submods: %s" % ctx.rule.attr.submodules)
        for [f, m] in ctx.rule.attr.submodules.items():
            print("submod: %s" % m)
            for fdep in f[DefaultInfo].files.to_list():
                print("NOPAM dep: %s" % fdep.path)
            # for path in f[DefaultMemo].paths.to_list():
            #     print("Path: %s" % path)
            # if OpamDepsProvider in f:
            #     print("OPAM deps: %s" % f[OpamDepsProvider])
            # if OcamlModuleProvider in f:
            #     print("Module Paths: %s" % f[OcamlModuleProvider].paths)
            #     print("Module resolvers: %s" % f[OcamlModuleProvider].resolvers)
            print("Submod: {m} -> {f}".format(
                m = m, f = f.label)
                  )
    if hasattr(ctx.rule.attr, 'struct'):
        print("struct: %s" % ctx.rule.attr.struct)
        for s in ctx.rule.attr.struct.files.to_list():
            print("Struct: %s" % s.path)
    return []

print_aspect = aspect(
    implementation = _print_aspect_impl,
    attr_aspects = ["submodules", "struct", "sig", "src", "deps"],
)

####################################
def _providers_impl(target, ctx):
    print("TARGET: %s" % target)
    for dep in target[DefaultInfo].files.to_list():
        print(dep)

    report = "REPORT "
    if CcDepsProvider in target:
        report = report + "CC DEPS:"
        for cc in target[CcDepsProvider].libs:
            report = report + str(cc)

    report_file = ctx.actions.declare_file("providers.txt")
    print("WRITING file: %s" % report_file.path)
    print("CONTENT: %s" % report)

    ctx.actions.write(
        report_file,
        report
    )

    return [
        OutputGroupInfo(
            providers = depset([report_file])
        )
    ]

providers = aspect(
    implementation = _providers_impl,
    attr_aspects = [],
)