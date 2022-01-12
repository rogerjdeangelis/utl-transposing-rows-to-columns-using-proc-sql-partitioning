%let pgm=utl-transposing-rows-to-columns-using-proc-sql-partitioning;

Transposing rows to columns using proc sql partitioning

github
https://tinyurl.com/47ncxbvy
https://github.com/rogerjdeangelis/utl-transposing-rows-to-columns-using-proc-sql-partitioning

I realize there is a simple non SQL solution, however this is a pure sql solution.
It may not be as slow as you think.

This is the case where you do not have column names in your input table

SAS does not directly supoort partitonibg however there is a way to doit.
Python and R Sqlite do support partitioning

Example of R and Python partitoning
select nam, score, row_number() over (partition by nam) as partition from havSql

  Two Solutions
        1. Without SQL arrays
        2. With SQL arrays

/*                   _
(_)_ __  _ __  _   _| |_
| | `_ \| `_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
*/

libname sd1 "d:/sd1";

options validvarname=upcase;

data sd1.have;

 do nam = "JANE ", "MIKE", "MIKE","ROGER", "ROGER","ROGER" ;
    score=50 + int(50*uniform(1234));
    output;
 end;

run;quit;

/*
Up to 40 obs SD1.HAVE total obs=6 12JAN2022:07:06:53

Obs     NAM     SCORE

 1     JANE       62
 2     MIKE       54
 3     MIKE       69
 4     ROGER      54
 5     ROGER      62
 6     ROGER      54

INTERMEDIATE PARTITION VIEW WITH PARTITIONS

Up to 40 obs from PARTITION total obs=6 12JAN2022:07:34:04

     Obs    PARTITION     NAM     SCORE

       1        1        JANE       62
       2        1        MIKE       54
       3        1        ROGER      54
       4        2        MIKE       69
       5        2        ROGER      62
       6        3        ROGER      54
             _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| `_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
*/

Up to 40 obs from WANT total obs=3 12JAN2022:07:35:28

Obs     NAM     SCORE1    SCORE2    SCORE3

 1     JANE       62         .         .
 2     MIKE       54        69         .
 3     ROGER      54        62        54


/*
 _ __  _ __ ___   ___ ___  ___ ___
| `_ \| `__/ _ \ / __/ _ \/ __/ __|
| |_) | | | (_) | (_|  __/\__ \__ \
| .__/|_|  \___/ \___\___||___/___/
|_|
 _             __                _
/ | __      __/ /__    ___  __ _| |   __ _ _ __ _ __ __ _ _   _
| | \ \ /\ / / / _ \  / __|/ _` | |  / _` | `__| `__/ _` | | | |
| |  \ V  V / / (_) | \__ \ (_| | | | (_| | |  | | | (_| | |_| |
|_|   \_/\_/_/ \___/  |___/\__, |_|  \__,_|_|  |_|  \__,_|\__, |
                              |_|                         |___/
*/

* safe use of undocumented monotonic function?;
* max is needed because of the group by;

proc sql;

   create view partition as
      select monotonic() as partition , nam, score from sd1.have where nam="JANE" union
      select monotonic() as partition , nam, score from sd1.have where nam="MIKE " union
      select monotonic() as partition , nam, score from sd1.have where nam="ROGER"
   ;
   create table want as select
      nam
     ,max(case when partition=1 then score else . end) as score1
     ,max(case when partition=2 then score else . end) as score2
     ,max(case when partition=3 then score else . end) as score3
   from
     partition
   group
     by nam
;quit;

/*___                         _
|___ \  __      __  ___  __ _| |   __ _ _ __ _ __ __ _ _   _
  __) | \ \ /\ / / / __|/ _` | |  / _` | `__| `__/ _` | | | |
 / __/   \ V  V /  \__ \ (_| | | | (_| | |  | | | (_| | |_| |
|_____|   \_/\_/   |___/\__, |_|  \__,_|_|  |_|  \__,_|\__, |
                           |_|                         |___/
*/
THIS IS A MORE GENERAL SOLUTION

* IN CASE YOU RERUN;
%symdel _nam1 _nam2 _nam3 _namn _part1 _part2 _part3 _partn / nowarn;

/* NOTE  %arraydelete(_nam) will also delete all the _nam macro variables */

*LOAD _NAM ARRAY;
proc sql; select distinct nam into: _nam1- from sd1.have ;quit;
%let _namn=&sqlobs;
%put &_namn;

* Load partition array;
%array(_part,values=1-&_namn);

/*
Macro arrays
%utlnopts;

%put &=_part1;  _part1=1
%put &=_part2;  _part2=2
%put &=_part3;  _part3=3
%put &=_partn;  _partn=3

%put &=_nam1;   _NAM1=JANE
%put &=_nam2;   _NAM2=MIKE
%put &=_nam3;   _NAM3=ROGER
%put &=_namn;   _NAMN=3

%utlopts;
*/

proc sql;
    create view partition as
        %do_over(_nam,phrase=%str(
          select monotonic() as partition , nam, score from sd1.have where nam="?"), between=union );
    create table want as select nam
        %do_over(_part,phrase=%str(
          ,max(case when partition=? then score else . end) as score?))
    from partition
    group by nam;
;quit;

/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|

*/
