/*
CP 1 - ENTREGA DIA 23/03
LUIS HENRIQUE RM552692
SABRINA CAFÉ RM553568
MATHEUS DUARTE RM554199
*/

CREATE TABLE tabela_de_pedidos AS 
SELECT * FROM PF1788.PEDIDO;

SELECT COUNT(*) FROM tabela_de_pedidos;--QUANTOS RESULTADOS APARECERAM

--CONFERINDO OS RESULTADOS NA TABELA DO PROFESSOR...
SELECT * FROM tabela_de_pedidos FETCH FIRST 10 ROWS ONLY; 

DESC tabela_de_pedidos;


/**************************************************************************/

SET SERVEROUTPUT ON;


-- EX 1: Desenvolvimento do Modelo Estrela
  
--CRIANDO TABELAS DE DIMENSÃO


--CLIENTE
CREATE TABLE DIM_CLIENTE (
    COD_CLIENTE NUMBER(10,0) NOT NULL ENABLE,
    NOME_CLIENTE VARCHAR2(100 BYTE),
    PERFIL_CONSUMO VARCHAR2(50 BYTE),
    CONSTRAINT PK_DIM_CLIENTE PRIMARY KEY (COD_CLIENTE)
);

--VENDEDOR
CREATE TABLE DIM_VENDEDOR (
    COD_VENDEDOR NUMBER(4,0) NOT NULL ENABLE,
    NOME_VENDEDOR VARCHAR2(100 BYTE),
    CONSTRAINT PK_DIM_VENDEDOR PRIMARY KEY (COD_VENDEDOR)
);

--PRODUTO
CREATE TABLE DIM_PRODUTO (
    COD_PRODUTO NUMBER(10,0) NOT NULL ENABLE,
    NOME_PRODUTO VARCHAR2(100 BYTE),
    CATEGORIA VARCHAR2(50 BYTE),
    CONSTRAINT PK_DIM_PRODUTO PRIMARY KEY (COD_PRODUTO)
);

--STATUS
CREATE TABLE DIM_STATUS (
    COD_STATUS NUMBER(5,0) NOT NULL ENABLE,
    DESCRICAO_STATUS VARCHAR2(20 BYTE),
    CONSTRAINT PK_DIM_STATUS PRIMARY KEY (COD_STATUS)
);

--PAGAMENTO
CREATE TABLE DIM_PAGAMENTO (
    COD_PAGAMENTO NUMBER(5,0) NOT NULL ENABLE,
    FORMA_PAGAMENTO VARCHAR2(30 BYTE),
    PARCELADO VARCHAR2(3 BYTE), -- Sim/Não
    CONSTRAINT PK_DIM_PAGAMENTO PRIMARY KEY (COD_PAGAMENTO)
);


--CRIAÇÃO DA TABELA FATO_VENDA
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

--POPULANDO TABELAS--

--DIM CLIENTE
CREATE OR REPLACE PROCEDURE INSERE_DIM_CLIENTE (
    p_cod_cliente     IN DIM_CLIENTE.COD_CLIENTE%TYPE,
    p_nome_cliente    IN DIM_CLIENTE.NOME_CLIENTE%TYPE,
    p_perfil_consumo  IN DIM_CLIENTE.PERFIL_CONSUMO%TYPE
) IS
    v_count NUMBER;
BEGIN
    -- Validação: nome não pode ser nulo
    IF p_nome_cliente IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nome do cliente não pode ser nulo.');
    END IF;

    -- Verifica duplicidade
    SELECT COUNT(*) INTO v_count
    FROM DIM_CLIENTE
    WHERE COD_CLIENTE = p_cod_cliente;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cliente já cadastrado.');
    END IF;

    -- Inserção
    INSERT INTO DIM_CLIENTE (
        COD_CLIENTE, NOME_CLIENTE, PERFIL_CONSUMO
    ) VALUES (
        p_cod_cliente, p_nome_cliente, p_perfil_consumo
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir cliente: ' || SQLERRM);
        RAISE;
END;
/
--POPULANDO CLIENTE
BEGIN
    INSERE_DIM_CLIENTE(1, 'Maria Souza', 'Frequente');
    INSERE_DIM_CLIENTE(2, 'João Lima', 'Ocasional');
    INSERE_DIM_CLIENTE(3, 'Ana Costa', 'VIP');
    INSERE_DIM_CLIENTE(4, 'Carlos Oliveira', 'Frequente');
    INSERE_DIM_CLIENTE(5, 'Fernanda Dias', 'Ocasional');
    INSERE_DIM_CLIENTE(6, 'Bruno Silva', 'VIP');
    INSERE_DIM_CLIENTE(7, 'Juliana Martins', 'Frequente');
    INSERE_DIM_CLIENTE(8, 'Lucas Pereira', 'Ocasional');
    INSERE_DIM_CLIENTE(9, 'Patrícia Mendes', 'Frequente');
    INSERE_DIM_CLIENTE(10, 'Ricardo Almeida', 'VIP');
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
    INSERE_DIM_VENDEDOR(10, 'Carlos Mendes');
    INSERE_DIM_VENDEDOR(11, 'Fernanda Dias');
    INSERE_DIM_VENDEDOR(12, 'Rafael Oliveira');
    INSERE_DIM_VENDEDOR(13, 'Luciana Martins');
    INSERE_DIM_VENDEDOR(14, 'Paulo Henrique');
    INSERE_DIM_VENDEDOR(15, 'Tatiane Souza');
    INSERE_DIM_VENDEDOR(16, 'Roberto Silva');
    INSERE_DIM_VENDEDOR(17, 'Vanessa Lima');
    INSERE_DIM_VENDEDOR(18, 'Marcos Andrade');
    INSERE_DIM_VENDEDOR(19, 'Aline Barros');
END;
/

--VERIFICANDO INSERÇÃO
SELECT * FROM DIM_VENDEDOR;


--DIM PRODUTP
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
    INSERE_DIM_STATUS(1, 'Processando');
    INSERE_DIM_STATUS(2, 'Concluído');
    INSERE_DIM_STATUS(3, 'Pendente');
    INSERE_DIM_STATUS(4, 'Cancelado');
    INSERE_DIM_STATUS(5, 'Em análise');
    INSERE_DIM_STATUS(6, 'Reembolsado');
    INSERE_DIM_STATUS(7, 'Aguardando pagamento');
    INSERE_DIM_STATUS(8, 'Entregue');
    INSERE_DIM_STATUS(9, 'Em transporte');
    INSERE_DIM_STATUS(10, 'Falha na entrega');
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
ALTER TABLE DIM_PAGAMENTO MODIFY PARCELADO VARCHAR2(5 BYTE);


--POPULANDO DIM PAGAMENTO
BEGIN
    INSERE_DIM_PAGAMENTO(1, 'Cartão de Crédito', 'Sim');
    INSERE_DIM_PAGAMENTO(2, 'Cartão de Débito', 'Não');
    INSERE_DIM_PAGAMENTO(3, 'PIX', 'Não');
    INSERE_DIM_PAGAMENTO(4, 'Boleto Bancário', 'Não');
    INSERE_DIM_PAGAMENTO(5, 'Transferência Bancária', 'Não');
    INSERE_DIM_PAGAMENTO(6, 'Dinheiro', 'Não');
    INSERE_DIM_PAGAMENTO(7, 'Cheque', 'Não');
    INSERE_DIM_PAGAMENTO(8, 'Carteira Digital', 'Sim');
    INSERE_DIM_PAGAMENTO(9, 'Parcelamento Loja', 'Sim');
    INSERE_DIM_PAGAMENTO(10, 'Pagamento na Entrega', 'Não');
END;
/

--VERIFICANDO INSERÇÃO
SELECT * FROM DIM_PAGAMENTO;



--FATO VENDAS
CREATE OR REPLACE PROCEDURE INSERE_FATO_VENDAS (
    p_id_venda             IN FATO_VENDAS.ID_VENDA%TYPE,
    p_cod_cliente          IN FATO_VENDAS.COD_CLIENTE%TYPE,
    p_cod_vendedor         IN FATO_VENDAS.COD_VENDEDOR%TYPE,
    p_cod_status           IN FATO_VENDAS.COD_STATUS%TYPE,
    p_cod_pagamento        IN FATO_VENDAS.COD_PAGAMENTO%TYPE,
    p_cod_produto          IN FATO_VENDAS.COD_PRODUTO%TYPE,
    p_qtd_produto_vendido  IN FATO_VENDAS.QTD_PRODUTO_VENDIDO%TYPE,
    p_val_total_pedido     IN FATO_VENDAS.VAL_TOTAL_PEDIDO%TYPE,
    p_val_desconto         IN FATO_VENDAS.VAL_DESCONTO%TYPE
) IS
    v_count NUMBER;
BEGIN
    -- Validação de quantidade
    IF p_qtd_produto_vendido <= 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Quantidade vendida deve ser maior que zero.');
    END IF;

    -- Verifica se já existe uma venda com o mesmo ID
    SELECT COUNT(*) INTO v_count
    FROM FATO_VENDAS
    WHERE ID_VENDA = p_id_venda;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Venda já cadastrada.');
    END IF;

    -- Inserção
    INSERT INTO FATO_VENDAS (
        ID_VENDA, COD_CLIENTE, COD_VENDEDOR, COD_STATUS, COD_PAGAMENTO,
        COD_PRODUTO, QTD_PRODUTO_VENDIDO, VAL_TOTAL_PEDIDO, VAL_DESCONTO
    ) VALUES (
        p_id_venda, p_cod_cliente, p_cod_vendedor, p_cod_status, p_cod_pagamento,
        p_cod_produto, p_qtd_produto_vendido, p_val_total_pedido, p_val_desconto
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir venda: ' || SQLERRM);
        RAISE;
END;
/


--TESTE DE INSERÇÃO
BEGIN
    INSERE_FATO_VENDAS(
        p_id_venda => 1001,
        p_cod_cliente => 1,
        p_cod_vendedor => 10,
        p_cod_status => 2,
        p_cod_pagamento => 1,
        p_cod_produto => 1001,
        p_qtd_produto_vendido => 2,
        p_val_total_pedido => 25.00,
        p_val_desconto => 5.00
    );
END;
/
SELECT * FROM FATO_VENDAS ORDER BY ID_VENDA;



--EX3: Carregamento de Dados

--CLIENTE
INSERT INTO DIM_CLIENTE (COD_CLIENTE, NOME_CLIENTE, PERFIL_CONSUMO)
SELECT DISTINCT
    COD_CLIENTE,
    'Cliente Desconhecido',      -- Nome fictício
    'Não classificado'           --PERFIL GENERICO
FROM TABELA_DE_PEDIDOS
WHERE COD_CLIENTE IS NOT NULL
  AND COD_CLIENTE NOT IN (SELECT COD_CLIENTE FROM DIM_CLIENTE);



--VENDEDOR
INSERT INTO DIM_VENDEDOR (COD_VENDEDOR, NOME_VENDEDOR)
SELECT DISTINCT
    COD_VENDEDOR,
    'Vendedor Desconhecido'      --NOME GENERICO
FROM TABELA_DE_PEDIDOS
WHERE COD_VENDEDOR IS NOT NULL
  AND COD_VENDEDOR NOT IN (SELECT COD_VENDEDOR FROM DIM_VENDEDOR);


--STATUS
INSERT INTO DIM_STATUS (COD_STATUS, DESCRICAO_STATUS)
SELECT DISTINCT
    ROWNUM + 100 AS COD_STATUS,  -- Gera um código único temporário
    STATUS
FROM (
    SELECT DISTINCT STATUS
    FROM TABELA_DE_PEDIDOS
    WHERE STATUS IS NOT NULL
)
WHERE STATUS NOT IN (SELECT DESCRICAO_STATUS FROM DIM_STATUS);


--PAGAMENTO
INSERT INTO DIM_PAGAMENTO (COD_PAGAMENTO, FORMA_PAGAMENTO, PARCELADO)
VALUES (11, 'Vale Refeição', 'Não');

--PRODUTO
INSERT INTO DIM_PRODUTO (COD_PRODUTO, NOME_PRODUTO, CATEGORIA)
VALUES (1011, 'Spray Refrescante Bucal', 'Acessórios');


/**
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
**/

INSERT INTO FATO_VENDAS (
    ID_VENDA,
    COD_CLIENTE,
    COD_VENDEDOR,
    COD_STATUS,
    COD_PAGAMENTO,
    COD_PRODUTO,
    QTD_PRODUTO_VENDIDO,
    VAL_TOTAL_PEDIDO,
    VAL_DESCONTO
)
SELECT
    p.COD_PEDIDO,
    p.COD_CLIENTE,
    p.COD_VENDEDOR,
    (SELECT s.COD_STATUS
     FROM DIM_STATUS s
     WHERE s.DESCRICAO_STATUS = p.STATUS),
    1,        -- COD_PAGAMENTO fixo (ex: 'PIX')
    1001,     -- COD_PRODUTO fixo (Produto Genérico)
    1,        -- QTD_PRODUTO_VENDIDO (assumido como 1)
    p.VAL_TOTAL_PEDIDO,
    p.VAL_DESCONTO
FROM TABELA_DE_PEDIDOS p
WHERE p.COD_PEDIDO NOT IN (
    SELECT ID_VENDA FROM FATO_VENDAS
);





--EX4: Empacotamento das Procedures e Objetos

CREATE OR REPLACE PACKAGE PKG_ETL_VENDAS AS
    PROCEDURE INSERE_DIM_CLIENTE(
        p_cod_cliente     IN DIM_CLIENTE.COD_CLIENTE%TYPE,
        p_nome_cliente    IN DIM_CLIENTE.NOME_CLIENTE%TYPE,
        p_perfil_consumo  IN DIM_CLIENTE.PERFIL_CONSUMO%TYPE
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
        p_val_desconto         IN FATO_VENDAS.VAL_DESCONTO%TYPE
    );

    PROCEDURE ETL_COMPLETO;
END PKG_ETL_VENDAS;
/


--CORPO DO PKG BODY
CREATE OR REPLACE PACKAGE BODY PKG_ETL_VENDAS AS

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

        INSERT INTO DIM_CLIENTE VALUES (p_cod_cliente, p_nome_cliente, p_perfil_consumo);
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
        p_val_desconto         IN FATO_VENDAS.VAL_DESCONTO%TYPE
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

        INSERT INTO FATO_VENDAS VALUES (
            p_id_venda, p_cod_cliente, p_cod_vendedor, p_cod_status, p_cod_pagamento,
            p_cod_produto, p_qtd_produto_vendido, p_val_total_pedido, p_val_desconto
        );
    END;

    -- PROCEDURE OPCIONAL PARA EXECUTAR O ETL COMPLETO
    PROCEDURE ETL_COMPLETO IS
    BEGIN
        -- Aqui você pode incluir os comandos de carga automática por SELECT INTO, caso deseje
        DBMS_OUTPUT.PUT_LINE('Executar carga completa com INSERTs automáticos aqui se desejado.');
    END;

END PKG_ETL_VENDAS;
/


--VISUALIZAÇÃO
SELECT OBJECT_NAME, STATUS FROM USER_OBJECTS
WHERE OBJECT_TYPE = 'PACKAGE' AND OBJECT_NAME = 'PKG_ETL_VENDAS';

--TESTANDO UMA PROCEDURE
BEGIN
    PKG_ETL_VENDAS.INSERE_DIM_CLIENTE(101, 'Maria Teste', 'Frequente');
END;
/



--EX5: Execução das procedures


--BLOCO BEGIN - FATOS VENDA
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
        p_val_desconto         => 5.00
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
        p_val_desconto         => 0.00
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
        p_val_desconto         => 15.00
    );
END;
/

SELECT * FROM DIM_CLIENTE ORDER BY COD_CLIENTE;
SELECT * FROM DIM_VENDEDOR ORDER BY COD_VENDEDOR;
SELECT * FROM DIM_PRODUTO ORDER BY COD_PRODUTO;
SELECT * FROM DIM_STATUS ORDER BY COD_STATUS;
SELECT * FROM DIM_PAGAMENTO ORDER BY COD_PAGAMENTO;


SELECT * FROM FATO_VENDAS ORDER BY ID_VENDA;





-- Implementação das Trigger

--TABELA DE AUDITORIA
CREATE TABLE AUDITORIA_DIMENSOES (
    ID_AUDITORIA     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TABELA_AFETADA   VARCHAR2(30),
    ID_REGISTRO      NUMBER,
    USUARIO_BANCO    VARCHAR2(30),
    DATA_INSERCAO    DATE
);


--TRIGGER DE AUDITORIA
CREATE OR REPLACE TRIGGER TRG_AUDIT_DIM_CLIENTE
AFTER INSERT ON DIM_CLIENTE
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        TABELA_AFETADA,
        ID_REGISTRO,
        USUARIO_BANCO,
        DATA_INSERCAO
    ) VALUES (
        'DIM_CLIENTE',
        :NEW.COD_CLIENTE,
        USER,
        SYSDATE
    );
END;
/


--Triggers de auditoria por tabela
--DIM_CLIENTE
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

--DIM_VENDEDOR
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


--PRODUTO
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

--STATUS
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

--DIM_PAGAMENTO
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

--TESTES
BEGIN
    PKG_ETL_VENDAS.INSERE_DIM_CLIENTE(999, 'Auditoria Teste', 'VIP');
END;
/
















