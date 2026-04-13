{
  lib,
  pkgs,
  fetchFromGitHub,
  python3,
  libreoffice,
  makeWrapper,
  runCommand,
}: let
  src = fetchFromGitHub {
    owner = "patrup";
    repo = "mcp-libre";
    rev = "edc5123dcd740049c54de9bc9abf8d69b2f1293f";
    hash = "sha256-J0oXBvn5Bejnn6p6cc4He6lfk+aFnuMSgxJBGhcS6EE=";
  };

  pythonEnv = python3.withPackages (ps: [
    ps.httpx
    ps.pydantic
    ps.mcp
  ]);
in
  runCommand "mcp-libre" {
    nativeBuildInputs = [makeWrapper];
    meta = {
      description = "LibreOffice Model Context Protocol server";
      homepage = "https://github.com/patrup/mcp-libre";
      license = lib.licenses.mit;
      mainProgram = "mcp-libre";
    };
  } ''
    mkdir -p $out/share/mcp-libre $out/bin
    cp -r ${src}/src/. $out/share/mcp-libre/

    makeWrapper ${pythonEnv}/bin/python $out/bin/mcp-libre \
      --add-flags "$out/share/mcp-libre/main.py" \
      --prefix PATH : ${lib.makeBinPath [libreoffice]} \
      --set PYTHONPATH "$out/share/mcp-libre" \
      --unset PYTHONHOME
  ''
