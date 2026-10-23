# Deploy no Render

O app roda no [Render](https://render.com) como um Web Service Ruby com um Postgres gerenciado, descritos no `render.yaml` (Blueprint). Os comprovantes e logos ficam num bucket do Cloudflare R2, porque o disco do Render é apagado a cada deploy.

| Peça | Plano no `render.yaml` | Custo aproximado |
|---|---|---|
| Web Service `agetur` | Starter (512 MB) | US$ 7/mês |
| Postgres `agetur-db` | Basic-256mb (+ US$ 0,30/GB) | US$ 6/mês |
| Cloudflare R2 | até 10 GB grátis | US$ 0 |

Os preços do Render mudaram em agosto de 2026: confira em render.com/pricing. Uma empresa com o histórico inteiro do SISTGER ocupa uns 30 MB no Postgres.

Quando houver várias empresas em produção, suba o Web Service para o Standard (2 GB) e ponha `WEB_CONCURRENCY=2`, e suba o Postgres para o Basic-1GB.

## 1. Bucket no Cloudflare R2

1. No painel da Cloudflare, abra **R2 Object Storage** e crie um bucket, por exemplo `agetur-arquivos`. Deixe o acesso público desligado: o app entrega os arquivos por links assinados.
2. Em **Manage R2 API Tokens**, crie um token com permissão **Object Read & Write** só nesse bucket.
3. Anote quatro valores:
   - o **Access Key ID**;
   - o **Secret Access Key**;
   - o nome do bucket;
   - o endpoint, `https://<account id>.r2.cloudflarestorage.com`.

## 2. Criar os serviços pelo Blueprint

1. No Render, use **New → Blueprint** e escolha o repositório `MarcosCaliope/agetur`, branch `main`.
2. O Render lê o `render.yaml` e pede as variáveis marcadas `sync: false`:
   - `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`: os valores do passo 1;
   - `MAILER_FROM`, `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD`: podem ficar em branco por enquanto (veja o passo 5).
3. Confirme. O Render cria o banco e o serviço e faz o primeiro deploy:
   - **build** (`bin/render-build.sh`): gems, pacotes yarn e assets;
   - **pre-deploy**: `db:migrate` e `db:seed` (os 27 estados);
   - **start**: Puma, verificado pelo health check em `/up`.

O `SECRET_KEY_BASE` é gerado pelo próprio Render. O `config/master.key` do repositório não é usado em produção, porque já foi exposto no histórico do git.

## 3. Primeiro acesso

1. No serviço `agetur`, abra a aba **Shell** e crie o administrador:
   ```bash
   bin/rails runner 'Admin.create!(email: "voce@empresa.com.br", password: "uma-senha-forte")'
   ```
2. Entre em `https://agetur.onrender.com/admins/sign_in` (o endereço aparece no topo do serviço).
3. Para cada empresa que for avaliar, você tem dois caminhos:
   - cadastrar a empresa em **Empresa** e os usuários em **Usuários**;
   - ou importar a empresa do SISTGER (passo 4).

## 4. Importar uma empresa do SISTGER

O Render não alcança o SQL Server da sua rede, então a importação roda **no seu computador**, gravando direto no banco do Render:

1. No Render, abra o banco `agetur-db`.
2. Em **Access Control**, libere o IP público do seu computador.
3. Copie a **External Database URL**.
4. Neste computador, com o `.env` de desenvolvimento apontando para o SISTGER, rode:
   ```bash
   DATABASE_URL='<External Database URL>' bin/rails sistger:importar
   ```
   Para importar só algumas etapas, use `ETAPAS=ordens,caixa`. A lista de etapas está em `SistgerImport::ETAPAS`.

A tarefa mostra a origem e o destino antes de gravar e, no fim, quanto leu e gravou em cada etapa. Ela é a mesma importação da tela Manutenção → SISTGER: pode ser repetida, e atualiza os registros em vez de duplicar. Pela internet, ela demora mais do que os ~30 s locais.

Depois da importação, tire o seu IP do Access Control, se não for mais usar.

## 5. E-mail (recuperação de senha)

Sem SMTP, o app funciona, mas o "esqueci minha senha" não envia nada. Para ativar:

1. Crie uma conta num serviço de envio, como Brevo, Resend ou Amazon SES, e verifique o domínio do remetente.
2. Preencha as variáveis no serviço `agetur`:
   - `MAILER_FROM` (por exemplo `Agetur <nao-responda@suaempresa.com.br>`);
   - `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD`;
   - `SMTP_PORT`, que já vem como 587.

Salvar as variáveis faz um novo deploy.

## 6. Domínio próprio (opcional)

1. Em **Settings → Custom Domains**, adicione o domínio e crie o CNAME que o Render indicar. O certificado HTTPS é emitido sozinho.
2. Ponha o domínio em `APP_HOST`, para os links dos e-mails usarem ele.

## Variáveis de ambiente

| Variável | Para quê |
|---|---|
| `DATABASE_URL` | Postgres (vem do `agetur-db`) |
| `SECRET_KEY_BASE` | sessões e cookies (gerada pelo Render) |
| `ACTIVE_STORAGE_SERVICE` | `r2` (comprovantes e logos no R2); `local` só onde o disco é mantido |
| `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` | bucket do R2 |
| `MAILER_FROM`, `SMTP_*` | envio de e-mail |
| `APP_HOST` | domínio próprio, se houver (senão usa o endereço `.onrender.com`) |
| `WEB_CONCURRENCY`, `RAILS_MAX_THREADS` | processos e threads do Puma (0 e 5 no Starter) |
| `RAILS_LOG_LEVEL` | `info` por padrão |
