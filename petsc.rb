class Petsc < Formula
  desc "Scalable (parallel) solution of scientific applications modeled by partial differential equations"
  homepage "http://www.mcs.anl.gov/petsc/index.html"
  url "http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-3.6.1.tar.gz"
  sha256 "aeac101565a4ba609c3f3f13ada475720bcd32a44676e3cbfe792da1c9fb32a2"
  head "https://bitbucket.org/petsc/petsc", :using => :git
  revision 2

  bottle do
    sha256 "bd647f0e0c83aa3a53b67ff0fe90fa89e6d1479e83fbcb34e3928884d8c1d02c" => :el_capitan
    sha256 "61618095ab4d14f51d87e8b34db427278384009b8dc05c8930d37edf311e37d5" => :yosemite
    sha256 "c74f70d54a8a6b5fe5e2b4cfc1b4a4ba62e25d65e0a38e4f01233d2f546047ef" => :mavericks
  end

  option "without-check", "Skip build-time tests (not recommended)"
  option "with-complex", "Link complex version of PETSc by default."
  option "with-debug", "Build debug version"

  deprecated_option "complex" => "with-complex"
  deprecated_option "debug"   => "with-debug"

  depends_on :mpi => [:cc, :cxx, :f77, :f90]
  depends_on :fortran
  depends_on :x11 => :optional
  depends_on "cmake" => :build

  depends_on "openblas" => :optional
  openblasdep = (build.with? "openblas") ? ["with-openblas"] : []

  depends_on "superlu43"    => [:recommended] + openblasdep
  depends_on "superlu_dist" => [:recommended] + openblasdep
  depends_on "metis"        => :recommended
  depends_on "parmetis"     => :recommended
  depends_on "scalapack"    => [:recommended] + openblasdep
  depends_on "mumps"        => [:recommended] + openblasdep # mumps is built with mpi by default
  depends_on "hypre"        => ["with-mpi", :recommended] + openblasdep
  depends_on "sundials"     => ["with-mpi", :recommended] + openblasdep
  depends_on "hdf5"         => ["with-mpi", :recommended]
  depends_on "hwloc"        => :recommended
  depends_on "suite-sparse" => [:recommended] + openblasdep
  depends_on "netcdf"       => ["with-fortran", :recommended]
  depends_on "fftw"         => ["with-mpi", "with-fortran", :recommended]

  # TODO: add ML, YAML dependencies when the formulae are available

  def oprefix(f)
    Formula[f].opt_prefix
  end

  def install
    ENV.deparallelize

    arch_real="real"
    arch_complex="complex"

    # Environment variables CC, CXX, etc. will be ignored by PETSc.
    ENV.delete "CC"
    ENV.delete "CXX"
    ENV.delete "F77"
    ENV.delete "FC"
    args = %W[CC=#{ENV["MPICC"]}
              CXX=#{ENV["MPICXX"]}
              F77=#{ENV["MPIF77"]}
              FC=#{ENV["MPIFC"]}
              --with-shared-libraries=1
           ]
    args << ("--with-debugging=" + ((build.with? "debug") ? "1" : "0"))

    # We don't dowload anything, don't need to build against openssl
    args << "--with-ssl=0"

    if build.with? "superlu_dist"
      slud = Formula["superlu_dist"]
      args << "--with-superlu_dist-include=#{slud.opt_include}/superlu_dist"
      args << "--with-superlu_dist-lib=-L#{slud.opt_lib} -lsuperlu_dist"
    end

    if build.with? "superlu"
      slu = Formula["superlu"]
      args << "--with-superlu-include=#{slu.opt_include}/superlu"
      args << "--with-superlu-lib=-L#{slu.opt_lib} -lsuperlu"
    end

    args << "--with-fftw-dir=#{oprefix("fftw")}" if build.with? "fftw"
    args << "--with-netcdf-dir=#{oprefix("netcdf")}" if build.with? "netcdf"
    args << "--with-suitesparse-dir=#{oprefix("suite-sparse")}" if build.with? "suite-sparse"
    args << "--with-hdf5-dir=#{oprefix("hdf5")}" if build.with? "hdf5"
    args << "--with-metis-dir=#{oprefix("metis")}" if build.with? "metis"
    args << "--with-parmetis-dir=#{oprefix("parmetis")}" if build.with? "parmetis"
    args << "--with-scalapack-dir=#{oprefix("scalapack")}" if build.with? "scalapack"
    args << "--with-mumps-dir=#{oprefix("mumps")}" if build.with? "mumps"
    args << "--with-x=0" if build.without? "x11"

    # if build with openblas, need to provide lapack as well.
    if build.with? "openblas"
      exten = (OS.mac?) ? "dylib" : "so"
      args << ("--with-blas-lib=#{Formula["openblas"].opt_lib}/libopenblas.#{exten}")
      args << ("--with-lapack-lib=#{Formula["openblas"].opt_lib}/libopenblas.#{exten}")
    end

    # configure fails if those vars are set differently.
    ENV["PETSC_DIR"] = Dir.getwd

    # real-valued case:
    ENV["PETSC_ARCH"] = arch_real
    args_real = ["--prefix=#{prefix}/#{arch_real}",
                 "--with-scalar-type=real",
                ]
    args_real << "--with-hypre-dir=#{oprefix("hypre")}" if build.with? "hypre"
    args_real << "--with-sundials-dir=#{oprefix("sundials")}" if build.with? "sundials"
    args_real << "--with-hwloc-dir=#{oprefix("hwloc")}" if build.with? "hwloc"
    system "./configure", *(args + args_real)
    system "make", "all"
    if build.with? "check"
      log_name = "make-check-" + arch_real + ".log"
      system "make test 2>&1 | tee #{log_name}"
      ohai `grep "Completed test examples" "#{log_name}"`.chomp
      prefix.install "#{log_name}"
    end
    system "make", "install"

    # complex-valued case:
    ENV["PETSC_ARCH"] = arch_complex
    args_cmplx = ["--prefix=#{prefix}/#{arch_complex}",
                  "--with-scalar-type=complex",
                 ]
    system "./configure", *(args + args_cmplx)
    system "make", "all"
    if build.with? "check"
      log_name = "make-check-" + arch_complex + ".log"
      system "make test 2>&1 | tee #{log_name}"
      ohai `grep "Completed test examples" "#{log_name}"`.chomp
      prefix.install "#{log_name}"
    end
    system "make", "install"

    # Link only what we want.
    petsc_arch = ((build.with? "complex") ? arch_complex : arch_real)

    include.install_symlink Dir["#{prefix}/#{petsc_arch}/include/*h"],
                                "#{prefix}/#{petsc_arch}/include/finclude",
                                "#{prefix}/#{petsc_arch}/include/petsc-private"
    prefix.install_symlink "#{prefix}/#{petsc_arch}/conf"
    # symlink only files (don't symlink pkgconfig as it won't symlink to opt/lib)
    lib.install_symlink Dir["#{prefix}/#{petsc_arch}/lib/*.*"]
    pkgshare.install_symlink Dir["#{prefix}/#{petsc_arch}/share/*"]
  end

  def caveats; <<-EOS
    Set PETSC_DIR to #{prefix}/real or #{prefix}/complex.
    Fortran module files are in
      #{prefix}/real/include and #{prefix}/complex/include
    EOS
  end

  test do
    (testpath/"test.c").write <<-EOS
    static char help[] = "Solve a tridiagonal linear system with KSP.\\n";
    #include <petscksp.h>
    #undef __FUNCT__
    #define __FUNCT__ "main"
    int main(int argc,char **args) {
      Vec            x, b, u;
      Mat            A;
      KSP            ksp;
      PC             pc;
      PetscReal      norm, tol=1.e-14;
      PetscErrorCode ierr;
      PetscInt i, n=10, col[3], its;
      PetscMPIInt size;
      PetscScalar neg_one=-1.0, one=1.0, value[3];
      PetscInitialize(&argc, &args, (char*)0, help);
      ierr = MPI_Comm_size(PETSC_COMM_WORLD, &size); CHKERRQ(ierr);
      if (size != 1) SETERRQ(PETSC_COMM_WORLD, 1, "This is a uniprocessor example only!\\n");

      /* Create vectors */
      ierr = VecCreate(PETSC_COMM_WORLD, &x); CHKERRQ(ierr);
      ierr = PetscObjectSetName((PetscObject) x, "Solution"); CHKERRQ(ierr);
      ierr = VecSetSizes(x, PETSC_DECIDE, n); CHKERRQ(ierr);
      ierr = VecSetFromOptions(x); CHKERRQ(ierr);
      ierr = VecDuplicate(x, &b); CHKERRQ(ierr);
      ierr = VecDuplicate(x, &u); CHKERRQ(ierr);

      /* Create matrix */
      ierr = MatCreate(PETSC_COMM_WORLD, &A); CHKERRQ(ierr);
      ierr = MatSetSizes(A, PETSC_DECIDE, PETSC_DECIDE, n, n); CHKERRQ(ierr);
      ierr = MatSetFromOptions(A); CHKERRQ(ierr);
      ierr = MatSetUp(A); CHKERRQ(ierr);

      /* Setup linear system */
      value[0] = -1.0; value[1] = 2.0; value[2] = -1.0;
      for (i = 1; i < n-1; i++) {
        col[0] = i-1; col[1] = i; col[2] = i+1;
        ierr = MatSetValues(A, 1, &i, 3, col, value, INSERT_VALUES); CHKERRQ(ierr);
      }
      i = n-1; col[0] = n-2; col[1] = n-1;
      ierr = MatSetValues(A, 1, &i, 2, col, value, INSERT_VALUES); CHKERRQ(ierr);
      i = 0; col[0] = 0; col[1] = 1; value[0] = 2.0; value[1] = -1.0;
      ierr = MatSetValues(A, 1, &i, 2, col, value, INSERT_VALUES); CHKERRQ(ierr);
      ierr = MatAssemblyBegin(A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
      ierr = MatAssemblyEnd(A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);

      ierr = VecSet(u, one); CHKERRQ(ierr);
      ierr = MatMult(A, u, b); CHKERRQ(ierr);

      /* Create linear solver */
      ierr = KSPCreate(PETSC_COMM_WORLD, &ksp); CHKERRQ(ierr);
      ierr = KSPSetOperators(ksp, A, A); CHKERRQ(ierr);
      ierr = KSPGetPC(ksp, &pc); CHKERRQ(ierr);
      ierr = PCSetType(pc, PCJACOBI); CHKERRQ(ierr);
      ierr = KSPSetTolerances(ksp, 1.e-8, PETSC_DEFAULT, PETSC_DEFAULT, PETSC_DEFAULT);CHKERRQ(ierr);

      /* Solve */
      ierr = KSPSolve(ksp, b, x); CHKERRQ(ierr);
      ierr = KSPView(ksp, PETSC_VIEWER_STDOUT_WORLD); CHKERRQ(ierr);

      /* Check solution */
      ierr = VecAXPY(x, neg_one, u); CHKERRQ(ierr);
      ierr = VecNorm(x, NORM_2, &norm); CHKERRQ(ierr);
      ierr = KSPGetIterationNumber(ksp, &its); CHKERRQ(ierr);
      ierr = PetscPrintf(PETSC_COMM_WORLD, "Norm of error %g\\nIterations %D\\n",
                         (double)norm, its); CHKERRQ(ierr);

      /* Free work space */
      ierr = VecDestroy(&x); CHKERRQ(ierr); ierr = VecDestroy(&u); CHKERRQ(ierr);
      ierr = VecDestroy(&b); CHKERRQ(ierr); ierr = MatDestroy(&A); CHKERRQ(ierr);
      ierr = KSPDestroy(&ksp); CHKERRQ(ierr);

      ierr = PetscFinalize();
      return 0;
    }
    EOS
    system "mpicc", "test.c", "-I#{include}", "-L#{lib}", "-lpetsc", "-o", "test"
    assert (`./test | grep 'Norm of error' | awk '{print $NF}'`.to_f < 1.0e-8)
  end
end
