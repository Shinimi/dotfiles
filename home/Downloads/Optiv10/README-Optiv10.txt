Optiv10 — OptiScaler v10.0.0-pre1 (build 10911bcb, 2026-10-20 17:46) + AMD FSR 4.1.2 driver DLLs
Put together for: RX 9060 XT (RDNA4) on CachyOS.

WHAT'S INSIDE
  OptiScaler.dll        newest build (from the 4.1.2_Vulkan 7z); adds INT8 RDNA2 / INT8 Lite FSR4 models
  OptiScaler.ini        stock, except: Dx12Upscaler=ffx, UpscalerIndex=0 (FSR4), Fsr4Model=0 (FP8),
                        Fsr4GpuSupport=1 (Proton misreports RDNA4 as RDNA3, which would force the INT8 model)
  amdxcffx64.dll        AMD DX12 driver FSR library 2.4.0.4370 (FSR 4.1.2), AMD-signed
  amdvkffx64.dll        AMD Vulkan driver FSR library 2.4.0.4370 (FSR 4.1.2), AMD-signed
  OptiScaler\           FFX / XeSS libs, D3D12 Agility, plugins (OptiPatcher, MFGUnlocker), streamline
  setup_linux.sh        official installer (renames OptiScaler.dll to dxgi.dll etc.)

DEFAULTS IN OptiScaler.ini (tuned for RX 9060 XT, 144 Hz VRR)
  Upscaling : FSR 4.1.2, FP8 model (Dx12Upscaler=ffx, UpscalerIndex=0, Fsr4Model=0, Fsr4GpuSupport=1)
  Frame gen : XeFG output (FGOutput=xefg) + MFGUnlocker plugin (LoadAsiPlugins=true), fixed 2x (InterpolationCount=1; 2=3x, 3=4x)
  FPS cap   : none (FramerateLimit=auto)
  Fixes     : UseNtdllHooks=false, PreserveSwapChain=false
  FGInput is per game (auto = off). Pick the game's own FG as input:
     game has DLSS Frame Gen  -> dlssg      game has FSR 3.1 FG -> fsrfg
     game has FSR 3.0 FG      -> fsrfg30    no FG in game       -> upscaler (OptiFG, may need HUDfix)

INSTALL (Linux) — one command
  bash ~/Downloads/Optiv10/install-optiv10.sh "<game exe folder>" dxgi.dll <FGInput>
  e.g. bash ~/Downloads/Optiv10/install-optiv10.sh "$HOME/.../SomeGame/Binaries/Win64" dxgi.dll dlssg
  It backs up anything it replaces into _optiv10_backup_<date>/ in the game folder.
  Use winmm.dll or version.dll instead of dxgi.dll if the game already ships a dxgi.dll.
  Steam launch options:  game-performance mangohud %command%
  In game: choose DLSS (or FSR/XeSS) + the game's frame gen, then press INSERT to check:
  upscaler FSR 4.x / FP8, XeFG state ON.

UNINSTALL: delete dxgi.dll, OptiScaler.ini, OptiScaler\, amdxcffx64.dll, amdvkffx64.dll from the game
           folder and restore files from the _optiv10_backup_* folder.
