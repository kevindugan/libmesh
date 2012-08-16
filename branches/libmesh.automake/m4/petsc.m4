# -------------------------------------------------------------
# PETSc
# -------------------------------------------------------------
AC_DEFUN([CONFIGURE_PETSC], 
[
  AC_ARG_ENABLE(petsc,
                AC_HELP_STRING([--enable-petsc],
                               [build with PETSc iterative solver suppport]),
		[case "${enableval}" in
		  yes)  enablepetsc=yes ;;
		   no)  enablepetsc=no ;;
 		    *)  AC_MSG_ERROR(bad value ${enableval} for --enable-petsc) ;;
		 esac],
		 [enablepetsc=$enableoptional])


  AC_ARG_VAR([PETSC_DIR],  [path to PETSc installation])
  AC_ARG_VAR([PETSC_ARCH], [PETSc build architecture])

  
  if (test "$enablepetsc" !=  no) ; then
    # AC_REQUIRE:
    # If the M4 macro AC_PROG_F77 has not already been called, call
    # it (without any arguments). Make sure to quote AC_PROG_F77 with
    # square brackets. AC_PROG_F77 must have been defined using
    # AC_DEFUN or else contain a call to AC_PROVIDE to indicate
    # that it has been called.
    AC_REQUIRE([AC_PROG_F77])
  
    # If the user doesn't have any PETSC directory specified, let's check to
    # see if it's installed via Ubuntu module
    if (test "x$PETSC_DIR" = x); then
      AC_PATH_PROG(PETSCARCH, petscarch)
      if (test "x$PETSCARCH" != x); then
        export PETSC_DIR=/usr/lib/petsc
        export PETSC_ARCH=`$PETSCARCH`
	if (test -d $PETSC_DIR); then
  	  AC_MSG_RESULT([using system-provided PETSC_DIR $PETSC_DIR])
	  AC_MSG_RESULT([using system-provided PETSC_ARCH $PETSC_ARCH])
        fi
      fi	
    fi
  
    AC_CHECK_FILE($PETSC_DIR/include/petsc.h,
                  PETSC_H_PATH=$PETSC_DIR/include/petsc.h)
  
    # Grab PETSc version and substitute into Makefile.
    # If version 2.x, also check that PETSC_ARCH is set
    if (test -r $PETSC_DIR/include/petsc.h) ; then
      # Some tricks to discover the version of petsc.
      # You have to have grep and sed for this to work.
      petscmajor=`grep "define PETSC_VERSION_MAJOR" $PETSC_DIR/include/petscversion.h | sed -e "s/#define PETSC_VERSION_MAJOR[ ]*//g"`
      petscminor=`grep "define PETSC_VERSION_MINOR" $PETSC_DIR/include/petscversion.h | sed -e "s/#define PETSC_VERSION_MINOR[ ]*//g"`
      petscsubminor=`grep "define PETSC_VERSION_SUBMINOR" $PETSC_DIR/include/petscversion.h | sed -e "s/#define PETSC_VERSION_SUBMINOR[ ]*//g"`
      petscversion=$petscmajor.$petscminor.$petscsubminor
      petscmajorminor=$petscmajor.$petscminor.x
  
      AC_SUBST(petscversion)
      AC_SUBST(petscmajor)
      AC_SUBST(petscmajorminor)
  
      AC_DEFINE_UNQUOTED(DETECTED_PETSC_VERSION_MAJOR, [$petscmajor],
        [PETSc's major version number, as detected by LibMesh])
  	      
      AC_DEFINE_UNQUOTED(DETECTED_PETSC_VERSION_MINOR, [$petscminor],
        [PETSc's minor version number, as detected by LibMesh])
  	      
      AC_DEFINE_UNQUOTED(DETECTED_PETSC_VERSION_SUBMINOR, [$petscsubminor],
        [PETSc's subminor version number, as detected by LibMesh])
  
      if test $petscmajor = 2; then
        if test "x$PETSC_ARCH" = x ; then
          enablepetsc=no
          AC_MSG_RESULT([<<< PETSc 2.x detected and "\$PETSC_ARCH" not set.  PETSc disabled. >>>])
          # PETSc config failed.  We will try MPI at the end of this function.
          # ACX_MPI
        fi
      fi
  
    else # petsc.h was not readable
        enablepetsc=no
    fi
  
  
  
  
    # If we haven't been disabled yet, carry on!
    if (test $enablepetsc != no) ; then
  
        AC_SUBST(PETSC_ARCH) # Note: may be empty...
        AC_SUBST(PETSC_DIR)
        AC_DEFINE(HAVE_PETSC, 1,
    	      [Flag indicating whether or not PETSc is available])
  
        # Check for snoopable MPI
        if (test -r $PETSC_DIR/bmake/$PETSC_ARCH/petscconf) ; then           # 2.3.x	
        	 PETSC_MPI=`grep MPIEXEC $PETSC_DIR/bmake/$PETSC_ARCH/petscconf | grep -v mpiexec.uni` 
        elif (test -r $PETSC_DIR/$PETSC_ARCH/conf/petscvariables) ; then # 3.0.x
        	 PETSC_MPI=`grep MPIEXEC $PETSC_DIR/$PETSC_ARCH/conf/petscvariables | grep -v mpiexec.uni`
        elif (test -r $PETSC_DIR/conf/petscvariables) ; then # 3.0.x
        	 PETSC_MPI=`grep MPIEXEC $PETSC_DIR/conf/petscvariables | grep -v mpiexec.uni`
        fi		 
        if test "x$PETSC_MPI" != x ; then
          AC_DEFINE(HAVE_MPI, 1,
    	        [Flag indicating whether or not MPI is available])
          MPI_IMPL="petsc_snooped"      
  	AC_MSG_RESULT(<<< Configuring library with MPI from PETSC config >>>)
        else
  	AC_MSG_RESULT(<<< Warning: configuring in serial - no MPI in PETSC config >>>)
        fi
  
        # Print informative message about the version of PETSc we detected
        AC_MSG_RESULT([<<< Configuring library with PETSc version $petscversion support >>>])
  	
	
        # If we have a full petsc distro with a makefile query it to get the includes and link libs
	if (test -r $PETSC_DIR/makefile); then
          PETSCLINKLIBS=`make -s -C $PETSC_DIR getlinklibs`
          PETSCINCLUDEDIRS=`make -s -C $PETSC_DIR getincludedirs`

	# otherwise create a simple makefile to provide what we want, then query it.
  	elif (test -r $PETSC_DIR/conf/variables); then
 	  cat <<EOF >Makefile_config_petsc
include $PETSC_DIR/conf/variables
getincludedirs:
	echo -I\$(PETSC_DIR)/include -I\$(PETSC_DIR)/\$(PETSC_ARCH)/include \$(BLOCKSOLVE_INCLUDE) \$(HYPRE_INCLUDE) \$(PACKAGES_INCLUDES)

getlinklibs:
	echo \$(PETSC_SNES_LIB)\$(libmesh_LIBS)
EOF
	  # cat Makefile_config_petsc
          PETSCLINKLIBS=`make -s -f Makefile_config_petsc getlinklibs`
          PETSCINCLUDEDIRS=`make -s -f Makefile_config_petsc getincludedirs`
	  rm -f Makefile_config_petsc
	fi
        #echo ""
        #echo "PETSCLINKLIBS=$PETSCLINKLIBS"
        #echo "PETSCINCLUDEDIRS=$PETSCINCLUDEDIRS"
        #echo ""
  
        libmesh_optional_INCLUDES="$PETSCINCLUDEDIRS $libmesh_optional_INCLUDES"
        libmesh_optional_LIBS="$PETSCLINKLIBS $libmesh_optional_LIBS"
  
        AC_SUBST(PETSCLINKLIBS)
        AC_SUBST(PETSCINCLUDEDIRS)
  
        AC_SUBST(MPI_IMPL)
  
        # Check for Hypre
        if (test -r $PETSC_DIR/bmake/$PETSC_ARCH/petscconf) ; then           # 2.3.x	
        	 HYPRE_LIB=`grep "HYPRE_LIB" $PETSC_DIR/bmake/$PETSC_ARCH/petscconf` 
        elif (test -r $PETSC_DIR/$PETSC_ARCH/conf/petscvariables) ; then # 3.0.x
        	 HYPRE_LIB=`grep "HYPRE_LIB" $PETSC_DIR/$PETSC_ARCH/conf/petscvariables`
        elif (test -r $PETSC_DIR/conf/petscvariables) ; then # 3.0.x 
           HYPRE_LIB=`grep "HYPRE_LIB" $PETSC_DIR/conf/petscvariables`
        fi
  		 
        if test "x$HYPRE_LIB" != x ; then
          AC_DEFINE(HAVE_PETSC_HYPRE, 1, [Flag indicating whether or not PETSc was compiled with Hypre support])
  	AC_MSG_RESULT(<<< Configuring library with Hypre support >>>)
        fi
    
    else 
        # PETSc config failed.  Try MPI.
        AC_MSG_RESULT(<<< PETSc disabled.  Will try configuring MPI now... >>>)
        ACX_MPI
    fi


  else # --disable-petsc
    if (test "$enablempi" != no) ; then
      ACX_MPI
    fi	
  fi
    
  AC_SUBST(enablepetsc)
  AM_CONDITIONAL(LIBMESH_ENABLE_PETSC, test x$enablepetsc = xyes)		 
])



# ----------------------------------------------------------------------------
# check for the required PETSc library
# ----------------------------------------------------------------------------
AC_DEFUN([ACX_PETSc], [
AC_REQUIRE([ACX_LAPACK])
BLAS_LIBS="$BLAS_LIBS $FLIBS"
LAPACK_LIBS="$LAPACK_LIBS $BLAS_LIBS"
AC_PATH_XTRA
X_LIBS="$X_PRE_LIBS $X_LIBS -lX11 $X_EXTRA_LIBS"

# Set variables...
AC_ARG_WITH([PETSc],
	    AC_ARG_HELP([--with-PETSc=PATH],
                        [Prefix where PETSc is installed (PETSC_DIR)]),
	    [PETSc="$withval"],
	    [
              if test $PETSC_DIR; then
		PETSc="$PETSC_DIR"
		echo "note: assuming PETSc library is in $PETSc (/lib,/include) as specified by environment variable PETSC_DIR"
	      else
		PETSc="/usr/local"
		echo "note: assuming PETSc library is in /usr/local (/lib,/include)"
	      fi
            ])

AC_ARG_WITH([BOPT],
	    AC_ARG_HELP([--with-BOPT=VAL],[BOPT setting for PETSc (BOPT)]),
 	    [BOPT="$withval"],
	    [
              echo "note: assuming BOPT to O"
	      BOPT="O"
            ])

AC_ARG_WITH([PETSc_ARCH],
	    AC_ARG_HELP([--with-PETSc_ARCH=VAL],[PETSc hardware architecture (PETSC_ARCH)]),
	    [PETSc_ARCH="$withval"],
	    [
              if test $PETSC_ARCH; then
		PETSc_ARCH="$PETSC_ARCH"
		echo "note: assuming PETSc hardware architecture to be $PETSc_ARCH as specified by environment variable PETSC_ARCH"
	      else
		PETSc_ARCH=`uname -p`
		echo "note: assuming PETSc hardware architecture to be $PETSc_ARCH"
	      fi
            ])

PETSc_LIBS_PATH="$PETSc/lib/lib$BOPT/$PETSc_ARCH"
PETSc_INCLUDES_PATH="$PETSc/include"

# Check that the compiler uses the library we specified...
if test -e $PETSc_LIBS_PATH/libpetsc.a || test -e $PETSc_LIBS_PATH/libpetsc.so; then
	echo "note: using $PETSc_LIBS_PATH/libpetsc (.a/.so)"
else
	AC_MSG_ERROR( [Could not physically find PETSc library... exiting] )
fi 
if test -e $PETSc_INCLUDES_PATH/petsc.h; then
	echo "note: using $PETSc_INCLUDES_PATH/petsc.h"
else
	AC_MSG_ERROR( [Could not physically find PETSc header file... exiting] )
fi 

# Ensure the comiler finds the library...
tmpLIBS=$LIBS
tmpCPPFLAGS=$CPPFLAGS
AC_LANG_SAVE
AC_LANG_CPLUSPLUS
AC_CHECK_LIB(
	[dl],
	[dlopen],
	[DL_LIBS="-ldl"],
	[DL_LIBS=""; echo "libdl not found, assuming not needed for this architecture"] )
LIBS="-L$PETSc_LIBS_PATH $MPI_LIBS_PATHS $MPI_LIBS $LAPACK_LIBS $X_LIBS $LIBS -lm $DL_LIBS"
CPPFLAGS="$MPI_INCLUDES_PATHS -I$PETSc_INCLUDES_PATH -I$PETSc/bmake/$PETSc_ARCH $CPPFLAGS"
echo "cppflags=$CPPFLAGS"

AC_CHECK_LIB(
	[petsc],
	[PetscError],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc library... exiting] )] )
AC_CHECK_LIB(
	[petscvec],
	[ISCreateGeneral],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscvec library... exiting] )] )
AC_CHECK_LIB(
	[petscmat],
	[MAT_Copy],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscmat library... exiting] )] )
AC_CHECK_LIB(
	[petscdm],
	[DMInitializePackage],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscdm library... exiting] )] )
AC_CHECK_LIB(
	[petscsles],
	[SLESCreate],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscsles library... exiting] )] )
AC_CHECK_LIB(
	[petscsnes],
	[SNESCreate],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscsnes library... exiting] )] )
AC_CHECK_LIB(
	[petscts],
	[TSCreate],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscts library... exiting] )] )
AC_CHECK_LIB(
	[petscmesh],
	[MESH_CreateFullCSR],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscmesh library... exiting] )] )
AC_CHECK_LIB(
	[petscgrid],
	[GridCreate],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscgrid library... exiting] )] )
AC_CHECK_LIB(
	[petscgsolver],
	[GSolverInitializePackage],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petscgsolver library... exiting] )] )
AC_CHECK_LIB(
	[petscfortran],
	[meshcreate_],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc library... exiting] )] )
	AC_CHECK_LIB(
	[petsccontrib],
	[SDACreate1d],
	[],
	[AC_MSG_ERROR( [Could not link in the PETSc petsccontrib library... exiting] )] )
AC_CHECK_HEADER(
	[petsc.h],
	[AC_DEFINE( 
		[HAVE_PETSC],,
		[Define to 1 if you have the <petsc.h> header file.])],
	[AC_MSG_ERROR( [Could not compile in the PETSc headers... exiting] )] )
PETSc_LIBS="-lpetsc -lpetscvec -lpetscmat -lpetscdm -lpetscsles -lpetscsnes \
	-lpetscts -lpetscmesh -lpetscgrid -lpetscgsolver -lpetscfortran -lpetsccontrib \
	$PETSc_ARCH_LIBS"
PETSc_LIBS_PATHS="-L$PETSc_LIBS_PATH"
PETSc_INCLUDES_PATHS="-I$PETSc_INCLUDES_PATH -I$PETSc/bmake/$PETSc_ARCH"

# Save variables...
AC_LANG_RESTORE
LIBS=$tmpLIBS
CPPFLAGS=$tmpCPPFLAGS
AC_SUBST( PETSc )
AC_SUBST( PETSc_IMPL )
AC_SUBST( PETSc_LIBS )
AC_SUBST( PETSc_LIBS_PATH )
AC_SUBST( PETSc_LIBS_PATHS )
AC_SUBST( PETSc_INCLUDES_PATH )
AC_SUBST( PETSc_INCLUDES_PATHS )
])# ACX_PETSc ------------------------------------------------------------