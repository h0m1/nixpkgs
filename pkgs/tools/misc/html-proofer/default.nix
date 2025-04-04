{
  bundlerEnv,
  ruby,
  lib,
  bundlerUpdateScript,
}:

bundlerEnv rec {
  name = "${pname}-${version}";
  pname = "html-proofer";
  version = (import ./gemset.nix).html-proofer.version;

  inherit ruby;
  gemdir = ./.;

  passthru.updateScript = bundlerUpdateScript pname;

  meta = with lib; {
    description = "Tool to validate HTML files";
    homepage = "https://github.com/gjtorikian/html-proofer";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "htmlproofer";
  };
}
