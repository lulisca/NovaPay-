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
evidencias/auditor_ext_bloqueado.png. (salvo na pasta/evidencias)
ALTER USER 'auditor_ext'@'%' ACCOUNT UNLOCK;
evidencias/auditor_ext_desbloqueado.png  (salvo na pasta/evidencias)
-- =====================================================
-- Passo 2: Matriz de Escopos
-- =====================================================

-- =====================================================
-- Passo 3: Roles & Limites
-- =====================================================

-- =====================================================
-- Passo 4: Auditoria & Entrega
-- =====================================================
