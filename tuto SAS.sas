/* clear sas output*/
DM 'odsresults; clear';


/*****************************************************/
/* Definition de librairies
/*   ces repertoires sont a creer
/*****************************************************/  
LIBNAME tuto "P:\Ludo\Cours\SAS\tutoriel SAS" /*ACCESS=READONLY*/;
LIBNAME sortie "P:\Ludo\Cours\SAS\tutoriel SAS\sortie";


PROC DELETE DATA=tuto.personne; 
RUN;

/*****************************************************/
/* Creation d une table
/*****************************************************/            
DATA tuto.personne;
  /* Modifier la taille de certaines variables */
  LENGTH 
    prenom  $30
    nom     $30       /* par defaut la taille des variables est de 8 si on veut changer il faut preciser ici*/
    sexe    $1
    ;
  /* Liste des variables */
  INPUT 
    id                /* par defaut une variable est de type NUMBER */
    prenom $          /* $ pour dire que le type est TEXT */
    nom $ 
    sexe $
    taille 
    dnais date9.      /* format de saisie de la date */
    ;
  FORMAT 
    dnais DDMMYY10.;  /* format d affichage de la date */
  /* insertion de donnees */
  DATALINES;
    1   Alphonse    Danlmur     1   180 25JAN2002
    2   Armelle     Couvert     2   175 19SEP1986
    3   Barack      Afritt      1   185 29FEB2000
	4   Céline      Evitable    2   150 01MAR1991
	5   Daisy       Rable       2   150 10OCT1979
	6   Elsa        Dorsa       2   160 12NOV2005
	7   Esmeralda   Desgros     2   170 12JUL1998
	8   Eva         Poree       2   175 11AUG1999
	9   Henri       Stourne     1   200 27JUL2001
	10  Jacques     Ouzi        1   160 05JUL2003
  ;
RUN;


/*****************************************************/
/* Structure d une table
/*****************************************************/ 
PROC CONTENTS DATA=tuto.personne;
RUN;


/*****************************************************/
/* Copier et enrichir une table
/*****************************************************/
DATA sortie.personne_enrichie;
  SET tuto.personne;
  RENAME id = ident; /* renommer id en ident */
  age = intck("year", dnais, today(), "c"); /* ajouter une variable */
  SELECT;
    WHEN(year(dnais)>=1970 AND year(dnais)<1980) decennie='1970s';
    WHEN(year(dnais)>=1980 AND year(dnais)<1990) decennie='1980s';
    WHEN(year(dnais)>=1990 AND year(dnais)<2000) decennie='1990s';
    WHEN(year(dnais)>=2000 AND year(dnais)<2010) decennie='2000s';
	OTHERWISE decennie='null';
  END;
RUN;

/* creer table avec SQL */
PROC SQL;
  CREATE TABLE sortie.prenom_nom_h AS
  SELECT prenom,
         nom          
    FROM tuto.personne
   WHERE sexe = '1';
QUIT;

/* idem ci-dessus */
/* ne garder que les variables PRENOM et NOM (colonnes)*/
/* ne garder que les hommes (lignes)*/
DATA sortie.prenom_nom_h;
  SET tuto.personne (KEEP=prenom nom sexe /*DROP= dnais taille*/);
  WHERE sexe = '1';
  DROP sexe;
RUN;

/* inserer variable cumulative */
/*   DATA traite ligne par ligne */
/*   si on veut transmettre une info de lignes en lignes il faut utiliser RETAIN*/
DATA sortie.personne_cumul_taille;
  SET tuto.personne;
  RETAIN cumul_taille 0;
  cumul_taille = SUM(taille,cumul_taille);
RUN;


/*****************************************************/
/* Comparer 2 tables
/*****************************************************/
PROC COMPARE BASE = tuto.personne COMPARE = sortie.personne_enrichie;
RUN;


/*****************************************************/
/* Affichage des valeurs d une table
/*****************************************************/ 
PROC PRINT DATA=tuto.personne;
RUN;

PROC PRINT DATA=tuto.personne (WHERE =(id >= 5 AND sexe = '2'));
RUN;

/* creer un format et utiliser pour afficher */
PROC FORMAT;
  VALUE $sexe_txt
  '1' = 'Homme'
  '2' = 'Femme';

PROC PRINT DATA=tuto.personne;
  FORMAT sexe $sexe_txt.;
RUN;


/*****************************************************/
/* Trier une table
/*****************************************************/ 
PROC SORT DATA = tuto.personne OUT=sortie.personne_triee;
  BY taille
     DESCENDING dnais
     ;
RUN;

/*****************************************************/
/* Indicateurs variable quantitative
/*****************************************************/ 
/* infos sur la variable TAILLE pour les femmes*/
PROC MEANS DATA = tuto.personne(WHERE=( sexe = '2')) N MEAN MEDIAN;
  VAR taille;
RUN ;

/* Moyenne des tailles par sexe*/
PROC MEANS DATA = tuto.personne MEAN;
  VAR taille;
  CLASS sexe;
RUN ;

PROC UNIVARIATE DATA = tuto.personne;
  VAR taille;
RUN ;


/*****************************************************/
/* Indicateurs variable qualitative
/*****************************************************/ 
PROC FREQ DATA = tuto.personne;
  TABLES sexe;
RUN ;

/* NOPRINT pour ne pas afficher dans la sortie SAS
   NOCUM pour ne pas afficher les cumuls
   OUT pour creer une table de sortie*/
PROC FREQ DATA = tuto.personne NOPRINT;
  TABLES sexe / NOCUM OUT=sortie.freq_sexe;
RUN ;

PROC FREQ DATA = sortie.personne_enrichie;
  TABLES sexe*decennie / NOCOL NOCUM NOROW;
RUN ;







/*****************************************************/
/* Export vers excel
/*****************************************************/
PROC EXPORT DATA = tuto.personne
         OUTFILE = "P:\Ludo\Cours\SAS\tutoriel SAS\personne.xls"
            DBMS = EXCEL REPLACE ;
  SHEET = "feuille1" ; 
RUN ;


/*****************************************************/
/* Concatener des tables
/*****************************************************/
/* Attention : il faut que les tables aient les memes variables aux memes formats*/
/*
DATA tuto.table_concat;
  SET tuto.table1 tuto.table2 tuto.table3 tuto.table4;
RUN;
*/

/*****************************************************/
/* Joindre des tables
/*****************************************************/
/* avec un id commun aux 2 tables*/
/*
DATA tuto.table_merge;
MERGE tuto.personne tuto.loisirs;
BY id;
RUN;
*/

/* ou idem en SQL */
/*
PROC SQL;
CREATE TABLE tuto.table_merge AS
  SELECT * 
    FROM tuto.personne p
    JOIN tuto.loisirs l
      ON p.id = l.id;
QUIT ;


/*****************************************************/
/* Graphiques
/*****************************************************/
PROC GPLOT DATA=tuto.personne;
  PLOT sexe*taille;
RUN;

