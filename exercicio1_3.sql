DECLARE
  -- Definicao de um record type com a estrutura de destino da tabela MC_SGV_OCORRENCIA_SAC
  TYPE tipo_ocorrencia_sac IS RECORD (
    -- Colunas que serao retornadas via cursor principal
    nr_sac mc_sgv_sac.nr_sac%TYPE,
    dt_abertura_sac mc_sgv_sac.dt_abertura_sac%TYPE,
    hr_abertura_sac mc_sgv_sac.hr_abertura_sac%TYPE,
    tp_sac mc_sgv_sac.tp_sac%TYPE,
    cd_produto mc_produto.cd_produto%TYPE,
    ds_produto mc_produto.ds_produto%TYPE,
    vl_unitario mc_produto.vl_unitario%TYPE,
    vl_perc_lucro mc_produto.vl_perc_lucro%TYPE,
    nr_cliente mc_cliente.nr_cliente%TYPE,
    nm_cliente mc_cliente.nm_cliente%TYPE,

    -- Colunas que serao retornadas em query dentro do cursor usando tabela endereco
    sg_estado mc_estado.sg_estado%TYPE,
    nm_estado mc_estado.nm_estado%TYPE,

    -- Colunas adicionais que serao calculadas dentro do cursor ou trazidos de funcao
    DS_TIPO_CLASSIFICACAO_SAC VARCHAR2(100),
    VL_UNITARIO_LUCRO NUMBER,
    VL_ICMS_PRODUTO NUMBER
  );

  VL_PERC_ICMS_ESTADO NUMBER;

  -- Declaracao da query em um cursor
  CURSOR sac_cursor IS
    SELECT
      sac.nr_sac, sac.dt_abertura_sac, sac.hr_abertura_sac, sac.tp_sac,
      prod.cd_produto, prod.ds_produto, prod.vl_unitario, prod.vl_perc_lucro,
      cli.nr_cliente, cli.nm_cliente
    FROM mc_sgv_sac sac
    JOIN mc_produto prod ON (sac.cd_produto = prod.cd_produto)
    JOIN mc_cliente cli ON (sac.nr_cliente = cli.nr_cliente);

  -- Uso do tipo de registro em uma variavel
  linha_sac tipo_ocorrencia_sac;
BEGIN
  -- Abertura de cursor para inicio da iteracao
  OPEN sac_cursor;

  -- Looping de interacao do cursor para execucao de comandos internos
  LOOP
    -- Retorna a linha da query para a variavel de registro
    FETCH sac_cursor INTO
      linha_sac.nr_sac, linha_sac.dt_abertura_sac,
      linha_sac.hr_abertura_sac, linha_sac.tp_sac,
      linha_sac.cd_produto, linha_sac.ds_produto,
      linha_sac.vl_unitario, linha_sac.vl_perc_lucro,
      linha_sac.nr_cliente, linha_sac.nm_cliente;

    -- Sair do loop quand nao houver mais linhas no cursor
    EXIT WHEN sac_cursor%NOTFOUND;


  --b.1) Classificacao do SAC
     CASE linha_sac.tp_sac
       WHEN 'S' THEN linha_sac.DS_TIPO_CLASSIFICACAO_SAC := 'SUGESTÃO';
       WHEN 'D' THEN linha_sac.DS_TIPO_CLASSIFICACAO_SAC := 'DÚVIDA';
       WHEN 'E' THEN linha_sac.DS_TIPO_CLASSIFICACAO_SAC := 'ELOGIO';
       ELSE linha_sac.DS_TIPO_CLASSIFICACAO_SAC := 'CLASSIFICAÇÃO INVÁLIDA';
     END CASE;

  --b.2) Valor unitario lucro do produto
  linha_sac.VL_UNITARIO_LUCRO := (linha_sac.vl_perc_lucro / 100 ) * linha_sac.vl_unitario;

  --b.3) Busca de Informacoes de estado com base no join e cliente que esta sendo iterado
    SELECT est.sg_estado, est.nm_estado INTO linha_sac.sg_estado, linha_sac.nm_estado
    FROM mc_end_cli ende
    JOIN mc_cliente cli ON (ende.nr_cliente = cli.nr_cliente)
    JOIN mc_logradouro logr ON (ende.cd_logradouro_cli = logr.cd_logradouro)
    JOIN mc_bairro bai ON (logr.cd_bairro = bai.cd_bairro)
    JOIN mc_cidade cid ON (bai.cd_cidade = cid.cd_cidade)
    JOIN mc_estado est ON (cid.sg_estado = est.sg_estado)
    WHERE cli.nr_cliente = linha_sac.nr_cliente;

    --b.4) Atribuicao da coluna VL_ICMS_PRODUTO usando function disponibilizada no banco FIAP
    SELECT pf0110.fun_mc_gera_aliquota_media_icms_estado(linha_sac.sg_estado) INTO VL_PERC_ICMS_ESTADO FROM dual;
    linha_sac.VL_ICMS_PRODUTO := ( VL_PERC_ICMS_ESTADO / 100 ) * linha_sac.vl_unitario;

    -- Resultado final, alimentar tabela de ocorrencias SAC
    INSERT INTO MC_SGV_OCORRENCIA_SAC (
      NR_OCORRENCIA_SAC, DT_ABERTURA_SAC, HR_ABERTURA_SAC, DS_TIPO_CLASSIFICACAO_SAC,
      CD_PRODUTO, DS_PRODUTO, VL_UNITARIO_PRODUTO, VL_PERC_LUCRO, VL_UNITARIO_LUCRO_PRODUTO,
      SG_ESTADO, NM_ESTADO, NR_CLIENTE, NM_CLIENTE, VL_ICMS_PRODUTO
    ) VALUES (
      linha_sac.nr_sac, linha_sac.dt_abertura_sac, linha_sac.hr_abertura_sac, linha_sac.DS_TIPO_CLASSIFICACAO_SAC,
      linha_sac.cd_produto, linha_sac.ds_produto, linha_sac.vl_unitario, linha_sac.vl_perc_lucro, linha_sac.VL_UNITARIO_LUCRO,
      linha_sac.sg_estado, linha_sac.nm_estado, linha_sac.nr_cliente, linha_sac.nm_cliente, linha_sac.VL_ICMS_PRODUTO
    );

  END LOOP;

  --c) Fechando o cursor
  CLOSE sac_cursor;

  --c) Commit da insercao
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    -- Gerenciamento de excecoes do cursor
    DBMS_OUTPUT.PUT_LINE('Erro ao executar cursor: ' || SQLERRM);
    ROLLBACK;
END;
/
