Especificação de Requisitos do Sistema
Este documento descreve os Requisitos Funcionais (RF) e Requisitos Não-Funcionais (RNF) para o Sistema de Gestão de Gado. Os requisitos foram reestruturados, padronizados e organizados por categorias para facilitar o desenvolvimento, os testes e a manutenção do projeto.
1. Requisitos Funcionais (RF)
Os requisitos funcionais definem o que o sistema deve fazer em termos de funcionalidades e interações diretas com o usuário.
1.1 Gestão de Entidades Básicas (CRUD)
    • RF01 - Cadastrar e Gerenciar Gado: O sistema deve permitir o cadastro, visualização, edição e exclusão (CRUD) das informações dos animais.
    • RF02 - Cadastrar e Gerenciar Pastos: O sistema deve permitir o cadastro, edição e consulta de pastos/piquetes.
    • RF03 - Cadastrar e Gerenciar Medicamentos: O sistema deve permitir o cadastro e gerenciamento das informações sobre remédios/medicamentos.
    • RF04 - Gestão do Perfil do Usuário: O usuário deve ser capaz de consultar e editar suas próprias informações pessoais de perfil.
1.2 Regras de Negócio e Processos
    • RF05 - Manter Histórico de Tratamentos: O sistema deve registrar e manter um histórico completo dos tratamentos aplicados a cada animal (incluindo diagnósticos, datas e medicamentos utilizados).
    • RF06 - Consulta e Controle de Estoque de Medicamentos: O sistema deve permitir a consulta detalhada do estoque de medicamentos cadastrados.
    • RF07 - Filtragem de Gado por Pasto: O sistema deve disponibilizar funcionalidade para filtrar e visualizar a lista de gados alocados em cada pasto específico.
2. Requisitos Não-Funcionais (RNF)
Os requisitos não-funcionais definem as qualidades, restrições arquiteturais, padrões de engenharia e escolhas de infraestrutura do sistema.
2.1 Ecossistema de Linguagem e Arquitetura
    • RNF01 - Linguagem e Ecossistema Kof: Todo o sistema (frontend, backend e ferramentas de suporte) deve ser obrigatoriamente escrito, mantido e sustentado utilizando a linguagem Kof (https://koflang.github.io/web), aproveitando seus ecossistemas nativos/múltiplos targets.
    • RNF02 - Persistência de Dados: O sistema deve utilizar o banco de dados relacional PostgreSQL para armazenamento persistente de dados.
    • RNF03 - Arquitetura de Backend Único em Kof: A API/Backend deve ser única e compartilhada, implementada com as bibliotecas web nativas da Kof, atendendo simultaneamente aos clientes Web e Mobile.
    • RNF04 - Estrutura de Repositório (Monorepo): O projeto deve ser desenvolvido em um único repositório (Monorepo), contendo todo o código-fonte em Kof (frontend e backend) e configurações de containerização (Dockerfiles).
    • RNF05 - Conformidade com Modelo de Dados: O desenvolvimento do sistema deve seguir rigorosamente a estrutura definida no diagrama de classes prototipado.
2.2 Plataformas e Acessibilidade (Frontend)
    • RNF06 - Suporte Multiplataforma: O sistema deve possuir interfaces operacionais para as plataformas Web e Mobile.
    • RNF07 - Acessibilidade e Ajuste de Interface: A interface do usuário deve oferecer recursos de acessibilidade, permitindo aumentar e diminuir dinamicamente a escala de fontes e componentes visuais.
2.3 Segurança e Privacidade
    • RNF08 - Autenticação OAuth2: O sistema deve autenticar usuários exclusivamente via protocolo OAuth2, oferecendo suporte aos provedores Google e GitHub.
    • RNF09 - Privacidade e Uso de Dados de Usuários: O sistema não deve utilizar, armazenar indevidamente ou processar informações pessoais dos usuários além do estritamente necessário para autenticação e gestão do perfil.
2.4 Infraestrutura, DevOps e Deploy
    • RNF10 - Containerização: A aplicação deve incluir arquivos de configuração Dockerfile para empacotamento do runtime e serviços em Kof.
    • RNF11 - Orquestração em Kubernetes: O deploy do sistema deve ser realizado e orquestrado via Kubernetes (K8s).
    • RNF12 - Provedor de Nuvem (OCI Always Free): O deploy deve ser realizado na nuvem da Oracle Cloud Infrastructure (OCI), utilizando os recursos da camada Always Free.
    • RNF13 - Hospedagem de Código: O repositório do projeto deve ser mantido e hospedado no GitHub.
2.5 Qualidade e Documentação
    • RNF14 - Cobertura de Testes Automatizados: A aplicação deve conter testes automatizados unitários e testes end-to-end (E2E).
    • RNF15 - Documentação Didática (README.md): O repositório deve incluir um documento README.md completo e didático, com instruções claras para compilação/execução com o toolchain do Kof, execução de testes e deploy.

