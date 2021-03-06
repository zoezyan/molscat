      SUBROUTINE OUTMAT(TMAT, EIGOLD, HP, DRNOW, RNOW,
     1                  N, NMAX)
C  This subroutine is part of the MOLSCAT, BOUND and FIELD suite of programs
C
C  AUTHOR:  MILLARD ALEXANDER
C  CURRENT REVISION DATE: 14-FEB-91
C
C  UPDATED TO USE ESHIFT, IREAD, IWRITE FROM COMMON BLOCK: CRLS 27-03-19
C
C  SUBROUTINE TO EITHER WRITE OR READ TRANSFORMATION MATRIX AND
C  RELEVANT INFORMATION FROM FILE ISCRU
C  ---------------------------------------------------------------------
C  VARIABLES IN CALL LIST:
C    TMAT:     N X N MATRIX TO CONTAIN TRANSFORMATION MATRIX
C    EIGOLD:   ARRAY OF DIMENSION N WHICH CONTAINS LOCAL WAVEVECTORS
C    HP:       ARRAY OF DIMENSION N WHICH CONTAINS DERIVATIVES OF
C              HAMILTONIAN MATRIX.  THIS IS JUST THE NEGATIVE OF THE
C              DERIVATIVES OF THE WAVEVECTOR MATRIX
C    DRNOW:    WIDTH OF CURRENT INTERVAL
C    RNOW:     MIDPOINT OF CURRENT INTERVAL
C    N:        NUMBER OF CHANNELS
C    NMAX:     MAXIMUM ROW DIMENSION OF MATRIX TMAT
C  ---------------------------------------------------------------------
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION EIGOLD(1), HP(1), TMAT(1)
C
C  COMMON BLOCK FOR CONTROL OF USE OF PROPAGATION SCRATCH FILE
      LOGICAL IREAD,IWRITE
      COMMON /PRPSCR/ ESHIFT,ISCRU,IREAD,IWRITE
C    ESHIFT:   AMOUNT LOCAL WAVEVECTORS WILL BE SHIFTED IN SECOND ENERGY
C              CALCULATION:  2         2
C                           K (NEW) = K (OLD) + ESHIFT
C
C  IF FIRST      ENERGY CALCULATION, IWRITE = T: ISCRU WILL BE WRITTEN TO
C  IF SUBSEQUENT ENERGY CALCULATION, IREAD  = T: ISCRU WILL BE READ FROM
C
C  READ/WRITE RNOW, DRNOW, DIAGONAL ELEMENTS OF TRANSFORMED DW/DR MATRIX
C  AND DIAGONAL ELEMENTS OF TRANSFORMED W MATRIX
C
      NSQ = NMAX * NMAX
      IF (IREAD) THEN
        READ(ISCRU) RNOW, DRNOW, (HP(I) , I = 1, N),
     1              (EIGOLD(I) , I = 1, N), (TMAT(I), I=1, NSQ)
        DO  30   I = 1, N
          EIGOLD(I) = EIGOLD(I) + ESHIFT
30      CONTINUE
      ELSEIF (IWRITE) THEN
        WRITE(ISCRU) RNOW, DRNOW, (HP(I) , I = 1, N),
     1               (EIGOLD(I) , I = 1, N), (TMAT(I), I=1, NSQ)
      ENDIF
      RETURN
      END
