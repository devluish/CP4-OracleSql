/*
CP 1 - ENTREGA DIA 23/03
LUIS HENRIQUE RM552692
SABRINA CAFÉ RM553568
MATHEUS DUARTE RM554199
*/

CREATE TABLE TB_Pedido AS 
SELECT * FROM PF1788.PEDIDO;

SELECT COUNT(*) FROM TB_Pedido;--QUANTOS RESULTADOS APARECERAM

--CONFERINDO OS RESULTADOS NA TABELA DO PROFESSOR...
SELECT * FROM TB_Pedido FETCH FIRST 40 ROWS ONLY; 

DESC TB_Pedido;

--  staging (temporária) com limpeza dos dados
CREATE TABLE STG_PEDIDO_CLEAN AS
SELECT 
    COD_PEDIDO,
    NVL(COD_CLIENTE, 0) AS COD_CLIENTE, -- cliente genérico
    NVL(COD_VENDEDOR, 0) AS COD_VENDEDOR, -- vendedor genérico
    NVL(VAL_TOTAL_PEDIDO, 0) AS VAL_TOTAL_PEDIDO,
    NVL(VAL_DESCONTO, 0) AS VAL_DESCONTO,
    NVL(STATUS, 'Não Informado') AS STATUS,
    DAT_PEDIDO AS DATA_VENDA
FROM TB_PEDIDO
WHERE COD_PEDIDO IS NOT NULL;


/**************************************************************************/

SET SERVEROUTPUT ON;

-- DROP das tabelas na ordem correta (evitando erro de FK)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE FATO_VENDAS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DIM_CLIENTE CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE DIM_VENDEDOR CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE DIM_PRODUTO CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE DIM_STATUS CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE DIM_PAGAMENTO CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/



-- EX 1: Desenvolvimento do Modelo Estrela com colunas adicionais para análise no Power BI

-- Tabela de Dimensão: CLIENTE
CREATE TABLE DIM_CLIENTE (
    COD_CLIENTE NUMBER(10,0) NOT NULL ENABLE,
    NOME_CLIENTE VARCHAR2(100 BYTE),
    PERFIL_CONSUMO VARCHAR2(50 BYTE),
    ESTADO VARCHAR2(50 BYTE), -- Adicionado: necessário para segmentar vendas por estado no Power BI
    CONSTRAINT PK_DIM_CLIENTE PRIMARY KEY (COD_CLIENTE)
);

-- Tabela de Dimensão: VENDEDOR
CREATE TABLE DIM_VENDEDOR (
    COD_VENDEDOR NUMBER(4,0) NOT NULL ENABLE,
    NOME_VENDEDOR VARCHAR2(100 BYTE),
    CONSTRAINT PK_DIM_VENDEDOR PRIMARY KEY (COD_VENDEDOR)
);

-- Tabela de Dimensão: PRODUTO
CREATE TABLE DIM_PRODUTO (
    COD_PRODUTO NUMBER(10,0) NOT NULL ENABLE,
    NOME_PRODUTO VARCHAR2(100 BYTE),
    CATEGORIA VARCHAR2(50 BYTE),
    CONSTRAINT PK_DIM_PRODUTO PRIMARY KEY (COD_PRODUTO)
);

-- Tabela de Dimensão: STATUS
CREATE TABLE DIM_STATUS (
    COD_STATUS NUMBER(5,0) NOT NULL ENABLE,
    DESCRICAO_STATUS VARCHAR2(20 BYTE),
    CONSTRAINT PK_DIM_STATUS PRIMARY KEY (COD_STATUS)
);

-- Tabela de Dimensão: PAGAMENTO
CREATE TABLE DIM_PAGAMENTO (
    COD_PAGAMENTO NUMBER(5,0) NOT NULL ENABLE,
    FORMA_PAGAMENTO VARCHAR2(30 BYTE),
    PARCELADO VARCHAR2(3 BYTE), -- Sim/Não
    CONSTRAINT PK_DIM_PAGAMENTO PRIMARY KEY (COD_PAGAMENTO)
);

-- Tabela Fato: VENDAS
CREATE TABLE FATO_VENDAS (
    ID_VENDA NUMBER(12,0) NOT NULL ENABLE,

    COD_CLIENTE NUMBER(10,0),
    COD_VENDEDOR NUMBER(4,0),
    COD_STATUS NUMBER(5,0),
    COD_PAGAMENTO NUMBER(5,0),
    COD_PRODUTO NUMBER(10,0),

    QTD_PRODUTO_VENDIDO NUMBER(10,0),  
    VAL_TOTAL_PEDIDO NUMBER(12,2),
    VAL_DESCONTO NUMBER(12,2),

    DATA_VENDA DATE, -- Adicionado: fundamental para análise por ano/mês no Power BI

    CONSTRAINT PK_FATO_VENDAS PRIMARY KEY (ID_VENDA),
    CONSTRAINT FK_FATO_CLIENTE FOREIGN KEY (COD_CLIENTE) REFERENCES DIM_CLIENTE (COD_CLIENTE) ENABLE,
    CONSTRAINT FK_FATO_VENDEDOR FOREIGN KEY (COD_VENDEDOR) REFERENCES DIM_VENDEDOR (COD_VENDEDOR) ENABLE,
    CONSTRAINT FK_FATO_STATUS FOREIGN KEY (COD_STATUS) REFERENCES DIM_STATUS (COD_STATUS) ENABLE,
    CONSTRAINT FK_FATO_PAGAMENTO FOREIGN KEY (COD_PAGAMENTO) REFERENCES DIM_PAGAMENTO (COD_PAGAMENTO) ENABLE,
    CONSTRAINT FK_FATO_PRODUTO FOREIGN KEY (COD_PRODUTO) REFERENCES DIM_PRODUTO (COD_PRODUTO) ENABLE
);


SELECT * FROM DIM_CLIENTE;
SELECT * FROM DIM_VENDEDOR;
SELECT * FROM DIM_PRODUTO;
SELECT * FROM DIM_STATUS;
SELECT * FROM DIM_PAGAMENTO;
SELECT * FROM FATO_VENDAS;


-- EX 2: Criação de Procedures para Dimensões
-- PROCEDURE para inserir cliente com ESTADO incluso
CREATE OR REPLACE PROCEDURE INSERE_DIM_CLIENTE (
    p_cod_cliente     IN DIM_CLIENTE.COD_CLIENTE%TYPE,
    p_nome_cliente    IN DIM_CLIENTE.NOME_CLIENTE%TYPE,
    p_perfil_consumo  IN DIM_CLIENTE.PERFIL_CONSUMO%TYPE,
    p_estado          IN DIM_CLIENTE.ESTADO%TYPE -- NOVO PARÂMETRO
) IS
    v_count NUMBER;
BEGIN
    -- Validação: nome e estado não podem ser nulos
    IF p_nome_cliente IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nome do cliente não pode ser nulo.');
    END IF;

    IF p_estado IS NULL THEN
        RAISE_APPLICATION_ERROR(-20014, 'Estado do cliente não pode ser nulo.');
    END IF;

    -- Verifica duplicidade
    SELECT COUNT(*) INTO v_count
    FROM DIM_CLIENTE
    WHERE COD_CLIENTE = p_cod_cliente;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cliente já cadastrado.');
    END IF;

    -- Inserção com coluna ESTADO
    INSERT INTO DIM_CLIENTE (
        COD_CLIENTE, NOME_CLIENTE, PERFIL_CONSUMO, ESTADO
    ) VALUES (
        p_cod_cliente, p_nome_cliente, p_perfil_consumo, p_estado
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir cliente: ' || SQLERRM);
        RAISE;
END;
/

BEGIN
    INSERE_DIM_CLIENTE(1, 'Maria Souza', 'Frequente', 'SP');
    INSERE_DIM_CLIENTE(2, 'João Lima', 'Ocasional', 'RJ');
    INSERE_DIM_CLIENTE(3, 'Ana Costa', 'VIP', 'SP');
    INSERE_DIM_CLIENTE(4, 'Carlos Oliveira', 'Frequente', 'MG');
    INSERE_DIM_CLIENTE(5, 'Fernanda Dias', 'Ocasional', 'BA');
    INSERE_DIM_CLIENTE(6, 'Bruno Silva', 'VIP', 'SP');
    INSERE_DIM_CLIENTE(7, 'Juliana Martins', 'Frequente', 'RJ');
    INSERE_DIM_CLIENTE(8, 'Lucas Pereira', 'Ocasional', 'BA');
    INSERE_DIM_CLIENTE(9, 'Patrícia Mendes', 'Frequente', 'MG');
    INSERE_DIM_CLIENTE(10, 'Ricardo Almeida', 'VIP', 'SP');
    INSERE_DIM_CLIENTE(11, 'Daniela Rocha', 'Frequente', 'SP');
    INSERE_DIM_CLIENTE(12, 'Gabriel Nunes', 'Ocasional', 'RJ');
    INSERE_DIM_CLIENTE(13, 'Camila Fernandes', 'VIP', 'SP');
    INSERE_DIM_CLIENTE(14, 'Thiago Castro', 'Frequente', 'MG');
    INSERE_DIM_CLIENTE(15, 'Larissa Pinto', 'Ocasional', 'BA');
    INSERE_DIM_CLIENTE(16, 'Eduardo Ramos', 'VIP', 'SP');
    INSERE_DIM_CLIENTE(17, 'Beatriz Ribeiro', 'Frequente', 'RJ');
    INSERE_DIM_CLIENTE(18, 'Felipe Mendes', 'Ocasional', 'BA');
    INSERE_DIM_CLIENTE(19, 'Sofia Lima', 'Frequente', 'MG');
    INSERE_DIM_CLIENTE(20, 'Pedro Henrique', 'VIP', 'SP');
END;
/


--VERIFICANDO INSERÇÃO
SELECT * FROM DIM_CLIENTE;


--DIM VENDEDOR
CREATE OR REPLACE PROCEDURE INSERE_DIM_VENDEDOR (
    p_cod_vendedor    IN DIM_VENDEDOR.COD_VENDEDOR%TYPE,
    p_nome_vendedor   IN DIM_VENDEDOR.NOME_VENDEDOR%TYPE
) IS
    v_count NUMBER;
BEGIN
    -- Validação: nome obrigatório
    IF p_nome_vendedor IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nome do vendedor não pode ser nulo.');
    END IF;

    -- Verifica duplicidade
    SELECT COUNT(*) INTO v_count
    FROM DIM_VENDEDOR
    WHERE COD_VENDEDOR = p_cod_vendedor;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Vendedor já cadastrado.');
    END IF;

    -- Inserção
    INSERT INTO DIM_VENDEDOR (
        COD_VENDEDOR, NOME_VENDEDOR
    ) VALUES (
        p_cod_vendedor, p_nome_vendedor
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir vendedor: ' || SQLERRM);
        RAISE;
END;
/

--POPULANDO VENDEDOR
BEGIN
    INSERE_DIM_VENDEDOR(1, 'Carlos Mendes');
    INSERE_DIM_VENDEDOR(2, 'Fernanda Dias');
    INSERE_DIM_VENDEDOR(3, 'Rafael Oliveira');
    INSERE_DIM_VENDEDOR(4, 'Luciana Martins');
    INSERE_DIM_VENDEDOR(5, 'Paulo Henrique');
    INSERE_DIM_VENDEDOR(6, 'Tatiane Souza');
    INSERE_DIM_VENDEDOR(7, 'Roberto Silva');
    INSERE_DIM_VENDEDOR(8, 'Vanessa Lima');
    INSERE_DIM_VENDEDOR(9, 'Marcos Andrade');
    INSERE_DIM_VENDEDOR(10, 'Aline Barros');
    INSERE_DIM_VENDEDOR(11, 'Juliano Castro');
    INSERE_DIM_VENDEDOR(12, 'Patrícia Lopes');
    INSERE_DIM_VENDEDOR(13, 'Rodrigo Fernandes');
    INSERE_DIM_VENDEDOR(14, 'Carla Ribeiro');
    INSERE_DIM_VENDEDOR(15, 'Tiago Almeida');
    INSERE_DIM_VENDEDOR(16, 'Juliana Rocha');
    INSERE_DIM_VENDEDOR(17, 'Bruno Cunha');
    INSERE_DIM_VENDEDOR(18, 'Camila Vieira');
    INSERE_DIM_VENDEDOR(19, 'Gustavo Nogueira');
    INSERE_DIM_VENDEDOR(20, 'Débora Cardoso');
END;
/

--VERIFICANDO INSERÇÃO
SELECT * FROM DIM_VENDEDOR;


--DIM PRODUTO
CREATE OR REPLACE PROCEDURE INSERE_DIM_PRODUTO (
    p_cod_produto   IN DIM_PRODUTO.COD_PRODUTO%TYPE,
    p_nome_produto  IN DIM_PRODUTO.NOME_PRODUTO%TYPE,
    p_categoria     IN DIM_PRODUTO.CATEGORIA%TYPE
) IS
    v_count NUMBER;
BEGIN
    -- Validação de campos obrigatórios
    IF p_nome_produto IS NULL OR p_categoria IS NULL THEN
        RAISE_APPLICATION_ERROR(-20005, 'Nome e categoria do produto são obrigatórios.');
    END IF;

    -- Verifica duplicidade
    SELECT COUNT(*) INTO v_count
    FROM DIM_PRODUTO
    WHERE COD_PRODUTO = p_cod_produto;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Produto já cadastrado.');
    END IF;

    -- Inserção
    INSERT INTO DIM_PRODUTO (
        COD_PRODUTO, NOME_PRODUTO, CATEGORIA
    ) VALUES (
        p_cod_produto, p_nome_produto, p_categoria
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir produto: ' || SQLERRM);
        RAISE;
END;
/

--POPULANDO
BEGIN
    INSERE_DIM_PRODUTO(1001, 'Escova Dental Ultra', 'Higiene Bucal');
    INSERE_DIM_PRODUTO(1002, 'Creme Dental MaxFresh', 'Higiene Bucal');
    INSERE_DIM_PRODUTO(1003, 'Enxaguante Bucal Menta', 'Higiene Bucal');
    INSERE_DIM_PRODUTO(1004, 'Fio Dental SuperFino', 'Higiene Bucal');
    INSERE_DIM_PRODUTO(1005, 'Kit Clareamento Caseiro', 'Estética');
    INSERE_DIM_PRODUTO(1006, 'Protetor Bucal Esportivo', 'Proteção');
    INSERE_DIM_PRODUTO(1007, 'Pastilha Refrescante', 'Acessórios');
    INSERE_DIM_PRODUTO(1008, 'Creme Dental Infantil', 'Infantil');
    INSERE_DIM_PRODUTO(1009, 'Escova Elétrica', 'Tecnologia');
    INSERE_DIM_PRODUTO(1010, 'Kit Tratamento Gengiva', 'Tratamento');
    INSERE_DIM_PRODUTO(1011, 'Spray Refrescante Bucal', 'Acessórios');
    INSERE_DIM_PRODUTO(1012, 'Clareador Dental Noturno', 'Estética');
    INSERE_DIM_PRODUTO(1013, 'Escova Ortodôntica', 'Higiene Bucal');
    INSERE_DIM_PRODUTO(1014, 'Enxaguante Bucal Infantil', 'Infantil');
    INSERE_DIM_PRODUTO(1015, 'Fita Dental Menta', 'Higiene Bucal');
    INSERE_DIM_PRODUTO(1016, 'Irrigador Oral Portátil', 'Tecnologia');
    INSERE_DIM_PRODUTO(1017, 'Gel Dental Calmante', 'Tratamento');
    INSERE_DIM_PRODUTO(1018, 'Kit Proteção Anti-Cárie', 'Proteção');
    INSERE_DIM_PRODUTO(1019, 'Creme Dental Sem Flúor', 'Higiene Bucal');
    INSERE_DIM_PRODUTO(1020, 'Escova Ecológica Bambu', 'Sustentável');
END;
/

--VERIFICANDO INSERÇÃO
SELECT * FROM DIM_PRODUTO;


--DIM STATUS
CREATE OR REPLACE PROCEDURE INSERE_DIM_STATUS (
    p_cod_status        IN DIM_STATUS.COD_STATUS%TYPE,
    p_descricao_status  IN DIM_STATUS.DESCRICAO_STATUS%TYPE
) IS
    v_count NUMBER;
BEGIN
    -- Validação de campo obrigatório
    IF p_descricao_status IS NULL THEN
        RAISE_APPLICATION_ERROR(-20007, 'Descrição do status é obrigatória.');
    END IF;

    -- Verifica duplicidade
    SELECT COUNT(*) INTO v_count
    FROM DIM_STATUS
    WHERE COD_STATUS = p_cod_status;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Status já cadastrado.');
    END IF;

    -- Inserção
    INSERT INTO DIM_STATUS (
        COD_STATUS, DESCRICAO_STATUS
    ) VALUES (
        p_cod_status, p_descricao_status
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir status: ' || SQLERRM);
        RAISE;
END;
/

--POPULANDO STATUS
BEGIN
    INSERE_DIM_STATUS(1,  'Processando');
    INSERE_DIM_STATUS(2,  'Concluído');
    INSERE_DIM_STATUS(3,  'Pendente');
    INSERE_DIM_STATUS(4,  'Cancelado');
    INSERE_DIM_STATUS(5,  'Em análise');
    INSERE_DIM_STATUS(6,  'Reembolsado');
    INSERE_DIM_STATUS(7,  'Aguard. pagamento');
    INSERE_DIM_STATUS(8,  'Entregue');
    INSERE_DIM_STATUS(9,  'Em transporte');
    INSERE_DIM_STATUS(10, 'Falha na entrega');
    INSERE_DIM_STATUS(11, 'Separando pedido');
    INSERE_DIM_STATUS(12, 'Aguard. retirada');
    INSERE_DIM_STATUS(13, 'Saiu p/ entrega');
    INSERE_DIM_STATUS(14, 'Devolvido');
    INSERE_DIM_STATUS(15, 'Troca andamento');
    INSERE_DIM_STATUS(16, 'Pagto confirmado');
    INSERE_DIM_STATUS(17, 'Rota de entrega');
    INSERE_DIM_STATUS(18, 'Agend. realizado');
    INSERE_DIM_STATUS(19, 'Indisponível');
    INSERE_DIM_STATUS(20, 'Aguard. estoque');
END;
/


--VERIFICANDO
SELECT * FROM DIM_STATUS;


--DIM PAGAMENTO
CREATE OR REPLACE PROCEDURE INSERE_DIM_PAGAMENTO (
    p_cod_pagamento     IN DIM_PAGAMENTO.COD_PAGAMENTO%TYPE,
    p_forma_pagamento   IN DIM_PAGAMENTO.FORMA_PAGAMENTO%TYPE,
    p_parcelado         IN DIM_PAGAMENTO.PARCELADO%TYPE
) IS
    v_count NUMBER;
BEGIN
    -- Validação de campos obrigatórios
    IF p_forma_pagamento IS NULL THEN
        RAISE_APPLICATION_ERROR(-20009, 'Forma de pagamento é obrigatória.');
    END IF;

    IF p_parcelado NOT IN ('Sim', 'Não') THEN
        RAISE_APPLICATION_ERROR(-20010, 'Valor de "parcelado" deve ser Sim ou Não.');
    END IF;

    -- Verifica duplicidade
    SELECT COUNT(*) INTO v_count
    FROM DIM_PAGAMENTO
    WHERE COD_PAGAMENTO = p_cod_pagamento;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Forma de pagamento já cadastrada.');
    END IF;

    -- Inserção
    INSERT INTO DIM_PAGAMENTO (
        COD_PAGAMENTO, FORMA_PAGAMENTO, PARCELADO
    ) VALUES (
        p_cod_pagamento, p_forma_pagamento, p_parcelado
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir forma de pagamento: ' || SQLERRM);
        RAISE;
END;
/


--PRECISEI ALTERAR O TAMANHO DA COLUNA
ALTER TABLE DIM_PAGAMENTO MODIFY FORMA_PAGAMENTO VARCHAR2(40 BYTE);
ALTER TABLE DIM_PAGAMENTO MODIFY PARCELADO VARCHAR2(5 BYTE); -- Garante compatibilidade



--POPULANDO DIM PAGAMENTO
BEGIN
    INSERE_DIM_PAGAMENTO(1,  'Cartão de Crédito', 'Sim');
    INSERE_DIM_PAGAMENTO(2,  'Cartão de Débito', 'Não');
    INSERE_DIM_PAGAMENTO(3,  'PIX', 'Não');
    INSERE_DIM_PAGAMENTO(4,  'Boleto Bancário', 'Não');
    INSERE_DIM_PAGAMENTO(5,  'Transferência Bancária', 'Não');
    INSERE_DIM_PAGAMENTO(6,  'Dinheiro', 'Não');
    INSERE_DIM_PAGAMENTO(7,  'Cheque', 'Não');
    INSERE_DIM_PAGAMENTO(8,  'Carteira Digital', 'Sim');
    INSERE_DIM_PAGAMENTO(9,  'Parcelamento Loja', 'Sim');
    INSERE_DIM_PAGAMENTO(10, 'Pagamento na Entrega', 'Não');
    INSERE_DIM_PAGAMENTO(11, 'Vale Refeição', 'Não');
    INSERE_DIM_PAGAMENTO(12, 'Vale Alimentação', 'Não');
    INSERE_DIM_PAGAMENTO(13, 'Cartão Corporativo', 'Sim');
    INSERE_DIM_PAGAMENTO(14, 'QR Code', 'Não');
    INSERE_DIM_PAGAMENTO(15, 'Débito Automático', 'Não');
    INSERE_DIM_PAGAMENTO(16, 'Link de Pagamento', 'Não');
    INSERE_DIM_PAGAMENTO(17, 'Pagamento Agendado', 'Não');
    INSERE_DIM_PAGAMENTO(18, 'Gift Card', 'Não');
    INSERE_DIM_PAGAMENTO(19, 'Recarga Celular', 'Não');
    INSERE_DIM_PAGAMENTO(20, 'Cartão Pré-pago', 'Sim');
END;
/


--VERIFICANDO INSERÇÃO
SELECT * FROM DIM_PAGAMENTO;


-- Procedure para inserir registros na tabela de FATO_VENDAS
CREATE OR REPLACE PROCEDURE INSERE_FATO_VENDAS (
    p_id_venda             IN FATO_VENDAS.ID_VENDA%TYPE,            -- Identificador único da venda
    p_cod_cliente          IN FATO_VENDAS.COD_CLIENTE%TYPE,         -- Código do cliente (chave estrangeira)
    p_cod_vendedor         IN FATO_VENDAS.COD_VENDEDOR%TYPE,        -- Código do vendedor (chave estrangeira)
    p_cod_status           IN FATO_VENDAS.COD_STATUS%TYPE,          -- Código do status (chave estrangeira)
    p_cod_pagamento        IN FATO_VENDAS.COD_PAGAMENTO%TYPE,       -- Código da forma de pagamento (chave estrangeira)
    p_cod_produto          IN FATO_VENDAS.COD_PRODUTO%TYPE,         -- Código do produto (chave estrangeira)
    p_qtd_produto_vendido  IN FATO_VENDAS.QTD_PRODUTO_VENDIDO%TYPE, -- Quantidade vendida
    p_val_total_pedido     IN FATO_VENDAS.VAL_TOTAL_PEDIDO%TYPE,    -- Valor total do pedido
    p_val_desconto         IN FATO_VENDAS.VAL_DESCONTO%TYPE,        -- Valor de desconto aplicado
    p_data_venda           IN FATO_VENDAS.DATA_VENDA%TYPE           -- Data da venda (para análise por mês/ano)
) IS
    v_count NUMBER; -- Variável auxiliar para validação de duplicidade
BEGIN
    -- Regra de negócio: quantidade precisa ser positiva
    IF p_qtd_produto_vendido <= 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Quantidade vendida deve ser maior que zero.');
    END IF;

    -- Verifica se o ID_VENDA já existe para evitar duplicidade
    SELECT COUNT(*) INTO v_count
    FROM FATO_VENDAS
    WHERE ID_VENDA = p_id_venda;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Venda já cadastrada.');
    END IF;

    -- Inserção do novo registro
    INSERT INTO FATO_VENDAS (
        ID_VENDA, COD_CLIENTE, COD_VENDEDOR, COD_STATUS, COD_PAGAMENTO,
        COD_PRODUTO, QTD_PRODUTO_VENDIDO, VAL_TOTAL_PEDIDO, VAL_DESCONTO, DATA_VENDA
    ) VALUES (
        p_id_venda, p_cod_cliente, p_cod_vendedor, p_cod_status, p_cod_pagamento,
        p_cod_produto, p_qtd_produto_vendido, p_val_total_pedido, p_val_desconto, p_data_venda
    );

EXCEPTION
    -- Captura erros inesperados e exibe no console
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir venda: ' || SQLERRM);
        RAISE;
END;
/


BEGIN
    INSERE_FATO_VENDAS(
        p_id_venda => 1001,
        p_cod_cliente => 1,
        p_cod_vendedor => 10,
        p_cod_status => 2,
        p_cod_pagamento => 1,
        p_cod_produto => 1001,
        p_qtd_produto_vendido => 2,
        p_val_total_pedido => TO_NUMBER('25.00', '9999.99'),
        p_val_desconto => TO_NUMBER('5.00', '9999.99'),
        p_data_venda => TO_DATE('2024-03-10', 'YYYY-MM-DD')
    );
END;
/

--SELECT para garantir que a tabela FATO_VENDAS não tem nenhum NOT NULL oculto ou restrição com valor inválido

SELECT column_name, nullable, data_type, data_precision, data_scale
FROM user_tab_columns
WHERE table_name = 'FATO_VENDAS';


SELECT * FROM FATO_VENDAS ORDER BY ID_VENDA;


--EX3: Carregamento de Dados

--CLIENTE
-- Popula a dimensão de clientes com dados "genéricos" (para manter integridade referencial)
INSERT INTO DIM_CLIENTE (
    COD_CLIENTE,
    NOME_CLIENTE,
    PERFIL_CONSUMO,
    ESTADO
)
SELECT DISTINCT
    COD_CLIENTE,
    'Cliente Desconhecido', -- Vem da tabela base de pedidos
    'Não classificado', -- Nome fictício (não temos nome real)
    'Desconhecido' -- Perfil genérico padrão
FROM TABELA_DE_PEDIDOS
WHERE COD_CLIENTE IS NOT NULL
  AND COD_CLIENTE NOT IN (
      SELECT COD_CLIENTE FROM DIM_CLIENTE
  );

-- VENDEDOR
-- Popula a dimensão de vendedores com valores padrão ("desconhecido")
-- Garante que todos os pedidos da tabela base tenham correspondência na dimensão
INSERT INTO DIM_VENDEDOR (
    COD_VENDEDOR,
    NOME_VENDEDOR
)
SELECT DISTINCT
    COD_VENDEDOR,
    'Vendedor Desconhecido'     -- Nome genérico
FROM TABELA_DE_PEDIDOS
WHERE COD_VENDEDOR IS NOT NULL
  AND COD_VENDEDOR NOT IN (
      SELECT COD_VENDEDOR FROM DIM_VENDEDOR
  );

--STATUS
INSERT INTO DIM_STATUS (COD_STATUS, DESCRICAO_STATUS)
SELECT 
    ROWNUM + (SELECT NVL(MAX(COD_STATUS), 0) FROM DIM_STATUS) AS COD_STATUS,
    STATUS
FROM (
    SELECT DISTINCT STATUS
    FROM TABELA_DE_PEDIDOS
    WHERE STATUS IS NOT NULL
      AND STATUS NOT IN (SELECT DESCRICAO_STATUS FROM DIM_STATUS)
);
/*
A subquery (SELECT NVL(MAX(COD_STATUS), 0) FROM DIM_STATUS) retorna o maior código atual de status.

O ROWNUM é somado a esse valor, garantindo que cada novo STATUS receba um código único e sequencial.

Evita erro de duplicidade de chave primária.
*/


--PAGAMENTO
DECLARE
    v_novo_codigo NUMBER;
BEGIN
    SELECT NVL(MAX(COD_PAGAMENTO), 0) + 1 INTO v_novo_codigo FROM DIM_PAGAMENTO;

    INSERT INTO DIM_PAGAMENTO (COD_PAGAMENTO, FORMA_PAGAMENTO, PARCELADO)
    VALUES (v_novo_codigo, 'Vale Refeição', 'Não');
END;
/


--PRODUTO
DECLARE
    v_novo_codigo NUMBER;
BEGIN
    SELECT NVL(MAX(COD_PRODUTO), 1000) + 1 INTO v_novo_codigo FROM DIM_PRODUTO;

    INSERT INTO DIM_PRODUTO (COD_PRODUTO, NOME_PRODUTO, CATEGORIA)
    VALUES (v_novo_codigo, 'Spray Refrescante Bucal', 'Acessórios');
END;
/


--CLIENTES
SELECT * FROM DIM_CLIENTE ORDER BY COD_CLIENTE;
--VENDEDORES
SELECT * FROM DIM_VENDEDOR ORDER BY COD_VENDEDOR;
--PRODUTO
SELECT * FROM DIM_PRODUTO ORDER BY COD_PRODUTO;
--STATUS
SELECT * FROM DIM_STATUS ORDER BY COD_STATUS;
--PAGAMENTO
SELECT * FROM DIM_PAGAMENTO ORDER BY COD_PAGAMENTO;


INSERT INTO FATO_VENDAS (
    ID_VENDA,
    COD_CLIENTE,
    COD_VENDEDOR,
    COD_STATUS,
    COD_PAGAMENTO,
    COD_PRODUTO,
    QTD_PRODUTO_VENDIDO,
    VAL_TOTAL_PEDIDO,
    VAL_DESCONTO,
    DATA_VENDA
)
SELECT
    p.COD_PEDIDO,
    p.COD_CLIENTE,
    p.COD_VENDEDOR,
    (
        SELECT s.COD_STATUS
        FROM DIM_STATUS s
        WHERE s.DESCRICAO_STATUS = p.STATUS
    ) AS COD_STATUS,
    1,            -- COD_PAGAMENTO fixo (ex: 'PIX')
    1001,         -- COD_PRODUTO fixo (Produto Genérico)
    1,            -- QTD_PRODUTO_VENDIDO assumido como 1
    p.VAL_TOTAL_PEDIDO,
    p.VAL_DESCONTO,
    p.DAT_PEDIDO   -- <- Adicionado corretamente
FROM TABELA_DE_PEDIDOS p
WHERE p.COD_PEDIDO NOT IN (
    SELECT ID_VENDA FROM FATO_VENDAS
);


--EX4: Empacotamento das Procedures e Objetos

-- Package spec para consolidar todas as procedures de ETL
CREATE OR REPLACE PACKAGE PKG_ETL_VENDAS AS

    -- Inserção de dados na dimensão CLIENTE
    PROCEDURE INSERE_DIM_CLIENTE(
        p_cod_cliente     IN DIM_CLIENTE.COD_CLIENTE%TYPE,
        p_nome_cliente    IN DIM_CLIENTE.NOME_CLIENTE%TYPE,
        p_perfil_consumo  IN DIM_CLIENTE.PERFIL_CONSUMO%TYPE
    );

    -- Inserção de dados na dimensão VENDEDOR
    PROCEDURE INSERE_DIM_VENDEDOR(
        p_cod_vendedor   IN DIM_VENDEDOR.COD_VENDEDOR%TYPE,
        p_nome_vendedor  IN DIM_VENDEDOR.NOME_VENDEDOR%TYPE
    );

    -- Inserção de dados na dimensão PRODUTO
    PROCEDURE INSERE_DIM_PRODUTO(
        p_cod_produto   IN DIM_PRODUTO.COD_PRODUTO%TYPE,
        p_nome_produto  IN DIM_PRODUTO.NOME_PRODUTO%TYPE,
        p_categoria     IN DIM_PRODUTO.CATEGORIA%TYPE
    );

    -- Inserção de dados na dimensão STATUS
    PROCEDURE INSERE_DIM_STATUS(
        p_cod_status        IN DIM_STATUS.COD_STATUS%TYPE,
        p_descricao_status  IN DIM_STATUS.DESCRICAO_STATUS%TYPE
    );

    -- Inserção de dados na dimensão PAGAMENTO
    PROCEDURE INSERE_DIM_PAGAMENTO(
        p_cod_pagamento     IN DIM_PAGAMENTO.COD_PAGAMENTO%TYPE,
        p_forma_pagamento   IN DIM_PAGAMENTO.FORMA_PAGAMENTO%TYPE,
        p_parcelado         IN DIM_PAGAMENTO.PARCELADO%TYPE
    );

    -- Inserção de dados na tabela fato VENDAS
    PROCEDURE INSERE_FATO_VENDAS(
        p_id_venda             IN FATO_VENDAS.ID_VENDA%TYPE,
        p_cod_cliente          IN FATO_VENDAS.COD_CLIENTE%TYPE,
        p_cod_vendedor         IN FATO_VENDAS.COD_VENDEDOR%TYPE,
        p_cod_status           IN FATO_VENDAS.COD_STATUS%TYPE,
        p_cod_pagamento        IN FATO_VENDAS.COD_PAGAMENTO%TYPE,
        p_cod_produto          IN FATO_VENDAS.COD_PRODUTO%TYPE,
        p_qtd_produto_vendido  IN FATO_VENDAS.QTD_PRODUTO_VENDIDO%TYPE,
        p_val_total_pedido     IN FATO_VENDAS.VAL_TOTAL_PEDIDO%TYPE,
        p_val_desconto         IN FATO_VENDAS.VAL_DESCONTO%TYPE,
        p_data_venda           IN FATO_VENDAS.DATA_VENDA%TYPE -- Adicionado para análise por tempo
    );

    -- Procedure opcional para executar o processo completo
    PROCEDURE ETL_COMPLETO;

END PKG_ETL_VENDAS;
/



--CORPO DO PKG BODY
CREATE OR REPLACE PACKAGE BODY PKG_ETL_VENDAS AS

    -- INSERE_DIM_CLIENTE com 4 colunas
PROCEDURE INSERE_DIM_CLIENTE(
    p_cod_cliente     IN DIM_CLIENTE.COD_CLIENTE%TYPE,
    p_nome_cliente    IN DIM_CLIENTE.NOME_CLIENTE%TYPE,
    p_perfil_consumo  IN DIM_CLIENTE.PERFIL_CONSUMO%TYPE
) IS
    v_count NUMBER;
BEGIN
    IF p_nome_cliente IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nome do cliente não pode ser nulo.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM DIM_CLIENTE WHERE COD_CLIENTE = p_cod_cliente;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cliente já cadastrado.');
    END IF;

    -- Adicionado ESTADO como 'Desconhecido' por padrão
    INSERT INTO DIM_CLIENTE VALUES (p_cod_cliente, p_nome_cliente, p_perfil_consumo, 'Desconhecido');
END;

-- Adicione ao final do package body
PROCEDURE ETL_COMPLETO IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Procedimento ETL completo em construção.');
END;

    PROCEDURE INSERE_DIM_VENDEDOR(
    p_cod_vendedor   IN DIM_VENDEDOR.COD_VENDEDOR%TYPE,
    p_nome_vendedor  IN DIM_VENDEDOR.NOME_VENDEDOR%TYPE
) IS
    v_count NUMBER;
BEGIN
    IF p_nome_vendedor IS NULL THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nome do vendedor não pode ser nulo.');
    END IF;

    SELECT COUNT(*) INTO v_count FROM DIM_VENDEDOR WHERE COD_VENDEDOR = p_cod_vendedor;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Vendedor já cadastrado.');
    END IF;

    INSERT INTO DIM_VENDEDOR VALUES (p_cod_vendedor, p_nome_vendedor);
END;



    PROCEDURE INSERE_DIM_PRODUTO(
        p_cod_produto   IN DIM_PRODUTO.COD_PRODUTO%TYPE,
        p_nome_produto  IN DIM_PRODUTO.NOME_PRODUTO%TYPE,
        p_categoria     IN DIM_PRODUTO.CATEGORIA%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_nome_produto IS NULL OR p_categoria IS NULL THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nome e categoria do produto são obrigatórios.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM DIM_PRODUTO WHERE COD_PRODUTO = p_cod_produto;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Produto já cadastrado.');
        END IF;

        INSERT INTO DIM_PRODUTO VALUES (p_cod_produto, p_nome_produto, p_categoria);
    END;

    PROCEDURE INSERE_DIM_STATUS(
        p_cod_status        IN DIM_STATUS.COD_STATUS%TYPE,
        p_descricao_status  IN DIM_STATUS.DESCRICAO_STATUS%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_descricao_status IS NULL THEN
            RAISE_APPLICATION_ERROR(-20007, 'Descrição do status é obrigatória.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM DIM_STATUS WHERE COD_STATUS = p_cod_status;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Status já cadastrado.');
        END IF;

        INSERT INTO DIM_STATUS VALUES (p_cod_status, p_descricao_status);
    END;

    PROCEDURE INSERE_DIM_PAGAMENTO(
        p_cod_pagamento     IN DIM_PAGAMENTO.COD_PAGAMENTO%TYPE,
        p_forma_pagamento   IN DIM_PAGAMENTO.FORMA_PAGAMENTO%TYPE,
        p_parcelado         IN DIM_PAGAMENTO.PARCELADO%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_forma_pagamento IS NULL THEN
            RAISE_APPLICATION_ERROR(-20009, 'Forma de pagamento é obrigatória.');
        END IF;

        IF p_parcelado NOT IN ('Sim', 'Não') THEN
            RAISE_APPLICATION_ERROR(-20010, 'Valor de "parcelado" deve ser Sim ou Não.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM DIM_PAGAMENTO WHERE COD_PAGAMENTO = p_cod_pagamento;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Forma de pagamento já cadastrada.');
        END IF;

        INSERT INTO DIM_PAGAMENTO VALUES (p_cod_pagamento, p_forma_pagamento, p_parcelado);
    END;

       PROCEDURE INSERE_FATO_VENDAS(
    p_id_venda             IN FATO_VENDAS.ID_VENDA%TYPE,
    p_cod_cliente          IN FATO_VENDAS.COD_CLIENTE%TYPE,
    p_cod_vendedor         IN FATO_VENDAS.COD_VENDEDOR%TYPE,
    p_cod_status           IN FATO_VENDAS.COD_STATUS%TYPE,
    p_cod_pagamento        IN FATO_VENDAS.COD_PAGAMENTO%TYPE,
    p_cod_produto          IN FATO_VENDAS.COD_PRODUTO%TYPE,
    p_qtd_produto_vendido  IN FATO_VENDAS.QTD_PRODUTO_VENDIDO%TYPE,
    p_val_total_pedido     IN FATO_VENDAS.VAL_TOTAL_PEDIDO%TYPE,
    p_val_desconto         IN FATO_VENDAS.VAL_DESCONTO%TYPE,
    p_data_venda           IN FATO_VENDAS.DATA_VENDA%TYPE
) IS
    v_count NUMBER;
BEGIN
    IF p_qtd_produto_vendido <= 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Quantidade vendida deve ser maior que zero.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM FATO_VENDAS
    WHERE ID_VENDA = p_id_venda;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Venda já cadastrada.');
    END IF;

    INSERT INTO FATO_VENDAS (
        ID_VENDA, COD_CLIENTE, COD_VENDEDOR, COD_STATUS, COD_PAGAMENTO,
        COD_PRODUTO, QTD_PRODUTO_VENDIDO, VAL_TOTAL_PEDIDO, VAL_DESCONTO, DATA_VENDA
    ) VALUES (
        p_id_venda, p_cod_cliente, p_cod_vendedor, p_cod_status, p_cod_pagamento,
        p_cod_produto, p_qtd_produto_vendido, p_val_total_pedido, p_val_desconto, p_data_venda
    );
END;


END PKG_ETL_VENDAS;
/

-- Verificando erros 
SHOW ERRORS PACKAGE BODY PKG_ETL_VENDAS;


--Corrigindo
CREATE OR REPLACE PACKAGE PKG_ETL_VENDAS AS
    PROCEDURE INSERE_DIM_CLIENTE(
        p_cod_cliente     IN DIM_CLIENTE.COD_CLIENTE%TYPE,
        p_nome_cliente    IN DIM_CLIENTE.NOME_CLIENTE%TYPE,
        p_perfil_consumo  IN DIM_CLIENTE.PERFIL_CONSUMO%TYPE,
        p_estado          IN DIM_CLIENTE.ESTADO%TYPE
    );

    PROCEDURE INSERE_DIM_VENDEDOR(
        p_cod_vendedor   IN DIM_VENDEDOR.COD_VENDEDOR%TYPE,
        p_nome_vendedor  IN DIM_VENDEDOR.NOME_VENDEDOR%TYPE
    );

    PROCEDURE INSERE_DIM_PRODUTO(
        p_cod_produto   IN DIM_PRODUTO.COD_PRODUTO%TYPE,
        p_nome_produto  IN DIM_PRODUTO.NOME_PRODUTO%TYPE,
        p_categoria     IN DIM_PRODUTO.CATEGORIA%TYPE
    );

    PROCEDURE INSERE_DIM_STATUS(
        p_cod_status        IN DIM_STATUS.COD_STATUS%TYPE,
        p_descricao_status  IN DIM_STATUS.DESCRICAO_STATUS%TYPE
    );

    PROCEDURE INSERE_DIM_PAGAMENTO(
        p_cod_pagamento     IN DIM_PAGAMENTO.COD_PAGAMENTO%TYPE,
        p_forma_pagamento   IN DIM_PAGAMENTO.FORMA_PAGAMENTO%TYPE,
        p_parcelado         IN DIM_PAGAMENTO.PARCELADO%TYPE
    );

    PROCEDURE INSERE_FATO_VENDAS(
        p_id_venda             IN FATO_VENDAS.ID_VENDA%TYPE,
        p_cod_cliente          IN FATO_VENDAS.COD_CLIENTE%TYPE,
        p_cod_vendedor         IN FATO_VENDAS.COD_VENDEDOR%TYPE,
        p_cod_status           IN FATO_VENDAS.COD_STATUS%TYPE,
        p_cod_pagamento        IN FATO_VENDAS.COD_PAGAMENTO%TYPE,
        p_cod_produto          IN FATO_VENDAS.COD_PRODUTO%TYPE,
        p_qtd_produto_vendido  IN FATO_VENDAS.QTD_PRODUTO_VENDIDO%TYPE,
        p_val_total_pedido     IN FATO_VENDAS.VAL_TOTAL_PEDIDO%TYPE,
        p_val_desconto         IN FATO_VENDAS.VAL_DESCONTO%TYPE,
        p_data_venda           IN FATO_VENDAS.DATA_VENDA%TYPE
    );

    PROCEDURE ETL_COMPLETO;
END PKG_ETL_VENDAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_ETL_VENDAS AS

    PROCEDURE INSERE_DIM_CLIENTE(
        p_cod_cliente     IN DIM_CLIENTE.COD_CLIENTE%TYPE,
        p_nome_cliente    IN DIM_CLIENTE.NOME_CLIENTE%TYPE,
        p_perfil_consumo  IN DIM_CLIENTE.PERFIL_CONSUMO%TYPE,
        p_estado          IN DIM_CLIENTE.ESTADO%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_nome_cliente IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Nome do cliente não pode ser nulo.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM DIM_CLIENTE WHERE COD_CLIENTE = p_cod_cliente;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Cliente já cadastrado.');
        END IF;

        INSERT INTO DIM_CLIENTE (COD_CLIENTE, NOME_CLIENTE, PERFIL_CONSUMO, ESTADO)
        VALUES (p_cod_cliente, p_nome_cliente, p_perfil_consumo, p_estado);
    END;

    PROCEDURE INSERE_DIM_VENDEDOR(
        p_cod_vendedor   IN DIM_VENDEDOR.COD_VENDEDOR%TYPE,
        p_nome_vendedor  IN DIM_VENDEDOR.NOME_VENDEDOR%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_nome_vendedor IS NULL THEN
            RAISE_APPLICATION_ERROR(-20003, 'Nome do vendedor não pode ser nulo.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM DIM_VENDEDOR WHERE COD_VENDEDOR = p_cod_vendedor;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Vendedor já cadastrado.');
        END IF;

        INSERT INTO DIM_VENDEDOR VALUES (p_cod_vendedor, p_nome_vendedor);
    END;

    PROCEDURE INSERE_DIM_PRODUTO(
        p_cod_produto   IN DIM_PRODUTO.COD_PRODUTO%TYPE,
        p_nome_produto  IN DIM_PRODUTO.NOME_PRODUTO%TYPE,
        p_categoria     IN DIM_PRODUTO.CATEGORIA%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_nome_produto IS NULL OR p_categoria IS NULL THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nome e categoria do produto são obrigatórios.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM DIM_PRODUTO WHERE COD_PRODUTO = p_cod_produto;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Produto já cadastrado.');
        END IF;

        INSERT INTO DIM_PRODUTO VALUES (p_cod_produto, p_nome_produto, p_categoria);
    END;

    PROCEDURE INSERE_DIM_STATUS(
        p_cod_status        IN DIM_STATUS.COD_STATUS%TYPE,
        p_descricao_status  IN DIM_STATUS.DESCRICAO_STATUS%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_descricao_status IS NULL THEN
            RAISE_APPLICATION_ERROR(-20007, 'Descrição do status é obrigatória.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM DIM_STATUS WHERE COD_STATUS = p_cod_status;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Status já cadastrado.');
        END IF;

        INSERT INTO DIM_STATUS VALUES (p_cod_status, p_descricao_status);
    END;

    PROCEDURE INSERE_DIM_PAGAMENTO(
        p_cod_pagamento     IN DIM_PAGAMENTO.COD_PAGAMENTO%TYPE,
        p_forma_pagamento   IN DIM_PAGAMENTO.FORMA_PAGAMENTO%TYPE,
        p_parcelado         IN DIM_PAGAMENTO.PARCELADO%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_forma_pagamento IS NULL THEN
            RAISE_APPLICATION_ERROR(-20009, 'Forma de pagamento é obrigatória.');
        END IF;

        IF p_parcelado NOT IN ('Sim', 'Não') THEN
            RAISE_APPLICATION_ERROR(-20010, 'Valor de "parcelado" deve ser Sim ou Não.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM DIM_PAGAMENTO WHERE COD_PAGAMENTO = p_cod_pagamento;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Forma de pagamento já cadastrada.');
        END IF;

        INSERT INTO DIM_PAGAMENTO VALUES (p_cod_pagamento, p_forma_pagamento, p_parcelado);
    END;

    PROCEDURE INSERE_FATO_VENDAS(
        p_id_venda             IN FATO_VENDAS.ID_VENDA%TYPE,
        p_cod_cliente          IN FATO_VENDAS.COD_CLIENTE%TYPE,
        p_cod_vendedor         IN FATO_VENDAS.COD_VENDEDOR%TYPE,
        p_cod_status           IN FATO_VENDAS.COD_STATUS%TYPE,
        p_cod_pagamento        IN FATO_VENDAS.COD_PAGAMENTO%TYPE,
        p_cod_produto          IN FATO_VENDAS.COD_PRODUTO%TYPE,
        p_qtd_produto_vendido  IN FATO_VENDAS.QTD_PRODUTO_VENDIDO%TYPE,
        p_val_total_pedido     IN FATO_VENDAS.VAL_TOTAL_PEDIDO%TYPE,
        p_val_desconto         IN FATO_VENDAS.VAL_DESCONTO%TYPE,
        p_data_venda           IN FATO_VENDAS.DATA_VENDA%TYPE
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_qtd_produto_vendido <= 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'Quantidade vendida deve ser maior que zero.');
        END IF;

        SELECT COUNT(*) INTO v_count FROM FATO_VENDAS WHERE ID_VENDA = p_id_venda;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Venda já cadastrada.');
        END IF;

        INSERT INTO FATO_VENDAS (
            ID_VENDA, COD_CLIENTE, COD_VENDEDOR, COD_STATUS, COD_PAGAMENTO,
            COD_PRODUTO, QTD_PRODUTO_VENDIDO, VAL_TOTAL_PEDIDO, VAL_DESCONTO, DATA_VENDA
        ) VALUES (
            p_id_venda, p_cod_cliente, p_cod_vendedor, p_cod_status, p_cod_pagamento,
            p_cod_produto, p_qtd_produto_vendido, p_val_total_pedido, p_val_desconto, p_data_venda
        );
    END;

    PROCEDURE ETL_COMPLETO IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Procedimento de ETL completo em construção.');
    END;

END PKG_ETL_VENDAS;
/

--VISUALIZAÇÃO
SELECT OBJECT_NAME, STATUS
FROM USER_OBJECTS
WHERE OBJECT_TYPE IN ('PACKAGE', 'PACKAGE BODY')
  AND OBJECT_NAME LIKE 'PKG_ETL%';


-- TESTANDO UMA PROCEDURE
BEGIN
    PKG_ETL_VENDAS.INSERE_DIM_CLIENTE(101, 'Maria Teste', 'Frequente', 'SP');
END;


--EX5: Execução das procedures

BEGIN
    -- Venda 1
    PKG_ETL_VENDAS.INSERE_FATO_VENDAS(
        p_id_venda             => 5001,
        p_cod_cliente          => 2,     -- João Lima
        p_cod_vendedor         => 11,    -- Fernanda Dias
        p_cod_status           => 2,     -- Concluído
        p_cod_pagamento        => 1,     -- Cartão de Crédito
        p_cod_produto          => 1002,  -- Creme Dental MaxFresh
        p_qtd_produto_vendido  => 3,
        p_val_total_pedido     => 59.90,
        p_val_desconto         => 5.00,
        p_data_venda           => TO_DATE('2024-03-10', 'YYYY-MM-DD')
    );

    -- Venda 2
    PKG_ETL_VENDAS.INSERE_FATO_VENDAS(
        p_id_venda             => 5002,
        p_cod_cliente          => 5,     -- Fernanda Dias
        p_cod_vendedor         => 12,    -- Rafael Oliveira
        p_cod_status           => 3,     -- Pendente
        p_cod_pagamento        => 3,     -- PIX
        p_cod_produto          => 1006,  -- Protetor Bucal Esportivo
        p_qtd_produto_vendido  => 1,
        p_val_total_pedido     => 79.90,
        p_val_desconto         => 0.00,
        p_data_venda           => TO_DATE('2024-03-11', 'YYYY-MM-DD')
    );

    -- Venda 3
    PKG_ETL_VENDAS.INSERE_FATO_VENDAS(
        p_id_venda             => 5003,
        p_cod_cliente          => 10,    -- Ricardo Almeida
        p_cod_vendedor         => 14,    -- Paulo Henrique
        p_cod_status           => 1,     -- Processando
        p_cod_pagamento        => 9,     -- Parcelamento Loja
        p_cod_produto          => 1010,  -- Kit Tratamento Gengiva
        p_qtd_produto_vendido  => 2,
        p_val_total_pedido     => 120.00,
        p_val_desconto         => 15.00,
        p_data_venda           => TO_DATE('2024-03-12', 'YYYY-MM-DD')
    );
END;


SELECT * FROM DIM_CLIENTE ORDER BY COD_CLIENTE;
SELECT * FROM DIM_VENDEDOR ORDER BY COD_VENDEDOR;
SELECT * FROM DIM_PRODUTO ORDER BY COD_PRODUTO;
SELECT * FROM DIM_STATUS ORDER BY COD_STATUS;
SELECT * FROM DIM_PAGAMENTO ORDER BY COD_PAGAMENTO;
SELECT * FROM FATO_VENDAS ORDER BY ID_VENDA;


--TRIGGER

-- TABELA DE AUDITORIA
CREATE TABLE AUDITORIA_DIMENSOES (
    ID_AUDITORIA     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TABELA_AFETADA   VARCHAR2(30),
    ID_REGISTRO      NUMBER,
    USUARIO_BANCO    VARCHAR2(30),
    DATA_INSERCAO    DATE
);

-- TRIGGER DE AUDITORIA PARA DIM_CLIENTE
CREATE OR REPLACE TRIGGER TRG_AUDIT_DIM_CLIENTE
AFTER INSERT ON DIM_CLIENTE
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        TABELA_AFETADA, ID_REGISTRO, USUARIO_BANCO, DATA_INSERCAO
    ) VALUES (
        'DIM_CLIENTE', :NEW.COD_CLIENTE, USER, SYSDATE
    );
END;
/

-- DIM_VENDEDOR
CREATE OR REPLACE TRIGGER TRG_AUDIT_DIM_VENDEDOR
AFTER INSERT ON DIM_VENDEDOR
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        TABELA_AFETADA, ID_REGISTRO, USUARIO_BANCO, DATA_INSERCAO
    ) VALUES (
        'DIM_VENDEDOR', :NEW.COD_VENDEDOR, USER, SYSDATE
    );
END;
/

-- DIM_PRODUTO
CREATE OR REPLACE TRIGGER TRG_AUDIT_DIM_PRODUTO
AFTER INSERT ON DIM_PRODUTO
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        TABELA_AFETADA, ID_REGISTRO, USUARIO_BANCO, DATA_INSERCAO
    ) VALUES (
        'DIM_PRODUTO', :NEW.COD_PRODUTO, USER, SYSDATE
    );
END;
/

-- DIM_STATUS
CREATE OR REPLACE TRIGGER TRG_AUDIT_DIM_STATUS
AFTER INSERT ON DIM_STATUS
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        TABELA_AFETADA, ID_REGISTRO, USUARIO_BANCO, DATA_INSERCAO
    ) VALUES (
        'DIM_STATUS', :NEW.COD_STATUS, USER, SYSDATE
    );
END;
/

-- DIM_PAGAMENTO
CREATE OR REPLACE TRIGGER TRG_AUDIT_DIM_PAGAMENTO
AFTER INSERT ON DIM_PAGAMENTO
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        TABELA_AFETADA, ID_REGISTRO, USUARIO_BANCO, DATA_INSERCAO
    ) VALUES (
        'DIM_PAGAMENTO', :NEW.COD_PAGAMENTO, USER, SYSDATE
    );
END;
/

-- TESTE DE INSERÇÃO COM AUDITORIA
BEGIN
    PKG_ETL_VENDAS.INSERE_DIM_CLIENTE(999, 'Auditoria Teste', 'VIP', 'SP');
END;


