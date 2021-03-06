      SUBROUTINE POTIN9(ITYPP, LAM, MXLAM, NPTS, NDIM, XPT, XWT,
     1                  MXPT, IVMIN, IVMAX, L1MAX, L2MAX,
     2                  MXLMB, X, MX, IXFAC)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION LAM(1,MXLAM), NPTS(NDIM), XPT(MXPT,NDIM),
     1          XWT(MXPT,NDIM), X(MX)
      NAMELIST /POTL9/ ITYPE
C
C  ROUTINE TO INITIALIZE POTENTIAL FOR ITYPE=9.
C  NOTE THAT THE ITYPE VARIABLE PASSED TO POTIN9 IS LOCAL TO
C  POTENL, AND MAY BE CHANGED TO CONTROL POTENL
C  WITHOUT AFFECTING HOW THE REST OF MOLSCAT/BOUND BEHAVES.
C
C  THE MINIMUM THAT POTIN9 MUST DO IS TO SET ITYPE SO THAT
C  POTENL USES ITS NORMAL LOGIC FOR SOME OTHER VALUE OF ITYPE.
C  HOWEVER, IN SOME CASES IT WILL BE NECESSARY TO DO MUCH MORE,
C  FOR EXAMPLE TO SET UP SPECIAL SETS OF QUADRATURE POINTS AND
C  WEIGHTS.
C
      ITYPE=1

      READ(5,POTL9)

      ITYPP=ITYPE
      RETURN
      END
