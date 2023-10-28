DECLARE
  v_sql VARCHAR2(4000);
BEGIN
  FOR i IN 1..100 LOOP
    v_sql := 'INSERT INTO MC_SGV_SAC(NR_SAC, NR_CLIENTE, CD_PRODUTO, CD_FUNCIONARIO, DS_DETALHADA_SAC, DT_ABERTURA_SAC, HR_ABERTURA_SAC, DT_ATENDIMENTO, HR_ATENDIMENTO_SAC, TP_SAC, ST_SAC) ' ||
             'VALUES (SQ_MC_SGV_SAC.NEXTVAL, ' || TO_NUMBER(MOD(i, 15) + 1) || ', ' || TO_NUMBER(MOD(i, 20) + 1) || ', ' || TO_NUMBER(MOD(i, 44) + 1) || ', ''Detalhes do SAC ' || i || ''', sysdate-' || TO_NUMBER(MOD(i, 30)) || ', ' || TO_NUMBER(MOD(i, 24)) || ', sysdate-' || TO_NUMBER(MOD(i, 30)) || ', ' || TO_NUMBER(MOD(i, 24)) || ', ' ||
             'CASE MOD(' || i || ', 3) WHEN 0 THEN ''S'' WHEN 1 THEN ''D'' WHEN 2 THEN ''E'' END, ' ||
             'CASE MOD(' || i || ', 2) WHEN 0 THEN ''A'' WHEN 1 THEN ''F'' END)';
    EXECUTE IMMEDIATE v_sql;
  END LOOP;
  COMMIT;
END;
/
