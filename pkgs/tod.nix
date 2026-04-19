{
  lib,
  buildGoModule,
  fetchgit,
}:
buildGoModule rec {
  pname = "tod";
  version = "2.1.1";

  src = fetchgit {
    url = "https://code.onedev.io/onedev/tod.git";
    rev = "refs/tags/v${version}";
    hash = "sha256-p/iz/sEwMLRCPtN4jqeGPY7iK6jPTzwV3Pmlh7hQXZw=";
  };

  vendorHash = "sha256-CQS24qkCtMZ0RRJ3UAiETZmJcAGpSU57z8m3jvEAUnc=";

  ldflags = [
    "-s"
    "-w"
  ];

  # Tests require a OneDev instance
  doCheck = false;

  meta = with lib; {
    description = "CLI tool and MCP server for OneDev";
    homepage = "https://code.onedev.io/onedev/tod";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "tod";
  };
}
