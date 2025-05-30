{
  lib,
  stdenv,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  replaceVars,
  alsa-utils,
  libnotify,
  which,
  poetry-core,
  jeepney,
  loguru,
  pytest,
  dbus,
  coreutils,
}:

buildPythonPackage rec {
  pname = "notify-py";
  version = "0.3.43";
  format = "pyproject";

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "ms7m";
    repo = "notify-py";
    tag = "v${version}";
    hash = "sha256-4PJ/0dLG3bWDuF1G/qUmvNaIUFXgPP2S/0uhZz86WRA=";
  };

  patches =
    lib.optionals stdenv.hostPlatform.isLinux [
      # hardcode paths to aplay and notify-send
      (replaceVars ./linux-paths.patch {
        aplay = "${alsa-utils}/bin/aplay";
        notifysend = "${libnotify}/bin/notify-send";
      })
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      # hardcode path to which
      (replaceVars ./darwin-paths.patch {
        which = "${which}/bin/which";
      })
    ];

  nativeBuildInputs = [
    poetry-core
  ];

  pythonRelaxDeps = [ "loguru" ];

  propagatedBuildInputs = [ loguru ] ++ lib.optionals stdenv.hostPlatform.isLinux [ jeepney ];

  nativeCheckInputs = [ pytest ] ++ lib.optionals stdenv.hostPlatform.isLinux [ dbus ];

  checkPhase =
    if stdenv.hostPlatform.isDarwin then
      ''
        # Tests search for "afplay" binary which is built in to macOS and not available in nixpkgs
        mkdir $TMP/bin
        ln -s ${coreutils}/bin/true $TMP/bin/afplay
        PATH="$TMP/bin:$PATH" pytest
      ''
    else if stdenv.hostPlatform.isLinux then
      ''
        dbus-run-session \
          --config-file=${dbus}/share/dbus-1/session.conf \
          pytest
      ''
    else
      ''
        pytest
      '';

  # GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name
  # org.freedesktop.Notifications was not provided by any .service files
  doCheck = false;

  pythonImportsCheck = [ "notifypy" ];

  meta = with lib; {
    description = "Cross-platform desktop notification library for Python";
    mainProgram = "notifypy";
    homepage = "https://github.com/ms7m/notify-py";
    changelog = "https://github.com/ms7m/notify-py/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [
      austinbutler
      dotlambda
    ];
  };
}
