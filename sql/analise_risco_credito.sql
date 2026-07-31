-- =====================================================
-- PROJETO: Análise de Risco de Crédito
-- Autor: Silas
-- Fonte dos dados: Kaggle - Give Me Some Credit (2011)
-- =====================================================

-- Criação do banco de dados
CREATE DATABASE risco_credito;

-- Selecionando o banco para uso
USE risco_credito;

-- Criação da tabela principal com os dados tratados de clientes
CREATE TABLE clientes_credito (
    id INT PRIMARY KEY,                          -- identificador único do cliente
    inadimplente TINYINT,                        -- variável alvo: 1 = inadimplente, 0 = adimplente
    perc_uso_credito_rotativo DECIMAL(10,6),     -- % de uso do limite de crédito rotativo
    idade INT,                                   -- idade do cliente em anos
    qtd_atraso_30_59_dias INT,                   -- qtd de vezes com atraso entre 30 e 59 dias
    indice_endividamento DECIMAL(15,6),          -- índice de endividamento (dívida mensal / renda)
    renda_mensal DECIMAL(12,2),                  -- renda mensal do cliente
    qtd_creditos_abertos INT,                    -- qtd de linhas de crédito e empréstimos abertos
    qtd_atraso_90_dias INT,                      -- qtd de vezes com atraso de 90 dias ou mais
    qtd_emprestimos_imoveis INT,                 -- qtd de empréstimos/linhas imobiliárias
    qtd_atraso_60_89_dias INT,                   -- qtd de vezes com atraso entre 60 e 89 dias
    qtd_dependentes INT,                         -- qtd de dependentes do cliente
    renda_informada VARCHAR(3)                   -- indica se a renda foi originalmente informada (SIM/NÃO)
);

-- Importação dos dados tratados (CSV limpo previamente no Excel)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credito_tratado.csv'
INTO TABLE clientes_credito
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Conferência: total de registros importados (esperado: 149.731)
SELECT COUNT(*) FROM clientes_credito;

-- Conferência visual: primeiras 10 linhas da tabela
SELECT * FROM clientes_credito LIMIT 10;

-- Taxa de inadimplência por faixa etária
SELECT 
    CASE 
        WHEN idade BETWEEN 18 AND 25 THEN '18-25'
        WHEN idade BETWEEN 26 AND 35 THEN '26-35'
        WHEN idade BETWEEN 36 AND 45 THEN '36-45'
        WHEN idade BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS faixa_etaria,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
GROUP BY faixa_etaria
ORDER BY faixa_etaria;

SELECT 
    CASE 
        WHEN renda_mensal < 2000 THEN 'Até 2.000'
        WHEN renda_mensal BETWEEN 2000 AND 4000 THEN '2.000-4.000'
        WHEN renda_mensal BETWEEN 4001 AND 6000 THEN '4.001-6.000'
        WHEN renda_mensal BETWEEN 6001 AND 10000 THEN '6.001-10.000'
        ELSE 'Acima de 10.000'
    END AS faixa_renda,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
GROUP BY faixa_renda
ORDER BY MIN(renda_mensal);

-- Distribuição de idade DENTRO do grupo de renda "até 2.000"
SELECT 
    CASE 
        WHEN idade BETWEEN 18 AND 25 THEN '18-25'
        WHEN idade BETWEEN 26 AND 35 THEN '26-35'
        WHEN idade BETWEEN 36 AND 45 THEN '36-45'
        WHEN idade BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS faixa_etaria,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
WHERE renda_mensal < 2000
GROUP BY faixa_etaria
ORDER BY faixa_etaria;

-- Taxa de inadimplência por número de dependentes
SELECT 
    qtd_dependentes,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
GROUP BY qtd_dependentes
ORDER BY qtd_dependentes;

-- Taxa de inadimplência por faixa de uso do crédito rotativo
SELECT 
    CASE 
        WHEN perc_uso_credito_rotativo <= 0.3 THEN 'Baixo uso (até 30%)'
        WHEN perc_uso_credito_rotativo <= 0.6 THEN 'Uso moderado (31-60%)'
        WHEN perc_uso_credito_rotativo <= 1.0 THEN 'Uso alto (61-100%)'
        ELSE 'Acima de 100% (suspeito)'
    END AS faixa_uso_credito,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
GROUP BY faixa_uso_credito
ORDER BY MIN(perc_uso_credito_rotativo);

-- Taxa de inadimplência por faixa de índice de endividamento
SELECT 
    CASE 
        WHEN indice_endividamento <= 0.3 THEN 'Baixo (até 0.3)'
        WHEN indice_endividamento <= 0.6 THEN 'Moderado (0.31-0.6)'
        WHEN indice_endividamento <= 1.0 THEN 'Alto (0.61-1.0)'
        WHEN indice_endividamento <= 1000 THEN 'Muito alto (1.01-1000)'
        ELSE 'Acima de 1000 (suspeito)'
    END AS faixa_endividamento,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
GROUP BY faixa_endividamento
ORDER BY MIN(indice_endividamento);

-- Investigando a renda mensal do grupo com índice de endividamento "suspeito" (acima de 1000)
SELECT 
    COUNT(*) AS qtd_clientes,
    MIN(renda_mensal) AS renda_minima,
    MAX(renda_mensal) AS renda_maxima,
    ROUND(AVG(renda_mensal), 2) AS renda_media,
    ROUND(AVG(indice_endividamento), 2) AS indice_medio
FROM clientes_credito
WHERE indice_endividamento > 1000;

-- Taxa de inadimplência por quantidade de atrasos de 90+ dias
SELECT 
    qtd_atraso_90_dias,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
GROUP BY qtd_atraso_90_dias
ORDER BY qtd_atraso_90_dias;

-- Taxa de inadimplência por quantidade de atrasos de 30-59 dias
SELECT 
    CASE 
        WHEN qtd_atraso_30_59_dias = 0 THEN '0'
        WHEN qtd_atraso_30_59_dias = 1 THEN '1'
        WHEN qtd_atraso_30_59_dias = 2 THEN '2'
        WHEN qtd_atraso_30_59_dias >= 3 THEN '3+'
    END AS faixa_atraso,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
GROUP BY faixa_atraso
ORDER BY faixa_atraso;

-- Taxa de inadimplência por quantidade de atrasos de 60-89 dias
SELECT 
    CASE 
        WHEN qtd_atraso_60_89_dias = 0 THEN '0'
        WHEN qtd_atraso_60_89_dias = 1 THEN '1'
        WHEN qtd_atraso_60_89_dias = 2 THEN '2'
        WHEN qtd_atraso_60_89_dias >= 3 THEN '3+'
    END AS faixa_atraso,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(inadimplente) * 100, 2) AS taxa_inadimplencia_pct
FROM clientes_credito
GROUP BY faixa_atraso
ORDER BY faixa_atraso;

-- Criação de uma VIEW consolidada para uso no Power BI
CREATE VIEW vw_analise_credito AS
SELECT
    id,
    inadimplente,
    idade,
    CASE 
        WHEN idade BETWEEN 18 AND 25 THEN '18-25'
        WHEN idade BETWEEN 26 AND 35 THEN '26-35'
        WHEN idade BETWEEN 36 AND 45 THEN '36-45'
        WHEN idade BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS faixa_etaria,
    
    renda_mensal,
    CASE 
        WHEN renda_mensal < 2000 THEN 'Até 2.000'
        WHEN renda_mensal BETWEEN 2000 AND 4000 THEN '2.000-4.000'
        WHEN renda_mensal BETWEEN 4001 AND 6000 THEN '4.001-6.000'
        WHEN renda_mensal BETWEEN 6001 AND 10000 THEN '6.001-10.000'
        ELSE 'Acima de 10.000'
    END AS faixa_renda,
    
    perc_uso_credito_rotativo,
    CASE 
        WHEN perc_uso_credito_rotativo <= 0.3 THEN 'Baixo uso (até 30%)'
        WHEN perc_uso_credito_rotativo <= 0.6 THEN 'Uso moderado (31-60%)'
        WHEN perc_uso_credito_rotativo <= 1.0 THEN 'Uso alto (61-100%)'
        ELSE 'Acima de 100%'
    END AS faixa_uso_credito,
    
    qtd_dependentes,
    CASE 
        WHEN qtd_dependentes >= 6 THEN '6+'
        ELSE CAST(qtd_dependentes AS CHAR)
    END AS faixa_dependentes,
    
    qtd_atraso_30_59_dias,
    qtd_atraso_60_89_dias,
    qtd_atraso_90_dias,
    CASE 
        WHEN qtd_atraso_90_dias = 0 THEN '0'
        WHEN qtd_atraso_90_dias = 1 THEN '1'
        WHEN qtd_atraso_90_dias = 2 THEN '2'
        ELSE '3+'
    END AS faixa_atraso_grave,
    
    indice_endividamento,
    renda_informada
    
FROM clientes_credito;

SELECT * FROM vw_analise_credito LIMIT 10;

use risco_credito;

SELECT 
    COUNT(*) AS total_clientes,
    SUM(inadimplente) AS total_inadimplentes,
    ROUND(AVG(inadimplente) * 100, 4) AS taxa_inadimplencia_pct
FROM clientes_credito;

-- Atualizando a VIEW para incluir uma coluna auxiliar de ordenação para faixa_renda
CREATE OR REPLACE VIEW vw_analise_credito AS
SELECT
    id,
    inadimplente,
    idade,
    CASE 
        WHEN idade BETWEEN 18 AND 25 THEN '18-25'
        WHEN idade BETWEEN 26 AND 35 THEN '26-35'
        WHEN idade BETWEEN 36 AND 45 THEN '36-45'
        WHEN idade BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS faixa_etaria,
    
    renda_mensal,
    CASE 
        WHEN renda_mensal < 2000 THEN 'Até 2.000'
        WHEN renda_mensal BETWEEN 2000 AND 4000 THEN '2.000-4.000'
        WHEN renda_mensal BETWEEN 4001 AND 6000 THEN '4.001-6.000'
        WHEN renda_mensal BETWEEN 6001 AND 10000 THEN '6.001-10.000'
        ELSE 'Acima de 10.000'
    END AS faixa_renda,
    -- Coluna auxiliar numérica, só para ordenação correta no Power BI
    CASE 
        WHEN renda_mensal < 2000 THEN 1
        WHEN renda_mensal BETWEEN 2000 AND 4000 THEN 2
        WHEN renda_mensal BETWEEN 4001 AND 6000 THEN 3
        WHEN renda_mensal BETWEEN 6001 AND 10000 THEN 4
        ELSE 5
    END AS ordem_faixa_renda,
    
    perc_uso_credito_rotativo,
    CASE 
        WHEN perc_uso_credito_rotativo <= 0.3 THEN 'Baixo uso (até 30%)'
        WHEN perc_uso_credito_rotativo <= 0.6 THEN 'Uso moderado (31-60%)'
        WHEN perc_uso_credito_rotativo <= 1.0 THEN 'Uso alto (61-100%)'
        ELSE 'Acima de 100%'
    END AS faixa_uso_credito,
    
    qtd_dependentes,
    CASE 
        WHEN qtd_dependentes >= 6 THEN '6+'
        ELSE CAST(qtd_dependentes AS CHAR)
    END AS faixa_dependentes,
    
    qtd_atraso_30_59_dias,
    qtd_atraso_60_89_dias,
    qtd_atraso_90_dias,
    CASE 
        WHEN qtd_atraso_90_dias = 0 THEN '0'
        WHEN qtd_atraso_90_dias = 1 THEN '1'
        WHEN qtd_atraso_90_dias = 2 THEN '2'
        ELSE '3+'
    END AS faixa_atraso_grave,
    
    indice_endividamento,
    renda_informada
    
FROM clientes_credito;





