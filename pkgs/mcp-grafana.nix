{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-grafana";
  version = "0.11.6";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "mcp-grafana";
    rev = "v${version}";
    sha256 = "sha256-cJjapd2phI4NgMAPzsKrs74+sEK7ykfKHQx24FVpHoQ=";
  };

  vendorHash = "sha256-a9VgfzJmbTudYSLqhBBnkpq37xghtxWTzpcd7rMlZmA=";

  subPackages = ["cmd/mcp-grafana"];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # Skip tests as they require network/Grafana instance
  doCheck = false;

  meta = with lib; {
    description = "Model Context Protocol server for Grafana";
    homepage = "https://github.com/grafana/mcp-grafana";
    license = licenses.asl20;
    maintainers = [];
    mainProgram = "mcp-grafana";
  };
}
