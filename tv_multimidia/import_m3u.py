import re
import psycopg2
import psycopg2.extras  # Importante para a performance (execute_batch)
import sys
import os               # Para ler variáveis de ambiente

# --- 1. CONFIGURAÇÕES ---

# Caminho para o arquivo M3U (ajuste se necessário)
ARQUIVO_M3U = os.environ.get('M3U_FILE_PATH', '/app/playlist_253588464_plus.m3u')
# Para execução local, comente a linha acima e descomente a abaixo:
# ARQUIVO_M3U = './playlist_253588464_plus.m3u'

# Configurações do PostgreSQL (usa variáveis de ambiente, com fallback)
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'postgres'),
    'database': os.environ.get('DB_NAME', 'tv_multimidia'),
    'user': os.environ.get('DB_USER', 'tv_user'),
    'password': os.environ.get('DB_PASSWORD', 'tv_password'),
    'port': os.environ.get('DB_PORT', 5432),
    'options': '-c client_encoding=UTF8'
}


def parse_m3u(filepath):
    """
    Lê um arquivo .m3u e extrai os dados de cada canal.
    """
    print(f"Iniciando leitura do arquivo: {filepath}...")
    channels = []
    current_channel_info = {}

    try:
        # Tenta abrir com utf-8, que é comum
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.readlines()
    except UnicodeDecodeError:
        # Se falhar, tenta com 'latin-1' ou 'iso-8859-1'
        print("Falha no UTF-8, tentando com 'latin-1'...")
        try:
            with open(filepath, 'r', encoding='latin-1') as f:
                content = f.readlines()
        except Exception as e_latin:
            print(f"--- ERRO FATAL ---")
            print(f"Não consegui ler o arquivo nem com UTF-8 nem com Latin-1: {e_latin}")
            return None
    except FileNotFoundError:
        print(f"--- ERRO FATAL ---")
        print(f"Arquivo não encontrado no caminho: '{filepath}'")
        return None
    except Exception as e:
        print(f"Ocorreu um erro inesperado ao ler o arquivo: {e}")
        return None

    # Processa as linhas lidas
    for line in content:
        line = line.strip()

        if line.startswith('#EXTINF:'):
            # Encontrou uma linha de informação do canal
            current_channel_info = {
                'name': None,
                'logo': None,
                'group_title': None,
            }

            # Extrai group-title
            match_group = re.search(r'group-title="(.*?)"', line)
            
            if match_group:
                group_name = match_group.group(1).strip()
                current_channel_info['group_title'] = group_name
                
                # FILTRAR APENAS CANAIS QUE CONTENHAM "CANAIS"
                if "CANAIS" not in group_name:
                    current_channel_info = {} # Ignora este canal
                    continue
            else:
                # Se não tiver group-title, ignora
                current_channel_info = {}
                continue

            # Extrai tvg-name
            match_name = re.search(r'tvg-name="(.*?)"', line)
            if match_name:
                current_channel_info['name'] = match_name.group(1).strip()
            else:
                # Pega o nome após a última vírgula como fallback
                try:
                    current_channel_info['name'] = line.split(',')[-1].strip()
                except Exception:
                    pass  # Deixa como None se falhar

            # Extrai tvg-logo
            match_logo = re.search(r'tvg-logo="(.*?)"', line)
            if match_logo:
                logo_url = match_logo.group(1).strip()
                # Trata logos vazios ("") como None
                current_channel_info['logo'] = logo_url if logo_url else None

        elif line and not line.startswith('#'):
            # Esta é a linha da URL, que vem DEPOIS da linha #EXTINF
            if current_channel_info:  # Se temos infos de um canal pendente
                # Não salvamos a URL de stream, conforme a lógica anterior
                channels.append(current_channel_info)
                # Reseta para o próximo canal
                current_channel_info = {}

    print(f"Leitura concluída. Total de {len(channels)} canais filtrados (contendo 'CANAIS').")
    return channels


def limpar_todos_canais(db):
    """
    Remove TODOS os canais da tabela channels.
    """
    print("Removendo todos os canais da tabela (TRUNCATE)...")
    try:
        with db.cursor() as cursor:
            cursor.execute("TRUNCATE TABLE channels RESTART IDENTITY")
            db.commit()
        print("Todos os canais foram removidos e a contagem de ID foi reiniciada.")
    except Exception as e:
        print(f"--- ERRO AO TRUNCAR TABELA ---")
        print(f"Erro: {e}")
        print("Revertendo (rollback)...")
        db.rollback()
        raise  # Levanta o erro para parar o script


def salvar_canais_no_banco(db, channels_data):
    """
    RECOMENDAÇÃO: Salva os canais no banco de dados em um único
    lote (batch) para máxima eficiência.
    """
    total = len(channels_data)
    if total == 0:
        print("Nenhum canal para inserir.")
        return

    print(f"Preparando {total} canais para inserção em lote...")
    data_to_insert = []
    skipped = 0

    # 1. Prepara a lista de tuplas em Python (operação rápida)
    for channel in channels_data:
        name = channel.get('name')
        logo = channel.get('logo') # Esta é a URL da imagem
        group_title = channel.get('group_title')
        description = None # Definido como None

        if not name:
            skipped += 1
            continue
        
        # A tupla deve corresponder aos %s na query
        # (name, logopath, category, description, imageurls)
        data_to_insert.append((name, logo, group_title, description, logo))
    
    if not data_to_insert:
        print("Nenhum canal válido para inserir (todos foram pulados).")
        return
    
    # 2. Define o SQL (streamurl é 'NULL' diretamente no SQL)
    sql_insert = """
        INSERT INTO channels (name, logopath, streamurl, category, description, imageurls)
        VALUES (%s, %s, NULL, %s, %s, %s)
    """
    
    # 3. Executa a transação
    try:
        with db.cursor() as cursor:
            print(f"Executando inserção em lote de {len(data_to_insert)} canais...")
            
            # ATUALIZAÇÃO: Usa execute_batch para performance
            psycopg2.extras.execute_batch(cursor, sql_insert, data_to_insert)
            
            inserted_count = cursor.rowcount # Pega o número de linhas afetadas
            
            print("Realizando commit final...")
            db.commit()
            print("Commit realizado com sucesso.")

    except Exception as e:
        print(f"\n--- ERRO DURANTE A INSERÇÃO EM LOTE ---")
        print(f"Erro: {e}")
        print("Revertendo todas as alterações (rollback)...")
        db.rollback()
        print("Alterações revertidas.")
        return # Sai da função em caso de erro

    print(f"\n--- Resumo da Importação ---")
    print(f"Total de canais na lista M3U: {total}")
    print(f"Inseridos com sucesso: {inserted_count}")
    print(f"Pulados (sem nome): {skipped}")


def main():
    # 1. Conecta ao banco de dados PostgreSQL
    try:
        # ATUALIZAÇÃO: Usa o dict DB_CONFIG (que usa env vars)
        db = psycopg2.connect(**DB_CONFIG)
        print(f"Conectado ao banco de dados PostgreSQL em: {DB_CONFIG['host']}")
    except Exception as e:
        print(f"Erro ao conectar ao PostgreSQL: {e}")
        print("Verifique se o host, usuário, senha e porta estão corretos.")
        return

    # 2. Lê e parseia o arquivo M3U
    lista_de_canais = parse_m3u(ARQUIVO_M3U)

    if not lista_de_canais:
        print("Nenhum canal foi processado. Encerrando o script.")
        db.close()
        return
        
    try:
        # 3. Remove todos os canais da tabela
        limpar_todos_canais(db)

        # 4. Salva os canais no banco
        print("\nIniciando inserção dos canais no banco de dados...")
        salvar_canais_no_banco(db, lista_de_canais)

    except Exception as e:
        print(f"Um erro crítico ocorreu durante a operação com o banco: {e}")
    finally:
        # 5. Fecha a conexão
        db.close()
        print("\nConexão com o banco de dados fechada.")

    print("\n--- Processo Concluído ---")


# --- Ponto de entrada do script ---
if __name__ == "__main__":
    main()