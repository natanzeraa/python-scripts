import re
import csv
import sqlite3
import pandas as pd


def txt_to_csv(input_path, output_path):
    with open(input_path, "r", encoding="utf-8") as infile:
        lines = infile.readlines()

    rows = []

    for line in lines:
        parts = re.split(r'\s{2,}', line.strip())
        if len(parts) == 3:
            nome, email, dominio = parts
            rows.append([nome.strip(), email.strip(), dominio.strip()])

    with open(output_path, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["nome", "email", "dominio"])
        writer.writerows(rows)

    create_database(output_path)


def create_database(csv_file):
    df = pd.read_csv(csv_file)

    conn = sqlite3.connect("dominios.db")
    cursor = conn.cursor()

    # Criação das tabelas
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS domains (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS emails (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            domain_id INTEGER,
            FOREIGN KEY(domain_id) REFERENCES domains(id)
        )
    """)

    for _, row in df.iterrows():
        domain = row['dominio'].strip().lower()

        # Verifica se o domínio já existe, se não, insere e obtém o ID
        cursor.execute("SELECT id FROM domains WHERE name = ?", (domain,))
        domain_result = cursor.fetchone()

        if domain_result:
            domain_id = domain_result[0]
        else:
            cursor.execute("INSERT INTO domains (name) VALUES (?)", (domain,))
            domain_id = cursor.lastrowid

        # Insere o e-mail com o ID do domínio
        try:
            cursor.execute("""
                INSERT INTO emails (name, email, domain_id)
                VALUES (?, ?, ?)
            """, (row['nome'], row['email'], domain_id))
        except sqlite3.IntegrityError:
            # Ignora duplicatas de email
            continue

    conn.commit()
    conn.close()
    print("Banco de dados criado com sucesso!")


# Caminhos
input = "input/email.txt"
output = "output/saida.csv"
txt_to_csv(input, output)
