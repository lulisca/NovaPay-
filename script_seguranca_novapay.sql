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
-- Passo 1: Anatomia & DDL
-- (continuar aqui conforme a equipe avancar na etapa)
-- =====================================================

-- =====================================================
-- Passo 2: Matriz de Escopos
-- =====================================================

-- =====================================================
-- Passo 3: Roles & Limites
-- =====================================================

-- =====================================================
-- Passo 4: Auditoria & Entrega
-- =====================================================
