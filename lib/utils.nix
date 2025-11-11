# Utility functions for module resolution and manipulation
# Provides helpers for working with the module system
{
  lib,
  modules,
}: rec {
  # Resolve a module by name and category with error handling
  resolveModule = name: category: let
    categoryModules = modules.${category} or {};
    hasModule = categoryModules ? ${name};
  in
    if !hasModule
    then
      throw ''
        Module '${name}' not found in category '${category}'.
        Available modules in '${category}': ${lib.concatStringsSep ", " (builtins.attrNames categoryModules)}
      ''
    else categoryModules.${name};

  # Flatten packages from a list of modules
  flattenPackages = moduleList:
    lib.flatten (map (m: m.packages or []) moduleList);

  # Merge shellHooks from multiple modules with newlines
  mergeShellHooks = moduleList:
    lib.concatStringsSep "\n" (map (m: m.shellHook or "") moduleList);

  # Merge environment variables from multiple modules
  # Later modules override earlier ones
  mergeEnv = moduleList:
    lib.foldl (acc: m: acc // (m.env or {})) {} moduleList;

  # Memoization helper - caches function results
  # Note: In Nix, memoization is implicit due to lazy evaluation
  # This is more of a documentation function
  memoize = fn: fn;

  # Filter modules by category
  filterByCategory = category: moduleList:
    builtins.filter (m: (m.meta.category or "") == category) moduleList;

  # Extract module names from a list of modules
  getModuleNames = moduleList:
    map (m: m.meta.name or "<unnamed>") moduleList;

  # Deduplicate modules by name (keeps last occurrence)
  # This allows explicit mcps to override preset-included ones
  deduplicateModules = moduleList: let
    # Create a map from module name to module
    # Later modules override earlier ones with the same name
    moduleMap =
      lib.foldl (
        acc: m: let
          name = m.meta.name or "<unnamed>";
        in
          acc // {${name} = m;}
      ) {}
      moduleList;
  in
    # Convert back to a list
    builtins.attrValues moduleMap;

  # Resolve multiple modules at once
  resolveModules = names: category:
    map (name: resolveModule name category) names;
}
