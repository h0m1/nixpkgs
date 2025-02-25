{
  stdenv,
  lib,
  fetchzip,
  replaceVars,
  dpkg,
  autoPatchelfHook,
  cups,
  tcl,
  tk,
  xorg,
  makeWrapper,
}:
let
  debPlatform =
    if stdenv.hostPlatform.system == "x86_64-linux" then
      "amd64"
    else if stdenv.hostPlatform.system == "i686-linux" then
      "i386"
    else
      throw "Unsupported system: ${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation rec {
  pname = "fxlinuxprintutil";
  version = "1.1.1-1";

  # https://support-fb.fujifilm.com/driver_downloads/fxlinuxpdf112119031.zip is gone
  src = fetchzip {
    url = "https://github.com/NixOS/nixpkgs/files/12232817/fxlinuxpdf112119031.zip";
    sha256 = "1mv07ch6ysk9bknfmjqsgxb803sj6vfin29s9knaqv17jvgyh0n3";
  };

  patches = [
    # replaces references to “path/to/fxlputil” via $0 that are broken by our wrapProgram
    # with /nix/store/fxlinuxprintutil/bin/fxlputil
    ./fxlputil.patch

    # replaces the code that looks for Tcl packages in the working directory and /usr/lib
    # or /usr/lib64 with /nix/store/fxlinuxprintutil/lib
    ./fxlputil.tcl.patch

    # replaces the code that looks for X11’s locale.alias in /usr/share/X11/locale or
    # /usr/lib/X11/locale with /nix/store/libX11/share/X11/locale
    (replaceVars ./fxlocalechk.tcl.patch {
      inherit (xorg) libX11;
    })
  ];

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    cups
    tcl
    tk
  ];

  sourceRoot = ".";
  unpackCmd = "dpkg-deb -x $curSrc/fxlinuxprintutil_${version}_${debPlatform}.deb .";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    mv usr/bin $out
    mv usr/lib $out

    wrapProgram $out/bin/fxlputil --prefix PATH : ${
      lib.makeBinPath [
        tcl
        tk
      ]
    }
  '';

  meta = with lib; {
    description = "Optional configuration tool for fxlinuxprint";
    homepage = "https://onlinesupport.fujixerox.com";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
