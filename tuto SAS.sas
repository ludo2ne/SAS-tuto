/* clear sas output*/
DM 'odsresults; clear';


/***********************************************************************************************************/
/* Definition de librairies
/*   ces repertoires sont a creer
/***********************************************************************************************************/  
LIBNAME entree "P:\Ludo\Cours\UE2 SAS\tutoriel SAS\Entrée" /*ACCESS=READONLY*/;
LIBNAME travail "P:\Ludo\Cours\UE2 SAS\tutoriel SAS\Travail";
LIBNAME sortie "P:\Ludo\Cours\UE2 SAS\tutoriel SAS\Sortie";


/***********************************************************************************************************/
/* Importer un fichier excel
/***********************************************************************************************************/ 

PROC IMPORT 
  FILE = "P:\Ludo\Cours\UE2 SAS\tutoriel SAS\Entrée\Métiers.xls"
  OUT = travail.metier
  DBMS = xls
  REPLACE;
run;



/***********************************************************************************************************/
/* Supression d une table
/***********************************************************************************************************/ 

PROC DELETE DATA=entree.personne; 
RUN;


/***********************************************************************************************************/
/* Creation d une table
/***********************************************************************************************************/
 
DATA entree.personne;
  /* Modifier la taille de certaines variables */
  LENGTH 
    prenom  $30
    nom     $30       /* par defaut la taille des variables est de 8 si on veut changer il faut preciser ici*/
    ville   $30
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
    ville $	
    ;
  FORMAT 
    dnais DDMMYY10.;  /* format d affichage de la date */
  /* insertion de donnees */
  DATALINES;
    1   Alphonse    Danlmur     1   180 25JAN2002 Amiens         
    2   Armelle     Couvert     2   175 19SEP1986 Valenciennes   
    3   Barack      Afritt      1   185 29FEB2000 Valenciennes   
    4   Céline      Evitable    2   150 01MAR1991 Amiens         
    5   Daisy       Rable       2   150 10OCT1979 Chauny         
    6   Elsa        Dorsa       2   160 12NOV2005 Chauny         
    7   Esmeralda   Desgros     2   170 12JUL1998 Valenciennes   
    8   Eva         Poree       2   175 11AUG1999 Amiens         
    9   Henri       Stourne     1   200 27JUL2001 Valenciennes   
    10  Jacques     Ouzi        1   160 05JUL2003 Amiens         
    11  Odile       Deray       2   165 03JAN1960 Amiens         
    12  Sam         Gratte      1   170 20SEP1975 Valenciennes   
    13  Pierre      Kiroul      1   190 31OCT1985 Amiens         
    14  Lara        Masse       2   180 11AUG1970 Chauny         
    15  Aude        Javel       2   170 20APR1989 Amiens          
  ;
RUN;


/***********************************************************************************************************/
/* Structure d une table
/*   permet de voir le nombre d observation, de variables, la liste des variables et leurs types
/***********************************************************************************************************/ 

PROC CONTENTS DATA=entree.personne;
RUN;


/***********************************************************************************************************/
/* Copier et enrichir une table
/*   RENAME : renommer une variable
/*   creer de nouvelles variables
/*   DROP ou KEEP pour supprimer ou conserver certaines variables (par défaut tout est conserve
/*   RETAIN pour transmettre des infos de lignes en lignes
/***********************************************************************************************************/

DATA travail.personne_2;
  SET entree.personne;
  RENAME id = ident;
  age = intck("year", dnais, today(), "c");
  SELECT;
    WHEN(year(dnais)>=1970 AND year(dnais)<1980) decennie='1970s';
    WHEN(year(dnais)>=1980 AND year(dnais)<1990) decennie='1980s';
    WHEN(year(dnais)>=1990 AND year(dnais)<2000) decennie='1990s';
    WHEN(year(dnais)>=2000 AND year(dnais)<2010) decennie='2000s';
    OTHERWISE decennie='null';
  END;
RUN;

/* creer une table avec une PROC SQL */
PROC SQL;
  CREATE TABLE travail.prenom_nom_h AS
  SELECT prenom,
         nom          
    FROM entree.personne
   WHERE sexe = '1';
QUIT;

/* idem ci-dessus */
/*   ne garder que les variables PRENOM et NOM (au niveau colonnes)*/
/*   ne garder que les hommes (au niveau lignes)*/
DATA travail.prenom_nom_h2;
  SET entree.personne (KEEP=prenom nom sexe /*DROP= dnais taille*/);
  WHERE sexe = '1';
  DROP sexe;
RUN;

/* inserer variable cumulative */
/*   DATA traite ligne par ligne */
/*   si on veut transmettre une info de lignes en lignes il faut utiliser RETAIN*/
DATA travail.personne_cumul_taille;
  SET entree.personne;
  RETAIN cumul_taille 0;
  cumul_taille = SUM(taille,cumul_taille);
RUN;


/***********************************************************************************************************/
/* Comparer 2 tables
/***********************************************************************************************************/

PROC COMPARE BASE = entree.personne COMPARE = travail.personne_2;
RUN;


/***********************************************************************************************************/
/* Affichage des valeurs d une table
/***********************************************************************************************************/ 

PROC PRINT DATA=travail.personne_2;
RUN;

PROC PRINT DATA=travail.personne_2 (WHERE =(ident >= 5 AND sexe = '2'));
RUN;

/* creer un format et utiliser pour afficher */
PROC FORMAT;
  VALUE $sexe_txt    /* pour une variable de type texte*/
  '1' = 'Homme'
  '2' = 'Femme';
  VALUE age_txt      /* pour une variable numerique */
    0 -< 18  = 'Enfants'
    18 -< 26 = 'Etudiants'
    26 -< 40 = 'Jeunes actifs'
    40 -< 55 = 'Actifs'
    55 -< 65 = 'Actifs expérimentés'
    65 -< 80 = 'Jeunes seniors'
    80 - HIGH = 'Seniors';
RUN;

/* importer les formats d une librairie */
OPTIONS FMTSEARCH = (entree);

/* Afficher la liste des formats d une librairie */
PROC FORMAT LIBRAIRY=source FMTLIB;
RUN;

/* Utiliser un format */
PROC PRINT DATA=travail.personne_2;
  FORMAT sexe $sexe_txt.;
RUN;



/***********************************************************************************************************/
/* Trier une table
/***********************************************************************************************************/ 
PROC SORT DATA = travail.personne_2 OUT=sortie.personne_triee;
  BY taille
     DESCENDING dnais
     ;
RUN;

/***********************************************************************************************************/
/* Indicateurs variable quantitative
/*   N MIN MAX MEAN MEDIAN VAR STD SUM P1 Q1
/*   MAXDEC pour arrondir à x decimales
/*   NOOBS pour ne pas afficher le nombre d observations
/***********************************************************************************************************/ 

/* infos sur la variable TAILLE*/
PROC MEANS DATA = travail.personne_2;
  VAR taille;
RUN ;

/* Moyenne, Mediane des tailles et ages par sexe pour les Amienois*/
PROC MEANS DATA = travail.personne_2(WHERE=( ville = 'Amiens')) MEAN MEDIAN NOOBS MAXDEC=2;
  VAR taille age;
  CLASS sexe;
  FORMAT sexe $sexe_txt.;
  /* OUTPUT OUT=sortie.means_taille_sexe; */  
  TITLE 'Moyenne, Mediane des tailles et ages par sexe'; 
  FOOTNOTE 'pour la population d''Amiens';
RUN ;


/* pour reinitialiser titre et note de bas de page*/
TITLE;
FOOTNOTE;


PROC UNIVARIATE DATA = travail.personne_2;
  VAR taille;
RUN ;

PROC UNIVARIATE DATA = travail.personne_2(WHERE=( ville = 'Amiens'));
  VAR taille;
  CLASS sexe;
  FORMAT sexe $sexe_txt.;
  /*OUTPUT OUT=sortie.univ_taille_sexe;*/
RUN ;


/***********************************************************************************************************/
/* Indicateurs variable qualitative
/*   NOPRINT pour ne pas afficher dans la sortie SAS
/*   NOCUM pour ne pas afficher les cumuls
/*   NOCOL et NOROW pour ne pas afficher les pourcentage par colonne ou ligne
/*   NOPERCENT pour le pas afficher les pourcentages globaux
/***********************************************************************************************************/ 

PROC FREQ DATA = travail.personne_2;
  TABLES sexe;
RUN ;

PROC FREQ DATA = travail.personne_2 NOPRINT;
  TABLES sexe / NOCUM OUT=sortie.freq_sexe;
RUN ;

PROC FREQ DATA = travail.personne_2;
  TABLES sexe*decennie / NOCUM NOROW NOCOL ;
  FORMAT sexe $sexe_txt.;
RUN ;


/***********************************************************************************************************/
/* Export vers excel
/***********************************************************************************************************/
PROC EXPORT DATA = travail.personne_2
         OUTFILE = "P:\Ludo\Cours\UE2 SAS\tutoriel SAS\Sortie\personne.xls"
            DBMS = EXCEL REPLACE ;
  SHEET = "feuille1" ; 
RUN ;


/***********************************************************************************************************/
/* Concatener des tables
/*   Attention il faut que les tables aient les memes variables aux memes formats
/***********************************************************************************************************/

DATA sortie.table_concat;
  SET travail.personne_2 entree.anciens;
RUN;


/***********************************************************************************************************/
/* Joindre des tables
/*   avec un identifiant commun aux 2 tables
/***********************************************************************************************************/

PROC SQL;
CREATE TABLE sortie.table_merge AS
  SELECT * 
    FROM travail.personne_2 p
    JOIN travail.metier m
      ON p.ident = m.ident;
QUIT ;

/* pour garder meme ceux qui ne sont pas dans la table metier*/
PROC SQL;
CREATE TABLE sortie.table_merge_left AS
  SELECT * 
    FROM travail.personne_2 p
    LEFT JOIN travail.metier m
      ON p.ident = m.ident;
QUIT ;


/***********************************************************************************************************/
/* Graphiques
/***********************************************************************************************************/

/* graphique*/ 
PROC GPLOT DATA=travail.personne_2;
  PLOT taille*age;
RUN;

/* Diagramme en barre*/ 
PROC GCHART DATA=travail.personne_2;
  VBAR ville / TYPE=PERCENT;
RUN;


/* Camembert*/ 
PROC SORT DATA=travail.personne_2;
  BY sexe;
RUN;
PROC GCHART DATA=travail.personne_2;
  PIE ville;
  BY sexe;
  FORMAT sexe $sexe_txt.;
RUN;
