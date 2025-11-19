#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de teste para conexão com PostgreSQL
"""

import psycopg2
import psycopg2.extras
import os

def test_connection():
    """Testa conexão com PostgreSQL"""
    try:
        # Configurar encoding para Windows
        os.environ['PYTHONIOENCODING'] = 'utf-8'
        os.environ['LC_ALL'] = 'C.UTF-8'
        os.environ['LANG'] = 'C.UTF-8'

        print("Tentando conectar ao PostgreSQL...")

        # Conexão direta com Docker usando string de conexão
        conn_string = "host=localhost port=5432 dbname=tv_multimidia user=tv_user password=tv_password"
        conn = psycopg2.connect(conn_string)

        print("Conexao estabelecida!")

        # Testar query simples
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"Versao PostgreSQL: {version[0][:50]}...")

        # Verificar tabelas
        cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
        tables = cursor.fetchall()
        print(f"Tabelas encontradas: {[t[0] for t in tables]}")

        # Contar registros
        for table in ['movies', 'tv_series', 'channels']:
            if table in [t[0] for t in tables]:
                cursor.execute(f"SELECT COUNT(*) FROM {table};")
                count = cursor.fetchone()[0]
                print(f"{table}: {count} registros")

        cursor.close()
        conn.close()
        print("Teste concluido com sucesso!")

    except Exception as e:
        print(f"Erro: {e}")
        return False

    return True

if __name__ == "__main__":
    test_connection()