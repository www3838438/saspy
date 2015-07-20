*filename  d1 url 'http://www-bcf.usc.edu/~gareth/ISL/Advertising.csv'; 
*proc import datafile=d1 out=work.data dbms=csv replace; run;

/*
%macro proccall(dset);
    proc reg data=&dset. plots(unpack)=all;
        model MSRP = weight wheelbase length;
    run;
    quit;
%mend;
*/

/*Take an ods document*/
%macro mangobj(objname,objtype,d);
    data _null_;
        guid=uuidgen();
        tmpdir=dcreate(guid,getoption('work'));
        call symputx('tmpdir',tmpdir);
    run;
    libname &objname. base "&tmpdir.";
    ods _all_ close;
/*    ods html file="&tmpdir./&objname..html";*/
    ods document name=&objname.(write);
    /*replace with code generation macro*/
    %proccall(&d.);
    /*end replace with code generation macro*/
    ods document close;
    /*create a libname using the document name*/
    
    proc document name=&objname.;
        ods output Properties=_&objname.properties;
        list \(where=(_type_='Dir')) /levels=all;
    quit; 
    filename file1 temp;
    data _null_;
        length path $1000;
        set _&objname.properties end=last;
        file file1;
        if _n_=1 then do;
            put "libname _&objname. sasedoc (";
        end;
        p=cat("'\&objname.", catt(path) , "'");
        put p;
        if last then do;
            put ');';
        end;
    run;
    /*concatentate all the directories in the ods document to the top level directory*/
    %include file1;
    /*Create a table of all the datasets using sashelp.vmember*/
    data _&objname.filelist;
        length objtype $32 objname $32.;
        set sashelp.vmember(where=(lower(libname)=lower("_&objname.")));
        ds="&d.";
        objtype="&objtype";
        objname="&objname";
        method=memname;
        keep ds objtype objname method;
    run;
%mend;
*%mangobj(cars,reg,sashelp.cars);
/*
%let d=sashelp.cars;
%let objtype=reg;
%let objname=cars;
%let method=ANOVA;
*/

%macro getdata(objname, method);
    proc document name=&objname.;
        replay \ (where=(lower(_name_)=lower("&method.")));;
    run;
    quit;
%mend;
/*
%getdata(cars,nobs);
%getdata(cars,qqplot);
%getdata(cars,diagnosticspanel);
*/;
%macro listdata(objname);
    data _null_;
        set _&objname.filelist end=last;
        if _n_=1 then put "startparse9878";
        put method;
        if  last then put "endparse9878";
    run;
%mend;
/*
%listdata(cars);
%listdata(lm);
*/



/*Full Test*/
/*
%macro proccall(dset); proc reg data=&dset. plots(unpack)=all; model MSRP = weight wheelbase length; run; quit; %mend;

%mangobj(cars,reg,sashelp.cars);

%listdata(cars);

%getdata(cars,COOKSDPLOT);
*/

/*Full Test2 */
/*
%macro proccall(d);
proc hpsplit plots=all data=sashelp.cars;model mpg_city = msrp cylinders length wheelbase weight;run; %mend;
%mangobj(hps1,hpsplit,cars);

%listdata(hps1);

%getdata(hps1,COOKSDPLOT);
*/