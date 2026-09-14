# Modelo de dados — Diagrama Entidade-Relacionamento

Modelo relacional da oficina, versionado hoje pelas migrations Flyway do repositório
[`oficina`](https://github.com/rremiao/oficina) (`src/main/resources/db/migration`, `V1` a `V10`).
Este documento existe neste repositório porque é aqui que a infraestrutura do banco gerenciado é
provisionada — a fonte de verdade do schema em si continua nas migrations do `oficina`.

## Diagrama

```mermaid
erDiagram
    CLIENTE ||--o{ VEICULO : possui
    CLIENTE ||--o{ ORDEM_SERVICO : solicita
    VEICULO ||--o{ ORDEM_SERVICO : "e atendido em"
    ORDEM_SERVICO ||--o{ HISTORICO_ORDEM_SERVICO : registra
    ORDEM_SERVICO ||--o{ ITEM_ORDEM_SERVICO : consome
    ORDEM_SERVICO ||--o{ SERVICO_ORDEM_SERVICO : executa
    ORDEM_SERVICO ||--o{ MOVIMENTACAO_ESTOQUE : "pode gerar"
    ITEM ||--|| ESTOQUE : controla
    ITEM ||--o{ ITEM_ORDEM_SERVICO : "e usado em"
    ITEM ||--o{ MOVIMENTACAO_ESTOQUE : movimenta
    SERVICO ||--o{ SERVICO_ORDEM_SERVICO : "e prestado em"

    CLIENTE {
        bigint id PK
        varchar nome
        varchar cpf_cnpj UK
        varchar telefone
        varchar email
        varchar cep
        varchar logradouro
        varchar bairro
        varchar cidade
        varchar uf
        date data_nascimento
        boolean ativo
    }

    VEICULO {
        bigint id PK
        bigint cliente_id FK
        varchar placa UK
        varchar marca
        varchar modelo
        int ano
        boolean ativo
    }

    SERVICO {
        bigint id PK
        varchar nome
        numeric valor
        boolean ativo
    }

    ITEM {
        bigint id PK
        varchar nome
        varchar tipo
        numeric valor_unitario
        varchar unidade_medida
        boolean ativo
    }

    ESTOQUE {
        bigint id PK
        bigint item_id FK "UK"
        int quantidade
        int estoque_minimo
    }

    MOVIMENTACAO_ESTOQUE {
        bigint id PK
        bigint item_id FK
        bigint ordem_servico_id "sem FK declarada"
        varchar tipo
        int quantidade
    }

    ORDEM_SERVICO {
        bigint id PK
        varchar codigo UK
        bigint cliente_id FK
        bigint veiculo_id FK
        varchar status
        numeric valor_total_servicos
        numeric valor_total_itens
        timestamp data_cadastro
    }

    HISTORICO_ORDEM_SERVICO {
        bigint id PK
        bigint ordem_servico_id FK
        varchar status
        timestamp data_cadastro
    }

    ITEM_ORDEM_SERVICO {
        bigint id PK
        bigint item_id FK
        bigint ordem_servico_id FK
        int quantidade
        numeric valor_unitario
    }

    SERVICO_ORDEM_SERVICO {
        bigint id PK
        bigint servico_id FK
        bigint ordem_servico_id FK
        varchar status
        numeric valor_unitario
    }

    USUARIO {
        bigint id PK
        varchar nome
        varchar email UK
        varchar senha
        varchar role
        boolean ativo
    }
```

`USUARIO` não tem relacionamento de chave estrangeira com as demais tabelas — é a base de login dos
operadores da oficina (autenticação por e-mail/senha), independente do fluxo de atendimento ao
cliente.

## Pontos de atenção do modelo

- **`movimentacao_estoque.ordem_servico_id`** referencia `ordem_servico` apenas por convenção da
  aplicação: a coluna existe e é usada para correlacionar baixas de estoque com a OS que as gerou,
  mas a migration `V6` não declara a constraint de chave estrangeira. Isso é uma dívida técnica do
  schema atual, não uma decisão deliberada — deveria ganhar a FK numa migration futura.
- **`estoque.item_id`** é `UNIQUE`, modelando uma relação 1:1 entre item e seu controle de estoque
  (em vez de 1:N), o que faz sentido porque cada item tem exatamente um saldo controlado.
- **Índice funcional `idx_cliente_cpf_cnpj_digitos`** (`V10`) existe especificamente para a consulta
  que a function serverless do `oficina-lambda` faz ao autenticar por CPF, comparando o documento
  normalizado (sem pontuação). Ver
  [`V10__index_cpf_cnpj_normalizado.sql`](https://github.com/rremiao/oficina/blob/main/src/main/resources/db/migration/V10__index_cpf_cnpj_normalizado.sql)
  no `oficina`.
- **`ordem_servico.codigo`** é gerado por uma função/trigger PL/pgSQL (`calcular_proximo_codigo_os`)
  com um contador anual (`os_contador`), garantindo um código legível (`OS-2026-000123`) e único sem
  depender de lógica de aplicação.
