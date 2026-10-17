# Sistema de Gestão de Gado — KOF MVP

Sistema completo (Backend, Persistência PostgreSQL e Interface Multiplataforma Web/Mobile) escrito **100% em KOF** (`https://koflang.github.io/docs`), seguindo a filosofia **"Feijão com Arroz" (KISS)** da skill `kof_engineering`, a [Especificação de Requisitos](./requisitos.md) e o [Diagrama de Classes](./diagram.png).

---

## 📁 Estrutura do Projeto (Monorepo KOF)

```text
/
├── app.kf                       # Entrypoint da API (kof.web, OAuth2 Google/GitHub e rotas REST)
├── kofdeps                      # Declaração de drivers JDBC (PostgreSQL e H2 para testes)
├── models/
│   └── entities.kf              # Enums (SaudeVaca, SexoVaca, AplicacaoRemedio), Entities e Records
├── db/
│   └── schema.kf                # Conexão PostgreSQL (kof.db) e inicialização tipada do KOF ORM (kof.orm)
├── handlers/
│   ├── rotas.kf                 # Registro compartilhado de rotas REST (usado por app.kf e E2E)
│   ├── pasto_handler.kf         # RF02 - CRUD de Pastos/Piquetes
│   ├── gado_handler.kf          # RF01 - CRUD de Gado + RF07 - Filtragem por Pasto
│   ├── remedio_handler.kf       # RF03 - CRUD de Medicamentos + RF06 - Controle de Estoque
│   ├── tratamento_handler.kf    # RF05 - Histórico de Tratamentos, Dosagens e Baixa de Estoque
│   └── usuario_handler.kf       # RF04, RNF08, RNF09 - Perfil do Usuário OAuth2 com privacidade estrita
├── ui/
│   └── app_ui.kf                # RNF06, RNF07 - Interface Web (KofJS) e Mobile (Android) com escala dinâmica de fonte (+A / -A)
├── test/
│   ├── unit_models_test.kf      # RNF14 - Testes unitários de Enums, Entities, Records e JSON
│   ├── unit_handlers_test.kf    # RNF14 - Testes de regras de negócio e persistência (RF01..RF07)
│   └── e2e_api_test.kf          # RNF14 - Testes End-to-End HTTP reais com withServer e withDb
├── Dockerfile                   # RNF10 - Empacotamento enxuto do runtime KOF em container
├── diagram.png                  # RNF05 - Diagrama de classes do modelo de dados
└── requisitos.md                # Especificação de Requisitos Funcionais (RF) e Não-Funcionais (RNF)
```

---

## 🚀 Como Executar com o Toolchain KOF (`0.6.5`)

### 1. Resolver Dependências JDBC (`kof deps`)

```bash
kof deps resolve
```

### 2. Variáveis de Ambiente (PostgreSQL e OAuth2)

Por padrão, o sistema conecta em `jdbc:postgresql://localhost:5432/kof_gado`. Você pode customizar via variáveis de ambiente lidas por `kof.secrets`:

```bash
export DB_URL="jdbc:postgresql://localhost:5432/kof_gado"
export DB_USER="postgres"
export DB_PASS="postgres"

# OAuth2 Resource Server (Google ou GitHub - RNF08)
export OAUTH_JWKS_URL="https://www.googleapis.com/oauth2/v3/certs"
export OAUTH_ISSUER="https://accounts.google.com"
export OAUTH_AUDIENCE="kof-gado-api"
export OAUTH_PROVIDER="google"
```

### 3. Rodar o Servidor Backend Localmente

```bash
kof serve app.kf
```

A API responderá em `http://localhost:8080`.

### 4. Executar a Interface Multiplataforma (Web & Mobile)

- **Web (`KofJS` / Webview nativo ou Browser):**
  ```bash
  kof run ui/app_ui.kf --target=js
  ```
- **Build Estático Web (`index.html` + ES Modules):**
  ```bash
  kof build ui/app_ui.kf --target=js
  ```
- **Mobile Android (`APK`):**
  ```bash
  kof build ui/app_ui.kf --target android --apk
  ```

### 5. Formatação e Verificação Estática (`kof fmt` & `kof check`)

```bash
kof fmt -w app.kf models db handlers ui test
kof check app.kf
kof check ui/app_ui.kf
```

### 6. Executar Testes Automatizados (Unitários e E2E)

```bash
# Executar todas as suítes do diretório test/ (Unitários + E2E HTTP)
kof test --module-root . test/

# Executar apenas testes unitários por tag
kof test --module-root . test/ --tag unit

# Executar apenas testes End-to-End HTTP por tag
kof test --module-root . test/ --tag e2e
```

---

## 📡 Endpoints Principais da API (`app.kf`)

| Método | Rota | Requisito | Descrição |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | — | Verificação de saúde do serviço |
| `GET` | `/perfil` | `RF04`, `RNF08`, `RNF09` | Consulta perfil do usuário autenticado via OAuth2 |
| `PUT` | `/perfil` | `RF04`, `RNF08`, `RNF09` | Atualiza nome e e-mail do perfil do usuário |
| `GET` | `/pastos` | `RF02` | Lista todos os pastos cadastrados |
| `GET` | `/pastos/:id` | `RF02` | Consulta pasto por UUID |
| `POST` | `/pastos` | `RF02` | Cadastra novo pasto (`nome`, `dono`, `valor_cabeca`) |
| `PUT` | `/pastos/:id` | `RF02` | Atualiza dados de um pasto |
| `GET` | `/gados` | `RF01` | Lista todos os animais cadastrados |
| `GET` | `/gados/:id` | `RF01` | Busca detalhes de um animal por UUID |
| `POST` | `/gados` | `RF01` | Cadastra novo animal validando `SaudeVaca` e `SexoVaca` |
| `PUT` | `/gados/:id` | `RF01` | Atualiza cadastro do animal |
| `DELETE` | `/gados/:id` | `RF01` | Remove registro de animal |
| `GET` | `/pastos/:pastoId/gados` | `RF07` | Filtra e lista os gados alocados em um pasto específico |
| `GET` | `/remedios` | `RF03` | Lista todos os medicamentos cadastrados |
| `GET` | `/remedios/estoque` | `RF06` | Consulta detalhada de estoque de medicamentos |
| `POST` | `/remedios` | `RF03` | Cadastra medicamento validando `AplicacaoRemedio` |
| `PUT` | `/remedios/:id/estoque` | `RF06` | Atualiza saldo em estoque de um medicamento |
| `GET` | `/gados/:gadoId/tratamentos` | `RF05` | Lista histórico completo de tratamentos do animal |
| `GET` | `/tratamentos/:id/remedios` | `RF05` | Lista medicamentos e dosagens aplicados no tratamento |
| `POST` | `/tratamentos` | `RF05`, `RF06` | Registra tratamento, vincula dosagem e abate do estoque |

---

## 🐳 Containerização (`Dockerfile`)

Para empacotar e executar a aplicação via Docker:

```bash
docker build -t kof-gado-system .
docker run -p 8080:8080 \
  -e DB_URL="jdbc:postgresql://host.docker.internal:5432/kof_gado" \
  -e DB_USER="postgres" \
  -e DB_PASS="postgres" \
  kof-gado-system
```
