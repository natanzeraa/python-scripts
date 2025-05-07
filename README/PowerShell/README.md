# 📦 Coleta e Ranking de Caixas de E-mail no Exchange Online

[Acesse o script clicando aqui 📍](https://github.com/natanzeraa/scripts-and-automation/blob/main/PowerShell%20Scripts/MicrosoftEntraID/GetExchangeMailBoxSize.ps1)

Este script PowerShell coleta estatísticas de caixas de e-mail no Exchange Online e gera um ranking das caixas mais ocupadas, exportando os resultados em CSV.

## 📋 Funcionalidades

* Lista todas as caixas de e-mail da organização.
* Exibe o nome da organização e total de caixas.
* Permite ao usuário escolher quantas caixas exibir no ranking.
* Exibe uma barra de progresso durante a execução.
* Gera relatório com:

  * Nome do usuário
  * E-mail
  * Tamanho total da caixa
  * Quantidade de e-mails
* Exporta os dados em CSV para a pasta `output`.

## ✅ Pré-requisitos

Para que o script funcione corretamente, o ambiente precisa atender aos seguintes requisitos:

### 1. **Permissões e Conectividade**

* A conta que executa o script deve ter permissões administrativas no Exchange Online.
* O PowerShell deve estar conectado ao Exchange Online (via módulo do Exchange Online Management).

```powershell
Connect-ExchangeOnline -UserPrincipalName seu_usuario@dominio.com
```

### 2. **Módulo PowerShell Necessário**

Instale o módulo **ExchangeOnlineManagement** caso ainda não o tenha:

```powershell
Install-Module ExchangeOnlineManagement
```

### 3. **Permissão para Execução de Scripts**

Certifique-se de que a execução de scripts está habilitada:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## ▶️ Como usar

1. Abra o PowerShell como Administrador.
2. Conecte-se ao Exchange Online:

```powershell
Connect-ExchangeOnline -UserPrincipalName seu_usuario@dominio.com
```

3. Execute o script:

```powershell
.\coleta_caixas.ps1
```

4. Quando solicitado, informe o número de caixas de e-mail mais ocupadas que deseja ver no ranking (por exemplo, `10`).

## 📁 Exportação

* O relatório será salvo automaticamente na pasta `output`, localizada um nível acima do diretório do script.
* Nome do arquivo gerado: `top_X_caixas_de_email.csv`, onde `X` é o número informado pelo usuário.

## ⚠️ Possíveis erros tratados

* Caixas de e-mail sem dados de tamanho.
* Falha ao coletar estatísticas individuais (exibido ao final da execução).

## 📌 Observações

* O script é útil para administradores de ambientes Microsoft 365 que desejam monitorar o uso de caixas de e-mail.
* Pode ser adaptado para rodar via agendamento ou integração com outras ferramentas de auditoria.

---

