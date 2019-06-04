      SUBROUTINE BAS9IN(PRTP,IBOUND,IPRINT)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE efvs
      USE potential
      USE basis_data
      USE physical_constants
C
C  BASE9 ROUTINE BY JM Hutson, DECEMBER 2006
C  TWO MULTIPLET S ATOMS WITH NUCLEAR SPIN
C  WORKS FOR EQUIVALENT OR NONEQUIVALENT ATOMS
C  AND FOR BOTH BOSONS AND FERMIONS
C
C  DEC 06 VERSION DEVELOPED FOR PAIRS OF DOUBLET S ATOMS
C  JAN 10 VERSION USING JTOT INSTEAD OF IBLOCK FOR MTOT LOOP
C  JUL 12 BUG FIXED IN SYMMETRY FOR IDENTICAL PARTICLES WITH ODD L
C  DEC 13 ALTERED TO USE EXTRA OPERATORS
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE
      CHARACTER(8) PRTP(4),QNAME(10)
      LOGICAL LEVIN,EIN,LCOUNT,IDENTN
      INTEGER M,MP,JJ
      DOUBLE PRECISION E1,E2,EPA,EPB,EMA,EMB,E,BFIELD,EREF
      DIMENSION EPA(30),EMA(30),EPB(30),EMB(30)
      DIMENSION E(900)
      DIMENSION LREQ(10),MFREQ(10)
      DIMENSION JSTATE(1),VL(1),IV(1),JSINDX(1),L(1),CENT(1),LAM(1)
      DIMENSION DGVL(*)
      DIMENSION MONQN(NQN1)
      DIMENSION NPTS(NDIM),XPT(MXPT,NDIM),XWT(MXPT,NDIM),
     1          X(MX)
C
C     include common block for data received via pvm
C
      logical :: inolls=.false.
cINOLLS include 'all/pvmdat1.f'
cINOLLS include 'all/pvmdat.f'
C
C  ALTERED TO USE ARRAY SIZES FROM MODULE sizes ON 23-06-17 BY CRLS

      NAMELIST /BASIS9/ ISA,ISB,GSA,GSB,INUCA,INUCB,
     1                  HFSPLA,HFSPLB,GA,GB,LMAX,NREQ,LREQ,MFREQ,ISPSP,
     2                  NEXTRA
C
C  VALUES AMENDED ON 30-6-11 TO CURRENT NIST DATA
C  ELECTRON G-FACTOR: NOTE +VE SIGN SO H_Z CONTAINS +GS BFIELD M_S
C     PARAMETER (GS=2.00231930436153D0)
C  BOHR MAGNETON IN AU/GAUSS
C     PARAMETER (BOHRMG=1.51982984600456D-16*13.99624555D5)
C  FINE-STRUCTURE CONSTANT
C     PARAMETER (ALPINV=1D0/7.2973525698D-3)
C  CONVERSION FACTOR FROM CM-1 TO GHZ
C     DATA GHZCM/29.9792458D0/
C  CONVERSION FACTOR FROM HARTREE TO CM-1
C     DATA AUCM/219474.631371D0/
C     BM=BOHRMG*AUCM
C
C  20-09-2016: UPDATED TO USE MODULE (physical_constants) THAT CONTAINS
C              CONSISTENT AND UP-TO-DATE VALUES
      GS=-g_e
      ALPINV=inverse_fine_structure_constant
      GHZCM=speed_of_light_in_cm/Giga_in_SI
      AUCM=hartree_in_inv_cm
      BM=bohr_magneton
C
C  BAS9IN IS CALLED ONCE FOR EACH SCATTERING SYSTEM (USUALLY ONCE
C  PER RUN) AND CAN READ IN ANY BASIS SET INFORMATION NOT CONTAINED
C  IN NAMELIST BLOCK &BASIS. IT MUST ALSO HANDLE THE FOLLOWING
C  VARIABLES AND ARRAYS:
C
C  PRTP   SHOULD BE RETURNED AS A CHARACTER STRING DESCRIBING THE
C         INTERACTION TYPE
C  IDENT  CAN BE SET>0 IF AN INTERACTION OF IDENTICAL PARTICLES IS
C         BEING CONSIDERED AND SYMMETRISATION IS REQUIRED.
C         HOWEVER, THIS WOULD REQUIRE EXTRA CODING IN IDPART.
C  IBOUND CAN BE SET>0 IF THE CENTRIFUGAL POTENTIAL IS NOT OF THE
C         FORM L(L+1)/R**2; IF IBOUND>0, THE CENT ARRAY MUST BE
C         RETURNED FROM ENTRY CPL9
C
      PRTP(1)='ATOM - A'
      PRTP(2)='TOM WITH'
      PRTP(3)=' NUC SP '
      PRTP(4)='+ MAG FL'
C
C  SET UP ELEMENTS OF efvs MODULE
      NEFV=1
      EFVNAM(1)='MAGNETIC Z FIELD'
      EFVUNT(1)='GAUSS'
      MAPEFV=2 ! MLEO'S, ADDED ON 19/09/07
C  THIS MUST BE THE TOTAL NUMBER OF CONSTANT TERMS PROGRAMMED IN CPL9
      NCONST=2
C
      VCONST(1)=1.D0/GHZCM
      IBOUND=0
      LMAX=0
      NREQ=0
      ISPSP=0
      ISA=1
      GSA=-1.D0
      INUCA=-1
      GA=0.D0
      HFSPLA=0.D0
      ISB=1
      GSB=-1.D0
      INUCB=-1
      GB=0.D0
      HFSPLB=0.D0
      IDENTN=.FALSE.
      JHALF=0
C
C  THIS IS THE NUMBER OF EXTRA OPERATORS INCLUDED IN THE CURRENT
C  CALCULATION
      NEXTRA=0
C  THERE ARE 2 EXTRA OPERATORS CODED UP IN CPL9
C  THE FIRST HAS ONE PART - MFA^2+MFB^2
      NEXTMS(1)=1
C  THE SECOND HAS ONE PART - MFA+MFB
      NEXTMS(2)=1
C

      if (.not.inolls) READ(5,BASIS9)
C
cINOLLS include 'all/rbasis9.alk-2010.f'

      IF (NEXTRA.GT.2) THEN
        WRITE(6,*) ' *** WARNING: THERE ARE ONLY 2 EXTRA '//
     1             'OPERATORS CODED IN CPL9'
        NEXTRA=2
      ENDIF

      NSPINS=1+MIN(ISA,ISB)
C
      IFMAX=INUCA+ISA
      IFMIN=ABS(INUCA-ISA)
      NSFAC=(IFMAX*(IFMAX+2)-IFMIN*(IFMIN+2))/4
      ANSA=0.D0
      IF (NSFAC.NE.0) ANSA=2.D0*HFSPLA/DBLE(NSFAC)
      IF (GSA.LT.0.D0) GSA=GS
      IF (GSB.LT.0.D0) GSB=GS
C
      IF (IDENTN .OR. INUCB.LT.0) THEN
        ISB=ISA
        GSB=GSA
        INUCB=INUCA
        GB=GA
        HFSPLB=HFSPLA
        IDENTN=.TRUE.
      ENDIF
C
      IFMAX=INUCB+ISB
      IFMIN=ABS(INUCB-ISB)
      NSFAC=(IFMAX*(IFMAX+2)-IFMIN*(IFMIN+2))/4
      ANSB=0.D0
      IF (NSFAC.NE.0) ANSB=2.D0*HFSPLB/DBLE(NSFAC)
C
      IF (IPRINT.LE.0) RETURN

      WRITE(6,'(2X,4A8/)') PRTP
      IF (IDENTN) THEN
        WRITE(6,601) 'S ',ISA,GSA,INUCA,GA,HFSPLA,ANSA
      ELSE
        WRITE(6,601) ' A',ISA,GSA,INUCA,GA,HFSPLA,ANSA
        WRITE(6,601) ' B',ISB,GSB,INUCB,GB,HFSPLB,ANSB
  601   FORMAT(/'  ATOM',A2,' WITH S =',I2,'/2,  MU_S   =',F12.6,
     1         ' MU_B',/,14X,'I =',I2,'/2,  MU_NUC =',F12.6,
     2         ' MU_B',/,9X,'HYPERFINE SPLITTING =',F12.6,
     3         ', COUPLING CONST =',F12.6,' GHZ',/)
      ENDIF
C
      WRITE(6,'(2X,A,I4)') 'L UP TO ',LMAX
      IF (NREQ.GT.0) THEN
        WRITE(6,*) ' ONLY THE FOLLOWING L,MF PAIRS ARE INCLUDED',
     1             ' (NOTE MFREQ >= 999 INCLUDES ALL MF)'
        DO 100 IREQ=1,NREQ
        WRITE(6,'(2X,A,I4,A,I5)') ' L = ',LREQ(IREQ),
     1                            ', MF = ',MFREQ(IREQ),'/2'
  100   CONTINUE
      ENDIF
      IF (ISPSP.GE.0) THEN
        WRITE(6,*) ' SPIN-SPIN TERM INCLUDED'
      ELSE
        WRITE(6,*) ' SPIN-SPIN TERM OMITTED'
      ENDIF
C
      RETURN
C========================================================== END OF BAS9IN
C
      ENTRY SET9(LEVIN,EIN,NSTATE,JSTATE,NQN,QNAME,MXPAR,NLABV,IPRINT)
C
C  SET9 IS CALLED ONCE FOR EACH SCATTERING SYSTEM. IT SETS UP:
C  MXPAR, THE NUMBER OF DIFFERENT SYMMETRY BLOCKS
C  NLABV, THE NUMBER OF INDICES NEEDED TO DESCRIBE EACH TERM IN THE
C         POTENTIAL EXPANSION
C  JSTATE AND NSTATE;
C
      MXPAR=2
      NLABV=1
      NQN=5
C  QNAME(1) TO (NQN-1) ARE NAMES OF QUANTUM NUMBERS
      QNAME(1)='  2*MSA '
      QNAME(2)='  2*MIA '
      QNAME(3)='  2*MSB '
      QNAME(4)='  2*MIB '
C
C  LOOP THROUGH THE QUANTUM NUMBERS TWICE, COUNTING THE NUMBER OF STATES
C  THE FIRST TIME, AND ASSIGNING VALUES TO JSTATE THE SECOND TIME
      DO ILOOP=1,2
        ISTATE=0
        DO 210 MSA=-ISA,ISA,2
        DO 210 MIA=-INUCA,INUCA,2
          MSBMAX=ISB
          IF (IDENTN) MSBMAX=MSA
        DO 210 MSB=-ISB,MSBMAX,2
          MIBMAX=INUCB
          IF (IDENTN .AND. MSA.EQ.MSB) MIBMAX=MIA
        DO 210 MIB=-INUCB,MIBMAX,2
          ISTATE=ISTATE+1
          IF (ILOOP.EQ.2) THEN
            JSTATE(ISTATE         )=MSA
            JSTATE(ISTATE+NSTATE  )=MIA
            JSTATE(ISTATE+NSTATE*2)=MSB
            JSTATE(ISTATE+NSTATE*3)=MIB
          ENDIF
  210   CONTINUE
        IF (ILOOP.EQ.1) NSTATE=ISTATE
      ENDDO
C
      RETURN
C ========================================================== END OF SET9
C
      ENTRY BASE9(LCOUNT,N,JTOT,IBLOCK,JSTATE,NSTATE,NQN,JSINDX,L,
     1            IPRINT)
C
C  BASE9 IS CALLED EITHER TO COUNT THE ACTUAL NUMBER OF CHANNEL BASIS
C  FUNCTIONS OR ACTUALLY TO SET THEM UP (IN THE JSINDX AND L ARRAYS).
C  IT IS CALLED FOR EACH TOTAL J (JTOT) AND SYMMETRY BLOCK (IBLOCK).
C  IF LCOUNT IS .TRUE. ON ENTRY, JUST COUNT THE BASIS FUNCTIONS.
C  OTHERWISE, SET UP JSINDX (POINTER TO JSTATE) AND
C  L (ORBITAL ANGULAR MOMENTUM) FOR EACH CHANNEL.
C  THIS MUST TAKE INTO ACCOUNT JTOT AND IBLOCK.
C
C  NOTE THAT BOTH MTOT AND ML ARE DOUBLED, LIKE MF ETC
C
      MTOT=JTOT
C
      IF (LCOUNT) THEN
        IF (IPRINT.GE.1) WRITE(6,605) IBLOCK,(-1)**IBLOCK,MTOT
  605   FORMAT('  SYMMETRY BLOCK = ',I3,' SELECTS PARITY',I3,/
     1         '  MTOT =',I3,'/2')
        IF (IDENTN) THEN
          IFA=INUCA+ISA
          IF (2*(IFA/2).EQ.IFA) THEN
            IBOSFR=0
            IF (IPRINT.GE.1) WRITE(6,610) 'BOSONS'
  610         FORMAT(2X,'BASIS SET GENERATED FOR TWO IDENTICAL ',A)
          ELSE
            IBOSFR=1
            IF (IPRINT.GE.1) WRITE(6,610) 'FERMIONS'
          ENDIF
        ENDIF
      ENDIF
C
      N=0
      DO 320 I=1,NSTATE
        MSA=JSTATE(I)
        MIA=JSTATE(NSTATE+I)
        MSB=JSTATE(2*NSTATE+I)
        MIB=JSTATE(3*NSTATE+I)
        MF=MSA+MSB+MIA+MIB
        ML=MTOT-MF
        LSTART=4-2*IBLOCK
C
C  SKIP ALL L FOR THIS MSA,MSB,MIA,MIB AND PARITY
C  IF FORBIDDEN BY IDENTICAL PARTICLE SYMMETRY
C
        IF (IDENTN .AND. MSA.EQ.MSB .AND. MIA.EQ.MIB .AND.
     1      IBOSFR+IBLOCK.NE.2) LSTART=2*LMAX+1
        DO 310 LL=LSTART,2*LMAX,4
          IF (ABS(ML).GT.LL) GOTO 310
C
C  IF AN EXPLICIT LIST OF L,MF PAIRS IS SUPPLIED, IS THIS IN IT?
C  NOTE THAT SETTING MFREQ >= 999 INCLUDES ALL MF VALUES FOR THAT L
C
          IF (NREQ.EQ.0) GOTO 300

          DO 290 IREQ=1,NREQ
            IF (LREQ(IREQ).GE.0 .AND. LL/2.NE.LREQ(IREQ)) GOTO 290
            IF (ABS(MFREQ(IREQ)).LT.999 .AND. MF.NE.MFREQ(IREQ))
     1        GOTO 290
            GOTO 300

  290     CONTINUE
C
C  THIS L,MF NOT WANTED
C
          GOTO 310
C
C  THIS L,MF IS WANTED
C
  300     N=N+1
          IF (LCOUNT) GOTO 310
          JSINDX(N)=I
          L(N)=LL/2
  310   CONTINUE
  320 CONTINUE
C
      IF (LCOUNT) RETURN
C
C  SORT CHANNELS BY L
C
      DO 350 I=1,N
        DO 340 JJ=I+1,N
          IF (L(JJ).LT.L(I)) THEN
            LJ=L(I)
            L(I)=L(JJ)
            L(JJ)=LJ
            LJ=JSINDX(I)
            JSINDX(I)=JSINDX(JJ)
            JSINDX(JJ)=LJ
          ENDIF
  340   CONTINUE
  350 CONTINUE

      RETURN
C ========================================================= END OF BASE9
C
      ENTRY CPL9(N,IBLOCK,NPOTL,LAM,MXLAM,NSTATE,JSTATE,JSINDX,L,JTOT,
     1           VL,IV,CENT,DGVL,IBOUND,IEXCH,IPRINT)
C
C  CPL9 IS CALLED AFTER BASE9 FOR EACH JTOT AND IBLOCK, TO SET UP THE
C  POTENTIAL COUPLING COEFFICIENTS VL.
C  IF IBOUND>0, IT ALSO SETS UP THE CENTRIFUGAL COEFFICIENTS CENT.
C  INDICES SPECIFYING THE MXLAM DIFFERENT POTENTIAL SYMMETRIES ARE IN
C  THE FIRST XX*MXLAM ELEMENTS OF LAM; THE STRUCTURE OF THE LAM ARRAY
C  (AND THE VALUE OF XX) IS CHOSEN BY THE PROGRAMMER, AND MUST
C  CORRESPOND WITH THAT USED IN SUBROUTINE POTENL.
C  NPOTL IS THE NUMBER OF DIFFERENT POTENTIAL TERMS WHICH CONTRIBUTE TO
C  EACH MATRIX ELEMENT (SEE SUBROUTINE WAVVEC). IT SOMETIMES SAVES
C  A SIGNIFICANT AMOUNT OF SPACE IF IT CAN BE LESS THAN MXLAM.
C
C  IN GENERAL THERE ARE 1+MIN(ISA,ISB) DIFFERENT TOTAL SPINS
C
C  FOR DOUBLET S + DOUBLET S
C  LL = 1: SINGLET POTENTIAL
C  LL = 2: TRIPLET POTENTIAL
C  LL = 3: SPIN-SPIN TERM (INCLUDING 2ND-ORDER SPIN-ORBIT)
C  LL = 4: S.I HYPERFINE TERM
C  LL = 5: MAGNETIC FIELD TERM
C
      SPMIN=0.5D0*ABS(DBLE(ISA-ISB))
C  NOTE THAT NSPINS+ISPSP MIGHT NOT MATCH MXLAM IF (FOR EXAMPLE) SPINS ARE
C  SET TO ZERO.  CARE MUST BE TAKEN TO ENSURE THAT THE NCONST TERMS
C  ALWAYS COME AFTER MXLAM POTENTIAL TERMS, NOT NSPINS+ISPSP TERMS,
C  BECAUSE WAVMAT ASSUMES THAT IS WHERE THEY ARE.
      IF (IDENTN) XBOSFR=(-1.D0)**(IBOSFR+L(1))
C
      DO 550 LL=1,NVLBLK
        NNZ=0
        I=LL
        DO 540 ICOL=1,N
C  PICK OUT COLUMN QUANTUM NUMBERS
          MSAC=JSTATE(JSINDX(ICOL))
          MIAC=JSTATE(JSINDX(ICOL)+NSTATE)
          MSBC=JSTATE(JSINDX(ICOL)+NSTATE*2)
          MIBC=JSTATE(JSINDX(ICOL)+NSTATE*3)
          LC=L(ICOL)
        DO 540 IROW=1,ICOL
C  PICK OUT ROW QUANTUM NUMBERS
          MSAR=JSTATE(JSINDX(IROW))
          MIAR=JSTATE(JSINDX(IROW)+NSTATE)
          MSBR=JSTATE(JSINDX(IROW)+NSTATE*2)
          MIBR=JSTATE(JSINDX(IROW)+NSTATE*3)
          MLR=MTOT-MSAR-MSBR-MIAR-MIBR
          MLC=MTOT-MSAC-MSBC-MIAC-MIBC
          LR=L(IROW)
          VL(I)=0.D0
          PREFAC=1D0
          IF (IDENTN .AND. MSAR.EQ.MSBR .AND. MIAR.EQ.MIBR)
     1      PREFAC=PREFAC/SQRT(2D0)
          IF (IDENTN .AND. MSAC.EQ.MSBC .AND. MIAC.EQ.MIBC)
     1      PREFAC=PREFAC/SQRT(2D0)
          IF (LL.LE.NSPINS .AND. LR.EQ.LC .AND. MLR.EQ.MLC) THEN
            XS=SPMIN+DBLE(LL-1)
            FAC=PREFAC*CENTPT(XS,ISA,ISB,MSAR,MSBR,MSAC,MSBC)
            IF (MIAR.EQ.MIAC .AND. MIBR.EQ.MIBC)
     1        VL(I)=FAC
C  FOR IDENTICAL PARTICLES, SECOND TERM IF EXCHANGED NUCLEAR SPIN PROJECTION
C  VALUES FOR BRA IDENTICAL TO (UNEXCHANGED) KET VALUES (OF SAME
C  MAGNITUDE WITH A POSSIBLE SIGN CHANGE).
            IF (IDENTN .AND. MIAR.EQ.MIBC .AND. MIBR.EQ.MIAC) THEN
              IF (MOD(ISA+NINT(XS)+IBOSFR+LR,2).NE.0) FAC=-FAC
              VL(I)=VL(I)+FAC
            ENDIF
          ELSEIF (LL.EQ.NSPINS+1 .AND. ISPSP.GE.0) THEN
C  SPIN-SPIN TERM ======================================================
            FAC=PREFAC*SPINSP(ISA,ISB,MSAR,MSBR,LR,MLR,MSAC,MSBC,LC,MLC)
            IF (MIAR.EQ.MIAC .AND. MIBR.EQ.MIBC) VL(I)=VL(I)+FAC
C  FOR IDENTICAL PARTICLES, SECOND TERM IF EXCHANGED NUCLEAR SPIN PROJECTION
C  VALUES FOR BRA IDENTICAL TO (UNEXCHANGED) KET VALUES
            IF (IDENTN .AND. MIAR.EQ.MIBC .AND. MIBR.EQ.MIAC) THEN
              FAC2=PREFAC*
     1             SPINSP(ISA,ISB,MSBR,MSAR,LR,MLR,MSAC,MSBC,LC,MLC)
              IF (MOD(IBOSFR+LR,2).NE.0) FAC2=-FAC2
              VL(I)=VL(I)+FAC2
            ENDIF
            VL(I)=VL(I)*AUCM/ALPINV**2
          ELSEIF (LL.EQ.MXLAM+1 .AND. LR.EQ.LC .AND. MLR.EQ.MLC) THEN
C  HYPERFINE  ==========================================================
            FACA=ANSA*SDOTI2(ISA,MSAR,MSAC,INUCA,MIAR,MIAC)
            FACB=ANSB*SDOTI2(ISB,MSBR,MSBC,INUCB,MIBR,MIBC)
            IF (MSBR.EQ.MSBC .AND. MIBR.EQ.MIBC)
     1        VL(I)=PREFAC*FACA
            IF (MSAR.EQ.MSAC .AND. MIAR.EQ.MIAC)
     1        VL(I)=VL(I)+PREFAC*FACB
            IF (IDENTN) THEN
C  FOR IDENTICAL PARTICLES, ALSO A TERM IF 'B' VALUES FOR BRA EQUAL TO
C  'A' VALUES FOR KET (NOMINALLY FROM HYPERFINE OF A)
              IF (MSAR.EQ.MSBC .AND. MIAR.EQ.MIBC) THEN
                FAC2=PREFAC*ANSA*SDOTI2(ISA,MSBR,MSAC,INUCA,MIBR,MIAC)
                IF (MOD(IBOSFR+LR,2).NE.0) FAC2=-FAC2
                VL(I)=VL(I)+FAC2
              ENDIF
C  FOR IDENTICAL PARTICLES, ALSO A TERM IF 'A' VALUES FOR BRA EQUAL TO
C  'B' VALUES FOR KET (NOMINALLY FROM HYPERFINE OF B)
              IF (MSBR.EQ.MSAC .AND. MIBR.EQ.MIAC) THEN
                FAC2=PREFAC*ANSA*SDOTI2(ISA,MSAR,MSBC,INUCA,MIAR,MIBC)
                IF (MOD(IBOSFR+LR,2).NE.0) FAC2=-FAC2
                VL(I)=VL(I)+FAC2
              ENDIF
            ENDIF
          ELSEIF (LL.EQ.MXLAM+2 .AND. ICOL.EQ.IROW) THEN
C  MAGNETIC FIELD ALONG Z AXIS =========================================
C  THIS IS DIAGONAL SO THERE ARE NO EXCHANGE SYMMETRY COMPLICATIONS
            VL(I)=GSA*DBLE(MSAR)+GSB*DBLE(MSBR)
     1            +GA*DBLE(MIAR)+GB*DBLE(MIBR)
            VL(I)=VL(I)*BM*0.5D0
          ELSEIF (LL.EQ.MXLAM+NCONST+1 .AND. ICOL.EQ.IROW) THEN
C  OPERATOR FOR M_F_A^2 + M_F_B^2 (ALSO DIAGONAL) =====================
            VL(I)=DBLE((MSAR+MIAR)**2+(MSBR+MIBR)**2)
          ELSEIF (LL.EQ.MXLAM+NCONST+2 .AND. ICOL.EQ.IROW) THEN
C  OPERATOR FOR M_F_A + M_F_B (ALSO DIAGONAL) =========================
            VL(I)=DBLE(MSAR+MIAR+MSBR+MIBR)
          ENDIF
          IF (VL(I).NE.0.D0) NNZ=NNZ+1
  540     I=I+NVLBLK

        IF (NNZ.EQ.0) THEN
          WRITE(6,612) JTOT,LL
  612     FORMAT('  * * * NOTE.  FOR JTOT =',I4,',  ALL COUPLING',
     1           ' COEFFICIENTS ARE 0.0 FOR POTENTIAL SYMMETRY',I4)
        ENDIF
  550 CONTINUE

      RETURN
C ========================================================= END OF CPL9
C
      ENTRY THRSH9(JREF,MONQN,NQN1,EREF,IPRINT)
C
C  THIS CALCULATES THRESHOLDS FOR TWO ATOMS, BOTH WITH ELECTRONIC SPIN 1/2
C  USING BREIT-RABI RELATIONSHIP FOR EACH ATOM SEPARATELY AND THEN ADDING
C  THE RESULTS.  THE MONOMER QUANUM NUMBERS ARE SPECIFIED IN THE ARRAY
C  MONQN, AND ARE:
C     MONQN(1): 2*F(A) THAT DESIRED STATE CORRELATES WITH AT LOW FIELD
C     MONQN(2): 2*MF(A)
C
      BFIELD=EFV(1)
      IF (JREF.GT.0) THEN
        WRITE(6,*) ' *** ERROR - THRSH9 CALLED WITH POSITIVE IREF'
        STOP
      ENDIF
C
      IF (MONQN(1).EQ.-99999) THEN
        WRITE(6,*) ' *** ERROR - THRSH9 CALLED WITH MONQN UNSET'
        STOP
      ENDIF
C
      BOHRM=BM*GHZCM
C
C  BREIT-RABI FOR ATOM A
C
      M=MONQN(2)
      IF (ABS(MONQN(1)-INUCA).NE.1) THEN
        WRITE(6,*) ' *** THRSH9: INVALID MONQN(1) =',MONQN(1)
        STOP
      ELSEIF (ABS(M).GT.MONQN(1)) THEN
        WRITE(6,*) ' *** THRSH9: MA =',M,' > FA. STOPPING'
        STOP
      ELSEIF (MOD(M+MONQN(1),2).NE.0) THEN
        WRITE(6,*) ' *** THRSH9: INVALID MONQN(1),MONQN(2) PAIR =',
     1             MONQN(1),M
        STOP
      ENDIF

      E1=-HFSPLA/(2.D0*DBLE(INUCA+1)) + 0.5D0*GA*BOHRM*DBLE(M)*BFIELD
      BX=BOHRM*BFIELD*(GSA-GA)/HFSPLA
      E2=0.5D0*HFSPLA*SQRT(1.D0+DBLE(M+M)*BX/DBLE(INUCA+1)+BX*BX)
C
      IF (ABS(M).EQ.INUCA+1) THEN
        EA=DBLE(INUCA)*HFSPLA/(2D0*DBLE(INUCA+1))+SIGN(1.0D0,DBLE(M))
     1     *BOHRM*BFIELD*(GSA*ISA*0.5D0+GA*INUCA*0.5D0)
      ELSEIF (MONQN(1).EQ.INUCA+1) THEN
        EA=E1+E2
      ELSEIF (MONQN(1).EQ.INUCA-1) THEN
        EA=E1-E2
      ENDIF
C
C  BREIT-RABI FOR ATOM B
C
      M=MONQN(4)
      IF (ABS(MONQN(3)-INUCB).NE.1) THEN
        WRITE(6,*) ' *** THRSH9: INVALID MONQN(3) =',MONQN(3)
        STOP
      ELSEIF (ABS(M).GT.MONQN(3)) THEN
        WRITE(6,*) ' *** THRSH9: MB =',M,' > FB. STOPPING'
        STOP
      ELSEIF (MOD(M+MONQN(3),2).NE.0) THEN
        WRITE(6,*) ' *** THRSH9: INVALID MONQN(3),MONQN(4) PAIR =',
     1             MONQN(3),M
        STOP
      ENDIF

      E1=-HFSPLB/(2.D0*DBLE(INUCB+1)) + 0.5D0*GB*BOHRM*DBLE(M)*BFIELD
      BX=BOHRM*BFIELD*(GSB-GB)/HFSPLB
      E2=0.5D0*HFSPLB*SQRT(1.D0+DBLE(M+M)*BX/DBLE(INUCB+1)+BX*BX)
C
      IF (ABS(M).EQ.INUCB+1) THEN
        EB=DBLE(INUCB)*HFSPLB/(2D0*DBLE(INUCB+1))+SIGN(1.0D0,DBLE(M))
     1     *BOHRM*BFIELD*(GSB*ISB*0.5D0+GB*INUCB*0.5D0)
      ELSEIF (MONQN(3).EQ.INUCB+1) THEN
        EB=E1+E2
      ELSEIF (MONQN(3).EQ.INUCB-1) THEN
        EB=E1-E2
      ENDIF
C
      IF (IPRINT.GE.8) THEN
        WRITE(6,*)
        WRITE(6,667) 'A',MONQN(1),MONQN(2),EA
        WRITE(6,667) 'B',MONQN(3),MONQN(4),EB
  667   FORMAT('  ATOM ',A1,' WITH DOUBLED QUANTUM NOS',2I3,
     1     ' IS AT ENERGY',F12.7,' GHZ')
      ENDIF
      EAB=EA+EB
      EREF=EAB/GHZCM
c     IF (IPRINT.GE.6) WRITE(6,668) EAB,EREF
  668 FORMAT('  THRESHOLD USED IS AT ',F12.7,' GHZ =',F19.12,' CM-1')

      RETURN
C ======================================================== END OF THRSH9
      ENTRY POTIN9(ITYPE,LAM,MXLAM,NPTS,NDIM,XPT,XWT,
     1             MXPT,IVMIN,IVMAX,L1MAX,L2MAX,
     2             MXLMB,X,MX,IXFAC)
C
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
      ITYPE=1

      RETURN
      END
C ======================================================== END OF POTIN9
      FUNCTION SDOTI2(IS,MS1,MS2,II,MI1,MI2)
C
C  FUNCTION FOR A MATRIX ELEMENT OF A DOT PRODUCT OF TWO ANGULAR
C  MOMENTA IN A DECOUPLED BASIS SET.
C  ALL INPUT INTEGERS ARE TWICE THE CORRESPONDING QUANTUM NUMBERS
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
      SDOTI2=0.D0
      IF (MS1+MI1.EQ.MS2+MI2) THEN
        IF (MS1.EQ.MS2) THEN
          SDOTI2=0.25D0*DBLE(MI1*MS1)
        ELSEIF (ABS(MS1-MS2).EQ.2) THEN
          SDOTI2=0.125D0*SQRT(DBLE(II*(II+2)-MI1*MI2))
     1                  *SQRT(DBLE(IS*(IS+2)-MS1*MS2))
        ENDIF
      ENDIF
      RETURN
      END
C ======================================================= END OF SDOTI2
      FUNCTION CENTPT(XS,ISA,ISB,MSAR,MSBR,MSAC,MSBC)
C
C  FUNCTION FOR A MATRIX ELEMENT OF A CENTRAL POTENTIAL TERM
C  ALL INPUT INTEGERS ARE TWICE THE CORRESPONDING QUANTUM NUMBERS
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
      XSA=0.5D0*DBLE(ISA)
      XSB=0.5D0*DBLE(ISB)
      XMSA=0.5D0*DBLE(MSAR)
      XMSB=0.5D0*DBLE(MSBR)
      FAC1=THRJ(XSA,XSB,XS,XMSA,XMSB,-XMSA-XMSB)
      XMSA=0.5D0*DBLE(MSAC)
      XMSB=0.5D0*DBLE(MSBC)
      FAC2=THRJ(XSA,XSB,XS,XMSA,XMSB,-XMSA-XMSB)
      FAC3=(XS+XS+1.D0)*PARSGN(ISA-ISB+(MSAR+MSBR+MSAC+MSBC)/2)
      CENTPT=FAC1*FAC2*FAC3
      RETURN
      END
C ====================================================== END OF CENTPT
      FUNCTION SPINSP(ISA,ISB,MSAR,MSBR,LR,MLR,MSAC,MSBC,LC,MLC)
C
C  FUNCTION FOR A MATRIX ELEMENT OF A SPIN-SPIN TERM
C  ALL INPUT INTEGERS EXCEPT LR AND LC
C  ARE TWICE THE CORRESPONDING QUANTUM NUMBERS
C  THIS IS BASED ON EQ 8.464 OF BROWN & CARRINGTON
C  IT CALCULATES THE MATRIX ELEMENT OF
C  SUM_Q ROOT(6) (-1)^Q T^2_Q(S1,S2) T^2_-Q(C)
C  WHICH WHEN MULTIPLIED BY -LAMBDA FROM EQN A2 OF HUTSON, TIESINGA AND
C  JULIENNE, PRA 78 052703 (2008) GIVES THE SPIN-SPIN DIPOLAR TERM
C
C  NOTE THAT THE SUM IN THAT EXPRESSION (A2) CORRESPONDS TO JUST ONE TERM.
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
      SPINSP=0.D0
      IF (MSAR+MSBR+MLR .NE. MSAC+MSBC+MLC) RETURN
      IF (ABS(LC-LR).GT.2 .OR. ABS(MLR-MLC).GT.4) RETURN
      IQA=(MSAR-MSAC)/2
      IQB=(MSBR-MSBC)/2
      IQ=IQA+IQB
      IF ((MLC-MLR)/2.NE.IQ) RETURN

      XSA=0.5D0*DBLE(ISA)
      XSB=0.5D0*DBLE(ISB)
      XMSAR=0.5D0*DBLE(MSAR)
      XMSBR=0.5D0*DBLE(MSBR)
      XMLR=0.5D0*DBLE(MLR)
      XMSAC=0.5D0*DBLE(MSAC)
      XMSBC=0.5D0*DBLE(MSBC)
      XMLC=0.5D0*DBLE(MLC)
      FAC1=THREEJ(LR,2,LC)
      FAC2=SQRT(XSA*(XSA+1.D0)*(XSA+XSA+1.D0)*
     1          XSB*(XSB+1.D0)*(XSB+XSB+1.D0)*DBLE((2*LR+1)*(2*LC+1)))
     2     *PARSGN((ISA+ISB-MSAR-MSBR-MLR)/2)
C
      FAC3=FAC1*FAC2*THRJ(DBLE(LR),2.D0,DBLE(LC),-XMLR,-DBLE(IQ),XMLC)
      FAC4=THRJ(1.D0,1.D0,2.D0,DBLE(IQA),DBLE(IQB),-DBLE(IQ))
      FAC5=THRJ(XSA,1.D0,XSA,-XMSAR,DBLE(IQA),XMSAC)
      FAC6=THRJ(XSB,1.D0,XSB,-XMSBR,DBLE(IQB),XMSBC)
      SPINSP=SPINSP+FAC3*FAC4*FAC5*FAC6
      SPINSP=SPINSP*SQRT(30.D0)
      RETURN
C
      END
C ====================================================== END OF SPINSP
