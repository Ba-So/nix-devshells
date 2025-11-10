# Module validation functions
# Provides validation for module structure and categories
{lib}: rec {
  # Validate that a module has the required structure
  # Throws descriptive errors if validation fails
  validateModule = module: let
    hasValidMeta =
      module ? meta
      && module.meta ? name
      && builtins.isString module.meta.name
      && module.meta.name != "";

    hasPackages = module ? packages && builtins.isList module.packages;

    moduleName =
      if module ? meta && module.meta ? name
      then module.meta.name
      else "<unnamed>";
  in
    if !hasValidMeta
    then
      throw ''
        Module validation failed: Module must have 'meta.name' field.
        ${
          if module ? meta
          then "meta exists but name is missing or invalid"
          else "meta field is missing"
        }
      ''
    else if !hasPackages
    then
      throw ''
        Module validation failed for module '${moduleName}':
        Module must have 'packages' field as a list.
        ${
          if module ? packages
          then "packages exists but is not a list"
          else "packages field is missing"
        }
      ''
    else module;

  # Validate that a category name is valid
  validateCategory = category: let
    validCategories = ["language" "mcp" "tool" "preset"];
    isValid = builtins.elem category validCategories;
  in
    if !isValid
    then
      throw ''
        Invalid module category: '${category}'
        Valid categories are: ${lib.concatStringsSep ", " validCategories}
      ''
    else category;

  # Validate multiple modules at once
  validateModules = modules: map validateModule modules;
}
