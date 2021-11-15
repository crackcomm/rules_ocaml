load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

load("//ocaml:providers.bzl",
     "OcamlProvider",
     "CompilationModeSettingProvider",
     "OcamlNsResolverProvider")

load("//ocaml/_functions:utils.bzl",
     "capitalize_initial_char",
     "get_fs_prefix",
     "get_sdkpath",
)

load("//ocaml/_functions:module_naming.bzl", "normalize_module_label")

load(":impl_common.bzl", "dsorder", "module_sep", "resolver_suffix")

#################
def impl_ns_resolver(ctx):

    debug = False
    # if ctx.label.name == "":
    #     debug = True

    if debug:
        print("")
        print("Start: IMPL_NS %s" % ctx.label.name)
        print("LABEL: %s" % ctx.label)
        print("_NS_PREFIXES: %s" % ctx.attr._ns_prefixes[BuildSettingInfo].value)
        print("_NS_SUBMODULES: %s" % ctx.attr._ns_submodules[BuildSettingInfo].value)

    submodules = ctx.attr._ns_submodules[BuildSettingInfo].value
    if len(submodules) < 1:
        if debug:
            print("NO SUBMODULES")
        return [DefaultInfo(),
                OcamlNsResolverProvider()]
    # print("submodules: %s" % submodules)

    env = {"PATH": get_sdkpath(ctx)}

    tc = ctx.toolchains["@obazl_rules_ocaml//ocaml:toolchain"]

    mode = ctx.attr._mode[CompilationModeSettingProvider].value

    ################
    default_outputs = [] ## .cmx only
    action_outputs = []  ## .cmx, .cmi, .o
    rule_outputs = [] # excludes .cmi

    obj_cm_ = None
    obj_cmi = None

    aliases = []

    ns_prefixes = ctx.attr._ns_prefixes[BuildSettingInfo].value

    user_main = False

    for submod_label in submodules:  # e.g. [Color, Red, Green, Blue], where main = Color
        # print("submod_label: %s" % submod_label)
        submodule = normalize_module_label(submod_label)
        # print("submodule normed: %s" % submodule)
        # if ctx.attr._ns_strategy[BuildSettingInfo].value == "fs":
        #     ## NB: submodules may come from different pkgs
        #     fs_prefix = get_fs_prefix(submod_label)
        #     alias_prefix = fs_prefix
        # else:
        fs_prefix = ""
        alias_prefix = module_sep.join(ns_prefixes) ## ns_prefix

        ## an ns can be used as a submodule of another ns
        nslib_submod = False
        if submodule.startswith("#"):
            # this is an nslib submodule, do not prefix
            nslib_submod = True
            submodule = capitalize_initial_char(submodule[1:])

        if len(ns_prefixes) > 0:
            if len(ns_prefixes) == 1:
                # print("one ns_prefixes: %s" % ns_prefixes)
                ## this is the top-level nslib - do not use fs_prefix
                if submodule == ns_prefixes[0]:
                    user_main = True
                    continue ## no alias for main module
            elif submodule == ns_prefixes[-1]:
                # this is main nslib module
                user_main = True
                continue ## no alias for main module

        # print("submodule pre: %s" % submodule)
        submodule = capitalize_initial_char(submodule)
        # print("submodule uc: %s" % submodule)

        alias = "module {mod} = {ns}{sep}{mod}".format(
            mod = submodule,
            sep = "" if nslib_submod else module_sep, # fs_prefix != "" else module_sep,
            ns  = "" if nslib_submod else alias_prefix
        )
        aliases.append(alias)

    # print("aliases: %s" % aliases)

    ns_name = module_sep.join(ns_prefixes)
    if user_main:
        resolver_module_name = ns_name + resolver_suffix
    else:
        resolver_module_name = ns_name

    # do not generate a resolver module unless we have at least one alias
    if len(aliases) < 1:
        # print("NO ALIASES: %s" % ctx.label)
        return [DefaultInfo(),
                OcamlNsResolverProvider(ns_name = ns_name)]

    resolver_src_filename = resolver_module_name + ".ml"
    resolver_src_file = ctx.actions.declare_file(resolver_src_filename)

    # print("resolver_module_name: %s" % resolver_module_name)
    ## action: generate ns resolver module file with alias content
    ##################
    ctx.actions.write(
        output = resolver_src_file,
        content = "\n".join(aliases) + "\n"
    )
    ##################

    ## then compile it:

    obj_cmi_fname = resolver_module_name + ".cmi"
    obj_cmi = ctx.actions.declare_file(obj_cmi_fname)
    action_outputs.append(obj_cmi)

    if mode == "native":
        obj_o_fname = resolver_module_name + ".o"
        obj_o = ctx.actions.declare_file(obj_o_fname)
        action_outputs.append(obj_o)
        rule_outputs.append(obj_o)
        obj_cm__fname = resolver_module_name + ".cmx"
    else:
        obj_cm__fname = resolver_module_name + ".cmo"

    obj_cm_ = ctx.actions.declare_file(obj_cm__fname)
    action_outputs.append(obj_cm_)
    default_outputs.append(obj_cm_)
    rule_outputs.append(obj_cm_)

    ################################
    args = ctx.actions.args()

    # if mode == "native":
    #     args.add(tc.ocamlopt.basename)
    # else:
    #     args.add(tc.ocamlc.basename)

    if ctx.attr._warnings:
        args.add_all(ctx.attr._warnings[BuildSettingInfo].value, before_each="-w", uniquify=True)

    args.add("-I", resolver_src_file.dirname)
    action_inputs = []

    action_inputs.append(resolver_src_file)

    ## -no-alias-deps is REQUIRED for ns modules;
    ## see https://caml.inria.fr/pub/docs/manual-ocaml/modulealias.html
    args.add("-no-alias-deps")

    args.add("-c")

    args.add("-o", obj_cm_)

    args.add("-impl")
    args.add(resolver_src_file.path)

    if mode == "native":
        exe = tc.ocamlopt.basename
    else:
        exe = tc.ocamlc.basename

    ctx.actions.run(
        env = env,
        executable = exe,
        arguments = [args],
        inputs = action_inputs,
        outputs = action_outputs,
        tools = [tc.ocamlopt],
        mnemonic = "OcamlNsResolverAction" if ctx.attr._rule == "ocaml_ns" else "PpxNsResolverAction",
        progress_message = "{mode} compiling {rule}: {ws}//{pkg}:{tgt}".format(
            mode = mode,
            rule=ctx.attr._rule,
            ws  = ctx.label.workspace_name if ctx.label.workspace_name else ctx.workspace_name,
            pkg = ctx.label.package,
            tgt=ctx.label.name,
        )
    )

    defaultInfo = DefaultInfo(
        files = depset(
            order  = dsorder,
            direct = default_outputs # action_outputs
        )
    )

    nsResolverProvider = OcamlNsResolverProvider(
        # provide src for output group, for easy reference
        resolver_file = resolver_src_file,
        submodules = submodules,
        resolver = resolver_module_name,
        prefixes   = ns_prefixes,
        ns_name    = ns_name
    )

    ocamlProvider = OcamlProvider(
        inputs    = depset(
            order = dsorder,
            direct = rule_outputs + action_outputs
        ),
        paths     = depset(direct = [obj_cmi.dirname]),
    )

    # print("resolver provider: %s" % ocamlProvider)

    return [
        defaultInfo,
        nsResolverProvider,
        ocamlProvider,
    ]
