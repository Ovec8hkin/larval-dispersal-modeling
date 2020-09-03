% Generate fiscm nml file for ensemble runs
%
%
clear all
clc
close all

cw=pwd;

path2mydata='/vortexfs1/share/jilab/zahner-ssf2020/auxdata';
path2mytool='/vortexfs1/share/jilab/zahner-ssf2020/matlabtools';

addpath(genpath(path2mytool));

NP = 821099;

% define variables
Year             = 1983;
Month            = 3
Day              = 1

total_days       = 120;   % total simulation days
deltaT           = 600;  % physical time step in seconds
ireport          = 144;  % report every day 
ngroups          = 1;
year_cycle       = 0;
nfiles_in        = 5;

spherical        = 0;
sz_cor           = 1;
Dtop             = 0.0;
Dbot             = 100.0;
fix_dep          = 1;    % passive = 0; fix_depth = 1.
dvm_bio          = 0;
wind_type        = 0;
bio_fd           = 1;    % food-dependency
n_extfile        = 0;    % external satellite chlorophyll-a input file
dvmh_up          = 15.0;
dvmh_dn          = 1.0;
bcond_type       = 1;

Tnind            = NP;
space_dim        = 3;
group_name       = 'Haddock 03-1983';
hdiff_type       = 0;
hdiff_const_val  = 10.0;
vdiff_type       = 0;
vdiff_const_val  = 0.0;
vdiff_substeps   = 5;
intvl_bio        = 6;
biology          = 'T';
intvl_out        = 144;
start_out        = 0.0;
nstate_ud        = 1;
ini_file         = 'particle_init.txt';

%
tic

Release_date = datenum(Year,Month,Day);

beg_day = datenum(Year,Month,Day) - datenum(Year,1,1) + 1;
end_day = datenum(Year,Month,Day) - datenum(Year,1,1) + 1 + total_days;
mjd_offset = datenum(Year,1,1)-datenum(1858,11,17);

cd(cw)     

% write nml file  
nml_file = 'model_settings.nml';
nml_file_ID = fopen(nml_file,'w');

fprintf(nml_file_ID,'%s\n','&NML_FISCM');
fprintf(nml_file_ID,' %s %6.2f %s\n',   'beg_time_days = ',beg_day,',');
fprintf(nml_file_ID,' %s %6.2f %s\n',   'end_time_days = ',end_day,',');
fprintf(nml_file_ID,' %s %d %s\n'   ,   'mjd_offset    = ',mjd_offset,',');
fprintf(nml_file_ID,' %s %6.2f %s\n',   'deltaT        =',deltaT,',');
fprintf(nml_file_ID,' %s %d %s\n',      'ireport       =',ireport,',');
fprintf(nml_file_ID,' %s %d %s\n',      'ngroups       =',ngroups,',');
fprintf(nml_file_ID,' %s %d %s\n',      'year_cycle    =',year_cycle,',');
fprintf(nml_file_ID,' %s %d %s\n',      'nfiles_in     =',nfiles_in,',');
	      
forcname1=[' ''/vortexfs1/share/jilab/gom3_hourly/gom3_',num2str(Year),'02.nc'','];
forcname2=[' ''/vortexfs1/share/jilab/gom3_hourly/gom3_',num2str(Year),'03.nc'','];
forcname3=[' ''/vortexfs1/share/jilab/gom3_hourly/gom3_',num2str(Year),'04.nc'','];
forcname4=[' ''/vortexfs1/share/jilab/gom3_hourly/gom3_',num2str(Year),'05.nc'''];
forcname5=[' ''/vortexfs1/share/jilab/gom3_hourly/gom3_',num2str(Year),'06.nc'''];

fprintf(nml_file_ID,' %s',    forcname1);
fprintf(nml_file_ID,' %s',    forcname2);
fprintf(nml_file_ID,' %s',    forcname3); 
fprintf(nml_file_ID,' %s',    forcname4);
fprintf(nml_file_ID,' %s\n',  forcname5);

fprintf(nml_file_ID,' %s %d %s\n',   'spherical     =',spherical,',');
fprintf(nml_file_ID,' %s %d %s\n',   'sz_cor        =',sz_cor,',');
fprintf(nml_file_ID,' %s %6.2f %s\n','Dtop          =',Dtop,',');
fprintf(nml_file_ID,' %s %6.2f %s\n','Dbot          =',Dbot,',');
fprintf(nml_file_ID,' %s %d %s\n',   'fix_dep       =',fix_dep,',');
fprintf(nml_file_ID,' %s %d %s\n',   'dvm_bio       =',dvm_bio,',');
fprintf(nml_file_ID,' %s %d %s\n',   'wind_type     =',wind_type,',');
fprintf(nml_file_ID,' %s %d %s\n',   'bio_fd        =',bio_fd,',');
fprintf(nml_file_ID,' %s %d %s\n',   'n_extfile     =',n_extfile,',');
fprintf(nml_file_ID,' %s \n',        'extfile_name  = '''', ');
         
fprintf(nml_file_ID,' %s %6.2f %s\n','dvmh_up       =',dvmh_up,',');
fprintf(nml_file_ID,' %s %6.2f %s\n','dvmh_dn       =',dvmh_dn,',');
fprintf(nml_file_ID,' %s %d %s\n',   'bcond_type    =',bcond_type,',');
fprintf(nml_file_ID,' %s \n\n',      '/');

fprintf(nml_file_ID,'%s\n','&NML_GROUP');
fprintf(nml_file_ID,' %s %d %s\n',    'Tnind           = ',Tnind,',');
fprintf(nml_file_ID,' %s %d %s\n',    'space_dim       = ',space_dim,',');
fprintf(nml_file_ID,' %s\n',          'group_name      = ''C. finmarchicus'',');
fprintf(nml_file_ID,' %s %d %s\n',    'hdiff_type      = ',hdiff_type,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'hdiff_const_val = ',hdiff_const_val,',');
fprintf(nml_file_ID,' %s %d %s\n',    'vdiff_type      = ',vdiff_type,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'vdiff_const_val = ',vdiff_const_val,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'vdiff_substeps  = ',vdiff_substeps,',');
fprintf(nml_file_ID,' %s %d %s\n',    'intvl_bio       = ',intvl_bio,',');
fprintf(nml_file_ID,' %s \n',         'biology         = ',biology,',');
fprintf(nml_file_ID,' %s %d %s\n',    'intvl_out       = ',intvl_out,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'start_out       = ',start_out,',');
fprintf(nml_file_ID,' %s %d %s\n',    'nstate_ud       = ',nstate_ud,',');
fprintf(nml_file_ID,' %s\n',       ['ini_file          = ''',ini_file,''',']);
fprintf(nml_file_ID,' %s \n\n',      '/');

% define copepod initial age
fprintf(nml_file_ID,'%s\n','&NML_STATEVAR');
fprintf(nml_file_ID,' %s \n',         'state_varname        = ''PASD'', ');
fprintf(nml_file_ID,' %s \n',         'state_longname       = ''Model Currency'', ');
fprintf(nml_file_ID,' %s \n',         'state_units          = ''-'', ');
fprintf(nml_file_ID,' %s %d %s\n',    'state_netcdf_out     = ',1,',');
fprintf(nml_file_ID,' %s %d %s\n',    'state_vartype        = ',2,',');
fprintf(nml_file_ID,' %s %d %s\n',    'state_initval_int    = ',1,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'state_initval_flt    = ',1.0,',');
fprintf(nml_file_ID,' %s \n',         'state_from_ext_var   = ''NONE'', ');
fprintf(nml_file_ID,' %s \n\n',      '/');

% define copepod initial temperature
fprintf(nml_file_ID,'%s\n','&NML_STATEVAR');
fprintf(nml_file_ID,' %s \n',         'state_varname        = ''T'', ');
fprintf(nml_file_ID,' %s \n',         'state_longname       = ''temperature'', ');
fprintf(nml_file_ID,' %s \n',         'state_units          = ''C'', ');
fprintf(nml_file_ID,' %s %d %s\n',    'state_netcdf_out     = ',1,',');
fprintf(nml_file_ID,' %s %d %s\n',    'state_vartype        = ',2,',');
fprintf(nml_file_ID,' %s %d %s\n',    'state_initval_int    = ',0,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'state_initval_flt    = ',0.0,',');
fprintf(nml_file_ID,' %s \n',         'state_from_ext_var   = ''temp'', ');
fprintf(nml_file_ID,' %s \n\n',      '/');

% define copepod initial stage
fprintf(nml_file_ID,'%s\n','&NML_STATEVAR');
fprintf(nml_file_ID,' %s \n',         'state_varname       = ''stage'', ');
fprintf(nml_file_ID,' %s \n',         'state_longname      = ''morphological stage'', ');
fprintf(nml_file_ID,' %s \n',         'state_units         = ''-'', ');
fprintf(nml_file_ID,' %s %d %s\n',    'state_netcdf_out    = ',1,',');
fprintf(nml_file_ID,' %s %d %s\n',    'state_vartype       = ',1,',');
fprintf(nml_file_ID,' %s %d %s\n',    'state_initval_int   = ',1,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'state_initval_flt   = ',1.0,',');
fprintf(nml_file_ID,' %s \n',         'state_from_ext_var  = ''NONE'', ');
fprintf(nml_file_ID,' %s \n\n',      '/');

% define copepod initial diapause status
fprintf(nml_file_ID,'%s\n','&NML_STATEVAR');
fprintf(nml_file_ID,' %s \n',         'state_varname        = ''diapause'', ');
fprintf(nml_file_ID,' %s \n',         'state_longname       = ''diapause flag'', ');
fprintf(nml_file_ID,' %s \n',         'state_units          = ''-'' ');
fprintf(nml_file_ID,' %s %d %s\n',    'state_netcdf_out     = ',1,',');
fprintf(nml_file_ID,' %s %d %s\n',    'state_vartype        = ',1,',');
fprintf(nml_file_ID,' %s %d %s\n',    'state_initval_int    = ',1,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'state_initval_flt    = ',1.0,',');
fprintf(nml_file_ID,' %s \n',         'state_from_ext_var   = ''NONE'', ');   
fprintf(nml_file_ID,' %s \n\n',       '/');

% define copepod initial chlorophylll food
fprintf(nml_file_ID,'%s\n','&NML_STATEVAR');
fprintf(nml_file_ID,' %s \n',         'state_varname        = ''CHL_2DIM'', ');
fprintf(nml_file_ID,' %s \n',         'state_longname       = ''chlorophyll'', ');
fprintf(nml_file_ID,' %s \n',         'state_units          = ''mg-chl m-3'', ');
fprintf(nml_file_ID,' %s %d %s \n',   'state_netcdf_out     = ',1,',');
fprintf(nml_file_ID,' %s %d %s \n',   'state_vartype        = ',2,',');
fprintf(nml_file_ID,' %s %d %s \n',   'state_initval_int    = ',1,',');
fprintf(nml_file_ID,' %s %8.2f %s\n', 'state_initval_flt    = ',1.0,',');
fprintf(nml_file_ID,' %s \n',         'state_from_ext_var   = ''chl_ext'', ');
fprintf(nml_file_ID,' %s \n\n',       '/');

% define life stage development parameters
fprintf(nml_file_ID,'%s\n','&NML_COPEPOD');
fprintf(nml_file_ID,' %s \n','BEL_ALPHA = 9.11,');
fprintf(nml_file_ID,' %s \n','BEL_A = 595 388 581 1387 759 716 841 966 1137 1428 2166 4083,');
fprintf(nml_file_ID,' %s \n','PC0 = 0.8,');
fprintf(nml_file_ID,' %s \n\n',      '/');

fclose(nml_file_ID);

cd(cw);
toc

cd(cw);
%%

