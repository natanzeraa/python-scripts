import re
import csv
import sqlite3
import pandas as pd
import argparse
import os
import logging


# Configura o logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger_duplicates = logging.getLogger('duplicates')
duplicates_handler = logging.FileHandler('output/duplicated_users.log', mode='w', encoding='utf-8')
duplicates_handler.setFormatter(logging.Formatter('%(message)s'))
logger_duplicates.addHandler(duplicates_handler)
logger_duplicates.setLevel(logging.INFO)


def extract_users(input_path):
    """Lê um arquivo .txt e extrai os usuários com seus dados."""
    with open(input_path, "r", encoding="utf-8") as infile:
        lines = infile.readlines()

    rows = []

    for line in lines:
        line = line.strip()

        # Divida as colunas pelo ponto e vírgula
        columns = line.split(';')

        if len(columns) >= 4:
            display_name = columns[0].strip()
            entra_id = columns[1].strip()
            mail = columns[2].strip()
            upn = columns[3].strip()

            # Extrair domínio do UPN
            domain_match = re.search(r'@(.+)$', upn)
            domain = domain_match.group(1).lower() if domain_match else ""

            # Extrair a licença se existir (se existir mais de 4 colunas, assume que é a licença)
            license = columns[4].strip() if len(columns) > 4 and columns[4].strip() else "UNLICENSED"

            # Adiciona a linha à lista de dados
            rows.append([display_name, entra_id, mail, upn, domain, license])

    return rows


def save_to_csv(rows, output_path):
    """Salva os dados dos usuários em formato CSV."""
    with open(output_path, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["display_name", "entra_id", "mail", "upn", "domain", "license"])
        writer.writerows(rows)


def create_tables(cursor):
    """Cria as tabelas necessárias no banco de dados."""
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS domains (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            display_name TEXT,
            entra_id TEXT,
            mail TEXT,
            upn TEXT,
            domain_id INTEGER,
            license TEXT NOT NULL,
            FOREIGN KEY(domain_id) REFERENCES domains(id)
        )
    """)


def import_domains(cursor, domain_file):
    """Importa domínios a partir de um arquivo e insere na tabela 'domains'."""
    with open(domain_file, "r", encoding="utf-8") as f:
        domains = [line.strip().lower() for line in f if line.strip()]

    for domain in domains:
        try:
            cursor.execute("INSERT INTO domains (name) VALUES (?)", (domain,))
        except sqlite3.IntegrityError:
            continue  # Já existe


def insert_users(cursor, df):
    """Insere os usuários no banco de dados e associa com seus respectivos domínios."""
    for _, row in df.iterrows():
        # Garantir que o campo 'mail' seja uma string e que não seja NaN
        mail = str(row['mail']).strip() if pd.notnull(row['mail']) else ''

        # Extrair o domínio do e-mail
        domain = mail.split('@')[1].strip() if '@' in mail else ''

        cursor.execute("SELECT id FROM domains WHERE name = ?", (domain,))
        result = cursor.fetchone()

        if result:
            domain_id = result[0]
        else:
            cursor.execute("INSERT INTO domains (name) VALUES (?)", (domain,))
            domain_id = cursor.lastrowid

        # Verifica se o usuário já existe no banco (evita duplicação de entra_id, mail, ou upn)
        # cursor.execute("""
        #     SELECT 1 FROM users WHERE entra_id = ? OR mail = ? OR upn = ?
        # """, (row['entra_id'], mail, row['upn']))

        # if cursor.fetchone():
        #     logger_duplicates.info(f"Duplicado ignorado: {row['display_name']}, {row['entra_id']}, {mail}, {row['upn']}, {domain}, {row.get('license', '')}")
        #     continue  # Se o usuário já existir, ignora a inserção

        try:
            cursor.execute("""
                INSERT INTO users (display_name, entra_id, mail, upn, domain_id, license)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (row['display_name'], row['entra_id'], mail, row['upn'], domain_id, row.get('license', '')))
        except sqlite3.IntegrityError as e:
            logging.error(f"🔴 Erro ao inserir dados no banco: {e}")
            # logger_duplicates.info(f"Erro ao inserir (IntegrityError): {row['display_name']}, {row['entra_id']}, {mail}, {row['upn']}, {domain}, {row.get('license', 'UNLICENSED')}")
            continue


def detect_csv_separator(file_path):
    """Detecta se o CSV está separado por vírgula ou ponto e vírgula."""
    with open(file_path, 'r', encoding='utf-8') as f:
        sample = f.read(1024)
        if sample.count(';') > sample.count(','):
            return ';'
        else:
            return ','


def process(input_path, output_path, db_name, domain_file):
    """Pipeline completo: txt → csv → banco de dados."""
    # Verifica se os arquivos existem
    for file_path in [input_path, domain_file]:
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Arquivo não encontrado: {file_path}")

    # Verifica se o arquivo já é CSV
    if input_path.lower().endswith(".csv"):
        sep = detect_csv_separator(input_path)
        df = pd.read_csv(input_path, sep=sep)
        print(df)
    else:
        rows = extract_users(input_path)
        save_to_csv(rows, output_path)
        df = pd.read_csv(output_path)

    conn = sqlite3.connect(db_name)
    cursor = conn.cursor()

    create_tables(cursor)
    import_domains(cursor, domain_file)
    insert_users(cursor, df)

    conn.commit()
    conn.close()
    logging.info(f"✅ Banco de dados '{db_name}' criado com sucesso!")


# Execução principal com argparse
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="""
        Processa usuários do Entra ID a partir de um arquivo de texto para CSV e SQLite DB.

        Exemplo de uso:
          python entra_parser.py --input-file entra-id-users.txt --output-file entra-id-users.csv \
                                  --db-name database.db --domains-file domains.txt
        """,
        formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "--input-file",
        type=str,
        required=True,
        help="Nome do arquivo de entrada .txt ou .csv (colocado dentro da pasta input/, ex: entra-id-users.txt ou entra-id-users.csv)"
    )

    parser.add_argument(
        "--output-file",
        type=str,
        required=True,
        help="Nome do arquivo de saída .csv (colocado dentro da pasta output/, ex: entra-id-users.csv)"
    )

    parser.add_argument(
        "--db-name",
        type=str,
        required=True,
        help="Nome do banco de dados SQLite a ser criado (ex: database.db)"
    )

    parser.add_argument(
        "--domains-file",
        type=str,
        required=True,
        help="Nome do arquivo contendo os domínios válidos (colocado dentro da pasta output/, ex: domains.txt)"
    )

    args = parser.parse_args()

    # Resolve automaticamente os caminhos completos
    input_file = os.path.join("input", args.input_file)
    output_file = os.path.join("output", args.output_file)
    db_file = args.db_name
    domains_file = os.path.join("output", args.domains_file)

    process(input_file, output_file, db_file, domains_file)
