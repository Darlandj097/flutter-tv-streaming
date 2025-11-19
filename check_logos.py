#!/usr/bin/env python3
"""
Script para verificar URLs de logos na tabela channels
"""

import psycopg2

def check_logos():
    try:
        # Conexão simples
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            dbname="tv_multimidia",
            user="tv_user",
            password="tv_password"
        )

        cursor = conn.cursor()

        print("=== VERIFICAÇÃO DE LOGOS NA TABELA CHANNELS ===")
        print()

        # Total de canais
        cursor.execute("SELECT COUNT(*) FROM channels;")
        total = cursor.fetchone()[0]
        print(f"Total de canais: {total}")

        # Canais com logopath preenchido
        cursor.execute("SELECT COUNT(*) FROM channels WHERE logopath IS NOT NULL AND logopath != '';")
        com_logo = cursor.fetchone()[0]
        print(f"Canais com logopath preenchido: {com_logo}")

        # Canais sem logopath
        cursor.execute("SELECT COUNT(*) FROM channels WHERE logopath IS NULL OR logopath = '';")
        sem_logo = cursor.fetchone()[0]
        print(f"Canais sem logopath: {sem_logo}")

        print()
        print("=== EXEMPLOS DE URLs DE LOGO ===")

        # Mostrar alguns exemplos
        cursor.execute("SELECT name, logopath FROM channels WHERE logopath IS NOT NULL AND logopath != '' LIMIT 5;")
        exemplos = cursor.fetchall()

        if exemplos:
            for nome, logo in exemplos:
                print(f"{nome}: {logo}")
        else:
            print("Nenhuma URL de logo encontrada.")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"Erro: {e}")

if __name__ == "__main__":
    check_logos()