# Sistema de Gestão de Gado — KOF MVP

Sistema completo (Backend, Persistência Nativa SQLite e Interface Multiplataforma Web/Mobile) escrito **100% em KOF** (`https://koflang.github.io/docs`), seguindo a filosofia **"Feijão com Arroz" (KISS)** da skill `kof_engineering`, a [Especificação de Requisitos](./requisitos.md) e o [Diagrama de Classes](./diagram.png).

---

## 📁 Estrutura do Projeto (Monorepo KOF)

```text
/
├── app.kf                       # Entrypoint da API (kof.web, OAuth2 Google/GitHub e rotas REST)
├── models/
│   └── entities.kf              # Enums (SaudeVaca, SexoVaca, AplicacaoRemedio), Entities e Records
├── db/
│   └── schema.kf                # Conexão com Banco Nativo KOF SQLite (kof.db) e KOF ORM (kof.orm)
├── handlers/
│   ├── rotas.kf                 # Registro compartilhado de rotas REST (usado por app.kf e E2E)
│   ├── pasto_handler.kf         # RF02 - CRUD de Pastos/Piquetes
│   ├── gado_handler.kf          # RF01 - CRUD de Gado + RF07 - Filtragem por Pasto
│   ├── remedio_handler.kf       # RF03 - CRUD de Medicamentos + RF06 - Controle de Estoque
│   ├── tratamento_handler.kf    # RF05 - Histórico de Tratamentos, Dosagens e Baixa de Estoque
│   └── usuario_handler.kf       # RF04, RNF08, RNF09 - Perfil do Usuário OAuth2 com privacidade estrita
├── ui/
│   └── app_ui.kf                # RNF06, RNF07 - Frontend completo em KOF (Formulários CRUD + Escala +A/-A)
├── public/                      # Bundle Web KofJS compilado de ui/app_ui.kf e servido em /ui
├── test/
│   ├── unit_models_test.kf      # RNF14 - Testes unitários de Enums, Entities, Records e JSON
│   ├── unit_handlers_test.kf    # RNF14 - Testes de regras de negócio e persistência (RF01..RF07)
│   ├── unit_ui_test.kf          # RNF14 - Testes unitários de componentes KOF UI, acessibilidade e bundle Web
│   └── e2e_api_test.kf          # RNF14 - Testes End-to-End HTTP reais (API + Frontend /ui)
├── Dockerfile                   # RNF10 - Empacotamento multi-stage (Backend JVM + Frontend KofJS)
├── diagram.png                  # RNF05 - Diagrama de classes do modelo de dados
└── requisitos.md                # Especificação de Requisitos Funcionais (RF) e Não-Funcionais (RNF)
```

---

## 🚀 Como Executar com o Toolchain KOF (`0.6.5`)

### 1. Banco de Dados Nativo KOF (`sqlite:fazenda.db`) e Variáveis de Ambiente

Por padrão, o sistema utiliza o banco de dados nativo embutido do KOF (`sqlite:fazenda.db` em produção e `sqlite::memory:` nos testes), provisionado automaticamente pelo compilador KOF sem necessidade de banco externo. Você pode customizar via variáveis de ambiente lidas por `kof.secrets`:

```bash
# Opcional: sobrescrever a URI do banco (padrão: sqlite:fazenda.db)
export DB_URL="sqlite:fazenda.db"

# OAuth2 Resource Server (Google ou GitHub - RNF08)
export OAUTH_JWKS_URL="https://www.googleapis.com/oauth2/v3/certs"
export OAUTH_ISSUER="https://accounts.google.com"
export OAUTH_AUDIENCE="kof-gado-api"
export OAUTH_PROVIDER="google"
```

### 2. Compilar o Frontend KOF e Rodar o Servidor Localmente

```bash
# Compila o frontend KOF (ui/app_ui.kf) para o diretório public/
kof build ui/app_ui.kf --target js --output public

# Inicia o servidor KOF (API + Frontend servido em /ui)
kof serve app.kf
```

- **API REST:** `http://localhost:8080`
- **Frontend Web KOF:** `http://localhost:8080/ui`

### 3. Executar a Interface Multiplataforma (Web & Mobile)

- **Execução Direta Web (`KofJS`):**
  ```bash
  kof run ui/app_ui.kf --target=js
  ```
- **Build Estático Web (`public/index.html` + `Default.mjs`):**
  ```bash
  kof build ui/app_ui.kf --target js --output public
  ```
- **Mobile Android (`APK`):**
  ```bash
  kof build ui/app_ui.kf --target android --apk
  ```

### 4. Formatação e Verificação Estática (`kof fmt` & `kof check`)

```bash
kof fmt app.kf models db handlers ui test
kof check app.kf
kof check ui/app_ui.kf
```

### 5. Executar Testes Automatizados (Unitários e E2E)

```bash
# Executar todas as 4 suítes do diretório test/ (19 testes: Unitários + UI + E2E HTTP)
kof test --module-root . test/

# Executar apenas testes unitários por tag
kof test --module-root . test/ --tag unit

# Executar apenas testes End-to-End HTTP por tag
kof test --module-root . test/ --tag e2e
```

---

## 📡 Endpoints Principais (`app.kf`)

| Método | Rota | Requisito | Descrição |
| :--- | :--- | :--- | :--- |
| `GET` | `/ui` | `RNF01`, `RNF06`, `RNF07` | Interface Web completa compilada de `ui/app_ui.kf` |
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

O `Dockerfile` baixa a distribuição oficial do [`KofLang/Kof4j`](https://github.com/KofLang/Kof4j) (`v0.6.5`), compila a aplicação em um fat JAR autocontido (`kof build app.kf --target jvm --fat --output /app/out`) já com o driver SQLite nativo embutido e gera a imagem final com `eclipse-temurin:25-jre-noble`:

```bash
docker build -t kof-gado-system .
docker run -p 8080:8080 kof-gado-system
```
