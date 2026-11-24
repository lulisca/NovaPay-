-- =====================================================
-- NovaPay S.A. - Script de Seguranca MySQL 8.0+
-- Integrantes: Luisa Felix, Leonardo rossetti e Alisson Silva
-- Roles e Governanca de Recursos
-- =====================================================

-- =====================================================
-- Passo 0: Script Base de Infraestrutura
-- =====================================================

DROP DATABASE IF EXISTS novapay_db;
CREATE DATABASE novapay_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE novapay_db;

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    saldo DECIMAL(12,2) DEFAULT 0.00
);

CREATE TABLE transacoes (
    id_transacao INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    valor DECIMAL(12,2) NOT NULL,
    tipo ENUM('PIX', 'TED', 'BOLETO') NOT NULL,
    data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE logs_auditoria (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    evento VARCHAR(255) NOT NULL,
    registrado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO clientes (nome, cpf, telefone, saldo) VALUES
('Mariana Costa', '111.222.333-44', '(11) 98888-1111', 15400.50),
('Carlos Eduardo', '555.666.777-88', '(19) 97777-2222', 320.00);

INSERT INTO transacoes (id_cliente, valor, tipo) VALUES (1, 500.00, 'PIX');
INSERT INTO logs_auditoria (evento) VALUES ('Inicializacao do sistema NovaPay');

-- =====================================================
-- Passo 1: Anatomia & DDL - Criacao de Contas e Ciclo de Vida
-- =====================================================

-- app_backend: aplicacao roda na mesma maquina do banco,
-- nao deve aceitar conexoes externas (host = localhost)
CREATE USER 'app_backend'@'localhost' IDENTIFIED BY 'App@Nova2026!';

-- dev_lucas: sub-rede da engenharia, deve trocar a senha no proximo login
CREATE USER 'dev_lucas'@'192.168.10.%' IDENTIFIED BY 'DevTemp#123';
ALTER USER 'dev_lucas'@'192.168.10.%' PASSWORD EXPIRE;

-- auditor_ext: auditor externo, conta criada ja bloqueada ate o inicio da auditoria
CREATE USER 'auditor_ext'@'%' IDENTIFIED BY 'Audit@2026!' ACCOUNT LOCK;

-- estagiario_suporte: conta de suporte interno nivel 1
CREATE USER 'estagiario_suporte'@'localhost' IDENTIFIED BY 'Sup@2026!';

-- Desafio de validacao: em outro terminal/aba, tentar conectar como auditor_ext
-- e registrar o codigo de erro retornado (conta bloqueada), depois desbloquear:
-- evidencias/auditor_ext_bloqueado.png (salvo na pasta evidencias)
ALTER USER 'auditor_ext'@'%' ACCOUNT UNLOCK;
-- evidencias/auditor_ext_desbloqueado.png (salvo na pasta evidencias)

-- =====================================================
-- Passo 2: Matriz de Escopos
-- =====================================================

-- app_backend: le, insere e atualiza clientes e transacoes.
-- Em logs_auditoria so pode ler e inserir (sem UPDATE/DELETE = logs imutaveis).
-- Nenhum privilegio estrutural (DROP, ALTER, CREATE).
GRANT SELECT, INSERT, UPDATE ON novapay_db.clientes TO 'app_backend'@'localhost';
GRANT SELECT, INSERT, UPDATE ON novapay_db.transacoes TO 'app_backend'@'localhost';
GRANT SELECT, INSERT ON novapay_db.logs_auditoria TO 'app_backend'@'localhost';

-- estagiario_suporte: seguranca em nivel de coluna (LGPD).
-- Le apenas id_cliente, nome e telefone (nao ve cpf nem saldo)
-- e so pode atualizar a coluna telefone.
GRANT SELECT (id_cliente, nome, telefone), UPDATE (telefone)
    ON novapay_db.clientes TO 'estagiario_suporte'@'localhost';

-- auditor_ext: somente leitura em todo o banco, sem WITH GRANT OPTION.
GRANT SELECT ON novapay_db.* TO 'auditor_ext'@'%';

-- dev_lucas: nenhum escopo definido para ele nesta etapa,
-- entao fica sem privilegios (menor privilegio).

-- Simulacao de incidente: DELETE em transacoes concedido por engano ao app_backend...
GRANT DELETE ON novapay_db.transacoes TO 'app_backend'@'localhost';
-- ...e revogado de forma cirurgica (so o DELETE sai, o resto continua).
REVOKE DELETE ON novapay_db.transacoes FROM 'app_backend'@'localhost';

-- Conferencia: o app_backend nao deve mais ter DELETE em transacoes.
SHOW GRANTS FOR 'app_backend'@'localhost';
-- evidencias/app_backend_grants.png (salvo na pasta evidencias)

-- Teste obrigatorio de LGPD (feito em outra conexao, logado como estagiario_suporte):
-- SELECT * FROM novapay_db.clientes;                          -> falha: ERROR 1142 (SELECT command denied)
-- evidencias/estagiario_select_negado.png (salvo na pasta evidencias)
-- SELECT id_cliente, nome, telefone FROM novapay_db.clientes; -> funciona
-- evidencias/estagiario_select_permitido.png (salvo na pasta evidencias)

-- =====================================================
-- Passo 3: Roles & Limites
-- =====================================================

-- Cria uma role para padronizar os privilegios dos analistas de BI.
CREATE ROLE 'role_analista_bi';

-- A role pode consultar todas as colunas de transacoes, mas somente
-- id_cliente e nome em clientes, preservando os demais dados pessoais.
GRANT SELECT ON novapay_db.transacoes TO 'role_analista_bi';
GRANT SELECT (id_cliente, nome)
    ON novapay_db.clientes TO 'role_analista_bi';

-- Cria os dois cientistas de dados com a senha definida no enunciado.
CREATE USER 'bi_ana'@'%' IDENTIFIED BY 'Bi@Nova2026!';
CREATE USER 'bi_bruno'@'%' IDENTIFIED BY 'Bi@Nova2026!';

-- Associa a role aos usuarios e a ativa automaticamente em cada login.
GRANT 'role_analista_bi' TO 'bi_ana'@'%', 'bi_bruno'@'%';
SET DEFAULT ROLE ALL TO 'bi_ana'@'%', 'bi_bruno'@'%';

-- Protege o servidor contra excesso de conexoes e consultas da conta bi_ana.
ALTER USER 'bi_ana'@'%' WITH
    MAX_USER_CONNECTIONS 2
    MAX_QUERIES_PER_HOUR 100;

-- Conferencias administrativas da configuracao aplicada.
SHOW GRANTS FOR 'role_analista_bi';
SHOW GRANTS FOR 'bi_ana'@'%';
SHOW GRANTS FOR 'bi_bruno'@'%';

-- Testes funcionais (executar em uma nova conexao como bi_ana ou bi_bruno):
-- SELECT * FROM novapay_db.transacoes;              -> deve funcionar
-- SELECT id_cliente, nome FROM novapay_db.clientes; -> deve funcionar
-- SELECT * FROM novapay_db.clientes;                -> deve falhar por restricao de colunas

-- Teste de estresse: abrir simultaneamente duas conexoes como bi_ana e,
-- sem fecha-las, tentar abrir uma terceira. A terceira deve falhar com:
-- ERROR 1226: User 'bi_ana' has exceeded the 'max_user_connections' resource.
-- evidencias/bi_ana_limite_conexoes.png

-- =====================================================
-- Passo 4: Auditoria & Entrega
-- =====================================================

-- Auditoria final das permissoes aplicadas.
SHOW GRANTS FOR 'estagiario_suporte'@'localhost';
-- evidencias/estagiario_grants_final.png

SHOW GRANTS FOR 'bi_ana'@'%' USING 'role_analista_bi';
-- evidencias/bi_ana_grants_role.png

-- Nao usamos FLUSH PRIVILEGES porque os comandos CREATE USER, ALTER USER,
-- GRANT e REVOKE atualizam imediatamente os privilegios no MySQL.
-- FLUSH PRIVILEGES seria necessario ao modificar diretamente as tabelas
-- internas de privilegios do banco mysql, o que nao foi feito neste script.
