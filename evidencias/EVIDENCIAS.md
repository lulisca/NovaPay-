# Evidências — NovaPay S.A. (Hardening MySQL)

## Etapa 1: Anatomia & DDL

- [auditor_ext bloqueado](auditor_ext_bloqueado.png)
- [auditor_ext desbloqueado](auditor_ext_desbloqueado.png)

## Etapa 2: Matriz de Escopos

- [app_backend sem DELETE apos o REVOKE](app_backend_grants.png)
- [estagiario_suporte: SELECT * negado (LGPD)](estagiario_select_negado.png)
- [estagiario_suporte: SELECT nas colunas permitidas](estagiario_select_permitido.png)

## Etapa 3: Roles & Limites

- [bi_ana: terceira conexao bloqueada pelo limite de recursos](bi_ana_limite_conexoes.png)
