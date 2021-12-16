clc;
clear functions;

old_dir = cd(fileparts(which(mfilename)));

isOctave = isempty(ver('matlab'));

if ~isOctave    % skip for Octave (which doesn't yet have INMEM)
  [~,mexLoaded] = inmem('-completenames');
  eval('while mislocked(''ipopt''); munlock(''ipopt''); end;');
end

disp('---------------------------------------------------------');
CMD = 'mex -largeArrayDims -Isrc ';
CMD = [ CMD ' ./src/ipopt.cc ./src/IpoptInterfaceCommon.cc '];

if ismac
  %
  % libipopt must be set with:
  % install_name_tool -id "@loader_path/libipopt.3.dylib" libipopt.3.dylib
  %
  IPOPT_HOME = '../Ipopt';
  CMD = [ CMD ...
    '-I' IPOPT_HOME '/include_osx/coin-or ' ...
    '-DOS_MAC -output bin/osx/ipopt_osx ' ...
    ' bin/osx/libipopt.3.dylib bin/osx/libcoinmumps.2.dylib ' ...
    ' bin/osx/libgfortran.5.dylib bin/osx/libquadmath.0.dylib ' ...
    ' bin/osx/libc++.1.dylib bin/osx/libc++abi.dylib bin/osx/libgcc_s.1.dylib' ...
    'LDFLAGS=''$LDFLAGS -Wl,-rpath,. -framework Accelerate'' ' ...
    'CXXFLAGS=''$CXXFLAGS -Wall -O2 -g'' ' ...
  ];
  %%  'LDFLAGS=''$LDFLAGS -Wl,-rpath,./ -Lbin/osx -L/usr/local/lib -lipopt -lcoinmumps -lgfortran -lquadmath  -framework Accelerate'' ' ...
  %%  '-output bin/osx/ipopt_osx bin/osx/libgcc_s.1.dylib ' ...
elseif isunix
  IPOPT_HOME = '../Ipopt';
  myCCompiler = mex.getCompilerConfigurations('C','Selected');
  switch myCCompiler.Version
  case {'4','5','6'}
    BIN_DIR = 'bin/linux_3';
    MEX_EXE = 'bin/linux_3/ipopt_linux_3';
  case {'7','8'}
    BIN_DIR = 'bin/linux_4';
    MEX_EXE = 'bin/linux_4/ipopt_linux_4';
  otherwise
    BIN_DIR = 'bin/linux_5';
    MEX_EXE = 'bin/linux_5/ipopt_linux_5';
  end
  CMD = [ CMD ...
    '-I' IPOPT_HOME '/include_linux/coin-or ' ...
    '-DOS_LINUX -output ' MEX_EXE ' '...
    'CXXFLAGS=''$CXXFLAGS -Wall -O2 -g'' ' ...
    'LDFLAGS=''$LDFLAGS -static-libgcc -static-libstdc++'' ' ...
    'LINKLIBS=''-L' BIN_DIR ' -L$MATLABROOT/bin/$ARCH -Wl,-rpath,$MATLABROOT/bin/$ARCH ' ...
              '-Wl,-rpath,. -lipopt -lcoinmumps -lopenblas -lgfortran -lgomp -ldl ' ...
              '-lMatlabDataArray -lmx -lmex -lmat -lm '' ' ...
  ];
elseif ispc
  % use ipopt precompiled with visual studio
  IPOPT_HOME = '../Ipopt/include_vs/';
  IPOPT_BIN  = 'bin/windows/';
  CMD = [ CMD ...
    '-DOS_WIN -I' IPOPT_HOME '/coin-or ' ...
    '-output ' IPOPT_BIN 'ipopt_win -L' IPOPT_BIN ...
    ' -lipopt -lipoptfort -lomp -lopenblas -lflang -lflangmain -lflangrti ' ...
  ];
else
  error('architecture not supported');
end

disp(CMD);
eval(CMD);

cd(old_dir);

disp('----------------------- DONE ----------------------------');
