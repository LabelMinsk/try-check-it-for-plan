execute ibeblock
as
declare variable GOD_RASH char(4);
begin
   AddLog = 'execute ibeblock (log variant, mes varchar(50))
            as
            begin
              cur_time = ''[''||ibec_Now()||'']'';
              mes = cur_time||'' ''||mes;
              ibec_fs_WriteLn(log, mes);
            end;';

  
  -- Текущий каталог
  ProgPath = ibec_GetRunDir();
  -- ini с параметрами
  _ini_file = ProgPath + 'bc.ini';
  -- лог файл с информацией
  log_file = ProgPath || + 'bc.log';
  _ini_file_var = ProgPath + 'global_var.ini';

  ibec_DeleteFile(:log_file);
  log_fs = ibec_fs_OpenFile(:log_file, __fmCreate);

  s = ' Начало работы скрипта...';
  execute ibeblock AddLog(log_fs, s);

  -- Проверим наличие ini файла *
  if (not ibec_FileExists(_ini_file)) then
  begin
    ibec_Progress('Файл ' + _ini_file + ' не найден.');
    Exit;
  end  
   -- Проверим наличие global_var.ini файла *
  if (not ibec_FileExists(_ini_file_var)) then
  begin
    ibec_Progress('Файл ' + _ini_file_var + ' не найден.');
    Exit;
  end  


  _ini = ibec_ini_Open(_ini_file);
  trg_base = ibec_ini_ReadString(_ini, 'BASE', 'FDBNAME', '');
  pass = ibec_ini_ReadString(_ini, 'BASE', 'PASSWORD', '');
  ibec_ini_Close(_ini);

  _ini_var  = ibec_ini_Open(_ini_file_var);
  var_year = ibec_ini_ReadString(_ini_var,'VAR_INI','GOD','');
  var_year_zam = ibec_ini_ReadString(_ini_var,'VAR_INI','PERIOD2','');
  var_year_izgot = ibec_ini_ReadString(_ini_var,'VAR_INI','PERIOD3','');

  ibec_ini_Close(_ini_var);

  ibec_Progress('База '+trg_base);

  -- Создание соединения с БД
  DB = ibec_CreateConnection(__ctFirebird, 'DBName="'+trg_base+'";
                                              ClientLib=gds32.dll;
                                              User=SYSDBA; Password="'+pass+'";
                                              Names=WIN1251; SqlDialect=3;');
  try
    -- Используем соединение к базе данных
    ibec_UseConnection(DB);
	-- очищаем tmp_poverka_old
    delete from tmp_poverka_old;
   -- delete from tmp_poverka t where coalesce(t.nom_nz,0)=0;
    commit;
	-- перезаписываем данные из tmp_poverka в tmp_poverka_old
	for select PHONE, PRIZ_POV, DATE_NAR_ZAD, TIME_POS, DATE_NATH_POV, DATE_UVED, NOM_ABON, KOD_SHT, ZAV_NOM, ID_BRIG, STAT_NZ, NOM_NZ, DATE_POV, PRIM, DATE_UST, DATE_POST_PRINT, ISPOLN, ID_SCH, DATE_VVOD from tmp_poverka
	into :t_PHONE, :t_PRIZ_POV, :t_DATE_NAR_ZAD, :t_TIME_POS, :t_DATE_NATH_POV, :t_DATE_UVED, :t_NOM_ABON, :t_KOD_SHT, :t_ZAV_NOM, :t_ID_BRIG, :t_STAT_NZ, :t_NOM_NZ, :t_DATE_POV, :t_PRIM, :t_DATE_UST, :t_DATE_POST_PRINT, :t_ISPOLN, :t_ID_SCH, :t_DATE_VVOD
		do begin
		insert into tmp_poverka_old(PHONE, PRIZ_POV, DATE_NAR_ZAD, TIME_POS, DATE_NATH_POV, DATE_UVED, NOM_ABON, KOD_SHT, ZAV_NOM, ID_BRIG, STAT_NZ, NOM_NZ, DATE_POV, PRIM, DATE_UST, DATE_POST_PRINT, ISPOLN, ID_SCH, DATE_VVOD) 
		values(:t_PHONE, :t_PRIZ_POV, :t_DATE_NAR_ZAD, :t_TIME_POS, :t_DATE_NATH_POV, :t_DATE_UVED, :t_NOM_ABON, :t_KOD_SHT, :t_ZAV_NOM, :t_ID_BRIG, :t_STAT_NZ, :t_NOM_NZ, :t_DATE_POV, :t_PRIM, :t_DATE_UST, :t_DATE_POST_PRINT, :t_ISPOLN, :t_ID_SCH, :t_DATE_VVOD);
commit;
end


  --  insert into tmp_poverka_old(PHONE, PRIZ_POV, DATE_NAR_ZAD, TIME_POS, DATE_NATH_POV, DATE_UVED, NOM_ABON, KOD_SHT, ZAV_NOM, ID_BRIG, STAT_NZ, NOM_NZ, DATE_POV, PRIM, DATE_UST, DATE_POST_PRINT, ISPOLN, ID_SCH, DATE_VVOD)  
  --  select PHONE, PRIZ_POV, DATE_NAR_ZAD, TIME_POS, DATE_NATH_POV, DATE_UVED, NOM_ABON, KOD_SHT, ZAV_NOM, ID_BRIG, STAT_NZ, NOM_NZ, DATE_POV, PRIM, DATE_UST, DATE_POST_PRINT, ISPOLN, ID_SCH, DATE_VVOD from tmp_poverka;
  --  commit;



-- очищаем tmp_poverka
    delete from tmp_poverka;
   -- delete from tmp_poverka t where coalesce(t.nom_nz,0)=0;
    commit;

    for select distinct s.nom_abon--count(*)
from shethik s, spr_abon a, sp_schet p,  licev l  , sp_punkt sp, sp_ul su, sp_vu vu
	where
	s.status = '+'
	
	and a.kod_punkt=sp.kod_punkt
	and a.kod_ul=su.kod_ul
	and a.kod_vu=vu.kod_vu
	
	and s.nom_abon = a.nom_abon
	
	and p.kod_sht = s.kod_sht
	
	and s.nom_abon=l.nom_abon
	and coalesce(l.status_pov,0)=0
        and ((extract(year from s.date_povr)between '2019' and :var_year) or (s.date_povr is null))  
--	and ((extract(year from s.date_povr)=:var_year) or (s.date_povr is null))

--в августе добавить(раскомментировать ) в отчете 6.8 Количественный график поверки счетчиков так же снять комментарии 
--	and ((s.date_zam is null) or (extract( year from s.date_zam) <= :var_year_zam))
--    and ((s.date_izgot is null) or (extract( year from s.date_izgot) <= :var_year_izgot))
    into :NOM

    do begin
        ibec_Progress('Лицевой - '||:NOM);

       select first 1 iif(a.telmobil is not null,a.telmobil||', '||a.teldom,a.teldom), s.kod_sht, s.zav_nom,
        s.date_ust, s.date_povr, s.ispoln, s.id
        from  shethik s, spr_abon a, sp_schet p,  licev l  , sp_punkt sp, sp_ul su, sp_vu vu
	where
		s.status = '+'
		
		and a.kod_punkt=sp.kod_punkt
		and a.kod_ul=su.kod_ul
		and a.kod_vu=vu.kod_vu
		
		and s.nom_abon = a.nom_abon
		
		and p.kod_sht = s.kod_sht
		
		and s.nom_abon=l.nom_abon
		and coalesce(l.status_pov,0)=0
                and ((extract(year from s.date_povr)between '2019' and :var_year) or (s.date_povr is null))
		--and ((extract(year from s.date_povr)=:var_year) or (s.date_povr is null))

--в августе добавить(раскомментировать ) в отчете 6.8 Количественный график поверки счетчиков так же снять комментарии 
--	and ((s.date_zam is null) or (extract( year from s.date_zam) <= :var_year_zam))
--    and ((s.date_izgot is null) or (extract( year from s.date_izgot) <= :var_year_izgot))
	        and s.nom_abon=:NOM
        into :PHONE,:KOD_SCH,:ZAV_NOM,:date_ust, :date_povr, :ispoln, :id_sch;

        insert into tmp_poverka(NOM_ABON, phone, kod_sht, zav_nom, DATE_UST, DATE_POV, ISPOLN, id_sch)
        values (:NOM,:PHONE,:KOD_SCH,:ZAV_NOM,:date_ust,:date_povr, :ispoln, :id_sch);

    end
   commit;

   for select s.nom_abon , trim(s.prim)
   from tmp_poverka_old s
   where 1=1
   and  s.prim is not null
   into :nom_abon , :prim
        do begin
          ibec_Progress('Обновление примечания. Лицевой - '||:nom_abon);
            update tmp_poverka t set t.prim=:prim
            where t.nom_abon=:nom_abon;
        end
    commit;
--------------------------------------------------------------------------------
  finally
    ibec_CloseConnection(DB);
  end;
  ibec_Progress('Готово...');
  execute ibeblock AddLog(log_fs, 'Готово...');
end

